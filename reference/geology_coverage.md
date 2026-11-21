# Part de l'emprise non couverte par la géologie (départements BD Charm-50)

La BD Charm-50 est téléchargée par département (`bdcharm_departements`
de config.yml, liste explicite faute de couche des départements
vérifiée). Avec `emprise: ser`, la SER peut déborder de ces départements
: la fonction mesure la part de l'emprise qu'aucune formation ne couvre
et **avertit** au-delà de `tol`.

## Usage

``` r
geology_coverage(geol, emprise, departements = character(0), tol = 0.01)
```

## Arguments

- geol:

  `sf` de
  [`read_geology()`](https://pobsteta.github.io/sylvostation/reference/read_geology.md).

- emprise:

  `sf`/`sfc` (EPSG:2154), par exemple
  [`real_extent()`](https://pobsteta.github.io/sylvostation/reference/real_extent.md).

- departements:

  Départements lus (pour le message).

- tol:

  Part tolérée (0,01).

## Value

La part non couverte (0 à 1), de façon invisible.

## Examples

``` r
g <- read_geology(system.file("extdata", "bdcharm50_emprise_test.gpkg",
                              package = "sylvostation"))
e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                                 ymax = 6805000), crs = sf::st_crs(2154)))
geology_coverage(g, e, c("067", "068", "088"))
```
