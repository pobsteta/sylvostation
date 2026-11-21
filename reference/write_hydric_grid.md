# Écrire les couches de la carte hydrique

Écrit `hydrique.tif` dans `out_dir/<ser_code>/` (couches `is_topo`,
`nj_topo`, `is_plat`, `k_sv`, `ru_maille` de
[`hydric_stress_grid()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress_grid.md)),
en **COG** si le pilote GDAL `COG` est disponible, sinon en GeoTIFF
tuilé compressé, comme
[`write_outputs()`](https://pobsteta.github.io/sylvostation/reference/write_outputs.md).
Si `synthetic = TRUE`, le fichier est préfixé `synth_` (CLAUDE.md). Les
cellules hors de `forest` (couche `foret` de
[`forest_mask()`](https://pobsteta.github.io/sylvostation/reference/forest_mask.md))
sont mises à `NA`.

## Usage

``` r
write_hydric_grid(
  r,
  out_dir,
  ser_code,
  forest = NULL,
  synthetic = FALSE,
  cog = TRUE
)
```

## Arguments

- r:

  `SpatRaster` de
  [`hydric_stress_grid()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress_grid.md)
  (EPSG:2154).

- out_dir:

  Dossier racine des sorties.

- ser_code:

  Code SER (sous-dossier).

- forest:

  `NULL` ou `SpatRaster` du masque forestier (couche `foret`).

- synthetic:

  `TRUE` pour préfixer le fichier par `synth_`.

- cog:

  Demander un COG.

## Value

Un `data.frame` (`fichier`, `format`), de façon invisible.

## Examples

``` r
r <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                 resolution = 20, crs = "EPSG:2154", nlyrs = 5)
terra::values(r) <- matrix(1, 4, 5)
#> Warning: [setValues] values were recycled
names(r) <- c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille")
w <- write_hydric_grid(r, tempdir(), "D11", synthetic = TRUE)
basename(w$fichier)
#> [1] "synth_hydrique.tif"
```
