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
4. Créer la base Firestore en région `europe-west1`.
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

`submitReport` est déclaré `enforceAppCheck: true`. Toute requête sans jeton
valide reçoit `unauthenticated`, **quel que soit l'état de la console** : pour
une fonction appelable, l'application se décide dans le code, pas dans le
tableau de bord. Le mode « non appliqué » de la console concerne Firestore et
Storage, auxquels le client n'a de toute façon pas accès ici.

Conséquence : tant que la configuration ci-dessous n'est pas faite, l'appel
échoue. C'est voulu, mais ça se prend en pleine figure au premier essai.

### Le fournisseur : Play Integrity

Sur Android, c'est **Play Integrity**. reCAPTCHA Enterprise y est un repli en
*preview* pour les appareils sans services Play — inutile ici. Sur iOS, ce sera
DeviceCheck, ou App Attest sur iOS 14+.

**Prérequis : l'empreinte SHA-256 de la clé de signature**, dans Paramètres du
projet → Vos applications → Android → Ajouter une empreinte. Sans elle,
l'enregistrement du fournisseur ne sert à rien.

```bash
cd android && ./gradlew signingReport
```

Noter que `android/app/build.gradle.kts` signe encore les builds *release* avec
la clé de *debug*. Le jour où une vraie clé de release est créée, son SHA-256
devra être ajouté aussi — sinon l'app publiée échoue à l'attestation alors que
tout marchait en test.

### Le piège : Play Integrity ne marche pas en développement

L'attestation demande à Google Play de confirmer que l'app est une installation
authentique, depuis Play. Sur un émulateur, ou sur un APK installé par
`flutter run`, il n'y a rien à confirmer : le verdict échoue, et il *doit*
échouer — c'est exactement ce contre quoi App Check protège.

Play Integrity ne devient donc réel qu'une fois l'application déposée sur une
piste de test interne du Play Console. D'ici là, développer avec le
**fournisseur de débogage** :

```dart
await FirebaseAppCheck.instance.activate(
  // Le fournisseur de débogage n'existe que dans les builds de debug. En
  // release, Play Integrity, sans condition ni repli — un repli serait
  // précisément la porte que App Check ferme.
  androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
);
```

Au premier lancement, l'app imprime un jeton de débogage dans les logs :

```bash
flutter run 2>&1 | grep -i "Enter this debug secret"
```

Ce jeton se colle dans la console : App Check → l'application → menu ⋮ →
**Gérer les jetons de débogage**. Il reste valide jusqu'à révocation.

**Un jeton de débogage contourne l'attestation.** Il vaut pour n'importe quel
appareil qui le possède, donc il ne se met ni dans le dépôt, ni dans un canal
d'équipe, ni dans une capture d'écran. Un par machine de développement, révoqué
quand la machine change de mains.

### Ordre praticable

1. Enregistrer Play Integrity dans la console (l'empreinte SHA-256 d'abord).
2. Développer avec le fournisseur de débogage — c'est ce qui débloque l'étape 3.
3. Déposer une build sur la piste de test interne du Play Console.
4. Vérifier dans App Check → Métriques que les requêtes vérifiées montent avant
   de compter dessus. Les métriques distinguent les requêtes vérifiées, non
   vérifiées et venant d'un jeton de débogage.
5. Révoquer les jetons de débogage avant la mise en production.

Les émulateurs Firebase n'appliquent pas App Check, donc `npm run test:emulator`
et tout le développement local contre émulateur sont indifférents à tout ceci.

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

Une page statique sur Firebase Hosting (`console/`), sans framework. Copier
`config.example.js` en `config.js` et y mettre la config web du projet.

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
