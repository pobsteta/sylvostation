# Valeurs de plusieurs couches à maille large aux placettes (règle des 700 m)

[`raster_at_points()`](https://pobsteta.github.io/sylvostation/reference/raster_at_points.md)
couche par couche, colonnes ajoutées à `points` (jointure par
`id_placette`). Chaque couche doit être `coarse_*` : l'assertion des 700
m est appelée.

## Usage

``` r
layers_at_points(points, layers)
```

## Arguments

- points:

  `sf` de points (EPSG:2154) avec `id_placette`, `source`,
  `loc_precision_m`.

- layers:

  `SpatRaster` de couches `coarse_*`.

## Value

`points` avec une colonne par couche.

## Examples

``` r
r <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
                 ymax = 6802500, crs = "EPSG:2154", vals = 6)
names(r) <- "coarse_x_700m"
p <- mark_ifn(sf::st_sf(id_placette = "a",
  geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)), crs = 2154)))
layers_at_points(p, r)$coarse_x_700m
#> [1] 6
```
