# Package index

## Configuration, règles et garde-fous

Lecture de config.yml, contrôle du système de coordonnées (EPSG:2154) et
règle bloquante des 700 m.

- [`sylvostation`](https://pobsteta.github.io/sylvostation/reference/sylvostation-package.md)
  [`sylvostation-package`](https://pobsteta.github.io/sylvostation/reference/sylvostation-package.md)
  : sylvostation : catalogue de stations forestières par sylvoécorégion
- [`read_config()`](https://pobsteta.github.io/sylvostation/reference/read_config.md)
  : Lire et valider la configuration
- [`assert_crs_2154()`](https://pobsteta.github.io/sylvostation/reference/assert_crs_2154.md)
  : Vérifier qu'un objet spatial est en Lambert-93
- [`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
  : Règle bloquante : pas d'extraction fine sans précision de
  localisation suffisante
- [`assert_not_synthetic()`](https://pobsteta.github.io/sylvostation/reference/assert_not_synthetic.md)
  : Refuser un fichier synthétique en mode réel
- [`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md)
  : Marquer des points comme placettes IFN
- [`COARSE_VARIABLES`](https://pobsteta.github.io/sylvostation/reference/COARSE_VARIABLES.md)
  : Variables à maille large (autorisées aux placettes IFN)
- [`FINE_VARIABLES`](https://pobsteta.github.io/sylvostation/reference/FINE_VARIABLES.md)
  : Variables fines (interdites aux placettes IFN)
- [`fetch_cached()`](https://pobsteta.github.io/sylvostation/reference/fetch_cached.md)
  : Télécharger un fichier une seule fois (cache local), ou refuser hors
  ligne

## 

Emprise, grille et dalles LiDAR

- [`get_ser()`](https://pobsteta.github.io/sylvostation/reference/get_ser.md)
  : Contour d'une sylvoécorégion (SER), avec tampon

- [`build_grid()`](https://pobsteta.github.io/sylvostation/reference/build_grid.md)
  : Grille vide alignée sur des multiples de la résolution

- [`real_extent()`](https://pobsteta.github.io/sylvostation/reference/real_extent.md)
  : Emprise de travail du mode réel

- [`real_grid()`](https://pobsteta.github.io/sylvostation/reference/real_grid.md)
  : Grille de travail du mode réel

- [`list_tiles()`](https://pobsteta.github.io/sylvostation/reference/list_tiles.md)
  : Tableau d'assemblage LiDAR HD sur une emprise

- [`local_tiles()`](https://pobsteta.github.io/sylvostation/reference/local_tiles.md)
  : Tableau des dalles à partir de fichiers LAZ locaux (sans réseau)

- [`fetch_mnt_large()`](https://pobsteta.github.io/sylvostation/reference/fetch_mnt_large.md)
  : MNT de 250 m (BD ALTI) sur une emprise, en cache

- [`select_tiles()`](https://pobsteta.github.io/sylvostation/reference/select_tiles.md)
  :

  Garder au plus `max_tiles` dalles, les plus proches du centre de
  l'ensemble

- [`tile_blocks()`](https://pobsteta.github.io/sylvostation/reference/tile_blocks.md)
  :

  Grouper les dalles en blocs contigus de `size` x `size`

- [`run_lasr()`](https://pobsteta.github.io/sylvostation/reference/run_lasr.md)
  : MNT et MHC à 1 m depuis des dalles LiDAR HD

- [`run_tile_block()`](https://pobsteta.github.io/sylvostation/reference/run_tile_block.md)
  : Traiter un bloc de dalles LiDAR (cache par dalle, reprise après
  interruption)

- [`mosaic_tiles()`](https://pobsteta.github.io/sylvostation/reference/mosaic_tiles.md)
  : Mosaïque des rasters LiDAR, agrégée

- [`aggregate_dtm()`](https://pobsteta.github.io/sylvostation/reference/aggregate_dtm.md)
  : Agréger un MNT à des résolutions plus grossières

- [`point_lidar_metrics()`](https://pobsteta.github.io/sylvostation/reference/point_lidar_metrics.md)
  : Métriques LiDAR ponctuelles autour de points précis

## 

Terrain, hydrographie et masque forestier

- [`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
  : Variables dérivées du MNT (prédicteurs fins)

- [`real_terrain()`](https://pobsteta.github.io/sylvostation/reference/real_terrain.md)
  : Dérivés du terrain ramenés à la grille

- [`get_hydro_network()`](https://pobsteta.github.io/sylvostation/reference/get_hydro_network.md)
  : Réseau hydrographique BD TOPAGE sur une emprise

- [`height_above_network()`](https://pobsteta.github.io/sylvostation/reference/height_above_network.md)
  : Hauteur au-dessus du réseau hydrographique

- [`forest_mask()`](https://pobsteta.github.io/sylvostation/reference/forest_mask.md)
  :

  Part de couvert forestier (MHC \> `height` m) par cellule de la grille

- [`solar_factor()`](https://pobsteta.github.io/sylvostation/reference/solar_factor.md)
  :

  Facteur topographique de rayonnement mensuel (GRASS `r.sun`, ciel
  clair)

- [`lateral_balance()`](https://pobsteta.github.io/sylvostation/reference/lateral_balance.md)
  : Bilan latéral en eau (Piedallu et al. 2006, tableau 20) : carte de
  contrôle

## 

Géologie et sols

- [`read_geology()`](https://pobsteta.github.io/sylvostation/reference/read_geology.md)
  : Lire la BD Charm-50 (formations géologiques) de plusieurs sources
- [`read_lithology_rules()`](https://pobsteta.github.io/sylvostation/reference/read_lithology_rules.md)
  : Lire les règles de recodage lithologique
- [`recode_lithology()`](https://pobsteta.github.io/sylvostation/reference/recode_lithology.md)
  : Recoder les formations en classes lithologiques
- [`dominant_lithology()`](https://pobsteta.github.io/sylvostation/reference/dominant_lithology.md)
  : Lithologie dominante dans un disque
- [`list_formations()`](https://pobsteta.github.io/sylvostation/reference/list_formations.md)
  : Lister les formations géologiques d'une couche
- [`check_geol_joins()`](https://pobsteta.github.io/sylvostation/reference/check_geol_joins.md)
  : Contrôler les raccords entre feuilles et départements
- [`geology_coverage()`](https://pobsteta.github.io/sylvostation/reference/geology_coverage.md)
  : Part de l'emprise non couverte par la géologie (départements BD
  Charm-50)
- [`rasterize_geol()`](https://pobsteta.github.io/sylvostation/reference/rasterize_geol.md)
  : Rasteriser une couche géologique sur la grille commune
- [`formation_encoded_layer()`](https://pobsteta.github.io/sylvostation/reference/formation_encoded_layer.md)
  : Couche numérique de la formation dominante encodée, calculée à
  maille de 100 m
- [`lithology_encoded_layer()`](https://pobsteta.github.io/sylvostation/reference/lithology_encoded_layer.md)
  : Couche numérique de la lithologie encodée, pour la carte
- [`lithology_at_points()`](https://pobsteta.github.io/sylvostation/reference/lithology_at_points.md)
  : Lithologie dominante dans un disque autour de points (placettes IFN)
- [`read_lithology_notations()`](https://pobsteta.github.io/sylvostation/reference/read_lithology_notations.md)
  : Lire la table notation -\> classe de la mission 040
- [`read_texture_dictionary()`](https://pobsteta.github.io/sylvostation/reference/read_texture_dictionary.md)
  : Lire le dictionnaire IFN des codes de texture
- [`texture_to_psd()`](https://pobsteta.github.io/sylvostation/reference/texture_to_psd.md)
  : Granulométrie représentative d'un code de texture IFN
- [`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md)
  : Réserve utile par la texture IFN : euptf2, contre-vérifiée par
  Bruand et al. (2004)
- [`ru_coefficients()`](https://pobsteta.github.io/sylvostation/reference/ru_coefficients.md)
  : Coefficients de réserve en eau par classe de texture IFN
- [`stack_soil_layers()`](https://pobsteta.github.io/sylvostation/reference/stack_soil_layers.md)
  : Empiler les couches de sols sur la grille du projet
- [`fetch_soilgrids_ph()`](https://pobsteta.github.io/sylvostation/reference/fetch_soilgrids_ph.md)
  : Lire le pH SoilGrids sur une emprise et le mettre en cache
  (Lambert-93, 250 m)
- [`fetch_soilgrids_texture()`](https://pobsteta.github.io/sylvostation/reference/fetch_soilgrids_texture.md)
  : Lire argile, sable, limon et cailloux de SoilGrids sur une emprise
  (Lambert-93, 250 m)
- [`soilgrids_cu()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_cu.md)
  : Capacité en eau par horizon tirée des textures SoilGrids (euptf2)
- [`ru_soilgrids()`](https://pobsteta.github.io/sylvostation/reference/ru_soilgrids.md)
  : Réserve utile SoilGrids jusqu'à une profondeur (diagnostic)
- [`ru_soilgrids_diagnostic()`](https://pobsteta.github.io/sylvostation/reference/ru_soilgrids_diagnostic.md)
  : Écart de la RU SoilGrids à la RU des placettes IFN (diagnostic)
- [`ru_learned_data()`](https://pobsteta.github.io/sylvostation/reference/ru_learned_data.md)
  : Données d'apprentissage de la RU apprise (placettes IFN)
- [`ru_fill_by_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_fill_by_cell.md)
  : Compléter une RU de carte par la RU de la maille SAFRAN
- [`raster_at_points()`](https://pobsteta.github.io/sylvostation/reference/raster_at_points.md)
  : Valeur d'une couche à maille large aux placettes (règle des 700 m)
- [`layers_at_points()`](https://pobsteta.github.io/sylvostation/reference/layers_at_points.md)
  : Valeurs de plusieurs couches à maille large aux placettes (règle des
  700 m)
- [`coarse_disk_mean()`](https://pobsteta.github.io/sylvostation/reference/coarse_disk_mean.md)
  : Moyenne dans un disque de 700 m (couche à maille large)
- [`coarse_cu_layers()`](https://pobsteta.github.io/sylvostation/reference/coarse_cu_layers.md)
  : Capacités SoilGrids moyennées dans 700 m (couches à maille large)
- [`soilgrids_disk_mean()`](https://pobsteta.github.io/sylvostation/reference/soilgrids_disk_mean.md)
  : pH SoilGrids moyenné dans un disque de 700 m (couche à maille large)

## 

Placettes IFN, relevés et flore

- [`fetch_ifn()`](https://pobsteta.github.io/sylvostation/reference/fetch_ifn.md)
  : Télécharger et décompresser l'archive des données brutes IFN

- [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md)
  : Lire les placettes IFN

- [`filter_greco()`](https://pobsteta.github.io/sylvostation/reference/filter_greco.md)
  : Garder les placettes IFN d'une GRECO

- [`filter_releves()`](https://pobsteta.github.io/sylvostation/reference/filter_releves.md)
  : Filtrer les relevés floristiques IFN

- [`ifn_flora_matrix()`](https://pobsteta.github.io/sylvostation/reference/ifn_flora_matrix.md)
  : Matrice de présence de la flore IFN (placettes x espèces)

- [`ifn_trees()`](https://pobsteta.github.io/sylvostation/reference/ifn_trees.md)
  :

  Arbres IFN au format de
  [`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)

- [`read_tree_cd_ref()`](https://pobsteta.github.io/sylvostation/reference/read_tree_cd_ref.md)
  :

  Codes `CD_REF` des essences arborées de l'IFN

- [`ifn_observables()`](https://pobsteta.github.io/sylvostation/reference/ifn_observables.md)
  : Observables de terrain des placettes IFN, pour la clé

- [`read_taxref()`](https://pobsteta.github.io/sylvostation/reference/read_taxref.md)
  : Lire la table TAXREF (colonnes utiles)

- [`unmatched_taxa()`](https://pobsteta.github.io/sylvostation/reference/unmatched_taxa.md)
  : Taxons de la flore IFN sans valeur indicatrice

- [`read_tichy()`](https://pobsteta.github.io/sylvostation/reference/read_tichy.md)
  : Lire la table de valeurs indicatrices de Tichý et al. (2023)

- [`load_indicator_values()`](https://pobsteta.github.io/sylvostation/reference/load_indicator_values.md)
  : Valeurs indicatrices (pH, azote, humidité) jointes à TAXREF

- [`indicator_match_rate()`](https://pobsteta.github.io/sylvostation/reference/indicator_match_rate.md)
  : Taux d'appariement des espèces d'une flore avec les valeurs
  indicatrices

- [`indicator_species()`](https://pobsteta.github.io/sylvostation/reference/indicator_species.md)
  : Espèces indicatrices par type (IndVal)

## 

Climat et gradients

- [`fetch_safran()`](https://pobsteta.github.io/sylvostation/reference/fetch_safran.md)
  : Télécharger SAFRAN (SIM2 quotidien) et garder les mailles d'une
  emprise
- [`read_safran()`](https://pobsteta.github.io/sylvostation/reference/read_safran.md)
  : Lire des fichiers SAFRAN (SIM2 quotidien)
- [`safran_climate()`](https://pobsteta.github.io/sylvostation/reference/safran_climate.md)
  : Climat kilométrique à partir de SAFRAN
- [`ru_by_safran_cell()`](https://pobsteta.github.io/sylvostation/reference/ru_by_safran_cell.md)
  : Réserve utile uniforme par maille SAFRAN (médiane des placettes IFN)
- [`hydric_stress()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress.md)
  : Gradient hydrique : indice de contrainte hydrique BILJOU sur climat
  SAFRAN
- [`hydric_stress_grid()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress_grid.md)
  : Carte de l'indice de contrainte hydrique à la maille de sortie :
  BILJOU modulé par le rayonnement
- [`write_hydric_grid()`](https://pobsteta.github.io/sylvostation/reference/write_hydric_grid.md)
  : Écrire les couches de la carte hydrique
- [`bioclim_axis()`](https://pobsteta.github.io/sylvostation/reference/bioclim_axis.md)
  : Axe bioclimatique des placettes
- [`apply_bioclim()`](https://pobsteta.github.io/sylvostation/reference/apply_bioclim.md)
  : Appliquer l'axe bioclimatique à un tableau ou à un raster
- [`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md)
  : Calculer les gradients écologiques par placette
- [`ifn_real_gradients()`](https://pobsteta.github.io/sylvostation/reference/ifn_real_gradients.md)
  : Gradients réels des placettes IFN (trophique, hydrique,
  bioclimatique)
- [`compare_gradients()`](https://pobsteta.github.io/sylvostation/reference/compare_gradients.md)
  : Comparer nos gradients à ceux de la référence (protocole § 9, étape
  1)
- [`comparison_res()`](https://pobsteta.github.io/sylvostation/reference/comparison_res.md)
  : Maille de comparaison à la référence
- [`safran_cell_altitude()`](https://pobsteta.github.io/sylvostation/reference/safran_cell_altitude.md)
  : Altitude moyenne des mailles SAFRAN
- [`safran_lapse_rate()`](https://pobsteta.github.io/sylvostation/reference/safran_lapse_rate.md)
  : Gradient altitudinal de la température entre les mailles SAFRAN
- [`safran_weights()`](https://pobsteta.github.io/sylvostation/reference/safran_weights.md)
  : Poids d'interpolation bilinéaire entre les centres des mailles
  SAFRAN
- [`t_corrected()`](https://pobsteta.github.io/sylvostation/reference/t_corrected.md)
  : Température corrigée du relief sur un MNT
- [`t_correction_validation()`](https://pobsteta.github.io/sylvostation/reference/t_correction_validation.md)
  : Validation croisée de la correction de température (une maille
  laissée de côté)
- [`coarse_t_corr_layer()`](https://pobsteta.github.io/sylvostation/reference/coarse_t_corr_layer.md)
  : Température corrigée moyennée dans 700 m (couche à maille large,
  apprentissage)
- [`model_climate_vars()`](https://pobsteta.github.io/sylvostation/reference/model_climate_vars.md)
  : Variables climatiques des modèles régionaux
- [`write_layers()`](https://pobsteta.github.io/sylvostation/reference/write_layers.md)
  : Écrire les couches de la mission 039 (température corrigée, RU de
  carte, bilan latéral)

## 

Points d’ancrage (GBIF, GNSS)

- [`get_gbif()`](https://pobsteta.github.io/sylvostation/reference/get_gbif.md)
  : Obtenir les occurrences GBIF de plantes vasculaires d'une emprise
- [`IFN_GBIF_DATASET_KEYS`](https://pobsteta.github.io/sylvostation/reference/IFN_GBIF_DATASET_KEYS.md)
  : Jeu GBIF des relevés de l'inventaire forestier national
- [`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
  : Nettoyer des occurrences GBIF et les reprojeter en Lambert-93
- [`gbif_anchors()`](https://pobsteta.github.io/sylvostation/reference/gbif_anchors.md)
  : Points d'ancrage GBIF : mailles de bioindication et prédicteurs
- [`PLANTNET_GBIF_DATASET_KEYS`](https://pobsteta.github.io/sylvostation/reference/PLANTNET_GBIF_DATASET_KEYS.md)
  : Jeux GBIF Pl@ntNet (identification par algorithme)
- [`grid_bioindication()`](https://pobsteta.github.io/sylvostation/reference/grid_bioindication.md)
  : Regrouper des occurrences en mailles et calculer les valeurs
  bioindiquées
- [`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md)
  : Lire des relevés GNSS propres
- [`gnss_field_gradients()`](https://pobsteta.github.io/sylvostation/reference/gnss_field_gradients.md)
  : Types de terrain des relevés GNSS

## 

Modèles, validation croisée et incertitude

- [`coarse_predictors()`](https://pobsteta.github.io/sylvostation/reference/coarse_predictors.md)
  : Prédicteurs à maille large sur la grille

- [`aggregate_to_km()`](https://pobsteta.github.io/sylvostation/reference/aggregate_to_km.md)
  : Agréger un raster à la maille kilométrique

- [`fit_gradient()`](https://pobsteta.github.io/sylvostation/reference/fit_gradient.md)
  : Ajuster le modèle d'un gradient (forêt aléatoire ou GAM)

- [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  : Validation croisée spatiale par blocs

- [`predict_raster()`](https://pobsteta.github.io/sylvostation/reference/predict_raster.md)
  : Prédire un gradient sur un raster, avec incertitude et zone
  d'applicabilité

- [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)
  : Encodage d'une variable catégorielle par la moyenne de la réponse
  (rétrécie)

- [`apply_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/apply_target_encoding.md)
  :

  Appliquer un encodage de
  [`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)

- [`encode_by_blocks()`](https://pobsteta.github.io/sylvostation/reference/encode_by_blocks.md)
  : Ajouter à un tableau d'apprentissage une variable encodée hors pli
  (blocs spatiaux)

- [`oof_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/oof_target_encoding.md)
  : Encodage hors pli (sans fuite) pour l'apprentissage

- [`local_trophic_vars()`](https://pobsteta.github.io/sylvostation/reference/local_trophic_vars.md)
  : Variables du modèle trophique local : les mêmes variables larges que
  le régional, plus des fines

- [`compare_local_regional()`](https://pobsteta.github.io/sylvostation/reference/compare_local_regional.md)
  : Comparer le modèle trophique local (ancrages GBIF) au modèle
  régional (IFN)

- [`select_trophic_map()`](https://pobsteta.github.io/sylvostation/reference/select_trophic_map.md)
  : Choisir la carte trophique publiée : régionale, ou locale si elle a
  gagné

## 

Typologie, caractérisation et clé

- [`default_thresholds()`](https://pobsteta.github.io/sylvostation/reference/default_thresholds.md)
  : Seuils provisoires de discrétisation des gradients

- [`discretise()`](https://pobsteta.github.io/sylvostation/reference/discretise.md)
  : Discrétiser les gradients en classes et former les types

- [`merge_rare()`](https://pobsteta.github.io/sylvostation/reference/merge_rare.md)
  : Fusionner les types rares avec le type voisin le plus proche

- [`apply_merges()`](https://pobsteta.github.io/sylvostation/reference/apply_merges.md)
  :

  Appliquer les fusions de
  [`merge_rare()`](https://pobsteta.github.io/sylvostation/reference/merge_rare.md)
  à un vecteur de types

- [`type_raster()`](https://pobsteta.github.io/sylvostation/reference/type_raster.md)
  : Raster des types à partir des types de cellules

- [`real_type_legend()`](https://pobsteta.github.io/sylvostation/reference/real_type_legend.md)
  : Légende des types du mode réel

- [`cluster_check()`](https://pobsteta.github.io/sylvostation/reference/cluster_check.md)
  : Contrôle de la typologie par classification non supervisée (PAM)

- [`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)
  : Fertilité observée par essence et par type

- [`real_fertility()`](https://pobsteta.github.io/sylvostation/reference/real_fertility.md)
  : Fertilité par type, ou table vide si aucun arbre n'a d'âge

- [`build_key()`](https://pobsteta.github.io/sylvostation/reference/build_key.md)
  : Clé de détermination terrain (arbre de décision CART)

## 

Validation, état de preuve et sorties

- [`validate_maps()`](https://pobsteta.github.io/sylvostation/reference/validate_maps.md)
  : Accord thématique entre types prédits et types de terrain
- [`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md)
  : R² et RMSE par gradient, comparés aux repères publiés
- [`load_reference()`](https://pobsteta.github.io/sylvostation/reference/load_reference.md)
  : Lire une carte de référence
- [`recode_3digits()`](https://pobsteta.github.io/sylvostation/reference/recode_3digits.md)
  : Recoder des gradients en code à trois chiffres de la référence
- [`evidence_table()`](https://pobsteta.github.io/sylvostation/reference/evidence_table.md)
  : Tableau « état de preuve » du pipeline démo
- [`evidence_table_real()`](https://pobsteta.github.io/sylvostation/reference/evidence_table_real.md)
  : Tableau « état de preuve » du mode réel
- [`real_sources()`](https://pobsteta.github.io/sylvostation/reference/real_sources.md)
  : Sources du mode réel (fichiers locaux ou téléchargement)
- [`empty_layers()`](https://pobsteta.github.io/sylvostation/reference/empty_layers.md)
  : Couches entièrement vides d'un raster
- [`write_outputs()`](https://pobsteta.github.io/sylvostation/reference/write_outputs.md)
  : Écrire les sorties du catalogue
- [`write_types_gpkg_real()`](https://pobsteta.github.io/sylvostation/reference/write_types_gpkg_real.md)
  : Réunir la table des types à la couche des polygones du GeoPackage
- [`validation_table()`](https://pobsteta.github.io/sylvostation/reference/validation_table.md)
  : Table de validation du pipeline : chiffre principal, sensibilité à
  blocs fixes, local
- [`calibration_counts()`](https://pobsteta.github.io/sylvostation/reference/calibration_counts.md)
  : Effectifs de la calibration : où se perdent les placettes

## 

Plan d’échantillonnage et fiches de terrain

Plan de relevés terrain (cellules homogènes, accessibilité, temps de
terrain) et lecture des fiches.

- [`sampling_frame()`](https://pobsteta.github.io/sylvostation/reference/sampling_frame.md)
  : Base de sondage du plan d'échantillonnage
- [`homogeneous_cells()`](https://pobsteta.github.io/sylvostation/reference/homogeneous_cells.md)
  : Cellules à voisinage 3 × 3 homogène
- [`get_access_network()`](https://pobsteta.github.io/sylvostation/reference/get_access_network.md)
  : Tronçons de route de la BD TOPO sur une emprise
- [`ACCESS_NATURES`](https://pobsteta.github.io/sylvostation/reference/ACCESS_NATURES.md)
  : Natures de tronçons BD TOPO retenues comme accès
- [`filter_access()`](https://pobsteta.github.io/sylvostation/reference/filter_access.md)
  : Tronçons accessibles et accès restreint
- [`access_cost()`](https://pobsteta.github.io/sylvostation/reference/access_cost.md)
  : Coût d'accès : distance au tronçon accessible le plus proche
- [`field_time()`](https://pobsteta.github.io/sylvostation/reference/field_time.md)
  : Durée de terrain estimée
- [`sampling_plan()`](https://pobsteta.github.io/sylvostation/reference/sampling_plan.md)
  : Plan d'échantillonnage des relevés floristiques GNSS
- [`sampling_coverage()`](https://pobsteta.github.io/sylvostation/reference/sampling_coverage.md)
  : Diagnostic de couverture du plan
- [`write_sampling_plan()`](https://pobsteta.github.io/sylvostation/reference/write_sampling_plan.md)
  : Écrire le plan d'échantillonnage
- [`read_field_sheet()`](https://pobsteta.github.io/sylvostation/reference/read_field_sheet.md)
  : Lire et valider la saisie de la flore
- [`read_station_sheet()`](https://pobsteta.github.io/sylvostation/reference/read_station_sheet.md)
  : Lire et valider la saisie des stations
- [`BRAUN_BLANQUET`](https://pobsteta.github.io/sylvostation/reference/BRAUN_BLANQUET.md)
  : Échelle de recouvrement de Braun-Blanquet
- [`HUMUS_FORMS`](https://pobsteta.github.io/sylvostation/reference/HUMUS_FORMS.md)
  : Grandes formes d'humus admises dans le gabarit de station

## 

Contrôle par essence (BD Forêt, ESPAR)

Contrôle du trophique prédit contre les essences en place, et modèle de
sensibilité.

- [`fetch_bdforet()`](https://pobsteta.github.io/sylvostation/reference/fetch_bdforet.md)
  : Télécharger la BD Forêt v2 (formation végétale) sur une emprise
- [`bdforet_class_means()`](https://pobsteta.github.io/sylvostation/reference/bdforet_class_means.md)
  : Moyennes du trophique de la carte par classe de peuplement pur (BD
  Forêt)
- [`read_espar_codes()`](https://pobsteta.github.io/sylvostation/reference/read_espar_codes.md)
  : Dictionnaire des codes ESPAR de l'IFN
- [`read_espar_cdref()`](https://pobsteta.github.io/sylvostation/reference/read_espar_cdref.md)
  : Table essence ESPAR -\> CD_REF de l'IFN
- [`espar_group_tfv()`](https://pobsteta.github.io/sylvostation/reference/espar_group_tfv.md)
  : Groupe de la nomenclature BD Forêt d'une essence IFN
- [`dominant_species()`](https://pobsteta.github.io/sylvostation/reference/dominant_species.md)
  : Essence dominante des placettes (surface terrière pondérée par W)
- [`species_optima()`](https://pobsteta.github.io/sylvostation/reference/species_optima.md)
  : Optimum trophique de Tichý des essences (repère indicatif)
- [`trophic_without_trees()`](https://pobsteta.github.io/sylvostation/reference/trophic_without_trees.md)
  : Trophique observé sans les arbres
- [`essence_control()`](https://pobsteta.github.io/sylvostation/reference/essence_control.md)
  : Contrôle : trophique prédit hors pli contre essences en place
- [`essence_sensitivity()`](https://pobsteta.github.io/sylvostation/reference/essence_sensitivity.md)
  : Modèle de sensibilité : le trophique avec l'essence dominante
- [`essence_tables()`](https://pobsteta.github.io/sylvostation/reference/essence_tables.md)
  : Tables publiables du contrôle par essence et de la sensibilité

## 

Comparaison à CarHab

Comparaison des gradients prédits aux paramètres ordinaux de CarHab (WFS
Géoplateforme).

- [`carhab_levels()`](https://pobsteta.github.io/sylvostation/reference/carhab_levels.md)
  : Modalites ordinales CarHab (provisoires)
- [`carhab_wfs_url()`](https://pobsteta.github.io/sylvostation/reference/carhab_wfs_url.md)
  : URL d'une page de la requête WFS CarHab (Géoplateforme)
- [`carhab_fetch()`](https://pobsteta.github.io/sylvostation/reference/carhab_fetch.md)
  : Lire les polygones CarHab de l'emprise (WFS paginé, avec cache)
- [`carhab_recode()`](https://pobsteta.github.io/sylvostation/reference/carhab_recode.md)
  : Recoder une modalité CarHab en rang ordinal
- [`carhab_rasterize()`](https://pobsteta.github.io/sylvostation/reference/carhab_rasterize.md)
  : Rasteriser un champ CarHab sur notre grille (centre de cellule)
- [`carhab_quantile_classes()`](https://pobsteta.github.io/sylvostation/reference/carhab_quantile_classes.md)
  : Classes de notre gradient aux mêmes proportions que CarHab
- [`carhab_kappa()`](https://pobsteta.github.io/sylvostation/reference/carhab_kappa.md)
  : Kappa pondéré de deux classements ordinaux, accord à une classe
  près, matrice
- [`carhab_spearman()`](https://pobsteta.github.io/sylvostation/reference/carhab_spearman.md)
  : Spearman avec intervalle tenant compte de l'autocorrélation spatiale
- [`carhab_compare()`](https://pobsteta.github.io/sylvostation/reference/carhab_compare.md)
  : Comparer un gradient à un paramètre CarHab sur le domaine commun

## Mode démonstration (données synthétiques)

Jeux d’essai fabriqués (préfixe synth\_, synthetic = TRUE) : ne valent
rien sur données réelles.

- [`synth_demo_biotic()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_biotic.md)
  : Flore et arbres synthétiques par type (mode démo)
- [`synth_demo_climat()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_climat.md)
  : Climat synthétique à maille de 1 km pour le mode démo
- [`synth_demo_dtm()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_dtm.md)
  : MNT synthétique du mode démo
- [`synth_demo_points()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_points.md)
  : Points synthétiques (ancrage ou relevés « GNSS ») du mode démo
- [`synth_demo_reference()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_reference.md)
  : Carte de référence synthétique (trois gradients à 50 m)
- [`synth_demo_truth()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_truth.md)
  : Gradients « vrais » synthétiques du mode démo
- [`demo_predictors()`](https://pobsteta.github.io/sylvostation/reference/demo_predictors.md)
  : Pile de prédicteurs du mode démo
