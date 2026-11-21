# Tronçons accessibles et accès restreint

Garde les tronçons dont `nature` est dans `natures`
([ACCESS_NATURES](https://pobsteta.github.io/sylvostation/reference/ACCESS_NATURES.md)),
en écartant les tronçons fictifs (`fictif`), ceux qui ne sont pas « En
service » (`etat_de_l_objet`) et ceux dont `acces_vehicule_leger` vaut «
Physiquement impossible ». Ajoute la colonne logique `acces_restreint` :
tronçon privé (`prive`), « Restreint aux ayants droit » ou « A péage ».
L'accès restreint est **signalé, pas exclu** : l'autorisation se demande
avant la sortie.

## Usage

``` r
filter_access(x, natures = ACCESS_NATURES)
```

## Arguments

- x:

  `sf` de tronçons BD TOPO (au moins la colonne `nature`).

- natures:

  Natures retenues.

## Value

`x` filtré, avec `acces_restreint` ; attribut `decompte` (tronçons lus
et gardés par nature).

## Examples

``` r
l <- sf::st_sf(nature = c("Chemin", "Sentier"), prive = c(TRUE, FALSE),
  geometry = sf::st_sfc(sf::st_linestring(rbind(c(1010000, 6795000), c(1010100, 6795000))),
                        sf::st_linestring(rbind(c(1010000, 6795100), c(1010100, 6795100))),
                        crs = 2154))
filter_access(l)
#> Simple feature collection with 1 feature and 3 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 1010000 ymin: 6795000 xmax: 1010100 ymax: 6795000
#> Projected CRS: RGF93 v1 / Lambert-93
#>   nature prive                       geometry acces_restreint
#> 1 Chemin  TRUE LINESTRING (1010000 6795000...            TRUE
```
