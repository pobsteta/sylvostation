# Écrire le plan d'échantillonnage

Écrit dans `out_dir` : `plan_gnss.gpkg` (couche `plan`, EPSG:2154),
`plan_gnss.gpx` (points de passage en WGS84, EPSG:4326 : `name` =
identifiant, `desc` = rang et parent), `couverture.csv` et la carte
`plan_gnss.png` (forêt, tronçons, points et remplaçants). Préfixe
`synth_` et colonne `synthetic` si `synthetic = TRUE`.

## Usage

``` r
write_sampling_plan(
  plan,
  coverage,
  out_dir,
  access = NULL,
  forest = NULL,
  synthetic = FALSE
)
```

## Arguments

- plan:

  Résultat de
  [`sampling_plan()`](https://pobsteta.github.io/sylvostation/reference/sampling_plan.md).

- coverage:

  Résultat de
  [`sampling_coverage()`](https://pobsteta.github.io/sylvostation/reference/sampling_coverage.md)
  (ou `NULL`).

- out_dir:

  Dossier de sortie (créé si besoin).

- access, forest:

  Tronçons et forêt pour la carte (facultatifs).

- synthetic:

  Données synthétiques ?

## Value

Chemins écrits, de façon invisible.

## Examples

``` r
if (FALSE) { # \dontrun{
write_sampling_plan(p, sampling_coverage(p), tempdir())
} # }
```
