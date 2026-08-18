# EMC Helpline

Application mobile Flutter de signalement des violences numériques visant les
enfants, les jeunes et les femmes au Maroc, en partenariat avec le CMRPI.

Interface en **français, arabe et anglais**. En arabe, **toute l'interface est
mise en miroir**, pas seulement le texte : ordre des onglets, flèches, coins des
bulles, marges. C'est ce que prescrivent Android, iOS et le W3C, et ce qu'attend
un lecteur arabophone. Les seules exceptions sont les contenus qui se lisent de
gauche à droite dans toutes les langues — numéros de téléphone, URL, numéro de
référence — forcés en LTR. `test/rtl_test.dart` verrouille les deux règles. Au lancement, le logo apparaît en fondu puis laisse la place à
l'application ; le splash natif Android affiche le même logo, donc la transition
est invisible.

## Ce que fait l'application

- **Signaler** — l'onglet ouvre sur un choix : déposer un signalement, ou
  suivre une demande. Le formulaire fait 11 étapes — contexte, profil, incident,
  récapitulatif —, chacune validée avant de pouvoir avancer, avec un message qui
  dit ce qui manque quand le bouton est désactivé. Le bouton « SIGNALER
  MAINTENANT » de l'accueil ouvre le formulaire directement : qui l'utilise a
  déjà décidé.
- **Suivre ma demande** — l'utilisateur saisit le numéro de référence reçu à
  l'envoi et consulte l'état de son dossier.
- **Ressources** — les gestes à adopter face à un incident.
- **Contact** — WhatsApp, téléphone, e-mail et portail web de l'équipe.
- **Chatbot** (+12 ans) — assistant proposé depuis l'étape « âge » et depuis
  l'écran de confirmation, là où commence l'attente d'une réponse humaine.

Les numéros d'urgence sont accessibles en permanence : Police **19**,
Gendarmerie **177**.

## Règles du formulaire

Trois d'entre elles ne sont pas évidentes à la lecture du code seul.

**Les preuves ne peuvent pas être passées à vide.** Il faut au moins une capture
d'écran — elles sont multiples, avec vignettes et suppression individuelle —, un
lien, **ou** un récit d'au moins `Validators.minDescriptionLength` caractères.
Un signalement anonyme sans rien à examiner ne peut être ni vérifié ni instruit,
et le portail en ligne demande la même chose. Mais le cas le plus grave est
souvent celui où l'agresseur a effacé les traces, où le contenu était éphémère,
ou où l'enfant a été contraint de supprimer : le récit tient donc lieu de preuve
plutôt que de fermer la porte. Le champ reste visible même quand une preuve est
jointe — marqué facultatif — pour que rien de ce qui a été écrit ne disparaisse.

**La fin du parcours dépend de la réponse à « Veux-tu de l'aide ? ».**

| Réponse | Type d'aide | Coordonnées |
|---|---|---|
| Accompagnement | demandée | **pseudo + téléphone, obligatoires** |
| Je ne sais pas | sautée | sautées — le signalement reste anonyme |
| Pas d'accompagnement | sautée | sautées — le signalement reste anonyme |

Ces deux questions n'existent que pour permettre un rappel : elles ne se posent
donc qu'à qui l'a explicitement demandé. Les étapes conditionnelles sont
déclarées une seule fois dans `ReportProvider._isStepSkipped()`, et la navigation
avant comme arrière les enjambe à partir de cette définition — elles ne peuvent
pas diverger.

**L'anonymat n'est pas un interrupteur mais une conséquence.** Il n'existe pas
de bouton « rester anonyme » : le vrai nom n'est demandé nulle part, et un
pseudo associé à un numéro est précisément ce qui permet d'être joint sans se
nommer. `ReportModel.isAnonymous` se déduit de l'absence de coordonnées. Seuls un
pseudo et un téléphone sont collectés : ni e-mail, ni WhatsApp.

---

## État : frontend

Le développement est découpé en étapes et celle-ci couvre le frontend. Il n'y a
pas encore de backend : `ReportProvider.submitReport()` génère un numéro de
référence localement et ajoute le dossier à une liste en mémoire. L'application
n'a pas vocation à être déployée avant que le backend existe.

Les points d'accroche sont en place et n'attendent que l'appel réseau :

