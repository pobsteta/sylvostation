# Traiter un bloc de dalles LiDAR (cache par dalle, reprise après interruption)

Appelle `runner`
([`run_lasr()`](https://pobsteta.github.io/sylvostation/reference/run_lasr.md)
par défaut) sur les dalles du bloc qui ne sont pas déjà calculées. Une
dalle est **réutilisée** (ni retéléchargée ni recalculée) seulement si
ses deux sorties `mnt_<dalle>.tif` et `mhc_<dalle>.tif` existent, se
lisent avec `terra`, sont en EPSG:2154 et ont la résolution `res`
demandée, et si les paramètres consignés à leur calcul (fichier
`params_<dalle>.txt`) sont ceux demandés (`res`, `buffer`, `engine`).
Une dalle sans fichier de paramètres (calculée avant la mission 032) est
acceptée sur les seuls contrôles du raster. Sinon elle est recalculée.
Avant tout recalcul, les sorties et le fichier de paramètres de la dalle
sont effacés (pas de dalle mixte après une interruption). Une dalle
reprise sans `params_*.txt` est signalée par un message. `force = TRUE`
recalcule toutes les dalles du bloc. Les LAZ téléchargés sont effacés
après le bloc (`keep_laz = FALSE`). Le nombre de coeurs (`ncores`) ne
change pas le résultat et n'est pas consigné.

## Usage

``` r
run_tile_block(
  block,
  out_dir,
  res = 1,
  buffer = 20,
  ncores = 3,
  engine = "auto",
  force = FALSE,
  runner = run_lasr
)
```

## Arguments

- block:

  Un élément de
  [`tile_blocks()`](https://pobsteta.github.io/sylvostation/reference/tile_blocks.md).

- out_dir:

  Dossier des rasters LiDAR (hors dépôt).

- res, buffer, ncores, engine:

  Transmis à `runner`.

- force:

  Si `TRUE`, recalcule toutes les dalles du bloc (défaut `FALSE`).

- runner:

  Fonction de traitement (signature de
  [`run_lasr()`](https://pobsteta.github.io/sylvostation/reference/run_lasr.md)).

## Value

Les chemins des rasters du bloc (`mnt_*` puis `mhc_*`), pour une cible
`format = "file"`.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
  run_tile_block(tile_blocks(local_tiles(f))[[1]], tempfile("lidar"), buffer = 0)
}
#> [1] "/tmp/RtmppotWvD/lidar2cf120c39715/mnt_1015-6794.tif"
#> [2] "/tmp/RtmppotWvD/lidar2cf120c39715/mhc_1015-6794.tif"
```
