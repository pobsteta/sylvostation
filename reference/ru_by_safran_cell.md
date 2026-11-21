# Réserve utile uniforme par maille SAFRAN (médiane des placettes IFN)

Réserve utile **provisoire** de la carte hydrique (mission 021) : aucune
source ne donne la réserve utile à cette échelle (`docs/referentiels.md`
§ 25.3), et aucune modulation topographique publiée n'a été trouvée (§
25.2) ; la réserve utile est donc **uniforme dans chaque maille SAFRAN
de 8 km**, égale à la médiane des réserves utiles (euptf2,
[`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md))
des placettes IFN de la maille. Une maille sans placette, ou avec moins
de `min_placettes` placettes (mission 033, valeur **provisoire**,
`ru_min_placettes` de `config.yml`), prend la médiane des placettes des
mailles de l'emprise, sinon celle de toutes les placettes fournies
(GRECO), et la colonne `origine` le dit (`n_placettes` garde l'effectif
de la maille). Jamais de modulation par la topographie.

## Usage

``` r
ru_by_safran_cell(
  points,
  safran,
  emprise = NULL,
  ru_col = "ru_mm",
  min_placettes = 1
)
```

## Arguments

- points:

  `sf` de points (EPSG:2154), par exemple les placettes IFN, avec la
  colonne `ru_col`.

- safran:

  `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).

- emprise:

  Emprise de la carte (bbox, `sf` ou `c(xmin, ymin, xmax, ymax)`,
  EPSG:2154) : mailles dont le centre est à moins d'une demi-diagonale
  (5,7 km). `NULL` : toutes les mailles de `safran`.

- ru_col:

  Colonne de réserve utile (mm).

- min_placettes:

  Effectif minimal de placettes pour garder la médiane de la maille (1 :
  toute maille avec au moins une placette). Le seuil de 5 retenu par la
  mission 033 est provisoire, non sourcé : à vérifier.

## Value

`data.frame` : `maille`, `ru_mm`, `n_placettes`, `origine`, `statut`.

## Details

Le rattachement d'une placette à sa maille de 8 km est une opération à
maille large, permise aux placettes IFN
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
avec `coarse_safran`).

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)
p <- mark_ifn(sf::st_as_sf(data.frame(ru_mm = c(80, 120), x = m$x[1:2], y = m$y[1:2]),
                           coords = c("x", "y"), crs = 2154))
ru_by_safran_cell(p, s)
#>        maille ru_mm n_placettes                          origine
#> 1  9560_23530    80           1           placettes de la maille
#> 2  9560_23610   120           1           placettes de la maille
#> 3  9560_23690   100           0 médiane des mailles de l'emprise
#> 4  9560_23770   100           0 médiane des mailles de l'emprise
#> 5  9640_23530   100           0 médiane des mailles de l'emprise
#> 6  9640_23610   100           0 médiane des mailles de l'emprise
#> 7  9640_23690   100           0 médiane des mailles de l'emprise
#> 8  9640_23770   100           0 médiane des mailles de l'emprise
#> 9  9720_23530   100           0 médiane des mailles de l'emprise
#> 10 9720_23610   100           0 médiane des mailles de l'emprise
#> 11 9720_23690   100           0 médiane des mailles de l'emprise
#> 12 9720_23770   100           0 médiane des mailles de l'emprise
#>                                                      statut
#> 1  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 2  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 3  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 4  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 5  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 6  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 7  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 8  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 9  provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 10 provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 11 provisoire (mission 021) : RU uniforme par maille SAFRAN
#> 12 provisoire (mission 021) : RU uniforme par maille SAFRAN
```
