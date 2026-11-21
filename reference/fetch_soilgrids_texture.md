# Lire argile, sable, limon et cailloux de SoilGrids sur une emprise (Lambert-93, 250 m)

Lit, par
[`fetch_soilgrids_ph()`](https://pobsteta.github.io/sylvostation/reference/fetch_soilgrids_ph.md),
les 24 couches `clay`, `sand`, `silt`, `cfvo` (moyenne) des six horizons
de SoilGrids 2.0 (0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm), en
pourcentage, à 250 m en Lambert-93, et les met en cache. Licence CC BY
4.0 (ISRIC), à citer. Volume mesuré sur la GRECO D (mission 039) : 45
Mo. Exactitude sur la France non évaluée.

## Usage

``` r
fetch_soilgrids_texture(
  bbox,
  cache_dir,
  margin_m = 2000,
  offline = FALSE,
  reader = NULL
)
```

## Arguments

- bbox:

  Emprise `c(xmin, ymin, xmax, ymax)` ou `bbox` en Lambert-93
  (EPSG:2154).

- cache_dir:

  Dossier de cache.

- margin_m:

  Marge autour de `bbox` (m), pour que la moyenne dans 700 m des
  placettes du bord soit complète.

- offline:

  `TRUE` : aucun accès au réseau (seul le cache sert).

- reader:

  Fonction `function(url)` renvoyant un `SpatRaster` (par défaut
  [`terra::rast`](https://rspatial.github.io/terra/reference/rast.html)
  sur `/vsicurl/` ; remplaçable dans les tests).

## Value

Un vecteur nommé de chemins (`clay_0-5cm`, ...).

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_soilgrids_texture(c(909550, 6723356, 1060558, 6912236), "data/cache/soilgrids")
} # }
```
