# Maille de comparaison à la référence

Plus petit multiple commun de `resolution_m` et de la maille de la
référence (50 m) :
[`compare_gradients()`](https://pobsteta.github.io/sylvostation/reference/compare_gradients.md)
exige un multiple entier de notre maille. 20 donne 100, 25 donne 50, 30
donne 150 (ADR 0007).

## Usage

``` r
comparison_res(resolution_m, ref_m = 50)
```

## Arguments

- resolution_m:

  Résolution de la grille (m), nombre entier positif.

- ref_m:

  Maille de la référence (m), 50 par défaut.

## Value

Un nombre (m).

## Examples

``` r
comparison_res(20)
#> [1] 100
```
