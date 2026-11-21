# Base de sondage du plan d'échantillonnage

Tableau des cellules forestières de la grille dont toutes les couches
sont renseignées (la distribution de référence de l'hypercube), avec
leur coût d'accès
([`access_cost()`](https://pobsteta.github.io/sylvostation/reference/access_cost.md))
et la colonne `candidat` : cellule tirable, c'est-à-dire à au plus
`cost_max_m` d'un tronçon accessible, à voisinage 3 × 3 homogène
([`homogeneous_cells()`](https://pobsteta.github.io/sylvostation/reference/homogeneous_cells.md))
et **sans tronçon retenu dans ce voisinage 3 × 3** (un relevé ne tombe
ni sur la route ni sur son bord ; même critère de voisinage que
l'homogénéité). Les couches entièrement vides (MRVBF non calculé, par
exemple ; voir
[`empty_layers()`](https://pobsteta.github.io/sylvostation/reference/empty_layers.md))
sont **écartées avec un avertissement** de classe
`sylvostation_non_calcule`, jamais remplacées. Les couches catégorielles
(géologie) deviennent des facteurs.

## Usage

``` r
sampling_frame(
  layers,
  forest,
  access,
  cost_max_m = 300,
  sd_ratio = .SD_RATIO_PROVISOIRE
)
```

## Arguments

- layers:

  `SpatRaster` des couches fines sur la grille (EPSG:2154) : par exemple
  `k_sv`, `is_topo`, `mrvbf`, `hauteur_reseau`, `pente`, `altitude`,
  `geologie`.

- forest:

  `SpatRaster` forestier, même géométrie (voir
  [`homogeneous_cells()`](https://pobsteta.github.io/sylvostation/reference/homogeneous_cells.md)).

- access:

  `sf` des tronçons accessibles.

- cost_max_m:

  Distance maximale à un tronçon, en mètres (300).

- sd_ratio:

  Seuil provisoire d'homogénéité (0,5).

## Value

`data.frame` : `cell`, `x` (est), `y` (nord), les couches, `cout_m`,
`candidat`. Attributs `vars`, `ecartees`, `cost_max_m`, `sd_ratio`.

## Examples

``` r
r <- terra::rast(nrows = 10, ncols = 10, xmin = 1010000, xmax = 1010200,
                 ymin = 6795000, ymax = 6795200, crs = "EPSG:2154", vals = 1:100)
r <- c(r, r * 0.5)  # au moins deux couches sont nécessaires
names(r) <- c("altitude", "pente")
l <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(
  rbind(c(1010000, 6795010), c(1010200, 6795010))), crs = 2154))
table(sampling_frame(r, r[[1]] * 0 + 1, l)$candidat)
#> 
#> FALSE  TRUE 
#>    44    56 
```
