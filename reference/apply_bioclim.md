# Appliquer l'axe bioclimatique à un tableau ou à un raster

Appliquer l'axe bioclimatique à un tableau ou à un raster

## Usage

``` r
apply_bioclim(x, axis, layers = NULL)
```

## Arguments

- x:

  Tableau ou `SpatRaster` portant les couches de `axis$vars`.

- axis:

  Résultat de
  [`bioclim_axis()`](https://pobsteta.github.io/sylvostation/reference/bioclim_axis.md).

- layers:

  Raster seulement : vecteur nommé (variable de l'axe = couche de `x`
  qui la remplace), par exemple `c(coarse_t_corr_700m = "t_corr")` pour
  appliquer à la cellule un axe appris sur la température moyennée dans
  700 m (mission 039). `NULL` : mêmes noms.

## Value

Un vecteur numérique (tableau) ou un `SpatRaster` `bioclim`.

## Examples

``` r
d <- data.frame(coarse_p_etp_sv = c(100, 300, 500), coarse_t_moy = c(10, 8, 6))
apply_bioclim(d, bioclim_axis(d))
#> [1]  1.414214  0.000000 -1.414214
```