| À remplacer | Où |
|---|---|
| Envoi du signalement | injecter un `ReportSubmitter` dans `ReportProvider` — voir « Envoi et échec » ci-dessous |
| Suivi d'une demande | `ReportProvider.findByReference()` — lit l'historique de session, deviendra une requête serveur |
| Numéro de référence | rendu par le `ReportSubmitter` ; la simulation le tire au sort, le serveur l'attribuera |
| Captures d'écran | `ReportModel.evidenceFilePaths` contient des chemins locaux, à téléverser |

### Envoi et échec

`ReportProvider` ne sait pas comment un signalement part. Il appelle un
[`ReportSubmitter`](lib/models/submission_outcome.dart) — une fonction qui reçoit
le rapport et rend le numéro de référence, ou lève une `SubmissionException`.
Sans implémentation injectée, une simulation locale prend le relais. Le backend
n'a donc qu'un seul point à brancher, et les tests injectent des pannes plutôt
que de faire semblant.

**Un échec ne peut pas passer inaperçu.** `submitReport()` ne lève jamais : il
enregistre un `SubmissionFailure`, et le wizard remplace le formulaire par
[`SubmissionErrorScreen`](lib/views/reporting/submission_error_screen.dart).
Écrire « ton signalement n'est pas parti » importe plus qu'ailleurs : sans cet
écran, un enfant conclurait soit que l'app est cassée, soit — bien pire — que
son signalement est arrivé.

**Réessayer ne coûte rien et ne duplique rien.** Les réponses restent en place,
et l'écran le dit avant de proposer le bouton : la crainte de refaire onze
étapes est ce qui dissuade de réessayer. Chaque tentative porte la même clé
d'idempotence, créée une fois par signalement. Un envoi qui expire alors que le
serveur avait déjà enregistré ne peut donc pas ouvrir un second dossier — un
doublon ici, c'est une deuxième personne qui passe du temps sur un incident déjà
traité. **Le serveur devra faire respecter cette clé** ; le client ne fait que la
transmettre inchangée.

Après deux échecs consécutifs, l'écran cesse de suggérer que réessayer suffira
et propose la ligne directe de l'équipe ainsi que la Police (19). Un signalement
qui ne part pas n'est pas qu'une panne technique : c'est que personne n'est au
courant.

Enfin, un signalement complet dont l'envoi a échoué reste récupérable depuis
l'écran de choix (« Reprendre l'envoi »). Sans cela, quitter l'écran d'erreur
puis toucher « Faire un signalement » effacerait tout en silence.

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
│   ├── constants/     couleurs, styles, numéros d'urgence
│   ├── localization/  libellés localisés des enums métier et des messages de validation
│   ├── storage/       préférences (langue) — voir « Données » ci-dessous
│   └── utils/         lancement d'appels/liens, validateurs
├── l10n/              app_fr.arb, app_ar.arb, app_en.arb (source des traductions)
├── models/            ReportModel (immuable) + enums métier
├── providers/         ReportProvider : état du wizard, validation, historique
└── views/
    ├── components/    composants partagés (ChoiceCard, StepLayout, stepper…)
    ├── reporting/     wizard, écran d'envoi animé, confirmation
    ├── tracking/      suivi d'une demande par numéro de référence
    └── …              accueil, ressources, contact, chatbot, splash
