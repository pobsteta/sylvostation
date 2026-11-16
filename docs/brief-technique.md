# Brief technique : génération semi-automatique d'un catalogue de stations par sylvoécorégion (SER)

## Consignes pour l'agent de développement (Claude Code)

- **Livrable** : un package R nommé `sylvostation`, versionné sous git, plus un pipeline `targets` à la racine du dépôt. Structure détaillée en section 6.
- **Ordre de travail** : avancer par incréments testables, dans l'ordre du phasage (section 8). Premier incrément : emprise, tableau d'assemblage LiDAR HD et MNT sur 4 dalles d'essai. Ne pas coder les étapes 5 à 10 avant que les étapes 1 à 4 tournent sur le massif test.
- **Ne rien inventer** : URL de téléchargement, noms de couches, noms de colonnes des fichiers IGN, signatures de fonctions de `lasR`, `lidarHD` et `rgbif` sont à vérifier dans la documentation ou sur les données réelles avant usage. Les esquisses de code de ce brief sont indicatives et n'ont pas été exécutées.
- **Règle bloquante** : ne jamais extraire de variable fine (LiDAR, pente, position topographique) aux coordonnées des placettes IGN, localisées à 700 m près. Prévoir une assertion dans le code.
- **Données** : aucune donnée volumineuse dans le dépôt. Chemins et paramètres dans un fichier `config.yml` (code SER, emprise du massif test, résolution, dossiers). Dalles LiDAR traitées en flux, puis supprimées.
- **Tests** : `testthat`, avec de petits jeux d'essai dans `inst/extdata` (une dalle LiDAR réduite, une centaine de placettes, un extrait géologique). Aucun téléchargement dans les tests.
- **Conventions** : noms de fonctions en anglais et en `snake_case`, documentation `roxygen2` en français, système de coordonnées EPSG:2154 partout, une fonction par tâche, pas d'effet de bord hors des fonctions d'écriture.
- **Décisions réservées à l'utilisateur** : choix du massif test, table de recodage lithologique, seuils de discrétisation des gradients, fusion des types. Proposer une valeur par défaut, la signaler, ne pas trancher seul.
- **Points d'arrêt** : s'arrêter et demander si une source de données est inaccessible, si une licence est ambiguë, ou si un prérequis de la section 9 manque (rasters de référence AgroParisTech).
- **Compte rendu** : à chaque incrément, lister ce qui a été vérifié sur données réelles et ce qui ne l'a pas été.

## 1. Objectif

Produire, pour une SER donnée en paramètre, un catalogue de stations reproductible composé de quatre livrables :

- une **typologie** : liste de 10 à 20 types de stations définis par trois gradients (niveau trophique, alimentation en eau, bioclimat) ;
- une **carte prédictive** raster des types (10 à 25 m), limitée aux zones forestières, accompagnée d'une carte d'incertitude ;
- une **clé de détermination terrain** dérivée automatiquement, n'utilisant que des variables observables sur place (topographie, humus, texture, profondeur, plantes indicatrices) ;
- une **fiche par type** (gradients, flore indicatrice, essences observées, fertilité, surface) et un rapport de validation.

Le même code doit tourner sur n'importe laquelle des 91 SER en changeant uniquement le code de la SER (ex. `C30`, `D11`).

## 2. Principe retenu

Approche « par gradients » de Gégout et al. (2008), généralisée et complétée par l'apprentissage automatique :

- on ne classe pas directement des pixels en types ; on modélise d'abord **trois variables continues** (trophique, hydrique, bioclimat), on les spatialise, puis on les **discrétise** et on les croise pour obtenir les types ;
- les modèles de gradients sont **calibrés à l'échelle de la GRECO** (ou de la France) pour disposer d'assez de placettes, puis la **discrétisation et le regroupement en types se font par SER** ;
- le climat reste une variable explicite, ce qui permet de recalculer la carte sous scénario climatique sans refaire la typologie ;
- deux jeux de points aux rôles distincts, car les placettes de l'inventaire ne sont localisées qu'à 700 m près : les **placettes IGN** servent à établir les relations entre flore, sol et station à l'intérieur de la placette ; des **points d'ancrage bien géolocalisés** (GBIF, relevés GNSS, relevés de conservatoires botaniques) servent à relier ces gradients au relief fin du LiDAR HD.

