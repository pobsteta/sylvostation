# Valeur d'une couche à maille large aux placettes (règle des 700 m)

Extrait une couche **à maille large** (préfixe `coarse_`) aux points,
par interpolation bilinéaire. La règle bloquante est appelée en premier
: une couche non large est refusée pour des placettes IFN ou des points
de précision \> 25 m, et une maille inférieure à `min_res_m` aussi.

## Usage

``` r
raster_at_points(points, layer, min_res_m = 250)
```

## Arguments

- points:

  `sf` de points en Lambert-93 avec `id_placette` (marqués IFN :
  [`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md)).

- layer:

  `SpatRaster` à une couche, nommée `coarse_*`, en EPSG:2154.

- min_res_m:

  Maille minimale (m, 250 par défaut).

## Value

Un `data.frame` : `id_placette` et la couche (même nom).

## Examples

``` r
r <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
                 ymax = 6802500, crs = "EPSG:2154", vals = 6)
names(r) <- "coarse_ph_soilgrids_700m"
p <- sf::st_sf(id_placette = "a", geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
                                                         crs = 2154))
raster_at_points(mark_ifn(p), r)
#>   id_placette coarse_ph_soilgrids_700m
#> 1           a                        6
```
