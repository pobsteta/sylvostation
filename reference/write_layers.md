# Écrire les couches de la mission 039 (température corrigée, RU de carte, bilan latéral)

Écrit chaque `SpatRaster` non `NULL` de `layers` dans
`out_dir/<ser_code>/<nom>.tif`, en COG si possible (comme
[`write_hydric_grid()`](https://pobsteta.github.io/sylvostation/reference/write_hydric_grid.md)),
préfixé `synth_` si `synthetic = TRUE`.

## Usage

``` r
write_layers(layers, out_dir, ser_code, synthetic = FALSE, cog = TRUE)
```

## Arguments

- layers:

  Liste nommée de `SpatRaster` (EPSG:2154) ou `NULL`.

- out_dir:

  Dossier racine des sorties.

- ser_code:

  Code SER (sous-dossier).

- synthetic:

  `TRUE` pour préfixer les fichiers par `synth_`.

- cog:

  Demander un COG.

## Value

Un `data.frame` (`fichier`, `format`), de façon invisible.

## Examples

``` r
r <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                 resolution = 25, crs = "EPSG:2154", vals = 9)
names(r) <- "t_corr"
basename(write_layers(list(temperature_corrigee = r, vide = NULL), tempdir(), "D11",
                      synthetic = TRUE)$fichier)
#> [1] "synth_temperature_corrigee.tif"
```
