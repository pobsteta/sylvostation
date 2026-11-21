# Capacités SoilGrids moyennées dans 700 m (couches à maille large)

[`coarse_disk_mean()`](https://pobsteta.github.io/sylvostation/reference/coarse_disk_mean.md)
de chaque horizon de
[`soilgrids_cu()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_cu.md)
: couches `coarse_cu_0_5_700m`, ..., permises aux placettes IFN (règle
des 700 m, comme le pH SoilGrids de la mission 035).

## Usage

``` r
coarse_cu_layers(cu, radius = 700)
```

## Arguments

- cu:

  `SpatRaster` de
  [`soilgrids_cu()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_cu.md)
  (250 m).

- radius:

  Rayon (m, \>= 700).

## Value

`SpatRaster` à six couches `coarse_cu_*_700m`.

## Examples

``` r
cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
                  ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
names(cu) <- sprintf("cu_%d_%d", c(0, 5, 15, 30, 60, 100), c(5, 15, 30, 60, 100, 200))
names(coarse_cu_layers(cu))
#> [1] "coarse_cu_0_5_700m"     "coarse_cu_5_15_700m"    "coarse_cu_15_30_700m"  
#> [4] "coarse_cu_30_60_700m"   "coarse_cu_60_100_700m"  "coarse_cu_100_200_700m"
```
