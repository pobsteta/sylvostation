# Couches entièrement vides d'un raster

Noms des couches sans aucune cellule renseignée (par exemple le MRVBF
sans GRASS, un TPI dont la fenêtre dépasse l'emprise, la hauteur au
réseau sans cours d'eau). Elles sont retirées des prédicteurs et
déclarées dans l'état de preuve.

## Usage

``` r
empty_layers(r)
```

## Arguments

- r:

  `SpatRaster`.

## Value

Un vecteur de noms (éventuellement vide).

## Examples

``` r
r <- terra::rast(nrows = 2, ncols = 2, nlyrs = 2, crs = "EPSG:2154",
                 xmin = 1007000, xmax = 1007050, ymin = 6790000, ymax = 6790050)
terra::values(r) <- cbind(1:4, NA)
names(r) <- c("a", "b")
empty_layers(r)
#> [1] "b"
```
