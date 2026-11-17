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
- la cible `rapport` n'existe que si le paquet `quarto` et le CLI Quarto sont disponibles ;
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
réseau : 0). Durée mesurée : environ 1 min 30 s (dont environ 50 s de MRVBF par GRASS).

**Hors ligne, seule la composante régionale à maille large est produite** : sans ancrage
GBIF réel (un extrait exigerait un DOI, donc un `occ_download` avec compte), les gradients
cartographiés viennent des placettes IFN et du climat SAFRAN. Le LiDAR et le terrain sont
calculés (masque forestier, état de preuve) mais n'entrent dans aucun modèle.

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
| `anchors`, `local_trophic` | `get_gbif()`, `clean_occ()`, `grid_bioindication()`, `gbif_anchors()` | `occ_search` ou `occ_download` | **absent** |
| `models`, `cvs`, `maps` | `fit_gradient()`, `spatial_cv()`, `predict_raster()` (trophique, hydrique) ; bioclimat = `apply_bioclim()` | | régional seul |
| typologie | `default_thresholds()`, `discretise()`, `merge_rare(plots = types des placettes)`, `type_raster()`, `real_type_legend()` (`azonal = FALSE`) | | |
| fiches, clé | `indicator_species()`, `real_fertility()`, `build_key()` sur `obs_pente`, `obs_topo`, `obs_humus` (notés par l'IFN) | | |
| `gnss_validation` | `load_gnss()`, `gnss_field_gradients()`, `validate_maps()` | si `gnss_path` | absent |
| `comparison_table` | `load_reference()`, `compare_gradients()` | si `reference_path` | absent |
| `evidence`, `outputs`, `rapport` | `evidence_table_real()`, `write_outputs(synthetic = FALSE)`, `write_types_gpkg_real()`, Quarto | | |

### Dalles : branchement dynamique et reprise

Les dalles sont groupées en blocs contigus de `lidar_block_size` x `lidar_block_size`
(3 x 3, 225 dalles = 25 blocs). Une branche `targets` par bloc : une branche terminée
n'est pas relancée ; dans un bloc interrompu, `run_tile_block()` saute les dalles dont
`mnt_<dalle>.tif` et `mhc_<dalle>.tif` existent. Les LAZ sont effacés après chaque bloc.
Le tampon de 20 m ne lit que les dalles du bloc : effets de bord entre blocs acceptés,
mesurés en mission 018. `error = "stop"` : jamais de mosaïque partielle silencieuse
(`mosaic_tiles()` vérifie que toutes les dalles attendues sont présentes).

### Entrées absentes

`gnss_path` absent : ligne « 15. Validation thématique par relevés GNSS indépendants »
= `non atteint (entrée absente)`. `reference_path` absent : ligne « 16. Comparaison à la
référence AgroParisTech » = `sautée (entrée absente)`, et aucun fichier de comparaison.
`soil_paths` absent : « 8. Sols » = `non exécuté`. Rien n'est remplacé par du synthétique.

### Choix provisoires (à geler avant la phase 1)

Saison de végétation avril-septembre ; bioclimat = premier axe principal de P - ETP et de
la température moyenne annuelle (centrées-réduites sur les placettes), « plus haut = plus
chaud » ; masque forestier (MHC > 5 m sur au moins la moitié de la cellule) ; seuils par
quantiles ; `azonal = FALSE` partout. Couches de terrain vides (MRVBF sans GRASS, TPI dont
la fenêtre dépasse l'emprise, hauteur au réseau sans cours d'eau) : retirées des
prédicteurs et nommées dans l'état de preuve (`empty_layers()`).

## À vérifier

- Format réel des rasters de référence (noms de couches, codage des 59 types) et ordre des
  chiffres du code à trois chiffres (`recode_3digits()`).
- Correspondance « réserve utile = gradient hydrique » pour le repère de R² de 0,43.
- Pilote COG : les balises `terra::metags` ne sont pas conservées ; la marque synthétique
  est le préfixe `synth_` du nom de fichier.
