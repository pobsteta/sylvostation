# Pipeline `targets` (mission 010)

Source : `_targets.R`, paramétré par `config.yml` (missions 010 et 016). Ce fichier décrit seulement ce qui n'est
pas évident dans le code ; les décisions restent dans `docs/adr/`.

## Mode démo (`demo: true`)

Sans réseau. Emprise : carré de 2 500 m au sud-ouest de `emprise_test` (100 x 100 cellules
de 25 m, Lambert-93, origine multiple de 50 m). Ce qui est **réel réduit** : contour SER
simplifié, extrait BD Charm-50, 100 placettes IFN. Tout le reste est **synthétique**
(fonctions `synth_demo_*` de `R/demo.R`) : MNT (plan de `synth_dtm.tif` + relief lisse),
climat de 1 km, points d'ancrage et « relevés GNSS », flore, arbres, carte de référence
(`inst/extdata/synth_reference.tif`, fabriquée par `inst/scripts/synth_reference.R`).

Choix de conception :

- les cibles qui portent des `SpatRaster` sont enregistrées « emballées » (`terra::wrap`),
  par un format `targets` personnalisé défini en tête de `_targets.R` ;
- le pipeline appelle `sylvostation::...` : pour utiliser le paquet chargé par
  `devtools::load_all()`, lancer `tar_make(callr_function = NULL)` (sinon le sous-processus
  charge le paquet installé) ;
- la cible `rapport` n'existe que si le paquet `quarto` et le CLI Quarto sont disponibles ; elle écrit `rapport.html` et, si un moteur LaTeX est disponible, `rapport.pdf` (voir « Rapport HTML et PDF ») ;
- les trois gradients (`trophic`, `hydric`, `bioclim`) sont modélisés sur les points
  synthétiques ; un modèle régional sur les placettes IFN (couches à maille large
  seulement) est validé à part ;
- le bloc « ancrage » (mission 007 : `get_gbif`, `clean_occ`, `grid_bioindication`,
  `load_gnss`) est intégré au paquet (`R/ancrage.R`) mais non branché au pipeline démo : `synth_demo_points()` le remplace.

## Mode réel (`demo: false`, mission 016)

À partir du seul code SER, le pipeline télécharge (cache sous `cache_dir`, hors dépôt),
calcule et écrit le catalogue **sans préfixe `synth_`** dans `out_dir/<ser_code>/`. Les
fonctions sont dans `R/pipeline_reel.R` ; les clés de configuration dans `config.yml`
(rubrique « Mode réel », valeurs par défaut dans `read_config()`).

### `offline: true` : mode réel sans réseau

Sources = les **extraits réels** de `inst/extdata`, jamais un jeu `synth_` :
`ser_extrait.gpkg`, `LHD_FXX_1015_6794_extrait.laz` (une dalle réduite à 80 m x 80 m),
`topage_troncons_extrait.gpkg`, `bdcharm50_emprise_test.gpkg`, `ifn_*.csv` (100 placettes),
`taxref_v18_extrait.csv`, `tichy_2023_extrait.csv`, `safran_sim2_12mailles_extrait.csv`
(12 mailles, 2003-2004). Aucune fonction de téléchargement n'est appelée
(`fetch_cached()` refuse hors ligne). C'est ce run que lancent la CI et les tests
(`test-acceptation-mode-reel.R`, `test-pipeline-reel.R`, ce dernier compte les appels
réseau : 0). Durée mesurée : environ 1 min 30 s (dont environ 50 s de MRVBF par GRASS) ;
2 min 26 s le 2026-11-18 avec la carte hydrique de 25 m (mission 021 : `terrain` 81 s,
`solar_k` 14 s, `hydric_grid` 3 s, rapport Quarto 18 s).

**Hors ligne, seule la composante régionale à maille large est produite** : sans ancrage
GBIF réel (un extrait exigerait un DOI, donc un `occ_download` avec compte), les gradients
cartographiés viennent des placettes IFN et du climat SAFRAN. Le LiDAR et le terrain sont
calculés (masque forestier, état de preuve) mais n'entrent dans aucun modèle. Seule
exception, la couche `hydric` (mission 021), calculée et non modélisée : voir « Carte
hydrique de 25 m ».

### Cibles

