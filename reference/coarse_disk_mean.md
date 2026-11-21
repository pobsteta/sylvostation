# Moyenne dans un disque de 700 m (couche à maille large)

Moyenne circulaire d'une couche d'au moins 250 m dans un disque de rayon
`radius` (700 m par défaut, la précision de localisation des placettes
IFN) : la couche rendue, nommée `coarse_*`, est un prédicteur à maille
large permis aux placettes IFN (règle des 700 m) ; la même couche sert à
l'apprentissage et à la carte. Généralise
[`soilgrids_disk_mean()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_disk_mean.md)
(mission 039 : température corrigée, capacité en eau SoilGrids).

## Usage

``` r
coarse_disk_mean(r, radius = 700, name)
```

## Arguments

- r:

  `SpatRaster` en Lambert-93 (EPSG:2154), maille \>= 250 m (première
  couche lue).

- radius:

  Rayon du disque (m, au moins 700).

- name:

  Nom de la couche rendue, préfixé `coarse_`.

## Value

Un `SpatRaster` à une couche `name`.

## Examples

``` r
r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1005000, ymin = 6.8e6,
                 ymax = 6805000, crs = "EPSG:2154", vals = 5)
names(coarse_disk_mean(r, name = "coarse_x_700m"))
#> [1] "coarse_x_700m"
```
