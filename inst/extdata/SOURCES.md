# Sources des jeux d'essai réels de `inst/extdata`

Extraits de données **réelles** (pas de préfixe `synth_`), découpés sur l'emprise du
massif test `xmin 1007000, ymin 6790000, xmax 1022000, ymax 6805000` (EPSG:2154).
Extraits le 2026-11-16, mission 001 (voir `docs/referentiels.md`, § 5 et § 7).

## `bdcharm50_emprise_test.gpkg` (couche `s_fgeol`)

- **Source :** BRGM, BD Charm-50 (cartes géologiques vectorisées et harmonisées à
  1/50 000), couches `S_FGEOL` des départements 67, 68 et 88 :
  `https://infoterre.brgm.fr/telechargements/BDCharm50/GEO050K_HARM_067.zip`,
  `…_068.zip`, `…_088.zip` (archives du 2019-11-22), téléchargées le 2026-11-16.
- **Traitement :** lecture en WINDOWS-1252, CRS posé à EPSG:2154, `st_make_valid`,
  découpe au carré de l'emprise, `st_simplify(dTolerance = 5)`. 661 polygones. Champs :
  `dep` (département source), `CARTE`, `CODE`, `CODE_LEG`, `NOTATION`, `DESCR` (champs
  d'origine), `surf_m2` (surface découpée avant simplification ; somme 225 km²).
  `CODE` n'est pas comparable d'un département à l'autre : utiliser `NOTATION`.
- **Licence :** aucune licence nommée. Métadonnées du BRGM reprises par data.gouv.fr
  (jeu `66631d4a67b5b112fafd0f8a`) : « Aucune condition ne s'applique », « Données
  ouvertes », `noConditionsApply` ; champ licence data.gouv.fr : `notspecified`.
  Citation : « BRGM, BD Charm-50, cartes géologiques départementales à 1/50 000
  harmonisées (67, 68, 88) ».

## `ifn_placette.csv`, `ifn_ecologie.csv`, `ifn_flore.csv`, `ifn_arbre.csv`

- **Source :** IGN – Inventaire forestier national français, Données brutes, Campagnes
  annuelles 2005 et suivantes, https://inventaire-forestier.ign.fr/dataIFN/ , site
  consulté le 16/11/2026. Archive
  `https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip`
  (mise à jour du 07/10/2026).
- **Traitement :** placettes de `PLACETTE.csv` dont `XL`, `YL` tombent dans l'emprise et
  qui ont une ligne dans `ECOLOGIE.csv` (138 `IDP`) ; pour chaque `IDP`, la campagne la
  plus récente ayant une telle ligne ; les 100 premiers par campagne décroissante (99 en
  SER D11, 1 en D12). Lignes de `ECOLOGIE`, `FLORE` et
  `ARBRE` de ces couples (`CAMPAGNE`, `IDP`). Colonnes et codes d'origine, séparateur `;`,
  UTF-8 sans BOM. `ifn_arbre.csv` garde le `;` final de chaque ligne du fichier d'origine.
- **Précision :** `XL`, `YL` (Lambert-93) sont le centre de la maille kilométrique la plus
  proche, à 700 m au plus de la placette : `loc_precision_m = 700`. Interdit pour toute
  extraction de variable fine.
- **Codes :** `CD_REF` en TAXREF v13.0 ; libellés et modalités dans `metadonnees.csv` et
  `espar-cdref13.csv` de l'archive (non copiés ici).
- **Licence :** Licence Ouverte / Open Licence Etalab Version 2.0. Ces données ne doivent
  pas servir à produire des résultats statistiques d'inventaire.

## `ser_extrait.gpkg` (couche `ser`)

- **Source :** IGN – Inventaire forestier national, sylvoécorégions (SER), fichier
  `https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip` (shapefile `ser_l93.shp`,
  mise à jour 03/2011, échelle 1/200 000, EPSG:2154), téléchargé le 2026-11-16 (mission 003,
  voir `docs/referentiels.md`, § 1).
- **Traitement :** SER `D11` et `D12` seulement, polygones réunis par SER, lecture en
  WINDOWS-1252, `st_simplify(dTolerance = 300)` (**contour simplifié : ne pas s'en servir
  pour une analyse, seulement pour les tests**). Champs `codeser`, `NomSER`. 110 Ko.
  Script : `inst/scripts/extdata_mission003.R`.
- **Licence :** IGN : « téléchargeables gratuitement et […] réutilisées, y compris à des fins
  commerciales, sans licence et sans versement de redevance » (page `rubrique267` du site
  de l'inventaire forestier) ; les jeux data.gouv.fr correspondants (WMTS) portent la Licence
  Ouverte 2.0.

## `LHD_FXX_1015_6794_extrait.laz`

- **Source :** IGN, LiDAR HD, dalle `1015-6794` (mission `22LHDVosgesRF`, vol du 2022-01-13,
  classement `IGN_AUTO_V5`, édition du 2024-12-20, IGN69, Lambert-93), URL lue dans le champ
  `url_npl` de la couche `IGNF_LIDAR-HD_METADONNEE:metadata` :
  `https://data.geopf.fr/telechargement/download/LiDARHD-NUALID/NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz`,
  téléchargée le 2026-11-16.
- **Traitement :** carré de 80 m x 80 m, x de 1015500 à 1015580, y de 6793500 à 6793580
  (EPSG:2154), découpé par `lasR::reader_rectangles()` puis écrit en LAZ (`lasR::write_las()`) ;
  environ 0,3 million de points (classes 1 à 5 ; ni classe 9 ni classe 66 dans cet extrait). 1,6 Mo.
  Script : `inst/scripts/extdata_mission003.R`.
- **Licence :** Licence Ouverte / Open Licence Etalab 2.0 (LiDAR HD, IGN).

## `lithologie_regles.csv` et `lithologie_massif_test.csv` (mission 004)

- **Nature :** travail de l'équipe (pas une donnée tierce). `lithologie_regles.csv` :
  règles provisoires mots-clés (expressions régulières sur `DESCR`, sans accents) vers
  classes lithologiques, par priorité. `lithologie_massif_test.csv` : les 94 `NOTATION` de
  `bdcharm50_emprise_test.gpkg`, recodées par ces règles (`statut` = `regle` ou
  `non_classe`, `validated = FALSE` jusqu'à relecture de Pascal). Les classes ne sont pas
  une nomenclature du BRGM.

## `synth_indicateurs.csv` (SYNTHÉTIQUE)

- **Nature :** valeurs indicatrices **fabriquées** (tirage uniforme, graine 2026), colonne
  `synthetic = TRUE` ; Baseflor n'était pas joignable (docs/referentiels.md § 9). Ne
  représente aucune mesure écologique : sert uniquement à tester `compute_gradients()`.
- **Format** (séparateur `;`, décimale `.`, UTF-8) : `cd_ref` (TAXREF v13.0, comme
  `FLORE.CD_REF`), `nom` (libellé du `CD_REF` dans `metadonnees.csv` de l'IFN), `ph`,
  `azote`, `humidite` (échelle 1 à 9 fictive), `synthetic`. Les 269 `CD_REF` de
  `ifn_flore.csv` y figurent. Pour brancher Baseflor ou EcoPlant : fournir un fichier de
  mêmes colonnes `cd_ref`, `ph`, `azote` (ajouter la jointure `CD_NOM` vers `CD_REF`).
- **Licence :** sans objet (données fabriquées) ; les libellés viennent de l'IFN
  (Licence Ouverte Etalab 2.0).

## `topage_troncons_extrait.gpkg` (mission 014)

- **Source :** BD TOPAGE (Sandre/OFB), tronçons hydrographiques de Métropole, couche
  `sa:TronconHydrographique_FXX_Topage2025`, service WFS
  `https://services.sandre.eaufrance.fr/geo/topage2025` (docs/referentiels.md, § 16),
  lue le 2026-11-17 par `get_hydro_network()` sur la boîte Lambert-93
  `1014500, 6792500, 1016500, 6794500` (x = est, y = nord) autour de la dalle LiDAR 1015-6794.
- **Contenu :** 10 tronçons (8 permanents, 2 intermittents), EPSG:2154, colonnes TOPAGE
  non vides conservées ; colonnes de service GML (`gml_id`, `lowerCorner`, `upperCorner`)
  retirées. Tronçons réels, pas de donnée synthétique.
- **Licence : Licence Ouverte (Etalab), à vérifier pour le millésime 2025 (fiches 2022-2024 lues).** Les fiches Sandre 2022 (v1.0) et 2024 (v2.0) la
  donnent ; **la fiche 2025 n'a pas été lue** (référentiels § 16) : à confirmer avant toute
  republication hors de ce dépôt. Les tronçons 2025 viennent des tronçons de la BD TOPO de
  l'IGN (édition de décembre 2023).

## `tichy_2023_extrait.csv` (mission 015, RÉEL)

- **Source :** Tichý L., Axmanová I., Dengler J. et al. (2023), « Ellenberg-type indicator
  values for European vascular plant species », *Journal of Vegetation Science* 34,
  e13168. Jeu Zenodo `https://zenodo.org/records/7427088`, DOI `10.5281/zenodo.7427088`,
  version 2.0 (2022-11-07), fichier `Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx`
  (19 503 599 octets, MD5 `3519d41639647dde8d80042fc98b2ef5`), téléchargé le 2026-11-17.
- **Traitement :** feuille `Tab-IVs-Tichy-et-al2023`, **189 taxons** sur 8 908 : ceux qui
  s'apparient aux espèces de `ifn_flore.csv` (nom, binôme, agrégat « binôme aggr. » ou synonyme TAXREF). Colonnes
  d'origine `SeqID`, `Taxon`, `MOISTURE`, `REACTION`, `NUTRIENTS` ; `LIGHT`,
  `TEMPERATURE`, `SALINITY` vidées. `x` (indifférent) devient une case vide. Script :
  `inst/scripts/extraire_indicateurs.R`. Le fichier complet se télécharge à l'exécution,
  hors dépôt.
- **Licence :** CC BY 4.0 (champ `license` de l'API Zenodo). À citer : Tichý et al. (2023).
  **Partage à l'identique :** les valeurs de Julve (2015) pour la France, reprises par Tichý et al., sont
  peut-être sous CC BY-SA 2.0 (Tela Botanica) ; si c'est le cas, toute redistribution de cet extrait
  (et de ses dérivés) devrait se faire sous la même licence ; point à trancher par Pascal.
  Réserve connue : le jeu reprend les valeurs de Julve (2015) pour la France, annoncées
  CC BY-SA 2.0 par Tela Botanica (écart de licence non résolu, `docs/referentiels.md`, § 14).
- **Noms :** Euro+Med, pas TAXREF ; jointure par nom latin.

## `taxref_v18_extrait.csv` (mission 015, RÉEL)

- **Source :** MNHN/PatriNat, TAXREF v18 (2025),
  `https://assets.patrinat.fr/files/referentiel/TAXREF_v18_2025.zip` (60 582 042 octets),
  fichier `TAXREFv18.txt` (708 685 lignes), téléchargé le 2026-11-17.
- **Traitement :** 4 colonnes (`CD_NOM`, `CD_REF`, `LB_NOM`, `RANG`), 2 248 lignes : les
  269 `CD_NOM` de la flore IFN (qui est en v13.0 ; un `CD_NOM` ne change pas pour un nom
  donné), leurs `CD_REF`, leurs synonymes de rang espèce, et les lignes dont `LB_NOM` est
  dans l'extrait Tichý. Script : `inst/scripts/extraire_indicateurs.R`.
- **Licence :** Licence Ouverte (data.gouv.fr : `lov2`, `fr-lo` ; la page PatriNat ne cite
  aucune licence, écart déjà noté `docs/referentiels.md` § 15).

## `ifn_texture_dictionnaire.csv` (mission 019, RÉEL)

- **Source :** IGN – Inventaire forestier national français, Données brutes, Campagnes
  annuelles 2005 et suivantes, https://inventaire-forestier.ign.fr/dataIFN/ , site consulté le
  17/11/2026. Fichier `metadonnees.csv` de l'archive
  `https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip`
  (export du 2026-10-07, 71 136 669 octets).
- **Traitement :** modalités des unités `TEXT` (campagnes 2005-2016) et `TEXT1` (2017 et
  suivantes) du bloc « Définition des modalités pour chaque unité » (lignes 5845-5865), avec
  la période de chaque unité lue dans le bloc « Définition des unités » (lignes 376-379).
  Colonnes `unite;campagnes;code;libelle;definition`, texte d'origine (espaces insécables
  compris), 21 lignes. Voir `docs/referentiels.md`, § 22.
- **Licence :** Licence Ouverte / Open Licence Etalab Version 2.0.

## `safran_sim2_extrait.csv` (mission 019, RÉEL)

- **Source :** Météo-France, « Données changement climatique - SIM quotidienne »
  (data.gouv.fr, jeu `6569b27598256cc583c917a7`), fichiers
  `https://meteofrance.s3.sbg.io.cloud.ovh.net/data/REF_CC/SIM/QUOT_SIM2_2003.csv.gz` et
  `…_2004.csv.gz`, téléchargés le 2026-11-17. Mention obligatoire : « Source : Météo-France ».
- **Traitement :** maille `LAMBX = 9640`, `LAMBY = 23690` (Lambert II étendu en hm ; centre
  environ x = 1 014 550, y = 6 799 283 en Lambert-93, au centre de l'emprise test), du
  2003-01-01 au 2004-12-31 (731 jours), colonnes `LAMBX;LAMBY;DATE;PRENEI;PRELIQ;ETP`
  (mm). 21 Ko. Voir `docs/referentiels.md`, § 23.
- **Licence :** Licence Ouverte 2.0 (`lov2`, champ licence de data.gouv.fr).

## `safran_sim2_12mailles_extrait.csv` (missions 016 et 021, RÉEL)

- **Source :** Météo-France, « Données changement climatique - SIM quotidienne »
  (data.gouv.fr, jeu `6569b27598256cc583c917a7`), fichiers
  `https://meteofrance.s3.sbg.io.cloud.ovh.net/data/REF_CC/SIM/QUOT_SIM2_2003.csv.gz` et
  `…_2004.csv.gz`, téléchargés le 2026-11-17 (cache `data/cache/safran/`, hors dépôt).
  Mention obligatoire : « Source : Météo-France ».
- **Traitement :** les **12 mailles** qui couvrent l'emprise test (`LAMBX` 9560, 9640, 9720 ×
  `LAMBY` 23530, 23610, 23690, 23770, Lambert II étendu en hm, liste
  `data/cache/safran/cellules_emprise.txt`), du 2003-01-01 au 2004-12-31 (8 772 lignes),
  colonnes d'origine `LAMBX;LAMBY;DATE;PRENEI;PRELIQ;T;FF;SSI;HU;ETP`, sans arrondi.
  Unités : document Météo-France intitulé « Données quotidiennes SIM » (2 pages, créé le
  2026-03-31), lu dans le cache local `data/cache/safran/params.pdf` (hors dépôt) ;
  **adresse de téléchargement à vérifier** (voir `docs/referentiels.md` § 25.8) : précipitations et ETP en mm, `T` en °C (moyenne quotidienne), `FF` en m/s
  (vent moyen quotidien), `HU` en % (humidité relative moyenne), `SSI` en **J/cm²**
  (« rayonnement visible », cumul quotidien ]00UTC-00UTC]). 458 Ko.
  Mission 016 : 7 colonnes (sans `FF`, `SSI`, `HU`). Mission 021 (2026-11-18) : `FF`, `SSI`
  et `HU` ajoutées, mêmes lignes, mêmes valeurs pour les 7 colonnes d'origine (vérifié
  colonne par colonne). Commande : lecture de `emprise_2003.csv` et `emprise_2004.csv` du
  cache par `utils::read.csv2(colClasses = "character")`, sélection des 10 colonnes,
  écriture `;`. Sert au mode réel hors ligne (`offline: true`) et à la carte hydrique de
  25 m (`hydric_stress_grid()`).
- **Licence :** Licence Ouverte 2.0 (`lov2`, champ licence de data.gouv.fr).
