# Appliquer les fusions de [`merge_rare()`](https://pobsteta.github.io/sylvostation/reference/merge_rare.md) à un vecteur de types

Rejoue, dans l'ordre, les fusions (`de` vers `vers`) de la table de
traçabilité de
[`merge_rare()`](https://pobsteta.github.io/sylvostation/reference/merge_rare.md)
: utile pour porter sur des points de terrain la typologie finale.

## Usage

``` r
apply_merges(types, merges)
```

## Arguments

- types:

  Vecteur de types (caractère).

- merges:

  Table `attr(<merge_rare()>, "merges")` (colonnes `de`, `vers`).

## Value

Le vecteur de types fusionnés.

## Examples

``` r
apply_merges(c("a", "b", "c"), data.frame(de = c("a", "b"), vers = c("b", "c")))
#> [1] "c" "c" "c"
```
