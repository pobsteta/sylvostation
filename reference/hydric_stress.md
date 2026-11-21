# Gradient hydrique : indice de contrainte hydrique BILJOU sur climat SAFRAN

Calcule, avec le modèle de bilan hydrique journalier BILJOU (paquet
`biljouR`, Granier et al. 1999), l'indice de contrainte hydrique
`Istress` (définition de l'outil en ligne de l'INRAE : somme sur les
jours de stress de (0,4 - REW) / 0,4) et le nombre de jours de stress
`NJstress` (REW \< 0,4), en moyenne annuelle, à partir de la réserve
utile et du climat journalier SAFRAN (SIM2, Météo-France, maille 8 km).
Le gradient hydrique devient cet indice ; la réserve utile en est une
entrée (ADR 0006).

## Usage

``` r
hydric_stress(
  x,
  safran = NULL,
  ru_col = "ru_mm",
  annees = NULL,
  lai_max = 6,
  forest_type = "broadleaved",
  budburst = 110,
  leaf_fall = 300,
  pas_ru = 10,
  interpolation = c("bilineaire", "proche")
)
```

## Arguments

- x:

  `sf` de points (EPSG:2154) ou `SpatRaster` de réserve utile
  (EPSG:2154).

- safran:

  `data.frame` SIM2 quotidien (colonnes `LAMBX`, `LAMBY`, `DATE`
  AAAAMMJJ, `PRELIQ`, `PRENEI`, `ETP` en mm, noms des fichiers
  `QUOT_SIM2_AAAA.csv.gz` de meteo.data.gouv.fr ; suffixe `_Q` accepté)
  ou `NULL`.

- ru_col:

  Colonne de réserve utile (mm) de `x` (points).

- annees:

  Années à garder (`NULL` : toutes).

- lai_max, forest_type, budburst, leaf_fall:

  Paramètres de
  [`biljouR::biljou_run()`](https://pobsteta.github.io/biljouR/reference/biljou_run.html).

- pas_ru:

  Pas (mm) de la suite de réserves utiles pour une grille.

- interpolation:

  `"bilineaire"` (défaut) ou `"proche"` (points seulement).

## Value

Points : `x` avec `maille_safran`, `is_biljou`, `nj_stress`, `n_annees`,
`grad_hydrique` (= `-is_biljou`, ou la réserve utile en repli). Grille :
`SpatRaster` à trois couches `is_biljou`, `nj_stress`, `grad_hydrique`.
Attributs `methode` (`"biljou"` ou `"repli_ru"`), `sens`, `parametres`.

## Details

- **Placettes** (`x` = `sf` de points en EPSG:2154 avec la colonne
  `ru_col`) : avec `interpolation = "bilineaire"` (défaut, mission 033),
  les séries journalières (`PRELIQ`, `PRENEI`, `ETP`) sont interpolées
  bilinéairement entre les centres des mailles SAFRAN, lues au point
  publié
  ([`safran_weights()`](https://pobsteta.github.io/sylvostation/reference/safran_weights.md))
  ; avec `"proche"`, le point prend la série de la maille la plus proche
  (avant 033). Les deux sont des variables larges (champ lissé à 8 km),
  croisables avec l'IFN :
  [`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
  est appelée avec `coarse_safran`. Un calcul BILJOU par couple (série,
  réserve utile). `maille_safran` reste la maille la plus proche.

- **Grille** (`x` = `SpatRaster` de réserve utile en mm, EPSG:2154) :
  pour chaque maille SAFRAN (la plus proche, quelle que soit
  `interpolation`), l'indice est calculé sur une suite de réserves
  utiles (pas `pas_ru`) puis interpolé linéairement pour chaque pixel
  (descente d'échelle par la réserve utile).

- **Sens** : `grad_hydrique` est orienté « plus haut = plus humide »
  dans les deux modes (attribut `sens`) : `-is_biljou` en mode nominal,
  la réserve utile en repli.

- **Repli** : sans `safran` ou sans le paquet `biljouR`, l'indice vaut
  `NA` et `grad_hydrique` reprend la réserve utile ; l'attribut
  `methode` vaut `"repli_ru"` et la raison est dans l'attribut `repli`
  (avertissement émis).

- Une réserve utile nulle ou absente donne un indice `NA` (BILJOU exige
  un réservoir positif).

Paramètres de végétation **provisoires** (mission 019) : `lai_max = 6`,
feuillus, débourrement au jour 110 et chute des feuilles au jour 300
(valeurs de l'exemple de `biljouR`) ; ils sont à mesurer par comparaison
à l'humidité bioindiquée, et à geler avant la phase 1.

## Examples

``` r
# \donttest{
s <- utils::read.csv2(system.file("extdata", "safran_sim2_extrait.csv",
                                  package = "sylvostation"))
m <- s[1, c("LAMBX", "LAMBY")]
xy <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(x = m$LAMBX * 100,
  y = m$LAMBY * 100), coords = c("x", "y"), crs = 27572), 2154))
p <- sf::st_as_sf(data.frame(id = 1:2, ru_mm = c(60, 150), x = xy[1], y = xy[2]),
                  coords = c("x", "y"), crs = 2154)
hydric_stress(p, s)
#> Simple feature collection with 2 features and 7 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 1014550 ymin: 6799283 xmax: 1014550 ymax: 6799283
#> Projected CRS: RGF93 v1 / Lambert-93
#>   id ru_mm                geometry maille_safran is_biljou nj_stress n_annees
#> 1  1    60 POINT (1014550 6799283)    9640_23690  22.69927        48        2
#> 2  2   150 POINT (1014550 6799283)    9640_23690  11.30421        37        2
#>   grad_hydrique
#> 1     -22.69927
#> 2     -11.30421
# }
```
