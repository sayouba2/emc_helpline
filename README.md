# EMC Helpline

Application mobile de signalement des violences numériques visant les enfants,
les jeunes et les femmes au Maroc, développée en partenariat avec le CMRPI.

Un signalement se dépose sans compte et sans donner son nom. En échange, son
auteur reçoit un **numéro de référence** — la seule chose qui relie une personne
à son dossier. L'équipe traite les dossiers depuis une console web séparée.

L'interface existe en **français, arabe et anglais**. En arabe, toute
l'interface est mise en miroir, pas seulement le texte.

---

## Trois parties

| | Où | Quoi |
|---|---|---|
| **Application** | `lib/` | Flutter, Android et iOS |
| **Backend** | `functions/` | Cloud Functions en TypeScript, Firestore, Cloud Storage |
| **Console équipe** | `console/` | Page statique, Firebase Hosting |

L'application ne parle jamais à Firestore directement : les règles refusent tout
à tout le monde, et chaque accès passe par une fonction appelable.

---

## Démarrer

Il faut Flutter 3.x, Node 22 et Java (pour les émulateurs Firebase).

```bash
flutter pub get
npm install && npm install --prefix functions
```

### L'application seule

```bash
flutter run
```

Sans backend joignable, un build de debug tourne sur une simulation locale : les
écrans fonctionnent, mais rien n'est envoyé nulle part. La console de `flutter
run` le dit au démarrage.

### Le parcours complet, en local

Deux terminaux. Le backend d'abord :

```bash
npm run backend
```

Puis l'application, pointée dessus :

```bash
flutter run --dart-define=USE_EMULATORS=true
```

Un signalement est alors réellement écrit, reçoit un vrai numéro de référence, et
l'écran de suivi le retrouve — dans une base qui vit sur la machine, visible sur
`http://127.0.0.1:4000`. Aucun compte de facturation, aucune donnée réelle.

Sur un téléphone physique plutôt qu'un émulateur Android, ajouter l'adresse de la
machine : `--dart-define=EMULATOR_HOST=192.168.1.24`. L'adresse par défaut,
`10.0.2.2`, n'est traduite que par l'émulateur Android d'AVD.

### La console

```bash
npm run console      # écrit console/config.js et crée un compte agent local
```

Puis `http://127.0.0.1:5000`, avec `agent@cmrpi.ma` / `console-locale`.

Les émulateurs conservent leurs données dans `.emulator-data`, mais l'export se
fait **en quittant** : sortir par `Ctrl-C`. Après un arrêt brutal, relancer
`npm run console:agent`.

---

## Vérifications

```bash
flutter analyze && flutter test && dart format --output=none --set-exit-if-changed lib test
```

```bash
npm run check        # typecheck TypeScript + suites backend contre les émulateurs
```

180 tests côté application, 103 côté backend. Les mêmes commandes tournent en CI
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

---

## Organisation

```
lib/
├── core/
│   ├── backend/       démarrage Firebase, envoi, téléversement, notifications
│   ├── constants/     couleurs, styles, numéros d'urgence
│   ├── localization/  libellés des enums métier
│   ├── storage/       préférences (langue, notifications)
│   └── utils/         numéro de référence, validateurs, liens
├── l10n/              app_fr.arb, app_ar.arb, app_en.arb
├── models/            ReportModel et enums métier
├── providers/         ReportProvider : état du wizard, validation, envoi
└── views/             écrans et composants partagés

functions/src/
├── config.ts          valeurs partagées : région, limites, conservation
├── schema.ts          contrat de transport + revalidation serveur
├── referenceCode.ts   génération et normalisation du numéro
├── submitReport.ts    dépôt, transaction, idempotence
├── trackReport.ts     suivi par numéro
├── evidence.ts        URL de téléversement et de lecture
├── console.ts         fonctions réservées aux agents
└── retention.ts       suppression des preuves avec le dossier
```

### Ce qu'il faut savoir avant de modifier

**Les noms des membres d'enum sont un contrat.** `IncidentType.threat` voyage
tel quel jusqu'à `functions/src/schema.ts`. Renommer un membre d'un seul côté
casse l'envoi ; `test/backend_contract_test.dart` lit le fichier TypeScript et
échoue si les deux listes divergent.

**Rien du contenu d'un signalement n'est écrit sur l'appareil** — ni pseudo, ni
coordonnées, ni preuves, ni historique. L'application vise des enfants qui
partagent souvent leur téléphone, parfois avec la personne qu'ils signalent. Un
test vérifie qu'aucune donnée de signalement n'atteint le disque.

