# Réserve utile SoilGrids jusqu'à une profondeur (diagnostic)

Somme des capacités par horizon
([`soilgrids_cu()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_cu.md))
× épaisseur jusqu'à `depth_cm`. **Diagnostic seulement** (arbitrage du
2026-11-20) : SoilGrids ne connaît pas la profondeur du sol ; sur la
GRECO D, la RU à 1 m surestime la RU des placettes IFN de 137 mm en
moyenne (corrélation 0,27), et son champ est presque plat (écart-type 15
mm sur l'emprise). La RU de la carte est la RU apprise
([`ru_learned_data()`](https://pobsteta.github.io/sylvostation/reference/ru_learned_data.md)).

## Usage

``` r
ru_soilgrids(cu, depth_cm)
```

## Arguments

- cu:

  `SpatRaster` de
  [`soilgrids_cu()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_cu.md)
  ou matrice (points x 6 horizons, mm/cm).

- depth_cm:

  Profondeur (cm, 0 à 200) : un nombre, ou un vecteur (un par point) si
  `cu` est une matrice.

## Value

`SpatRaster` `ru_soilgrids_<depth>cm` ou vecteur (mm).

## Examples

``` r
ru_soilgrids(matrix(1.5, 2, 6), c(50, 100))
#> [1]  75 150
```
