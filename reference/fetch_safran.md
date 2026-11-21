# Télécharger SAFRAN (SIM2 quotidien) et garder les mailles d'une emprise

Pour chaque année, télécharge (une fois, cache `cache_dir`) le fichier
`QUOT_SIM2_<année>.csv.gz` de meteo.data.gouv.fr (docs/referentiels.md,
§ 23, Licence Ouverte 2.0, « Source : Météo-France »), garde les mailles
dont le centre est à moins d'une demi-diagonale de maille (5,7 km) de
l'emprise, et écrit `emprise_<année>_<emprise>.csv` dans le cache. **Le
nom du fichier porte l'emprise** (`.cle_emprise_safran()`) : un fichier
filtré pour une autre emprise n'est jamais resservi (mission 035 :
l'ancien nom `emprise_<année>.csv`, sans emprise, avait resservi 12
mailles pour toute la GRECO D). Seules les colonnes lues par
[`read_safran()`](https://pobsteta.github.io/sylvostation/reference/read_safran.md)
sont écrites.

## Usage

``` r
fetch_safran(
  years,
  emprise,
  cache_dir,
  offline = FALSE,
  downloader = utils::download.file,
  lignes_par_bloc = 200000L
)
```

## Arguments

- years:

  Années (vecteur d'entiers).

- emprise:

  Emprise (bbox, sf ou `c(xmin, ymin, xmax, ymax)`, EPSG:2154).

- cache_dir:

  Dossier de cache.

- offline:

  `TRUE` : aucun téléchargement (seul le cache sert).

- downloader:

  Voir
  [`fetch_cached()`](https://pobsteta.github.io/sylvostation/reference/fetch_cached.md).

- lignes_par_bloc:

  Lignes lues à la fois : le fichier (environ 137 Mo compressé, toute la
  France) est filtré à la lecture, jamais chargé en entier.

## Value

Les chemins des fichiers `emprise_<année>_<emprise>.csv`.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_safran(1996:2025, c(1007000, 6790000, 1022000, 6805000), "data/cache/safran")
} # }
```
