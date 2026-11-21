# Grille vide alignée sur des multiples de la résolution

Crée un `SpatRaster` vide (sans valeurs) en Lambert-93 couvrant
l'emprise, dont les bords sont arrondis vers l'extérieur à des multiples
de `res`. Ainsi deux grilles de même résolution se superposent cellule à
cellule, quelle que soit l'emprise.

## Usage

``` r
build_grid(emprise, res)
```

## Arguments

- emprise:

  Un objet `sf`/`sfc` en EPSG:2154, une `bbox` de
  [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html),
  ou un vecteur `c(xmin, ymin, xmax, ymax)` (x = est, y = nord, mètres,
  EPSG:2154).

- res:

  Résolution en mètres (cellules carrées).

## Value

Un `SpatRaster` d'une couche, vide, en EPSG:2154.

## Examples

``` r
g <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099), res = 20)
terra::ext(g)
#> SpatExtent : 1007000, 1007180, 6790000, 6790100 (xmin, xmax, ymin, ymax)
```
