# Coût d'accès : distance au tronçon accessible le plus proche

Distance euclidienne (m) du centre de chaque cellule de `grid` à la
cellule la plus proche touchée par un tronçon de `access` (tronçons
rastérisés sur la grille).

## Usage

``` r
access_cost(grid, access)
```

## Arguments

- grid:

  `SpatRaster` modèle (EPSG:2154).

- access:

  `sf` de lignes (EPSG:2154), par exemple
  [`get_access_network()`](https://pobsteta.github.io/sylvostation/reference/get_access_network.md).

## Value

`SpatRaster` à une couche `cout_m`.

## Examples

``` r
g <- build_grid(c(1010000, 6795000, 1010200, 6795200), 20)
l <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(
  rbind(c(1010000, 6795010), c(1010200, 6795010))), crs = 2154))
access_cost(g, l)
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 20, 20  (x, y)
#> extent      : 1010000, 1010200, 6795000, 6795200  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> name        : cout_m
#> min value   :      0
#> max value   :    180
```
