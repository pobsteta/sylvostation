# Tableau des dalles à partir de fichiers LAZ locaux (sans réseau)

Pour le mode hors ligne : l'identifiant `XXXX-YYYY` est lu dans le nom
`LHD_FXX_XXXX_YYYY_*` (convention de l'IGN, docs/referentiels.md § 2) et
la dalle couvre x de `XXXX` à `XXXX + 1` km, y de `YYYY - 1` à `YYYY` km
(Lambert-93).

## Usage

``` r
local_tiles(laz_files)
```

## Arguments

- laz_files:

  Chemins de fichiers LAZ.

## Value

Un `sf` (EPSG:2154) : `tile_id`, `url` (le chemin local), géométrie de
la dalle.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
local_tiles(f)$tile_id
#> [1] "1015-6794"
```
