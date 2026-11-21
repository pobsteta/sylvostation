# Fusionner les types rares avec le type voisin le plus proche

Un type est **rare** s'il couvre moins de `area_min` de la surface
forestière ou compte moins de `n_min` placettes (1 % et 15 d'après le
brief, valeurs **provisoires** à confirmer). Les types rares sont
fusionnés un à un, le moins étendu d'abord, avec le type le plus proche
(distance euclidienne entre combinaisons de classes, dans l'espace des
colonnes `gradients`) ; en cas d'égalité de distance, le plus étendu.
Les surfaces et effectifs sont recalculés après chaque fusion. Les
stations azonales (alluviales, tourbeuses, éboulis) sont à traiter à
part, hors de cette fonction.

## Usage

``` r
merge_rare(
  types,
  area_min = 0.01,
  n_min = 15,
  gradients = NULL,
  area = NULL,
  plots = NULL
)
```

## Arguments

- types:

  Tableau issu de
  [`discretise()`](https://pobsteta.github.io/sylvostation/reference/discretise.md)
  : lignes = unités de surface (par exemple cellules du raster), colonne
  `type` et colonnes de classes.

- area_min:

  Part minimale de surface forestière (0,01 par défaut).

- n_min:

  Nombre minimal de placettes (15 par défaut).

- gradients:

  Noms des colonnes de classes définissant l'espace des distances
  (défaut : toutes les colonnes se terminant par `_cl`).

- area:

  Surface de chaque ligne de `types` (défaut : 1 par ligne, cellules de
  même taille).

- plots:

  Vecteur des types des **placettes** (un élément par placette, par
  exemple le `type` issu de
  [`discretise()`](https://pobsteta.github.io/sylvostation/reference/discretise.md)
  appliqué aux gradients des placettes). Si `NULL`, les lignes de
  `types` sont comptées comme placettes.

## Value

`types` avec `type` mis à jour, la colonne `type_initial` et les
attributs `merges` (table de traçabilité : `etape`, `de`, `vers`,
`distance`, `motif`, `part_surface`, `n_placettes`), `plots` (types des
placettes après fusion, si fournis) et `provisoire = TRUE`.

## Examples

``` r
set.seed(1)
g <- data.frame(trophic = rnorm(500), hydric = rnorm(500), bioclim = rnorm(500))
t <- discretise(g)
attr(merge_rare(t, n_min = 30), "merges")
#>    etape       de     vers distance     motif part_surface n_placettes
#> 1      1 T1-H2-B1 T1-H2-B2 1.000000 placettes        0.026          13
#> 2      2 T4-H3-B2 T3-H3-B2 1.000000 placettes        0.028          14
#> 3      3 T3-H2-B2 T3-H3-B2 1.000000 placettes        0.030          15
#> 4      4 T1-H3-B2 T1-H2-B2 1.000000 placettes        0.034          17
#> 5      5 T2-H1-B2 T3-H1-B2 1.000000 placettes        0.034          17
#> 6      6 T2-H1-B1 T2-H2-B1 1.000000 placettes        0.036          18
#> 7      7 T3-H2-B1 T2-H2-B1 1.000000 placettes        0.036          18
#> 8      8 T1-H1-B2 T1-H2-B2 1.000000 placettes        0.040          20
#> 9      9 T4-H3-B1 T3-H3-B1 1.000000 placettes        0.040          20
#> 10    10 T1-H1-B1 T1-H2-B2 1.414214 placettes        0.042          21
#> 11    11 T2-H3-B2 T3-H3-B2 1.000000 placettes        0.042          21
#> 12    12 T3-H1-B1 T3-H1-B2 1.000000 placettes        0.042          21
#> 13    13 T4-H1-B2 T3-H1-B2 1.000000 placettes        0.044          22
#> 14    14 T4-H2-B1 T4-H2-B2 1.000000 placettes        0.044          22
#> 15    15 T2-H2-B2 T1-H2-B2 1.000000 placettes        0.046          23
#> 16    16 T2-H3-B1 T2-H2-B1 1.000000 placettes        0.046          23
#> 17    17 T4-H1-B1 T3-H1-B2 1.414214 placettes        0.046          23
#> 18    18 T1-H3-B1 T1-H2-B2 1.414214 placettes        0.052          26
```
