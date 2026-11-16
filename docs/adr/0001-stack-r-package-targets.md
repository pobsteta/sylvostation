# ADR 0001 — Package R `sylvostation` et pipeline `targets` dans le même dépôt

- **Date :** 2026-11-16
- **Statut :** acceptée par délégation (Claude, orchestrateur, pour Pascal)
- **Proposée par :** brief technique de Pascal (§ 6), reprise par l'orchestrateur
- **Tranchée par :** Pascal, par délégation totale du 2026-11-16

## La décision en une phrase

Le code est un package R `sylvostation` (fonctions, roxygen2, testthat), et le pipeline
`targets`, paramétré par `config.yml`, vit à la racine du même dépôt, exclu du build.

## Contexte

Le brief impose R (§ 6) et propose Python comme alternative. Options : package + pipeline
(retenu), scripts sans package, Python (`geopandas`, `rasterio`, `scikit-learn`),
workflow Snakemake appelant R. R reste préférable pour l'analyse floristique (`vegan`,
`ade4`, `indicspecies`) et pour `lidR`/`lasR`.

Environnement de la session : R 4.3.3 (Ubuntu 24.04, paquets `r-cran-*` d'apt pour
`sf`, `terra`, `ranger`, `mgcv`…), compléments depuis CRAN ; `lasR` depuis
r-lidar.r-universe.dev. `renv` est prévu mais **le `renv.lock` n'est pas figé** dans
cette session : les versions installées sont celles d'apt et de CRAN du 2026-11-16, listées
dans le journal.

## Le crible FRANCE

| Lettre | Question | Réponse (une ligne) | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | La plus simple qui tienne ? | Un seul langage, un seul dépôt, un pipeline déclaratif | Apprendre `targets` | oui |
| **R**esponsable | Qui fait quoi ? | Le package porte les briques testées ; le pipeline les enchaîne | Deux niveaux à maintenir | oui |
| **A**nticiper | Si l'imprévu arrive ? | `lasR` évolue vite : il est isolé dans `R/lidar.R`, en `Suggests`, avec repli `lidR` | Dépendance hors CRAN | oui, isolée |
| **N**ovateur | Toutes les idées ? | Python et Snakemake écartés, documentés ici | — | — |
| **C**oût | Coût complet ? | Logiciels libres ; calcul local | Temps de calcul LiDAR à chiffrer (phase 0) | oui |
| **É**cologique | Réutilisation ? | Réutilise `sf`, `terra`, `lidR`, `lasR`, `happign`, `rgbif` ; fonctions réutilisables hors pipeline | — | — |

## Valeurs sacrifiées

- **Reproductibilité stricte de l'environnement** (Anticiper) : `renv.lock` non figé dans
  cette session (paquets apt). Sacrifice accepté pour avancer ; à figer avant la phase 1.
- Les dépendances lourdes (`lasR`, `lidR`, `rgbif`, `whitebox`, `blockCV`, `CAST`,
  `indicspecies`, `happign`, `targets`) sont en `Suggests` et testées avec
  `skip_if_not_installed()` : `R CMD check` reste léger, au prix de tests sautés si un
  paquet manque.

## Sources

- `docs/brief-technique.md`, § 6 (architecture), consignes.
- Documentation `targets` : https://docs.ropensci.org/targets/ (consultée le 2026-11-16, non relue ligne à ligne).

## Question de contrôle

Cette décision tient-elle nos six valeurs, et que sommes-nous prêts à payer pour cela ?
Oui, au prix d'un environnement non figé jusqu'à la phase 1.
