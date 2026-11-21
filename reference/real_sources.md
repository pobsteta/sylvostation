# Sources du mode réel (fichiers locaux ou téléchargement)

Résout, pour chaque entrée du mode réel, où la lire. Avec
`offline: true`, ce sont les **extraits réels** de `inst/extdata`
(jamais un jeu `synth_`) ; sinon les sources publiques de
`docs/referentiels.md`, mises en cache sous `cfg$data_dir/cache`. Les
entrées optionnelles (`gnss_path`, `reference_path`, `soil_paths`)
valent `NULL` quand elles sont absentes : elles ne sont jamais
remplacées.

## Usage

``` r
real_sources(cfg, extdata = system.file("extdata", package = "sylvostation"))
```

## Arguments

- cfg:

  Configuration de
  [`read_config()`](https://pobsteta.github.io/sylvostation/reference/read_config.md)
  (mode réel).

- extdata:

  Dossier des extraits (`inst/extdata` du paquet).

## Value

Une liste nommée de sources : `offline`, `ser`, `laz`, `hydro`, `geol`,
`ifn_dir`, `taxref`, `tichy`, `safran`, `gnss`, `reference`, `soils`.

## Details

La version de TAXREF de `cfg$taxref_version` doit figurer dans le nom du
fichier TAXREF utilisé (`v18`...) : sinon la fonction s'arrête.

## Examples

``` r
f <- tempfile(fileext = ".yml")
writeLines(c('ser_code: "D11"',
  "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
  "buffer_m: 5000", "resolution_m: 20", "crs: 2154", "data_dir: data",
  "laz_dir: data/laz", "out_dir: data/sorties", "ifn_precision_m: 700",
  "demo: false", "offline: true"), f)
names(real_sources(read_config(f)))
#> [1] "ser"     "laz"     "hydro"   "geol"    "ifn_dir" "taxref"  "tichy"  
#> [8] "safran"  "offline"
```
