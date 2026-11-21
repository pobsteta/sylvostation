# Prédicteurs à maille large sur la grille

Ramène le climat kilométrique sur la grille (bilinéaire) :
`coarse_p_etp_sv` (P - ETP de la saison de végétation) et
`coarse_t_moy`. Les couches entièrement `NA` sont retirées.

## Usage

``` r
coarse_predictors(climat, grid)
```

## Arguments

- climat:

  `SpatRaster` de
  [`safran_climate()`](https://pobsteta.github.io/sylvostation/reference/safran_climate.md).

- grid:

  `SpatRaster` modèle.

## Value

Un `SpatRaster` sur `grid`.

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
g <- build_grid(c(1015500, 6793500, 1015600, 6793600), 20)
names(coarse_predictors(safran_climate(s), g))
#> [1] "coarse_p_etp_sv" "coarse_t_moy"   
```
