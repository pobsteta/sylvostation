# Climat kilométrique à partir de SAFRAN

Pour chaque maille SAFRAN (8 km), moyenne sur les années des cumuls de
la saison de végétation (`months`, avril à septembre par défaut,
**provisoire**) des précipitations (`PRELIQ + PRENEI`, couche `p_sv`) et
de l'ETP (`etp_sv`), et température moyenne annuelle (`t_moy`, `NA` si
la colonne `T` manque). Le raster est construit en Lambert II étendu
(EPSG:27572, grille SAFRAN) puis projeté en Lambert-93 à `res` m.

## Usage

``` r
safran_climate(
  safran,
  months = 4:9,
  res = 1000,
  interpolation = c("bilineaire", "proche")
)
```

## Arguments

- safran:

  `data.frame` de
  [`read_safran()`](https://pobsteta.github.io/sylvostation/reference/read_safran.md).

- months:

  Mois de la saison de végétation (4:9).

- res:

  Résolution du raster en Lambert-93 (1000 m, minimum pour l'IFN).

- interpolation:

  `"bilineaire"` (défaut) ou `"proche"`.

## Value

Un `SpatRaster` (EPSG:2154) : `p_sv`, `etp_sv`, `t_moy` ; attributs
`months` et `interpolation`.

## Details

- `interpolation = "bilineaire"` (défaut, mission 033) : chaque cellule
  de `res` m reçoit l'interpolation bilinéaire des valeurs des mailles
  entre leurs centres
  ([`safran_weights()`](https://pobsteta.github.io/sylvostation/reference/safran_weights.md))
  : le champ est continu, sans saut aux limites des mailles. Lissé à
  l'échelle de 8 km, il reste un climat kilométrique (variable large),
  croisable avec les placettes IFN. Aucune correction d'altitude.

- `interpolation = "proche"` : plus proche voisin (comportement d'avant
  033), la valeur de la maille est uniforme sur ses 8 km. **Attention**
  : la maille d'une placette est lue dans un raster de 1 km reprojeté ;
  sur la GRECO D, 3,8 % des placettes (109 sur 2 894) reçoivent la
  maille voisine, avec jusqu'à 2,5 °C d'écart (mission 035).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
safran_climate(s)
#> class       : SpatRaster
#> size        : 32, 24, 3  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1002386, 1026386, 6779401, 6811401  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> names       :   p_sv,     etp_sv,     t_moy
#> min values  : 275.35, 538.558529,  8.146573
#> max values  :  571.3,     596.15, 11.227528
```
