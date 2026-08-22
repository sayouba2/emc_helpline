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
  status           string   received | inReview | contacted | closed
  whoFor, ageGroup, gender, incidentType, platform,
  assistanceNeeded, assistanceType, urgencyLevel   string (valeurs d'enum Dart)
  description      string?
  evidenceUrl      string?
  evidencePaths    string[] chemins Cloud Storage
  pseudo           string?  seulement si accompagnement demandé
  contactPhone     string?  idem
  createdAt        timestamp
  expiresAt        timestamp  ← politique TTL Firestore, 30 jours glissants

referenceIndex/{sha256}
  reportId         string
  createdAt        timestamp
  expiresAt        timestamp  ← tenu en phase avec le dossier

auditLog/{auto}
  action           string   read | status | delete
  reportId, agentUid, agentEmail, from, to, at
  (aucun contenu de signalement ; survit au dossier)

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

**La conservation est de 30 jours glissants**, décidée par le CMRPI. Le dépôt
la fixe, et **chaque changement de statut la repousse**. Trente jours fixes
depuis la création supprimeraient un dossier pendant qu'on l'instruit, ce qui est
le seul comportement qu'une politique de conservation ne doit pas avoir. La
console affiche le compte à rebours, en rouge sous sept jours.

**Le TTL Firestore ne connaît pas Cloud Storage.** Sans le déclencheur
`onReportDeleted`, la politique supprimerait le dossier et laisserait les
captures — des photographies de l'agression d'un enfant — dans le bucket, pour
toujours, détachées de l'enregistrement qui expliquait leur présence. La version
silencieuse de cette panne est la dangereuse : depuis Firestore, tout a l'air
conforme.

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
{ found: boolean, report?: { status, createdAt, incidentType, urgencyLevel } }
```

L'entrée est normalisée par `referencePayloadOf` — le même traitement que côté
Dart — puis hachée, puis cherchée par identifiant de document dans
`referenceIndex`. Un seul `get`, pas de requête, pas d'index composite.

**Ne renvoie jamais le contenu du signalement** : ni description, ni preuves, ni
pseudo, ni téléphone. Le code est le seul justificatif qui existe ; qui le lit
par-dessus une épaule, ou le trouve sur un téléphone partagé — le cas même pour
lequel cette application existe — apprend où en est un dossier, et rien d'autre.

« Introuvable » est une valeur de retour, pas une erreur : c'est le cas normal
d'une faute de frappe, et le traiter comme une exception mélangerait la faute de
frappe avec la panne.

Une entrée d'index qui ne pointe sur rien est journalisée et traitée comme
introuvable. La transaction de `submitReport` rend ce cas impossible — raison
de plus pour qu'il ne fasse pas tomber la recherche s'il survient quand même.

### `requestEvidenceUploadUrl`

```ts
{ idempotencyKey: string, contentType: string, sizeBytes: number }
{ uploadUrl: string, storagePath: string }
```

URL signée V4, valable 15 minutes, restreinte à un objet et à un type MIME
(`image/jpeg`, `image/png`, `image/webp`). Le client téléverse dessus, puis
passe `storagePath` dans `submitReport`. Rien n'atterrit dans le bucket que le
backend n'a pas autorisé, et le bucket n'est jamais ouvert en écriture.

**Le chemin est dérivé, pas stocké.** L'objet va dans
`evidence/{sha256(idempotencyKey)[0:32]}/{aléatoire}.{ext}`, donc `submitReport`
recalcule le seul dossier qu'il acceptera au lieu de faire confiance aux chemins
qu'on lui tend. Sans ce lien, un appelant pourrait faire pointer son signalement
vers les captures de quelqu'un d'autre : un chemin bien formé n'est pas une
preuve qu'il a été délivré. La clé est hachée plutôt qu'utilisée telle quelle —
c'est une valeur du client, sans forme garantie, et un chemin de bucket n'est
pas l'endroit où la renvoyer en écho.

**`submitReport` revérifie avant d'écrire** : le dossier, l'existence réelle de
l'objet, sa taille et son type stocké. Une URL signée fixe le type au moment de
la délivrance ; ce qui a effectivement atterri mérite d'être relu plutôt que
supposé. La vérification est faite **avant** la transaction, parce qu'elle lit
le bucket et qu'une transaction qui rejoue le relirait pour rien.

**Déploiement :** générer une URL signée demande au compte de service
d'exécution le rôle *Créateur de jetons du compte de service*
(`iam.serviceAccounts.signBlob`) sur lui-même. Sans lui, la fonction échoue à la
signature. C'est le piège classique, et il ne se voit qu'une fois déployé — les
émulateurs ne signent pas.

---

## 5. Limitation de débit

Elle porte tout le modèle de sécurité du suivi, donc elle n'est pas optionnelle.

| Point d'entrée | Clé | Limite proposée |
|---|---|---|
| `submitReport` | UID anonyme | 5 / heure, 20 / jour |
| `trackReport` | UID anonyme | 10 / heure |
| `requestEvidenceUploadUrl` | UID anonyme | 20 / heure |

Compteurs dans `rateLimits/`, incrémentés en transaction, purgés par TTL.

### Correction : ce qui protège réellement les dossiers

Une version antérieure de ce document recommandait de répondre la même chose
pour un code inconnu et un code au-delà de la limite, afin de ne pas donner
d'oracle à qui énumère. **C'était un mauvais conseil pour ce produit**, et le
code ne le suit pas.

D'abord parce que le coût tombe sur les vrais utilisateurs : un enfant qui
vérifie son dossier onze fois dans l'heure — ce que fait exactement quelqu'un
d'inquiet — lirait « aucun dossier ne correspond ». Pour lui, ça veut dire que
son signalement a disparu.

Ensuite parce que la protection n'a jamais reposé là-dessus. Un UID anonyme
s'obtient gratuitement et sans limite : qui veut vraiment énumérer réinitialise
son compteur à chaque requête. La limitation de débit sert contre les
inondations et l'abus occasionnel, pas contre un attaquant déterminé.

**Ce qui protège les dossiers, ce sont les 60 bits d'entropie du code.** Environ
10^18 possibilités : même sans aucune limite, l'énumération ne finit pas.

`trackReport` renvoie donc `resource-exhausted`, distinct de « introuvable », et
journalise chaque recherche en `track_hit` / `track_miss` — sans code, sans
identifiant. C'est ce sur quoi brancher une alerte : **une série soutenue de
`track_miss` est à quoi ressemble une énumération**, et c'est le signal que des
compteurs par appareil ne peuvent pas voir.

Le frontend écarte les codes mal formés avant d'appeler (`isWellFormed`), donc
ils ne consomment pas de budget. C'est une commodité, pas une garantie :
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

**Étapes 1 à 6 faites**, dans le dépôt, testées.

```
firestore.rules  storage.rules      tout fermé au client
firebase.json    .firebaserc        ⚠️ l'ID de projet est un espace réservé
functions/src/   config, schema, referenceCode, rateLimit, logging, submitReport
functions/test/  code de référence, schéma, transaction, limitation de débit
test/rules/      vérifie que le client ne peut rien lire ni écrire

lib/core/backend/firebase_backend.dart   démarrage, App Check, auth anonyme,
                                          ReportSubmitter, mappage d'erreurs
lib/core/backend/report_payload.dart     ReportModel → contrat de transport
lib/core/backend/evidence_uploader.dart  téléversement par URL signée
lib/models/tracking_outcome.dart         les quatre issues d'une recherche
lib/core/backend/case_notifications.dart abonnement FCM par sujet
test/backend_contract_test.dart          vérifie l'accord des deux côtés
test/evidence_uploader_test.dart         transferts, cache de réessai, échecs
test/notifications_test.dart             sujet, permission, avertissement

console/                                 console équipe (Firebase Hosting)
functions/scripts/grant-agent.ts         donne ou retire l'accès console
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
3. Activer **App Check** — voir §10, ce n'est pas une case à cocher.
4. Créer la base Firestore : **mode production**, région **`europe-west1`**.

   *Mode production*, pas *mode test* : le mode test ouvre la base en lecture et
   en écriture à quiconque possède la clé d'API — laquelle est dans l'APK —
   pendant trente jours. `firestore.rules` remplacera de toute façon ce que la
   console écrit, donc le mode test n'apporte rien et ouvre une fenêtre
   pendant laquelle des signalements d'enfants seraient lisibles par tous.
   Le mode ne change rien à la facturation — voir §13.

   **La région ne se change pas après coup.** Elle doit correspondre à `REGION`
   dans `functions/src/config.ts`, sinon chaque appel traverse un continent
   pour rien.

   Un second projet « de test » n'est pas nécessaire : les émulateurs couvrent
   déjà les tests locaux (`npm run test:emulator`), sans toucher à de vraies
   données. Il en faudra un le jour où une préproduction sera utile.
5. Politique TTL sur `idempotency.expiresAt` et `rateLimits.expiresAt`.
   **Pas sur `reports`** tant que la durée de conservation n'est pas arrêtée.
6. Donner au compte de service d'exécution le rôle *Créateur de jetons du
   compte de service* sur lui-même, sans quoi `requestEvidenceUploadUrl` ne peut
   pas signer d'URL. Les émulateurs ne signent pas : ça ne se voit qu'en ligne.
7. Alerte sur le journal : une série soutenue de `track_miss` est à quoi
   ressemble une énumération, et c'est le signal que les compteurs par appareil
   ne peuvent pas voir.
8. `firebase deploy --only firestore:rules,storage:rules,functions`.

### Étape 3 — le client, branché

`main()` appelle `initializeBackend()` avant la première frame et passe le
`ReportSubmitter` obtenu à `ReportProvider`. Aucun écran ne change : le wizard
appelait déjà `submitReport()`, et l'écran d'erreur réagissait déjà à
`submissionError`.

**Ce que fait le repli, et ce qu'il ne fait pas.** Si Firebase ne démarre pas :

| Build | Comportement |
|---|---|
| debug | simulation locale, avec un avertissement dans les logs — le frontend reste utilisable sans projet configuré |
| release | un submitter qui échoue systématiquement |

En release, **jamais la simulation**. Elle distribuerait un numéro de référence
pour un signalement parti nulle part, et l'enfant repartirait en croyant que de
l'aide arrive. Un échec franc l'amène sur l'écran d'erreur, avec le réessai et
la ligne directe de l'équipe.

**Le contrat est tenu par des tests, pas par la vigilance.**
`test/backend_contract_test.dart` lit `functions/src/schema.ts` et
`functions/src/config.ts` et compare aux enums Dart et à
`Validators.minDescriptionLength`. Renommer un membre d'enum d'un seul côté, ou
changer 120 d'un seul côté, fait échouer la suite Flutter.

### Étape 4 — les preuves

`EvidenceUploader` téléverse les captures avant d'envoyer le signalement, et
rend les chemins que le serveur acceptera. `ReportModel.evidenceFilePaths` —
des chemins sur le téléphone — ne quitte jamais l'appareil.

**Un réessai renvoie le signalement, pas les captures.** Les chemins déjà
obtenus sont gardés par clé d'idempotence. La situation que tout ceci sert est
une mauvaise connexion ; repousser les mêmes mégaoctets à chaque tentative en
serait exactement la mauvaise réponse.

**Un échec de téléversement n'est jamais un `timeout`.** Ce message-là dit à
l'utilisateur que son signalement est peut-être déjà enregistré. À ce stade rien
n'a été déposé, donc ce serait faux — et ça découragerait un réessai qui, lui,
est propre. Une coupure devient `network` ; un bucket en panne (5xx) devient
`server`, parce qu'envoyer quelqu'un vérifier son wifi pendant que Cloud Storage
est tombé le fait chercher au mauvais endroit.

Ce que le client refuse avant même de téléverser : une extension que le serveur
n'accepte pas — `image_picker` peut rendre un HEIC sur iOS — et un fichier trop
gros. Inutile de dépenser un transfert et du budget de limitation de débit pour
quelque chose qui sera rejeté.

---

## 10. App Check

### Ce que c'est, en une phrase

Un videur à l'entrée du backend : il vérifie que la requête vient bien de
**votre application**, et pas d'un script écrit par quelqu'un d'autre.

### Pourquoi ce projet en a besoin

La clé d'API est lisible dans l'APK — n'importe qui peut l'en extraire en
quelques minutes, c'est normal et prévu, ce n'est pas un secret. Sans App Check,
cette clé suffit à appeler `submitReport` en boucle et à noyer l'équipe sous de
faux signalements, ou à marteler `trackReport` pour deviner des numéros de
référence.

Il n'y a pas de comptes utilisateurs ici : App Check est donc la seule chose qui
distingue l'application d'un script.

### Le symptôme quand ce n'est pas configuré

`submitReport` est déclaré `enforceAppCheck: true`. Sans jeton valide, la
fonction renvoie `unauthenticated`, **quel que soit l'état de la console** :
pour une fonction appelable, l'application se décide dans le code. Le mode
« non appliqué » du tableau de bord ne concerne que Firestore et Storage.

Concrètement, dans l'app : l'envoi d'un signalement tombe sur l'écran d'erreur
avec « Nos serveurs n'ont pas pu enregistrer ton signalement ». Rien n'est
cassé — c'est le videur qui fait son travail.

### Marche à suivre, une fois

**1. Empreinte SHA-256 de la clé de signature.**

```bash
cd android && ./gradlew signingReport
```

Copier la ligne `SHA-256` de la variante `debug`. Console → ⚙️ Paramètres du
projet → *Vos applications* → l'app Android → **Ajouter une empreinte**.

Sans ça, Play Integrity n'a rien à quoi rattacher l'application.

**2. Enregistrer Play Integrity.**

Console → **App Check** → l'app Android → le `+` en face de **Play Integrity** →
Enregistrer. Ignorer reCAPTCHA Enterprise : c'est un repli en *preview* pour les
appareils sans services Play.

**3. Obtenir un jeton de débogage.**

C'est l'étape qui manque toujours, alors voici pourquoi elle existe.

Play Integrity demande à Google Play de confirmer que l'application est une
installation authentique **venant de Play**. Sur un émulateur, ou sur un APK posé
par `flutter run`, il n'y a rien à confirmer : le verdict échoue, et il *doit*
échouer — c'est exactement ce contre quoi App Check protège.

En développement, on utilise donc un **fournisseur de débogage**, déjà en place
dans [`firebase_backend.dart`](../lib/core/backend/firebase_backend.dart) :

```dart
providerAndroid: kDebugMode
    ? const AndroidDebugProvider()
    : const AndroidPlayIntegrityProvider(),
```

Lancer l'app une fois, puis lire le jeton dans les logs :

```bash
adb logcat -d | grep -i "debug secret"
```

Depuis Android Studio, c'est la fenêtre **Logcat** avec `debug secret` dans le
filtre. La ligne ressemble à :

```
DebugAppCheckProvider: Enter this debug secret into the allow list in
the Firebase Console for your project: 1a2b3c4d-....
```

**4. Enregistrer ce jeton.**

Console → App Check → l'app Android → menu **⋮** → *Gérer les jetons de
débogage* → Ajouter. Relancer l'application : l'envoi passe.

### Ce qu'il ne faut pas faire avec un jeton de débogage

Il **contourne** l'attestation, et vaut pour n'importe quel appareil qui le
possède. Il ne va donc ni dans le dépôt, ni dans un canal d'équipe, ni dans une
capture d'écran. Un par machine de développement, révoqué quand la machine
change de mains, et tous révoqués avant la mise en production.

### Plus tard

- Le jour où une vraie clé de signature de *release* est créée, ajouter son
  SHA-256 aussi. `android/app/build.gradle.kts` signe encore les builds release
  avec la clé de debug ; sinon l'application publiée échoue à l'attestation
  alors que tout marchait en test.
- Play Integrity ne devient réel qu'une fois une build déposée sur une piste de
  test interne du Play Console.
- Vérifier dans **App Check → Métriques** que les requêtes vérifiées montent
  avant de compter dessus. Le tableau distingue vérifiées, non vérifiées, et
  celles venues d'un jeton de débogage.
- Sur iOS : DeviceCheck, ou App Attest sur iOS 14+.

Les émulateurs Firebase n'appliquent pas App Check : `npm run test:emulator` et
tout le développement local contre émulateur sont indifférents à tout ceci.

---

## 11. Étape 5 — le suivi

`trackReport` est en place, et l'écran de suivi passe par le serveur : un
signalement se retrouve désormais après avoir fermé l'application, ce qui n'a
jamais été vrai jusqu'ici.

**Quatre issues, tenues séparées.** C'est le point de conception de cette étape :

| Issue | Ce que voit l'utilisateur |
|---|---|
| trouvé | le statut, la date, le type, l'urgence |
| introuvable | « aucun dossier ne correspond » |
| mal formé | « ce numéro n'a pas le bon format » — sans appel serveur |
| indisponible | « impossible de vérifier pour le moment… **ton dossier n'a pas disparu** » |

Les deux dernières lignes existent pour la même raison : un enfant qui a
signalé quelque chose de grave et qui lit « aucun dossier ne correspond » en
conclut que son signalement s'est évaporé. Ça ne doit pouvoir arriver que quand
c'est vrai — jamais parce que le réseau est tombé, ni parce qu'il a mal recopié.

**Un statut inconnu n'est pas deviné.** `enumByName` rend `null` plutôt que de
lever, et l'écran affiche une phrase neutre. Un backend qui gagne un statut ne
casse donc pas les applications déjà installées.

### Ce qui reste

- **Étape 6** — console équipe. Sans elle, un dossier reste éternellement
  `received` : personne ne peut faire passer un statut à `inReview`.
- **Conservation** — la politique TTL sur `reports` attend une durée du CMRPI.
- **Notifications** — FCM, pour prévenir d'un changement de statut sans que
  l'utilisateur ait à revenir vérifier. Utile précisément parce que le suivi est
  la seule chose qu'il puisse faire en attendant.

---

## 12. Étape 6 — la console, la conservation, les notifications

### La console

Une page statique sur Firebase Hosting (`console/`), sans framework ni étape de
construction. `npm run console` écrit sa configuration — voir §17.

**Le dessin suit le travail**, pas l'inverse. Quelqu'un s'assied là une heure
d'affilée pour lire des récits d'enfants menacés et décider quoi traiter en
premier. Trois règles en découlent :

- **L'urgence et l'échéance se lisent sans lire.** Ce sont les deux seules
  questions du triage, et elles occupent les deux marges de chaque ligne : un
  rail à gauche dont la couleur *et* l'épaisseur encodent l'urgence — donc
  lisible sans distinguer les couleurs — et le compte à rebours de conservation
  à droite, en rouge sous sept jours.
- **Ce qui identifie ou date un dossier est en chasse fixe ; ce qui le décrit
  est en linéale.** La règle encode quelque chose de vrai : ceci est un
  registre, et un numéro de dossier n'est pas une phrase.
- **Rien ne célèbre.** Pas de dégradé, pas de relief, une seule animation —
  l'ouverture d'un dossier. Une interface qui aurait l'air « designée » au-dessus
  du récit d'une agression serait indécente.

Le bleu est échantillonné dans le badge EMC (`#26368F`). Le contraste le plus
faible de la palette est de 4,56:1, au-dessus du seuil AA — le gris discret
porte les métadonnées en 11,5 px, et un gris plus clair tombait à 3,34.

**La ligne d'audit est montrée à l'agent lui-même**, à chaque ouverture, dans le
même registre typographique que le reste du dossier. Pas un avertissement : un
fait. Les gens qui lisent ces récits sont ceux dont l'accès est au registre.

**Ouvrir par numéro de référence.** Un champ en tête de file résout le code que
son auteur dicte au téléphone. Sans lui, un agent ne pouvait pas aider quelqu'un
qui appelle : le code est stocké haché, donc introuvable à l'œil. C'est le
moment pour lequel tout le produit existe, et il manquait.

**Les agents ne touchent pas Firestore non plus.** Les règles restent à `false`
pour tout le monde, et la console passe par des fonctions appelables. Ce n'est
pas de la cohérence pour la cohérence : c'est ce qui rend le journal d'audit
inévitable. Avec un accès direct par règles, « qui a ouvert quel dossier »
dépendrait de la discipline de qui écrit le client.

**La file ne contient ni récit, ni preuves, ni coordonnées.** Ouvrir un dossier
est un acte distinct, journalisé avec l'adresse de l'agent, et l'écran le dit.
Faire défiler une liste ne doit pas revenir à lire vingt récits d'enfants.

Les captures s'affichent via des URL signées valables quinze minutes : la
console montre les preuves, elle ne les publie pas.

**L'accès se donne en ligne de commande**, jamais depuis la console :

```bash
npm --prefix functions run grant-agent -- grant agent@cmrpi.ma
npm --prefix functions run grant-agent -- list
npm --prefix functions run grant-agent -- revoke agent@cmrpi.ma
```

Un compte qui peut promouvoir des comptes est un compte qui vaut la peine d'être
volé. Le script refuse une adresse non vérifiée — `requireAgent` la refuserait
aussi, et un compte qui *paraît* autorisé sans l'être est pire qu'un refus
franc. La révocation invalide les jetons de rafraîchissement, sinon le retrait
d'accès attendrait l'expiration du jeton, jusqu'à une heure.

### Les notifications

**Le point de conception, avant la technique :** une notification est la seule
chose que cette application fasse **sans qu'on la lui demande**, sur un écran
verrouillé, devant qui tient le téléphone. Le public visé partage souvent son
appareil, parfois avec la personne qu'il signale.

Trois règles en découlent, et elles sont testées :

1. **Désactivé tant que ce n'est pas explicitement accepté.** Aucune demande de
   permission au lancement. L'écran qui propose affiche l'avertissement
   **au-dessus** du bouton, pas en petits caractères en dessous : celui qui
   décide doit l'avoir lu, pas seulement avoir pu le lire.
2. **Le message ne dit rien.** Ni statut, ni numéro, ni même le mot
   « signalement ». Qui lit l'écran verrouillé apprend qu'une application a
   envoyé un message. Le reste demande d'ouvrir l'app avec un numéro qu'il n'a
   pas.
3. **Aucun appareil n'est enregistré en face d'un dossier.** L'abonnement se
   fait à un sujet FCM dérivé du hachage de la référence — jamais du code en
   clair. Le serveur n'apprend pas quels appareils écoutent et ne stocke aucun
   jeton à côté d'un signalement. Le lien entre ce téléphone et ce dossier
   n'existe que sur ce téléphone.

Le serveur publie vers les trois sujets de langue (`case_{hash}_{fr|ar|en}`)
parce qu'il ignore lequel l'appareil a choisi — et refuse délibérément de
l'apprendre. Deux envois sur trois n'atteignent personne, ce qui ne coûte rien
et ne stocke rien.

**Activer demande un numéro de référence, donc ne peut se faire que là où il est
affiché** — l'application ne le garde jamais. **Désactiver ne demande rien** :
jeter le jeton FCM annule d'un coup tous les sujets auxquels l'appareil était
abonné, sans que l'application ait eu à noter lesquels. C'est ce qui permet à
l'interrupteur des Paramètres d'exister sans qu'une liste des dossiers suivis
traîne sur un téléphone partagé.

### Ce qui reste à faire en console

Complète la liste du §9 :

- **Politique TTL Firestore** sur `reports.expiresAt`, `referenceIndex.expiresAt`,
  `idempotency.expiresAt`, `rateLimits.expiresAt`.
- **Règle de cycle de vie Cloud Storage** sur `evidence/`, ~35 jours. Elle
  rattrape ce que `onReportDeleted` ne voit pas : un téléversement dont le
  signalement n'a jamais été envoyé est orphelin dès sa naissance, et aucun
  document ne sera jamais supprimé pour déclencher son nettoyage.
- **Notifications** : activer Cloud Messaging. Sur iOS, il faut en plus une clé
  APNs — sans elle les notifications ne fonctionnent que sur Android.
- **Comptes agents** : les créer dans Authentication, faire vérifier l'adresse,
  puis `grant-agent`.
- **Hosting** : `firebase deploy --only hosting` après avoir écrit
  `console/config.js`.

---

## 13. Facturation

### Le mode de la base n'a rien à voir avec la facturation

« Mode test » et « mode production » ne choisissent **qu'un fichier de règles de
départ** :

| Mode | Règles écrites par la console |
|---|---|
| test | `allow read, write: if true;` pendant 30 jours |
| production | `allow read, write: if false;` |

Ni l'un ni l'autre ne coûte quoi que ce soit, et `firestore.rules` remplace les
deux au premier déploiement. Choisir « test » pour éviter la facturation ne
marche pas : le mur arrive au même endroit, un cran plus loin.

### Ce qui exige vraiment le plan Blaze

**Les Cloud Functions.** Elles ne se déploient pas sur le plan gratuit, quelle
que soit la base. Or tout le backend en est fait : `submitReport`, `trackReport`,
`requestEvidenceUploadUrl`, la console. Cloud Storage aussi, sur les projets
récents.

Firestore seul fonctionne sur le plan gratuit. **La base peut donc être créée
aujourd'hui, en mode production, sans carte** — et tout le développement local se
fait contre les émulateurs, qui ne coûtent rien et ne demandent rien. Blaze
n'est nécessaire qu'au moment de déployer.

### Ce que Blaze coûte pour cette application

Blaze est du paiement à l'usage **avec les quotas gratuits du plan gratuit
inclus**. Ce n'est pas un abonnement : en dessous des seuils, la facture est de
zéro.

Les ordres de grandeur (à revérifier sur la page tarifaire, ils bougent) : ~2
millions d'invocations de fonction par mois, ~50 000 lectures et ~20 000
écritures Firestore par jour, quelques Go de stockage. Une ligne d'assistance
qui traite quelques centaines de signalements par mois n'en atteint aucun.

Les 30 $ sont selon toute vraisemblance une **empreinte de vérification de
carte**, pas un prélèvement : Google autorise un montant puis le relâche sous
quelques jours. À vérifier sur l'écran, qui doit parler d'autorisation
temporaire. Les nouveaux comptes Google Cloud reçoivent en général un crédit
d'essai qui couvre largement cette phase.

### Ce qui empêche la facture de s'emballer

C'est la vraie question, et elle mérite mieux qu'un espoir.

- **`maxInstances: 10`** dans `index.ts` : les fonctions ne peuvent pas se
  démultiplier indéfiniment sous une charge anormale.
- **Mémoire à 256 Mio, délais courts** : une invocation coûte le minimum.
- **Limitation de débit** par appareil sur les trois points d'entrée publics.
- **App Check**, qui prend ici un second sens : sans lui, un script bouclant sur
  `submitReport` génère des invocations facturables autant qu'il génère de faux
  signalements. C'est un argument de coût autant que de sécurité.

À faire en plus, dans la console Google Cloud → *Facturation* → *Budgets et
alertes* : un budget de quelques euros avec alerte par e-mail à 50 % et 100 %.
Une alerte ne coupe rien, mais elle prévient avant la surprise.

### À qui appartient le compte de facturation

**Au CMRPI, pas à un développeur.** Ce n'est pas une question de confort : le
compte de facturation détient les données. Celui qui le ferme, le laisse expirer
ou perd sa carte emporte avec lui les signalements en cours et les preuves qui
vont avec.

L'organisation qui répond de ces données devant la CNDP et devant les familles
est aussi celle qui doit tenir l'infrastructure. Un compte personnel convient
pour la phase de développement, où rien de réel ne transite ; il ne convient pas
au jour où l'application reçoit son premier vrai signalement.

### S'il est vraiment impossible d'ouvrir un compte de facturation

L'architecture peut être déplacée : un service Node avec `firebase-admin` sur un
hébergeur à offre gratuite, parlant à Firestore resté sur le plan gratuit. Les
fonctions sont écrites en gestionnaires HTTP simples, donc le portage est
modeste. En revanche il faudrait un autre stockage d'objets pour les preuves, et
la clé de compte de service devient un secret à gérer — ce que les Cloud
Functions évitaient. À ne faire que si Blaze est hors d'atteinte.

---

## 14. Faire tourner le workflow complet en local

Sans compte de facturation, sans App Check, sans rien déployer.

### Deux mots « émulateur », deux choses différentes

C'est la confusion à lever avant tout le reste :

- **L'émulateur Android** — le faux téléphone que `flutter run` allume. Il fait
  tourner l'application.
- **Les émulateurs Firebase** — un faux Firebase qui tourne sur le portable. Ils
  font tourner le backend : les fonctions, la base, le stockage.

Les deux n'ont rien à voir. Il en faut **deux à la fois** : le faux Firebase
d'abord, le faux téléphone ensuite.

### Où atterrit un signalement

```
      MODE LOCAL                            APRÈS DÉPLOIEMENT
      npm run backend                       npx firebase deploy

  ┌─────────────────┐                    ┌─────────────────┐
  │   application   │                    │   application   │
  └────────┬────────┘                    └────────┬────────┘
           │ USE_EMULATORS=true                   │ (par défaut)
           ▼                                      ▼
  ┌─────────────────┐                    ┌─────────────────┐
  │ Firebase émulé  │                    │ Firebase, chez  │
  │ sur le portable │                    │     Google      │
  └─────────────────┘                    └─────────────────┘
   visible sur                            visible dans la
   127.0.0.1:4000                         console Firebase
   disparaît à l'arrêt                    persiste
   gratuit                                plan Blaze
```

Un signalement déposé en mode local **est réellement enregistré** — dans la base
émulée, sur le portable. Il n'apparaît **pas** dans la console Firebase en
ligne : ce sont deux bases distinctes, et rien ne circule de l'une à l'autre.

**Terminal 1** — le backend :

```bash
npm run backend
```

L'interface s'ouvre sur `http://127.0.0.1:4000` : on y voit les documents
Firestore apparaître en direct, et les logs de chaque fonction appelée.

**Terminal 2** — l'application, pointée dessus :

```bash
flutter run --dart-define=USE_EMULATORS=true
```

**Il faut un vrai émulateur Android (AVD)**, ou un téléphone physique.
`10.0.2.2` n'est pas une convention générale : c'est l'émulateur d'AVD qui
réécrit cette adresse vers le loopback de la machine hôte. Les extensions
d'aperçu mobile qui affichent l'application sans AVD dessous ne font pas cette
traduction, et le portable reste inatteignable — l'envoi échoue alors sans que
rien ne le dise, puisque le backend ne voit jamais la requête.

Sur un téléphone physique, passer l'adresse de la machine sur le réseau local
avec `--dart-define=EMULATOR_HOST=192.168.1.24`.

**Depuis Android Studio**, le `--dart-define` ne s'ajoute pas tout seul : la
configuration « main.dart » du menu déroulant ne passe aucun argument et
s'adresse au vrai projet Firebase, où rien n'est déployé. Choisir
**« main.dart (émulateurs) »**, versionnée dans `.idea/runConfigurations/`.

C'est le piège le plus coûteux de cette étape, parce qu'il ne ressemble pas à
une erreur de configuration : l'application démarre normalement et n'échoue
qu'à l'envoi.

Sur un téléphone physique plutôt qu'un émulateur Android, ajouter l'adresse de
la machine sur le réseau local :

```bash
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=192.168.1.24
```

Ce qui fonctionne alors de bout en bout : le signalement part vraiment,
`submitReport` s'exécute vraiment, le document apparaît dans Firestore, le
numéro de référence revient, et l'écran de suivi le retrouve. Les émulateurs
n'appliquent pas App Check et acceptent la connexion anonyme sans configuration
de console.

Rien n'est écrit dans le vrai projet, et tout disparaît à l'arrêt des
émulateurs.

### Si l'envoi échoue quand même

L'application dit à quel backend elle parle, dès le démarrage. Dans la console
de `flutter run` :

```
Backend: émulateurs Firebase sur 10.0.2.2.
```

Si c'est plutôt `Backend: projet Firebase en ligne`, le `--dart-define` n'a pas
été pris : l'application s'adresse au vrai projet, où rien n'est déployé.

Au lancement, trois lignes de diagnostic testent chaque maillon séparément —
connexion anonyme, jeton d'identité, et un POST HTTP brut vers l'émulateur sans
SDK au milieu :

```
Diag 1/3 auth anonyme : OK, uid=...
Diag 2/3 jeton d'identité : OK (900 car.)
Diag 3/3 émulateur de fonctions joignable : HTTP 200
```

Leur absence complète veut dire que le mode émulateurs n'est pas actif.

En cas d'échec, la console affiche la vraie erreur **et le backend visé**, à
côté du message volontairement vague que voit l'utilisateur :

```
Envoi échoué [not-found] — projet Firebase en ligne (emc-helpline-e82ef)
```

Le mode est répété là plutôt qu'au seul démarrage : une ligne de lancement sort
du journal bien avant qu'on appuie sur « Envoyer », et « à quel backend
parlait-il, au juste » est la première chose à savoir.

| Code | Ce que ça veut dire |
|---|---|
| `not-found` | la fonction n'est pas déployée — mode en ligne sans `firebase deploy` |
| `unauthenticated` | App Check ou la connexion anonyme a été refusée |
| `unavailable` | rien au bout : émulateurs éteints, ou mauvaise adresse |

**App Check est appliqué dans l'émulateur.** C'est contre-intuitif et ça m'a
coûté trois diagnostics faux : `enforceAppCheck` n'est pas une vérification
côté Google que les émulateurs sauteraient, c'est `firebase-functions` qui
l'applique lui-même, dans le processus. Un appel local se voyait donc répondre
`401 UNAUTHENTICATED` quelle que soit la qualité du jeton d'authentification.
`ENFORCE_APP_CHECK` le désactive sur la seule foi de `FUNCTIONS_EMULATOR`, que
rien en production ne peut poser.

**L'identifiant de projet doit être celui de l'application.** Les émulateurs
servent leurs fonctions sous `/{projectId}/{region}/{nom}`. Démarrés sous
`demo-emc` alors que l'application est `emc-helpline-e82ef`, ils n'exposent
tout simplement pas l'URL qu'elle appelle. `npm run backend` prend donc le
projet de `.firebaserc` — le même que `firebase_options.dart`.

**Le trafic en clair.** Les émulateurs parlent en HTTP, qu'Android bloque par
défaut depuis `targetSdk` 28. `android/app/src/debug/res/xml/network_security_config.xml`
lève ce blocage **dans les builds de debug uniquement** — le fichier vit dans
`src/debug/` et n'entre dans aucun build de release. Sans lui, `USE_EMULATORS`
ne peut pas fonctionner et l'échec ne dit pas pourquoi.

### Les captures, en local

Signer une URL demande un vrai compte de service — un `client_email` et une clé
privée — que la suite d'émulateurs n'a pas. `getSignedUrl` y échoue sur
`Cannot sign data without client_email`, et **cela se voyait comme une panne
intermittente** : un signalement avec un lien passait, un signalement avec une
capture échouait, sans que rien ne dise pourquoi.

`requestEvidenceUploadUrl` renvoie donc, dans l'émulateur, l'adresse de son
propre point d'envoi et le jeton d'administration `owner` qu'il accepte. Ce
jeton ne vaut rien ailleurs, et cette branche ne peut pas s'exécuter en
production : elle dépend de `FUNCTIONS_EMULATOR`, que rien n'y pose.

**L'URL est réécrite par le client, pas par le serveur.** La fonction voit
l'émulateur sur sa propre boucle locale, `127.0.0.1` — mais cette URL part vers
le téléphone, où `127.0.0.1` désigne le téléphone. Le seul côté qui sache
comment cet appareil joint la machine hôte, c'est cet appareil :
`reachableFromDevice()` remplace la boucle locale par `emulatorHost`. Hors mode
émulateur elle ne touche à rien — l'URL est signée, et changer un caractère
invaliderait la signature.

C'est la même erreur que `10.0.2.2` deux sections plus haut, sous une autre
forme, et elle mérite d'être énoncée en règle : **une URL n'est utile qu'à
l'adresse de celui qui va l'appeler.**

**La lecture a le même problème que l'envoi.** `getReport` demande une URL
signée par capture pour que la console les affiche ; l'émulateur ne sait pas
signer là non plus, et ouvrir un dossier portant une capture répondait un
`INTERNAL` nu. `evidenceReadUrl()` centralise les deux cas : URL signée de
quinze minutes en production, jeton de téléchargement de l'émulateur en local —
la seule forme qu'un `<img>` sait utiliser, puisqu'il ne peut pas envoyer
d'en-tête d'autorisation.

Une autre conséquence à connaître : **l'émulateur enregistre tout en
`application/octet-stream`**, quel que soit le type déclaré. La vérification du
type MIME est donc sautée en local — sinon elle rejetterait chaque capture — et
`evidenceReadUrl` remet le type d'aplomb au passage, pour qu'une console locale
serve ses images comme le ferait celle déployée. Le
contrôle qui compte, lui, tourne partout : le chemin doit appartenir au dossier
que la clé d'idempotence dérive.

---

## 15. Ce que fait `firebase deploy`

La commande lit `firebase.json` et envoie chaque partie à son service :

| Partie | Destination | Plan requis |
|---|---|---|
| `firestore.rules` | règles Firestore | gratuit |
| `firestore.indexes.json` | index Firestore | gratuit |
| `storage.rules` | règles Cloud Storage | gratuit |
| `functions/` | Cloud Functions | **Blaze** |
| `console/` | Firebase Hosting | gratuit |

Chaque partie se déploie séparément :

```bash
npx firebase deploy --only firestore:rules
npx firebase deploy --only functions
npx firebase deploy --only hosting
npx firebase deploy --only functions:submitReport
```

**Les règles se déploient dès maintenant, gratuitement.** C'est même la première
chose à faire une fois la base créée : la console a écrit ses règles par défaut,
et `firestore.rules` porte les commentaires qui expliquent pourquoi tout est
fermé.

Pour les fonctions, `deploy` lance d'abord `npm run build` (déclaré en
`predeploy`), refuse de continuer si TypeScript ne compile pas, téléverse le
code, puis remplace chaque fonction. Le remplacement n'est pas atomique entre
fonctions : pendant une trentaine de secondes, certaines répondent en ancienne
version et d'autres en nouvelle. Sans importance ici, à savoir le jour où un
changement touche le contrat entre deux d'entre elles.

