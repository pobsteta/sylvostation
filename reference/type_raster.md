# Raster des types à partir des types de cellules

Pose les types (caractères) de certaines cellules d'un raster modèle
dans un raster de codes entiers, et renvoie la légende. Les codes
suivent l'ordre alphabétique des types.

## Usage

``` r
type_raster(template, cells, types)
```

## Arguments

- template:

  `SpatRaster` modèle (EPSG:2154).

- cells:

  Numéros de cellules du modèle (comme
  `terra::as.data.frame(cells = TRUE)`).

- types:

  Type de chaque cellule de `cells`.

## Value

Une liste : `raster` (une couche `type_id`, entiers) et `legend`
(`data.frame` `id`, `type`).

## Examples

``` r
r <- terra::rast(nrows = 2, ncols = 2, xmin = 1007000, xmax = 1007050,
                 ymin = 6790000, ymax = 6790050, crs = "EPSG:2154")
type_raster(r, 1:3, c("b", "a", "b"))$legend
#>   id type
#> 1  1    a
#> 2  2    b
```
