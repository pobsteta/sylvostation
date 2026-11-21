# Couche numérique de la lithologie encodée, pour la carte

Remplace chaque classe du raster
[`dominant_lithology()`](https://pobsteta.github.io/sylvostation/reference/dominant_lithology.md)
par sa valeur de
[`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
(trophique moyen rétréci de la classe, calculé sur les placettes de la
GRECO) : la carte est prédite avec la même variable que celle de
l'apprentissage. Une classe absente de l'encodage reçoit la moyenne
générale
([`apply_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/apply_target_encoding.md)).

## Usage

``` r
lithology_encoded_layer(litho_dom, encoding, name = "coarse_litho_enc")
```

## Arguments

- litho_dom:

  `SpatRaster` catégoriel de
  [`dominant_lithology()`](https://pobsteta.github.io/sylvostation/reference/dominant_lithology.md).

- encoding:

  Résultat de
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
  (niveaux = classes lithologiques).

- name:

  Nom de la couche (`"coarse_litho_enc"`).

## Value

Un `SpatRaster` numérique à une couche.

## Examples

``` r
r <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000200,
                 ymin = 6.8e6, ymax = 6800200, crs = "EPSG:2154")
terra::values(r) <- c(1, 2, 1, 2)
levels(r) <- data.frame(id = 1:2, classe = c("granite", "gres"))
e <- target_encoding(c("granite", "gres"), c(5, 3), k = 0)
terra::values(lithology_encoded_layer(r, e))[, 1]
#> [1] 5 3 5 3
```
