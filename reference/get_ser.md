# Contour d'une sylvoécorégion (SER), avec tampon

Lit la couche des SER de l'IGN (`ser_l93.zip`, 86 SER ; champs `codeser`
et `NomSER`, encodage WINDOWS-1252 ; voir `docs/referentiels.md`, § 1),
en extrait la SER demandée, réunit ses polygones et applique un tampon
en mètres. Il n'existe pas de service WFS pour les SER : le fichier est
téléchargé une fois dans `data_dir` (`source = "download"`), ou lu
depuis `path` (`source = "file"`, pour les tests). Avec
`alluvial = TRUE`, la lecture porte sur la couche superposée des 5 SER
d'alluvions récentes (`ser_ar_l93.zip`, codes `L1` à `L5`).

## Usage

``` r
get_ser(
  ser_code,
  buffer_m = 0,
  source = c("download", "file"),
  path = NULL,
  data_dir = "data",
  alluvial = FALSE
)
```

## Arguments

- ser_code:

  Code de la SER (par exemple `"D11"`).

- buffer_m:

  Tampon en mètres (EPSG:2154), 0 par défaut.

- source:

  `"download"` (télécharge ou réutilise le fichier de `data_dir`) ou
  `"file"` (lit `path`).

- path:

  Chemin d'un `.zip`, `.shp` ou `.gpkg` de SER (obligatoire si
  `source = "file"`).

- data_dir:

  Dossier de cache du téléchargement.

- alluvial:

  Lire la couche des alluvions récentes plutôt que celle des SER.

## Value

Un objet `sf` d'une ligne (`codeser`, `NomSER`, géométrie) en EPSG:2154.

## Examples

``` r
f <- system.file("extdata", "ser_extrait.gpkg", package = "sylvostation")
if (nzchar(f)) get_ser("D11", buffer_m = 1000, source = "file", path = f)
#> Simple feature collection with 1 feature and 2 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 954968.1 ymin: 6742821 xmax: 1059887 ymax: 6902247
#> Projected CRS: RGF93 v1 / Lambert-93
#>   codeser                 NomSER                       geometry
#> 1     D11 Massif vosgien central POLYGON ((955710 6764918, 9...
```
