# pH SoilGrids moyenné dans un disque de 700 m (couche à maille large)

Moyenne circulaire du pH de
[`fetch_soilgrids_ph()`](https://pobsteta.github.io/sylvostation/reference/fetch_soilgrids_ph.md)
dans un disque de rayon `radius` (700 m par défaut, la précision de
localisation des placettes IFN) : couche `coarse_ph_soilgrids_700m`,
prédicteur à maille large permis pour les placettes IFN (règle des 700
m) ; la même couche sert à l'apprentissage et à la carte.

## Usage

``` r
soilgrids_disk_mean(ph, radius = 700)
```

## Arguments

- ph:

  `SpatRaster` en Lambert-93 (EPSG:2154) de pH, maille \>= 250 m.

- radius:

  Rayon du disque (m, au moins la précision de localisation, 700).

## Value

Un `SpatRaster` à une couche `coarse_ph_soilgrids_700m`.

## Examples

``` r
r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1005000, ymin = 6.8e6,
                 ymax = 6805000, crs = "EPSG:2154", vals = 5)
terra::values(soilgrids_disk_mean(r))[1:3, 1]
#> [1] 5 5 5
```
