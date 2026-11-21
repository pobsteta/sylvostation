# Ajouter à un tableau d'apprentissage une variable encodée hors pli (blocs spatiaux)

Pour le modèle final : la colonne `name` reçoit l'encodage **hors pli**
([`oof_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/oof_target_encoding.md),
plis = blocs spatiaux) de `var`, donc sans que la réponse d'une placette
entre dans sa propre valeur ; l'encodage calculé sur toutes les lignes
sert à prédire de nouvelles unités (cellules de la carte). Les lignes
sans `var` sont retirées (comptées dans l'attribut `retirees`).

## Usage

``` r
encode_by_blocks(
  data,
  response,
  var,
  name = "coarse_litho_enc",
  k = 10,
  block_size = NULL,
  nfolds = 5L,
  seed = 1L,
  oof = TRUE
)
```

## Arguments

- data:

  Objet `sf` (EPSG:2154, points) ou tableau `x`/`y`.

- response:

  Nom de la réponse (numérique).

- var:

  Colonne catégorielle de `data`.

- name:

  Nom de la colonne numérique créée.

- k:

  Voir
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md).

- block_size:

  Taille des blocs (m) ; `NULL` : portée estimée de la réponse, à défaut
  5 000 m, comme
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md).

- nfolds:

  Nombre de plis (5).

- seed:

  Graine de l'affectation des blocs aux plis.

- oof:

  `TRUE` (défaut) : encodage hors pli ; `FALSE` : encodage avec toutes
  les lignes (la réponse d'une placette entre alors dans sa propre
  valeur, atténuée par `k`).

## Value

Une liste : `data` (lignes avec `var`, colonne `name` ajoutée),
`encoding`
([`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
sur toutes ces lignes), `retirees` (nombre de lignes sans `var`).

## Examples

``` r
set.seed(2)
d <- data.frame(x = runif(60, 1e6, 1.03e6), y = runif(60, 6.8e6, 6.83e6),
                lev = sample(c("a", "b", "c"), 60, TRUE), g = rnorm(60))
r <- encode_by_blocks(d, "g", "lev", "enc", block_size = 8000)
r$encoding
#>   niveau  n    moyenne    valeur
#> 1      a 26 0.09038472 0.1163685
#> 2      b 15 0.27945916 0.2412460
#> 3      c 19 0.23650982 0.2183776
```
