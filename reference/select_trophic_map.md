# Choisir la carte trophique publiée : régionale, ou locale si elle a gagné

Rend les cartes du pipeline avec la couche trophique **régionale**, sauf
si la comparaison
([`compare_local_regional()`](https://pobsteta.github.io/sylvostation/reference/compare_local_regional.md))
a décidé de remplacer. Sans décision positive explicite, la carte
régionale est gardée : la carte locale n'est jamais lue.

## Usage

``` r
select_trophic_map(maps_regional, local_map = NULL, comparison = NULL)
```

## Arguments

- maps_regional:

  Liste nommée de `SpatRaster` (`trophic`, `hydric`, …) du modèle
  régional.

- local_map:

  `SpatRaster` du modèle local (couches `pred`, `sd`, `sd_cv`, `di`,
  `aoa`) ou `NULL`.

- comparison:

  Résultat de
  [`compare_local_regional()`](https://pobsteta.github.io/sylvostation/reference/compare_local_regional.md)
  ou `NULL`.

## Value

Une liste : `maps` (même structure que `maps_regional`), `publiee`
(`"locale"` ou `"regionale"`) et `motif`.

## Examples

``` r
r <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000040, ymin = 6.8e6, ymax = 6800040,
                 crs = "EPSG:2154", vals = 1)
select_trophic_map(list(trophic = r), NULL, NULL)$publiee
#> [1] "regionale"
```
