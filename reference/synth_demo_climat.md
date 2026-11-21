# Climat synthétique à maille de 1 km pour le mode démo

Trois couches nommées selon la convention de
[`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md)
: `p_sv` (précipitations de la saison de végétation, mm), `etp_sv` (mm)
et `t_moy` (°C), à maille de 1 000 m sur l'emprise, gradient régulier
plus un bruit lisse. **Valeurs fabriquées**, sans lien avec le climat
réel.

## Usage

``` r
synth_demo_climat(emprise, res = 1000, seed = 2L)
```

## Arguments

- emprise:

  Vecteur `c(xmin, ymin, xmax, ymax)` en EPSG:2154 (x = est, y = nord).

- res:

  Maille en mètres (1 000 par défaut).

- seed:

  Graine.

## Value

Un `SpatRaster` de trois couches, balisé `synthetic`.

## Examples

``` r
terra::nlyr(synth_demo_climat(c(1007000, 6790000, 1022000, 6805000)))
#> [1] 3
```
