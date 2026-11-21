# Agréger un raster à la maille kilométrique

Agrège par la **moyenne** un raster à une maille de `res_m` mètres (1000
par défaut). C'est l'étape obligatoire avant de croiser une couche de
sols ou de climat avec des placettes IFN (localisées à 700 m près ;
brief technique, étape 5 : pH GlobalSoilMap agrégé à 1 km). `res_m` doit
être un multiple entier de la maille de `x`.

## Usage

``` r
aggregate_to_km(x, res_m = 1000)
```

## Arguments

- x:

  `SpatRaster` en EPSG:2154, à maille carrée.

- res_m:

  Maille cible, en mètres.

## Value

Un `SpatRaster` de maille `res_m`, de mêmes noms de couches.

## Examples

``` r
r <- terra::rast(system.file("extdata", "synth_dtm.tif", package = "sylvostation"))
terra::res(aggregate_to_km(r))
#> [1] 1000 1000
```
