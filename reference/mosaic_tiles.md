# Mosaïque des rasters LiDAR, agrégée

Assemble
([`terra::vrt`](https://rspatial.github.io/terra/reference/vrt.html))
les rasters `mnt_*` ou `mhc_*` de toutes les dalles, vérifie qu'aucune
dalle attendue ne manque, agrège d'un facteur `fact` (moyenne, 1 m vers
5 m par défaut, ADR 0004) et rogne les bords vides.

## Usage

``` r
mosaic_tiles(files, kind = c("mnt", "mhc"), fact = 5, tile_ids = NULL)
```

## Arguments

- files:

  Chemins renvoyés par
  [`run_tile_block()`](https://pobsteta.github.io/sylvostation/reference/run_tile_block.md)
  (tous blocs).

- kind:

  `"mnt"` ou `"mhc"`.

- fact:

  Facteur d'agrégation (5 : de 1 m à 5 m).

- tile_ids:

  Dalles attendues (`NULL` : pas de contrôle).

## Value

Un `SpatRaster` en EPSG:2154, en mémoire.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
  r <- run_tile_block(tile_blocks(local_tiles(f))[[1]], tempfile("lidar"), buffer = 0)
  mosaic_tiles(r, "mnt")
}
#> class       : SpatRaster
#> size        : 16, 16, 1  (nrow, ncol, nlyr)
#> resolution  : 5, 5  (x, y)
#> extent      : 1015500, 1015580, 6793500, 6793580  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> name        :        mnt
#> min value   : 561.287632
#> max value   : 600.365733
```
