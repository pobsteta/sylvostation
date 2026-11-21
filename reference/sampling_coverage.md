# Diagnostic de couverture du plan

Compare la distribution de chaque couche dans l'échantillon (points de
rang 0) à celle de la forêt (toutes les cellules renseignées) et des
cellules candidates : test de Kolmogorov-Smirnov à deux échantillons
([`stats::ks.test`](https://rdrr.io/r/stats/ks.test.html), échantillon
contre forêt) et quantiles 5, 25, 50, 75 et 95 % pour les couches
continues ; proportions par classe pour les couches catégorielles.

## Usage

``` r
sampling_coverage(plan, frame = attr(plan, "frame"))
```

## Arguments

- plan:

  Résultat de
  [`sampling_plan()`](https://pobsteta.github.io/sylvostation/reference/sampling_plan.md).

- frame:

  Base de sondage
  ([`sampling_frame()`](https://pobsteta.github.io/sylvostation/reference/sampling_frame.md))
  ; par défaut `attr(plan, "frame")`.

## Value

`data.frame` : `variable`, `indicateur` (`ks_D`, `ks_p`, `q05`... ou
`classe:<nom>`), `echantillon`, `candidats`, `foret`.

## Examples

``` r
if (FALSE) { # \dontrun{
sampling_coverage(p)
} # }
```
