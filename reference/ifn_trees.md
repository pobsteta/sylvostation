# Arbres IFN au format de [`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)

Arbres IFN au format de
[`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)

## Usage

``` r
ifn_trees(arbre)
```

## Arguments

- arbre:

  `ifn$arbre` (colonnes `id_placette`, `ESPAR`, `HTOT`, `AGE`,
  docs/referentiels.md § 7).

## Value

Un `data.frame` : `plot`, `species`, `height` (m), `age` (ans).

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
nrow(ifn_trees(ifn$arbre))
#> [1] 1550
```
