# EMC Helpline

Application mobile Flutter de signalement des violences numériques visant les
enfants, les jeunes et les femmes au Maroc, en partenariat avec le CMRPI.

L'utilisateur remplit un formulaire en 11 étapes (contexte, profil, incident,
récapitulatif), peut rester totalement anonyme derrière un pseudo, et dispose en
permanence des numéros d'urgence — Police **19**, Gendarmerie **177**.

Interface disponible en **français, arabe et anglais**, avec mise en page
droite-à-gauche pour l'arabe.

---

## ⚠️ État actuel : version de démonstration

**Aucun signalement n'est transmis.** `ReportProvider.submitReport()` ajoute le
dossier à une liste en mémoire et génère un numéro de référence local ; il
n'existe pas encore de backend.

Tant que c'est le cas, l'application affiche un avertissement explicite sur
l'accueil et sur l'écran de confirmation, pour qu'un enfant en danger ne croie
pas avoir alerté quelqu'un. Ce bandeau disparaît lorsque le backend existe :

```bash
flutter build apk --dart-define=EMC_BACKEND_ENABLED=true
```

Le drapeau est défini dans [`lib/core/constants/app_contacts.dart`](lib/core/constants/app_contacts.dart).

## Démarrer

```bash
flutter pub get
flutter run
```

`flutter pub get` régénère `lib/l10n/app_localizations*.dart` à partir des
fichiers ARB ; ces fichiers générés ne sont pas versionnés.

## Vérifications

```bash
flutter analyze && flutter test && dart format --output=none --set-exit-if-changed lib test
```

Les mêmes commandes tournent en CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Architecture

```
lib/
├── core/
│   ├── constants/     couleurs, styles, numéros d'urgence, drapeau backend
│   ├── localization/  libellés localisés des enums métier
│   ├── storage/       préférences (langue) — voir « Données » ci-dessous
│   └── utils/         lancement d'appels/liens, validateurs
├── l10n/              app_fr.arb, app_ar.arb, app_en.arb (source des traductions)
├── models/            ReportModel (immuable) + enums métier
├── providers/         ReportProvider : état du wizard, validation, historique
└── views/             écrans et composants partagés
```

**Gestion d'état** : `provider` / `ChangeNotifier`. `ReportProvider` détient la
machine à états du wizard et la validation par étape ; les indices d'étapes sont
des constantes nommées (`ReportProvider.stepEvidence`…) pour éviter les
décalages.

**Valeurs métier** : ce sont des `enum`, jamais des chaînes. Traduire un libellé
ne peut donc pas casser la logique de branchement. Les libellés vivent dans
[`report_enum_labels.dart`](lib/core/localization/report_enum_labels.dart).

**Thème** : clair uniquement, volontairement. Une variante sombre a existé mais
était inatteignable et illisible sur les deux tiers des écrans.

## Traductions

Le français est la langue source. Pour modifier un texte, éditer
`lib/l10n/app_fr.arb` puis les deux autres, et relancer `flutter gen-l10n`.

> Les traductions **arabes et anglaises n'ont pas été relues par un locuteur
> natif**. Pour une ligne d'assistance destinée à des enfants en détresse, le ton
> compte autant que l'exactitude : une relecture est nécessaire avant mise en
> production, en particulier sur les messages du chatbot et les textes de
> réconfort.

## Données et vie privée

Seule la langue choisie est écrite sur l'appareil.

**Le contenu des signalements n'est jamais persisté** — ni pseudo, ni
coordonnées, ni preuves, ni historique. C'est délibéré : l'application vise des
enfants qui partagent souvent leur téléphone, parfois avec la personne qu'ils
signalent. Une trace lisible localement serait un risque, pas une fonctionnalité.
Un test (`test/settings_store_test.dart`) vérifie qu'aucune donnée de
signalement n'atteint le disque.

## Accessibilité

Quatre garde-fous automatisés dans `test/accessibility_test.dart` : contraste
WCAG AA, cibles tactiles ≥ 48 dp, étiquettes pour lecteurs d'écran, et absence
de débordement de mise en page jusqu'à un agrandissement du texte de 2×.

L'orange de marque est volontairement plus sombre que le #EA580C d'origine
(3,56:1 contre le blanc, sous le seuil AA) ; la teinte claire reste disponible
en `AppColors.primaryOrangeBright` pour les usages décoratifs.

## Limites connues

- Le chatbot est simulé : réponses scriptées, détection par mots-clés **en
  français uniquement**. Un message en arabe tombe toujours sur la réponse par
  défaut.
- Le sélecteur de langue est annoncé au sein du titre de l'`AppBar`, que Flutter
  fusionne en un seul nœud sémantique, plutôt que comme un bouton distinct.
- Le numéro de référence est généré localement avec `Random()` ; il devra venir
  du serveur.
