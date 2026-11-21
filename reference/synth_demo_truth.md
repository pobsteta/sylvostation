# Gradients « vrais » synthétiques du mode démo

Fonctions **fabriquées** des prédicteurs, qui servent de vérité aux jeux
synthétiques : `trophic` (climat, pente, TPI), `hydric` (TWI, pente,
TPI), `bioclim` (altitude, température). Chaque terme est centré-réduit
sur la grille. Rien de cela n'est une loi écologique.

## Usage

``` r
synth_demo_truth(predictors)
```

## Arguments

- predictors:

  `SpatRaster` de
  [`demo_predictors()`](https://pobsteta.github.io/sylvostation/reference/demo_predictors.md).

## Value

Un `SpatRaster` à trois couches : `trophic`, `hydric`, `bioclim`.

## Examples

``` r
if (FALSE) { # \dontrun{
synth_demo_truth(predictors)
} # }
```