`deploy` ne touche ni aux données, ni aux comptes, ni aux politiques TTL, ni aux
réglages App Check. Tout cela vit dans la console et n'est pas dans le dépôt.

---

## 16. Le test qui valide le parcours

`functions/test/workflow.test.ts` appelle les fonctions **par HTTP**, avec un
vrai jeton de l'émulateur d'authentification — exactement comme le fait un
client, enveloppe des appelables et vérification d'authentification comprises.

```bash
npm run test:workflow
```

Les autres suites appellent `submitReportCore` et `trackReportCore` en direct,
ce qui saute tout ce qu'il y a autour. C'est utile pour la logique, et
insuffisant : les deux pannes qui ont bloqué la première mise en route locale —
App Check appliqué dans l'émulateur, et l'identifiant de projet qui ne
correspondait pas — étaient toutes deux invisibles à ce niveau, et toutes deux
apparaissent immédiatement ici.

**La ligne de partage qu'il trace :** si cette suite passe et que l'application
échoue quand même, le problème est dans le téléphone, pas dans le backend.

Pour viser une instance déjà démarrée plutôt que d'en lancer une :

```bash
EMULATOR_PROJECT_ID=emc-helpline-e82ef \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
npx vitest run functions/test/workflow.test.ts
```

---

## 17. Ouvrir la console en local