**Le thème est clair uniquement.** Pas de variante sombre, nulle part.

**Le numéro de référence n'est jamais stocké en clair.** Son empreinte SHA-256
sert de clé de recherche. Un code perdu est un dossier perdu, et c'est le prix
de l'anonymat.

---

## Règles du formulaire

Trois règles ne se devinent pas à la lecture du code.

**Les preuves ne peuvent pas être passées à vide.** Il faut au moins une
capture, un lien, **ou** un récit d'au moins 120 caractères. Le récit tient lieu
de preuve parce que le cas le plus grave est souvent celui où l'agresseur a
effacé les traces.

**La fin du parcours dépend de la réponse à « Veux-tu de l'aide ? ».**

| Réponse | Type d'aide | Coordonnées |
|---|---|---|
| Accompagnement | demandée | pseudo + téléphone, obligatoires |
| Je ne sais pas | sautée | sautées |
| Pas d'accompagnement | sautée | sautées |

**L'anonymat n'est pas un interrupteur mais une conséquence.** Le vrai nom n'est
demandé nulle part ; `ReportModel.isAnonymous` se déduit de l'absence de
coordonnées. Seuls un pseudo et un téléphone sont collectés.

---

## Déployer

Rien de ceci ne se fait depuis le dépôt. Dans la console Firebase :

1. Créer le projet, puis `firebase use --add`.
2. Activer **Authentication → Anonymous**.
3. Créer la base Firestore : **mode production**, région `europe-west1`. La
   région ne se change pas après coup.
4. Activer **App Check** avec Play Integrity, après avoir ajouté l'empreinte
   SHA-256 (`cd android && ./gradlew signingReport`). Play Integrity ne peut pas
   attester une application que Play n'a pas installée : en développement, il
   faut enregistrer un jeton de débogage, que l'application imprime dans ses logs
   au premier lancement.
5. Politiques TTL sur `reports.expiresAt`, `referenceIndex.expiresAt`,
   `idempotency.expiresAt`, `rateLimits.expiresAt`.
6. Règle de cycle de vie Cloud Storage sur `evidence/`, ~35 jours, pour les
   téléversements dont le signalement n'a jamais été envoyé.
7. Donner au compte de service d'exécution le rôle *Créateur de jetons du compte
   de service* sur lui-même — sans quoi les URL de téléversement ne peuvent pas
   être signées. Les émulateurs ne signent pas : ça ne se voit qu'en ligne.
8. Comptes agents : les créer, faire vérifier l'adresse, puis
   `npm --prefix functions run grant-agent -- grant adresse@cmrpi.ma`.

```bash
npx firebase deploy --only firestore:rules,storage:rules   # gratuit
npx firebase deploy --only functions                       # demande le plan Blaze
npx firebase deploy --only hosting
```

Les Cloud Functions exigent le plan Blaze — pas la base, ni les règles. Blaze
inclut les quotas gratuits : en dessous des seuils, la facture est nulle. Poser
tout de même une alerte de budget.

---

## État

| | |
|---|---|
| Dépôt d'un signalement, preuves comprises | fait |
| Suivi par numéro de référence | fait |
| Console équipe, journal d'audit | fait |
| Conservation 30 jours glissants | fait |
| Notifications | code en place, non testable sans déploiement |

Avant une mise en production, il reste trois choses qui ne relèvent pas du code :

- **Les textes juridiques** portent un marqueur `⚠️ À COMPLÉTER PAR LE CMRPI` sur
  les passages qui demandent un juriste. L'écran affiche un bandeau tant qu'ils
  sont là.
- **Les traductions arabe et anglaise n'ont pas été relues par un locuteur
  natif.** Pour une ligne d'assistance destinée à des enfants en détresse, le ton
  compte autant que l'exactitude.
- **Le compte de facturation doit appartenir au CMRPI**, pas à un développeur :
  qui le ferme emporte les signalements en cours.

## Limites connues

- L'assistant est simulé : réponses scriptées, aiguillage par mots-clés dans les
  trois langues. Une phrase qu'aucun mot-clé n'attrape tombe sur la réponse par
  défaut. Le badge BÊTA le signale.
- Le récapitulatif indique qu'un récit a été écrit sans l'afficher.
- La mise en page vise le portrait ; le paysage reste utilisable sans être
  soigné.