## 3. Données d'entrée

- **Contours SER et GRECO** (IGN, inventaire forestier) : emprise et stratification.
- **Données brutes et indices écologiques de l'inventaire forestier** (IGN, DataIFN, data.gouv.fr) : fichiers `PLACETTE`, `ECOLOGIE`, `FLORE`, `HABITAT`, `ARBRE` ; environ 100 000 placettes avec relevé écologique depuis 2005. Source principale pour la flore et le sol à la placette. Coordonnées dégradées (voir encadré ci-dessous).
- **Occurrences floristiques GBIF** (package `rgbif`) : plantes vasculaires localisées à 25 m ou mieux, utilisées comme points d'ancrage. Ce sont des présences isolées, pas des relevés complets.
- **Autres relevés floristiques, selon disponibilité** : EcoPlant (AgroParisTech, sur demande), relevés géolocalisés des conservatoires botaniques nationaux (par convention), base SOPHY (localisation souvent approximative).
- **Valeurs indicatrices des espèces** : valeurs calibrées sur EcoPlant si accessibles ; à défaut Baseflor (Julve) ou Ellenberg, pour le pH, la richesse en azote et l'humidité. Harmoniser les noms d'espèces avec le référentiel TAXREF avant toute jointure.
- **Relief et hauteur de végétation** : nuages de points classés LiDAR HD (IGN, dalles LAZ de 1 km, au moins 10 impulsions/m²), traités avec `lasR` et `lidR` (voir section 5). Les MNT, MNS et MNH LiDAR HD à 50 cm déjà calculés par l'IGN servent de contrôle et de solution de repli. RGE ALTI en secours là où le LiDAR HD n'est pas encore diffusé.
- **Masque forestier** : BD Forêt V2 (IGN).
- **Géologie** : BD Charm-50 (BRGM), cartes au 1/50 000 vectorisées et harmonisées, 6 couches shapefile, téléchargement par département, licence ouverte. Les unités sont définies par l'âge : elles doivent être recodées en 8 à 15 classes lithologiques (étape 1). L'harmonisation étant départementale, contrôler les raccords aux limites de départements et de feuilles.
- **Formations superficielles** : carte du régolithe au 1/1 000 000 (BRGM, InfoTerre, couche « Géologie de la surface ») pour les grands ensembles (lœss, altérites, dépôts glaciaires). Connaissance inégale ; le relief LiDAR sert de complément.
- **Couches BRGM optionnelles, à tester** : sensibilité aux remontées de nappe (engorgement), aléa retrait-gonflement des argiles (texture). Non vérifiées : contrôler contenu, échelle et licence avant usage.
- **Climat** : normales de températures, précipitations, rayonnement et ETP (couches Digitalis/portail SILVAE d'AgroParisTech, ou à défaut données Météo-France ou CHELSA).
- **Sols, à empiler comme prédicteurs** :
- GlobalSoilMap France (INRAE Info&Sols, 90 m) : texture, pH, profondeur, éléments grossiers par couche de profondeur, et réservoir utile en mm jusqu'à 2 m, avec incertitudes ;
- référentiels régionaux pédologiques au 1/250 000 (Gis Sol) : unité de pédopaysage utilisée comme variable catégorielle ;
- cartes pH, C/N et réserve utile bioindiqués en forêt (SILVAE) ;
- BDGSF au 1/1 000 000 : trop grossière, à n'utiliser qu'en dernier recours ;
- RMQS (réseau de mesures de la qualité des sols, Gis Sol) : sites mesurés sur une grille lâche, à utiliser seulement comme contrôle régional des cartes précédentes ;
- BDAT, BDETM et BDSolU (Gis Sol) : hors sujet (terres agricoles, éléments traces, sols urbains).
- Les webservices WMS du Gis Sol renvoient des images, pas des valeurs : ils servent à la visualisation. Pour le calcul, utiliser les fichiers téléchargeables (entrepôt Recherche Data Gouv) ou les flux WFS, à inventorier dans le catalogue geodata.inrae.fr.
- Aucune de ces cartes n'est fiable à l'échelle de la station (un sondage pour 200 à 600 ha au 1/250 000 ; prédictions statistiques à 90 m ; calage probablement dominé par les sols agricoles). Elles entrent comme covariables, jamais comme vérité de terrain.
- **Hydrographie** : BD TOPAGE, pour les distances et dénivelés au réseau.
- **Facultatif** : catalogues, guides et cartes de stations existants de la SER, pour la validation et pour nommer les types.

**Contrainte confirmée : localisation des placettes IGN.** En open data, les coordonnées fournies sont celles du centre de la maille kilométrique ; la placette réelle se trouve jusqu'à 700 m de ce point. Conséquences : aucune extraction de variable fine (LiDAR, pente, position topographique) à ces coordonnées ; aucune métrique LiDAR à la placette. Seuls les prédicteurs à maille large (climat kilométrique, pédopaysage, géologie dominante) peuvent être croisés avec ces placettes. Les coordonnées précises ne s'obtiennent que par convention avec l'IGN.

## 4. Étapes de l'algorithme

### Étape 1 : préparation de l'emprise et de la géologie
- Charger le contour de la SER, ajouter un tampon de 5 à 10 km (effets de bord), reprojeter en Lambert-93 (EPSG:2154).
- Découper et aligner toutes les couches raster sur une grille commune (10 à 25 m).
- **Recodage lithologique** : extraire la liste des formations de la BD Charm-50 présentes dans l'emprise (code, notation, description) ; produire une table de correspondance `formation -> classe lithologique` pré-remplie par règles sur les mots-clés de la description (grès, granite, calcaire, marne, alluvions, etc.) ; la soumettre à l'utilisateur pour validation ; stocker la table validée dans `inst/extdata`. Signaler les formations non classées plutôt que de les affecter par défaut.
- Rasteriser la lithologie recodée et le régolithe sur la grille ; calculer aussi la lithologie dominante dans un rayon de 700 m, pour le croisement avec les placettes IGN.

### Étape 2 : variables dérivées du MNT
- MNT produit à 1 m à partir du LiDAR HD (section 5), puis agrégé à 5 m et 25 m : les indices ci-dessous se calculent sur ces versions agrégées, pas à 1 m où le microrelief (ornières, souches, fossés) domine le signal.
- Pente, exposition (transformée en cosinus/sinus), courbures.
- Indice de position topographique (TPI) à plusieurs rayons (100, 300, 1000 m).
- Indice topographique d'humidité (TWI), surface drainée, indice de fond de vallée (MRVBF), hauteur au-dessus du réseau hydrographique.
- Rayonnement solaire potentiel annuel et de saison de végétation.

### Étape 3 : gradients écologiques par placette
- **Trophique** : valeur bioindiquée par la flore (moyenne des valeurs indicatrices de pH et de richesse des espèces présentes, voir section 3) ; à défaut, premier axe d'une AFC des relevés floristiques ; contrôler avec la forme d'humus et la roche mère.
- **Hydrique** : réserve utile maximale calculée par fonctions de pédotransfert à partir de la texture, de la profondeur et de la charge en cailloux relevées par l'IFN ; ajouter un terme d'apports latéraux (position topographique) et un indicateur d'engorgement (profondeur d'apparition de l'hydromorphie).
- **Bioclimat** : bilan hydrique climatique (précipitations moins ETP) de saison de végétation et température moyenne ; second axe de l'AFC comme contrôle en montagne.
- Filtrer les relevés : flore relevée en saison, espèces présentes dans au moins 3 relevés, placettes sans perturbation majeure récente.

### Étape 4 : points d'ancrage géolocalisés
- **GBIF** : télécharger avec `occ_download()` les plantes vasculaires de l'emprise (coordonnées présentes, sans anomalie géographique, incertitude de 25 m au plus, depuis 2000). Ne pas utiliser `occ_search()`, plafonné à 100 000 enregistrements. Conserver le DOI du téléchargement.
- Écarter les relevés de l'inventaire IGN présents dans GBIF (localisation dégradée) ; privilégier les jeux de données de conservatoires botaniques, parcs et ONF ; tester à part l'apport de Pl@ntNet et iNaturalist.
- Ne garder que les points en forêt (BD Forêt et hauteur de canopée LiDAR supérieure à 5 m).
- Regrouper par maille de 50 à 100 m ; calculer les valeurs bioindiquées (trophique, humidité) dans les mailles comptant au moins 5 espèces indicatrices ; conserver le nombre d'espèces comme poids.
- **Relevés GNSS propres** : 30 à 50 points par massif test, stratifiés sur le relief et la géologie, avec relevé floristique complet et sondage à la tarière. Ils servent de jeu de validation indépendant, et de calibration si GBIF est trop pauvre.
- Mesurer d'emblée le nombre de mailles exploitables sur le massif test : c'est le critère qui décide si GBIF suffit.

### Étape 5 : modélisation spatiale, gradient par gradient
- **Bioclimat** : modèle calibré sur les placettes IGN (GRECO entière). Les prédicteurs climatiques étant kilométriques, la localisation à 700 m près est acceptable. Descente d'échelle par l'altitude et le rayonnement issus du LiDAR.
- **Trophique** : modèle en deux temps. Composante régionale calibrée sur les placettes IGN avec des prédicteurs à maille large (géologie dominante, pédopaysage, pH GlobalSoilMap agrégé à 1 km). Composante locale calibrée sur les points d'ancrage avec les prédicteurs fins (position topographique, géologie au 1/50 000, sols à 90 m).
- **Hydrique** : relation établie sur les placettes IGN entre réserve utile, engorgement et variables notées sur le terrain (pente, exposition, position topographique, texture, profondeur) ; application aux mêmes grandeurs dérivées du LiDAR ; recalage sur l'humidité bioindiquée des points d'ancrage. Le réservoir utile GlobalSoilMap entre comme covariable.
- Algorithmes : forêt aléatoire (`ranger`) et GAM (`mgcv`) en comparaison.
- **Validation croisée spatiale par blocs** (jamais de tirage aléatoire simple, qui surestime la précision), complétée par les relevés GNSS.
- Prédire sur la grille de la SER ; produire une carte d'erreur ou d'écart-type de prédiction, et une zone d'applicabilité du modèle.
- **Point fragile** : la position topographique jugée sur le terrain et celle calculée sur un MNT se recouvrent mal. Établir une table de correspondance sur les relevés GNSS avant de transférer le modèle hydrique.

### Étape 6 : construction de la typologie
- Discrétiser chaque gradient en classes à seuils écologiquement lisibles (ex. 4 à 6 niveaux trophiques, 3 à 5 niveaux hydriques, 1 à 5 bioclimats selon l'amplitude altitudinale de la SER).
- Croiser les classes ; fusionner les combinaisons rares (moins de 1 % de la surface forestière ou moins de 15 placettes) avec la combinaison voisine la plus proche.
- Variante de contrôle : classification non supervisée (PAM ou CAH sur les trois gradients), choix du nombre de groupes par silhouette, et comparaison avec la typologie par seuils.
- Traiter à part les stations azonales mal captées par les modèles : alluviales, tourbeuses, éboulis, à partir de couches dédiées (zones humides, géologie, SER alluviales).

### Étape 7 : caractérisation des types
- Espèces indicatrices par type (indice IndVal).
- Essences présentes et fertilité observée (hauteur dominante à un âge de référence ou indice équivalent tiré des données dendrométriques).
- Surface, répartition altitudinale, substrats dominants.

### Étape 8 : clé de détermination terrain
- Arbre de décision (CART) prédisant le type à partir des seules variables observables sur le terrain ; limiter la profondeur à 4 ou 5 niveaux pour rester utilisable.
- Publier le taux de bon classement de la clé par rapport à la typologie.

### Étape 9 : validation
- Statistique : R² et RMSE de chaque gradient en validation croisée spatiale. Repères tirés de la littérature : R² de 0,36 (trophique), 0,52 (bioclimat) et 0,43 (réserve utile) dans les Vosges ; 0,40 pour le niveau trophique en Wallonie ; 0,58 pour la carte nationale de pH bioindiqué.
- Thématique : concordance (kappa) avec des cartes de stations levées sur le terrain et avec les catalogues existants.
- Écologique : la fertilité des essences principales doit varier dans le sens attendu entre types. Elle se calcule sur les placettes IGN (hauteurs et âges mesurés sur le terrain), la hauteur LiDAR ne pouvant pas leur être rattachée.
- Terrain : relevés GNSS de l'étape 4 (30 à 50 points par massif test), jamais utilisés pour la calibration finale.

### Étape 10 : sorties
- Raster des types et rasters des trois gradients (GeoTIFF/COG), carte d'incertitude.
- Table des types (CSV/GeoPackage), fiches par type et rapport de validation générés automatiquement (Quarto).

## 5. LiDAR HD : MNT et hauteur des arbres avec lasR et lidR

### Répartition des rôles
- **`lasR`** pour la production sur toute la SER : il enchaîne les traitements en une seule lecture du nuage, gère les tampons entre dalles et le calcul en parallèle. C'est l'outil des traitements standards sur grande emprise (MNT, modèle de hauteur de canopée, rasters de métriques).
- **`lidR`** pour la mise au point, les contrôles visuels et les métriques à la placette (découpe de cercles, métriques de nuage), où sa souplesse compte plus que sa vitesse.

### Produits à calculer
- **MNT à 1 m** : triangulation des points classés sol (classe 2), eau (9) et points virtuels (66), comme le fait l'IGN pour son propre MNT.
- **Modèle de hauteur de canopée (MHC) à 1 m** : nuage normalisé par le MNT, puis hauteur maximale par cellule, avec comblement des trous.
- **Métriques de peuplement sur grille de 20 ou 25 m** (cohérente avec la taille d'une placette) : hauteur au 95e percentile (approximation de la hauteur dominante), hauteur moyenne, écart-type des hauteurs, taux de couvert au-dessus de 2 m, proportion de trouées.
- **Métriques ponctuelles** : mêmes indicateurs sur un cercle de 15 m de rayon autour des relevés GNSS et des mailles d'ancrage. Impossible sur les placettes IGN en open data, faute de coordonnées précises.

### Esquisse de code (à adapter)

```
library(lasR)
# Production par dalle, en un seul passage
pipeline <- reader() +
  dtm(res = 1, ofile = "mnt/*.tif") +
  chm(res = 1, ofile = "mhc/*.tif")
exec(pipeline, on = "laz/", ncores = 8, buffer = 20)

library(lidR)
# Métriques ponctuelles : relevés GNSS ou points d'ancrage, pas les placettes IGN
ctg <- readLAScatalog("laz/")
m   <- plot_metrics(ctg, .stdmetrics_z, points_gnss_sf, radius = 15)
```

```
library(rgbif)
# Compte GBIF requis ; emprise en WKT (WGS84)
dl <- occ_download(
  pred_within(ser_wkt),
  pred("taxonKey", 7707728),   # Tracheophyta, clé à confirmer avec name_backbone()
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_lte("coordinateUncertaintyInMeters", 25),
  pred_gte("year", 2000),
  format = "SIMPLE_CSV")
occ_download_wait(dl)
occ <- occ_download_import(occ_download_get(dl))
```

Ces esquisses n'ont pas été exécutées. `lasR` évolue vite : vérifier les noms de fonctions et d'arguments dans la documentation de la version installée avant de figer le code.

### Usage de la hauteur dans le catalogue
- **La hauteur seule ne mesure pas la station** : elle dépend d'abord de l'âge, de l'essence et de la sylviculture. Elle ne devient un indicateur de fertilité que rapportée à un âge (hauteur dominante à âge de référence).
- **Usage principal : validation et caractérisation des types.** Sans coordonnées précises, la hauteur LiDAR ne peut pas être reliée à l'âge mesuré sur les placettes IGN. Deux voies : relever âge et essence sur les points GNSS, ou comparer entre types de station la distribution des hauteurs des peuplements adultes fermés.
- **Usage comme prédicteur : avec prudence.** Introduire la hauteur dans le modèle de types ferait dépendre la station de l'histoire du peuplement. Une variante défendable : la hauteur maximale atteinte localement par les peuplements adultes fermés, comme indicateur de potentiel.
- **Usages annexes** : masque forestier fin, repérage des coupes et des jeunes peuplements à exclure de la validation.

### Précautions propres au LiDAR HD
- **Dates et saisons d'acquisition hétérogènes** : les vols s'étalent de 2020 à 2026 et sont majoritairement réalisés en hiver. Hors feuilles, la hauteur des feuillus est sous-estimée et le couvert mal mesuré. Conserver la date de vol par dalle, l'intégrer comme covariable, et comparer les hauteurs LiDAR aux hauteurs mesurées sur placette avant tout usage.
- **Décalage temporel** avec les relevés de terrain et les occurrences : écarter les points où une coupe est intervenue entre l'observation et le vol.
- **Volume** : traiter dalle par dalle en flux (téléchargement, calcul, suppression du nuage) et ne conserver que les rasters. Chiffrer le stockage et le temps de calcul sur un bloc test avant d'engager une SER entière.
- **Couverture** : vérifier la disponibilité sur la SER visée ; la diffusion n'est pas encore complète partout.
- **Contrôle** : comparer le MNT recalculé au MNT LiDAR HD de l'IGN sur quelques dalles ; un écart notable signale un problème de paramétrage.

## 6. Architecture logicielle (R)

- Pipeline `targets`, paramétré par le code SER ; environnement figé avec `renv`.
- LiDAR : `lidarHD` (INRAE, tableau d'assemblage et téléchargement des dalles), `lasR` (production), `lidR` (métriques ponctuelles, contrôles).
- Flore : `rgbif` (occurrences), référentiel TAXREF pour l'harmonisation des noms.
- Spatial : `sf`, `terra`, `whitebox` (ou `RSAGA`) pour les indices de terrain, `happign` pour télécharger les données IGN.
- Écologie : `vegan`, `ade4` (AFC), `indicspecies` (IndVal), `cluster` (PAM, silhouette).
- Modélisation : `ranger`, `mgcv`, `mlr3` avec `mlr3spatiotempcv` ou `blockCV`, `CAST` (zone d'applicabilité), `rpart` (clé).
- Restitution : `quarto`, `tmap`, `gt`.

### Organisation : un package R et un pipeline

Le code prend la forme d'un package R, `sylvostation`, hébergé sur GitHub, avec le pipeline `targets` à la racine du même dépôt. Le package porte les fonctions, leur documentation et leurs tests ; le pipeline les enchaîne pour une SER donnée. Cette séparation permet de réutiliser les fonctions hors du pipeline et de tester chaque brique isolément.

```
sylvostation/
  DESCRIPTION          dépendances ; lasR et lidarHD hors CRAN (champ Remotes
                       ou Additional_repositories)
  LICENSE              GPL-3 (cohérent avec lidR et lasR)
  R/
    emprise.R          get_ser(), build_grid()
    geologie.R         list_formations(), recode_lithology(), rasterize_geol()
    lidar.R            list_tiles(), run_lasr(), point_lidar_metrics()
    terrain.R          aggregate_dtm(), derive_terrain()
    placettes.R        load_ifn(), filter_releves(), compute_gradients()
    ancrage.R          get_gbif(), clean_occ(), grid_bioindication(), load_gnss()
    sols.R             stack_soil_layers()
    modeles.R          fit_gradient(), spatial_cv(), predict_raster()
    typologie.R        discretise(), merge_rare(), cluster_check()
    caracterisation.R  indicator_species(), fertility_by_type()
    cle.R              build_key()
    validation.R       validate_stats(), validate_maps()
    reference.R        load_reference(), recode_3digits(), compare_gradients()
    utils.R            assert_no_fine_extract_on_ifn()
  inst/extdata/        jeux d'essai réduits, table lithologique validée
  inst/rapport/        gabarit Quarto du rapport par SER
  tests/testthat/
  vignettes/           tutoriel sur le massif test
  _targets.R           pipeline, paramétré par config.yml
  config.yml           code SER, emprise test, résolution, dossiers
  .Rbuildignore        exclut _targets.R, config.yml, _targets/, data/
  .gitignore           exclut data/, _targets/, *.laz, *.tif
  README.md
  CLAUDE.md            rappel des consignes en tête de ce brief
```

- Intégration continue : `R CMD check` par GitHub Actions à chaque envoi.
- Gestion de l'environnement : `renv`.
- Dépôt privé tant que les questions de licence des données de référence (AgroParisTech) ne sont pas réglées ; ouverture possible ensuite.

Alternative Python équivalente : `geopandas`, `rasterio`/`xarray`, `whitebox`, `scikit-learn`, `scikit-bio`. R reste préférable pour l'analyse floristique (`vegan`, `ade4`).

## 7. Critères d'acceptation

- Le pipeline s'exécute de bout en bout sur une SER pilote à partir du seul code SER.
- Toutes les performances annoncées proviennent d'une validation croisée spatiale et d'un jeu de relevés GNSS indépendant.
- Aucune variable fine n'est extraite aux coordonnées dégradées des placettes IGN.
- Chaque type couvre au moins 1 % de la surface forestière de la SER ou est justifié comme station azonale.
- La clé terrain reclasse correctement au moins 70 % des placettes ; à défaut, les types confondus sont fusionnés.
- Le rapport liste explicitement les limites : stations marginales, zones hors domaine d'applicabilité, précision à l'échelle de la parcelle.

## 8. Phasage conseillé

- **Phase 0, bloc test** : un massif forestier de 100 à 300 km² à l'intérieur de la SER pilote, pour régler la chaîne LiDAR (paramètres, temps de calcul, stockage), compter les points d'ancrage GBIF exploitables et réaliser les relevés GNSS.
- **Phase 1, pilote** : les SER vosgiennes, avec comparaison à la carte prédictive de référence selon le protocole de la section 9.
- **Phase 2** : une SER de plaine à substrats contrastés et une SER méditerranéenne, pour éprouver la généricité.
- **Phase 3** : généralisation par GRECO, puis harmonisation des types aux limites entre SER voisines.

## 9. Protocole de test sur le massif vosgien

### Objectif
Comparer la chaîne à la carte prédictive de Gégout et al. (2008) : 8 800 km², pixels de 50 m, 59 types codés sur trois chiffres (6 classes trophiques, 5 bioclimatiques, 4 classes d'eau), version simplifiée à 12 classes. Performances publiées : R² de 0,36 (trophique), 0,52 (bioclimat) et 0,43 (réserve utile).

### Principe
La carte de référence est elle-même un modèle. Un bon accord montre que la chaîne reproduit l'existant, pas qu'elle a raison ; un désaccord peut signifier que le LiDAR fait mieux. Les deux cartes sont donc évaluées contre un arbitre indépendant : les relevés GNSS.

### Emprise
- Massif test de 100 à 300 km², couvrant tout l'étagement (du piémont aux crêtes) et les deux grands substrats (grès, roches cristallines).
- Extension ensuite aux SER vosgiennes entières (GRECO D ; codes et contours à confirmer sur la couche IGN).

### Données de référence à réunir
- Raster des 59 types et, si possible, rasters des trois gradients intermédiaires. La page SILVAE présente la carte mais ne mentionne ni téléchargement, ni licence, ni diffusion séparée des gradients : **demande à adresser à AgroParisTech Nancy** (équipe SILVAE). Sans les gradients, seules les comparaisons de types restent possibles.
- Seuils de discrétisation utilisés par les auteurs (article de la Revue forestière française).
- Catalogues de stations vosgiens et cartes de stations levées sur le terrain (ONF, CNPF), pour l'interprétation.
- LiDAR HD : les acquisitions du Nord-Est (Vosges) ont été réalisées à l'hiver 2021-2022, donc hors feuilles. Lister les dalles et leurs dates via le tableau d'assemblage (flux WFS de l'IGN, couche `IGNF_LIDAR-HD_METADONNEE:metadata`, ou package R `lidarHD` d'INRAE).

### Étapes de comparaison
- **1. Gradients** : agréger nos trois gradients à 50 m ; corrélation de rang avec ceux de la référence ; carte des écarts.
- **2. Types à codage identique** : appliquer à nos gradients les seuils et le code à trois chiffres de la référence ; matrice de confusion, kappa, accord exact et accord à une classe près par axe ; même exercice sur la version à 12 classes.
- **3. Performances de modèle** : nos R² en validation croisée spatiale face aux valeurs publiées, facteur par facteur.
- **4. Analyse des désaccords** : par position topographique (fonds de vallon, versants, crêtes), par substrat et par tranche d'altitude.
- **5. Arbitrage terrain** : 30 à 50 relevés GNSS stratifiés, dont une part volontairement placée dans les zones de désaccord ; erreur de chaque carte sur ces points.
- **6. Lecture forestière** : confrontation des types obtenus aux catalogues existants avec un forestier local.

### Critères de réussite (à ajuster)
- R² de nos modèles au moins égaux aux valeurs publiées.
- Accord à une classe près supérieur à 70 % sur le bioclimat ; seuil plus bas admis sur l'eau, gradient le plus incertain des deux côtés.
- Sur les relevés GNSS, erreur de notre carte inférieure ou égale à celle de la référence, avec un gain net dans les positions topographiques marquées.

### Limites du test
- Les Vosges ne représentent ni les plaines calcaires ni le Midi : la généricité se juge en phase 2.
- Les données de la référence sont antérieures à 2008 ; le climat de référence diffère.
- Vols d'hiver : les hauteurs de feuillus sont sous-estimées ; le test porte surtout sur le relief, peu sur la hauteur.

## 10. Risques et parades

- **Peu de placettes dans les petites SER** : calibrer à l'échelle GRECO, discrétiser à l'échelle SER.
- **Cumul des erreurs des trois modèles** : propager l'incertitude et afficher une confiance par pixel.
- **Géologie hétérogène entre feuilles et entre départements, unités définies par l'âge** : recodage lithologique validé par l'utilisateur, contrôle visuel des raccords, variable « département » testée comme facteur de nuisance.
- **Types sans réalité de terrain** : confrontation systématique aux catalogues existants et à un forestier local avant diffusion.
- **Trop peu de points d'ancrage GBIF en forêt, ou biais vers les chemins et les sites remarquables** : mesurer la densité sur le massif test ; pondérer par le nombre d'espèces ; compléter par des relevés GNSS et, si possible, par une convention avec un conservatoire botanique.
- **Cartes de sols peu représentatives des sols forestiers** : les comparer aux sols décrits sur les placettes IGN à l'échelle de la SER avant de leur donner du poids.
- **Transfert terrain vers LiDAR du gradient hydrique** : table de correspondance et validation GNSS obligatoires.
- **Usage abusif à la parcelle** : rappeler que la carte oriente le diagnostic et ne remplace pas le sondage à la tarière.

## 11. Questions à trancher avant de coder

- Dépôt GitHub public ou privé, et sous quel compte ?
- Quel massif test dans les Vosges, et quels catalogues ou cartes de stations de terrain y sont disponibles ?
- AgroParisTech peut-il fournir les rasters de la carte de référence et de ses trois gradients ?
- Une convention avec l'IGN (coordonnées précises) ou avec un conservatoire botanique (relevés géolocalisés) est-elle envisageable à terme ? Elle simplifierait fortement la chaîne.
- Capacité à réaliser 30 à 50 relevés GNSS avec flore et tarière sur le massif test ?
- Finalité principale : choix des essences, aménagement, habitats, vulnérabilité climatique ? Elle conditionne le nombre de types et les seuils.
- Résolution cible de la carte des stations (10 à 25 m) et capacité de calcul et de stockage disponible pour le LiDAR HD.
