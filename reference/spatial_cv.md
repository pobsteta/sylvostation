# Validation croisée spatiale par blocs

Découpe l'espace en blocs carrés (Lambert-93, mètres) affectés à `k`
plis ; tous les points d'un bloc sont dans le même pli, ce qui limite la
fuite par autocorrélation. **Pas de tirage aléatoire simple par
défaut.** Taille de bloc par défaut : portée de l'autocorrélation de la
réponse (semi-variogramme empirique, 95 % du palier), à défaut 5 000 m
(valeur provisoire, mission 008). Les blocs sont faits maison (aucune
dépendance) ; blockCV n'est pas utilisé.

## Usage

``` r
spatial_cv(
  data,
  response,
  predictors,
  method = c("ranger", "gam"),
  block_size = NULL,
  k = 5L,
  weights = NULL,
  folds = NULL,
  encode = NULL,
  ...
)
```

## Arguments

- data:

  Objet `sf` de points en EPSG:2154, ou tableau avec colonnes `x` (est)
  et `y` (nord) **supposées en Lambert-93** : il est converti en `sf`
  EPSG:2154 puis contrôlé par
  [`assert_crs_2154()`](https://pobsteta.github.io/sylvostation/reference/assert_crs_2154.md)
  (des coordonnées hors de la France métropolitaine, par exemple x/y
  inversés ou degrés, sont refusées). Porte la réponse, les prédicteurs
  et `loc_precision_m`.

- response:

  Nom de la colonne réponse (numérique).

- predictors:

  Noms des colonnes prédictrices.

- method:

  `"ranger"` (forêt aléatoire, écart-type par quantiles) ou `"gam"`
  (mgcv, erreur-type du modèle).

- block_size:

  Taille des blocs en mètres (`NULL` : estimée, sinon 5 000).

- k:

  Nombre de plis (5 par défaut).

- weights:

  Poids des observations (`NULL` ou vecteur de la longueur de `data`).

- folds:

  Identifiants de plis fournis par l'utilisateur (diagnostic, par
  exemple un tirage aléatoire pour mesurer l'optimisme d'une CV non
  spatiale) ; `NULL` : blocs spatiaux.

- encode:

  `NULL`, une liste `list(var, name, k, oof)` ou une liste de telles
  listes (mission 035 ; `oof = FALSE` encode l'apprentissage avec toute
  sa partie, sans plis internes ; défaut `TRUE`) : `var` est une colonne
  catégorielle de `data` (lithologie, formation) et `name` le nom du
  prédicteur numérique à créer (il doit figurer dans `predictors` ; **si
  une colonne de ce nom existe déjà dans `data`, elle est recalculée
  dans chaque pli**, par exemple la colonne hors pli de
  [`encode_by_blocks()`](https://pobsteta.github.io/sylvostation/reference/encode_by_blocks.md),
  jamais utilisée telle quelle). Dans chaque pli, l'apprentissage reçoit
  l'encodage **hors pli**
  ([`oof_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/oof_target_encoding.md),
  blocs de la même taille) et le pli de test l'encodage de toute la
  partie d'apprentissage : la réponse du pli de test n'intervient
  jamais, sans fuite.

- ...:

  Transmis à
  [`fit_gradient()`](https://pobsteta.github.io/sylvostation/reference/fit_gradient.md)
  (`num_trees`, `seed`, `points_source`).

## Value

Une liste : `par_pli` (pli, n, r2, rmse), `global` (r2, rmse sur toutes
les prédictions hors pli), `predictions` (observé, prédit, écart-type
prédit `sd`, pli), `block_size`, `k`, `plis`, `n_blocs` (blocs carrés
occupés par au moins un point ; `NA` si `folds` est fourni). R² = 1 -
SCR/SCT par rapport à la moyenne observée ; il peut être négatif.

## Examples

``` r
set.seed(1)
d <- data.frame(x = runif(120, 0, 20000), y = runif(120, 0, 20000) + 6e6,
                loc_precision_m = 10, coarse_a = rnorm(120))
d$g <- d$coarse_a + rnorm(120, sd = 0.3)
if (requireNamespace("mgcv", quietly = TRUE)) {
  spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 5000)$global
}
#>        r2      rmse 
#> 0.9180948 0.2957536 
```
