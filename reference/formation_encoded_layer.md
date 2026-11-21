# Couche numérique de la formation dominante encodée, calculée à maille de 100 m

Formation (`NOTATION`) **dominante dans un disque de 700 m**, remplacée
par sa valeur de
[`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
(trophique moyen rétréci de la formation sur les placettes de la GRECO),
pour la carte (mission 035). Le mode du disque est calculé à `res` m
(100 m par défaut) : avec des centaines de formations, un calcul à la
maille de la grille (20 m) coûterait des dizaines de minutes pour un
prédicteur lisse à l'échelle de 700 m ; la couche est ensuite ramenée
sur `grid` (plus proche voisin). Une formation absente de l'encodage
(jamais dominante sur une placette) reçoit la moyenne générale.

## Usage

``` r
formation_encoded_layer(
  geol,
  grid,
  encoding,
  radius = 700,
  res = 100,
  name = "coarse_formation_enc"
)
```

## Arguments

- geol:

  `sf` polygonal en Lambert-93 avec `NOTATION`
  ([`read_geology()`](https://pobsteta.github.io/sylvostation/reference/read_geology.md)).

- grid:

  `SpatRaster` modèle (Lambert-93).

- encoding:

  Résultat de
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
  (niveaux = `NOTATION`).

- radius:

  Rayon du disque (m, 700).

- res:

  Maille du calcul du mode (m), multiple de la maille de `grid`.

- name:

  Nom de la couche (`"coarse_formation_enc"`).

## Value

Un `SpatRaster` numérique à une couche sur `grid`.

## Examples

``` r
g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg", package = "sylvostation"),
                 quiet = TRUE)
grid <- terra::rast(xmin = 1007000, xmax = 1010000, ymin = 6790000, ymax = 6793000,
                    resolution = 100, crs = "EPSG:2154")
e <- target_encoding(g$NOTATION[1:20], seq_len(20), k = 5)
formation_encoded_layer(g, grid, e, res = 100)
#> class       : SpatRaster
#> size        : 30, 30, 1  (nrow, ncol, nlyr)
#> resolution  : 100, 100  (x, y)
#> extent      : 1007000, 1010000, 6790000, 6793000  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> name        : coarse_formation_enc
#> min value   :                 10.5
#> max value   :                 10.5
```
