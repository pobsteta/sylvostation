# Garder au plus `max_tiles` dalles, les plus proches du centre de l'ensemble

Pour un essai court (par exemple 4 dalles avant la SER entière). Les
dalles gardées sont les plus proches du centre de l'ensemble
(contiguës), triées par `tile_id` ; en cas d'égalité de distance,
l'ordre de `tile_id` décide.

## Usage

``` r
select_tiles(tiles, max_tiles = NULL)
```

## Arguments

- tiles:

  `sf` de
  [`list_tiles()`](https://pobsteta.github.io/sylvostation/reference/list_tiles.md)
  ou
  [`local_tiles()`](https://pobsteta.github.io/sylvostation/reference/local_tiles.md).

- max_tiles:

  Nombre maximal de dalles (`NULL` : toutes).

## Value

`tiles`, éventuellement réduit.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
nrow(select_tiles(local_tiles(f), 1))
#> [1] 1
```
