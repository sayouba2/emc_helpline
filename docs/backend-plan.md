# Plan backend — EMC Helpline

Base de données : **Firestore**. Ce document décrit ce qui se met autour.

Il s'adresse à qui écrira le backend, et suppose le frontend dans son état
actuel : le seul point de branchement côté Flutter est le `ReportSubmitter`
défini dans [`lib/models/submission_outcome.dart`](../lib/models/submission_outcome.dart).

---

## 1. La décision structurante : le client n'écrit pas dans Firestore

Règles Firestore et Storage : `allow read, write: if false`. Tout passe par des
Cloud Functions.

C'est l'inverse du schéma Firebase habituel, donc voici pourquoi il ne
s'applique pas ici.

Le schéma habituel — SDK client plus règles de sécurité — repose sur une
identité par utilisateur : `request.auth.uid` dans la règle. **Cette
application n'a pas de comptes, délibérément** : demander une inscription à un
enfant qui signale un adulte de son entourage est exactement ce qu'il faut
éviter. Sans identité, la règle d'écriture devient `if true`, et la clé d'API
est lisible dans l'APK. N'importe qui peut alors écrire dans la collection —
et une erreur symétrique en lecture exposerait des signalements d'enfants.

Le suivi par numéro de référence aggrave le problème. « Lire un document si on
connaît une chaîne » n'est pas une règle Firestore : c'est un jeton porteur
sans limitation de débit. Il faut compter les tentatives, ce que seule une
fonction peut faire.

**Conséquence pratique :** aucune dépendance `cloud_firestore` côté Flutter. Le
client ne connaît que des appels de fonctions.

---

## 2. Pile

| Rôle | Choix |
|---|---|
| API | Cloud Functions for Firebase, 2ᵉ génération, **TypeScript** (Node 22) |
| Données | Firestore en mode natif |
| Fichiers | Cloud Storage, écriture par URL signée uniquement |
| Anti-abus | Firebase App Check (Play Integrity / DeviceCheck) |
| Identité d'appareil | Firebase Auth **anonyme** — pour compter, pas pour identifier |
| Notifications (plus tard) | Firebase Cloud Messaging |
| Console équipe (plus tard) | application web séparée, Auth par e-mail + custom claim `role: agent` |

TypeScript plutôt que Python : `firebase-admin` et `firebase-functions` y sont
de première classe, et le contrat de données doit rester aligné avec le modèle
Dart — un schéma Zod partagé est plus facile à tenir honnête qu'une convention.

Les fonctions 2ᵉ gen tournent sur Cloud Run. Écrites en handlers HTTP simples,
elles migrent vers un service Cloud Run autonome presque sans changement, le
jour où la partie métier grossit (file de modération, exports, intégration
e-vigilance).

### Auth anonyme, précision

Elle ne sert pas à retrouver l'utilisateur. Elle donne un identifiant stable par
installation, qui sert de clé de comptage pour la limitation de débit. Aucun UID
n'est stocké dans le document de signalement — sinon deux signalements du même
appareil deviendraient liables entre eux, ce que l'anonymat promis interdit. Le
UID ne vit que dans les compteurs, avec un TTL court.

---

## 3. Collections

```
reports/{reportId}
  status           string   received | in_review | contacted | closed
  whoFor, ageGroup, gender, incidentType, platform,
  assistanceNeeded, assistanceType, urgencyLevel   string (valeurs d'enum Dart)
  description      string?
  evidenceUrl      string?
  evidencePaths    string[] chemins Cloud Storage
  pseudo           string?  seulement si accompagnement demandé
  contactPhone     string?  idem
  createdAt        timestamp

referenceIndex/{sha256}
  reportId         string
  createdAt        timestamp

idempotency/{key}
  reportId         string
  referenceCode    string   rendu tel quel si la même clé revient
  createdAt        timestamp
  expiresAt        timestamp  ← TTL 30 jours, la fenêtre de réessai

rateLimits/{scope}_{subject}
  count            number
  windowStart      timestamp
  expiresAt        timestamp  ← TTL
```

**Le numéro de référence n'est stocké nulle part en clair.** C'est un secret
porteur : il ouvre le dossier. Le garder en clair signifie qu'une fuite de la
base — ou un accès console accordé un peu trop largement — donne accès à tous
les dossiers d'un coup.

Son SHA-256 sert d'**identifiant de document** dans `referenceIndex`, ce qui
donne trois choses à la fois : une contrainte d'unicité réelle (deux dossiers ne
peuvent pas partager un code), un `get` par clé exacte pour le suivi — sans
index composite —, et la séparation entre le dossier et sa clé d'accès.

