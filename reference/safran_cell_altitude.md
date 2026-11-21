# Altitude moyenne des mailles SAFRAN

Pour chaque maille SAFRAN de 8 km (carré centré sur `LAMBX`, `LAMBY`, en
Lambert II étendu, EPSG:27572, reprojeté en Lambert-93), moyenne du MNT
`dem` sur la maille et part de la maille couverte par le MNT. SAFRAN
analyse le climat à l'altitude moyenne de la maille (Vidal et al. 2010,
doi 10.1002/joc.2003, **à vérifier** sur le texte) : la validation
croisée de la mission 039 va dans ce sens (RMSE 0,11 °C avec la moyenne
contre 0,34 avec l'altitude du centre).

## Usage

``` r
safran_cell_altitude(safran, dem)
```

## Arguments

- safran:

  `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).

- dem:

  `SpatRaster` d'altitude (m) en Lambert-93 (EPSG:2154), par exemple la
  BD ALTI à 250 m de
  [`fetch_mnt_large()`](https://pobsteta.github.io/sylvostation/reference/fetch_mnt_large.md).

## Value

`data.frame` : `maille`, `LAMBX`, `LAMBY`, `x`, `y` (centre, Lambert-93,
x = est, y = nord), `z_moy` (m, `NA` si la maille est hors du MNT),
`couverture` (0 à 1).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
dem <- terra::rast(xmin = min(m$x) - 6000, xmax = max(m$x) + 6000, ymin = min(m$y) - 6000,
                   ymax = max(m$y) + 6000, resolution = 250, crs = "EPSG:2154", vals = 400)
head(safran_cell_altitude(s, dem))
#>       maille LAMBX LAMBY       x       y z_moy couverture
#> 1 9560_23530  9560 23530 1006418 6783365   400          1
#> 2 9560_23610  9560 23610 1006487 6791359   400          1
#> 3 9560_23690  9560 23690 1006556 6799353   400          1
#> 4 9560_23770  9560 23770 1006626 6807347   400          1
#> 5 9640_23530  9640 23530 1014411 6783295   400          1
#> 6 9640_23610  9640 23610 1014481 6791289   400          1
```
