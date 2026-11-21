# Modalites ordinales CarHab (provisoires)

Ordre proposé au § 26.4 de `docs/referentiels.md`, **provisoire**
(décisions du 2026-11-18) : `neutre` est une classe propre, jamais
fusionnée avec `basique` ; l'ordre de l'humidité mêle réserve en eau et
engorgement. Les modalités sont celles du service (lues sur l'emprise
test) ; une modalité inconnue donne `NA`, comptée par
[`carhab_recode()`](https://pobsteta.github.io/sylvostation/reference/carhab_recode.md).

## Usage

``` r
carhab_levels(champ = c("acidite_edaphique", "humidite_edaphique"))
```

## Arguments

- champ:

  `"acidite_edaphique"` ou `"humidite_edaphique"`.

## Value

Un vecteur nommé d'entiers (nom = modalité CarHab, valeur = rang, 1 =
bas).

## Examples

``` r
carhab_levels("acidite_edaphique")
#>       très acide légèrement acide           neutre          basique 
#>                1                2                3                4 
#>     hyperbasique 
#>                5 
```
