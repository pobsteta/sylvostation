# Encodage hors pli (sans fuite) pour l'apprentissage

Chaque ligne est encodée avec une table calculée **sans** les lignes de
son pli (plis spatiaux de préférence) : la réponse d'une ligne n'entre
jamais dans son propre encodage.

## Usage

``` r
oof_target_encoding(x, y, folds, k = 10)
```

## Arguments

- x, y, k:

  Voir
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md).

- folds:

  Identifiants de plis (longueur de `x`), au moins deux.

## Value

Un vecteur numérique (`NA` si `x` est `NA`).

## Examples

``` r
oof_target_encoding(rep(c("a", "b"), 6), 1:12, rep(1:3, 4), k = 1)
#>  [1] 7.0 7.7 6.0 7.0 5.3 6.0 7.0 7.7 6.0 7.0 5.3 6.0
```
