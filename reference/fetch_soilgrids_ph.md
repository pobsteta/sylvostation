# Lire le pH SoilGrids sur une emprise et le mettre en cache (Lambert-93, 250 m)

Lit une fenêtre du raster virtuel SoilGrids 2.0 `phh2o` (pH × 10, 250 m,
projection Goode interrompue de Homolosine), la reprojette en Lambert-93
à 250 m (bilinéaire), divise par 10 et écrit un GeoTIFF dans
`cache_dir`. **Le nom du fichier porte la couche et l'emprise** : un
fichier d'une autre emprise n'est jamais resservi. Seule la fenêtre est
lue (quelques Mo), jamais le raster mondial. Licence CC BY 4.0 (ISRIC),
à citer. Exactitude sur la France non évaluée.

## Usage

``` r
fetch_soilgrids_ph(
  bbox,
  cache_dir,
  layer = "phh2o_0-5cm_mean",
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

- layer:

  Couche (`"phh2o_0-5cm_mean"` par défaut : 0-5 cm, moyenne). Depuis la
  mission 039, aussi `clay`, `sand`, `silt` (g/kg, rendus en %) et
  `cfvo` (cm³/dm³, rendu en % du volume) : toutes ces couches sont
  stockées × 10 par SoilGrids.

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

Le chemin du GeoTIFF (pH en unités de pH, EPSG:2154, 250 m).

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_soilgrids_ph(c(909550, 6723356, 1060558, 6912236), "data/cache/soilgrids")
} # }
```
