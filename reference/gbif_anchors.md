# Points d'ancrage GBIF : mailles de bioindication et prédicteurs

Centres des mailles de
[`grid_bioindication()`](https://pobsteta.github.io/sylvostation/reference/grid_bioindication.md)
(`source = "gbif"`), niveau trophique bioindiqué (moyenne de `ph` et
`azote`, comme aux placettes) et extraction des prédicteurs. La
précision de localisation d'une maille (`loc_precision_m`) est
l'**incertitude maximale** des occurrences qu'elle contient (colonne
`loc_precision_m` de
[`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md))
; une maille sans occurrence lisible est écartée (et comptée). **La
règle bloquante est appelée avant l'extraction**
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md))
: une précision supérieure à 25 m l'arrête.

## Usage

``` r
gbif_anchors(cells, occ, predictors)
```

## Arguments

- cells:

  `sf` de
  [`grid_bioindication()`](https://pobsteta.github.io/sylvostation/reference/grid_bioindication.md)
  (colonnes `cell_id`, `ph`, `azote`).

- occ:

  `sf` de points de
  [`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
  (colonne `loc_precision_m`), ceux qui ont servi à `cells`.

- predictors:

  `SpatRaster` des prédicteurs (fins et à maille large).

## Value

Un `sf` de points : `cell_id`, `source`, `loc_precision_m`,
`n_occ_maille`, `trophic`, une colonne par couche de `predictors`.
Attribut `n_ecartees`. Si aucune maille n'est bioindiquée : `sf` de 0
ligne aux mêmes colonnes et avertissement de classe
`sylvostation_non_calcule` (l'aval, modèle trophique local, reste
sauté).

## Examples

``` r
cel <- sf::st_sf(cell_id = "a", ph = 5, azote = 4,
  geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(1015500, 6793500), c(1015550, 6793500),
  c(1015550, 6793550), c(1015500, 6793550), c(1015500, 6793500)))), crs = 2154))
occ <- sf::st_as_sf(data.frame(x = c(1015510, 1015520), y = 6793510,
                               loc_precision_m = c(5, 12)),
                    coords = c("x", "y"), crs = 2154)
r <- terra::rast(xmin = 1015500, xmax = 1015600, ymin = 6793500, ymax = 6793600,
                 resolution = 20, crs = "EPSG:2154", vals = 1)
names(r) <- "pente"
gbif_anchors(cel, occ, r)$loc_precision_m
#> [1] 12
```
