# Variables dérivées du MNT (prédicteurs fins)

Calcule les prédicteurs de terrain de l'étape 2 du brief technique.
Toutes les couches sont des variables **fines** (voir
[FINE_VARIABLES](https://pobsteta.github.io/sylvostation/reference/FINE_VARIABLES.md))
: elles ne doivent jamais être extraites aux coordonnées des placettes
IFN (appeler
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
avant toute extraction).

## Usage

``` r
derive_terrain(
  dtm,
  tpi_radii = c(100, 300, 1000),
  streams = NULL,
  mrvbf = FALSE,
  mrvbf_res = NULL
)
```

## Arguments

- dtm:

  `SpatRaster` à une couche, EPSG:2154, maille carrée, altitudes en
  mètres.

- tpi_radii:

  Rayons du TPI, en mètres.

- streams:

  Réseau hydrographique (BD TOPAGE) : `SpatVector` ou `sf` de lignes en
  EPSG:2154, ou `NULL`.

- mrvbf:

  `TRUE` pour calculer le MRVBF par GRASS (lent : 2 à 4 minutes mesurées
  pour 1 600 à 57 600 cellules) ; `FALSE` (défaut) laisse la couche à
  `NA` avec avertissement. Le pipeline en mode réel doit passer `TRUE`.

- mrvbf_res:

  Résolution (m) du MNT sur lequel le MRVBF est calculé : multiple
  entier de la maille du MNT, `NULL` (défaut) = la maille du MNT. Le MNT
  est agrégé (moyenne) avant GRASS ; le seuil `t_slope` suit la maille
  de calcul (mission 027, provisoire sous 25 m, à vérifier).

## Value

Un `SpatRaster` multicouche nommé.

## Details

Couches (noms stables) :

- `pente` (degrés, Horn 1981, via
  [`terra::terrain`](https://rspatial.github.io/terra/reference/terrain.html))
  ;

- `exposition_cos`, `exposition_sin` : cosinus et sinus de l'exposition
  (azimut de la descente, depuis le nord, sens horaire). `NA` sur
  terrain plat ;

- `courbure`, `courbure_profil`, `courbure_plan` (1/m) : Zevenbergen et
  Thorne (1987), signes d'ESRI : `courbure = -2 (D + E)` (positive en
  convexe) ; profil et plan comme dans la documentation ArcGIS «
  Curvature » ;

- `tpi_<rayon>` (m) : altitude moins moyenne des cellules du disque de
  ce rayon (centre exclu). `NA` là où le disque sort du MNT. Au-delà de
  40 cellules de rayon, la moyenne est calculée sur une version agrégée
  puis rééchantillonnée (bilinéaire) pour borner le temps de calcul :
  approximation, **à vérifier** sur données réelles ;

- `twi` : ln(a / tan(pente)), `a` = surface drainée spécifique (m) ;
  pente minimale de 0,1 degré pour éviter les infinis ;

- `surface_drainee` (m2) : accumulation D8 (O'Callaghan et Mark 1984)
  calculée en R, **sans remplissage des cuvettes** (elles retiennent
  l'eau). Sur un MNT réel, prétraitement hydrologique **à vérifier** ;

- `mrvbf` : indice multi-résolution de fond de vallée (Gallant et
  Dowling 2003), par l'extension GRASS `r.valley.bottom` (`whitebox` n'a
  pas d'outil MRVBF, référentiels § 20). Seuil de pente initial adapté à
  la maille (mission 027) : 16 % à 25 m (Gallant et Dowling 2003),
  divisé par 2 par grossissement x 3 (manuel de l'extension), règle
  prolongée aux mailles fines (44,2 % à 5 m, **provisoire, à vérifier**)
  ; `t_vf = 0,3` (défaut documenté) ; autres paramètres par défaut
  (`p_slope` = 4, `p_pctl` = 3 : de l'exemple de 6 m du manuel, seul
  `t_slope` est repris, `p_slope` = 3 et `p_pctl` = 2 ne le sont pas).
  Avec 16 % à 5 m, le MRVBF était quasi nul partout sur les dalles
  vosgiennes. Le calcul peut se faire sur une version agrégée du MNT
  (`mrvbf_res`), puis rééchantillonnée (bilinéaire) sur la maille du
  MNT. `NA` et avertissement de classe `sylvostation_non_calcule` si
  `mrvbf = FALSE` ou si GRASS (`grass`) ou l'extension est absent.
  Calcul lent (2 à 4 minutes mesurées pour 1 600 à 57 600 cellules) ;

- `hauteur_reseau` (m), voir
  [`height_above_network()`](https://pobsteta.github.io/sylvostation/reference/height_above_network.md)
  : HAND (altitude moins celle de la première cellule du réseau atteinte
  en suivant les directions D8 de `surface_drainee`, les cuvettes
  intérieures étant franchies par leur col). `NA` si l'écoulement
  n'atteint pas le réseau dans l'emprise ; jamais négatif ; `NA` avec
  avertissement si `streams` est `NULL` ;

- `rayonnement` (kWh/m2/an) : rayonnement direct potentiel **hors
  atmosphère et sans ombres portées**, 12 jours types (Klein 1977), pas
  de 30 min, formules d'incidence de Duffie et Beckman (*Solar
  Engineering of Thermal Processes*, éq. 1.6.2 et 1.10.3). Indice
  relatif d'exposition, non un flux au sol.

Choisir la résolution en amont avec
[`aggregate_dtm()`](https://pobsteta.github.io/sylvostation/reference/aggregate_dtm.md)
(5 m puis `resolution_m`, ADR 0007). Le pourtour d'une cellule du MNT
est `NA` pour la pente, l'exposition et les courbures.

## Examples

``` r
f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
if (nzchar(f)) {
  d <- terra::rast(f)   # surface synthétique
  suppressWarnings(names(derive_terrain(d, tpi_radii = 100)))
}
#>  [1] "pente"           "exposition_cos"  "exposition_sin"  "courbure"       
#>  [5] "courbure_plan"   "courbure_profil" "tpi_100"         "twi"            
#>  [9] "surface_drainee" "mrvbf"           "hauteur_reseau"  "rayonnement"    
```
