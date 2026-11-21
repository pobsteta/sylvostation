# Types de terrain des relevés GNSS

Pour chaque relevé GNSS
([`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md),
une ligne par couple point-espèce) : moyenne des valeurs indicatrices
des espèces (niveau trophique = moyenne de `ph` et `azote`, comme aux
placettes ; humidité = `humidite`), bioclimat par
[`apply_bioclim()`](https://pobsteta.github.io/sylvostation/reference/apply_bioclim.md)
sur le climat kilométrique du point, puis type par les seuils et fusions
du catalogue. Le gradient hydrique de terrain est l'humidité
bioindiquée, sur une autre échelle que la carte (-Is) : seuls les axes
trophique et bioclimatique sont donc comparables tant que les deux
échelles ne sont pas raccordées (à faire par Pascal).

## Usage

``` r
gnss_field_gradients(gnss, indicateurs, predictors, axis)
```

## Arguments

- gnss:

  `sf` de
  [`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md)
  (colonnes `id`, `species`).

- indicateurs:

  Valeurs indicatrices (`nom`, `ph`, `azote`, `humidite`).

- predictors:

  `SpatRaster` des prédicteurs à maille large.

- axis:

  Résultat de
  [`bioclim_axis()`](https://pobsteta.github.io/sylvostation/reference/bioclim_axis.md).

## Value

Un `sf` (un point par relevé) : `id`, `n_especes`, `trophic`,
`humidite`, `bioclim`.

## Examples

``` r
g <- load_gnss(system.file("extdata", "synth_gnss.csv", package = "sylvostation"))
ind <- data.frame(nom = c("Synthia alpha", "Synthia beta"), ph = 5, azote = 4, humidite = 6)
r <- terra::rast(xmin = 1009000, xmax = 1012000, ymin = 6794000, ymax = 6797000,
                 resolution = 1000, crs = "EPSG:2154", nlyrs = 2)
terra::values(r) <- cbind(300, 8); names(r) <- c("coarse_p_etp_sv", "coarse_t_moy")
ax <- list(vars = names(r), center = c(coarse_p_etp_sv = 300, coarse_t_moy = 8),
           scale = c(coarse_p_etp_sv = 1, coarse_t_moy = 1),
           loadings = c(coarse_p_etp_sv = -0.7, coarse_t_moy = 0.7))
gnss_field_gradients(g, ind, r, ax)
#> Simple feature collection with 3 features and 7 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 1010012 ymin: 6795012 xmax: 1015030 ymax: 6800020
#> Projected CRS: RGF93 v1 / Lambert-93
#>    id loc_precision_m source                geometry n_especes trophic humidite
#> 1 G01               3   gnss POINT (1010012 6795012)         2     4.5        6
#> 4 G02               5   gnss POINT (1012500 6797500)         1     4.5        6
#> 6 G03               8   gnss POINT (1015030 6800020)         0      NA       NA
#>   bioclim
#> 1       0
#> 4      NA
#> 6      NA
```
