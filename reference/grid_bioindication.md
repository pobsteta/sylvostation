# Regrouper des occurrences en mailles et calculer les valeurs bioindiquées

Pose une grille de `cell` mètres calée sur l'origine (0, 0) de
Lambert-93 (donc sur un multiple de 50 m, ADR 0004). Dans chaque maille,
les espèces sont dédoublonnées ; seules celles présentes dans
`indicateurs` comptent comme **espèces indicatrices**. Une maille est
exploitable si elle en compte au moins `min_species` (brief technique, §
4 étape 4) ; ce nombre est conservé comme poids (`poids`). La valeur
bioindiquée de chaque gradient est la moyenne, sur les espèces
indicatrices de la maille, de la valeur indicatrice.

## Usage

``` r
grid_bioindication(occ, indicateurs, cell = 50, min_species = 5)
```

## Arguments

- occ:

  Points `sf` en EPSG:2154 issus de
  [`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
  (colonnes `species` et `loc_precision_m`). Refusés si la précision est
  absente, `NA` ou supérieure à `cell / 2` (le point pourrait tomber
  dans une autre maille).

- indicateurs:

  `data.frame` des valeurs indicatrices, format partagé de la mission
  006 (`inst/extdata/synth_indicateurs.csv`, séparateur `;`) : `cd_ref`,
  `nom`, et une colonne numérique par gradient (`ph`, `azote`,
  `humidite`). Les colonnes `cd_ref`, `cd_nom`, `id` et `synthetic` ne
  sont jamais des gradients. L'appariement se fait sur `cd_ref` quand
  `occ` et `indicateurs` le portent, sinon sur le nom (`nom` ou
  `species`, nom vernaculaire entre parenthèses ignoré ; repli **à
  vérifier** : la table GBIF vers TAXREF `CD_REF` manque).

- cell:

  Côté de la maille, en mètres (50).

- min_species:

  Nombre minimal d'espèces indicatrices par maille (5).

## Value

Un `sf` de polygones (mailles exploitables, EPSG:2154) : `cell_id`,
`x_min`, `y_min` (coin sud-ouest), `n_occ`, `poids`, une colonne par
gradient, et les attributs `n_mailles_occupees` (mailles comptant au
moins une occurrence), `n_mailles_exploitables`, `cell`,
`especes_non_appariees` (espèces d'`occ` absentes de `indicateurs`, avec
leur nombre d'occurrences) et `log_appariement`.

## Details

GBIF emploie le référentiel GBIF, Baseflor TAXREF : sans `cd_ref` dans
`occ`, le repli par nom perd des espèces indicatrices. Elles sont
listées dans l'attribut `especes_non_appariees`, jamais supprimées en
silence.

## Examples

``` r
p <- sf::st_as_sf(data.frame(x = c(1010010, 1010020), y = c(6795010, 6795020),
                             species = c("A a", "B b"), loc_precision_m = 10),
                  coords = c("x", "y"), crs = 2154)
ind <- data.frame(nom = c("A a", "B b"), trophique = c(2, 4))
nrow(grid_bioindication(p, ind, min_species = 2))
#> [1] 1
```