Pas de sel : la valeur hachée fait 60 bits aléatoires, il n'y a donc pas de
dictionnaire contre lequel se défendre, et un sel par enregistrement rendrait la
recherche par code impossible, ce qui est tout l'objet.

Corollaire à assumer : **un code perdu est un dossier perdu**. C'est déjà ce que
dit l'écran de suivi, et c'est le prix de l'anonymat.

`reports` ne porte pas d'`expiresAt` : la durée de conservation est une décision
du CMRPI, et une politique TTL inventée ici se mettrait à supprimer des preuves
en silence.

---

## 4. API

Trois fonctions appelables (`onCall`), plus App Check exigé sur les trois.

### `submitReport`

```ts
// requête
{ idempotencyKey: string, report: ReportPayload }
// réponse
{ referenceCode: string }   // "EMC-4K7P-W9XM-2QTR"
```

Déroulé, dans une transaction Firestore :

1. Lire `idempotency/{key}`. S'il existe, **renvoyer le `referenceCode` stocké
   et s'arrêter là.** C'est tout l'intérêt de la clé : le client réessaie après
   un timeout, et le serveur avait peut-être déjà enregistré.
2. Sinon : valider le payload (Zod), tirer un code, écrire `reports/{id}` et
   `idempotency/{key}` **dans la même transaction**. Si l'un des deux échoue,
   aucun ne passe — sans quoi un réessai créerait le doublon qu'on cherche à
   éviter.
3. Renvoyer le code.

La clé d'idempotence vient du client et **est déjà implémentée côté Flutter**
(`ReportProvider._newIdempotencyKey`, stable pour un signalement donné, tant
qu'il n'est pas envoyé ou abandonné). C'est le serveur qui la fait respecter ;
le client ne fait que la transmettre inchangée.

Génération du code : [`functions/src/referenceCode.ts`](../functions/src/referenceCode.ts),
port fidèle de [`lib/core/utils/reference_code.dart`](../lib/core/utils/reference_code.dart).
Les deux ont la même suite de tests, parce que le client analyse ce que le
serveur produit. `crypto.randomBytes`, jamais `Math.random` ; l'alphabet fait
exactement 32 caractères, donc masquer un octet par 31 est uniforme — pas de
biais de modulo.

### `trackReport`

```ts
{ referenceCode: string }
{ status: string, createdAt: string, incidentType: string, urgencyLevel: string }
```

Normaliser l'entrée comme le fait `ReferenceCode.payloadOf` (majuscules, tirets
retirés, `O`→`0`, `I`/`L`→`1`), hacher, chercher sur `referenceHash`.

**Ne renvoie jamais le contenu du signalement** : ni description, ni preuves, ni
coordonnées. Un code qui fuite doit donner l'état d'avancement, pas le dossier.

Limitation de débit stricte — voir §5. C'est la seule défense en profondeur
derrière l'entropie du code.

### `requestEvidenceUploadUrl`

```ts
{ idempotencyKey: string, fileName: string, contentType: string, sizeBytes: number }
{ uploadUrl: string, storagePath: string }
```

URL signée V4, valable 15 minutes, restreinte à un objet, un type MIME
(`image/jpeg`, `image/png`, `image/webp`) et une taille maximale. Le client
téléverse dessus, puis passe `storagePath` dans `submitReport`.

Ainsi rien n'atterrit dans le bucket que le backend n'a pas autorisé, et le
bucket n'a jamais besoin d'être ouvert en écriture.

---

## 5. Limitation de débit

Elle porte tout le modèle de sécurité du suivi, donc elle n'est pas optionnelle.

| Point d'entrée | Clé | Limite proposée |
|---|---|---|
| `submitReport` | UID anonyme | 5 / heure, 20 / jour |
| `trackReport` | UID anonyme | 10 / heure |
| `trackReport` | global | seuil d'alerte, pas de blocage |
| `requestEvidenceUploadUrl` | UID anonyme | 20 / heure |

Compteurs dans `rateLimits/`, incrémentés en transaction, purgés par TTL.

Sur `trackReport`, répondre **le même délai et le même message** pour un code
inconnu et un code au-delà de la limite : une différence de comportement
observable est un oracle qui rend l'énumération plus rapide.

Le frontend écarte déjà les codes mal formés avant d'appeler (`isWellFormed`),
donc ils ne consomment pas de budget. C'est une commodité, pas une garantie :
**revalider côté serveur.**

---

## 6. Journalisation

