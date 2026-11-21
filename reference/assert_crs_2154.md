# Vérifier qu'un objet spatial est en Lambert-93

Vérifie le code EPSG:2154, puis la plausibilité des coordonnées :
l'emprise doit tenir dans des bornes **approximatives** de la France
métropolitaine en Lambert-93, x (est) entre 0 et 1 300 000 et y (nord)
entre 6 000 000 et 7 200 000 mètres. Cela détecte les x/y inversés et
les degrés étiquetés à tort en 2154.

## Usage

``` r
assert_crs_2154(x)
```

## Arguments

- x:

  Un objet `sf`, `sfc`, `SpatRaster` ou `SpatVector`.

## Value

`x` de façon invisible ; erreur si le CRS est absent, n'est pas
EPSG:2154 ou si les coordonnées sont implausibles.

## Examples

``` r
p <- sf::st_sfc(sf::st_point(c(1010000, 6795000)), crs = 2154)
assert_crs_2154(p)
```
