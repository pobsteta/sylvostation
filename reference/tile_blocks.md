# Grouper les dalles en blocs contigus de `size` x `size`

Bloc d'une dalle = (`floor((x_km - x0) / size)`,
`floor((y0 - y_km) / size)`), avec `x0` le plus petit `x_km` et `y0` le
plus grand `y_km` (coin nord-ouest) des dalles. Valeur provisoire de 3 x
3 (journal, mission 003 : environ 1,7 Go de LAZ au pic).

## Usage

``` r
tile_blocks(tiles, size = 3)
```

## Arguments

- tiles:

  `sf` de dalles (`tile_id` = « x_km-y_km », coin nord-ouest).

- size:

  Côté du bloc, en dalles (3).

## Value

Une liste de `data.frame` (`tile_id`, `url`, `block`), un par bloc, dans
l'ordre des blocs : l'unité du branchement dynamique de `targets`.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
length(tile_blocks(local_tiles(f)))
#> [1] 1
```