Le point à ne pas rater : **le contenu d'un signalement ne doit apparaître dans
aucun log.** Cloud Logging est consultable par tout le projet, se conserve
longtemps et sort du périmètre pensé pour ces données.

- Journaliser `reportId`, `status`, la durée, le code d'erreur. Rien d'autre.
- Jamais : `description`, `pseudo`, `contactPhone`, `referenceCode`,
  chemins de preuves.
- Attention aux erreurs de validation Zod, qui incluent la valeur fautive par
  défaut. Filtrer avant de logger.

---

## 7. Ordre de construction

1. Projet Firebase, App Check, Auth anonyme, règles Firestore et Storage à
   `false`. Vérifier que le client ne peut rien lire ni écrire.
2. `submitReport` avec l'idempotence et la génération de code. C'est le cœur :
   tout le reste s'y appuie.
3. Brancher le `ReportSubmitter` Flutter dessus, avec le mappage
   d'erreurs (§8). Le frontend ne change nulle part ailleurs.
4. `requestEvidenceUploadUrl` + téléversement client.
5. `trackReport` + limitation de débit.
6. Politiques TTL, une fois la durée de conservation arrêtée.
7. Console équipe.

Aux étapes 2 et 3, l'application est déjà utilisable de bout en bout, sans
preuves ni suivi. C'est le premier jalon qui vaut d'être testé en vrai.

---

## 8. Mappage des erreurs

Le `ReportSubmitter` doit lever une `SubmissionException` portant un
`SubmissionFailure` — c'est ce qui décide du texte que voit l'utilisateur.

| Côté client | `SubmissionFailure` |
|---|---|
| `SocketException`, `unavailable`, pas de réseau | `network` |
| `deadline-exceeded`, timeout HTTP | `timeout` |
| `internal`, `unavailable` côté serveur, 5xx | `server` |
| `invalid-argument`, `failed-precondition` | `server` (bug client : ne pas dire à l'enfant que c'est sa faute) |
| `resource-exhausted` (débit) | `server` |
| tout le reste | laisser remonter — le provider retombe sur `unknown` |

`timeout` a son propre texte pour une raison : c'est le seul cas où le
signalement est peut-être déjà enregistré, et le message le dit. Ne pas le
replier sur `network`.

---

## 9. Où on en est

**Étapes 1 et 2 faites**, dans le dépôt, testées contre l'émulateur.

```
firestore.rules  storage.rules      tout fermé au client
firebase.json    .firebaserc        ⚠️ l'ID de projet est un espace réservé
functions/src/   config, schema, referenceCode, rateLimit, logging, submitReport
functions/test/  code de référence, schéma, transaction, limitation de débit
test/rules/      vérifie que le client ne peut rien lire ni écrire
```

### Lancer

```bash
npm install && npm install --prefix functions
```

```bash
npm run test:emulator
```

50 tests. Les tests de logique pure tournent aussi sans émulateur (`npm test`),
mais le reste est alors ignoré — un test de garde le signale plutôt que de
laisser croire à un succès complet.

### Ce qui reste à faire à la main, en console

Rien de tout cela ne peut être fait depuis le dépôt :

1. Créer le projet Firebase, puis `firebase use --add` — `.firebaserc` contient
   un espace réservé.
2. Activer **Authentication → Anonymous**.
3. Activer **App Check** (Play Integrity pour Android, DeviceCheck pour iOS) et
   enregistrer les empreintes de l'application. `submitReport` refuse déjà les
   requêtes sans jeton valide : tant que ce n'est pas fait, l'appel échoue.
4. Créer la base Firestore en région `europe-west1`.
5. Politique TTL sur `idempotency.expiresAt` et `rateLimits.expiresAt`.
   **Pas sur `reports`** tant que la durée de conservation n'est pas arrêtée.
6. `firebase deploy --only firestore:rules,storage:rules,functions`.

### Étape 3 — brancher le client

Le seul point de contact est le `ReportSubmitter` de
[`lib/models/submission_outcome.dart`](../lib/models/submission_outcome.dart).
Il reçoit `(report, idempotencyKey)`, appelle `submitReport`, rend le
`referenceCode` ou lève une `SubmissionException` selon le tableau du §8.
Aucun autre fichier Flutter ne change.

Deux points à ne pas rater :

- **`MIN_DESCRIPTION_LENGTH` doit rester égal à
  `Validators.minDescriptionLength`** (120). S'ils divergent, le client laisse
  passer un signalement que le serveur refuse, et l'utilisateur voit un échec
  qu'il ne peut pas corriger.
- Les noms de membres d'enum voyagent tels quels. Renommer un membre Dart est un
  changement de contrat.
