# Refuser un fichier synthétique en mode réel

Le mode réel ne remplace jamais une entrée par un jeu fabriqué
(CLAUDE.md). Arrêt si le nom du fichier commence par `synth_`, si une
colonne `synthetic` vaut `TRUE` (CSV, TXT, GeoPackage, classeur `.xlsx`
si `readxl` est installé) ou si un raster porte la balise
`synthetic = TRUE`
([`terra::metags`](https://rspatial.github.io/terra/reference/metags.html)).

## Usage

``` r
assert_not_synthetic(paths, entree = "entrée")
```

## Arguments

- paths:

  Chemins des fichiers.

- entree:

  Nom de l'entrée (clé de config.yml), pour le message.

## Value

`paths`, de façon invisible, si aucun n'est synthétique.

## Examples

``` r
f <- tempfile("synth_gnss_", fileext = ".csv")
writeLines("id,x,y", f)
try(assert_not_synthetic(f, "gnss_path"))
#> Error : Mode réel : `gnss_path` désigne un jeu synthétique (préfixe synth_) : /tmp/RtmppotWvD/synth_gnss_2cf12b3aedd3.csv. Une entrée absente se déclare (retirer la clé), elle ne se remplace pas.
```
