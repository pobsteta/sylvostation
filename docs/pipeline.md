# Pipeline `targets` (mission 010)

Source : `_targets.R`, paramétré par `config.yml` (missions 010 et 016). Ce fichier décrit seulement ce qui n'est
pas évident dans le code ; les décisions restent dans `docs/adr/`.

## Mode démo (`demo: true`)

Sans réseau. Emprise : carré de 2 500 m au sud-ouest de `emprise_test` (125 x 125 cellules
de `resolution_m` (20 m), Lambert-93, origine multiple de 20 m ; ADR 0007). Ce qui est **réel réduit** : contour SER
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
2 min 26 s le 2026-11-18 avec la carte hydrique à 25 m (mission 021, avant le passage à 20 m : `terrain` 81 s,
`solar_k` 14 s, `hydric_grid` 3 s, rapport Quarto 18 s). À 20 m (mission 025, 1 dalle, hors ligne) :
112 s en tout (`terrain` 54 s, rapport 27 s, `solar_k` 10 s, `ifn_gradients` 9 s, `hydric_grid` 1 s).
`r.sun` mesuré directement sur 562 500 cellules de 20 m (225 dalles) : 301 s pour les 12 mois avec
ombres (machine chargée, 1 cœur disponible), contre environ 1 min annoncée à 25 m (360 000 cellules,
3 fils, autre mesure) : les deux ne sont pas comparables, la phase des 225 dalles refera la mesure.

**Hors ligne, seule la composante régionale à maille large est produite** : sans ancrage
GBIF réel (un extrait exigerait un DOI, donc un `occ_download` avec compte), les gradients
cartographiés viennent des placettes IFN et du climat SAFRAN. Le LiDAR et le terrain sont
calculés (masque forestier, état de preuve) mais n'entrent dans aucun modèle. Seule
exception, la couche `hydric` (mission 021), calculée et non modélisée : voir « Carte
hydrique ».

### Cibles

