# Clé de détermination terrain (arbre de décision CART)

Ajuste un arbre de classification (`rpart`) qui prédit le type à partir
des seules variables **observables sur le terrain**, de profondeur
limitée (`maxdepth`, 5 par défaut, valeur provisoire) pour rester
utilisable. Publie deux taux de bon classement par rapport à la
typologie : `accuracy` (sur les données d'ajustement, optimiste) et
`accuracy_cv` (validation croisée à `folds` blocs tirés au hasard). Le
critère des 70 % du brief est appliqué au taux **en validation croisée**
(choix prudent) ; s'il n'est pas atteint, `merge_suggestions` liste,
dans l'ordre, les types les plus confondus à fusionner et le taux obtenu
après chaque fusion.

## Usage

``` r
build_key(
  data,
  observables,
  maxdepth = 5L,
  type = "type",
  min_accuracy = 0.7,
  folds = 5L,
  cp = 0.005,
  minbucket = 5L,
  seed = 1L
)
```

## Arguments

- data:

  Tableau portant la colonne des types et les observables (un `sf` est
  accepté, géométrie ignorée).

- observables:

  Noms des colonnes observables sur le terrain.

- maxdepth:

  Profondeur maximale de l'arbre (5).

- type:

  Nom de la colonne des types (`"type"`).

- min_accuracy:

  Taux minimal de bon classement (0,70).

- folds:

  Nombre de blocs de la validation croisée (5).

- cp:

  Paramètre de complexité de `rpart` (0,005, provisoire).

- minbucket:

  Effectif minimal d'une feuille (5).

- seed:

  Graine de la validation croisée.

## Value

Un objet de classe `sylvo_key` (liste) : `tree` (`rpart`), `accuracy`,
`accuracy_cv`, `confusion` (validation croisée), `meets_target`,
`merge_suggestions`, `depth`, `observables`, `provisoire = TRUE`.
[`print()`](https://rdrr.io/r/base/print.html) imprime la clé en texte.

## Examples

``` r
set.seed(1)
d <- data.frame(pente = runif(120, 0, 30), humus = sample(c("mull", "moder"), 120, TRUE))
d$type <- ifelse(d$pente > 15, "A", ifelse(d$humus == "mull", "B", "C"))
build_key(d, c("pente", "humus"))
#> Clé de détermination terrain (CART), profondeur 2 - valeurs provisoires
#> Bon classement : 100.0 % (ajustement), 100.0 % (validation croisée) ; cible 70 % : atteinte
#> - pente>=15.25 -> A (n = 57)
#> - pente< 15.25
#>   - humus=mull -> B (n = 32)
#>   - humus=moder -> C (n = 31)
```
