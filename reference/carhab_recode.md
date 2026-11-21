# Recoder une modalité CarHab en rang ordinal

Recoder une modalité CarHab en rang ordinal

## Usage

``` r
carhab_recode(x, champ = c("acidite_edaphique", "humidite_edaphique"))
```

## Arguments

- x:

  Vecteur de modalités (texte).

- champ:

  Voir
  [`carhab_levels()`](https://pobsteta.github.io/sylvostation/reference/carhab_levels.md).

## Value

Un vecteur d'entiers (`NA` pour une modalité absente de l'ordre, avec un
attribut `inconnues` : table des modalités non reconnues, jamais
supprimées en silence).

## Examples

``` r
carhab_recode(c("neutre", "basique", NA), "acidite_edaphique")
#> [1]  3  4 NA
#> attr(,"inconnues")
#> < table of extent 0 >
```
