# Comparer le modèle trophique local (ancrages GBIF) au modèle régional (IFN)

Décide si la carte trophique locale peut remplacer la carte régionale
(mission 037, décision de Pascal : **le local ne remplace le régional
que s'il fait mieux**). Sur les **mêmes ancrages et les mêmes plis** :
le modèle local est évalué hors pli par blocs (`local_trophic$cv`) ; le
modèle régional, appris sur les placettes IFN, n'a jamais vu les
ancrages : on lit sa carte aux coordonnées des ancrages (x = est, y =
nord, EPSG:2154). R² = 1 - SCR / SCT sur les mêmes points. Le gain est
`R²(local) - R²(régional brut)`. Son **IC** vient d'un bootstrap **de
blocs** (les blocs de la grille de
[`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md),
rééchantillonnés avec remise) ; le local remplace le régional
**seulement si** la borne basse de l'IC dépasse `gain_min`.

## Usage

``` r
compare_local_regional(
  local_trophic,
  regional_map,
  n_anchors = NA_integer_,
  gain_min = 0.02,
  min_anchors = 20L,
  min_blocks = 10L,
  level = 0.95,
  n_boot = 1000L,
  seed = 1L,
  aoa_part = NA_real_
)
```

## Arguments

- local_trophic:

  Liste de la cible `local_trophic` : `data` (`sf` des ancrages, colonne
  `trophic`, EPSG:2154) et `cv` (résultat de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  sur ces ancrages) ; sans modèle, `NULL` ou une liste portant
  `n_complets` (effectif après exclusion des incomplets) et, si
  l'ajustement a échoué, `erreur` (message d'origine).

- regional_map:

  `SpatRaster` (une couche) de la carte trophique **régionale**,
  EPSG:2154.

- n_anchors:

  Nombre d'ancrages avant exclusion des incomplets (pour le message ;
  `NA` ok).

- gain_min:

  Marge minimale sur la borne basse de l'IC du gain de R² (0,02).

- min_anchors, min_blocks:

  Effectifs minimaux (20 ancrages, 10 blocs).

- level:

  Niveau de l'IC bilatéral (0,95).

- n_boot:

  Tirages du bootstrap de blocs (1 000).

- seed:

  Graine du bootstrap (l'état du générateur est restauré).

- aoa_part:

  Part de la carte dans la zone d'applicabilité du modèle local
  (information).

## Value

Une liste : `resume` (une ligne : `n_ancrages`, `n_blocs`, `k_plis`,
`n_tirages` (tirages valides du bootstrap), `r2_local`, `r2_regional`,
`r2_regional_recalibre` (information), `gain`, `ic_bas`, `ic_haut`,
`niveau_ic`, `seuil_gain`, `rmse_local`, `rmse_regional`,
`biais_regional`, `aoa_part_carte`, `variables_locales` (variables du
modèle local, lues dans `local_trophic$variables`), `decision`, `motif`,
`statut_seuils`), `par_pli`, `remplace` (logique) et `publiee`
(`"locale"` ou `"regionale"`).

## Details

La comparaison est **impossible** (carte régionale gardée, avertissement
avec la raison, jamais un silence) si le modèle local est absent, s'il y
a moins de `min_anchors` ancrages, moins de `min_blocks` blocs occupés,
ou une prédiction régionale manquante.

Trois asymétries, à lire avec le verdict : (a) décalage de domaine : le
régional apprend des placettes IFN (flore sur 700 m), les ancrages sont
des listes de 50 m ; (b) fuite possible en faveur du régional : des
placettes IFN d'apprentissage voisines des ancrages ; (c) les ancrages
sont là où l'on herborise (chemins, lisières), non représentatifs de la
carte (`aoa_part_carte`). Le **régional recalibré hors pli** (décalage
moyen appris sur les autres plis) est rendu **pour information
seulement, jamais comme critère de décision**.

L'IC est **conditionnel aux prédictions hors pli figées** : il rend
compte du choix des blocs d'ancrages, pas de la variabilité de
l'ajustement du modèle local ni de la répartition en plis.

Seuils : **valeur provisoire, sans source, à vérifier**.

## Examples

``` r
set.seed(1)
n <- 60
d <- sf::st_as_sf(data.frame(x = runif(n, 1e6, 1.1e6), y = runif(n, 6.8e6, 6.9e6),
                             loc_precision_m = 10, a = rnorm(n)),
                  coords = c("x", "y"), crs = 2154, remove = FALSE)
d$trophic <- d$a + rnorm(n, sd = 0.2)
cv <- spatial_cv(d, "trophic", "a", k = 3, block_size = 20000, num_trees = 50)
r <- terra::rast(xmin = 1e6, xmax = 1.1e6, ymin = 6.8e6, ymax = 6.9e6, resolution = 1000,
                 crs = "EPSG:2154", vals = 0)
compare_local_regional(list(data = d, cv = cv), r, min_blocks = 3)$resume$decision
#> [1] "locale"
```
