# Température corrigée moyennée dans 700 m (couche à maille large, apprentissage)

[`t_corrected()`](https://pobsteta.github.io/sylvostation/reference/t_corrected.md)
sur un MNT d'au moins 250 m (BD ALTI), puis moyenne dans un disque de
`radius` m
([`coarse_disk_mean()`](https://pobsteta.github.io/sylvostation/reference/coarse_disk_mean.md))
: couche `coarse_t_corr_700m`, prédicteur à maille large permis aux
placettes IFN (règle des 700 m). Sur l'emprise de la GRECO D (mission
039), la moyenne dans 700 m porte 94 % de la variance de la T corrigée à
20 m (écart-type du résidu 0,26 °C) : c'est le coût du changement
d'échelle entre l'apprentissage et la carte.

## Usage

``` r
coarse_t_corr_layer(
  dem,
  safran,
  alt_mailles,
  lapse,
  months = 1:12,
  radius = 700
)
```

## Arguments

- dem:

  `SpatRaster` d'altitude, maille \>= 250 m, EPSG:2154.

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

- radius:

  Rayon du disque (m, \>= 700).

## Value

`SpatRaster` `coarse_t_corr_700m`.

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
dem <- terra::rast(xmin = m$x[1] - 2000, xmax = m$x[1] + 2000, ymin = m$y[1] - 2000,
                   ymax = m$y[1] + 2000, resolution = 250, crs = "EPSG:2154", vals = 600)
names(coarse_t_corr_layer(dem, s, data.frame(maille = m$maille, z_moy = 400), -0.0055))
#> [1] "coarse_t_corr_700m"
```
