# MNT synthétique du mode démo

Prend le plan incliné de `inst/extdata/synth_dtm.tif` (surface
analytique synthétique de 240 x 240 cellules de 25 m, jeu fabriqué), le
ramène par interpolation bilinéaire à la maille de `grid` (20 m depuis
la mission 025), en découpe autant de cellules que `grid`, replace le
résultat **sur l'emprise de `grid`** (pour que la démo se situe sur le
massif test) et y ajoute un relief lisse aléatoire (écart-type 40 m)
pour que pente, TWI et TPI varient. **Entièrement synthétique** : balise
`synthetic = TRUE`.

## Usage

``` r
synth_demo_dtm(grid, seed = 1L)
```

## Arguments

- grid:

  `SpatRaster` vide en EPSG:2154 (voir
  [`build_grid()`](https://pobsteta.github.io/sylvostation/reference/build_grid.md)),
  à `resolution_m`, pas plus grand que l'emprise de `synth_dtm.tif` (6
  000 m de côté).

- seed:

  Graine du relief aléatoire.

## Value

Un `SpatRaster` à une couche `z` (mètres) sur la grille de `grid`.

## Examples

``` r
g <- build_grid(c(xmin = 1007000, ymin = 6790000, xmax = 1008000, ymax = 6791000), 20)
terra::res(synth_demo_dtm(g))
#> [1] 20 20
```
