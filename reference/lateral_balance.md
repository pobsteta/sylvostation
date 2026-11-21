# Bilan latéral en eau (Piedallu et al. 2006, tableau 20) : carte de contrôle

Classe de bilan latéral (1 départ, 2 équilibre, 3 apports) par le logit
multinomial du tableau 20 de Piedallu et al. (2006, HAL hal-00835906, p.
53 imprimée) sur trois variables du MNT : courbure à 150 m (`curv150`,
Zevenbergen et Thorne, signe ESRI, 1/m), indice de dénivelé relatif dans
1 500 m (`idr_1500` = (z − min) / (max − min), carte 6F du rapport) et
indice de Moore (`moore`, lu comme le TWI ln(a / tan β), à vérifier), à
50 m. Équivalent en réserve utile `offsets` (−30, 0, +60 mm, synthèse
bibliographique de la p. 54, non reproduite).

## Usage

``` r
lateral_balance(dtm, coef, offsets = c(-30, 0, 60))
```

## Arguments

- dtm:

  `SpatRaster` d'altitude (m), EPSG:2154, maille \<= 50 m.

- coef:

  Coefficients (liste `depart`, `equilibre` : `constante`, `curv150`,
  `idr_1500`, `moore`), `bilan_lateral_coef` de
  [`read_config()`](https://pobsteta.github.io/sylvostation/reference/read_config.md)
  (config.yml).

- offsets:

  Équivalent en RU (mm) des classes départ, équilibre, apports.

## Value

`SpatRaster` à 50 m : `curv150`, `idr_1500`, `moore`, `p_depart`,
`p_equilibre`, `p_apports`, `bilan_lateral` (classe 1 à 3),
`ru_bilan_lateral` (mm). Attribut `parts` (part des cellules par
classe).

## Details

**Désactivé par défaut** (`bilan_lateral: false`, arbitrage du
2026-11-20, option C) et jamais ajouté à la RU de BILJOU : appliqué tel
quel à l'emprise test (mesure de la mission 034), il donne 53 %
d'apports et presque aucun départ (0 à 0,1 %), contre 27,6 % d'apports
et 25,9 % de départs observés en calibration (tableau 21). Coefficients
**à vérifier**, lus dans `config.yml` (`bilan_lateral_coef`, mission
039b). Toutes les couches sont fines (`FINE_VARIABLES`).

## Examples

``` r
# coefficients du tableau 20 (à vérifier) : valeur par défaut de read_config()
y <- tempfile(fileext = ".yml")
writeLines(c('ser_code: "D11"',
  "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
  "buffer_m: 5000", "resolution_m: 20", "crs: 2154", "data_dir: data",
  "laz_dir: data/laz", "out_dir: data/sorties", "ifn_precision_m: 700"), y)
cf <- read_config(y)$bilan_lateral_coef
f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
if (nzchar(f)) {
  b <- lateral_balance(terra::rast(f), cf)
  attr(b, "parts")
}
#>     depart  equilibre    apports 
#> 0.00000000 0.06140351 0.93859649 
```
