# Garder les placettes IFN d'une GRECO

Le modèle régional est calibré sur les placettes de la GRECO (première
lettre du code SER, docs/referentiels.md § 1 ; colonne `GRECO` de
`PLACETTE`).

## Usage

``` r
filter_greco(ifn, greco)
```

## Arguments

- ifn:

  Résultat de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md).

- greco:

  Lettre de la GRECO.

## Value

`ifn` réduit (placettes, flore, arbres).

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
nrow(filter_greco(ifn, "D")$placettes)
#> [1] 100
```
