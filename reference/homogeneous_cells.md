# Cellules à voisinage 3 × 3 homogène

Une cellule est retenue si ses 9 cellules (elle et ses 8 voisines) sont
forestières et renseignées, si chaque couche continue a dans ce
voisinage un écart-type au plus égal à `sd_ratio` fois son écart-type
sur la forêt, et si chaque couche catégorielle (géologie) y prend une
seule classe. But : qu'un relevé localisé à quelques mètres près (GNSS)
lise les mêmes valeurs que la cellule tirée, et qu'il ne tombe pas en
lisière.

## Usage

``` r
homogeneous_cells(layers, forest, sd_ratio = .SD_RATIO_PROVISOIRE)
```

## Arguments

- layers:

  `SpatRaster` des couches fines (EPSG:2154).

- forest:

  `SpatRaster` : forêt si valeur non `NA` et positive (couche `foret` de
  [`forest_mask()`](https://pobsteta.github.io/sylvostation/reference/forest_mask.md),
  ou première couche).

- sd_ratio:

  Seuil **provisoire** (0,5).

## Value

`SpatRaster` `homogene` (1 retenue, 0 non retenue, `NA` hors forêt).

## Examples

``` r
r <- terra::rast(nrows = 5, ncols = 5, xmin = 1010000, xmax = 1010100, ymin = 6795000,
                 ymax = 6795100, crs = "EPSG:2154", vals = 1:25)
names(r) <- "pente"
f <- r * 0 + 1
homogeneous_cells(r, f)
#> class       : SpatRaster
#> size        : 5, 5, 1  (nrow, ncol, nlyr)
#> resolution  : 20, 20  (x, y)
#> extent      : 1010000, 1010100, 6795000, 6795100  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> name        : homogene
#> min value   :        0
#> max value   :        0
```
