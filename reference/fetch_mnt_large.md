# MNT de 250 m (BD ALTI) sur une emprise, en cache

Lit la BD ALTI de l'IGN (Licence Ouverte Etalab 2.0, fiche
`IGNF_BD-ALTI`) par le WMS raster de la Géoplateforme (couche
`ELEVATION.ELEVATIONGRIDCOVERAGE`, GeoTIFF Float32 ; source vérifiée le
2026-11-20), par tuiles d'au plus 4 000 pixels de côté, à `res / 2` m,
puis agrège par moyenne 2 × 2 à `res` m (Lambert-93). Le
rééchantillonnage du service est non documenté (à vérifier). Les valeurs
inférieures à −500 m (absence de donnée, mer) sont mises à `NA`. Sert à
l'altitude des mailles SAFRAN et à la température corrigée moyennée dans
700 m (couche large) ; jamais extrait tel quel aux placettes IFN (couche
`mnt_250`, variable fine par son préfixe).

## Usage

``` r
fetch_mnt_large(
  bbox,
  cache_dir,
  res = 250,
  margin_m = 2000,
  offline = FALSE,
  downloader = NULL
)
```

## Arguments

- bbox:

  Emprise `c(xmin, ymin, xmax, ymax)` ou `bbox` en Lambert-93
  (EPSG:2154).

- cache_dir:

  Dossier de cache.

- res:

  Maille rendue (m), 250 par défaut.

- margin_m:

  Marge autour de `bbox` (m).

- offline:

  `TRUE` : aucun accès au réseau (seul le cache sert).

- downloader:

  Fonction `function(url, destfile)` (par défaut
  [`utils::download.file`](https://rdrr.io/r/utils/download.file.html)
  en binaire ; remplaçable dans les tests).

## Value

Le chemin du GeoTIFF (`mnt_250`, m, EPSG:2154).

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_mnt_large(c(909550, 6723356, 1060558, 6912236), "data/cache/bdalti")
} # }
```
