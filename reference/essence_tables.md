# Tables publiables du contrôle par essence et de la sensibilité

Met en forme les résultats pour
[`write_outputs()`](https://pobsteta.github.io/sylvostation/reference/write_outputs.md)
: trois tables, dont la première (`controle_essence`) place **en tête le
défaut d'amplitude** (pente prévu contre observé par essence : les
prédictions hors pli sont écrasées vers la moyenne).

## Usage

``` r
essence_tables(controle = NULL, sensibilite = NULL)
```

## Arguments

- controle:

  Résultat de
  [`essence_control()`](https://pobsteta.github.io/sylvostation/reference/essence_control.md),
  ou `NULL` (table omise).

- sensibilite:

  Résultat de
  [`essence_sensitivity()`](https://pobsteta.github.io/sylvostation/reference/essence_sensitivity.md),
  ou `NULL` (table omise) : le contrôle est publié même sans la
  sensibilité.

## Value

Une liste nommée de `data.frame` : `controle_essence`,
`controle_essence_par_essence`, `sensibilite_essence`.

## Examples

``` r
sens <- list(resume = data.frame(bloc_m = 1, variante = "base", r2 = 0.2, rmse = 1,
                                 gain_r2 = 0, gain_rmse = 0, avertissement = "x"),
              par_pli = data.frame(bloc_m = 1, variante = "tfv", pli = 1L, n = 10L, r2 = 0.2,
                                   gain_r2 = 0.05, avertissement = "x"))
ctl <- list(global = data.frame(pente_amplitude = 0.3, bloc_m = 1), par_essence = data.frame(a = 1))
names(essence_tables(ctl, sens))
#> [1] "controle_essence"             "controle_essence_par_essence"
#> [3] "sensibilite_essence"         
```
