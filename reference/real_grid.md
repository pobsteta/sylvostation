# Grille de travail du mode réel

Grille de `res` m (origine multiple de `res`, ADR 0007) sur
l'intersection de l'emprise et de la partie renseignée du MNT (les
dalles traitées).

## Usage

``` r
real_grid(emprise, dtm, res)
```

## Arguments

- emprise:

  `sfc` de
  [`real_extent()`](https://pobsteta.github.io/sylvostation/reference/real_extent.md).

- dtm:

  `SpatRaster` du MNT (mosaïque).

- res:

  Résolution (m).

## Value

Un `SpatRaster` vide en EPSG:2154.

## Examples

``` r
d <- terra::rast(xmin = 1015500, xmax = 1015580, ymin = 6793500, ymax = 6793580,
                 resolution = 5, crs = "EPSG:2154", vals = 1)
e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                   ymax = 6805000), crs = sf::st_crs(2154)))
terra::ext(real_grid(e, d, 20))
#> SpatExtent : 1015500, 1015580, 6793500, 6793580 (xmin, xmax, ymin, ymax)
```
