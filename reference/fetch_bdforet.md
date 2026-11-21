# Télécharger la BD Forêt v2 (formation végétale) sur une emprise

Lit la couche WFS `LANDCOVER.FORESTINVENTORY.V2:formation_vegetale` de
la Géoplateforme (`docs/referentiels.md`, § 4), par pages de 5 000
entités, en EPSG:2154, et la met en cache. **Licence contradictoire**
(Licence Ouverte pour data.gouv.fr, « conditions générales d'utilisation
IGN » dans les métadonnées livrées : § 33.5 bis et § 36) : le cache
reste dans `data/` (hors dépôt) et rien n'en est publié, hors moyennes
par classe.

## Usage

``` r
fetch_bdforet(bbox, cache_dir = file.path("data", "cache", "bdforet"))
```

## Arguments

- bbox:

  Emprise : `bbox` de `sf` en EPSG:2154.

- cache_dir:

  Dossier du cache.

## Value

Un `sf` (EPSG:2154) avec `code_tfv`, `tfv`, `essence`.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_bdforet(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000),
                          crs = 2154), tempdir())
} # }
```
