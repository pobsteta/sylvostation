# Modèle de sensibilité : le trophique avec l'essence dominante

Refait la validation croisée spatiale du trophique du pipeline, **avec**
l'essence dominante en plus, pour chiffrer ce que le pipeline s'interdit
(ADR 0008). L'essence est **encodée par le trophique moyen de l'essence,
refait dans chaque pli** à partir des seuls plis d'apprentissage (comme
la lithologie :
[`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md),
argument `encode`) ; la réponse du pli de test n'intervient jamais.
Trois variantes : essence fine (essences à au moins `min_placettes`
placettes pures, sinon `autre`) et groupes de la BD Forêt
([`espar_group_tfv()`](https://pobsteta.github.io/sylvostation/reference/espar_group_tfv.md))
; dans les deux, `mixte` (part sous `part_pure`) et `sans_arbre` ; et un
**placebo** (niveaux de l'essence fine mélangés au hasard, graine fixe)
: le gain de l'essence se lit moins celui du placebo. La base (sans
essence) est recalculée avec les mêmes plis. **Jamais un prédicteur de
la carte, des types ni des modèles** ; toute sortie porte la mention «
ne pas lire comme la carte ». La variable `coarse_essence_enc` vient de
la table ARBRE de la placette (observée, non extraite d'un raster) : le
préfixe `coarse_` ne sert qu'à passer
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md).

## Usage

``` r
essence_sensitivity(
  train,
  predictors,
  encode = NULL,
  dominant,
  block_sizes,
  part_pure = 0.75,
  min_placettes = 15L,
  k = 10,
  ifn_precision_m = 700,
  num_trees = 500L,
  seed = 1,
  folds = 5L
)
```

## Arguments

- train:

  `sf` d'apprentissage du trophique (`trophic`, prédicteurs, colonnes
  encodées).

- predictors:

  Prédicteurs du modèle de base (`vars_modele$trophic`).

- encode:

  Encodages du modèle de base (liste de listes `var`, `name`, `k`,
  `oof`).

- dominant:

  Résultat de
  [`dominant_species()`](https://pobsteta.github.io/sylvostation/reference/dominant_species.md)
  (placettes de `train`).

- block_sizes:

  Tailles de blocs (m) de la validation croisée.

- part_pure, min_placettes:

  Seuils (provisoires).

- k:

  Poids de la moyenne générale dans l'encodage de l'essence.

- ifn_precision_m:

  Précision des placettes IFN (700).

- num_trees, seed, folds:

  Transmis à
  [`fit_gradient()`](https://pobsteta.github.io/sylvostation/reference/fit_gradient.md)
  ; `folds` : nombre de plis (5).

## Value

Une liste : `resume` (`bloc_m`, `variante`, `r2`, `rmse`, `gain_r2`,
`gain_rmse`, `avertissement`), `par_pli` (`bloc_m`, `variante`, `pli`,
`n`, `r2`, `gain_r2`), `niveaux` (effectifs par niveau d'essence).

## Examples

``` r
# \donttest{
set.seed(1)
n <- 150
d <- sf::st_as_sf(data.frame(id_placette = as.character(seq_len(n)),
  x = runif(n, 1e6, 1.04e6), y = runif(n, 6.8e6, 6.84e6), loc_precision_m = 700,
  coarse_a = rnorm(n)), coords = c("x", "y"), crs = 2154, remove = FALSE)
dom <- data.frame(id_placette = d$id_placette, espar = rep(c("09", "61"), length.out = n),
                  share = 0.9)
d$trophic <- d$coarse_a + ifelse(dom$espar == "09", 1, -1) + rnorm(n, sd = 0.3)
essence_sensitivity(d, "coarse_a", NULL, dom, block_sizes = 10000, min_placettes = 10,
                    num_trees = 50)$resume
#>   bloc_m variante        r2      rmse   gain_r2  gain_rmse
#> 1  10000     base 0.1941316 1.2817807 0.0000000  0.0000000
#> 2  10000     fine 0.8509986 0.5511588 0.6568671 -0.7306219
#> 3  10000      tfv 0.8509986 0.5511588 0.6568671 -0.7306219
#> 4  10000  placebo 0.3336087 1.1655914 0.1394771 -0.1161893
#>                                                            avertissement
#> 1 sensibilite : essence en place ; ne pas lire comme la carte (ADR 0008)
#> 2 sensibilite : essence en place ; ne pas lire comme la carte (ADR 0008)
#> 3 sensibilite : essence en place ; ne pas lire comme la carte (ADR 0008)
#> 4 sensibilite : essence en place ; ne pas lire comme la carte (ADR 0008)
# }
```