Trois commandes, une fois pour toutes.

```bash
npm run backend          # terminal 1, laissé ouvert
npm run console          # terminal 2 : config + compte agent
```

**Les émulateurs conservent leurs données** entre deux démarrages, dans
`.emulator-data` (ignoré par git). Sans cela ils repartent vides à chaque
lancement : le compte agent disparaît — la connexion répond « adresse ou mot de
passe incorrect » alors que rien n'a changé — et les signalements de test avec.

Une réserve : l'export se fait **en quittant**, donc quitter par `Ctrl-C`. Un
`kill` brutal n'exporte rien, et il faut alors relancer `npm run console:agent`,
qui est idempotent.

`npm run console` enchaîne deux choses :

- **`console:config`** écrit `console/config.js` à partir de
  `lib/firebase_options.dart`. Les deux doivent désigner le même projet — la
  console lit ce que l'application dépose — et recopier ces valeurs à la main,
  c'est se garantir une divergence au prochain `flutterfire configure`. Une
  console qui pointe vers un projet vide ressemble à une console cassée.
- **`console:agent`** crée `agent@cmrpi.ma` / `console-locale` dans l'émulateur,
  marque l'adresse vérifiée et pose le claim `role: agent`.

Puis **http://127.0.0.1:5000** — l'émulateur d'hébergement annonce son port à
son démarrage s'il a dû en prendre un autre.

