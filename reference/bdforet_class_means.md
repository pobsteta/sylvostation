# Moyennes du trophique de la carte par classe de peuplement pur (BD Forêt)

Pour chaque classe de peuplement **pur** de la BD Forêt v2 (hêtre,
chênes décidus, sapin ou épicéa, etc.), moyenne du trophique de la carte
à l'**intérieur** des polygones (tampon intérieur de `buffer_m`,
provisoire, sans source : marge de lisière et d'écart de position),
moyenne des moyennes par polygone, et nombre de polygones. Comparaison
de **lecture**, pas une validation : la carte n'a pas vu l'essence, mais
le modèle a été entraîné sur des placettes dont l'essence est corrélée
au climat et à la roche. Seules des moyennes par classe sont rendues
(aucune géométrie).

## Usage

``` r
bdforet_class_means(forest, trophic, buffer_m = 50, min_polygones = 5L)
```

## Arguments

- forest:

  `sf` BD Forêt (EPSG:2154) avec `code_tfv`.

- trophic:

  `SpatRaster` du trophique (EPSG:2154).

- buffer_m:

  Tampon intérieur (m).

- min_polygones:

  Polygones minimaux pour que la classe soit jugée.

## Value

Un `data.frame` : `classe`, `n_polygones`, `n_cellules`,
`moyenne_carte`, `ecart_type_polygones`, `suffisant`.

## Examples

``` r
p <- sf::st_sf(code_tfv = "FF1-09-09", geometry = sf::st_sfc(sf::st_polygon(list(
  rbind(c(1e6, 6.8e6), c(1e6 + 400, 6.8e6), c(1e6 + 400, 6.8e6 + 400), c(1e6, 6.8e6 + 400),
        c(1e6, 6.8e6)))), crs = 2154))
r <- terra::rast(xmin = 1e6, xmax = 1e6 + 400, ymin = 6.8e6, ymax = 6.8e6 + 400,
                 resolution = 20, crs = "EPSG:2154", vals = 4.5)
bdforet_class_means(p, r, buffer_m = 50, min_polygones = 1)
#>   classe n_polygones n_cellules moyenne_carte ecart_type_polygones suffisant
#> 1  Hêtre           1        225           4.5                   NA      TRUE
```
