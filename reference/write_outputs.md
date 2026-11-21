# Écrire les sorties du catalogue

Seule fonction d'écriture du jeu de sorties : crée `out_dir/<ser_code>/`
et y écrit (formats ouverts) les rasters en GeoTIFF (**COG** si le
pilote GDAL `COG` est disponible, sinon GeoTIFF tuilé compressé), un
GeoPackage de la carte des types (polygones, lisible hors ligne dans
QGIS) et des tables CSV (séparateur `;`, décimale `.`, UTF-8). Si
`synthetic = TRUE`, **tous les fichiers sont préfixés `synth_`**
(CLAUDE.md) : le préfixe est la marque portée par les fichiers, car le
pilote COG ne conserve pas les balises
[`terra::metags`](https://rspatial.github.io/terra/reference/metags.html).
Le tableau « état de preuve » est écrit en CSV avec les autres tables.

## Usage

``` r
write_outputs(
  out_dir,
  ser_code,
  types,
  type_legend,
  gradients,
  uncertainty = NULL,
  tables = list(),
  evidence = evidence_table(),
  synthetic = TRUE,
  cog = TRUE
)
```

## Arguments

- out_dir:

  Dossier racine des sorties (`read_config()$out_dir`).

- ser_code:

  Code SER (sous-dossier).

- types:

  `SpatRaster` à une couche de codes entiers de types (EPSG:2154).

- type_legend:

  `data.frame` (`id`, `type`) : le type de chaque code de `types`.

- gradients:

  `SpatRaster` des gradients prédits.

- uncertainty:

  `SpatRaster` d'incertitude (écart-type, zone d'applicabilité...) ou
  `NULL`.

- tables:

  Liste nommée de `data.frame` écrits en CSV (le nom de l'élément fait
  le nom du fichier).

- evidence:

  Tableau d'état de preuve
  ([`evidence_table()`](https://pobsteta.github.io/sylvostation/reference/evidence_table.md)).

- synthetic:

  `TRUE` pour préfixer les fichiers par `synth_`.

- cog:

  Demander un COG (par défaut oui, si GDAL le permet).

## Value

Un `data.frame` (`fichier`, `format`) des fichiers écrits, de façon
invisible.

## Examples

``` r
if (FALSE) { # \dontrun{
write_outputs(tempdir(), "D11", types, legende, gradients, tables = list(types = tab))
} # }
```
