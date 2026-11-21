# Lithologie dominante dans un disque

Classe **modale** dans un disque de rayon `radius` autour de chaque
cellule : le prédicteur géologique à maille large autorisé pour les
placettes de l'IFN (localisées à 700 m près ; brief technique, règle des
700 m). En cas d'égalité, la classe de plus petit identifiant l'emporte
(résultat déterministe). Les cellules sans aucune donnée dans le disque
restent `NA` ; hors du raster, les cellules sont ignorées.

## Usage

``` r
dominant_lithology(litho_rast, radius = 700)
```

## Arguments

- litho_rast:

  `SpatRaster` catégoriel de
  [`rasterize_geol()`](https://pobsteta.github.io/sylvostation/reference/rasterize_geol.md),
  à maille carrée.

- radius:

  Rayon du disque, en mètres (700 par défaut).

## Value

`SpatRaster` catégoriel nommé `geologie_700m` (nom de la variable à
maille large de
[COARSE_VARIABLES](https://pobsteta.github.io/sylvostation/reference/COARSE_VARIABLES.md)),
mêmes niveaux que `litho_rast`.

## Examples

``` r
r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1000500,
                 ymin = 6.8e6, ymax = 6800500, crs = "EPSG:2154")
terra::values(r) <- rep(c(1, 2), each = 200)
levels(r) <- data.frame(id = 1:2, classe = c("a", "b"))
dominant_lithology(r, radius = 50)
#> class       : SpatRaster
#> size        : 20, 20, 1  (nrow, ncol, nlyr)
#> resolution  : 25, 25  (x, y)
#> extent      : 1000000, 1000500, 6800000, 6800500  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> categories  : classe
#> name        : geologie_700m
#> min value   :             a
#> max value   :             b
```
