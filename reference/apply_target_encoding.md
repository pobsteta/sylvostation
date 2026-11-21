# Appliquer un encodage de [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)

Appliquer un encodage de
[`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)

## Usage

``` r
apply_target_encoding(x, encoding)
```

## Arguments

- x:

  Vecteur de niveaux. Un niveau absent de l'encodage reçoit la moyenne
  générale (jamais une valeur inventée) ; `NA` reste `NA`.

- encoding:

  Résultat de
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md).

## Value

Un vecteur numérique de la longueur de `x`.

## Examples

``` r
e <- target_encoding(c("a", "a", "b"), c(1, 3, 10), k = 1)
apply_target_encoding(c("a", "b", "z", NA), e)
#> [1] 2.888889 7.333333 4.666667       NA
```
