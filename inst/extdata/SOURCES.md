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
