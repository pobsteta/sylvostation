# Gradient altitudinal de la température entre les mailles SAFRAN

Ajuste, sur les mailles SAFRAN de la SER, `T ~ z_moy + x + y` (T moyenne
des moyennes annuelles des jours de `months`, `z_moy` de
[`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md),
x = est et y = nord du centre en Lambert-93, km) et rend le coefficient
de l'altitude. Sur la GRECO D (mission 039) : −0,49 °C/100 m (R² 0,92) ;
repère publié −0,55 °C/100 m (Rolland 2003, **à vérifier** dans les
Vosges). Choix de la mission 039 (arbitrage du 2026-11-20) : pas de
coefficient extérieur, le gradient est lu dans SAFRAN.

## Usage

``` r
safran_lapse_rate(safran, alt_mailles, months = 1:12, min_mailles = 6L)
```

## Arguments

- safran:

  `data.frame` SIM2 quotidien (colonnes `LAMBX`, `LAMBY`, `DATE`, `T`).

- alt_mailles:

  `data.frame` de
  [`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md).

- months:

  Mois pris en compte (1:12 : température annuelle).

- min_mailles:

  Nombre minimal de mailles avec altitude.

## Value

Une liste : `gradient` (°C/m), `gradient_100m` (°C/100 m),
`erreur_type_100m`, `r2`, `sigma` (°C), `n` (mailles), `months`,
`formule`.

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
a <- data.frame(maille = m$maille, x = m$x, y = m$y, z_moy = seq(200, 900, length.out = nrow(m)))
safran_lapse_rate(s, a)$gradient_100m
#> [1] -0.1936932
```
