# Carte de référence synthétique (trois gradients à 50 m)

Agrège les gradients vrais
([`synth_demo_truth()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_truth.md))
à `res` mètres et y ajoute un bruit, pour fabriquer un **substitut** de
la carte de référence de Gégout et al. (2008), dont les rasters
(AgroParisTech) manquent. C'est l'origine de
`inst/extdata/synth_reference.tif` (script
`inst/scripts/synth_reference.R`).

## Usage

``` r
synth_demo_reference(truth, res = 50, noise_sd = 0.3, seed = 3L)
```

## Arguments

- truth:

  `SpatRaster` de
  [`synth_demo_truth()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_truth.md).

- res:

  Maille de la référence en mètres (50, comme la carte publiée). Si elle
  n'est pas un multiple de la maille de `truth` (50 m sur 20 m), moyenne
  par rééchantillonnage.

- noise_sd:

  Bruit ajouté.

- seed:

  Graine.

## Value

Un `SpatRaster` `trophic`, `hydric`, `bioclim`, balisé `synthetic`.

## Examples

``` r
if (FALSE) { # \dontrun{
synth_demo_reference(truth)
} # }
```
