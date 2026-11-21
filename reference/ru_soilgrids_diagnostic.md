# Écart de la RU SoilGrids à la RU des placettes IFN (diagnostic)

Pour chaque profondeur, RU SoilGrids
([`ru_soilgrids()`](https://pobsteta.github.io/sylvostation/reference/ru_soilgrids.md)
sur les capacités moyennées dans 700 m) aux placettes, comparée à
`ru_mm` : moyenne, biais, RMSE, corrélation, écarts-types.

## Usage

``` r
ru_soilgrids_diagnostic(points, cu700, depths = c(50, 100, 200))
```

## Arguments

- points:

  Placettes (`sf`) avec `ru_mm`, `id_placette`, `source`,
  `loc_precision_m`.

- cu700:

  `SpatRaster` de
  [`coarse_cu_layers()`](https://pobsteta.github.io/sylvostation/reference/coarse_cu_layers.md).

- depths:

  Profondeurs (cm).

## Value

`data.frame` : `profondeur_cm`, `n`, `ru_ifn_moy`, `ru_sg_moy`, `biais`,
`rmse`, `correlation`, `sd_ifn`, `sd_sg`, `statut`.

## Examples

``` r
cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
                  ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
names(cu) <- sprintf("coarse_cu_%d_%d_700m", c(0, 5, 15, 30, 60, 100),
                     c(5, 15, 30, 60, 100, 200))
p <- mark_ifn(sf::st_sf(id_placette = c("a", "b"), ru_mm = c(80, 120),
  geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
                        sf::st_point(c(1001500, 6801000)), crs = 2154)))
ru_soilgrids_diagnostic(p, cu)
#>   profondeur_cm n ru_ifn_moy ru_sg_moy biais      rmse correlation   sd_ifn
#> 1            50 2        100        50   -50  53.85165          NA 28.28427
#> 2           100 2        100       100     0  20.00000          NA 28.28427
#> 3           200 2        100       200   100 101.98039          NA 28.28427
#>   sd_sg                                                            statut
#> 1     0 diagnostic (mission 039) : RU SoilGrids non utilisée par la carte
#> 2     0 diagnostic (mission 039) : RU SoilGrids non utilisée par la carte
#> 3     0 diagnostic (mission 039) : RU SoilGrids non utilisée par la carte
```
