# Contrôle : trophique prédit hors pli contre essences en place

Sur les placettes **pures**, compare le trophique prédit **hors pli**
(prédictions de
[`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
; jamais celles de l'apprentissage) à la moyenne d'essence. Trois
mesures :

## Usage

``` r
essence_control(
  train,
  cv,
  dominant,
  optima,
  trophic_sans_arbres,
  part_pure = 0.75,
  min_placettes = 15L,
  alerte_ecart = 0.5,
  alerte_ratio = 0.5,
  alerte_pente = 0.2
)
```

## Arguments

- train:

  `data.frame` ou `sf` d'apprentissage : `id_placette`, `trophic` (même
  ordre que les prédictions).

- cv:

  Liste de résultats de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  (un par taille de blocs) ou de listes par gradient (élément
  `trophic`). Un élément `NULL` est ignoré avec un avertissement.

- dominant:

  Résultat de
  [`dominant_species()`](https://pobsteta.github.io/sylvostation/reference/dominant_species.md)
  (placettes de `train`).

- optima:

  Résultat de
  [`species_optima()`](https://pobsteta.github.io/sylvostation/reference/species_optima.md).

- trophic_sans_arbres:

  Résultat de
  [`trophic_without_trees()`](https://pobsteta.github.io/sylvostation/reference/trophic_without_trees.md),
  aligné sur `train`.

- part_pure, min_placettes, alerte_ecart, alerte_ratio, alerte_pente:

  Seuils (provisoires).

## Value

Une liste : `global` (une ligne par taille de blocs) et `par_essence`.

## Details

- **accord d'ordre** : Spearman entre le prédit et la moyenne d'essence
  **apprise hors pli** (trophique observé sans les arbres, plis
  d'apprentissage seuls), rapporté au même accord avec le trophique
  observé ; alerte si le ratio tombe sous `alerte_ratio` (non évaluée
  sous `min_placettes` placettes pures : trop peu pour juger) ;

- **écart par essence** (essences à au moins `min_placettes` placettes
  pures) : moyenne prédite moins moyenne observée ; alerte si
  `|écart| > alerte_ecart` ;

- **amplitude** : pente de la moyenne prédite sur la moyenne observée,
  par essence ; alerte sous `alerte_pente`.

Les optimums de Tichý
([`species_optima()`](https://pobsteta.github.io/sylvostation/reference/species_optima.md))
ne servent que de repère (Spearman rendu, jamais d'alerte). **Seuils :
valeur provisoire, sans source, à vérifier.** Ce contrôle n'est pas une
validation indépendante : les essences sont corrélées au climat et à la
roche que le modèle voit ; l'accord d'ordre est un minimum de cohérence.

## Examples

``` r
set.seed(1)
n <- 120
tr <- data.frame(id_placette = as.character(seq_len(n)), trophic = rnorm(n, 4))
dom <- data.frame(id_placette = tr$id_placette, espar = rep(c("09", "61", "52"), 40),
                  share = 0.9)
cv <- list(predictions = data.frame(observe = tr$trophic, predit = tr$trophic + rnorm(n)),
           plis = rep(1:4, 30), block_size = 5000)
opt <- data.frame(espar = c("09", "61", "52"), nom = c("a", "b", "c"), optimum_tichy = 4)
essence_control(tr, list(`5000` = cv), dom, opt, tr$trophic, min_placettes = 10)$global
#>   bloc_m n_pures n_essences accord_predit accord_observe    ratio alerte_ordre
#> 1   5000     120          3    0.07484626     0.04780683 1.565598        FALSE
#>   pente_amplitude alerte_amplitude n_alertes_ecart tichy_placette tichy_essence
#> 1        1.503166            FALSE               0             NA            NA
#>   tichy_essence_observe r2_predit_essence r2_sans_arbres_essence seuil_ratio
#> 1                    NA         0.0215366             0.02265249         0.5
#>   seuil_ecart seuil_pente part_pure min_placettes
#> 1         0.5         0.2      0.75            10
#>                                statut_seuils
#> 1 valeur provisoire, sans source, à vérifier
```
