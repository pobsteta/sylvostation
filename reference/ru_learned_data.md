# Données d'apprentissage de la RU apprise (placettes IFN)

RU de la carte (mission 039, arbitrage du 2026-11-20) : la RU des
placettes IFN (`ru_mm`,
[`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md))
est apprise par une forêt aléatoire
([`fit_gradient()`](https://pobsteta.github.io/sylvostation/reference/fit_gradient.md))
sur des prédicteurs à maille large : lithologie et formation dominantes
encodées dans 700 m (`coarse_litho_enc`, `coarse_formation_enc`) et
capacités SoilGrids moyennées dans 700 m
([`coarse_cu_layers()`](https://pobsteta.github.io/sylvostation/reference/coarse_cu_layers.md)).
R² par blocs mesuré sur la GRECO D : 0,14 (41 km) à 0,17 (8 358 m),
contre 0,10 (optimiste, non spatial) pour la médiane de la maille
SAFRAN.

## Usage

``` r
ru_learned_data(train, cu700)
```

## Arguments

- train:

  Placettes IFN (`sf`) avec `ru_mm` et les colonnes d'encodage de la
  lithologie (`trophic_enc$data` du pipeline).

- cu700:

  `SpatRaster` de
  [`coarse_cu_layers()`](https://pobsteta.github.io/sylvostation/reference/coarse_cu_layers.md).

## Value

Une liste : `data` (placettes complètes), `vars` (prédicteurs),
`retirees` (placettes sans RU ou sans prédicteur).

## Examples

``` r
cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
                  ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
names(cu) <- sprintf("coarse_cu_%d_%d_700m", c(0, 5, 15, 30, 60, 100),
                     c(5, 15, 30, 60, 100, 200))
p <- mark_ifn(sf::st_sf(id_placette = c("a", "b"), ru_mm = c(80, NA),
  coarse_litho_enc = 1, coarse_formation_enc = 2,
  geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
                        sf::st_point(c(1001500, 6801000)), crs = 2154)))
ru_learned_data(p, cu)$vars
#> [1] "coarse_litho_enc"       "coarse_formation_enc"   "coarse_cu_0_5_700m"    
#> [4] "coarse_cu_5_15_700m"    "coarse_cu_15_30_700m"   "coarse_cu_30_60_700m"  
#> [7] "coarse_cu_60_100_700m"  "coarse_cu_100_200_700m"
```
