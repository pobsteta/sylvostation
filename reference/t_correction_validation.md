# Validation croisée de la correction de température (une maille laissée de côté)

Pour chaque maille SAFRAN ayant au moins deux voisines directes (8 km au
nord, au sud, à l'est ou à l'ouest), sa T moyenne est prédite sans elle
: `bilineaire` (moyenne des voisines, la méthode d'avant 039 au centre
d'une maille), `gradient_fixe` (voisines ramenées à l'altitude de la
maille par −0,55 °C/100 m, Rolland 2003, **à vérifier**), `gradient_ser`
(voisines ramenées par le gradient de
[`safran_lapse_rate()`](https://pobsteta.github.io/sylvostation/reference/safran_lapse_rate.md)
réestimé sans la maille). Erreur rendue par méthode, sur toutes les
mailles et sur celles dont l'altitude s'écarte de plus de 100 m de la
moyenne de leurs voisines (« relief »). C'est la comparaison qui
justifie, dans le rapport, le choix du gradient lu dans SAFRAN plutôt
que meteoland (mesure de la mission 039 sur la GRECO D : 0,11 °C contre
0,23 en bilinéaire et 0,12 pour meteoland).

## Usage

``` r
t_correction_validation(safran, alt_mailles, months = 1:12, fixe = -0.0055)
```

## Arguments

- safran:

  `data.frame` SIM2 quotidien (colonnes `LAMBX`, `LAMBY`, `DATE`, `T`).

- alt_mailles:

  `data.frame` de
  [`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md).

- months:

  Mois pris en compte (1:12 : température annuelle).

- fixe:

  Gradient fixe de comparaison (°C/m).

## Value

`data.frame` : `methode`, `n`, `rmse`, `biais`, `n_relief`,
`rmse_relief` (°C).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
a <- data.frame(maille = m$maille, z_moy = seq(200, 900, length.out = nrow(m)))
t_correction_validation(s, a)
#>         methode  n      rmse        biais n_relief rmse_relief
#> 1    bilineaire 12 0.5002940 -0.036655386        2   0.4275875
#> 2 gradient_fixe 12 0.9072365 -0.036655386        2   1.2901032
#> 3  gradient_ser 12 0.6260639 -0.004720533        2   0.7086391
```
