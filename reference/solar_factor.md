# Facteur topographique de rayonnement mensuel (GRASS `r.sun`, ciel clair)

Pour chaque cellule `x` et chaque mois `j` (jour type de Klein 1977) :
k(x, j) = G(x ; pente, exposition, ombres portées) / G(x ; pente 0, sans
ombres), où G est le rayonnement global journalier (`glob_rad`, direct +
diffus + réfléchi, Wh m⁻² j⁻¹) de GRASS `r.sun` (Šúri et Hofierka 2004)
**en ciel clair** (`coeff_bh`, `coeff_dh` absents). C'est la méthode A
de `docs/referentiels.md` § 25.4 (adaptation **non validée** de Dyer
2009) : k multiplie le rayonnement SAFRAN dans l'ETP de
[`hydric_stress_grid()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress_grid.md).

## Usage

``` r
solar_factor(
  dtm,
  days = .JOURS_TYPES,
  linke = 3,
  albedo = 0.2,
  step = 0.5,
  nprocs = 1,
  grass = Sys.which("grass")
)
```

## Arguments

- dtm:

  `SpatRaster` à une couche, EPSG:2154, maille carrée (`resolution_m`
  dans le pipeline), altitudes en mètres.

- days:

  Jours de l'année des 12 mois (jours types de Klein 1977).

- linke, albedo:

  Trouble de Linke et albédo de `r.sun` (provisoires).

- step:

  Pas de temps de `r.sun` (heures, provisoire).

- nprocs:

  Nombre de fils de `r.sun`.

- grass:

  Exécutable GRASS (`""` : absent, repli).

## Value

`SpatRaster` à 12 couches `k_01` à `k_12` sur la grille de `dtm`,
attributs `methode` (`"r.sun"` ou `"climatique"`), `repli` (raison du
repli) et `parametres`.

## Details

- Pente et exposition :
  [`terra::terrain`](https://rspatial.github.io/terra/reference/terrain.html)
  (Horn 1981), comme la couche `pente` de
  [`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
  ; l'exposition (depuis le nord, sens horaire) est convertie vers la
  convention de `r.sun` (270 = sud) par (450 - azimut) mod 360. Terrain
  plat : pente 0. Pourtour du MNT (pente inconnue) : `NA`.

- Numérateur avec ombres portées (défaut de `r.sun`) ; dénominateur
  `r.sun -p slope_value=0` (plat, sans ombres).

- Valeurs **provisoires** (§ 25.5) : ciel clair, trouble de Linke 3,0,
  albédo 0,2 (défauts du manuel), jours types de Klein, pas de 0,5 h.
  Les ombres portées par le relief situé hors du MNT fourni ne sont pas
  vues (bord de l'emprise).

- **Repli** : sans GRASS (`grass` introuvable) ou si `r.sun` échoue, k =
  1 partout (méthode « climatique », attribut `methode`), avertissement
  de classe `sylvostation_non_calcule`.

Coût mesuré (GRASS 8.4.2, 3 fils, 2026-11-18, mission 021) : 4,1 s par
jour type avec ombres et 0,9 s pour le plat sur 360 000 cellules de 25 m
(225 dalles), soit environ une minute pour les 12 mois ; plus de 10
minutes par jour à 5 m. Mesure de la mission 025 (2026-11-18, machine
chargée, 1 cœur disponible, 12 mois avec ombres) : 36 s pour 90 000
cellules de 20 m et 301 s pour 562 500 cellules de 20 m (225 dalles).

k est une variable **fine** (`k_01` à `k_12`, voir
[FINE_VARIABLES](https://pobsteta.github.io/sylvostation/reference/FINE_VARIABLES.md))
: jamais aux placettes IFN
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)).

## Examples

``` r
f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
d <- terra::rast(f)   # surface synthétique
k <- suppressWarnings(solar_factor(d, grass = ""))   # sans GRASS : repli k = 1
attr(k, "methode")
#> [1] "climatique"
```