```

**Gestion d'état** : `provider` / `ChangeNotifier`. `ReportProvider` détient la
machine à états du wizard et la validation par étape ; les indices d'étapes sont
des constantes nommées (`ReportProvider.stepEvidence`…) pour éviter les
décalages.

**Valeurs métier** : ce sont des `enum`, jamais des chaînes. Traduire un libellé
ne peut donc pas casser la logique de branchement. Les libellés vivent dans
[`report_enum_labels.dart`](lib/core/localization/report_enum_labels.dart).

**Validation** : le provider ne renvoie pas des phrases mais des
`ValidationMessage` — il n'a pas de `BuildContext`, et la formulation appartient
aux fichiers ARB.

**Modification du modèle** : `ReportModel.copyWith()` distingue « argument omis »
de « champ à effacer » grâce à une sentinelle `unsetField`. Omettre conserve,
passer `null` efface. Les champs à choix (enums) n'acceptent pas d'effacement :
un choix se change, il ne s'annule pas.

**Thème** : clair uniquement, volontairement. Une variante sombre a existé mais
était inatteignable et illisible sur les deux tiers des écrans.

**Étapes du wizard** : les onze écrans sont déclaratifs. `StepLayout` porte la
question et le sous-titre, `ChoiceCard` / `ChoiceTile` portent une réponse
sélectionnable — état choisi, sémantique et zone tactile compris. Un écran de
choix tient en une quarantaine de lignes, et l'état « sélectionné » annoncé aux
lecteurs d'écran ne peut plus être oublié sur une étape. Les fichiers sont
numérotés d'après les indices de `ReportProvider` (`step00_who` … `step10_summary`).

**Écrans** : un seul est construit à la fois. Les deux `IndexedStack` imbriqués
d'origine gardaient ~15 écrans vivants à chaque frame, ce qui suffisait à
étrangler un émulateur.

## Textes légaux

L'écran Paramètres — accessible par l'engrenage de l'en-tête — donne accès à la
politique de confidentialité, aux conditions d'utilisation et à une note « Mes
données ».

> Ces textes sont des **brouillons**. Les passages qui relèvent du juridique
> portent un marqueur `⚠️ À COMPLÉTER PAR LE CMRPI` : responsable de traitement,
> délégué à la protection des données, déclaration CNDP au titre de la loi
> 09-08, durée de conservation, exercice des droits, traitement des données d'un
> mineur, limites de responsabilité. `LegalDocumentScreen` détecte ce marqueur
> et affiche un bandeau d'avertissement en tête du document, pour qu'un
> paragraphe non validé ne passe jamais pour une clause approuvée.
>
> Les passages **sans** marqueur décrivent le comportement réel de
> l'application et sont vérifiables dans le code.
>
> Une politique de confidentialité est **obligatoire** pour publier sur Google
> Play dès lors que l'application collecte des données personnelles, et cette
> application relève en plus de la Families Policy.

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

L'accueil n'affiche **aucun historique de signalements** : sur un téléphone
partagé, la liste montrerait à la première personne qui l'ouvre ce qui a été
signalé et sur quelle plateforme. Le suivi passe par le numéro de référence,
que seul l'auteur possède.

**Le contenu des signalements n'est jamais persisté** — ni pseudo, ni
coordonnées, ni preuves, ni historique. Le suivi d'une demande ne retrouve donc
un dossier que pendant la session où il a été envoyé ; il s'appuiera sur le
serveur une fois celui-ci en place. C'est délibéré : l'application vise des
enfants qui partagent souvent leur téléphone, parfois avec la personne qu'ils
signalent. Une trace lisible localement serait un risque, pas une fonctionnalité.
Un test (`test/settings_store_test.dart`) vérifie qu'aucune donnée de
signalement n'atteint le disque.

## Accessibilité

Sept garde-fous automatisés dans `test/accessibility_test.dart` : contraste
WCAG AA, cibles tactiles ≥ 48 dp, étiquettes pour lecteurs d'écran, absence de
débordement jusqu'à un agrandissement du texte de 2×, barre de navigation qui
reste à sa taille, dégagement du header sous une encoche haute, et contenu qui
évite une encoche latérale en paysage.

Les écrans qui défilent passent par [`ScrollablePage`](lib/views/components/scrollable_page.dart) :
la barre de défilement reste visible dès que le contenu dépasse, pour qu'on
sache en arrivant sur une étape qu'il y a autre chose plus bas. Flutter ne
dessine rien quand tout tient à l'écran, donc une étape courte reste nette.

Le contenu s'écarte des encoches latérales en paysage, sans que les fonds
cessent de couvrir toute la largeur.

L'orange de marque est volontairement plus sombre que le #EA580C d'origine
(3,56:1 contre le blanc, sous le seuil AA) ; la teinte claire reste disponible
en `AppColors.primaryOrangeBright` pour les usages décoratifs.

## Limites connues

- Le chatbot est simulé : réponses scriptées, détection par mots-clés **en
  français uniquement**. Un message en arabe tombe toujours sur la réponse par
  défaut. Le badge BÊTA de son en-tête le signale à l'utilisateur.
- Le seuil d'âge qui décide de proposer l'assistant est une règle interne :
  aucun texte ne le mentionne, un test le vérifie.
- Le sélecteur de langue est annoncé au sein du titre de l'`AppBar`, que Flutter
  fusionne en un seul nœud sémantique, plutôt que comme un bouton distinct.
- Le récapitulatif indique qu'un récit a été écrit mais ne l'affiche pas : il
  peut faire plusieurs centaines de caractères. « Modifier » ouvre l'étape.
- L'orientation n'est pas verrouillée, mais la mise en page est pensée pour le
  portrait ; le paysage reste utilisable sans être soigné.
