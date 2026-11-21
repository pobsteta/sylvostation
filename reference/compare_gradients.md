# Comparer nos gradients à ceux de la référence (protocole § 9, étape 1)

Agrège nos gradients à `res` mètres (moyenne), amène la référence sur la
même grille (rééchantillonnage bilinéaire si les grilles diffèrent),
puis calcule, pour chaque gradient commun, la **corrélation de rang** de
Spearman sur les cellules communes, et une carte des écarts. Les deux
cartes n'ayant pas forcément la même échelle, les écarts sont calculés
sur des valeurs **centrées-réduites** (par couche, sur les cellules
communes) : écart = notre z moins le z de la référence. Un bon accord
montre que la chaîne reproduit l'existant, pas qu'elle a raison (brief §
9).

## Usage

``` r
compare_gradients(ours, ref, res = 50, max_cells = 100000L)
```

## Arguments

- ours:

  `SpatRaster` de nos gradients (couches nommées comme celles de `ref`),
  en EPSG:2154.

- ref:

  `SpatRaster` de référence (voir
  [`load_reference()`](https://pobsteta.github.io/sylvostation/reference/load_reference.md)).

- res:

  Maille de comparaison en mètres (50, comme la référence). Doit être un
  multiple entier de notre maille.

- max_cells:

  Nombre maximal de cellules pour la corrélation (échantillon régulier
  au-delà).

## Value

Une liste : `correlation` (`data.frame` : `gradient`, `rho`, `n`),
`ecarts` (`SpatRaster`, une couche `ecart_<gradient>`), `ours` et `ref`
(les rasters comparés, sur la même grille à `res` mètres), `res`,
`synthetic`.

## Examples

``` r
a <- terra::rast(nrows = 20, ncols = 20, xmin = 1007000, xmax = 1007500,
                 ymin = 6790000, ymax = 6790500, crs = "EPSG:2154")
terra::values(a) <- seq_len(400)
names(a) <- "trophic"
compare_gradients(a, a, res = 50)$correlation
#>   gradient rho   n
#> 1  trophic   1 100
```
