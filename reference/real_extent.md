# Emprise de travail du mode réel

`cfg$emprise = "test"` (défaut, phase 0) : le carré `emprise_test`
recoupé avec la SER tamponnée ; `"ser"` : la SER tamponnée entière.

## Usage

``` r
real_extent(ser, cfg)
```

## Arguments

- ser:

  `sf` de
  [`get_ser()`](https://pobsteta.github.io/sylvostation/reference/get_ser.md)
  (déjà tamponné).

- cfg:

  Configuration de
  [`read_config()`](https://pobsteta.github.io/sylvostation/reference/read_config.md).

## Value

Un `sfc` (polygone) en EPSG:2154.

## Examples

``` r
ser <- get_ser("D11", source = "file",
               path = system.file("extdata", "ser_extrait.gpkg", package = "sylvostation"))
cfg <- list(emprise = "test", emprise_test = list(xmin = 1007000, ymin = 6790000,
            xmax = 1022000, ymax = 6805000))
sf::st_bbox(real_extent(ser, cfg))
#>    xmin    ymin    xmax    ymax 
#> 1007000 6790000 1022000 6805000 
```
