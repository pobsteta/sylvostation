# Compléter une RU de carte par la RU de la maille SAFRAN

Les cellules sans RU apprise (géologie ou SoilGrids absents dans le
disque de 700 m) reçoivent la RU uniforme de leur maille
([`ru_by_safran_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_by_safran_cell.md))
: la carte hydrique n'a pas de trou là où elle en avait avant la mission
039. La part complétée est rendue en attribut `part_completee` (perdu
dans un store `targets` : la lire aussitôt).

## Usage

``` r
ru_fill_by_cell(ru, ru_mailles, safran)
```

## Arguments

- ru:

  `SpatRaster` de RU (mm), EPSG:2154.

- ru_mailles:

  `data.frame` (`maille`, `ru_mm`) de
  [`ru_by_safran_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_by_safran_cell.md).

- safran:

  `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).

## Value

`SpatRaster` `ru_carte` (mm).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)[1, ]
r <- terra::rast(xmin = m$x - 50, xmax = m$x + 50, ymin = m$y - 50, ymax = m$y + 50,
                 resolution = 50, crs = "EPSG:2154", vals = c(NA, 120, 130, NA))
terra::values(ru_fill_by_cell(r, data.frame(maille = m$maille, ru_mm = 90), s))[, 1]
#> [1]  90 120 130  90
```
