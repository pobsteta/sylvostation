# Métriques LiDAR ponctuelles autour de points précis

Calcule des métriques de hauteur (nombre de points, moyenne, écart-type,
95e percentile, maximum, part des points au-dessus de 2 m) dans un
disque de rayon `radius` autour de chaque point. Les points doivent être
normalisés (hauteur au-dessus du sol) ou un `dtm` doit être fourni.
**Extraction fine : la règle bloquante s'applique** ; la fonction
appelle
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
en premier et refuse les placettes IFN et tout point dont
`loc_precision_m` est absent, `NA` ou supérieur à 25 m.

## Usage

``` r
point_lidar_metrics(ctg_or_files, points, radius = 15, dtm = NULL)
```

## Arguments

- ctg_or_files:

  Un objet [`lidR::LAS`](https://rdrr.io/pkg/lidR/man/LAS-class.html),
  un `lidR::LAScatalog` ou des chemins de fichiers LAZ/LAS.

- points:

  Un `sf` de points en EPSG:2154, avec la colonne `loc_precision_m`.

- radius:

  Rayon du disque, en mètres (15 par défaut).

- dtm:

  Un `SpatRaster` de MNT pour normaliser les hauteurs (facultatif).

## Value

`points` complété des colonnes `lidar_n_pts`, `lidar_zmean`,
`lidar_zsd`, `lidar_zq95`, `lidar_zmax`, `lidar_cover2` (`NA` si aucun
point dans le disque).

## Examples

``` r
p <- mark_ifn(sf::st_as_sf(data.frame(x = 1015040, y = 6793960),
                           coords = c("x", "y"), crs = 2154))
try(point_lidar_metrics("absent.laz", p))
#> Error : Extraction interdite sur les placettes IFN (localisées à 700 m près). Variables fines : metriques_lidar. Seules les variables à maille large (préfixe `coarse_` ou COARSE_VARIABLES) sont permises.
```
