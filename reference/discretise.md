# Discrétiser les gradients en classes et former les types

Pour chaque gradient, attribue une classe (1 = valeurs les plus basses)
selon des seuils, puis croise les classes : la combinaison est le
**type** (par exemple `T2-H1-B1`, préfixe = initiale du gradient). Une
valeur égale à un seuil tombe dans la classe supérieure. Une valeur
manquante donne une classe et un type `NA`.

## Usage

``` r
discretise(gradients, thresholds = default_thresholds(gradients))
```

## Arguments

- gradients:

  Tableau de gradients (colonnes numériques) ; un `sf` est accepté (la
  géométrie est ignorée).

- thresholds:

  Liste nommée de seuils par gradient (voir
  [`default_thresholds()`](https://pobsteta.github.io/sylvostation/reference/default_thresholds.md)).
  Défaut : seuils **provisoires** par quantiles.

## Value

Un `data.frame` de même nombre de lignes que `gradients` : une colonne
entière `<gradient>_cl` par gradient seuillé et une colonne `type`
(caractère). Attributs : `thresholds`, `provisoire` (`TRUE` si les
seuils le sont) et `synthetic` (hérité de `gradients`).

## Examples

``` r
set.seed(1)
g <- data.frame(trophic = rnorm(200), hydric = rnorm(200), bioclim = rnorm(200))
head(discretise(g))
#>   trophic_cl hydric_cl bioclim_cl     type
#> 1          1         2          2 T1-H2-B2
#> 2          3         3          2 T3-H3-B2
#> 3          1         3          1 T1-H3-B1
#> 4          4         2          1 T4-H2-B1
#> 5          3         1          1 T3-H1-B1
#> 6          1         3          1 T1-H3-B1
```
