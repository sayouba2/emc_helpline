# Captures à fournir — rapport EMC Helpline

Le rapport compile **déjà** sans aucune image : chaque emplacement affiche un
cadre pointillé portant le chemin du fichier attendu. Il suffit de déposer le
fichier au bon chemin et de recompiler — aucune modification du `.tex` n'est
nécessaire.

Format conseillé : **PNG**, écrans de téléphone en 1080 × 2340 (ratio ~2,16),
captures larges en 1600 × 1000 (ratio ~0,62). Émulateur en mode clair, batterie
et heure propres, aucune donnée réelle.

---

## Logos (page de garde)

| Fichier | Contenu | Note |
|---|---|---|
| `figures/logos/ecole.png` | Logo FST Marrakech / Université Cadi Ayyad | fond transparent, hauteur ≥ 500 px |
| `figures/logos/entreprise.png` | Logo CMRPI ou EMC Helpline | idem ; vérifier le droit d'usage avec l'encadrant |

## Maquettes Figma — figure 4.4 (chapitre 4, Conception)

| Fichier | Écran Figma à exporter |
|---|---|
| `figures/screens/figma-01-accueil.png` | `01 - Accueil` |
| `figures/screens/figma-05-incident.png` | `05` (type d'incident), **variante de sélection** de préférence |
| `figures/screens/figma-10-recap.png` | `10` (récapitulatif) |

> Export Figma : sélectionner la frame → Export → PNG 2×.

## Application — figure 5.1, parcours de signalement (chapitre 5)

| Fichier | Écran de l'app | Ce qu'il faut montrer |
|---|---|---|
| `figures/screens/app-01-accueil.png` | `HomeScreen` | bandeau numéro d'urgence en haut, accès rapides |
| `figures/screens/app-02-age.png` | `step01_age` | les 4 tranches d'âge, une sélectionnée |
| `figures/screens/app-03-preuves.png` | `step05_evidence` | les trois voies : capture, lien, récit |
| `figures/screens/app-04-recap.png` | `step10_summary` | le récit mentionné mais **non affiché** |

## Application — figure 5.2, envoi, suivi et arabe (chapitre 5)

| Fichier | Écran de l'app | Ce qu'il faut montrer |
|---|---|---|
| `figures/screens/app-05-envoi.png` | `sending_screen` | animation d'envoi en cours |
| `figures/screens/app-06-succes.png` | `report_success_screen` | le numéro de référence, avec un code **fictif** |
| `figures/screens/app-07-suivi.png` | `track_request_screen` | saisie du numéro + statut retrouvé |
| `figures/screens/app-08-arabe.png` | `HomeScreen` en arabe | interface entièrement en miroir (RTL) |

## Validation — figure 6.1 (chapitre 6)

| Fichier | Source | Ce qu'il faut montrer |
|---|---|---|
| `figures/screens/console-dossier.png` | console web `http://127.0.0.1:5000` | liste des dossiers **ou** détail avec statut, compte à rebours et journal d'audit |
| `figures/screens/ci-github-actions.png` | GitHub → Actions | les deux tâches au vert sur un même *run* |

## Annexe B — écrans complémentaires

| Fichier | Écran de l'app |
|---|---|
| `figures/screens/app-09-ressources.png` | `resources_screen` |
| `figures/screens/app-10-contact.png` | `contact_screen` |
| `figures/screens/app-11-assistant.png` | `emc_chatbot_screen` — avec le badge BÊTA visible |
| `figures/screens/app-12-parametres.png` | `settings_screen` — langue, notifications, textes légaux |

---

## Captures possibles, non utilisées dans cette version

À ajouter seulement si tu veux étoffer une section (chacune coûte ~1/3 de page) :

- `emulateur-firestore.png` — Emulator UI montrant le document `reports/` et son `expiresAt`
- `portail-evigilance.png` — page d'accueil de `evigilance.ma/fr/signaler` (chapitre 2, analyse de l'existant)
- `app-onboarding.png` — écran de premier lancement
- `app-erreur.png` — échec d'envoi avec bouton de réessai
- `tests-terminal.png` — sortie de `flutter test` et `npm run check`

---

## Rappel de compilation

```bash
latexmk -xelatex rapport.tex        # ou : xelatex → biber → xelatex ×2
```

Sur Overleaf : menu *Compiler* → **XeLaTeX**, et laisser le moteur de
bibliographie sur **Biber**.
