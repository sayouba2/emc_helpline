# Rapport de stage PFA — sources LaTeX

```
rapport/
├── rapport.tex        document principal (page de garde, chapitres, annexes)
├── preambule.tex      polices, couleurs, boîtes, styles de code, diagrammes
├── references.bib     bibliographie (biblatex + biber)
├── CAPTURES.md        liste des captures à fournir, avec leur emplacement
└── figures/
    ├── logos/         ecole.png, entreprise.png
    └── screens/       les 17 captures listées dans CAPTURES.md
```

## Compiler

```bash
latexmk -xelatex rapport.tex
```

Moteur : **XeLaTeX** (le document utilise `fontspec`). Bibliographie : **biber**.
Le glossaire est composé par LaTeX lui-même (`\makenoidxglossaries`) — aucun
outil externe, aucun Perl.

## Ce que le document utilise

| Élément | Paquet | Où le voir |
|---|---|---|
| Page de garde avec emplacements de logos | TikZ + `\IfFileExists` | page 1 |
| Placeholders de captures auto-remplacés | `\shot` / `\phoneshot` / `\wideshot` | `preambule.tex` |
| Diagramme de Gantt du planning | `pgfgantt` | figure 2.1 |
| Diagrammes UML (cas d'utilisation, classes, séquence) | TikZ pur, sans dépendance | figures 3.1, 4.2, 4.3 |
| Schéma d'architecture en couches | TikZ | figure 4.1 |
| Encadrés « Décision technique » / « Point de vigilance » | `tcolorbox` | chapitres 3 à 6 |
| Coloration Dart et TypeScript | `listings`, langages définis à la main | listings 5.1, 5.2 |
| Acronymes (`\gls`) | `glossaries`, mode `noidx` | liste des acronymes |
| Références croisées en français | `cleveref` | tout le document |
| Bibliographie numérotée | `biblatex` + `biber` | fin du document |
| Polices avec repli automatique | `fontspec` + `\IfFontExistsTF` | `preambule.tex` |

## Pagination

15 pages numérotées en chiffres arabes (chapitre 1 → conclusion), plus les pages
liminaires en chiffres romains, la bibliographie et les annexes. Ajouter des
captures ne change pas la pagination : les cadres pointillés ont déjà la taille
des images finales.

Pour raccourcir encore : supprimer l'annexe B (`\section{Écrans
complémentaires}`) et la figure 6.1.