| Cible | Fonction | En ligne | Hors ligne |
|---|---|---|---|
| `ser`, `emprise` | `get_ser()`, `real_extent()` (`emprise: test` ou `ser`) | `ser_l93.zip` | extrait |
| `tiles` | `list_tiles()` ou `local_tiles()`, puis `select_tiles(max_tiles)` | WFS | nom du LAZ |
| `tile_blocks`, `lidar_files` | `tile_blocks()` (3 x 3), `run_tile_block()` par branche | `url_npl` | LAZ local |
| `dtm`, `grid` | `mosaic_tiles()` (5 m), `real_grid()` (25 m) | | |
| `hydro`, `terrain` | `get_hydro_network()`, `real_terrain()` (`mrvbf = TRUE`) | WFS TOPAGE | extrait |
| `forest` | `forest_mask()` : MHC > 5 m sur la moitié de la cellule (provisoire) | | |
| `geol_*` | `read_geology()`, `recode_lithology()`, `dominant_lithology(700)` | BD Charm-50 (`bdcharm_departements`) | extrait |
| `ifn` | `load_ifn()`, `filter_greco()`, `filter_releves()` | `fetch_ifn()` | extrait |
| `taxref`, `indicateurs` | `read_taxref()`, `load_indicator_values("tichy")` | `taxref_url`, `tichy_path` | extraits |
| `safran`, `climat` | `fetch_safran()`, `read_safran()`, `safran_climate()` (avril-septembre) | SIM2 | 12 mailles |
| `ifn_gradients` | `ifn_real_gradients()` : Tichý, `ru_from_texture()`, `hydric_stress()` (ADR 0006), `bioclim_axis()` | | |
| `solar_k` | `solar_factor()` : k mensuel de GRASS `r.sun` (ciel clair) sur l'altitude de 25 m ; repli k = 1 sans GRASS | | |
| `ru_mailles` | `ru_by_safran_cell()` : RU uniforme par maille SAFRAN (médiane euptf2 des placettes IFN), provisoire | | |
| `hydric_grid` | `hydric_stress_grid()` : Istress de 25 m (BILJOU, ETP Penman biljouR sur SSI × k), plat de référence, écart table / calcul direct | | |
| `anchors`, `local_trophic` | `get_gbif()`, `clean_occ()`, `grid_bioindication()`, `gbif_anchors()` | `occ_search` ou `occ_download` | **absent** |
| `models`, `cvs`, `maps` | `fit_gradient()`, `spatial_cv()`, `predict_raster()` (trophique, hydrique) ; bioclimat = `apply_bioclim()` ; couche `hydric` de `gradient_map` = `-is_topo` de `hydric_grid` (le modèle régional hydrique ne sert qu'à la validation croisée) ; `incertitude.tif` : trophique seul | | régional seul |
| typologie | `default_thresholds()`, `discretise()`, `merge_rare(plots = types des placettes)`, `type_raster()`, `real_type_legend()` (`azonal = FALSE`) | | |
| fiches, clé | `indicator_species()`, `real_fertility()`, `build_key()` sur `obs_pente`, `obs_topo`, `obs_humus` (notés par l'IFN) | | |
| `gnss_validation` | `load_gnss()`, `gnss_field_gradients()`, `validate_maps()` | si `gnss_path` | absent |
| `comparison_table` | `load_reference()`, `compare_gradients()` | si `reference_path` | absent |
| `evidence`, `outputs`, `rapport` | `evidence_table_real()`, `write_outputs(synthetic = FALSE)`, `write_types_gpkg_real()`, Quarto | | |

### Carte hydrique de 25 m (mission 021)

Méthode A de `docs/referentiels.md` § 25.4 (adaptation non validée de Dyer 2009) : la
topographie module l'**ETP** par le rayonnement reçu par la pente, jamais la réserve utile.

- `solar_factor()` : k(x, mois) = G `r.sun`(pente, exposition, ombres) / G `r.sun`(plat,
  sans ombres), ciel clair, 12 jours types, sur l'altitude de 25 m de `terrain` (environ
  une minute pour 225 dalles ; plus de deux heures à 5 m, mesuré). Pourtour de la grille :
  `NA` (pente inconnue).
- `hydric_stress_grid()` : rg = SSI × 0,01 × k, ETP de Penman de `biljouR`, P et RU de la
  maille SAFRAN, BILJOU ; plat de référence par la même formule (k = 1) ; table par
  maille sur les classes de `k_sv` (pas `hydric_pas_k`), écart à un calcul direct sur
  `hydric_n_controle` cellules par maille, sans seuil bloquant (`hydrique_ecart_table.csv`).
- RU uniforme par maille (`ru_by_safran_cell()`, `hydrique_mailles.csv`) : provisoire.
- Sorties : couche `hydric` de `gradients.tif` (= `grad_hydrique_25m` = -Istress),
  `hydrique_25m.tif` écrit par `write_hydric_grid()` (COG, préfixe `synth_` si
  synthétique ; `is_topo`, `nj_topo`, `is_plat`, `k_sv`, `ru_maille`, masqués par la
  forêt), ligne « 6 bis » de l'état de preuve (méthode, RU, écart, échelle, limites ;
  état « repli » si la méthode n'est pas `biljou_topo`).
- **Placettes IFN** : Istress sans k, sur la RU de la placette (`hydric_stress()`, règle
  des 700 m) ; la carte et les placettes ne sont pas à la même échelle. Les placettes
  sont pourtant discrétisées avec les seuils de la carte de 25 m alors que leur Istress
  est calculé sans k : cet écart d'échelle peut déplacer une placette d'un type hydrique
  à l'autre et changer les fusions de types rares (`merge_rare(plots = …)`). Le calcul
  n'est pas corrigé ; l'état de preuve (ligne « 6 bis ») le dit.
- **TWI, MRVBF et `hauteur_reseau`** restent hors de BILJOU : ce sont des prédicteurs du
  seul modèle local trophique (ancrages GBIF, en ligne) ; aucun modèle hydrique local
  n'existe, la composante hydrique locale passe par Istress seul.
- Replis signalés (attribut `methode`) : `biljou_climatique` (GRASS absent, k = 1),
  `climatique_etp_safran` (SAFRAN sans `T`, `FF`, `HU` ou `SSI`), `repli_ru`.

### Dalles : branchement dynamique et reprise

Les dalles sont groupées en blocs contigus de `lidar_block_size` x `lidar_block_size`
(3 x 3, 225 dalles = 25 blocs). Une branche `targets` par bloc : une branche terminée
n'est pas relancée ; dans un bloc interrompu, `run_tile_block()` saute les dalles dont
`mnt_<dalle>.tif` et `mhc_<dalle>.tif` existent. Les LAZ sont effacés après chaque bloc.
Le tampon de 20 m ne lit que les dalles du bloc : effets de bord entre blocs acceptés,
mesurés en mission 018. `error = "stop"` : jamais de mosaïque partielle silencieuse
(`mosaic_tiles()` vérifie que toutes les dalles attendues sont présentes).

### Sources : règles

- **Aucun jeu synthétique en mode réel** : `real_sources()` passe chaque extrait et chaque
  entrée optionnelle (`gnss_path`, `reference_path`, `soil_paths`, `tichy_path`) par
  `assert_not_synthetic()` : arrêt si le nom commence par `synth_`, si une colonne
  `synthetic` vaut `TRUE` (CSV, GeoPackage, classeur) ou si un raster porte la balise
  `synthetic = TRUE`.
- **URL IFN et TAXREF** : une seule source, `config.yml` (`ifn_archive_url`, `taxref_url`),
  exigée en ligne.
- **SAFRAN en ligne** : chaque fichier annuel (toute la France) est lu par blocs de lignes
  et filtré à la lecture aux mailles proches de l'emprise ; mesuré sur `QUOT_SIM2_2003.csv.gz`
  (3 610 580 lignes) : pic de mémoire du processus R 449 Mo (dont 255 Mo pour R et le
  paquet) contre 1 649 Mo en lecture complète.
- **Ancrages GBIF** : la précision d'une maille est l'incertitude maximale de ses
  occurrences (`gbif_anchors()`), contrôlée par la règle bloquante (25 m).
  Aucune maille bioindiquée (petite emprise) : `gbif_anchors()` rend un `sf` de 0 ligne
  (mêmes colonnes) avec l'avertissement `sylvostation_non_calcule` ; le modèle trophique
  local est alors sauté et la ligne « 7. Points d'ancrage (GBIF) » vaut
  `non atteint (aucune maille GBIF)` (mission 026).
- **Reprise réseau** (mission 026) : `fetch_cached()` reprend un téléchargement en échec
  (3 tentatives par défaut, attentes 5, 20 puis 60 s, fichier partiel supprimé, message à
  chaque tentative, erreur claire à la fin). Nombre de tentatives : argument `retries` ou
  option `sylvostation.download_retries` ; la clé `download_retries` de `config.yml` reste
  **à brancher** (hors périmètre de 026). Les téléchargements de dalles LiDAR
  (`.download_once()`, `R/emprise.R`), du TOPAGE (`R/hydro.R`) et de la SER ne passent pas
  par `fetch_cached()` : **non repris pour l'instant**.
- **Géologie avec `emprise: ser`** : `geology_coverage()` avertit si plus de 1 % de la SER
  tombe hors des départements de `bdcharm_departements`.

### Entrées absentes

`gnss_path` absent : ligne « 15. Validation thématique par relevés GNSS indépendants »
= `non atteint (entrée absente)`. `reference_path` absent : ligne « 16. Comparaison à la
référence AgroParisTech » = `sautée (entrée absente)`, et aucun fichier de comparaison.
`soil_paths` absent : « 8. Sols » = `non exécuté`. Rien n'est remplacé par du synthétique.

### Choix provisoires (à geler avant la phase 1)

Saison de végétation avril-septembre ; bioclimat = premier axe principal de P - ETP et de
la température moyenne annuelle (centrées-réduites sur les placettes), « plus haut = plus
chaud » ; masque forestier (MHC > 5 m sur au moins la moitié de la cellule) ; seuils par
quantiles ; `azonal = FALSE` partout. Carte hydrique de 25 m (§ 25.5) : ciel clair pour k,
Penman de `biljouR` à la place de Turc, Linke 3,0, albédo 0,2, jours de Klein, pas de
0,5 h, RU uniforme par maille, altitude moyenne de la maille, pas des classes de k. Couches de terrain vides (MRVBF sans GRASS, TPI dont
la fenêtre dépasse l'emprise, hauteur au réseau sans cours d'eau) : retirées des
prédicteurs et nommées dans l'état de preuve (`empty_layers()`).

## À vérifier

- Format réel des rasters de référence (noms de couches, codage des 59 types) et ordre des
  chiffres du code à trois chiffres (`recode_3digits()`).
- Correspondance « réserve utile = gradient hydrique » pour le repère de R² de 0,43.
- Pilote COG : les balises `terra::metags` ne sont pas conservées ; la marque synthétique
  est le préfixe `synth_` du nom de fichier.

## Rapport HTML et PDF (mission 022)

La cible `rapport` rend `inst/rapport/rapport.qmd` (copié dans `out_dir/<ser_code>/`) en
**HTML** puis en **PDF** (Quarto, moteur `xelatex`, A4). Le modèle ne lit que les fichiers
écrits par `write_outputs()` (CSV et GeoTIFF) : il ne dépend pas du paquet et ne calcule
rien. Le rendu est dans `inst/rapport/rendre_rapport.R` (`rendre_rapport()`, lu par
`_targets.R` et par les tests).

- **Contenu** : données d'entrée (tableau des sources avec état et volume du run, fiches
  version / date / licence / URL ou DOI d'après `inst/extdata/SOURCES.md` et
  `docs/referentiels.md`) ; calculs réalisés (schéma de la chaîne et tableau par étape :
  méthode, référence, valeurs provisoires, règle des 700 m) ; cartes produites (types,
  gradient hydrique de 25 m `is_topo` et `k_sv` de `hydrique_25m.tif`, incertitude `sd_cv`
  et `aoa`, gradients), chacune avec légende, échelle, flèche du nord, EPSG:2154 et ses
  limites ; puis état de preuve, types, fiches, clé, validation, limites, reproductibilité.
- **Démo** : encadré « DONNÉES SYNTHÉTIQUES » en tête du HTML et du PDF ; la carte hydrique
  de 25 m n'existe qu'en mode réel (le rapport le dit à sa place).
- **Le PDF n'est jamais obligatoire** : sans moteur LaTeX (`xelatex` absent), ou si son
  rendu échoue, le HTML est livré seul, un avertissement dit pourquoi (attribut
  `pdf_message` du résultat) et aucun PDF ancien ne reste dans le dossier. Sans Quarto, la
  cible n'existe pas (comme avant).
- **Dépendance LaTeX** : polices DejaVu, paquets `longtable`, `booktabs`, `etoolbox`,
  `fontspec` ; `tinytex` installe un paquet manquant par `tlmgr` s'il a le réseau.
