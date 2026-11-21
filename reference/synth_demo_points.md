# Points synthétiques (ancrage ou relevés « GNSS ») du mode démo

Tire `n` points au hasard dans l'emprise des prédicteurs (moins une
marge de 350 m), y lit les prédicteurs et les gradients vrais
([`synth_demo_truth()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_truth.md))
bruités, et fabrique des observables de terrain (`pente_obs`, `humus`,
`position`). Les points portent `loc_precision_m = 10` (points précis :
l'extraction fine y est permise) et `synthetic = TRUE`. **La règle
bloquante est appliquée** :
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
est appelée avant l'extraction. Remplace, en démo, les points d'ancrage
GBIF (mission 007, non intégrée) et les relevés GNSS (absents).

## Usage

``` r
synth_demo_points(
  predictors,
  truth,
  n = 300L,
  noise_sd = 0.25,
  seed = 11L,
  loc_precision_m = 10
)
```

## Arguments

- predictors:

  `SpatRaster` de
  [`demo_predictors()`](https://pobsteta.github.io/sylvostation/reference/demo_predictors.md).

- truth:

  `SpatRaster` de
  [`synth_demo_truth()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_truth.md).

- n:

  Nombre de points.

- noise_sd:

  Écart-type du bruit ajouté aux gradients.

- seed:

  Graine.

- loc_precision_m:

  Précision de localisation (m) posée sur les points.

## Value

Un `sf` de points en EPSG:2154 : `x`, `y`, prédicteurs, gradients,
observables, `loc_precision_m`, `synthetic`.

## Examples

``` r
if (FALSE) { # \dontrun{
synth_demo_points(predictors, truth, n = 50)
} # }
```
