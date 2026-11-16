# sylvostation — spécification

> Rédigée par l'orchestrateur à partir de `docs/brief.md` et de
> [`docs/brief-technique.md`](brief-technique.md) (source unique du contenu métier :
> étapes, données, critères). Cette spec n'en recopie pas le détail ; elle dit **comment on
> le découpe et comment on saura que c'est juste**. Validée par délégation le 2026-11-16.

## Parcours

1. L'utilisateur choisit une SER (`ser_code`, ex. `D11`) et, pour la phase 0, une emprise
   test dans `config.yml`.
2. `targets::tar_make()` enchaîne les étapes 1 à 10 du brief technique (§ 4).
3. Il obtient dans `data/sorties/<ser_code>/` les rasters, la table des types, les fiches
   et le rapport Quarto.
4. Sur le terrain, le forestier se sert de la clé (`build_key()`) et de la carte.

## Fonctions (une par tâche ; noms du brief technique, § 6)

| Fichier | Fonctions | Étape |
|---|---|---|
| `R/config.R` | `read_config()` | — |
| `R/utils.R` | `assert_no_fine_extract_on_ifn()`, `mark_ifn()`, `assert_crs_2154()` | règle bloquante, fondée aussi sur `loc_precision_m` |
| `R/emprise.R` | `get_ser()`, `build_grid()` | 1 |
| `R/geologie.R` | `list_formations()`, `recode_lithology()`, `rasterize_geol()`, `dominant_lithology()` | 1 |
| `R/lidar.R` | `list_tiles()`, `run_lasr()`, `point_lidar_metrics()` | 2, § 5 |
| `R/terrain.R` | `aggregate_dtm()`, `derive_terrain()` | 2 |
| `R/placettes.R` | `load_ifn()`, `filter_releves()`, `compute_gradients()` | 3 |
| `R/ancrage.R` | `get_gbif()`, `clean_occ()`, `grid_bioindication()`, `load_gnss()` | 4 |
| `R/sols.R` | `stack_soil_layers()` | 5 |
| `R/modeles.R` | `fit_gradient()`, `spatial_cv()`, `predict_raster()` | 5 |
| `R/typologie.R` | `discretise()`, `merge_rare()`, `cluster_check()` | 6 |
| `R/caracterisation.R` | `indicator_species()`, `fertility_by_type()` | 7 |
| `R/cle.R` | `build_key()` | 8 |
| `R/validation.R` | `validate_stats()`, `validate_maps()` | 9 |
| `R/reference.R` | `load_reference()`, `recode_3digits()`, `compare_gradients()` | 9, § 9 |
| `R/sorties.R` | `write_outputs()` | 10 |

Les fonctions qui ajoutent des noms au brief technique (`read_config`,
`assert_crs_2154`, `dominant_lithology`, `write_outputs`) sont des ajouts de
l'orchestrateur, signalés ici.

## Données manipulées

Voir `docs/brief-technique.md` § 3 ; URL, couches et colonnes vérifiées dans
`docs/referentiels.md` (mission 001). Tout ce qui n'y figure pas est « à vérifier ».

## Hors périmètre de cette session

Relevés GNSS réels, rasters de référence AgroParisTech, calcul sur une SER entière.

## Critères d'acceptation

Ceux du brief technique, § 7, plus, pour cette session :
- `R CMD check` sans erreur ; `testthat` vert sans réseau ;
- un test prouve que `assert_no_fine_extract_on_ifn()` bloque une extraction fine sur
  des placettes IFN ;
- incrément 1 (emprise, tableau d'assemblage LiDAR HD, MNT sur 4 dalles du massif test)
  exécuté **sur données réelles** et chiffré (temps, stockage), ou son blocage écrit au
  journal ;
- **contrat d'interface vérifié** (ce n'est pas une acceptation) : le pipeline `targets`
  s'exécute de bout en bout sur les jeux d'essai ;
- les critères du brief technique § 7 restent **« non atteints »** tant qu'ils n'ont pas
  tourné sur données réelles ;
- la PR et le rapport Quarto portent un tableau **« état de preuve »** : pour chaque étape,
  `réel`, `réel réduit` ou `synthétique` (objection B1 de la mission 000).

## Besoins en référentiels (mission `acquereur`)

Couche SER/GRECO et codes ; tableau d'assemblage LiDAR HD (couche WFS, champs, URL des
dalles) ; MNT LiDAR HD IGN (contrôle) ; BD Forêt V2 ; BD Charm-50 (URL, couches,
champs) ; fichiers bruts IFN (URL, colonnes de `PLACETTE`, `ECOLOGIE`, `FLORE`,
`ARBRE`) ; clé GBIF des Tracheophyta ; Baseflor (accès, licence) ; signatures `lasR`,
`lidR`, `rgbif`, `happign`, `lidarHD`.
