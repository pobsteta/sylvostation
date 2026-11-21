# Taux d'appariement des espèces d'une flore avec les valeurs indicatrices

Mesure, pour la flore IFN, la part des espèces (codes `CD_REF`
distincts) et des occurrences (lignes de relevé) qui ont une valeur
indicatrice, via
[`load_indicator_values()`](https://pobsteta.github.io/sylvostation/reference/load_indicator_values.md)
en mode `taxa`. Les non-appariés sont listés avec leur nom et leur rang,
jamais supprimés.

## Usage

``` r
indicator_match_rate(flore, indicateurs)
```

## Arguments

- flore:

  `data.frame` de flore (colonne `CD_REF`) ou résultat de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md).

- indicateurs:

  Résultat de `load_indicator_values(..., taxa = unique(flore$CD_REF))`.

## Value

Une liste : `n_especes`, `n_apparies`, `taux_especes`, `n_occurrences`,
`taux_occurrences`, `par_appariement` (effectifs `nom` / `binome`),
`non_apparies` (avec `n_releves`).

## Examples

``` r
fl <- data.frame(CD_REF = c(1, 1, 2), id_placette = c("a", "b", "a"))
ind <- data.frame(cd_ref = 1, appariement = "nom")
indicator_match_rate(fl, ind)$taux_especes
#> [1] 0.5
```