| Cible | Fonction | En ligne | Hors ligne |
|---|---|---|---|
| `ser`, `emprise` | `get_ser()`, `real_extent()` (`emprise: test` ou `ser`) | `ser_l93.zip` | extrait |
| `tiles` | `list_tiles()` ou `local_tiles()`, puis `select_tiles(max_tiles)` | WFS | nom du LAZ |
| `tile_blocks`, `lidar_files` | `tile_blocks()` (3 x 3), `run_tile_block()` par branche | `url_npl` | LAZ local |
| `dtm`, `grid` | `mosaic_tiles()` (5 m), `real_grid()` (`resolution_m`) | | |
| `hydro`, `terrain` | `get_hydro_network()`, `real_terrain()` (`mrvbf = TRUE`) | WFS TOPAGE | extrait |
| `forest` | `forest_mask()` : MHC > 5 m sur la moitié de la cellule (provisoire) | | |
| `geol_*` | `read_geology()`, `recode_lithology()` (règles `lithologie_regles.csv` + table de notations `lithologie_notations.csv`, 14 classes dont `volcanite`, `schiste_grauwacke`, `plutonite_intermediaire` ; mission 040), `dominant_lithology(700)` | BD Charm-50 (`bdcharm_departements`) | extrait |
| `ifn` | `load_ifn()`, `filter_greco()`, `filter_releves()` | `fetch_ifn()` | extrait |
| `taxref`, `indicateurs` | `read_taxref()`, `load_indicator_values("tichy")` | `taxref_url`, `tichy_path` | extraits |
| `safran`, `climat` | `fetch_safran()`, `read_safran()`, `safran_climate()` (avril-septembre, interpolation bilinéaire entre centres de mailles, `safran_interpolation`, mission 033). **Emprise lue = boîte de toutes les placettes de la GRECO ∪ emprise de la carte** (497 mailles pour la GRECO D) ; le fichier filtré `emprise_<année>_<emprise>.csv` porte son emprise dans son nom, jamais resservi pour une autre (mission 035) | SIM2 | 12 mailles |
| `mnt_large_file`, `alt_mailles`, `t_lapse`, `t_validation`, `t_coarse` | mission 039 : `fetch_mnt_large()` (BD ALTI 250 m, WMS de l'IGN, Licence Ouverte), `safran_cell_altitude()` (altitude moyenne des mailles), `safran_lapse_rate()` (gradient T ~ z + x + y entre mailles), `t_correction_validation()` (maille laissée de côté), `coarse_t_corr_layer()` (T corrigée moyennée dans 700 m, couche large) ; `climat_temperature: corrigee` | WMS BD ALTI | `mnt_large_path`, sinon **absent** : T bilinéaire, avertissement |
| `ifn_gradients` | `ifn_real_gradients()` : Tichý, `ru_from_texture()`, `hydric_stress()` (ADR 0006), `bioclim_axis()` ; axe appris sur `coarse_t_corr_700m` si la T corrigée existe (mission 039) | | |
| `solar_k` | `solar_factor()` : k mensuel de GRASS `r.sun` (ciel clair) sur l'altitude de la grille ; repli k = 1 sans GRASS | | |
| `ru_mailles` | `ru_by_safran_cell()` : RU uniforme par maille SAFRAN (médiane euptf2 des placettes IFN ; médiane de l'emprise sous `ru_min_placettes` = 5 placettes, provisoire) | | |
| `hydric_grid` | `hydric_stress_grid()` : Istress à `resolution_m` (BILJOU, ETP Penman biljouR sur SSI × k), plat de référence, écart table / calcul direct ; météo interpolée sur un réseau de `hydric_node_res_m` = 1 000 m (mission 033) ; mission 039 : RU apprise (`ru_map`, complétée par la RU de la maille, `ru_fill_by_cell()`) et T journalière corrigée du relief par nœud (`t_lapse`, `alt_mailles`) si elles existent | | |
| `predictors_climat`, `clim_vars`, `coarse_vars`, `t_corr_grid` | `coarse_predictors()` + `coarse_t_corr_700m` ; `model_climate_vars()` : variables climatiques selon `climat_temperature` et `trophique_climat` ; `t_corrected()` : T corrigée à la cellule (`t_corr`, **variable fine**, bioclimat de la carte par `apply_bioclim(layers = c(coarse_t_corr_700m = "t_corr"))`) | | |
| `soilgrids_texture_files`, `cu700`, `ru_learn`, `ru_model`, `ru_cv`, `ru_map`, `ru_sg_diagnostic` | mission 039, `ru_carte: apprise` : `fetch_soilgrids_texture()` (24 couches, CC BY 4.0), `soilgrids_cu()` (euptf2 par horizon, cailloux), `coarse_cu_layers()` (700 m), `ru_learned_data()` + `fit_gradient()` : RU des placettes apprise sur la géologie encodée et les capacités SoilGrids ; `spatial_cv()` aux deux tailles de blocs (`ru_apprise_validation.csv`) ; `ru_soilgrids_diagnostic()` : RU SoilGrids brute contre RU IFN (diagnostic, jamais la carte) | files.isric.org | **absent** : RU par maille |
| `lateral` | `lateral_balance()` : bilan latéral de Piedallu et al. (2006, tableau 20), carte de contrôle, `bilan_lateral: false` par défaut, jamais ajouté à la RU | | |
| `anchors`, `local_trophic`, `maps_regional`, `local_map`, `comparaison_locale` | `get_gbif()`, `clean_occ()` (écarte les licences CC BY-NC, les jeux Pl@ntNet et les licences inconnues, effectifs par motif dans l'attribut `ecartees`, mission 037), `grid_bioindication()`, `gbif_anchors()` | `occ_search` ou `occ_download` | **absent** |
| `geol_placettes`, `geol_classes_placettes`, `litho_placettes` | `read_geology()` sur tous les départements de `bdcharm_departements` (7 pour la GRECO D) recoupés à la boîte des placettes ; `lithology_at_points()` : classe et formation (`NOTATION`) dominantes dans 700 m, disque couvert à moins de `litho_min_cover` = pas de lithologie (placette retirée et comptée) ; formations sans règle listées (`formations_non_classees`) | BD Charm-50 | extrait |
| `soilgrids_file`, `ph_layer` | `fetch_soilgrids_ph()` : pH SoilGrids 2.0 0-5 cm (250 m, CC BY 4.0), fenêtre de la GRECO, cache par emprise ; `soilgrids_disk_mean()` : moyenne dans 700 m (`soilgrids_ph: true`) | files.isric.org | **absent** (jamais remplacé) |
| `train_climat`, `trophic_enc`, `litho_layer`, `formation_layer`, `calibration_effectifs` | placettes avec climat complet ; `encode_by_blocks()` : lithologie (classe) et formation encodées par le trophique moyen rétréci (`litho_encoding_k`) : la **classe** avec toute la partie d'apprentissage (`oof = FALSE`), la **formation** hors pli (blocs spatiaux, `oof = TRUE`) ; `lithology_encoded_layer()` et `formation_encoded_layer()` (mode du disque calculé à 100 m) pour la carte ; `calibration_counts()` : entonnoir des effectifs | | |
| `models`, `cvs`, `maps` | `fit_gradient()`, `spatial_cv()`, `predict_raster()` (trophique, hydrique) ; bioclimat = `apply_bioclim()` ; couche `hydric` de `gradient_map` = `-is_topo` de `hydric_grid` (le modèle régional hydrique ne sert qu'à la validation croisée) ; `incertitude.tif` : trophique seul | | régional seul |
| `espar_codes`, `ifn_dir`, `espar_cdref`, `arbres_cd_ref`, `essence_dominante`, `controle_essence`, `cv_essence`, `controle_bdforet` | `read_espar_codes()`, `read_espar_cdref()` et `read_tree_cd_ref()` (retrait des essences de l'indice par jointure sur `CD_REF`), `dominant_species()` (surface terrière pondérée par `W`), `essence_control()` (trophique prédit hors pli contre essence en place, alertes), `essence_sensitivity()` (gain de R² avec l'essence + placebo), `bdforet_class_means()` (option) | `essence_*` et `bdforet_*` de `config.yml` (valeurs provisoires, sans source) | extrait IFN du dépôt (`ifn_espar_codes.csv`) ; BD Forêt : **réel et facultatif seulement** |
| typologie | `default_thresholds()`, `discretise()`, `merge_rare(plots = types des placettes)`, `type_raster()`, `real_type_legend()` (`azonal = FALSE`) | | |
| fiches, clé | `indicator_species()`, `real_fertility()`, `build_key()` sur `obs_pente`, `obs_topo`, `obs_humus` (notés par l'IFN) | | |
| `gnss_validation` | `load_gnss()`, `gnss_field_gradients()`, `validate_maps()` | si `gnss_path` | absent |
| `comparison_table` | `load_reference()`, `compare_gradients()` (à 100 m : plus petit multiple commun de `resolution_m` et de 50 m, ADR 0007) | si `reference_path` | absent |
| `evidence`, `outputs`, `rapport` | `evidence_table_real()`, `write_outputs(synthetic = FALSE)`, `write_types_gpkg_real()`, Quarto | | |

### Calibration sur toute la GRECO (mission 035)

Le modèle régional est calibré sur **toutes** les placettes IFN de la GRECO (D : 2 894 avec
trophique calculé, au lieu de 187 en 018) avec des prédicteurs tous à maille large (règle des
700 m) : climat SAFRAN interpolé (033), lithologie et formation géologique dominantes dans
700 m (BD Charm-50, 7 départements), pH SoilGrids moyenné dans 700 m. L'effectif 187 de 018
n'était pas une limite des données : le cache `emprise_<année>.csv` de 12 mailles avait été
resservi pour toute la GRECO (`fetch_safran()` ne regardait pas l'emprise). Le tableau
`effectifs_calibration` (table de sortie) donne l'entonnoir : lignes `PLACETTE` → relevé →
saison → sans incident → trophique → climat → lithologie → apprentissage.

- **Encodage sans fuite** : la lithologie (classe) et la formation sont remplacées par le
  trophique moyen rétréci vers la moyenne générale (`(n × moyenne + k × générale) / (n + k)`,
  `litho_encoding_k` = 10, provisoire). À l'apprentissage, la **classe** (12 niveaux, des
  centaines de placettes par niveau) est encodée avec toute la partie d'apprentissage
  (`oof = FALSE` : R² par blocs 0,15 contre 0,09 hors pli) et la **formation** (666 niveaux,
  certains rares) hors pli (`oof = TRUE`, blocs spatiaux : 0,264 contre 0,242). En validation
  croisée (`spatial_cv(encode = )`) les deux encodages sont refaits dans chaque pli, et les
  colonnes de même nom déjà présentes sont recalculées : la réponse du pli de test n'y
  intervient jamais (un test le vérifie).
- **Blocs de la validation croisée** : `cv_block_m` (config.yml, `null` par défaut = portée de
  l'autocorrélation estimée sur la réponse ; le R² publié, le plus prudent : environ 22 km pour
  le trophique de la GRECO D, 76,7 km pour l'hydrique). La cible `cv_sensibilite` refait la
  validation de **chaque gradient modelisé** (`trophic`, `hydric`) avec des blocs de
  `cv_block_sensibilite_m` (8 358 m) ; les lignes « `<gradient>` (sensibilité : blocs de taille
  fixe) » figurent dans `val_stats` (`validation_table()`) et le rapport. Si une sensibilité
  échoue (jeu trop petit pour 5 plis de cette taille, par exemple hors ligne), un **avertissement
  donne la raison** et la ligne est omise.
- **Alerte `blocs_insuffisants`** : `validation_stats.csv` porte les colonnes `blocs` (blocs
  occupés), `k`, `blocs_insuffisants` (vraie si `blocs < cv_min_blocs_par_pli × k`, soit moins de
  20 blocs pour 5 plis ; valeur provisoire, à vérifier) et `alerte`. Le rapport l'affiche en clair :
  « R² peu interprétable : N blocs pour k plis ; voir la ligne de sensibilité ». Cas réel : l'hydrique
  de la relance 035, à 8 blocs.
- **Pas de variable de peuplement** (ADR 0008) : ni essence, ni BD Forêt dans les prédicteurs.
- **Placettes sans géologie** (disque couvert à moins de `litho_min_cover`) : retirées de
  l'apprentissage et comptées, jamais complétées ; formations sans règle : `non_classe`
  (jamais d'affectation par défaut), listées dans `formations_non_classees`.
- **Réponse trophique** : indice de Tichý sur toutes les espèces à valeur indicatrice
  (historique). `compute_gradients(exclude_cd_ref = read_tree_cd_ref(), abundance_weights = TRUE)`
  calcule la variante sans essences arborées et pondérée par l'abondance ; voir
  `docs/referentiels.md` § 35 pour les R² côte à côte. Non activée dans `_targets.R`.
- **Hydrique** : prédicteurs climatiques seuls ; la lithologie n'y entre pas.

### Carte hydrique (mission 021)

Méthode A de `docs/referentiels.md` § 25.4 (adaptation non validée de Dyer 2009) : la
topographie module l'**ETP** par le rayonnement reçu par la pente, jamais la réserve utile.

- `solar_factor()` : k(x, mois) = G `r.sun`(pente, exposition, ombres) / G `r.sun`(plat,
  sans ombres), ciel clair, 12 jours types, sur l'altitude de `terrain` (environ
  5 min pour 225 dalles à 20 m, 301 s mesurés pour 562 500 cellules, mission 025 ; plus de deux heures à 5 m, mesuré). Pourtour de la grille :
  `NA` (pente inconnue).
- `hydric_stress_grid()` : rg = SSI × 0,01 × k, ETP de Penman de `biljouR`, P et RU de la
  maille SAFRAN, BILJOU ; plat de référence par la même formule (k = 1) ; table par
  maille sur les classes de `k_sv` (pas `hydric_pas_k`), écart à un calcul direct sur
  `hydric_n_controle` cellules par maille, sans seuil bloquant (`hydrique_ecart_table.csv`).
- **Coût de calcul (mission 028).** Le temps de `hydric_grid` et de `ifn_gradients` était
  presque entièrement `biljouR::biljou_run()` (boucle de 11 000 jours qui réécrit un
  `data.frame` à chaque jour ; 9,9 s par passe de 30 ans mesurés, machine chargée, voir plus bas), appelée une fois par classe
  de `k_sv` (et par RU), plus une fois par cellule de contrôle, et une fois par couple
  (maille, RU) pour les placettes. `.biljou_cols()` fait avancer **toutes ces passes d'une
  maille ensemble**, jour par jour, en vecteurs (même bilan, mêmes fonctions de `biljouR`
  pour l'interception, la transpiration et le sous-bois ; seule la boucle d'état est
  réécrite) ; l'ETP de Penman des profils de `k` ne relit plus les dates ; l'attribution des
  mailles est vectorisée. Résultats **identiques** (égalité exacte mesurée, tolérance écrite
  et testée : 1e-12 en relatif contre `biljou_run()`, `.biljou_ru_ref()`). Pas de
  parallélisme : la vectorisation suffit.
  **Mesures** (2026-11-18, machine chargée : charge 10 sur 8 cœurs, pendant le run des 225
  dalles, donc des temps pessimistes ; ancien code = commit 38f3a39 ; extrait SAFRAN réel de
  12 mailles, 2003-2004, 731 jours ; résultats identiques à 1e-12, mesuré) :
  grille de 5 671 cellules (150 m, 2 mailles) : **61,1 s → 1,6 s** (×38) ; 200 placettes
  fictives (RU distinctes, 12 mailles, `synth_`, hors IFN réel) : **73,7 s → 1,2 s** (×59) ;
  `.biljou_ru` seul, 20 RU sur 731 jours : ×73. Une passe de 30 ans (10 965 jours) : 9,9 s
  par `biljou_run()`, 1,4 s pour une colonne vectorisée, 2,4 s pour 60 colonnes (0,02 s par
  colonne en plus).
  **Profil** (`Rprof`) : ancien code, 97 à 99 % du temps dans `biljou_run()` (dont
  `rainfall_interception` 28 %, `$<-.data.frame` 19 à 25 %, `pmax`/`pmin` 19 %,
  `match.arg` 8 %) ; interpolation par cellule, extraction et lecture : moins de 1 %.
  Nouveau code (grille) : ETP de Penman des profils de `k` 32 %, boucle d'état 66 %, le reste
  négligeable ; placettes : boucle d'état 65 %.
  **Projection** (extrapolée, non mesurée sur les 225 dalles) : le coût dépend du nombre de
  **mailles SAFRAN touchées** et de la durée de la série, pas du nombre de cellules (grille
  de 51 200 cellules à 50 m : pas de surcoût mesurable contre 5 671). Sur 30 ans, mesuré sur
  l'extrait (série 2003-2004 répétée 15 fois, `synth_`) : nouveau code 4,4 s par maille ;
  ancien code ≈ 458 s par maille (30,5 s sur 2 ans × 15, linéaire en jours). Pour
  `hydric_grid` sur 562 500 cellules à 20 m, avec **5 mailles touchées (hypothèse)** : ancien
  ≈ 38 min, nouveau ≈ 22 s plus le coût par cellule, non mesuré à cette taille (inférieur à
  une minute d'après les 51 200 cellules). Pour `ifn_gradients` (2 894 placettes) : le coût
  est proportionnel au nombre de couples (maille, RU) distincts, inconnu sans les données
  réelles ; l'ancien run de 19 min pour 9 392 placettes ramené à 2 894 placettes donne au
  plus 6 min (proportionnel), soit ≈ 6 s avec le facteur ×60 mesuré.
- RU uniforme par maille (`ru_by_safran_cell()`, `hydrique_mailles.csv`) : provisoire.
- **Descente d'échelle du climat (mission 033, provisoire, référentiels § 32).** Avant 033,
  le climat était celui de la maille SAFRAN de 8 km, uniforme : la maille expliquait 84 %
  de la variance d'Istress, 78 % du trophique, 95 % du bioclimat. Maintenant
  (`safran_interpolation: bilineaire`) :
  - les séries journalières (pluie liquide, neige, T, vent, humidité, SSI, ETP) sont
    interpolées **bilinéairement entre les centres des mailles** (`safran_weights()`) ;
    BILJOU tourne **par nœud d'un réseau de 1 km** (`hydric_node_res_m`), non par cellule
    de 20 m ; la latitude et l'altitude d'un nœud sont pondérées de même ; la RU reste
    **uniforme par maille** (plus proche maille), donc un saut de RU subsiste à la limite ;
  - `climat` (`p_sv`, `etp_sv`, `t_moy`) est l'interpolation bilinéaire des agrégats de
    maille ; les placettes IFN reçoivent **le même climat kilométrique** (`coarse_*`), et
    leur Istress est calculé sur les séries interpolées au point (variable large : la règle
    des 700 m est respectée, `safran_weights()` n'extrait rien de fin) ;
  - **aucune correction d'altitude** (option A différée : gradient vertical non stable,
    aucune valeur publiée lue) : le champ est lissé à l'échelle de 8 km, il ne reproduit pas
    le relief ;
  - `safran_interpolation: proche` redonne le comportement d'avant 033.
  Mesure sur les 225 dalles de D11 (entrées de 018, même emprise, sans r.sun refait ; avant =
  `data/sorties/D11/` de 018, après = même chaîne en aval, scratchpad) : part de la variance
  expliquée par la maille (cellules forestières typées, n = 394 055) : Istress 0,844 → 0,631 ;
  trophique 0,778 → 0,142 ; bioclimat 0,950 → 0,753 ; part des cellules dans le type modal de
  leur maille 0,896 → 0,532 ; part des limites entre types sur une limite de maille 0,052 →
  0,009. Saut médian d'Istress entre cellules voisines (20 m), limite de maille / intérieur :
  horizontal 15,7 / 0,39 (rapport 40) → 8,8 / 0,34 (rapport 26) ; vertical 6,1 / 0,53 (rapport
  12) → 1,6 / 0,48 (rapport 3,4). Trophique et bioclimat : rapport 1,0 à 2,4 (continus). Le saut
  qui subsiste sur Istress est celui de la RU (écart médian 40 mm entre mailles voisines,
  même valeur de 8,8 sur les 1 509 paires à RU différente ; saut aux autres limites de
  nœuds de 1 km : 1,9). Temps de `hydric_grid` : 15 s → 258 s (réseau de 1 km, 9 mailles).
  **Prix à lire** : la validation croisée spatiale du trophique passe de R² ≈ 0 à −0,23
  (187 placettes, 2 variables climatiques lissées) : la carte ne dit plus « 9 mailles », elle
  dit « un gradient climatique lisse », pas plus de signal ; le trophique attend la mission
  034.
- Sorties : couche `hydric` de `gradients.tif` (= `grad_hydrique_carte` = -Istress),
  `hydrique.tif` écrit par `write_hydric_grid()` (COG, préfixe `synth_` si
  synthétique ; `is_topo`, `nj_topo`, `is_plat`, `k_sv`, `ru_maille`, masqués par la
  forêt), ligne « 6 bis » de l'état de preuve (méthode, RU, écart, échelle, limites ;
  état « repli » si la méthode n'est pas `biljou_topo`).
- **Placettes IFN** : Istress sans k, sur la RU de la placette (`hydric_stress()`, règle
  des 700 m) ; la carte et les placettes ne sont pas à la même échelle. Les placettes
  sont pourtant discrétisées avec les seuils de la carte hydrique alors que leur Istress
  est calculé sans k : cet écart d'échelle peut déplacer une placette d'un type hydrique
  à l'autre et changer les fusions de types rares (`merge_rare(plots = …)`). Le calcul
  n'est pas corrigé ; l'état de preuve (ligne « 6 bis ») le dit.
- **TWI, MRVBF et `hauteur_reseau`** restent hors de BILJOU : ce sont des prédicteurs du
  seul modèle local trophique (ancrages GBIF, en ligne) ; aucun modèle hydrique local
  n'existe, la composante hydrique locale passe par Istress seul.
- **MRVBF et `hauteur_reseau` depuis la mission 027** (référentiels § 28) :
  - *MRVBF* : calculé sur le MNT agrégé à la maille choisie par `mrvbf_res`
    (`derive_terrain()`, défaut = maille du MNT ; décision de l'orchestrateur du 2026-11-18 :
    la maille de la grille, `resolution_m` = 20 m, plus proche du domaine de validation du
    manuel, 25 m), puis rééchantillonné (bilinéaire) sur le MNT. Seuil de pente
    `t_slope` = 16 % x 2^(log3(25 / maille)), soit 18,4 % à 20 m (**provisoire, à vérifier**
    sous 25 m), `t_vf = 0,3`. Prix mesuré sur les 4 dalles : à 20 m le MRVBF reconnaît moins
    de fonds étroits qu'à 5 m (part >= 0,5 : 7,4 % contre 24,1 %, sur la grille de 20 m).
    La maille est la clé `mrvbf_res_m` de `config.yml` (défaut `resolution_m`, soit 20 ;
    provisoire, à vérifier), transmise par `real_terrain(mrvbf_res = )`. **Compromis accepté**
    (décision de l'orchestrateur du 2026-11-18) : les fonds étroits sont moins vus à 20 m
    qu'à 5 m (4 dalles, maille de 5 m : part >= 1,5 de 7,9 % à 0,8 %, part >= 0,5 de 23,8 %
    à 7,6 %, réseau >= 0,5 de 68 % à 58 %).
  - *HAND* : franchit les cuvettes du MNT par leur col ; réseau TOPAGE seul, **sans
    densification** (décision de l'orchestrateur du 2026-11-18). Sensibilité mesurée au
    seuil d'accumulation, si l'on densifiait (4 dalles, 5 m) : NA 11,0 % (TOPAGE seul), 7,1 %
    (+ 50 ha), 2,6 % (+ 10 ha), 1,2 % (+ 2 ha) ; médiane 86,6 m, 86,3, 74,3, 59,1 m
    (référentiels § 28.3). Les HAND de 200 à 325 m sont réels (têtes de bassin à plus de
    500 m du réseau), pas un défaut de calcul.
  - *Limites connues du franchissement* : (1) dans une **zone plate jouxtant le ruisseau**
    (cellules de même altitude, p. ex. fond de vallée aplani, lac), les cols ont des
    poids égaux et l'arbre couvrant minimal en choisit un **arbitrairement** (ordre des
    cellules) : l'eau peut sortir par le bord du MNT plutôt que par le ruisseau voisin,
    d'où des `NA` ; (2) un **MNT entièrement plat** avec réseau donne `NA` partout sauf sur
    les cellules du réseau (essai : 30 x 30 cellules, 870 `NA`, 30 zéros) ; sans réseau dans
    l'emprise, `NA` partout avec avertissement. Le LiDAR réel ne donne pas de plat parfait ;
    à surveiller sur les lacs et les plans d'eau (classe 9) des 225 dalles.
  - Les sorties produites avant cette mission (run de 018) sont à recalculer depuis la cible
    `terrain`.
- Replis signalés (attribut `methode`) : `biljou_climatique` (GRASS absent, k = 1),
  `climatique_etp_safran` (SAFRAN sans `T`, `FF`, `HU` ou `SSI`), `repli_ru`.

### Dalles : branchement dynamique et reprise

Les dalles sont groupées en blocs contigus de `lidar_block_size` x `lidar_block_size`
(3 x 3, 225 dalles = 25 blocs). Une branche `targets` par bloc : une branche terminée
n'est pas relancée. Les LAZ sont effacés après chaque bloc.

**Cache par dalle (mission 032).** `run_tile_block()` réutilise une dalle seulement si
`mnt_<dalle>.tif` et `mhc_<dalle>.tif` existent, se lisent avec `terra`, sont en EPSG:2154 à la
maille demandée (1 m) et si le fichier `params_<dalle>.txt` (écrit à leur calcul : maille,
tampon, moteur) correspond aux paramètres demandés ; sinon la dalle est recalculée. Une dalle
sans `params_*.txt` (calculée avant la mission 032) est acceptée sur les contrôles du raster.
Le nombre de coeurs (`lidar_ncores`) ne change pas le résultat et n'est pas consigné.
Avant tout recalcul, `run_tile_block()` efface les sorties et le `params_*.txt` de la dalle
(une coupure ne laisse pas de dalle mixte). Une dalle reprise sans `params_*.txt` est signalée
par un message (une ligne par bloc : nombre de dalles et paramètres demandés) ; l'écriture
des paramètres des 225 dalles de 018 se fera hors de la mission 032.
Recalcul forcé de toutes les dalles : seule la valeur exacte `SYLVOSTATION_LIDAR_FORCE=1` (toute
autre valeur, `0` comprise, ne force pas) dans l'environnement, puis
`targets::tar_invalidate(lidar_files)` et `tar_make()` ; ou `run_tile_block(force = TRUE)`.

**Dépendances de `_targets.R` à `config.yml`.** `targets` suit chaque objet global lu par une
cible : lire `cfg` en entier rendait toutes les cibles périmées à l'ajout d'une clé (écart du
2026-11-19, 10 à 16 h de LiDAR). Les cibles `ser`, `emprise`, `tiles`, `tile_blocks` et
`lidar_files` ne lisent donc que des scalaires extraits au début du mode réel (`p_ser_code`,
`p_ser_buffer_m`, `p_max_tiles`, `p_block_size`, `p_lidar_buffer_m`, `p_lidar_ncores`,
`p_lidar_res_m`, `p_lidar_engine`, `cfg_emprise`, `src_ser`, `src_laz`) : seul le changement
d'une de ces valeurs les périme (test dans `tests/testthat/test-pipeline-reel.R`). Toute
nouvelle cible d'emprise ou de LiDAR suit la même règle : jamais `cfg` ni `src` en entier.
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
  option `sylvostation.download_retries`, posée au démarrage du mode réel par `_targets.R`
  depuis la clé `download_retries` de `config.yml` (3, provisoire, entier >= 1). Les
  téléchargements hors `fetch_cached()` (SER et dalles LiDAR par `.download_once()`,
  tableau d'assemblage WFS LiDAR, GetCapabilities et pages TOPAGE) passent par le même
  mécanisme (`.download_retry()`).
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
quantiles ; `azonal = FALSE` partout. Carte hydrique (§ 25.5) : ciel clair pour k,
Penman de `biljouR` à la place de Turc, Linke 3,0, albédo 0,2, jours de Klein, pas de
0,5 h, RU uniforme par maille, altitude moyenne de la maille, pas des classes de k. Couches de terrain vides (MRVBF sans GRASS, TPI dont
la fenêtre dépasse l'emprise, hauteur au réseau sans cours d'eau) : retirées des
prédicteurs et nommées dans l'état de preuve (`empty_layers()`).

### Bioclimat et RU plus fins (mission 039)

Choix et mesures : `docs/referentiels.md` § 37. En bref : température SAFRAN corrigée du relief
par le gradient lu entre les mailles (−0,49 °C/100 m sur la GRECO D ; RMSE de la validation croisée
0,11 °C contre 0,22 en bilinéaire), apprise sur sa moyenne dans 700 m (`coarse_t_corr_700m`) et
appliquée à la cellule (`t_corr`, fine) ; RU de la carte apprise (géologie et SoilGrids dans 700 m),
la RU SoilGrids brute restant un diagnostic (biais +137 mm à 1 m) ; bilan latéral câblé et
désactivé ; **climat retiré du modèle trophique** (`trophique_climat: sans`, décision de Pascal du
2026-11-20), les variantes `actuel` (P − ETP et T bilinéaire, état d'avant 039) et `corrige`
(P − ETP et T corrigée) restant des options ; table `variables_modeles`. Clés de `config.yml` : `climat_temperature`, `trophique_climat`, `ru_carte`,
`mnt_large_res_m`, `mnt_large_path`, `bilan_lateral`, `bilan_lateral_ru_mm`, `bilan_lateral_coef`.
Sorties ajoutées : `temperature_corrigee.tif`, `ru_apprise.tif`, `bilan_lateral.tif` (si activé),
tables `temperature_gradient`, `temperature_validation`, `ru_apprise_validation`,
`ru_soilgrids_diagnostic`, `bilan_lateral_parts`. Hors ligne (extraits du dépôt), sans MNT de 250 m
ni SoilGrids : état d'avant 039, avec un avertissement.

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
  gradient hydrique `is_topo` et `k_sv` de `hydrique.tif`, incertitude `sd_cv`
  et `aoa`, gradients), chacune avec légende, échelle, flèche du nord, EPSG:2154 et ses
  limites ; puis état de preuve, types, fiches, clé, validation, limites, reproductibilité.
- **Démo** : encadré « DONNÉES SYNTHÉTIQUES » en tête du HTML et du PDF ; la carte hydrique
  n'existe qu'en mode réel (le rapport le dit à sa place).
- **Le PDF n'est jamais obligatoire** : sans moteur LaTeX (`xelatex` absent), ou si son
  rendu échoue, le HTML est livré seul, un avertissement dit pourquoi (attribut
  `pdf_message` du résultat) et aucun PDF ancien ne reste dans le dossier. Sans Quarto, la
  cible n'existe pas (comme avant).
- **Dépendance LaTeX** : polices DejaVu, paquets `longtable`, `booktabs`, `etoolbox`,
  `fontspec` ; `tinytex` installe un paquet manquant par `tlmgr` s'il a le réseau.

## Site pkgdown et page de résultats (mission 023)

Le site (`_pkgdown.yml`, construit dans `site/` car `docs/` porte la documentation du projet)
est publié par `.github/workflows/pkgdown.yaml` : construction sur chaque pull request (sans
déploiement), déploiement sur la branche `gh-pages` seulement après un push sur `main`.
Deux jobs : `build` (jeton en lecture seule, sert aussi aux PR) et `deploy` (écriture, seulement sur
push de `main`). `CLAUDE.md` est retiré de la copie de CI (pkgdown rend tout `.md` de la racine) et une
garde fait échouer le build si une page interne (`CLAUDE`, `pilotage/`, `.claude`) apparaît dans
`site/`, `sitemap.xml`, `search.json` ou `llms.txt`. Prérequis, à faire une fois par Pascal : Réglages du dépôt > Pages > Source = branche `gh-pages`.

- **Référence** des fonctions groupée par étape du pipeline ; **articles** : le tutoriel
  `massif-test` (démo, données synthétiques) et `vignettes/articles/resultats-vosges-d11.Rmd`
  (résultats du run réel de la mission 018 sur l'emprise test de la SER D11).
- **L'article ne calcule rien** : il lit `vignettes/articles/figures/` (images PNG réduites,
  moins de 2 Mo au total, et petites tables CSV), produit à la main par
  `Rscript inst/scripts/figures_article_vosges.R AAAA-MM-JJ <data/sorties/D11>` (la date du run est un argument obligatoire : les sorties n'en consignent aucune) après un run réel. Le
  script refuse un dossier de sorties à préfixe `synth_`. Chaque figure porte sa source, la
  date du run, l'emprise et le système (EPSG:2154). Pour mettre l'article à jour : relancer le
  script, relire les chiffres du texte, commiter.
- Les rasters complets ne sont pas versionnés ; le rapport PDF du run n'est pas joint à la
  release (la release ne porte que le tarball du paquet).
- Construction locale : `pkgdown::check_pkgdown()` puis
  `pkgdown::build_site()` sur une copie du dépôt privée de `CLAUDE.md` (sortie dans `site/`, ignoré par git).


## Contrôle par essence et modèle de sensibilité (mission 037, ADR 0008)

Cibles du mode réel, **hors carte** : `controle_essence`, `cv_essence` et, si `bdforet_controle`,
`controle_bdforet` produisent `controle_essence.csv`, `controle_essence_par_essence.csv`,
`sensibilite_essence.csv` (et `controle_bdforet_classes.csv`) dans les sorties. Aucune n'est une
entrée de `train`, `vars_modele`, `models`, `cvs`, `maps`, `gradient_map` ni des types (un test lit
`_targets.R` pour le vérifier). L'essence dominante vient de la table ARBRE (observée sur la placette,
non extraite d'un raster : la règle des 700 m n'est pas en cause) ; le préfixe `coarse_` de
`coarse_essence_enc` ne sert qu'à passer `assert_no_fine_extract_on_ifn()`.

- **Contrôle** : placettes pures (au moins `essence_part_pure` de la surface terrière pondérée par `W`) ;
  trophique prédit **hors pli** (prédictions de `cvs` et de `cv_sensibilite`) contre la moyenne d'essence
  apprise hors pli sur le trophique **sans les arbres**. Trois mesures : accord d'ordre (ratio sous
  `essence_alerte_ratio`), écart par essence (au-dessus de `essence_alerte_ecart`), amplitude (pente sous
  `essence_alerte_pente`) ; Tichý en repère indicatif. Les alertes s'affichent, elles ne bloquent pas. Une validation croisée ou une taille de blocs impossible donne un avertissement avec sa raison et la partie manquante est omise (jamais un silence) ; `bloc_m` est arrondi au mètre.
  Le **défaut d'amplitude** (prédictions écrasées vers la moyenne) est en tête du rapport.
- **Sensibilité** : même validation croisée spatiale du trophique, plus l'essence dominante encodée dans
  chaque pli (variantes : essence fine, groupes de la BD Forêt, placebo). Publiée avec la mention
  « ne pas lire comme la carte ».
- **Seuils** : valeur provisoire, sans source, à vérifier (`config.yml`).
- **BD Forêt** (`bdforet_controle: false` par défaut) : télécharge la couche WFS dans `data/cache/bdforet`
  (hors dépôt, licence contradictoire, `docs/referentiels.md` § 33.5 bis et § 36) ; seules les moyennes par
  classe sont publiées.

## Carte trophique locale ou régionale (mission 037)

En ligne, le modèle local du trophique (`local_trophic`, ancrages GBIF) **ne remplace la carte
régionale (`maps_regional`, placettes IFN) que s'il fait mieux** en validation croisée, sur les mêmes
ancrages et les mêmes plis (décision de Pascal, option b). `compare_local_regional()` évalue le local hors
pli par blocs et lit la carte régionale aux ancrages ; le gain de R² a un IC par bootstrap de blocs
(`local_ic_niveau`, `local_bootstrap`) ; le local remplace seulement si la **borne basse de l'IC dépasse
`local_gain_min`** (0,02). Comparaison impossible (modèle local absent, moins de `local_min_ancrages`
ancrages ou `local_min_blocs` blocs, carte régionale indéfinie) : **avertissement avec la raison, carte
régionale gardée**, ligne de décision écrite quand même. Hors ligne (pas d'ancrage cherché) : pas de
comparaison, carte régionale. `select_trophic_map()` est le seul passage du local vers `maps`. Sorties :
`comparaison_trophique_locale.csv` (une ligne : R² local et régional, gain, IC, décision, motif ; le
régional recalibré hors pli est une **information**, jamais un critère) et
`comparaison_trophique_locale_par_pli.csv` ; le rapport écrit quelle carte est publiée et pourquoi, avec
les trois asymétries (décalage de domaine, fuite possible en faveur du régional, représentativité).
L'IC est conditionnel aux prédictions hors pli figées. Le local prend les mêmes variables larges que le régional (`vars_modele$trophic`, donc il suit
`trophique_climat`) plus des variables fines nommées (cible `vars_fines` : terrain fin non vide, sols), écrites dans
`variables_locales` (`local_trophic_vars()`). Seuils :
valeur provisoire, sans source, à vérifier (`config.yml`) ; justification : `docs/referentiels.md` § 41.
