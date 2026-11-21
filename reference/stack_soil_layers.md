# Empiler les couches de sols sur la grille du projet

Lit des rasters de sols (GlobalSoilMap, pH SILVAE, pédopaysage...) et
les ramène sur `grid` (même emprise, même maille, EPSG:2154) par
[`terra::project()`](https://rspatial.github.io/terra/reference/project.html).
Une couche dont la **maille d'origine** est \>= `coarse_res_m` (90 m par
défaut) est préfixée `coarse_` : seule cette famille de prédicteurs peut
être croisée avec les placettes IFN (règle bloquante, voir
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)).
Le rééchantillonnage ne rend pas une couche grossière plus fine : le
préfixe suit la résolution native, jamais celle de `grid`.

## Usage

``` r
stack_soil_layers(paths, grid, method = "bilinear", coarse_res_m = 90)
```

## Arguments

- paths:

  Chemins des rasters (vecteur, nommé de préférence ; sinon le nom du
  fichier sans extension sert de nom de couche).

- grid:

  `SpatRaster` modèle, en EPSG:2154.

- method:

  Méthode de rééchantillonnage de
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html)
  (`"bilinear"` par défaut pour des variables continues ; `"near"` pour
  des classes).

- coarse_res_m:

  Seuil de maille (m) à partir duquel une couche est `coarse_`.

## Value

Un `SpatRaster` à autant de couches que de rasters sources (un raster
multicouche donne `nom_1`, `nom_2`...), sur la grille de `grid`.

## Details

**Attention** : `coarse_` signifie maille \>= 90 m (prédicteurs du
modèle local), pas « croisable avec l'IFN ». Avant tout croisement avec
des placettes IFN, ces couches doivent être agrégées à 1 km
([`aggregate_to_km()`](https://pobsteta.github.io/sylvostation/reference/aggregate_to_km.md))
; l'extraction exige une maille \>= 1000 m.

Pour une source en degrés (WGS84), la maille est estimée à 111 320 m par
degré (approximation).

## Examples

``` r
f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
g <- terra::rast(f)
names(stack_soil_layers(c(sol = f), g))
#> [1] "sol"
```
