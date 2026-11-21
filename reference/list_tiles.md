# Tableau d'assemblage LiDAR HD sur une emprise

Interroge la couche `IGNF_LIDAR-HD_METADONNEE:metadata` de la
Géoplateforme (WFS, `CQL_FILTER=WITHIN(...)` : le BBOX déborde sur les
voisines ; voir `docs/referentiels.md`, § 2), puis ne garde que les
dalles qui recoupent réellement l'emprise. L'identifiant d'une dalle est
`coordonnees_nw` (« x_min en km - y_max en km ») ; l'URL du nuage est
lue dans `url_npl`, jamais reconstruite.

## Usage

``` r
list_tiles(emprise, source = c("wfs", "file"), path = NULL)
```

## Arguments

- emprise:

  Un objet `sf`/`sfc` en EPSG:2154, une `bbox`, ou
  `c(xmin, ymin, xmax, ymax)` en EPSG:2154.

- source:

  `"wfs"` (réseau) ou `"file"` (lit `path`, une extraction de la
  métadonnée, pour les tests).

- path:

  Fichier de métadonnée (GeoJSON, GeoPackage...) si `source = "file"`.

## Value

Un `sf` (EPSG:2154) : `tile_id`, `url` (nuage COPC LAZ), `url_mnt` (MNT
IGN de contrôle), `date_debut`, `date_fin` (dates de vol),
`nombre_points`.

## Examples

``` r
if (FALSE) { # \dontrun{
list_tiles(c(xmin = 1014000, ymin = 6793000, xmax = 1016000, ymax = 6795000))
} # }
```
