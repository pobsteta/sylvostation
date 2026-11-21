# URL d'une page de la requête WFS CarHab (Géoplateforme)

Requête vérifiée au § 26.2 de `docs/referentiels.md` : type
`Carhab_habitat:habitats_carhab`, filtre CQL `INTERSECTS` en EPSG:2154,
pagination `COUNT` / `STARTINDEX` (tri stable sur `id_polygone_carhab`).

## Usage

``` r
carhab_wfs_url(bbox, occupation = "foret", start = 0L, count = 500L)
```

## Arguments

- bbox:

  Emprise `c(xmin, ymin, xmax, ymax)` en Lambert-93 (x = est, y = nord).

- occupation:

  Valeur du champ `occupation` (défaut `"foret"`), ou `NULL`.

- start, count:

  Index de départ et taille de page.

## Value

Une chaîne (URL).

## Examples

``` r
carhab_wfs_url(c(1007000, 6790000, 1022000, 6805000))
#> [1] "https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAMES=Carhab_habitat:habitats_carhab&SRSNAME=EPSG:2154&SORTBY=id_polygone_carhab&COUNT=500&STARTINDEX=0&CQL_FILTER=INTERSECTS%28geom%2CSRID%3D2154%3BPOLYGON%28%281007000%206790000%2C1022000%206790000%2C1022000%206805000%2C1007000%206805000%2C1007000%206790000%29%29%29%20AND%20occupation%3D%27foret%27"
```
