# Lire une carte de référence

Lit un GeoTIFF de référence (EPSG:2154 exigé) dont les couches portent
les noms de la convention de ce paquet : `trophic`, `hydric`, `bioclim`
(gradients) et, facultativement, `type3` (code à trois chiffres). Le
format réel des rasters d'AgroParisTech n'étant pas connu, cette
convention est **à vérifier** à leur réception. Un fichier dont le nom
commence par `synth_` ou balisé `synthetic` donne un raster balisé
synthétique.

## Usage

``` r
load_reference(path, layers = NULL)
```

## Arguments

- path:

  Chemin du GeoTIFF.

- layers:

  Noms de couches exigés (défaut : au moins une parmi `trophic`,
  `hydric`, `bioclim`, `type3` doit exister).

## Value

Un `SpatRaster` en EPSG:2154.

## Examples

``` r
f <- system.file("extdata", "synth_reference.tif", package = "sylvostation")
if (nzchar(f)) names(load_reference(f))
#> [1] "trophic" "hydric"  "bioclim"
```
