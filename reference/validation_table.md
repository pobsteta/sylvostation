# Table de validation du pipeline : chiffre principal, sensibilité à blocs fixes, local

Réunit
[`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md)
des gradients (blocs de portée estimée, le chiffre publié), une ligne «
`<gradient>` (sensibilité : blocs de taille fixe) » pour chaque gradient
dont la sensibilité est fournie, et la ligne du modèle local (ancrages
GBIF) si elle existe. Un résultat `NULL` est omis. L'alerte
`blocs_insuffisants` s'applique à chaque ligne.

## Usage

``` r
validation_table(
  cvs,
  sensibilite = NULL,
  local = NULL,
  min_blocs_par_pli = 4,
  synthetic = FALSE
)
```

## Arguments

- cvs:

  Liste nommée de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  (un élément par gradient).

- sensibilite:

  Liste nommée de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  à blocs fixes (éléments `NULL` omis) ou `NULL`.

- local:

  `NULL` ou résultat de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  du modèle local (trophique, GBIF).

- min_blocs_par_pli:

  Voir
  [`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md).

- synthetic:

  Voir
  [`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md).

## Value

Un `data.frame` (colonnes de
[`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md)).

## Examples

``` r
set.seed(1)
d <- data.frame(x = runif(100, 1007000, 1012000), y = runif(100, 6790000, 6795000),
                loc_precision_m = 10, coarse_a = rnorm(100))
d$g <- d$coarse_a + rnorm(100, sd = 0.3)
if (requireNamespace("mgcv", quietly = TRUE)) {
  cv <- spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 1000)
  validation_table(list(trophic = cv), list(trophic = cv), synthetic = TRUE)
}
#>                                       gradient   n        r2      rmse
#> 1                                      trophic 100 0.8977123 0.3157231
#> 2 trophic (sensibilité : blocs de taille fixe) 100 0.8977123 0.3157231
#>   r2_repere  ecart_r2 atteint block_size blocs k blocs_insuffisants alerte
#> 1      0.36 0.5377123    TRUE       1000    24 5              FALSE       
#> 2      0.36 0.5377123    TRUE       1000    24 5              FALSE       
#>   synthetic
#> 1      TRUE
#> 2      TRUE
```
