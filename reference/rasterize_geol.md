# Rasteriser une couche géologique sur la grille commune

Rasterise un champ de classes d'une couche polygonale (BD Charm-50, ou
toute autre couche polygonale, par exemple le régolithe) sur une grille.
Le résultat est un raster **catégoriel** (niveaux = classes), `NA` hors
polygones. La cellule prend la valeur du polygone qui contient son
centre.

## Usage

``` r
rasterize_geol(geol, grid, field = "classe", table = NULL)
```

## Arguments

- geol:

  Objet `sf` polygonal en Lambert-93 (EPSG:2154).

- grid:

  `SpatRaster` en Lambert-93 : la grille commune.

- field:

  Nom du champ de classes (texte) de `geol`.

- table:

  Optionnel : tableau de recodage (par exemple le résultat de
  [`recode_lithology()`](https://pobsteta.github.io/sylvostation/reference/recode_lithology.md)
  ou `lithologie_massif_test.csv`) avec colonnes `notation` et `classe`
  ; `geol` est alors joint par `NOTATION` (jamais par `CODE`) pour créer
  le champ `field` ; une notation absente du tableau devient
  `non_classe`.

## Value

`SpatRaster` catégoriel à une couche nommée `field`.

## Examples

``` r
g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
                             package = "sylvostation"), quiet = TRUE)
grid <- terra::rast(xmin = 1007000, xmax = 1010000, ymin = 6790000, ymax = 6793000,
                    resolution = 100, crs = "EPSG:2154")
tab <- suppressWarnings(recode_lithology(list_formations(g)))
rasterize_geol(g, grid, "classe", table = tab)
#> class       : SpatRaster
#> size        : 30, 30, 1  (nrow, ncol, nlyr)
#> resolution  : 100, 100  (x, y)
#> extent      : 1007000, 1010000, 6790000, 6793000  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> categories  : classe
#> name        :    classe
#> min value   : alluvions
#> max value   :      gres
```
