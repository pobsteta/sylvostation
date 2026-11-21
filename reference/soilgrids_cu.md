# Capacité en eau par horizon tirée des textures SoilGrids (euptf2)

Pour chaque horizon de SoilGrids, eau disponible θ(pF 2,0) − θ(pF 4,2)
par euptf2 (PTF01 : sable, limon, argile ramenés à 100 %, profondeur au
milieu de l'horizon), comme
[`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md),
réduite par les cailloux : capacité `cu_<horizon>` en mm d'eau par cm de
sol. La réserve utile jusqu'à une profondeur est la somme des capacités
× épaisseurs
([`ru_soilgrids()`](https://pobsteta.github.io/sylvostation/reference/ru_soilgrids.md)).
Valeur obtenue : environ 3,2 mm/cm pour un limon à 20 % d'argile sans
cailloux, haute pour une eau disponible (pF 2,0 au lieu de 2,5) : **à
vérifier**. Calcul mesuré sur la GRECO D : 231 s pour 447 044 cellules ×
6 horizons, 1,4 Go.

## Usage

``` r
soilgrids_cu(files)
```

## Arguments

- files:

  Chemins de
  [`fetch_soilgrids_texture()`](https://pobsteta.github.io/sylvostation/reference/fetch_soilgrids_texture.md)
  (ou `SpatRaster` à 24 couches nommées `clay_0-5cm_mean`, ...), en %,
  EPSG:2154 ; ou un seul GeoTIFF à 24 couches nommées
  (`soilgrids_texture_path`, mode hors ligne), divisé par 10 s'il porte
  la balise `echelle = 10` (unités natives de SoilGrids).

## Value

`SpatRaster` à six couches `cu_0_5`, `cu_5_15`, ..., `cu_100_200`
(mm/cm).

## Details

Un GeoTIFF unique sans balise `echelle = 10` doit être en % : argile +
sable + limon doit valoir 100 à ± 2 près, sinon arrêt (unités natives de
SoilGrids, × 10, sans la balise).

## Examples

``` r
# \donttest{
if (requireNamespace("euptf2", quietly = TRUE)) {
g <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000500, ymin = 6.8e6,
                 ymax = 6800500, crs = "EPSG:2154")
L <- lapply(c("clay", "sand", "silt", "cfvo"), function(p) {
  r <- terra::rast(g, nlyrs = 6)
  terra::values(r) <- switch(p, clay = 20, sand = 40, silt = 40, cfvo = 10)
  names(r) <- paste0(p, "_", c("0-5", "5-15", "15-30", "30-60", "60-100", "100-200"), "cm_mean")
  r
})
soilgrids_cu(do.call(c, L))
}
#> class       : SpatRaster
#> size        : 2, 2, 6  (nrow, ncol, nlyr)
#> resolution  : 250, 250  (x, y)
#> extent      : 1000000, 1000500, 6800000, 6800500  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> names       :   cu_0_5,  cu_5_15, cu_15_30, cu_30_60, cu_60_100, cu_100_200
#> min values  : 2.892445, 2.892445, 2.892445, 2.892445,  2.892445,   2.892445
#> max values  : 2.892445, 2.892445, 2.892445, 2.892445,  2.892445,   2.892445
# }
```
