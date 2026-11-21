# Essence dominante des placettes (surface terrière pondérée par W)

Surface terrière à l'hectare de chaque essence = somme de
`W * C13^2 / (4 pi)` sur les arbres **vivants** (`VEGET` 0 ou 1) de
chaque placette (`C13` : circonférence en m ; `W` : coefficient
d'extrapolation, 1 / surface du cercle de mesure en ha). Sans `W`, les
petits arbres, mesurés sur un cercle plus petit, seraient surpondérés.
L'essence dominante est celle de plus forte surface terrière ; la
placette est **pure** si sa part atteint `min_share` (75 % par défaut).
L'essence est observée sur la placette (table ARBRE), non extraite d'un
raster : elle ne tombe pas sous la règle des 700 m.

## Usage

``` r
dominant_species(arbre, ids = NULL, min_share = 0.75)
```

## Arguments

- arbre:

  `data.frame` de la table ARBRE : `id_placette`, `ESPAR`, `C13`, `W`,
  `VEGET`.

- ids:

  Identifiants de placettes à rendre, dans cet ordre (défaut : ceux de
  `arbre`).

- min_share:

  Part minimale de la surface terrière pour une placette pure.

## Value

Un `data.frame` : `id_placette`, `espar`, `share`, `g_ha` (m2/ha, tous
arbres vivants), `pure` ; `NA` pour une placette sans arbre vivant
mesuré.

## Examples

``` r
a <- data.frame(id_placette = c("p", "p", "p"), ESPAR = c("09", "09", "61"),
                C13 = c(1, 0.5, 0.4), W = c(14.1, 39.3, 88.4), VEGET = "0")
dominant_species(a)
#>   id_placette espar     share     g_ha  pure
#> 1           p    09 0.6284641 3.029435 FALSE
```
