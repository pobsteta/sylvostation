# Poids d'interpolation bilinéaire entre les centres des mailles SAFRAN

Pour chaque point (Lambert-93, x = est, y = nord), les quatre mailles
SAFRAN qui l'entourent sur la grille de 8 km (Lambert II étendu,
`LAMBX`, `LAMBY` en hm) et leurs poids bilinéaires. Une maille voisine
absente de `safran` (bord de l'extrait) reçoit un poids nul et les
autres poids sont renormalisés : hors de l'enveloppe des centres, la
valeur est celle du bord (extrapolation constante). Un point à plus
d'une demi-diagonale (5,66 km) de toute maille fournie n'a pas de poids
(ligne de `NA`), comme pour la maille la plus proche. Au centre d'une
maille, son poids vaut 1. L'interpolation bilinéaire est un choix de la
mission 033, aucune référence publiée lue : à vérifier.

## Usage

``` r
safran_weights(x, y, safran)
```

## Arguments

- x, y:

  Coordonnées en Lambert-93 (EPSG:2154), x = est, y = nord (m).

- safran:

  `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).

## Value

Une matrice (points x mailles) de poids de somme 1 (ou `NA`), colonnes
nommées par maille (`"LAMBX_LAMBY"`), dans l'ordre de
`.mailles_safran()`.

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
w <- safran_weights(1014550, 6799283, s)   # centre de la maille 9640_23690
round(w[, w > 0.001], 3)
#> 9640_23690 
#>          1 
```
