# ADR 0004 — Grille de 25 m calée sur 50 m, dérivés de terrain à 5 m

- **Date :** 2026-11-16
- **Statut :** maille de 25 m remplacée par 20 m (ADR 0007, 2026-11-18) ; acceptée par délégation (Claude, orchestrateur, pour Pascal), provisoire jusqu'à la mesure de l'incrément 1
- **Proposée par :** contradicteur (mission 000, I3), reprise par l'orchestrateur
- **Tranchée par :** Pascal, par délégation totale du 2026-11-16

## La décision en une phrase

La carte des stations est produite sur une grille de 25 m dont l'origine est un multiple
de 50 m en Lambert-93 ; les dérivés de terrain se calculent à 5 m puis s'agrègent ; le
coût d'une version à 10 m est mesuré sur les 4 dalles de l'incrément 1.

## Contexte

Le brief laisse 10 à 25 m (§ 1, § 11). La carte de référence de Gégout et al. (2008) est à
50 m (§ 9). À 25 m, les fonds de vallon étroits s'estompent, alors que le § 9 attend un gain
dans les positions topographiques marquées. Options : 10 m (détail, coût ×6,25 en cellules),
25 m (retenu, provisoire), 50 m (alignement direct sur la référence, perte de détail).

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | 25 m : 16 cellules par hectare | — | — |
| **R**esponsable | Qui fait quoi ? | Mission 003 mesure le coût à 10 m | — | — |
| **A**nticiper | Si l'imprévu arrive ? | Origine sur 50 m : agrégation exacte 2×2 vers la référence | — | — |
| **N**ovateur | Toutes les idées ? | 10 m écarté pour l'instant | Moins de détail | oui, provisoirement |
| **C**oût | Coût complet ? | Stockage et calcul 6 fois moindres qu'à 10 m | — | — |
| **É**cologique | Réutilisation ? | Grille compatible avec la référence à 50 m | — | — |

## Valeurs sacrifiées

**Novateur** et service rendu au forestier (le détail des vallons étroits), au profit du
**Coût**. Atténué : les dérivés de terrain sont calculés à 5 m et résumés dans la cellule.

## Sources

`docs/brief-technique.md`, § 1, § 4 étape 2, § 9 ; mission 000, objection I3.

## Question de contrôle

Cette décision tient-elle nos six valeurs ? Oui, au prix du détail, jusqu'à la mesure à 10 m.
