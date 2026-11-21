# Lire et valider la configuration

Lit un fichier `config.yml` (paquet `yaml`) et vérifie les types, le
système de coordonnées (EPSG:2154 uniquement) et la cohérence de
l'emprise.

## Usage

``` r
read_config(path = "config.yml")
```

## Arguments

- path:

  Chemin du fichier YAML. Par défaut `"config.yml"`.

## Value

Une liste nommée : `ser_code`, `emprise_test` (xmin, ymin, xmax, ymax,
crs), `buffer_m`, `resolution_m`, `crs`, `data_dir`, `laz_dir`,
`out_dir`, `ifn_precision_m`, `demo` (booléen, `FALSE` si la clé est
absente : en mode démo, le pipeline tourne sans réseau sur les jeux
d'essai synthétiques de `inst/extdata`), et les clés du mode réel
(mission 016, valeurs par défaut si absentes) : `offline` (`FALSE` ;
`TRUE` = mode réel sans réseau sur les extraits réels de
`inst/extdata`), `max_tiles` (`NULL` = toutes les dalles), `emprise`
(`"test"` ou `"ser"`), `mrvbf_res_m` (maille en m du MNT sur lequel le
MRVBF est calculé, multiple de 5 ; défaut `resolution_m` ; provisoire, à
vérifier, mission 027), `lidar_block_size` (3), `lidar_buffer_m` (20),
`lidar_ncores` (3), `taxref_version` (`"18"`, figée), `indicator_source`
(`"tichy"`), `ru_source` (`"euptf2"`), `safran_annees` (1996-2025),
`saison_vegetation` (mois 4 à 9), `bdcharm_departements`, `gbif_method`
(`"search"`), `forest_mask` (`TRUE`), `forest_height_m` (5),
`cache_dir`, la carte hydrique (mission 021, provisoires) :
`solar_linke` (3), `solar_albedo` (0,2), `solar_step_h` (0,5),
`hydric_pas_k` (0,02), `hydric_n_controle` (30), la descente d'échelle
du climat (mission 033, provisoires) : `safran_interpolation`
(`"bilineaire"` ou `"proche"`), `hydric_node_res_m` (1000),
`ru_min_placettes` (5), la calibration sur la GRECO (mission 035,
provisoires) : `litho_min_cover` (0,5), `litho_encoding_k` (10),
`soilgrids_ph` (`TRUE`), `cv_block_m` (`NULL` : portée estimée de la
réponse) `cv_block_sensibilite_m` (8 358 m) et `cv_min_blocs_par_pli`
(4), les choix de la mission 039 : `climat_temperature` (`"corrigee"` ou
`"bilineaire"`), `trophique_climat` (`"sans"` par défaut, décision de
Pascal du 2026-11-20 ; options `"actuel"` et `"corrige"`), `ru_carte`
(`"apprise"` ou `"maille"`), `mnt_large_res_m` (250), `bilan_lateral`
(`FALSE`), `bilan_lateral_ru_mm` (−30, 0, 60) et `bilan_lateral_coef`
(coefficients du tableau 20 de Piedallu et al. 2006, à vérifier),
l'entrée optionnelle `mnt_large_path` (MNT de 250 m local, mode hors
ligne), l'entrée optionnelle `soilgrids_texture_path` (`NULL` par défaut
: GeoTIFF à 24 couches de textures et cailloux SoilGrids, mode hors
ligne, mission 039b), `ifn_archive_url` et `taxref_url` (sans valeur par
défaut : seule source, config.yml ; exigées en ligne), et les entrées
optionnelles `gnss_path`, `reference_path`, `soil_paths`, `tichy_path`
(`NULL` si absentes : jamais remplacées).

## Examples

``` r
f <- tempfile(fileext = ".yml")
writeLines(c(
  'ser_code: "D11"',
  "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
  "buffer_m: 5000", "resolution_m: 20", "crs: 2154",
  "data_dir: data", "laz_dir: data/laz", "out_dir: data/sorties",
  "ifn_precision_m: 700"), f)
read_config(f)$ser_code
#> [1] "D11"
```
