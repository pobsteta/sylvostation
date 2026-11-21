# Part de couvert forestier (MHC \> `height` m) par cellule de la grille

Masque forestier du mode réel (brief technique, étape 4 : hauteur de
canopée LiDAR supérieure à 5 m) : pour chaque cellule de `grid`, part
des pixels du MHC (1 m) au-dessus de `height`, parmi les pixels
renseignés. Une cellule est forestière si cette part atteint `min_share`
(0,5, provisoire) et si au moins la moitié de ses pixels sont renseignés
; sinon `NA`.

## Usage

``` r
forest_mask(files, grid, height = 5, min_share = 0.5)
```

## Arguments

- files:

  Chemins des rasters `mhc_*` (ou un `SpatRaster` de MHC).

- grid:

  `SpatRaster` modèle (EPSG:2154).

- height:

  Seuil de hauteur, en mètres (5).

- min_share:

  Part minimale de pixels au-dessus du seuil (0,5).

## Value

Un `SpatRaster` sur `grid` : `foret` (1 ou `NA`) et `part_couvert` (0 à
1).

## Examples

``` r
chm <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                   resolution = 1, crs = "EPSG:2154", vals = 10)
g <- build_grid(c(1015500, 6793500, 1015550, 6793550), 20)
forest_mask(chm, g)
#> class       : SpatRaster
#> size        : 3, 3, 2  (nrow, ncol, nlyr)
#> resolution  : 20, 20  (x, y)
#> extent      : 1015500, 1015560, 6793500, 6793560  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> names       : foret, part_couvert
#> min values  :     1,            1
#> max values  :     1,            1
```
