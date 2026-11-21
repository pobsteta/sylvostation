# Réunir la table des types à la couche des polygones du GeoPackage

[`write_outputs()`](https://pobsteta.github.io/sylvostation/reference/write_outputs.md)
écrit dans `types.gpkg` une couche de polygones `types` et une table
attributaire sans géométrie `table_types`. Une table sans géométrie n'a
pas de système de coordonnées : en mode réel, ses colonnes sont jointes
(par `type`) aux polygones, qui restent en EPSG:2154, puis la table est
retirée du GeoPackage (elle reste dans `types.csv`). Fonction d'écriture
: modifie le fichier en place.

## Usage

``` r
write_types_gpkg_real(path, type_table)
```

## Arguments

- path:

  Chemin de `types.gpkg`.

- type_table:

  Table des types (colonne `type`).

## Value

`path`, de façon invisible.

## Examples

``` r
f <- tempfile(fileext = ".gpkg")
p <- sf::st_sf(type_id = 1L, type = "T1",
  geometry = sf::st_sfc(sf::st_point(c(1015500, 6793500)), crs = 2154))
sf::st_write(p, f, layer = "types", quiet = TRUE)
sf::st_write(data.frame(type = "T1", n = 3), f, layer = "table_types", append = TRUE, quiet = TRUE)
write_types_gpkg_real(f, data.frame(type = "T1", n = 3))
sf::st_layers(f)$name
#> [1] "types"
```
