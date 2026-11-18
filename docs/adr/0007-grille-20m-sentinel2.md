# ADR 0007 — Grille de 20 m alignée sur des multiples de 20 m en Lambert-93, pour Sentinel-2

- **Date :** 2026-11-18
- **Statut :** acceptée (décision de Pascal du 2026-11-18, mission 025) ; remplace l'ADR 0004 pour la
  maille de sortie (les dérivés de terrain restent calculés à 5 m puis résumés dans la cellule)
- **Proposée par :** Pascal (« oui on part sur 20m aligné sentinel 2 »)
- **Tranchée par :** 20 m alignée : tranchée par Pascal le 2026-11-18 ; comparaison à 100 m et
  rééchantillonnage du MNT synthétique : décidés par l'orchestrateur par délégation

## La décision en une phrase

La grille de sortie fait `resolution_m: 20` m en Lambert-93 (EPSG:2154), origine (xmin, ymax) sur
des multiples de 20 m ; tout le code lit `resolution_m` (noms de fichiers et de couches sans
résolution, masque forestier « au moins la moitié de la cellule »), et les bandes Sentinel-2 à
20 m se rééchantillonnent sur cette grille.

## Contexte

Les bandes de Sentinel-2 à 20 m (B5, B6, B7, B8a, B11, B12) sont des prédicteurs candidats. Les
tuiles Sentinel-2 sont en UTM/WGS84 (pas de 100 km, tuiles de 110 km) : `docs/referentiels.md`
§ Sentinel-2. Une correspondance pixel à pixel avec une grille Lambert-93 est impossible, la
projection n'étant pas la même (convergence des méridiens, axes tournés). Un pixel de 20 m a la
taille d'une cellule de 20 m, mais pas la même emprise.

Options : (1) grille en UTM, pixel à pixel avec Sentinel-2 mais en rupture avec la règle du
projet « EPSG:2154 partout » et avec les autres couches ; (2) 20 m en Lambert-93, S2 rééchantillonné
(retenu) ; (3) rester à 25 m.

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | Un seul CRS, une seule clé `resolution_m` | Rééchantillonnage de S2 (une interpolation) | oui |
| **R**esponsable | Qui fait quoi ? | Mission 025 (code), puis 023 (S2) rééchantillonne | — | — |
| **A**nticiper | Si l'imprévu arrive ? | Retour à 25 m : changer `resolution_m` (tout le code la lit) | Noms de couches et fichiers déjà génériques | oui |
| **N**ovateur | Toutes les idées ? | UTM natif écarté (rupture de la règle EPSG:2154) | — | — |
| **C**oût | Coût complet ? | +56 % de cellules (1/400 contre 1/625 par m2) ; mesurée : hors ligne (1 dalle) 112 s ; `r.sun` sur 562 500 cellules (225 dalles) 301 s, 12 mois avec ombres | calcul et stockage | oui |
| **É**cologique | Réutilisation ? | Plus de détail dans les fonds de vallon ; compatible Sentinel-2 20 m | — | — |

## Conséquences

- **Référence à 50 m** (Gégout et al. 2008) : 50 n'est plus un multiple de 20, l'agrégation
  2 x 2 de l'ADR 0004 disparaît. La comparaison se fait à 100 m (plus petit multiple commun de
  `resolution_m` et de 50 ; `res_comparaison` de `_targets.R`) : notre grille est agrégée 5 x 5,
  la référence est ramenée à 100 m par interpolation bilinéaire (sur une grille alignée, la
  bilinéaire de 50 m vers 100 m équivaut à la moyenne 2 x 2 : pas de changement de méthode).
  Calcul : `comparison_res()`. Prix : comparaison moins fine.
- **Seuil de précision d'extraction fine** `loc_precision_m` <= 25 m : inchangé (c'est une
  précision de localisation, pas la maille).
- **Noms** : `hydrique_25m.tif` devient `hydrique.tif` ; la couche `grad_hydrique_25m` devient
  `grad_hydrique_carte` (inscrite dans `FINE_VARIABLES`). Voir `NEWS.md`.
- **Jeux synthétiques** (`synth_dtm.tif`, 25 m) : ramenés à la maille de la grille par
  interpolation bilinéaire (démo seulement).

## Réversibilité

Forte : `resolution_m` seul. Une grille en UTM resterait possible (nouvelle ADR) si Sentinel-2
devient le prédicteur dominant et que le rééchantillonnage pose un problème de justesse.

## Valeurs sacrifiées

**Frugal** (+56 % de cellules) et la comparaison fine à la référence (100 m au lieu de 50 m), au
profit de la compatibilité Sentinel-2 et du détail. Valeur provisoire, à geler avant la phase 1.

## Sources

`docs/referentiels.md` § Sentinel-2 ; `docs/adr/0004-resolution-grille.md` ; mission 025.
