# Dérivés du terrain ramenés à la grille

Calcule les dérivés de
[`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
sur le MNT à 5 m (avec MRVBF et réseau hydrographique en mode réel),
puis les agrège (moyenne) à la grille (ADR 0004). Le MNT est d'abord
bordé de `NA` sur le plus grand rayon du TPI (la fenêtre doit tenir dans
le raster, même sur une petite emprise), puis le résultat est rogné.

## Usage

``` r
real_terrain(
  dtm,
  grid,
  streams = NULL,
  mrvbf = TRUE,
  tpi_radii = c(100, 300),
  mrvbf_res = NULL
)
```

## Arguments

- dtm:

  `SpatRaster` du MNT (5 m).

- grid:

  `SpatRaster` modèle.

- streams:

  Réseau (`sf` de lignes) ou `NULL`.

- mrvbf:

  Calculer le MRVBF (`TRUE` en mode réel).

- tpi_radii:

  Rayons du TPI (m).

- mrvbf_res:

  Maille (m) du calcul du MRVBF, passée à
  [`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
  (`mrvbf_res`, `mrvbf_res_m` de `config.yml`) ; `NULL` = maille du MNT.

## Value

Un `SpatRaster` sur `grid` : couches de
[`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
et `altitude` (couches éventuellement vides : voir
[`empty_layers()`](https://pobsteta.github.io/sylvostation/reference/empty_layers.md)).

## Examples

``` r
# \donttest{
f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
d <- terra::rast(f)
g <- build_grid(terra::ext(d)[c(1, 3, 2, 4)], 20)
suppressWarnings(names(real_terrain(d, g, mrvbf = FALSE)))
#>  [1] "pente"           "exposition_cos"  "exposition_sin"  "courbure"       
#>  [5] "courbure_plan"   "courbure_profil" "tpi_100"         "tpi_300"        
#>  [9] "twi"             "surface_drainee" "mrvbf"           "hauteur_reseau" 
#> [13] "rayonnement"     "altitude"       
# }
```
