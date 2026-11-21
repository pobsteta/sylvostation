# Agréger un MNT à des résolutions plus grossières

Agrège un modèle numérique de terrain par la **moyenne** (brief
technique, § 4 étape 2 : indices de terrain sur 5 m puis résumés à la
maille de sortie, pas sur 1 m). Le facteur d'agrégation doit être entier
; si la maille d'origine est alignée sur un multiple de `res` (ADR 0007
: grille de `resolution_m`, 20 m, d'origine multiple de 20 m), la grille
agrégée l'est aussi.

## Usage

``` r
aggregate_dtm(dtm, res = c(5, 20))
```

## Arguments

- dtm:

  `SpatRaster` à une couche, en Lambert-93 (EPSG:2154), à maille carrée.

- res:

  Résolutions cibles, en mètres. Une résolution égale à celle du MNT le
  renvoie tel quel ; une résolution plus fine est refusée.

## Value

Une liste nommée (`res_5`, `res_20`, ...) de `SpatRaster`.

## Examples

``` r
r <- terra::rast(nrows = 100, ncols = 100, xmin = 980000, xmax = 980100,
                 ymin = 6800000, ymax = 6800100, crs = "EPSG:2154")
terra::values(r) <- seq_len(terra::ncell(r))
names(aggregate_dtm(r, res = c(5, 20)))
#> [1] "res_5"  "res_20"
```
