# Tronçons de route de la BD TOPO sur une emprise

Lit la couche `BDTOPO_V3:troncon_de_route` de la Géoplateforme (WFS
2.0.0, GeoJSON, EPSG:2154 ; docs/referentiels.md, § 29), filtrée par
l'emprise en Lambert-93 (`BBOX=...,urn:ogc:def:crs:EPSG::2154`, x = est
puis y = nord), par pages. Avec `source = "file"`, lit un extrait local
(aucun réseau : mode des tests). Le résultat est ensuite filtré par
[`filter_access()`](https://pobsteta.github.io/sylvostation/reference/filter_access.md)
si `filter = TRUE`.

## Usage

``` r
get_access_network(
  emprise,
  source = c("wfs", "file"),
  path = NULL,
  filter = TRUE,
  taille_page = 5000L
)
```

## Arguments

- emprise:

  Objet `sf`/`sfc` en EPSG:2154, `bbox`, ou `c(xmin, ymin, xmax, ymax)`.

- source:

  `"wfs"` (réseau) ou `"file"` (lit `path`).

- path:

  Fichier vectoriel local si `source = "file"`.

- filter:

  Appliquer
  [`filter_access()`](https://pobsteta.github.io/sylvostation/reference/filter_access.md)
  (`TRUE` par défaut).

- taille_page:

  Nombre de tronçons par requête.

## Value

Un `sf` de lignes en EPSG:2154.

## Examples

``` r
l <- sf::st_sf(nature = "Chemin", geometry = sf::st_sfc(sf::st_linestring(
  rbind(c(1010000, 6795000), c(1010500, 6795000))), crs = 2154))
f <- tempfile(fileext = ".gpkg"); sf::st_write(l, f, quiet = TRUE)
nrow(get_access_network(c(1009000, 6794000, 1011000, 6796000), "file", f))
#> [1] 1
```