La console détecte qu'elle est servie depuis `localhost` et se branche
elle-même sur les émulateurs d'authentification et de fonctions. Le test porte
sur l'hôte plutôt que sur un drapeau : une console déployée n'est jamais servie
depuis localhost, elle ne peut donc pas basculer par accident. Un badge
« émulateurs » apparaît à côté de l'adresse connectée.

### Le compte agent en production

Rien de ce qui précède ne s'applique au vrai projet. Là-bas :

1. Créer le compte dans Authentication, faire vérifier l'adresse.
2. `npm --prefix functions run grant-agent -- grant adresse@cmrpi.ma`

`grant-agent` refuse une adresse non vérifiée, parce que `requireAgent` la
refuserait aussi et qu'un compte qui *paraît* autorisé sans l'être est pire
qu'un refus franc. La révocation invalide les jetons de rafraîchissement, sinon
le retrait d'accès attendrait l'expiration du jeton — jusqu'à une heure.

### Ce que les tests couvrent

`functions/test/consoleWorkflow.test.ts` appelle les fonctions de la console par
HTTP avec un vrai jeton d'agent. Il vérifie ce qu'aucune autre suite ne
couvre : **`requireAgent`**. Ces fonctions sont les seules à lire le contenu
d'un signalement, et la seule chose qui en tient la porte est un claim sur un
compte — une suite appelant les fonctions cœur en direct sauterait précisément
ce contrôle.

Il vérifie aussi que la file ne laisse fuir ni récit, ni pseudo, ni téléphone,
et que faire avancer un dossier repousse bien son expiration.

**Un piège du SDK web** y est verrouillé : il sérialise `undefined` en `null`.
Un filtre vide part donc en `{status: null}`, et un schéma Zod en `.optional()`
— qui n'accepte que l'absence — rejetait la requête la plus banale qui soit,
celle de la page au premier chargement. Les champs facultatifs des fonctions de
la console sont en `.nullish()` pour cette raison.
