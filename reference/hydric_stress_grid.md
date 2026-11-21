# Carte de l'indice de contrainte hydrique à la maille de sortie : BILJOU modulé par le rayonnement

Descente d'échelle de l'indice `Istress` de BILJOU (ADR 0006) par la
méthode A de `docs/referentiels.md` § 25.4 (adaptation **non validée**
de Dyer 2009) : l'ETP est modulée par le rayonnement reçu par la pente ;
ni la réserve utile, ni TWI, ni MRVBF, ni HAND n'entrent dans BILJOU
(ils restent des prédicteurs à part).

## Usage

``` r
hydric_stress_grid(
  k,
  ru,
  safran = NULL,
  points = NULL,
  altitude = NULL,
  annees = NULL,
  lai_max = 6,
  forest_type = "broadleaved",
  budburst = 110,
  leaf_fall = 300,
  pas_k = 0.02,
  pas_ru = 10,
  n_controle = 30,
  seed = 1,
  k_methode = attr(k, "methode"),
  interpolation = c("bilineaire", "proche"),
  node_res = 1000,
  t_lapse = NULL,
  alt_mailles = NULL
)
```

## Arguments

- k:

  `SpatRaster` à 12 couches (EPSG:2154), de
  [`solar_factor()`](https://pobsteta.github.io/sylvostation/reference/solar_factor.md).

- ru:

  Réserve utile : `data.frame` (`maille`, `ru_mm`) de
  [`ru_by_safran_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_by_safran_cell.md),
  ou `SpatRaster` (mm) sur la grille de `k`.

- safran:

  `data.frame` SIM2 quotidien avec `LAMBX`, `LAMBY`, `DATE`, `PRELIQ`,
  `PRENEI`, `T`, `FF`, `HU`, `SSI` (suffixe `_Q` accepté), ou `NULL`.

- points:

  `NULL` (grille) ou `sf` de points précis (EPSG:2154).

- altitude:

  `SpatRaster` d'altitude (m) sur la grille, ou `NULL` (0 m).

- annees:

  Années à garder (`NULL` : toutes).

- lai_max, forest_type, budburst, leaf_fall:

  Paramètres de
  [`biljouR::biljou_run()`](https://pobsteta.github.io/biljouR/reference/biljou_run.html).

- pas_k:

  Pas des classes de `k_sv` (provisoire).

- pas_ru:

  Pas de la suite de RU si `ru` est un raster.

- n_controle:

  Cellules de contrôle par maille (calcul direct).

- seed:

  Graine du tirage des cellules de contrôle.

- k_methode:

  Méthode de `k` (`attr(k, "methode")` par défaut).

- interpolation:

  `"bilineaire"` (défaut, mission 033) ou `"proche"`.

- node_res:

  Pas (m) du réseau des nœuds de calcul de la météo interpolée (1000).
  L'interpolation bilinéaire (aucune référence publiée lue) et ce pas de
  1 km sont provisoires : à vérifier.

- t_lapse:

  `NULL` (aucune correction, comportement d'avant 039) ou gradient
  altitudinal de la température (°C/m, ou liste de
  [`safran_lapse_rate()`](https://pobsteta.github.io/sylvostation/reference/safran_lapse_rate.md)).
  Mission 039 : la température journalière de chaque nœud (ou point) est
  décalée de `t_lapse × (z_nœud − z_bilinéaire)` (`z_nœud` = altitude
  moyenne de ses cellules dans `altitude`, `z_bilinéaire` = altitude des
  mailles `alt_mailles` interpolée avec les mêmes poids), l'humidité
  relative recalculée à pression de vapeur constante (FAO-56, éq. 11),
  et l'altitude de Penman est `z_nœud`. Gradient constant chaque jour :
  inversions hivernales ignorées (à vérifier). Exige
  `interpolation = "bilineaire"` et `altitude`.

- alt_mailles:

  `data.frame` de
  [`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md)
  (si `t_lapse`).

## Value

Grille : `SpatRaster` `is_topo`, `nj_topo`, `is_plat`, `k_sv`,
`ru_maille`, `grad_hydrique_carte` (= `-is_topo`, plus haut = plus
humide). Points : `points` avec ces colonnes et `maille_safran`.
Attributs `methode`, `k_methode`, `ecart`, `mailles`, `parametres`,
`sens`, `repli`.

## Details

**Climat de la cellule (mission 033).** Avec
`interpolation = "bilineaire"` (défaut), les séries journalières SAFRAN
(`PRELIQ`, `PRENEI`, `T`, `FF`, `HU`, `SSI`) sont interpolées
bilinéairement entre les centres des mailles de 8 km
([`safran_weights()`](https://pobsteta.github.io/sylvostation/reference/safran_weights.md))
au centre de chaque nœud d'un réseau de `node_res` m (1 km, carrés
partant du coin nord-ouest de la grille, rognés à son emprise) : toutes
les cellules du nœud partagent cette météo, sans saut aux limites des
mailles. Latitude et altitude de Penman sont pondérées de même (altitude
moyenne des mailles, **provisoire**, sans correction des températures :
option A différée). Avec `"proche"`, chaque cellule prend la série de sa
maille (comportement d'avant 033). La réserve utile reste celle de la
maille la plus proche
([`ru_by_safran_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_by_safran_cell.md)).

Pour chaque cellule `x` de la grille, avec la météo de son nœud (ou de
sa maille) :

1.  rayonnement du jour `d` : rg(x, d) = SSI(nœud, d) × 0,01 × k(x, mois
    de d) (SSI en J/cm², unité vérifiée dans le document « Données
    quotidiennes SIM » de Météo-France du 2026-03-31 ; k de
    [`solar_factor()`](https://pobsteta.github.io/sylvostation/reference/solar_factor.md)).
    Ce document nomme `SSI` « Rayonnement visible » : il est lu ici
    comme le rayonnement global de courte longueur d'onde, **à
    vérifier** ; la hauteur du vent `FF` (10 m supposés par `biljouR`)
    est aussi **à vérifier** ;

2.  ETP de Penman de `biljouR`
    ([`biljouR::safran_to_meteo()`](https://pobsteta.github.io/biljouR/reference/safran_to_meteo.html)
    avec `compute_pet = TRUE` :
    `penman_pet(T, rg, wind_to_2m(FF, 10), HU, doy, latitude, altitude)`)
    ; latitude du centre de la maille, altitude = moyenne de `altitude`
    dans la maille (**provisoire**) ;

3.  `Istress(x)` = BILJOU(ETP(x), P(nœud), RU(maille)) ;

4.  **plat de référence** (`is_plat`) par la même formule avec k = 1 :
    l'écart `is_topo - is_plat` est purement topographique (l'ETP
    SAFRAN, Penman-Monteith, n'est pas la référence).

**Table par nœud (ou par maille).** BILJOU ne tourne pas cellule par
cellule (environ 2 s par passe sur 30 ans). Dans chaque nœud (ou
maille), chaque cellule reçoit un facteur scalaire `k_sv`, moyenne de
ses 12 facteurs mensuels pondérée par le rayonnement SAFRAN moyen des
jours de la saison de BILJOU (`budburst` à `leaf_fall`) ; les cellules
sont classées par pas de `pas_k`, et BILJOU tourne une fois par classe
avec le profil mensuel moyen de la classe, et par réserve utile (une
seule valeur si la RU est uniforme par maille, sinon une suite de pas
`pas_ru`). Chaque cellule est interpolée linéairement en `k_sv` puis en
RU. **Écart mesuré** : sur `n_controle` cellules tirées dans chaque
maille, BILJOU tourne avec le vrai profil de 12 facteurs et la météo de
leur nœud ; l'écart à la table est rendu (attribut `ecart`), sans seuil
bloquant.

**Points** (`points`, `sf` en EPSG:2154) : calcul direct, sans table,
pour des points précis (relevés GNSS, points au sol), météo interpolée
au point même.
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
est appelée d'abord : **k n'est jamais appliqué aux placettes IFN**
(localisées à 700 m), dont l'indice reste celui de
[`hydric_stress()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress.md),
sans k.

**Replis** (attribut `methode`, avertissement) : `"biljou_topo"` (k de
`r.sun`) ; `"biljou_climatique"` (k = 1, GRASS absent) ;
`"climatique_etp_safran"` (colonnes `T`, `FF`, `HU` ou `SSI` absentes :
BILJOU sur l'ETP SAFRAN de la maille la plus proche, sans k ni
interpolation) ; `"repli_ru"` (SAFRAN ou `biljouR` absent : la réserve
utile).

Valeurs **provisoires** (§ 25.5) : ciel clair pour k, passage de Turc au
Penman de `biljouR`, Linke 3,0, albédo 0,2, jours de Klein, RU uniforme
par maille, pas des suites, altitude moyenne de la maille ; paramètres
de végétation de
[`hydric_stress()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress.md).

## Examples

``` r
# \donttest{
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
m <- sylvostation:::.mailles_safran(s)[1, ]
k <- terra::rast(xmin = m$x - 50, xmax = m$x + 50, ymin = m$y - 50, ymax = m$y + 50,
                 resolution = 50, crs = "EPSG:2154", nlyrs = 12)
terra::values(k) <- matrix(c(1.3, 1, 1, 0.7), 4, 12)
names(k) <- sprintf("k_%02d", 1:12)
h <- hydric_stress_grid(k, data.frame(maille = m$maille, ru_mm = 100), s, n_controle = 2)
terra::values(h)
#>       is_topo nj_topo  is_plat k_sv ru_maille grad_hydrique_carte
#> [1,] 45.68111    99.0 26.47008  1.3       100           -45.68111
#> [2,] 26.47008    60.5 26.47008  1.0       100           -26.47008
#> [3,] 26.47008    60.5 26.47008  1.0       100           -26.47008
#> [4,] 12.70511    35.5 26.47008  0.7       100           -12.70511
# }
```
