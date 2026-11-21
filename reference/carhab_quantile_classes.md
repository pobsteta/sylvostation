# Classes de notre gradient aux mêmes proportions que CarHab

Découpe `x` en autant de classes que `ref` (rang ordinal CarHab) a de
modalités présentes, aux **mêmes parts de surface** (quantiles de `x`),
pour ne pas dépendre de nos seuils.

## Usage

``` r
carhab_quantile_classes(x, ref)
```

## Arguments

- x:

  Gradient continu (nombres).

- ref:

  Rang ordinal CarHab (même longueur, sans `NA`).

## Value

Une liste : `classe` (entiers 1..k, k modalités présentes de `ref`),
`rangs` (rangs CarHab présents, dans l'ordre), `parts` (parts cibles),
`parts_obtenues` (parts réellement obtenues par `classe`), `coupes`
(quantiles).

## Details

**Règle des égalités** : les coupes sont les quantiles (type 7) de `x`
aux parts cumulées de `ref`, et une cellule est rangée par
`findInterval(x, coupes, left.open = TRUE) + 1`, c'est-à-dire que `x`
égal à une coupe va dans la classe **basse**. Les cellules à valeurs
égales ne sont jamais séparées (pas de tirage au sort) : si une masse
d'égalités recouvre une coupe, la classe basse est **surgonflée** et la
classe suivante sous-remplie, voire vide. Les parts obtenues peuvent
donc s'écarter des parts cibles ; elles sont rendues (`parts_obtenues`)
pour être lues avec le kappa.

## Examples

``` r
carhab_quantile_classes(c(1, 2, 3, 4, 5, 6), c(1, 1, 2, 2, 3, 3))$classe
#> [1] 1 1 2 2 3 3
```
