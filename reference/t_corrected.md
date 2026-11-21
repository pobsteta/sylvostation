# Température corrigée du relief sur un MNT

`T(cellule) = T_bilinéaire + G × (z − z_bilinéaire)` : `T_bilinéaire`
interpole entre les centres des mailles SAFRAN la T moyenne des mailles
(jours de `months`), `z_bilinéaire` interpole de même leur altitude
moyenne (`alt_mailles`), `z` est l'altitude de la cellule lue dans
`dem`, `G` le gradient de
[`safran_lapse_rate()`](https://pobsteta.github.io/sylvostation/reference/safran_lapse_rate.md).
Les poids sont calculés par blocs de cellules, sous forme creuse (quatre
mailles par cellule) : la mémoire croît avec le nombre de cellules, non
avec celui des mailles.

## Usage

``` r
t_corrected(
  dem,
  safran,
  alt_mailles,
  lapse,
  months = 1:12,
  name = "t_corr",
  chunk = 500000L
)
```

## Arguments

- dem:

  `SpatRaster` d'altitude (m), EPSG:2154.

- safran:

  `data.frame` SIM2 quotidien.

- alt_mailles:

  `data.frame` de
  [`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md).

- lapse:

  Gradient (°C/m) ou liste de
  [`safran_lapse_rate()`](https://pobsteta.github.io/sylvostation/reference/safran_lapse_rate.md).

- months:

  Mois de la température (1:12 : annuelle).

- name:

  Nom de la couche rendue.

- chunk:

  Nombre de cellules par bloc.

## Value

`SpatRaster` à une couche sur la grille de `dem`, attributs `gradient`
(°C/m) et `months`.

## Details

**Règle des 700 m.** Sur le MNT fin de la grille, la couche rendue
(`t_corr` par défaut) est une **variable fine** (`FINE_VARIABLES`),
jamais extraite aux placettes IFN. Pour l'apprentissage, voir
[`coarse_t_corr_layer()`](https://pobsteta.github.io/sylvostation/reference/coarse_t_corr_layer.md)
(moyenne dans 700 m).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
a <- data.frame(maille = m$maille, z_moy = 400)
dem <- terra::rast(xmin = m$x[1] - 500, xmax = m$x[1] + 500, ymin = m$y[1] - 500,
                   ymax = m$y[1] + 500, resolution = 250, crs = "EPSG:2154", vals = 600)
terra::values(t_corrected(dem, s, a, -0.0055))[1:3]
#> [1] 7.594863 7.594697 7.612925
```
