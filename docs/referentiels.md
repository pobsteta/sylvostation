# Référentiels de données vérifiés

- **Propriétaire :** Pascal (délégué à l'orchestrateur).
- **Rédigé par :** agent `acquereur`, mission 001, le 2026-11-16.
- **Décision éclairée :** quelles URL, couches, champs et signatures les `dev` des missions
  003 à 007 peuvent écrire dans le code sans les inventer, et si l'emprise du massif test
  (`1007000 6790000 1022000 6805000`, EPSG:2154) est conservée.
- **Deux passes.** Passe 1 (agent `acquereur`, WebFetch seul) : § 2, § 3 et la couche
  du § 4 ; WebFetch résumait les pages par un petit modèle, les décomptes `numberMatched`
  sont ceux du serveur. Passe 2 (agent général briefé en acquéreur, journal 001, même
  jour) : `curl` par le proxy de la session et R 4.3.3 (`sf` 1.0.15, `terra` 1.7.65) ;
  tout le reste du document. Fichiers temporaires dans `/tmp/claude-0/acq/`, supprimés
  ensuite.
- **Hôtes joints en passe 2 :** `data.geopf.fr`, `www.data.gouv.fr`,
  `inventaire-forestier.ign.fr`, `infoterre.brgm.fr` (fichiers de
  `/telechargements/` seulement, voir § 5), `api.gbif.org`, `api.github.com`.
  **Refusés :** `geoservices.brgm.fr` (page « Request Rejected » du pare-feu du BRGM,
  code 200 et 246 octets, à chaque requête), `mapsref.brgm.fr`, `inpn.mnhn.fr`,
  `taxref.mnhn.fr` (hors des hôtes ouverts de la session).
- **Passe 3 (agent `acquereur`, mission 013, 2026-11-17).** Outils : `WebFetch` (page
  convertie puis résumée par un petit modèle : les décomptes `numberMatched` et les horodatages
  `timeStamp` sont ceux du serveur, la liste des colonnes est celle du `DescribeFeatureType`
  lu par ce résumeur) et `WebSearch`. **Pas de `curl` ni de R dans cette passe** : aucune
  signature n'a été exécutée avec `args()`, aucune archive n'a été décompressée. Les PDF
  (IGN LiDAR HD, Bruand et al. 2004) ont été enregistrés par l'outil et **lus en image page
  par page** : les chiffres des tableaux sont recopiés de ces pages. Sections : § 14 à § 21 ;
  les § 6 et § 9 renvoient vers elles.
- **Les surfaces** sont calculées avec `sf::st_area` en EPSG:2154 après
  `st_make_valid` et `st_intersection` avec le carré de l'emprise.

Légende des états : **vérifié** (URL exacte consultée le 2026-11-16, résultat noté) ;
**non vérifié** (avec la raison) ; **piste** (relevée par une recherche web, source
primaire non consultée, ne pas coder).

Racine WFS utilisée : `https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0` (abrégée
`WFS` ci-dessous).

---

## 1. SER et GRECO : vérifié

| Point | État | Source / commande | Résultat |
|---|---|---|---|
| Couche SER sur la Géoplateforme (WFS) | **vérifié : n'existe pas** | `curl -s "https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities"` (5 387 870 octets, 861 `FeatureType` lus en entier) | Aucun nom ni titre ne contient « sylvo », « greco » ni « écorégion » française. Les seules « régions écologiques » (`ecoregions:regions_ecologiques`, `pays_ecoregions:regions_ecologiques`) sont des « grandes régions naturelles mondiales » (champs `eco_name`, `biome_name`, `realm`…) : **ce ne sont pas les SER**. |
| Jeux data.gouv.fr « Sylvoécorégions » | **vérifié** | `curl -s "https://www.data.gouv.fr/api/1/datasets/?q=sylvoecoregions&page_size=20"` | Deux jeux IGN, licence `lov2` (Licence Ouverte 2.0) : `sylvoecoregions` (id `69aa19403500af2ce22aa1aa`, ressource unique : couche WMTS `LANDCOVER.SYLVOECOREGIONS`) et `sylvoecoregions-dalluvions-recentes` (id `69868293b2dbae8cd3bd68da`, WMTS `LANDCOVER.SYLVOECOREGIONS.ALLUVIUM`). **Aucun fichier vecteur sur data.gouv.fr**, seulement des tuiles d'image. |
| Source vecteur réelle | **vérifié** | `https://inventaire-forestier.ign.fr/spip.php?rubrique267` (formulaire « J'accepte ces conditions » → `spip.php?article731`), puis `curl -s -o ser_l93.zip https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip` (code 200) | **86 SER** : `https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip` (10 592 240 octets ; shapefile `ser_l93.shp/.dbf/.prj/.shx/.sbn/.sbx`, fichiers datés du 2011-03-08). **5 SER d'alluvions récentes** : `https://inventaire-forestier.ign.fr/IMG/zip/ser_ar_l93.zip` (36 315 555 octets, `ser_ar_l93.*`). Variantes Lambert II étendu `ser_l2e.zip`, `ser_ar_l2e.zip` ; métadonnées `IMG/pdf/ser-2.pdf`, `IMG/xml/sylvoecoregions.xml` (ISO 19139). |
| Version, date, échelle | **vérifié** | `IMG/pdf/ser-2.pdf` (lu avec `pdftotext`) | Création 12/2010, mise à jour **03/2011**, échelle 1/200 000, EPSG:2154 (et 27572), producteur Inventaire forestier national. Données de référence 1985 à 2002. |
| Champs | **vérifié** | `sf::st_read("ser_l93.shp", options = "ENCODING=WINDOWS-1252")` | `codeser` (code), `NomSER` (libellé). **Encodage du .dbf : WINDOWS-1252** (accents corrects avec cette option). Le `.prj` est lu « RGF93 v1 / Lambert-93 », EPSG 2154. 473 polygones, 87 valeurs de `codeser` : les 86 SER et `-1` (libellé vide). Couche alluvions : mêmes champs, 1 048 polygones, codes `L1` à `L5`. **Pas de champ GRECO** : la GRECO est la première lettre de `codeser`. |
| Libellés des GRECO | **vérifié** | `metadonnees.csv` de l'archive IFN (§ 7), lignes `GRECO;A;…` à `GRECO;K;…` | A Grand Ouest cristallin et océanique ; B Centre Nord semi-océanique ; C Grand Est semi-continental ; **D Vosges** ; E Jura ; F Sud-Ouest océanique ; G Massif central ; H Alpes ; I Pyrénées ; J Méditerranée ; K Corse. Nombre de SER par GRECO (shapefile) : A 6, B 21, C 8, D 2, E 2, F 12, G 14, H 6, I 5, J 7, K 3 (= 86). |
| Codes de la GRECO D | **vérifié** (décompte complet) | `unique(codeser)` filtré sur `^D` | **Deux SER seulement : `D11` « Massif vosgien central » et `D12` « Collines périvosgiennes et Warndt ».** Surfaces totales du shapefile : D11 5 319,0 km² ; D12 4 017,9 km². |
| Existence de `C30` | **vérifié** | idem | `C30` existe : « Plaines et dépressions argileuses du Nord-Est » (GRECO C, 13 951,6 km²). **Ce n'est pas une SER vosgienne** (exemple du brief § 1). |
| Surface de l'emprise test par SER | **vérifié** | `st_intersection(ser_l93, emprise)` puis `st_area` | **D11 : 202,633 km² (90,06 %)** ; D12 : 21,489 km² (9,55 %) ; C41 « Plaine d'Alsace » : 0,879 km² (0,39 %) ; total 225,000 km². Hors SER principale : 22,37 km² = **9,94 %** (sous le seuil de 10 %, de justesse). Couche d'alluvions récentes : `L2` « Vallées du bassin Rhin-Meuse » recoupe l'emprise sur 2,437 km² (elle se superpose aux 86 SER). |
| Licence | **vérifié** | texte de `spip.php?rubrique267` | « Les fichiers et leur documentation sont la propriété de l'IGN. Ils peuvent être téléchargés gratuitement et les données […] réutilisées, y compris à des fins commerciales, sans licence et sans versement de redevance. » Les deux jeux data.gouv.fr (WMTS) portent `lov2`. |

**Pour les dev :** `get_ser()` lit `ser_l93.zip` (URL ci-dessus, encodage WINDOWS-1252,
champ `codeser`, GRECO = `substr(codeser, 1, 1)`) ; la couche d'alluvions est une couche
à part, superposée. `ser_code` par défaut : **`D11`** (vérifié).

## 2. Tableau d'assemblage LiDAR HD : vérifié

| Point | État | Commande (URL après `WFS`) | Résultat |
|---|---|---|---|
| Nom de couche | **vérifié** | `&REQUEST=DescribeFeatureType&TYPENAMES=IGNF_LIDAR-HD_METADONNEE:metadata` | `IGNF_LIDAR-HD_METADONNEE:metadata` existe. Le nom du brief est confirmé. |
| Champs | **vérifié** (même requête) | idem | `capteur` (string), `url_mnh`, `url_mns`, `url_mnt`, `url_npl` (string), `code_mission` (string), `date_edition` (date), `nombre_points` (long), `coordonnees_nw` (string), `moa_acquisition`, `moe_acquisition`, `procede_classement`, `date_fin_acquisition` (date), `systeme_altimetrique`, `moe_classement_manuel`, `systeme_planimetrique`, `date_debut_acquisition` (date), `moe_classement_automatique`, `geom`. **Aucun champ « nom de dalle » distinct** : l'identifiant de la dalle est `coordonnees_nw`. |
| URL du nuage LAZ | **vérifié** | `&REQUEST=GetFeature&TYPENAMES=IGNF_LIDAR-HD_METADONNEE:metadata&SRSNAME=EPSG:2154&BBOX=1007000,6790000,1022000,6805000,EPSG:2154&OUTPUTFORMAT=application/json&COUNT=3` | Champ `url_npl`. Exemple, dalle `1007-6793` : `https://data.geopf.fr/telechargement/download/LiDARHD-NUALID/NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1007_6793_PTS_LAMB93_IGN69.copc.laz`. Format COPC LAZ. **Lire l'URL dans `url_npl`, ne pas la reconstruire** : le chemin contient la date d'édition. |
| Sens de `coordonnees_nw` | **vérifié** | même requête : premier sommet de la dalle `1015-6790` = (1014999.99, 6790000.00) ; emprise x 1015000–1016000, y 6789000–6790000 | `coordonnees_nw` = « x_min en km – y_max en km » (coin nord-ouest). La dalle `XXXX-YYYY` couvre x ∈ [XXXX, XXXX+1] km et y ∈ [YYYY−1, YYYY] km. |
| **Le filtre BBOX déborde** | **vérifié** | `RESULTTYPE=hits`, BBOX exacte → `numberMatched="289"`. BBOX rentrée de 1 m → 285. BBOX rentrée de 100 m → 280. | Le BBOX du WFS renvoie aussi des dalles voisines, hors de l'emprise. **Filtrer avec `CQL_FILTER=WITHIN(…)` ou recouper localement dans `sf`.** |
| Dalles dans l'emprise test | **vérifié** | `&REQUEST=GetFeature&TYPENAMES=IGNF_LIDAR-HD_METADONNEE:metadata&RESULTTYPE=hits&SRSNAME=EPSG:2154&CQL_FILTER=WITHIN(geom,SRID=2154;POLYGON((1006990 6789990,1022010 6789990,1022010 6805010,1006990 6805010,1006990 6789990)))` | `numberMatched="225"` : 15 × 15 dalles, couverture complète. La liste triée (`PROPERTYNAME=coordonnees_nw,…&SORTBY=coordonnees_nw`, 285 lignes) montre x_NW de 1007 à 1021 et y_NW de 6791 à 6805, sans trou. |
| Mission, édition | **vérifié** | même filtre `WITHIN` `AND code_mission<>'22LHDVosgesRF'` → 0 ; `AND date_edition<>'2024-12-20'` → 0 | Les 225 dalles relèvent de la mission `22LHDVosgesRF`, édition du 2024-12-20, classement `IGN_AUTO_V5`, IGN69, LAMB93. |
| Dates d'acquisition | **vérifié** (décomptes) | même filtre `WITHIN`, plus : `date_fin_acquisition>'2022-02-01'` → 154 ; `date_debut_acquisition>'2022-02-01'` → 116 ; `(date_debut_acquisition<'2022-01-12' OR date_fin_acquisition>'2022-04-21')` → 0 | Toutes les dates vont du 2022-01-12 au 2022-04-21. **116** dalles volées entièrement en avril (le 2022-04-21 d'après la liste). **71** volées entièrement en janvier (12 ou 13). **38** à cheval entre janvier et avril (116 + 71 + 38 = 225). Toutes sont hors feuilles ou en début de débourrement : garder la date comme covariable (brief § 5). |
| Taille d'une dalle | **vérifié** (passe 2, voir § 13) | `curl -sI <url_npl>` | `1007-6793` : 227 690 995 octets pour 37 644 004 points ; 225 dalles : 45 735 823 198 octets. |

## 3. MNT, MNS, MNH LiDAR HD à 50 cm (contrôle) : vérifié

| Point | État | Source | Résultat |
|---|---|---|---|
| Service et couche du MNT | **vérifié** (URL lue dans le champ `url_mnt` du tableau d'assemblage ; aucun GeoTIFF téléchargé) | requête `COUNT=3` du § 2 | WMS-R `https://data.geopf.fr/wms-r`, couche `IGNF_LIDAR-HD_MNT_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93`, `FORMAT=image/geotiff`, `CRS=EPSG:2154`, 2000 × 2000 px pour 1 km (50 cm). Nom de fichier, par exemple `LHD_FXX_1007_6793_MNT_O_0M50_LAMB93_IGN69.tif`. La BBOX de l'URL est décalée d'un quart de pixel (`1006999.75,6792000.25,…`). |
| MNS, MNH | **vérifié** (même source) | idem | `IGNF_LIDAR-HD_MNS_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93`, `IGNF_LIDAR-HD_MNH_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93` (champs `url_mns`, `url_mnh`). |

## 4. BD Forêt V2 : vérifié

| Point | État | Commande | Résultat |
|---|---|---|---|
| Couche et champs | **vérifié** | `WFS&REQUEST=DescribeFeatureType&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale` | `id`, `code_tfv`, `tfv`, `tfv_g11`, `essence` (string), `geom` (MultiSurface). Type de formation végétale : `code_tfv` (code) et `tfv` (libellé). `tfv_g11` est un regroupement en 11 postes. |
| Contenu dans l'emprise | **vérifié** | `WFS&REQUEST=GetFeature&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale&SRSNAME=EPSG:2154&BBOX=1007000,6790000,1022000,6805000,EPSG:2154&OUTPUTFORMAT=application/json&COUNT=5` | `numberMatched` = 1073 polygones (BBOX, qui peut déborder comme au § 2). Valeurs vues : `FF0` « Forêt fermée sans couvert arboré » ; `FF2-00-00` « Forêt fermée à mélange de conifères » ; `FF1-00` « Forêt fermée de feuillus purs en îlots » ; `LA4` « Lande » (essence `NC`). **La couche contient des landes** : le masque forestier doit filtrer sur `code_tfv`. La liste complète, lue en passe 2, est donnée plus bas. |
| Liste complète des `code_tfv` et surfaces dans l'emprise | **vérifié** (décompte complet, pas d'échantillon) | `curl -s "https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale&SRSNAME=EPSG:2154&BBOX=1007000,6790000,1022000,6805000,EPSG:2154&OUTPUTFORMAT=application/json&COUNT=5000"` → `numberMatched` = `numberReturned` = 1073 ; découpe `sf` au carré exact : 1 072 polygones | Voir le tableau ci-dessous (21 codes). |
| Part de forêt dans l'emprise | **vérifié** | même fichier, `st_intersection` + `st_area` | Codes commençant par `F` (`FF*`, `FO*`, `FP`) : **165,744 km² = 73,66 % de l'emprise** (dont peupleraie `FP` 0,019 km²). Landes et formations herbacées (`LA4`, `LA6`) : 1,492 km². Somme de toutes les classes 167,236 km², surface de leur union 165,796 km² : **1,44 km² de recouvrements entre polygones** (cause non recherchée). Forêt par SER : **D11 164,315 km²**, D12 1,429 km², C41 0. Seuls **0,86 %** de la forêt de l'emprise sont hors D11. |
| Encodage | **vérifié** | même fichier | Le libellé `tfv` contient le caractère `\u0092` à la place de l'apostrophe (« Forêt fermée d\u0092un autre conifère pur… ») : apostrophe Windows-1252 mal transcodée par le service. Ne pas joindre sur `tfv`, joindre sur `code_tfv`. |

`code_tfv` présents dans l'emprise test (surface après découpe, km² ; % des 225 km² ;
nombre de morceaux de polygones) :

| `code_tfv` | `tfv` | `tfv_g11` | km² | % | n |
|---|---|---|---|---|---|
| FF2G61-61 | Forêt fermée de sapin ou épicéa | Forêt fermée conifères | 45,156 | 20,07 | 157 |
| FF32 | Forêt fermée à mélange de conifères prépondérants et feuillus | Forêt fermée mixte | 28,624 | 12,72 | 162 |
| FF31 | Forêt fermée à mélange de feuillus prépondérants et conifères | Forêt fermée mixte | 24,846 | 11,04 | 158 |
| FF1-00-00 | Forêt fermée à mélange de feuillus | Forêt fermée feuillus | 18,275 | 8,12 | 136 |
| FF2-00-00 | Forêt fermée à mélange de conifères | Forêt fermée conifères | 15,985 | 7,10 | 62 |
| FF2-52-52 | Forêt fermée de pin sylvestre pur | Forêt fermée conifères | 7,950 | 3,53 | 58 |
| FF0 | Forêt fermée sans couvert arboré | Forêt fermée sans couvert arboré | 5,235 | 2,33 | 71 |
| FF2-90-90 | Forêt fermée d'un autre conifère pur autre que pin | Forêt fermée conifères | 4,186 | 1,86 | 31 |
| FF1-09-09 | Forêt fermée de hêtre pur | Forêt fermée feuillus | 4,123 | 1,83 | 25 |
| FF1G01-01 | Forêt fermée de chênes décidus purs | Forêt fermée feuillus | 4,084 | 1,81 | 21 |
| FF2-64-64 | Forêt fermée de douglas pur | Forêt fermée conifères | 3,443 | 1,53 | 40 |
| FF1-49-49 | Forêt fermée d'un autre feuillu pur | Forêt fermée feuillus | 2,214 | 0,98 | 9 |
| LA4 | Lande | Lande | 1,029 | 0,46 | 39 |
| FF1-00 | Forêt fermée de feuillus purs en îlots | Forêt fermée feuillus | 0,573 | 0,25 | 67 |
| FF1-10-10 | Forêt fermée de châtaignier pur | Forêt fermée feuillus | 0,533 | 0,24 | 6 |
| LA6 | Formation herbacée | Formation herbacée | 0,463 | 0,21 | 15 |
| FO1 | Forêt ouverte de feuillus purs | Forêt ouverte feuillus | 0,171 | 0,08 | 6 |
| FF2-63-63 | Forêt fermée de mélèze pur | Forêt fermée conifères | 0,152 | 0,07 | 3 |
| FO3 | Forêt ouverte à mélange de feuillus et conifères | Forêt ouverte mixte | 0,107 | 0,05 | 2 |
| FO2 | Forêt ouverte de conifères purs | Forêt ouverte conifères | 0,068 | 0,03 | 3 |
| FP | Peupleraie | Peupleraie | 0,019 | 0,01 | 1 |

(L'apostrophe est rétablie dans ce tableau ; le service renvoie `\u0092`.)

**Pour les dev :** masque forestier = `code_tfv` commençant par `FF` ou `FO` (exclure
`LA4`, `LA6` ; décision à prendre pour `FP` et `FF0`). Relire la version de la couche
(non lue : seul le nom `…FORESTINVENTORY.V2` l'indique) ; jeu data.gouv.fr « BD Forêt® »
(id `61489da4b77d1697d00d2feb`), licence `lov2`, modifié le 2024-12-09.

## 5. BD Charm-50 (BRGM) : vérifié

| Point | État | Commande / URL | Résultat |
|---|---|---|---|
| URL par département | **vérifié** pour 67, 68, 88 | `curl -sI https://infoterre.brgm.fr/telechargements/BDCharm50/GEO050K_HARM_068.zip` (et `_067`, `_088`) | Motif : `https://infoterre.brgm.fr/telechargements/BDCharm50/GEO050K_HARM_0DD.zip` (DD = département sur 3 chiffres). Tailles : **068 : 14 559 588 octets** (Last-Modified 2019-11-22) ; 067 : 15 704 631 ; 088 : 36 808 583. Tous trois téléchargés (code 200). |
| État du site InfoTerre | **vérifié** | `curl -s https://infoterre.brgm.fr/` | Page « Site fermé par mesure de sécurité » depuis le **21 octobre 2026** (demande de l'ANSSI, PHP 7) ; bêta du nouveau site annoncée « fin décembre 2026 ». **Les fichiers de `/telechargements/BDCharm50/` répondent encore**, mais la page de formulaire citée par data.gouv.fr (`/formulaire/telechargement-cartes-geologiques-departementales-150-000-bd-charm-50`) répond **404** et le répertoire `/telechargements/BDCharm50/` répond 403. L'URL peut changer avec la refonte. Copies régionales (DataGrandEst, hôte non ouvert, non testées) : jeux data.gouv.fr `fr-236700019-geo050k-harm-068-cigal-9` et `…-067-cigal-7`. |
| Couches (archive 068) | **vérifié** | `unzip -l GEO050K_HARM_068.zip` | Six couches shapefile en EPSG:2154 (suffixe `_2154`), avec `.lyr` et `.qml` de symbologie : `S_FGEOL` (polygones des formations, 7 722 objets), `S_SURCH` (surcharges, polygones, 1 096), `L_FGEOL` (contours, lignes, 22 647), `L_STRUCT` (lignes structurales, 3 890), `L_DIVERS` (lignes diverses, 1 412), `P_STRUCT` (points structuraux, 1 276), `P_DIVERS` (points divers, 2 221). Plus le PDF « Descriptif des cartes géologiques à 1_50 000 vecteur » (BRGM/RP-53473-FR, 2004). |
| Champs de `S_FGEOL` | **vérifié** | `sf::st_read(…, options = "ENCODING=WINDOWS-1252")` | `MI_PRINX, CARTE, CODE, CODE_LEG, NOTATION, DESCR, C_FOND, M_FOND, J_FOND, N_FOND, NOM_SYMB, C_SYMB, M_SYMB, J_SYMB, N_SYMB, ROT_SYMB`. Selon le PDF descriptif : `CARTE` = numéro de la feuille à 1/50 000 ; `CODE` = entier identifiant le caisson de légende ; `NOTATION` = notation stratigraphique, **à afficher avec la police TrueType `BRGM_NOT`** (les caractères `ã`, `æ`, `í`… y codent des lettres grecques) ; `DESCR` = description courte. Mêmes champs dans 067 et 088. Encodage du .dbf : WINDOWS-1252. Le `.prj` (« RGF93_Lambert_93 », ESRI) **n'est pas reconnu comme EPSG:2154 par `sf`** (`st_crs()$epsg` = NA) : poser `st_set_crs(x, 2154)`. |
| `CODE` non comparable entre départements | **vérifié** | tableau croisé `dep × CODE × NOTATION` | La même formation porte des `CODE` différents selon le département : `t1-2V` « Grès vosgien indifférencié » = 131 (68) et 155 (67) ; `Smæsill` = 232 (68) et 226 (67) ; `h3-4pã3` = 188 (68) et 218 (67). Les `DESCR` de `r2bK` diffèrent aussi d'une virgule et d'une parenthèse. **Joindre par `NOTATION` (et vérifier `DESCR`), jamais par `CODE`, quand on assemble plusieurs départements.** |
| Départements de l'emprise test | **vérifié** | `st_intersection(S_FGEOL, emprise)` pour 067, 068, 088 | 068 : 636 polygones, **219,302 km²** ; 067 : 23 polygones, 3,931 km² ; 088 : 2 polygones, 1,768 km² ; total 225,000 km². **Il faut trois départements** pour couvrir l'emprise. |
| Formations de l'emprise | **vérifié** (liste complète dans `inst/extdata/bdcharm50_emprise_test.gpkg`) | agrégation par `dep, CODE, NOTATION, DESCR` | **102** couples (département, `CODE`), **94** `NOTATION` distinctes. Plus grandes : `Smæsill` gneiss à sillimanite (27,16 km²), `h2ã3sc` granite du Bilstein (24,70), `h3M2Ka` granite migmatitique de Kaysersberg (21,45), `h3-4pã3` granite de Thannenkirch (19,70), `t1-2V` Grès vosgien (12,97 + 0,08 dans le 67). |
| Grès **et** roches cristallines | **vérifié : les deux présents, dans D11** | classement de l'agent (règle ci-contre), croisé avec les SER | Classement : grès du Buntsandstein = `NOTATION` commençant par `t1`, `t2` ou `r-t1` (`t1-2V`, `t1A`, `t1-2P`, `t2-3`, `r-t1A`) ; cristallin et métamorphique = `DESCR` contenant granit-, gneiss, migmat-, leptyn-, amphibol-, granul-, durbach-, péridot-, cipolin, lamproph-, kinzigit-, diatexit-, rhyolit-, granophyr-, microgranit-. Résultat (km²) : **D11 : cristallin 170,10, grès 18,37, autre 14,16** ; D12 : cristallin 0,004, grès 0,18, autre 21,31 ; C41 : autre 0,88. Ce classement par mots-clés est celui de l'agent, pas une nomenclature du BRGM ; l'« autre » réunit alluvions, éboulis, conglomérats tertiaires, Muschelkalk, Keuper, Lias… |
| Licence | **vérifié, sans nom de licence** | `curl -s https://www.data.gouv.fr/api/1/datasets/66631d4a67b5b112fafd0f8a/` (jeu BRGM « Cartes géologiques vectorisées et harmonisées à 1/50 000 du BRGM ») | Champ `license` : **`notspecified`**. Métadonnées DCAT moissonnées du BRGM : `license` = `…/ConditionsApplyingToAccessAndUse/noConditionsApply`, `accessRights` = `noLimitations`, `rights` = « Limite d'utilisation liée à l'échelle », « Aucune condition ne s'applique », « Données ouvertes ». **La Licence Ouverte Etalab n'est pas nommée.** Le PDF descriptif porte « © BRGM, 2004, ce document ne peut être reproduit […] sans l'autorisation expresse du BRGM » (le document, pas les données). |
| Extrait déposé | **fait** | script R de l'agent (découpe, `st_simplify(dTolerance = 5)`) | `inst/extdata/bdcharm50_emprise_test.gpkg`, couche `s_fgeol`, 661 polygones, 565 248 octets, EPSG:2154, champs `dep, CARTE, CODE, CODE_LEG, NOTATION, DESCR, surf_m2` (`surf_m2` avant simplification ; somme 225 km²). Déposé sur la foi de « Aucune condition ne s'applique / Données ouvertes » ; **à retirer si l'orchestrateur exige une licence nommée.** Source dans `inst/extdata/SOURCES.md`. |

## 6. Régolithe 1/1 000 000 (BRGM) : vérifié en passe 3 (voir § 19)

(Les lignes ci-dessous sont celles de la passe 2, le 2026-11-16 ; la ligne « Service
joignable » est **levée** par le § 19, relu le 2026-11-17.)

| Point | État | Commande | Résultat |
|---|---|---|---|
| Jeux et couches | **vérifié** (catalogue) | `curl -s "https://www.data.gouv.fr/api/1/datasets/?q=regolithe&page_size=10"` | Deux jeux BRGM : « Etat des lieux de la connaissance du régolithe **allochtone** au millionième » (id `66631d4a67b5b112fafd0f8b`, couche WMS `REGOLITHES_ALLOCH_S_1M`) et « … **autochtone** au millionième » (id `66631d4b67b5b112fafd0f8d`, couche WMS `REGOLITHES_AUTOCH_S_1M`, modifié le 2026-08-26). Service annoncé : `https://mapsref.brgm.fr/wxs/infoterre/regolithe?SERVICE=WMS&REQUEST=GetCapabilities`. |
| Service joignable, couches réelles, champs, WFS | **non vérifié le 2026-11-16 ; levé le 2026-11-17 (§ 19)** | `curl` sur `mapsref.brgm.fr` → aucune réponse (code 000, hôte hors des hôtes ouverts) ; `https://geoservices.brgm.fr/geologie?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities` (et WFS) → page « Request Rejected » du pare-feu BRGM | Ni GetCapabilities, ni champs, ni existence d'un WFS lus. À relancer avec `mapsref.brgm.fr` ouvert. |
| Licence | **vérifié, sans nom de licence** | API data.gouv.fr des deux jeux | `license` = `notspecified` ; `rights` : « Limite d'utilisation liée à l'échelle » (allochtone), « Aucune limite d'utilisation mise a part l'échelle d'utilisation… » (autochtone). |

## 7. Données brutes IFN : vérifié

| Point | État | Commande / URL | Résultat |
|---|---|---|---|
| URL réelle | **vérifié** | `https://inventaire-forestier.ign.fr/spip.php?rubrique159` → redirection 302 vers `https://inventaire-forestier.ign.fr/dataifn/?lang=fr` | Toutes campagnes : `https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip` (**71 136 669 octets**, Last-Modified 2026-10-07) ; dernière campagne : `…/export_dataifn_2025.zip` (9 661 766) ; documentation seule : `…/export_dataifn_doc_2025.zip` (6 207 768). Page : « Date de dernière mise à jour des données brutes : 07/10/2026 ». **Le nom du fichier change à chaque campagne** (`2005_2025`) : lire le lien sur la page, ne pas le figer. |
| Format, contenu | **vérifié** | `unzip -l export_dataifn_2005_2025.zip` | CSV séparés par `;`, UTF-8 **avec BOM**, une virgule de fin de ligne (`;` final, dernière colonne vide). Fichiers : `PLACETTE.csv` (27 005 130 octets), `ECOLOGIE.csv` (13 633 200), `FLORE.csv` (66 352 232), `ARBRE.csv` (231 974 014), `BOIS_MORT.csv`, `COUVERT.csv`, `HABITAT.csv`, `espar-cdref13.csv`, `metadonnees.csv`, `precision-donnees_2020-2024.csv` (encodé WINDOWS-1252, décimales à virgule), `recapitulatif_donnees.csv`, 9 PDF `IGN_DB_doc_*.pdf`. Décompressé : 379 013 174 octets. |
| Volumes | **vérifié** (décompte complet) | `read.csv2` dans R | `PLACETTE` 229 696 lignes, 134 230 `IDP` distincts, campagnes 2005 à 2025 ; `ECOLOGIE` 131 704 ; `FLORE` 2 875 858 ; `ARBRE` 2 517 332. GRECO D : 9 392 lignes de `PLACETTE` (D11 6 475, D12 2 917) ; département 68 : 2 254 ; 88 : 4 829. |
| Colonnes `PLACETTE` | **vérifié** | `head -1 PLACETTE.csv` | `CAMPAGNE;IDP;XL;YL;DATEPOINT;VISITE;RAD13;DEP;GRECO;SER;PBUIS;DPYR;ANPYR;NINCID;INCID;DIST;ACCES;ITI;ASPERITE;PENTEXP;PORTN;PORTANCE;ORNIERE;GEST;ELAG;PRELEV5;DEF5;DCESPAR1;DCESPAR2;INSTP5;TPESPAR1;TPESPAR2;TPLANT;BPLANT;IPLANT;VIDEPLANT;ENTP;VIDEPEUPLIER;TCAT10;CSA;BOIS;PEUPNR;UTA1;UTA2;UTIP;AUTUT;PLISI;CSLISI;ELISI;NLISI5;ANDAIN;BORD;INTEGR;TM2;TFORM;SVER;SFO;CAM;DC` |
| Colonnes `ECOLOGIE` | **vérifié** | `head -1 ECOLOGIE.csv` | `CAMPAGNE;IDP;TOPO;OBSTOPO;EXPO;MSUD;MASQUE;PENT2;OBSCHEMIN;HUMUS;OLN;OLT;OFR;OLV;OH;TSOL;PROF1;PROF2;OBSPROF;TEXT1;TEXT2;OBSPEDO;ROCHE;OBSROC;AFFROC;CAI40;CAILLOUX;TYPCAI;AFPLA;PGLEY;POX;PPSEUDO;OBSHYDR;PCALC;PCALF;OBSRIV;OBSRIV2;TYPRIV;DISTRIV;DENIVRIV;LIGN1;LIGN2;HERB;MOUSSE;OBSVEGET;DATEECO;OBSDATE` |
| Colonnes `FLORE` | **vérifié** | `head -1 FLORE.csv` | `CAMPAGNE;IDP;CD_REF;ABOND;INCO_FLOR`. Clé de jointure : (`CAMPAGNE`, `IDP`). |
| Colonnes `ARBRE` | **vérifié** | `unzip -p … ARBRE.csv \| head -1` | `CAMPAGNE;IDP;A;ESPAR;VEGET;VEGET5;DATEMORT;ORI;TIGE;FORME;TETARD;Q1;Q2;Q3;QUALITE;CIBLE;LIB;AGE13;AGE;SIMPLIF;ACCI;CLON;C13;MES_C13;C0;HTOT;HDEC;DDEC;DECOUPE;LFSD;V;W;R;HRB;IR5;IR1;MORTB;MA;MR;SFCOEUR;SFDORGE;SFGELIV;SFGUI;SFPIED;DEGGIB` |
| Codes espèces de `FLORE`, TAXREF | **vérifié** | `IGN_DB_doc_flore.pdf` (version 2.0) ; `metadonnees.csv` | `CD_REF` = « identifiant unique de taxon de référence […] codé selon le référentiel **TAXREF v13.0** » (MNHN). Le libellé de chaque `CD_REF` est dans `metadonnees.csv`, lignes `CDREF13;<cd_ref>;<nom>;<nom avec auteur>` (**3 659** taxons). `espar-cdref13.csv` (colonnes `espar;lib_espar;cd_ref;lib_cdref`) relie les codes d'essence `ESPAR` d'`ARBRE` aux `CD_REF` (ex. `61;Sapin pectiné;79319;Abies alba`). **La flore IFN est en TAXREF v13, pas en version courante** : une mise à jour de version est à prévoir avant jointure avec d'autres sources. Flore relevée seulement sur les points de première visite (`VISITE` = 1). |
| Dictionnaire des modalités | **vérifié** | `metadonnees.csv` | Trois blocs : libellés des colonnes (`donnee;libelle;definition`), unités et périodes de validité (ex. `HUMUS` → `HUMUS` 2005–2021 puis `HUMUS22` 2022– ; `ROCHE` → `ROCHED0` 2005–2024 puis `ROCHED2` 2025– ; `ESPAR` → `ESPAR`, `ESPAR0`, `ESPAR1` selon les années), puis modalités (`GRECO;D;Vosges;…`, `SER;D11;Massif vosgien central;…`, 86 SER). **Les codes d'une même colonne changent de nomenclature selon la campagne** : joindre les libellés avec la période. |
| Système de coordonnées | **vérifié** | `metadonnees.csv` (`GEOM93;Géométrie (en projection Lambert 93)`) ; plages de `XL` (126 637 à 1 238 943) et `YL` (6 050 791 à 7 109 696) ; `IGN_DB_documentation_generale.pdf` | `XL`, `YL` en **Lambert-93 (EPSG:2154)**, en mètres. « Les coordonnées XY des points ne correspondent pas aux coordonnées réelles mais au centre de la maille kilométrique de la grille d'échantillonnage la plus proche du point (distance maximum d'environ 700 m) » : `loc_precision_m = 700` confirmé. |
| Placettes dans l'emprise test | **vérifié** | filtre `XL ∈ [1007000, 1022000]`, `YL ∈ [6790000, 6805000]` | 245 lignes, **138 IDP** distincts (D11 : 137 lignes en 1re visite et 106 en 2e ; D12 : 1 et 1), de 5 à 16 par campagne de 2005 à 2025. |
| Licence | **vérifié** | page `dataifn/` et en-tête de `metadonnees.csv` | **Licence Ouverte / Open Licence Etalab Version 2.0.** Citation obligatoire : « IGN – Inventaire forestier national français, Données brutes, Campagnes annuelles 2005 et suivantes, https://inventaire-forestier.ign.fr/dataIFN/ , site consulté le JJ/MM/AAAA ». Interdiction d'en tirer des résultats statistiques d'inventaire (poids des placettes non diffusé). Le jeu data.gouv.fr « Données brutes de l'inventaire forestier » (id `5369931ba3a729239d2040cc`) porte `fr-lo` (Licence Ouverte 1.0) : écart de version. |
| Extrait déposé | **fait** | script R de l'agent | `inst/extdata/ifn_placette.csv` (100 placettes : les 100 premiers `IDP` de l'emprise test ayant une ligne `ECOLOGIE`, campagne la plus récente de chaque `IDP`, triées par campagne décroissante ; 99 en D11, 1 en D12), `ifn_ecologie.csv` (100 lignes), `ifn_flore.csv` (2 238 lignes, 269 `CD_REF`), `ifn_arbre.csv` (1 550 lignes). Format d'origine (`;`), BOM retiré. Total 238 406 octets. |

## 8. GBIF : vérifié

Emprise test en WGS84 (les quatre coins reprojetés par `sf::st_transform`, sens
anti-horaire) : `POLYGON ((7.1290454 48.13811, 7.3303954 48.130883, 7.3414755 48.265649,
7.1396122 48.272893, 7.1290454 48.13811))`. Les côtés sont des droites en degrés, pas en
Lambert-93 : écart de l'ordre du mètre sur 15 km (non mesuré). Requête de base
(`<WKT>` encodé) :
`https://api.gbif.org/v1/occurrence/search?limit=0&geometry=<WKT>&taxonKey=7707728&hasCoordinate=true&hasGeospatialIssue=false&year=2000,2026`.

| Point | État | Commande (ajout à la requête de base) | Résultat |
|---|---|---|---|
| Clé de Tracheophyta (ancien référentiel) | **vérifié** | `curl -s 'https://api.gbif.org/v1/species/match?name=Tracheophyta'` | `usageKey` **7707728**, PHYLUM, ACCEPTED, EXACT, confidence 94 (GBIF Backbone Taxonomy, `d7dddbf4-2cf0-4f39-9b2a-bb099caae36c`). |
| Clé dans le référentiel par défaut de `rgbif` 3.9.0 | **vérifié** | `rgbif::name_backbone("Tracheophyta")` ; `curl -s "https://api.gbif.org/v2/species/match?scientificName=Tracheophyta&checklistKey=7ddf754f-d193-4cc9-b351-99906754a03b"` | `usageKey` **`TP`** (chaîne). `rgbif` 3.9.0 a pour `checklistKey` par défaut `7ddf754f-d193-4cc9-b351-99906754a03b` = « Catalogue of Life ». **Piège :** avec l'API brute, `taxonKey=7707728&checklistKey=7ddf754f-…` renvoie **0** ; `taxonKey=TP&checklistKey=7ddf754f-…` renvoie 18 538. Via `rgbif::occ_search(limit = 0)`, `taxonKey = 7707728`, `taxonKey = "TP"` et `7707728` + `checklistKey = "d7dddbf4-…"` renvoient tous 18 538. Le comportement de `occ_download` avec 7707728 n'est **pas vérifié** (compte GBIF requis). |
| Total plantes vasculaires, depuis 2000 | **vérifié** | (aucun) | **18 538** (`occurrenceStatus=ABSENT` → 0 ; `PRESENT` → 18 538). |
| Incertitude ≤ 25 m | **vérifié** | `&coordinateUncertaintyInMeters=0,25` | **4 440** |
| Incertitude renseignée | **vérifié** | `&coordinateUncertaintyInMeters=*,*` | 15 606 ; dont > 25 m (`25.001,*`) 11 166 (4 440 + 11 166 = 15 606). |
| Incertitude absente | **vérifié par différence** | `&isNull=coordinateUncertaintyInMeters` est **ignoré** par l'API de recherche (renvoie 18 538) | 18 538 − 15 606 = **2 932**. Dans l'API de téléchargement, `rgbif::pred_isnull("coordinateUncertaintyInMeters")` existe (signature ci-dessous), non exécuté. |
| Jeu IFN dans GBIF | **vérifié** | `&facet=datasetKey&facetLimit=1000` puis `https://api.gbif.org/v1/dataset/<clé>` | `datasetKey` **`e5f16d86-e225-4822-97be-a64ce17079c7`**, « Données de l'inventaire forestier national de l'IGN-Relevés floristiques du protocole de l'Inventaire National Forestier de l'IGN », CC BY 4.0. Dans l'emprise depuis 2000 : **2 150** (11,6 % du total). |
| **Incertitude déclarée du jeu IFN** | **vérifié — piège** | `&datasetKey=e5f16d86-…&coordinateUncertaintyInMeters=0,25` puis lecture de 300 occurrences | **1 800 des 2 150 occurrences IFN déclarent `coordinateUncertaintyInMeters` = 1,0 m**, alors que l'IFN publie des coordonnées à 700 m près (§ 7) ; les 350 autres n'ont pas d'incertitude. Par période : 2000–2004 : 57 ; 2005–2010 : 633 (633 à ≤ 25 m) ; 2011–2015 : 761 (761) ; 2016–2020 : 525 (349) ; 2021–2026 : 174 (0). `dataGeneralizations` et `informationWithheld` vides sur l'échantillon lu. **1 800 des 4 440 occurrences « ≤ 25 m » (40,5 %) sont des placettes IFN à 700 m.** Le filtre sur l'incertitude ne suffit pas : **exclure aussi `datasetKey = e5f16d86-e225-4822-97be-a64ce17079c7`** (ou le marquer `mark_ifn()`). |
| `dataGeneralizations`, `informationWithheld` (tous jeux) | **non vérifié en entier** | 300 premières occurrences de la requête de base | 0 sur 300. Ce n'est qu'un échantillon ; non filtrable dans l'API de recherche. |
| Jeux et licences | **vérifié** (liste complète : 30 jeux, somme 18 538) | `&facet=datasetKey&facetLimit=1000`, puis `https://api.gbif.org/v1/dataset/<clé>` pour chacun | Voir le tableau ci-dessous. **CC BY-NC 4.0 : 4 jeux, 2 588 occurrences** (Carnet en Ligne 1 029, iNaturalist 844, Observation.org 714, Cartographie des Leguminosae 1) ; les 26 autres sont CC BY 4.0. |

Jeux GBIF de l'emprise test (Tracheophyta, 2000–2026), `datasetKey`, nombre, licence :

| datasetKey | n | Licence | Titre (tronqué) |
|---|---|---|---|
| 72b6bac4-3a93-491b-a931-cbd07bff5b39 | 7 416 | CC BY 4.0 | Inventaire de la flore d'Alsace - Données de la flore d'Alsace (SBA) |
| 14d5676a-2c54-4f94-9023-1e8dcd822aa0 | 2 591 | CC BY 4.0 | Pl@ntNet automatically identified occurrences |
| e5f16d86-e225-4822-97be-a64ce17079c7 | 2 150 | CC BY 4.0 | Données de l'inventaire forestier national de l'IGN (IFN) |
| 69580c67-e820-423f-a75b-20e0489107e3 | 2 085 | CC BY 4.0 | R44_CBAL_BD_Alsace_2012-2022 |
| baa86fb2-7346-4507-a34f-44e4c1bd0d57 | 1 029 | CC BY-NC 4.0 | Carnet en Ligne |
| 50c9509d-22c7-4a22-a47d-8c48425ef4a7 | 844 | CC BY-NC 4.0 | iNaturalist Research-grade Observations |
| 8a863029-f435-446a-821e-275f4f641165 | 714 | CC BY-NC 4.0 | Observation.org, Nature data from around the World |
| 7a3679ef-5582-4aaa-81f0-8c2545cafc81 | 547 | CC BY 4.0 | Pl@ntNet observations |
| 7d2dc1b9-aee3-4097-953b-f755a41132f4 | 386 | CC BY 4.0 | CardObs : Observations naturalistes (Pasc…) |
| 43027054-3812-4599-b7bc-a01f1df5b071 | 192 | CC BY 4.0 | Données ONF faune-flore-fonge |
| 017f23ba-bf04-4eb7-a076-04ab2e5de250 | 182 | CC BY 4.0 | ONF - Observations et inventaires MOA ONF |
| 6ac3f774-d9fb-4796-b3e9-92bf6c81c084 | 120 | CC BY 4.0 | NABU\|naturgucker |
| c0dd99c3-fa06-499c-949e-aa44d42f2f16 | 80 | CC BY 4.0 | Inventaire des Messicoles (FCBN) |
| f946666e-67dc-4848-9fa8-2162f3559e33 | 61 | CC BY 4.0 | Données d'occurrences Espèces issues de l'inventaire des ZNIEFF |
| 662a5899-42ba-4ca3-b075-c51d45516ba1 | 49 | CC BY 4.0 | Données Vigie-Flore |
| 7247dc2e-b862-4555-b533-7701d183271b | 14 | CC BY 4.0 | INPN Espèces |
| 87f62455-777c-4562-a2ca-9cde09292507 | 14 | CC BY 4.0 | CardObs (Jean…) |
| f97eeccc-8409-4075-ab7c-8980f73c0d0d | 13 | CC BY 4.0 | Atlas des plantes vasculaires de Lorraine |
| fe99edff-54d8-43b9-a25d-57964403efa6 | 11 | CC BY 4.0 | Observatoire de la Biodiversité des Jardins |
| aa79690b-018a-44b0-8ed4-2704ba530ade | 9 | CC BY 4.0 | CardObs |
| 0eb4ad83-f80d-4d86-83d8-f3a55ddd216f | 5 | CC BY 4.0 | CardObs (Xavi…) |
| 41e8840e-57eb-40d4-a1ac-cfda408bc871 | 5 | CC BY 4.0 | Livre rouge de la flore menacée de France (FCBN) |
| d921f444-3029-4ff9-876f-4bd412b1d3e4 | 5 | CC BY 4.0 | CardObs (Ségo…) |
| 6f7c417f-74df-4b7d-bce5-35a9ee9bc2a6 | 4 | CC BY 4.0 | CardObs (Phil…) |
| 966426ce-f762-11e1-a439-00145eb45e9a | 4 | CC BY 4.0 | Herbarium Senckenbergianum (FR) |
| 7c411d81-3534-4cc3-8444-885e82ccdfa3 | 3 | CC BY 4.0 | Inventaire de la flore d'Alsace - Herbiers de l'Université de Strasbourg |
| e553568e-2317-4592-8638-92e5ac93b40c | 2 | CC BY 4.0 | Herbarium specimens of Jardins botaniques and Conservatoire Botanique of Nancy |
| 2700f1e5-0f50-4f53-8810-67bb54852aae | 1 | CC BY 4.0 | Anciennes données CBNBP |
| 92204c07-5011-47ac-82b7-4050858a9cd0 | 1 | CC BY 4.0 | Atlas des Orchidées de France métropolitaine (2010) |
| cbd241aa-a115-4856-af66-fac5cb90f2cc | 1 | CC BY-NC 4.0 | Cartographie des Leguminosae (Fabaceae) en France |

Signatures `rgbif` 3.9.0 (`args()`, voir § 10).

## 9. Baseflor, TAXREF : état du 2026-11-16 (repris aux § 14 et § 15)

(La passe 3 du 2026-11-17 complète ce § : Baseflor et les autres valeurs indicatrices au
§ 14, TAXREF au § 15. Les lignes ci-dessous restent l'état de la passe 2.)

| Point | État | Commande | Résultat |
|---|---|---|---|
| Baseflor : source, licence, colonnes | **non vérifié** | `curl -s "https://www.data.gouv.fr/api/1/datasets/?q=baseflor"` → 0 jeu ; `q=julve` → 0 ; `q=ellenberg` → 0 ; `q=catminat` → 0 ; recherche de dépôts `baseflor` sur l'API GitHub → 2 dépôts sans rapport | Aucune source primaire joignable depuis les hôtes ouverts (le site de l'auteur et Tela Botanica ne sont pas dans la liste). Colonnes des valeurs indicatrices (pH, azote, humidité), licence : **rien n'est écrit ici**. À faire avec un hôte ouvert vers la source de Julve. |
| TAXREF : version utilisée par l'IFN | **vérifié** | § 7 | v13.0. |
| TAXREF : version courante, URL | **non vérifié** | data.gouv.fr `q=taxref` → jeu MNHN `referentiel-taxonomique-taxref` (licence `fr-lo`) et jeu SIB `referentiel-taxonomique-taxref-1` (`lov2`), qui renvoient vers `https://inpn.mnhn.fr/telechargement/referentielEspece/referentielTaxo` et `https://taxref.mnhn.fr/taxref-web/api/doc` | Ces deux hôtes ne sont pas ouverts : **version courante non lue**. Le jeu GBIF « TAXREF » (`0e61f8fe-7d25-4f81-ada7-d970bbb2c6d6`, CC BY 4.0) porte `version` « 4.17 » (version de la ressource IPT, pas de TAXREF) et `pubDate` 2025-03-10 : ne pas en déduire la version de TAXREF. Écart de licence entre les deux fiches data.gouv.fr (`fr-lo` / `lov2`). |

## 10. Signatures des paquets R installés : vérifié

Commande : `LC_ALL=C.UTF-8 Rscript` avec `packageVersion()` et `args(getExportedValue(pkg, f))`.

| Paquet | Version | Signatures relevées |
|---|---|---|
| `lasR` | **0.21.4** | `reader(filter = "", select = "*", depth = NULL, ...)` ; `reader_las`, `reader_las_coverage`, `reader_coverage` : même signature ; `dtm(res = 1, add_class = NULL, ofile = temptif())` ; `chm(res = 1, tin = FALSE, ofile = tempfile(fileext = ".tif"))` ; `exec(pipeline, on, with = NULL, ...)` ; `rasterize(res, operators = "max", filter = "", ofile = temptif(), ...)` ; `triangulate(max_edge = 0, filter = "", ofile = "", use_attribute = "Z")` ; `transform_with(stage, operator = "-", store_in_attribute = "", bilinear = TRUE)` ; `write_las(ofile = paste0(tempdir(), "/*.las"), filter = "", keep_buffer = FALSE, version = NULL, pdrf = NULL)` ; `hulls(mesh = NULL, ofile = tempgpkg())` ; `local_maximum(ws, min_height = 2, filter = "", ofile = tempgpkg(), use_attribute = "Z", record_attributes = FALSE, store_in_attribute = "")` ; `summarise(zwbin = 2, iwbin = 50, metrics = NULL, filter = "")` ; `filter_with_grid(res, operator = "min", filter = "")` ; `classify_with_sor(k = 8, m = 6, class = 18L)` ; `load_raster(file, band = 1L)` ; `info(f)` ; `set_parallel_strategy(strategy)` ; `concurrent_points(ncores = half_cores())`. Exportées aussi : `normalize`, `hag`, `dsm`, `keep_ground`, `keep_ground_and_water`, `keep_class`, `drop_class`, `pit_fill`, `focal`, `write_copc`, `write_vpc`, `reader_circles`, `reader_rectangles`, `sampling_*`, `classify_with_csf/ipf/ivf/ptd`… `pipeline_info` : **absente**. |
| `lidR` | **4.3.3** | `readLAScatalog(folder, progress = TRUE, select = "*", filter = "", chunk_size = 0, chunk_buffer = 30, ...)` ; `plot_metrics(las, func, geometry, ..., radius)` ; `pixel_metrics(las, func, res = 20, start = c(0, 0), ...)` ; `rasterize_terrain(las, res = 1, algorithm = tin(), use_class = c(2L, 9L), shape = "convex", ...)` ; `rasterize_canopy(las, res = 1, algorithm = p2r(), ...)` ; `normalize_height(las, algorithm, use_class = c(2L, 9L), dtm = NULL, ...)` ; `opt_chunk_size(ctg)` ; `opt_chunk_buffer(ctg)`. |
| `rgbif` | **3.9.0** | `occ_download(..., body = NULL, type = "and", format = "DWCA", verbatim_extensions = NULL, checklistKey = "7ddf754f-d193-4cc9-b351-99906754a03b", user = NULL, pwd = NULL, email = NULL, curlopts = list(http_version = 2))` ; `occ_download_wait(x, status_ping = 5, curlopts = list(http_version = 2), quiet = FALSE)` ; `occ_download_get(key, path = ".", overwrite = FALSE, ...)` ; `occ_download_import(x = NULL, key = NULL, path = ".", fill = FALSE, encoding = "UTF-8", ...)` ; `occ_count(..., occurrenceStatus = "PRESENT", curlopts = list(http_version = 2))` ; `occ_search(taxonKey = NULL, …, geometry = NULL, …, datasetKey = NULL, …, year = NULL, …, hasGeospatialIssue = NULL, …, coordinateUncertaintyInMeters = NULL, …, checklistKey = "7ddf754f-d193-4cc9-b351-99906754a03b", limit = 500, start = 0, …)` ; `name_backbone(name = NULL, rank = NULL, kingdom = NULL, …, checklistKey = "7ddf754f-d193-4cc9-b351-99906754a03b", …)`. Prédicats : `pred(key, value, checklistKey = NULL)`, `pred_in(key, value, checklistKey = NULL)`, `pred_and(..., .list = list())`, `pred_or(..., .list = list())`, `pred_not(...)`, `pred_within(value)`, `pred_gte(key, value)`, `pred_lte(key, value)`, `pred_isnull(key)`, `pred_notnull(key)`, `pred_default()`. `occ_download` exige un compte GBIF (`user`, `pwd`, `email`) : **non exécuté**. |
| `happign` | **0.3.8** | `get_wfs(x = NULL, layer = NULL, predicate = bbox(), query = NULL, verbose = TRUE)` ; `get_layers_metadata(data_type, apikey = NULL)` ; `get_wms_raster(x, layer = "ORTHOIMAGERY.ORTHOPHOTOS", res = 10, crs = 2154, rgb = TRUE, filename = NULL, overwrite = FALSE, verbose = TRUE)`. |
| `sf`, `terra` | 1.0.15, 1.7.65 | — |
| `lidarHD` | **non installé** ; **dépôt GitHub non trouvé** | `packageVersion("lidarHD")` → erreur ; API GitHub `search/repositories?q=lidarHD` → 25 dépôts, **aucun en R, aucun d'INRAE** ; `q=lidarHD+language:R` → 0 ; `q=lidarHD+INRAE` → 0 ; `q=lidarhd+R+package` → 0 ; `GET /repos/inrae/lidarHD` et `/repos/jmmonnet/lidarHD` → 403 (non concluant). | Le paquet cité par le brief (§ 6, « `lidarHD` (INRAE, tableau d'assemblage et téléchargement des dalles) ») n'est pas trouvé sur GitHub. Il peut être hébergé ailleurs (forge INRAE, hôte non ouvert) : **non vérifié**. Fonctions : rien n'est écrit. Le tableau d'assemblage WFS du § 2 suffit à lister et télécharger les dalles sans lui. |

## 11. Licences : vérifié sauf Baseflor

| Source | Licence | Où lue |
|---|---|---|
| LiDAR HD (nuages, MNT, MNS, MNH) | Licence Ouverte 2.0 (`lov2`) | data.gouv.fr : « Nuages de points LiDAR HD » (`655b12122591e7a83414199e`), « MNT LiDAR HD » (`675871bd6e60265b46ab356e`), « MNS », « MNH » ; API data.gouv.fr, 2026-11-16 |
| BD Forêt V2 | Licence Ouverte 2.0 (`lov2`) | data.gouv.fr « BD Forêt® » (`61489da4b77d1697d00d2feb`) |
| SER, GRECO | Réutilisation libre « sans licence et sans versement de redevance » (page IFN) ; `lov2` sur les jeux WMTS data.gouv.fr | § 1 |
| Données brutes IFN | Licence Ouverte Etalab 2.0, citation imposée (page `dataifn/`) ; `fr-lo` sur data.gouv.fr | § 7 |
| BD Charm-50 | Pas de licence nommée ; métadonnées BRGM : « Aucune condition ne s'applique », « Données ouvertes » ; data.gouv.fr : `notspecified` | § 5 |
| Régolithe 1/1 000 000 | Pas de licence nommée ; data.gouv.fr : `notspecified` | § 6 |
| GBIF | Par jeu : 26 jeux CC BY 4.0, 4 jeux CC BY-NC 4.0 dans l'emprise | § 8 |
| TAXREF | `lov2` et `fr-lo` selon la fiche data.gouv.fr ; aucune licence sur la page PatriNat ; source primaire (INPN) en erreur 500 | § 15 |
| Baseflor | **piste** : ODbL 1.0 (base) et CC BY-SA 2.0 (données), annoncées par un résultat de recherche ; page Tela Botanica en 403 | § 14 |
| Valeurs de type Ellenberg (Tichý et al.) | CC BY 4.0 (Zenodo, API) | § 14 |
| EcoPlant | non trouvée | § 14 |
| BD TOPAGE | Licence Ouverte 1.0 (2022), 2.0 (2023, 2024) ; fiche 2025 non lue | § 16 |
| LiDAR HD, descriptif de contenu | cartes.gouv.fr : etalab-2.0 (page) | § 17 |
| SoilGrids (phh2o) | CC BY 4.0 | § 18 |
| Réserve utile BDGSF 1/1 000 000 | Licence Ouverte 2.0 | § 18 |
| Bruand et al. 2004 (tableau) | droits de reproduction non vérifiés | § 18 |

## 12. Emprise du massif test : gardée

| Critère | Mesure | Verdict |
|---|---|---|
| LiDAR HD | 225/225 dalles, mission `22LHDVosgesRF` (§ 2) | oui |
| Part hors SER principale (D11) | 22,37 km² = 9,94 % (D12 9,55 %, C41 0,39 %) (§ 1) | sous le seuil de 10 %, de justesse |
| Forêt hors D11 | 1,43 km² sur 165,74 km² de forêt = 0,86 % (§ 4) | négligeable |
| Grès et cristallin dans D11 | grès du Buntsandstein 18,37 km², cristallin et métamorphique 170,10 km² (§ 5) | oui |
| Part de forêt | 73,66 % (§ 4) | oui |

**Emprise gardée** (`1007000 6790000 1022000 6805000`, EPSG:2154). Aucune emprise de
remplacement n'est proposée : la condition (> 10 % hors SER principale) n'est pas
remplie. Limites : le seuil est frôlé ; le grès ne couvre que 9 % de la partie D11 (18,37 sur 202,63 km²) ; la
géologie impose trois départements BD Charm-50 (68, 67, 88).

## 13. Taille d'une dalle LAZ (complément du § 2) : vérifié

| Point | État | Commande | Résultat |
|---|---|---|---|
| Une dalle | **vérifié** | `curl -sI https://data.geopf.fr/telechargement/download/LiDARHD-NUALID/NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1007_6793_PTS_LAMB93_IGN69.copc.laz` | HTTP/2 200, `content-type: application/octet-stream`, **`content-length: 227690995`** (227,7 Mo) pour 37 644 004 points. |
| Les 225 dalles de l'emprise | **vérifié** (225 requêtes HEAD) | liste `url_npl` par la requête `WITHIN` du § 2 (`OUTPUTFORMAT=application/json&PROPERTYNAME=coordonnees_nw,url_npl,nombre_points&COUNT=300`), puis `curl -sI` sur chaque URL | Total **45 735 823 198 octets (45,7 Go)** ; minimum 61 589 356 (`1021-6796`, 15 725 137 points) ; médiane 207 019 249 ; maximum 358 541 399 (`1007-6791`, 65 776 663 points). Points : 7 959 708 253 au total. **Une dalle dépasse souvent 200 Mo** : aucune n'a été téléchargée. |

---

# Passe 3 (mission 013, 2026-11-17) : compléments pour le mode réel

**Décision éclairée :** ce que les missions 014 à 016 peuvent coder sans rien inventer
(URL, couches, colonnes), et quelle valeur indicatrice peut entrer dans un dépôt public.
Toutes les consultations datent du **2026-11-17**. Statut de chaque ligne : **vérifié**
(lu à la source primaire, résultat noté), **piste** (relevé dans un résultat de recherche,
source primaire non lue : ne pas coder), **non vérifié** (avec la raison).

## 14. Valeurs indicatrices (pH, azote, humidité) : Baseflor, Ellenberg, EcoPlant

CQQCOQP : **pourquoi** (calibrer pH, richesse en azote et humidité sur la flore des placettes,
`docs/brief-technique.md` l. 42 : EcoPlant si accessible, sinon Baseflor ou Ellenberg) ; **qui** Julve (Baseflor, programme CATMINAT), Tichý et al. (compilation
européenne), Gégout et al. (EcoPlant, AgroParisTech) ; **où** France entière (Baseflor),
Europe (Tichý), forêts françaises (EcoPlant).

| Source | État | URL / DOI, version, date | Licence | Colonnes, clé taxonomique |
|---|---|---|---|---|
| **Baseflor** (Julve) | **piste** (la page de téléchargement et la fiche de métadonnées de Tela Botanica répondent **HTTP 403** à l'outil ; résultat de recherche seulement) | `https://www.tela-botanica.org/ressources/donnees/telechargements/` (lien « Télécharger baseflor »), fiche `https://www.tela-botanica.org/eflore/consultation/popup.php?module=fiche-metadonnees&action=affichageMetaDonnees&projet=baseflor` ; version annoncée **01 juin 2024**. Page INRAE Capflor (`https://capflor.inra.fr/index.php/site/page/view/mentions`) : version citée **15/08/2012**, lien d'origine chez Julve (page personnelle Orange ; un commentaire de mars 2026 la dit hors ligne, non vérifié). | Annoncée : base sous **ODbL 1.0**, données contenues sous **CC BY-SA 2.0** (résultat de recherche, non lu à la source) | **Non vérifié : aucune colonne lue.** Ne coder aucun nom de colonne pH, azote ou humidité. Clé taxonomique non lue. |
| **Valeurs de type Ellenberg harmonisées** (Tichý et al. 2023, J. Veg. Sci. 34, e13168) | **vérifié** (API Zenodo) ; contenu du fichier **non lu** | `https://zenodo.org/records/7427088`, DOI `10.5281/zenodo.7427088`, version 2.0 (révision 11), publiée **2022-11-07** ; fichier `Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx`, **19 503 599 octets**, MD5 `3519d41639647dde8d80042fc98b2ef5` | **CC BY 4.0** (champ `license` de l'API) | Lumière, température, humidité, réaction, nutriments, salinité ; valeurs originales de **13 jeux sources** dont la France ; noms standardisés sur **Euro+Med PlantBase, pas TAXREF**. Feuilles et colonnes **non lues** (fichier de plus de 10 Mo, refusé par l'outil). |
| **EcoPlant** (Gégout et al. 2005, J. Veg. Sci. 16(2), DOI `10.1658/1100-9233(2005)016[0257:EAFSDL]2.0.CO;2`) | **non vérifié** pour l'accès | Base de 6 432 relevés phytosociologiques de forêts françaises avec sol et climat (résumé de l'article). Aucune page de téléchargement, aucune licence, aucune procédure de demande trouvées. Le brief technique (l. 41) la dit « sur demande ». | **Non trouvée** | Non lues. Gril et al. 2024 (DOI `10.1111/jvs.13241`, p. 2) la rangent parmi les valeurs « biogéographiques » à échelle continue, par opposition aux valeurs ordinales de Julve fondées sur l'expertise. |

**Lecture pour la décision.**

- **Aucune de ces trois sources n'a pu être ouverte jusqu'aux colonnes.** Les missions
  014 à 016 ne doivent coder aucun nom de colonne d'indicatrices ; la colonne à utiliser
  est à lire dans le fichier quand il aura été téléchargé (par Pascal ou sur un poste dont
  Tela Botanica répond).
- **Laquelle peut entrer dans un dépôt public ?** Aucune n'entre dans `inst/extdata` à ce
  jour. Baseflor est annoncée ODbL et CC BY-SA : l'obligation de partage à l'identique
  serait à examiner avant tout dépôt, et la règle du projet (une nomenclature tenue par un
  autre système se lit, ne se recopie pas) joue : **téléchargement à l'exécution, cache
  hors dépôt**. Le fichier Zenodo est CC BY 4.0, mais il reprend les valeurs de Julve
  pour la France, annoncées CC BY-SA 2.0 par Tela Botanica : **écart de licence non
  résolu** (§ Écarts, n° 15). EcoPlant : pas de licence, donnée AgroParisTech, jamais dans
  le dépôt (règle du `CLAUDE.md`).
- **Deuxième source :** Baseflor (expert, France) et Tichý (compilation européenne dont
  la France) ne sont pas indépendantes (la seconde reprend Julve) ; l'indépendance
  viendrait d'EcoPlant, inaccessible ici.
- **Clé de jointure :** nom latin ou Euro+Med dans le fichier Zenodo, donc passage par
  TAXREF (§ 15) à prévoir ; rien n'est vérifié pour Baseflor.

## 15. TAXREF : version courante, téléchargement, passage depuis la v13

| Point | État | URL, commande | Résultat |
|---|---|---|---|
| Version courante | **vérifié** | page `https://www.patrinat.fr/fr/page-temporaire-de-telechargement-des-referentiels-de-donnees-lies-linpn-7353` (publiée 2025-08-11, mise à jour **2026-10-19**) | **TAXREF v18 (2025)**. Un site tiers (`mycofrance.fr`, résultat de recherche) date la 18.0 du 9 janvier 2025. La page PatriNat dit que cette page temporaire sera supprimée « dans les prochains mois » (**URL volatile**) et renvoie à `https://inpn.mnhn.fr/referentiels-donnees` (non lue). |
| Téléchargement | **vérifié** (fichier téléchargé le 2026-11-17, mission 015 ; contenu relu le 2026-11-18, mission 016) | `https://assets.patrinat.fr/files/referentiel/TAXREF_v18_2025.zip`, cache hors dépôt `data/cache/TAXREF_v18_2025.zip` | **60 582 042 octets**, MD5 `f3b4b9d7d656c2ac57a00c03fc74b805` (`unzip -l`, `md5sum`). Neuf fichiers : `TAXREFv18.txt` (317 126 709 octets, daté 2025-01-09), `TAXVERNv18.txt`, `TAXREF_LIENS.txt`, `TAXREF_CHANGES.txt`, `CDNOM_DISPARUS.txt`, `habitats_note.csv`, `rangs_note.csv`, `statuts_note.csv`, `TAXREFv18.pdf` (2025-11-06). `TAXREFv18.txt` : séparateur tabulation, textes entre guillemets, fin de ligne CRLF, **708 686 lignes en-tête compris** ; 44 colonnes dont `CD_NOM`, `CD_REF`, `RANG`, `LB_NOM`, `NOM_VALIDE`, `NOM_VERN` (en-tête lu par `unzip -p … \| head -1`). `read_taxref()` lit l'archive et garde `CD_NOM`, `CD_REF`, `LB_NOM`, `RANG` ; extrait du dépôt : `inst/extdata/taxref_v18_extrait.csv`. |
| `CDNOM_DISPARUS.txt` (dans le zip) | **vérifié** (en-tête et décompte) | `unzip -p TAXREF_v18_2025.zip CDNOM_DISPARUS.txt` | 12 892 lignes en-tête compris ; colonnes `CD_NOM`, `PLUS_RECENTE_DIFFUSION`, `CD_NOM_REMPLACEMENT`, `CD_RAISON_SUPPRESSION`, `RAISON_SUPPRESSION`. C'est la piste du séminaire de 2016 (ligne suivante), publiée dans l'archive v18 ; **non utilisée par le code à ce jour**. |
| Page officielle | **non vérifié : indisponible** | `https://inpn.mnhn.fr/telechargement/referentielEspece/referentielTaxo` → HTTP 500 ; `https://inpn.mnhn.fr/programme/referentiel-taxonomique-taxref` → HTTP 500 ; `https://taxref.mnhn.fr/taxref-web/api/doc` répond (navigation seulement, pas de version) | Le MNHN a subi une cyberattaque (page PatriNat) ; la fiche data.gouv.fr (`66601a4032498dd005f23ba9`) note ces liens en erreur. Un tiers rapporte une barrière anti-robot sur l'API. |
| **Table de passage v13 vers v18** | **non trouvée** | recherches web, pages `taxref.mnhn.fr/taxref-web/stat/versions` et `/stat/versions/compare` (pages de consultation : « Évolutions des données », « Comparaison de deux versions ») | **Aucun fichier de correspondance entre versions trouvé.** Pistes : tableau `CDNOM_DISPARUS.xls` (7 498 lignes : CD_NOM disparus, cause, remplaçant des doublons) cité par la présentation du séminaire TAXREF de 2016 (`https://seminaire-taxref.mnhn.fr/wp-content/uploads/sites/15/2016/01/07_nouvelle_version.pdf`), **non confirmé comme encore publié** ; historique par taxon sur `taxref.mnhn.fr/taxref-web/taxa/<cd_nom>/history`. Principe de méthode cité (même séminaire) : un `CD_NOM` ne change pas pour un `LB_NOM` donné, la synonymie passe par `CD_REF`. |
| Licence | **écart** | API data.gouv.fr, 2026-11-17 | `lov2` (jeu `66601a4032498dd005f23ba9`, modifié 2025-08-29) et `fr-lo` (jeu `559ba6aec751df5c17390bd3`, modifié 2025-08-28) ; la page PatriNat ne cite aucune licence. |

**Pour les dev.** Il n'existe pas ici de table de passage à lire : la **stratégie** est celle du
`CLAUDE.md` : joindre le `CD_REF` v13 de la flore IFN (§ 7) sur le `CD_NOM` v18, prendre le
`CD_REF` v18 de la ligne, lister les non appariés. Stratégie appliquée par la mission 015
(`load_indicator_values(taxa = ...)`) sur le fichier v18 ouvert (ligne « Téléchargement »).
Version figée dans `config.yml` : **`taxref_version: "18"`**, avec `taxref_url` ; le fichier
est téléchargé une fois et gardé hors dépôt (`data/cache/`). `real_sources()` refuse un
fichier TAXREF dont le nom ne porte pas cette version.

## 16. BD TOPAGE : tronçons hydrographiques

CQQCOQP : **pourquoi** (hauteur au-dessus du réseau hydrographique, `docs/brief-technique.md` l. 75) ; **qui** Sandre/OFB avec IGN, collaboratif ; **où** France ; **quand**
millésime annuel.

| Point | État | Commande | Résultat |
|---|---|---|---|
| Service Sandre, millésime 2025 | **vérifié** | `https://services.sandre.eaufrance.fr/geo/topage2025?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities` | Titre « Référentiel Hydrographique (BD TOPAGE) », WFS 2.0.0, **38 `FeatureType`** (préfixe `sa:`), dont cinq de tronçons : `sa:TronconHydrographique_Topage2025` (France entière), **`sa:TronconHydrographique_FXX_Topage2025` (Métropole)**, `…_MTQ_…`, `…_GLP_…`, `…_MYT_…`. **Le millésime est dans le nom de la couche** (autres millésimes vus : 2019, 2022, 2023) : lire le nom dans le GetCapabilities, ne pas le figer. |
| Colonnes de `TronconHydrographique_FXX_Topage2025` | **vérifié** | `&REQUEST=DescribeFeatureType&TYPENAMES=sa:TronconHydrographique_FXX_Topage2025` | **38 éléments**, tous facultatifs : `msGeometry` (`gml:GeometryPropertyType`), `gid` (entier), `CdOH`, `DateCreationOH` (`gml:TimeInstantType`), `StatutOH`, `TopoOH`, `StatutNomOH`, `SourceNomOH`, `NatureTH`, `TronconFictifTH` (booléen), `PositionParRapportSolTH`, `PersistanceTH`, `SaliniteTH` (booléen), `OrigineTH`, `SensEcoulementTH`, `ReseauPrincipalCoulantTH` (booléen), `DelimitationTH` (booléen), `ClasseLargeurTH`, `BrasTH`, `NumeroOrdreTH`, `StrategieClassementNumeroOrdreTH`, `PerimetreUtilisationNumeroOrdreTH`, `CommentaireOH`, `CdCoursEau_1`, `CdCoursEau_2`, `CdCoursEau_3`, `CdSurfaceElementaire`, `CdNoeudDebut`, `CdNoeudFin`, `CdPays_1`, `CdPays_2`, `CdPays_3`, `SystemeAltiOH`, `PrecAltiOH`, `ModeAltiOH`, `PrecPlaniOH`, `ModObCoordiOH`, `ProjCoordOH` (les autres sont des chaînes). |
| Volume | **vérifié** | `&RESULTTYPE=hits` | **3 042 333** tronçons (Métropole), horodatage serveur 2026-11-17T21:17:53. Toujours filtrer par emprise. Sans `RESULTTYPE=hits`, `numberMatched` vaut « unknown ». |
| Emprise voisine du massif test | **vérifié** | `&RESULTTYPE=hits&BBOX=48.13,7.12,48.28,7.35,urn:ogc:def:crs:EPSG::4326` | **748** (2026-11-17T21:24:29). **Ordre des axes : latitude puis longitude** avec le CRS en `urn:ogc:def:crs:EPSG::4326`. Cette boîte (WGS84) enveloppe l'emprise test (§ 8) sans la coïncider. Relecture du 2026-11-17 (shell) : la BBOX en Lambert-93 `BBOX=1007000,6790000,1022000,6805000,urn:ogc:def:crs:EPSG::2154` répond et donne **641** tronçons sur l'emprise test : à préférer (EPSG:2154 partout). |
| Valeurs vues (2 tronçons) | **vérifié** (échantillon de 2, pas un inventaire) | `&COUNT=2&PROPERTYNAME=CdOH,NatureTH,PersistanceTH,PositionParRapportSolTH,NumeroOrdreTH,TronconFictifTH,ClasseLargeurTH` | `NatureTH` = « Ecoulement naturel » ; `PersistanceTH` = « permanent » ; `PositionParRapportSolTH` = « surface » ; `ClasseLargeurTH` = « 0_5 » ; `TronconFictifTH` = false ; `NumeroOrdreTH` vide. **La liste des modalités n'a pas été lue** (dictionnaire : `https://id.eaufrance.fr/ddd/ETH/latest`). `CQL_FILTER=PersistanceTH='permanent'` : 748, identique au décompte sans filtre : **non tranché** (tous permanents ou filtre ignoré). |
| Alternative IGN (Géoplateforme) | **vérifié** | `https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=DescribeFeatureType&TYPENAMES=BDTOPO_V3:troncon_hydrographique` | **45 éléments**, géométrie `geometrie` (`gml:CurvePropertyType`) ; dont `cleabs`, `code_hydrographique`, `nature`, `fictif`, `etat_de_l_objet`, `position_par_rapport_au_sol`, `persistance`, `statut`, `numero_d_ordre`, `classe_de_largeur`, `sens_de_l_ecoulement`, `reseau_principal_coulant`. Même boîte WGS84 : **752** tronçons (2026-11-17T20:24:43Z). `CQL_FILTER=persistance='permanent'` : HTTP 500. |
| Origine du millésime 2025 | **piste** (fiche Sandre vue en résultat de recherche) | — | « issus des tronçons hydrographiques du thème hydrographique de la BD TOPO, édition du 15 décembre 2023 ». |
| Licence | **écart** | fiches `sandre.eaufrance.fr/atlas/srv/api/records/<id>` | **2022** : Licence Ouverte 1.0 (`fc253cb2-0de4-41bb-8cf7-1347fe0a14a2`) ; **2023** : `lov2` (data.gouv.fr, jeu `bd-topage-r-metropole-2023`) ; **2024** : Licence Ouverte 2.0, « pas de restriction d'accès public » (`7fa4c224-fe38-4e2c-846d-dcc2fa7ef73e`). **Fiche 2025 non lue.** Licence de la couche `BDTOPO_V3` : non lue. |
| Fichiers | **vérifié** (liens lus, rien téléchargé) | fiches 2022 et 2024 | Shapefile 2024 Métropole : `https://services.sandre.eaufrance.fr/telechargement/geo/ETH/BDTopage/2024/BD_Topage_FXX_2024-shp.zip` ; tronçons 2022 en shp, gpkg, geojson sous `…/BDTopage/2022/TronconHydrographique/TronconHydrographique_FXX-{shp,gpkg,geojson}.zip`. Fichiers 2025 : non vus. |

**Écart observé :** 748 tronçons (TOPAGE 2025) contre 752 (BD TOPO courante) dans la même boîte.
La BD TOPO est plus récente que l'édition de décembre 2023 qui alimente TOPAGE 2025 ;
**cause non vérifiée**.

## 17. Classes LiDAR HD : nomenclature officielle de l'IGN

Source unique : « LiDAR HD, version 1.0, Nuages de points, Modèles numériques, Descriptif de
contenu », date du document mai 2022, **révision juillet 2026**,
`https://data.geopf.fr/annexes/ressources/documentation/DC_LiDAR_HD_1-0.pdf` (5,8 Mo ; les
anciennes adresses `geoservices.ign.fr/sites/default/files/…/DC_LiDAR_HD_1-0*.pdf`
redirigent vers la page d'accueil de cartes.gouv.fr). Lu en images, pages 1 à 10 et 15 à 20
(PDF et pagination du document coïncident). Le sommaire (p. 2) liste les sections
2.2.8.1 à 2.2.8.9.

| Code | Description (p. 16) | Prédéfinie LAS 1.4 | Section |
|---|---|---|---|
| 1 | Non classé | oui | 2.2.8.1, p. 16 |
| 2 | Sol | oui | 2.2.8.2, p. 16 |
| 3 | Végétation basse (0-50 cm) | oui | 2.2.8.3, p. 16 |
| 4 | Végétation moyenne (50 cm-1,50 m) | oui | 2.2.8.3, p. 16 |
| 5 | Végétation haute (+1,50 m) | oui | 2.2.8.3, p. 16 |
| 6 | Bâtiment | oui | 2.2.8.4, p. 17 |
| 9 | Eau | oui | 2.2.8.5, p. 17 |
| 17 | Tablier de pont | oui | 2.2.8.6, p. 18 |
| **64** | **Sursol pérenne** | non | 2.2.8.7, p. 19 |
| **66** | **Points virtuels** | non | 2.2.8.8, p. 19 |
| **67** | **Divers - bâtis** | non | 2.2.8.9, p. 20 |

**11 classes** : 8 prédéfinies LAS 1.4 et 3 créées pour le LiDAR HD « parmi des valeurs
réservées par la spécification (64, 66 et 67) » (p. 15). **Il n'y a pas de classe 65 dans
cette révision** (ni dans le tableau, ni dans le sommaire).

Ce que dit le descriptif des trois classes propres (p. 19 et 20) :

- **64, Sursol pérenne** : éléments du sursol ni bâtiment, ni végétation, ni pont, pérennes
  (éoliennes, téléphériques, antennes, câbles et pylônes, caténaires ; haubans et piliers de
  ponts) ; hors classe : véhicules, personnes, objets transitoires.
- **66, Points virtuels** : « points artificiels situés sur des lignes de rupture de pente »
  saisis sous les ponts, pour améliorer le modèle du sol ; aussi « certains points virtuels
  situés dans certains cours d'eau » (traitement des écoulements, p. 20). Sens de balayage et
  bord de bande fixés à 0 (p. 15).
- **67, Divers - bâtis** : points de bâtiments « avec un degré de certitude inférieur » à
  la classe 6 ; classement produit **exclusivement par le procédé automatique de l'IGN** ;
  peut contenir « certains types de végétation (haies bien taillées, pins parasols,
  massifs proches d'habitation) », des rochers et ruptures de pente, des terrasses, etc.

**Décision éclairée : l'exclusion des classes 65 et 66 du MHC.**

- **66 : exclusion fondée** sur la nomenclature officielle (points artificiels, pas des
  retours du couvert).
- **65 : exclusion sans objet dans la nomenclature de juillet 2026** (aucune définition).
  Un résultat de recherche attribue à une version antérieure du descriptif (2023) une section
  « Artefact (code 65) » ; **non vérifié** (ce PDF n'est plus à son adresse). Garder 65
  dans la liste d'exclusion reste inoffensif, mais **sans citer l'IGN pour la justifier**.
- **À trancher en 014 (non fixé ici)** : les dalles du massif test ont été classées par
  `IGN_AUTO_V5` (§ 2) ; la classe **67 y est donc possible** et peut contenir de la
  végétation, tandis que la classe **64** (pylônes, câbles) n'est pas du couvert. Un décompte
  des classes sur une dalle (`lasR::info`, non exécuté) dira ce qu'elles pèsent.
- **Cohérence :** `use_class = c(2L, 9L)` de `lidR` (§ 10) correspond bien à Sol et Eau.
- **Autres sources :** cartes.gouv.fr (`…/nuages-points-lidar-hd/`) annonce « 11 catégories »,
  licence etalab-2.0 ; une présentation wallonne de décembre 2024 donne 67 = « Divers - bâtis ».
  Concordance. Une documentation tierce (projet `IGN_LIDAR_HD_DATASET`) regroupe 64, 65 et
  67 en classe 1 : choix de cet outil, pas la nomenclature de l'IGN.

## 18. Sols : pH, réserve utile, pédotransfert

| Point | État | Source | Résultat |
|---|---|---|---|
| GlobalSoilMap France, programme | **piste** | pages Theia (`theia-land.fr/en/blog/ceslist/digital-soil-mapping-sec/`) | Produits à **90 m**, six profondeurs (0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm), propriétés dont pH, granulométrie, réserve utile ; diffusion en ligne « 2020-2023 » annoncée au calendrier. **Aucun jeu de pH France à 90 m avec URL et licence n'a été trouvé.** |
| Texture 90 m (granulométrie) | **piste** (page refusée par la protection anti-robot) | DOI `10.57745/N4E4NE`, `https://entrepot.recherche.data.gouv.fr/dataset.xhtml?persistentId=doi:10.57745/N4E4NE` | Couches de sable 0-5, 5-15, 15-30 cm, 90 m (page Theia). Licence, fichiers : **non lus**. |
| Réserve utile nationale 90 m | **piste** (page refusée) | DOI `10.15454/9IRARJ` (page Theia « Map of the Soil Available Water Capacity in Metropolitan France ») | Méthode : fonction de pédotransfert sur propriétés cartographiées. Résolution nationale, licence, fichiers : **non lus** (la mention « 90 m » de la page vise le Languedoc-Roussillon). |
| **pH ouvert, équivalent** | **vérifié** (fiche ISRIC lue) | SoilGrids 2.0, `https://data.isric.org/geonetwork/srv/api/records/713396fd-1687-11ea-a7c0-a0481ca9e724` | `phh2o`, **250 m**, **pH × 10** (diviser par 10), profondeurs 0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm, statistiques mean, Q0.05, Q0.5, Q0.95 ; **CC BY 4.0** ; publié 2020-05-04. Fichiers : `https://files.isric.org/soilgrids/latest/data/` (WebDAV, chemin « latest »), WMS `https://maps.isric.org/mapserv?map=/map/phh2o.map`. Le WCS a été signalé hors service par la documentation d'ISRIC (résultat de recherche, non revérifié). Exactitude sur la France : **non évaluée**. |
| **Réserve utile ouverte, grossière** | **vérifié** (fiche INRAE lue) | `https://geodata.inrae.fr/geonetwork/srv/api/records/393d8106-4400-51cd-9767-e8bbef2f73a6`, DOI `10.15454/JPB9RB` | « Carte de la Réserve Utile en eau issue de la BDGSF » : classe dominante par unité cartographique de sol, **1/1 000 000**, 2 295 objets, BDGSF 3.2.8.0, par fonctions de pédotransfert ; **Licence Ouverte 2.0** ; créée 2018-02-02, révisée 2023-02-13. WFS : `https://geodata.inrae.fr/geoserver/inra_bdgsf/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=inra_bdgsf:bdgsf_classe_ru&outputFormat=shape-zip`, couche `inra_bdgsf:bdgsf_classe_ru`. Unités des classes : **non indiquées**. La fiche déconseille toute lecture plus fine que le 1/1 000 000 : **trop grossière pour un massif de 225 km²**. |
| Réserves utiles Languedoc-Roussillon | **vérifié** (hors zone) | data.gouv.fr, jeu `61aab14989a1ddaa864ed799` | `lov2`, 100, 150, 200 cm, 1/250 000, Languedoc-Roussillon seulement : **inutilisable pour les Vosges**. |
| **Table de pédotransfert** | **vérifié** (article lu en images) | Bruand A., Duval O., Cousin I. (2004), « Estimation des propriétés de rétention en eau des sols à partir de la base de données SOLHYDRO : une première proposition combinant le type d'horizon, sa texture et sa densité apparente », *Étude et Gestion des Sols* 11(3) : 323-332, `https://afes.fr/wp-content/uploads/2024/10/EGS_2004_11_3_bruand.pdf` | **Tableau 2, p. 328** : réserve en eau utile en mm par cm, par type d'horizon et classe de texture (triangle de l'Aisne), sans puis avec prise en compte de la densité apparente. Reproduction ci-dessous des colonnes « sans prise en compte de Da ». |
| Jamagne et al. (1977) | **non consulté** | cité par Bruand et al. p. 325 ; bibliographie p. 332 : Jamagne M., Bétrémieux R., Bégon J.C., Mori A., 1977, *Bulletin Technique d'Information* 324-325, pp. 627-641 | Tableau d'origine non lu. Bruand et al. (p. 327) disent que leurs valeurs sont plus faibles pour les textures argileuses (ALO, AL, A) et limono-argileuses (LA, LAS, LSA). |

**Tableau 2 de Bruand et al. (2004), p. 328, sans prise en compte de Da** (mm de réserve
utile par cm de sol ; « excès » = θ1,5 − θ4,2 ; « défaut » = θ2,0 − θ4,2, pF 1,5 ; 2,0 ; 4,2).
Codes de texture **tels qu'imprimés** ; l'article précise seulement LL = limon léger, LLS =
limon léger sableux, LS = limon sableux ; la légende complète du triangle n'est pas dans les
pages lues. Valeurs recopiées de la page, deuxième lecture à faire par un relecteur.
Valeurs proposées pour **12 classes sur 15** par type d'horizon (p. 329) ; `-` = pas de valeur.

| Texture | Horizons A, excès | A, défaut | Horizons E, B, C, excès | E, B, C, défaut |
|---|---|---|---|---|
| ALO | 1,42 | 1,24 | 1,24 | 1,12 |
| AL | 1,49 | 1,36 | 1,29 | 1,13 |
| AS | 1,73 | 1,73 | 1,15 | 0,95 |
| A | - | - | 1,10 | 0,93 |
| LA | 1,88 | 1,73 | 1,68 | 1,49 |
| LAS | 1,82 | 1,67 | 1,65 | 1,48 |
| LSA | 1,63 | 1,43 | 1,50 | 1,27 |
| LM | 2,28 | 2,13 | 2,15 | 2,07 |
| LMS | 1,94 | 1,83 | 2,19 | 1,96 |
| LS | 1,73 | 1,62 | - | - |
| LLS | - | - | - | - |
| LL | - | - | - | - |
| SA | 1,47 | 1,28 | 1,26 | 1,03 |
| SL | 1,74 | 1,31 | 1,55 | 1,16 |
| S | 0,83 | 0,60 | 1,27 | 0,73 |

Réserve : la reproduction de ce tableau d'un article de la revue de l'AFES n'a pas fait
l'objet d'une vérification de droits ; **ne pas copier ce tableau dans `inst/extdata`**
sans cette vérification (les écarts types sont à l'annexe, p. 332 : par exemple 0,14 à 0,53
mm/cm sur les classes renseignées).

## 19. Régolithe 1/1 000 000 (BRGM) : service joignable (lève la réserve du § 6)

| Point | État | Commande | Résultat |
|---|---|---|---|
| Service WMS | **vérifié** | `https://mapsref.brgm.fr/wxs/infoterre/regolithe?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities` | WMS 1.3.0, résumé « Catalogue InfoTerre ». Couches : `REGOLITHE`, `REGOLITHES_AUTOCH_S_1M` (« Formations autochtones au 1/1 000 000e »), `REGOLITHES_ALLOCH_S_1M` (« Formations allochtones au 1/1 000 000e »), `REGOLITHE_SP`, `REGOLITHE_RAPPORTS_SP_COMPTE`, `REGOLITHE_RAPPORTS_SP`. CRS dont EPSG:2154 ; échelles de 1/150 000 à 1/4 000 000 ; pas d'attribution ni de `MetadataURL`. |
| Service WFS | **vérifié** | même hôte, `SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities` | WFS 2.0.0, **4 `FeatureType`** : `ms:REGOLITHES_AUTOCH_S_1M`, `ms:REGOLITHES_ALLOCH_S_1M`, `ms:REGOLITHE_RAPPORTS_SP_COMPTE`, `ms:REGOLITHE_RAPPORTS_SP`. |
| Colonnes (les deux couches de formations) | **vérifié** | `&REQUEST=DescribeFeatureType&TYPENAMES=ms:REGOLITHES_AUTOCH_S_1M,ms:REGOLITHES_ALLOCH_S_1M` | Identiques : `msGeometry` (`gml:GeometryPropertyType`), `NOTATION`, `TITRE`, `TITRE1`, `DESCR` (chaînes). |
| Allochtone : volume | **vérifié** | `&TYPENAMES=ms:REGOLITHES_ALLOCH_S_1M&RESULTTYPE=hits` | **9 095** (2026-11-17T21:23:10). |
| Allochtone : boîte du massif test | **vérifié** | `&BBOX=48.13,7.12,48.28,7.35,urn:ogc:def:crs:EPSG::4326` (axes latitude, longitude), `COUNT=20` | **6** entités : `Fz` « Holocène à actuel », « Alluvionnaire », « Dépôts alluviaux » ; `Fy` « Weichsélien (Pléistocène sup.) », « Alluvionnaire », « Dépôts récents de la basse vallée et sous-flandriennes. Sables +/- argileux, graviers et galets » ; `J` « Age indéterminé », « Alluvionnaire », « Cône de déjection » (×2) ; `OE` « Age indéterminé », « Éolien », « Loess et lehms » (×2). |
| Autochtone : boîte du massif test | **vérifié** (1 entité) | même BBOX, `ms:REGOLITHES_AUTOCH_S_1M` | `NOTATION` = « ¡m » (caractère `¡` : encodage à vérifier), `TITRE` = « Age indéterminé », `TITRE1` = « Altérites de roches du socle », `DESCR` = « Altérites de roches plutoniques et métamorphiques ». |
| Pièges | **vérifié** | — | (1) **Corrigé par la relecture du 2026-11-17 (shell)** : `GetFeature` avec `BBOX` en **EPSG:2154** répond **HTTP 200** en sortie par défaut (boîte écrite `EPSG:2154`, `urn:ogc:def:crs:EPSG::2154` ou sans CRS) ; le HTTP 400 vient de `OUTPUTFORMAT=application/json`, pas du système de coordonnées : ne pas demander de JSON. Sur l'emprise de `config.yml` (1007000, 6790000, 1022000, 6805000) : 4 entités allochtones (Fz, Fy, J × 2) et 1 autochtone (¡m, caractère U+00A1 réel du service). (2) `numberMatched` = « unknown » sans `RESULTTYPE=hits`. (3) **Autochtone : `hits` sans filtre = 0 mais 1 entité avec la boîte** : le décompte brut de cette couche n'est pas fiable. (4) L'emprise annoncée pour `REGOLITHES_AUTOCH_S_1M` dans le GetCapabilities WMS se lit (ouest −1,92, est 6,86, sud 4,89, nord 12,75), ce qui n'est pas la France : lecture par résumeur, **à relire dans le XML**. |
| Hôte `geoservices.brgm.fr` | **changement d'état** | `https://geoservices.brgm.fr/geologie?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities` | Répond le 2026-11-17 (page « Request Rejected » le 2026-11-16 ; autre chemin réseau). Document de 225 796 caractères, lu jusqu'au caractère 200 000 : 36 `FeatureType` nommés (17 dans les 100 000 premiers caractères, 19 dans les 100 000 suivants, plus un nom coupé), **les 25 796 derniers caractères ne sont pas lus** ; aucun nom lu n'est du régolithe ; dont `ms:C50_L_DIVERS`, `ms:C50_P_STRUCT`, `ms:SCAN_H_GEOL50_PERIMETRE` (« Périmètre de la carte géologique 50 000e - harmonisé »). |
| Licence | **inchangé** | § 6 | `notspecified` sur data.gouv.fr ; non relue ce jour. |

**Pour les dev.** Couche utile : `ms:REGOLITHES_ALLOCH_S_1M` (alluvions, loess) et
`ms:REGOLITHES_AUTOCH_S_1M` (altérites du socle), champ à lire : `TITRE1` (famille) et `DESCR`.
À 1/1 000 000, la couche renseigne 7 polygones sur la boîte WGS84 (plus large) et 5 sur l'emprise test en Lambert-93 (relecture du 2026-11-17) : **prédicteur de
contexte, pas de détail**.

## 20. WhiteboxTools sous R

Source : paquet `whitebox` **2.4.3**, publié 2025-10-20, licence MIT, `https://whiteboxr.gishub.org/`,
`https://github.com/opengeos/whiteboxR` (CRAN : `https://cran.r-project.org/web/packages/whitebox/index.html`),
`SystemRequirements` : WhiteboxTools. Fonctions lues dans les sources sur GitHub (branche
principale, fichiers `R/wbt.R`, `R/terrain_analysis.R`, `R/hydro_analysis.R`), **non exécutées**
(pas de R dans cette passe).

| Point | État | Résultat |
|---|---|---|
| Installation | **vérifié** (source lue) | `whitebox::install_whitebox(pkg_dir = wbt_data_dir(), platform = NULL, force = FALSE, remove = FALSE)` : appelle `wbt_install()` (mêmes arguments), télécharge un ZIP depuis whiteboxgeo.com, l'extrait, règle les droits, appelle `wbt_init()`. `platform` : `"linux_amd64"`, `"linux_musl"`, `"darwin_amd64"`, `"darwin_m_series"`, `"win_amd64"`. Voir aussi `wbt_init(exe_path = wbt_exe_path(shell_quote = FALSE), ..., check_version = TRUE)`, `wbt_version(extract = FALSE)`, `wbt_exe_path(exe_path = NULL, shell_quote = TRUE)` (ordre : argument, variable `R_WHITEBOX_EXE_PATH`, option `whitebox.exe_path`, PATH, défaut). |
| **Outil MRVBF** | **vérifié : absent du paquet R** | Aucune fonction `wbt_mrvbf` ni fonction de fond de vallée dans `R/terrain_analysis.R` (lu en entier, 191 859 caractères) ni dans la liste du manuel CRAN (premiers 100 000 de 609 559 caractères : séries `wbt_multiscale_*` sans MRVBF), ni dans `R/hydro_analysis.R` (113 883 caractères, derniers 13 883 non lus). Les fonctions voisines, alphabétiquement, de `wbt_minimal_curvature` sont `wbt_multidirectional_hillshade`, `wbt_multiscale_*`. **Il n'y a donc pas de « nom exact de l'outil MRVBF » côté `whitebox`.** Limites : branche principale de GitHub, pas l'étiquette 2.4.3 ; le binaire WhiteboxTools lui-même (manuel de whiteboxgeo.com : URL consultée en 404) n'a pas été interrogé. |
| Équivalents du MRVBF | **piste** (documentation, pas exécutée) | SAGA GIS, bibliothèque `ta_morphometry`, outil 8 « Multiresolution Index of Valley Bottom Flatness (MRVBF) » (`https://saga-gis.sourceforge.io/saga_tool_doc/9.3.2/ta_morphometry_8.html` ; seuil de pente initial par défaut 16) ; GRASS, extension `r.valley.bottom`. Méthode : Gallant et Dowling (2003), *Water Resources Research*. Passerelle R vers SAGA : non vérifiée. |
| Signatures lues | **vérifié** (sources) | `wbt_slope(dem, output, zfactor=NULL, units="degrees", wd=NULL, verbose_mode=NULL, compress_rasters=NULL, command_only=FALSE)` ; `wbt_wetness_index(sca, slope, output, wd=NULL, verbose_mode=NULL, compress_rasters=NULL, command_only=FALSE)` ; `wbt_relative_topographic_position(dem, output, filterx=11, filtery=11, wd=…)` ; `wbt_multiscale_topographic_position_image(local, meso, broad, output, hillshade=NULL, lightness=1.2, wd=…)` ; `wbt_multiscale_curvatures(dem, out_mag, curv_type="ProfileCurv", out_scale=NULL, min_scale=0, step=1, num_steps=1, step_nonlinearity=1.0, log=TRUE, standardize=FALSE, wd=…)` ; `wbt_elevation_above_stream(dem, streams, output, wd=…)` ; `wbt_d_inf_flow_accumulation(input, output, out_type="Specific Contributing Area", threshold=NULL, log=FALSE, clip=FALSE, pntr=FALSE, wd=…)` ; `wbt_breach_depressions_least_cost(dem, output, dist, max_cost=NULL, min_dist=TRUE, flat_increment=NULL, fill=TRUE, wd=…)`. (`wd=…` : suite commune `wd=NULL, verbose_mode=NULL, compress_rasters=NULL, command_only=FALSE`.) |
| Fonctions dont seul le nom est lu | **vérifié** (noms) | `wbt_depth_to_water`, `wbt_elevation_above_stream_euclidean`, `wbt_geomorphons`, `wbt_stream_power_index`, `wbt_openness`, `wbt_downslope_distance_to_stream`, `wbt_d8_flow_accumulation`, `wbt_fd8_flow_accumulation` : signatures **non lues**. |

## 21. Référence AgroParisTech : ce qui est publié du format des rasters de stations

| Point | État | Source | Résultat |
|---|---|---|---|
| Publication de référence | **vérifié** (notice) | Gégout J.-C., Piedallu C., Cornu J.-F., Cluzeau C. (2008), « La cartographie prédictive des stations forestières : un nouvel outil au service du gestionnaire », *Revue forestière française* 60(1) : 37-60, DOI `10.4267/2042/17240`, notice `https://infodoc.agroparistech.fr/index.php?lvl=notice_display&id=101455` | Le résumé parle de « couches numériques » produites sous SIG et d'une carte d'unités écologiquement homogènes pour le massif vosgien ; **aucun format de fichier, aucun nombre de types, aucun codage** n'y figure. |
| Les 59 types, le code à trois chiffres, la résolution de 50 m | **non vérifié à la source** | brief technique, `docs/brief-technique.md` l. 255 : « 8 800 km², pixels de 50 m, 59 types codés sur trois chiffres (6 classes trophiques, 5 bioclimatiques, 4 classes d'eau) » | **Ce chiffrage vient du brief, pas d'une consultation de cette passe.** Rien n'a été trouvé qui publie le raster, ses couches ou son codage (recherches : data.gouv.fr, Zenodo, entrepôt recherche.data.gouv.fr). La page SILVAE, citée par le brief, n'a pas été consultée. |
| Diffusion | **non trouvée** | brief technique l. 265 | Le brief dit : demande à adresser à AgroParisTech Nancy (équipe SILVAE). **Aucune diffusion ouverte trouvée.** |
| Voisins, pour mémoire | **piste** (listes de résultats, pages non ouvertes sauf la première) | data.gouv.fr « Guides des stations forestières en France métropolitaine » (La Forestière, Licence Ouverte 2.0, GeoPackage 2,4 Mo, couches `guides`, `ressources`, `guides_urls`, `cnpfs`, `cnpfs_urls`, `stations`, mise à jour 2026-09-22 ; **emprises de validité des guides, pas un raster**) ; cartes prédites des Hauts-de-France (WMS/WFS) et du CNPF Normandie (WMS), inspirées du LERFoB | Ne donnent pas le format du raster de référence. |

**Pour les dev.** Le format réel des rasters, les noms de couches, le codage des 59 types et
l'ordre des chiffres du code (`recode_3digits()`) **restent inconnus** : ne rien coder, garder la
mention « à vérifier » (docs/pipeline.md l. 38-39) jusqu'à la réponse d'AgroParisTech.

---

# Passe 4 (mission 019, 2026-11-17) : gradient hydrique (ADR 0006)

## 22. Dictionnaire IFN des codes de texture `TEXT1`, `TEXT2` : vérifié

| Point | État | Commande / source | Résultat |
|---|---|---|---|
| Archive | **vérifié** | `curl -sSL -o data/cache/ifn/export_dataifn_2005_2025.zip https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip` | 71 136 669 octets, mêmes 20 fichiers qu'au § 7 (export du 2026-10-07). Gardée hors dépôt dans `data/cache/ifn/`. |
| Unités des colonnes | **vérifié** | `metadonnees.csv`, bloc « Définition des unités », lignes 376-379 | `TEXT1` et `TEXT2` : unité `TEXT` pour les campagnes **2005-2016**, unité `TEXT1` pour **2017 et suivantes** (« Estimation manuelle de la texture des horizons du sol »). `PROF1`, `PROF2` : unité `DM` (décimètre). `CAILLOUX` : `1/10PCT` (2005-2016), `1/10PCT_X` (2017-), en dixièmes du volume. |
| **Modalités** | **vérifié** | `metadonnees.csv`, bloc « Définition des modalités pour chaque unité », lignes 5845-5865 | `0` absence de terre fine ; `1` sable « S : sable dominant » ; `2` sable limoneux « Sl » ; `3` sable argileux « Sa » ; `4` limon sableux « **Ls, Lsa, Lms, Lls** : limon dominant + sable » ; `5` limon argileux « **La, Las** » ; `6` limon « **Lm, Ll** » ; `7` argile limoneuse « Al » ; `8` argile sablo-limoneuse « **As, Als** » ; `9` argile « **A, Alo** : argile et argile lourde » ; `H` texture organique (unité `TEXT1` seulement). Codes 0 à 9 identiques dans les deux unités. Un **espace insécable** (U+00A0) précède chaque « : ». |
| Triangle de référence | **déduit des abréviations** (l'IFN ne nomme pas le triangle) | `soiltexture::TT.get("FR.AISNE.TT")` | Les abréviations des codes 1 à 9 contiennent **les 15 classes du triangle de l'Aisne** (ALO, A, AL, AS, LA, LAS, LSA, SA, LM, LMS, LS, SL, S, LL, LLS), **chacune une fois** : les codes en forment une partition. Le triangle du GEPPA (`FR.GEPPA.TT`, 17 classes) n'a ni Lms, ni Lls, ni Lm, ni Alo. **Une abréviation est hors du triangle de l'Aisne : `Als`** (code 8), classe « argile limono-sableuse » du GEPPA. |
| Documentation | **vérifié** | `IGN_DB_doc_ecologie.pdf` (version 2.3, 14/10/2025), p. 6 | Texture appréciée **au toucher**. « Dans le cas d'un sol à texture homogène, TEXT1 = 0, et TEXT2 est renseigné. » Non renseignées sans fosse (`OBSPEDO` = 5). L'annexe `IGN_DB_doc_ecologie_annexes.pdf` (25 p.) ne contient pas de triangle. |
| Extrait déposé | **fait** | commande ci-dessous (lecture des deux blocs de `metadonnees.csv`) | `inst/extdata/ifn_texture_dictionnaire.csv` : colonnes `unite;campagnes;code;libelle;definition`, 21 lignes, texte d'origine (Licence Ouverte 2.0). |
| `TEXT1 = 0` avec `PROF1` renseigné | **vérifié** (décompte sur `ECOLOGIE.csv` complet, 131 704 lignes) | `e <- read.delim("ECOLOGIE.csv", sep = ";", colClasses = "character", na.strings = "", fileEncoding = "UTF-8-BOM"); sum(e$TEXT1 %in% "0" & !is.na(e$PROF1))` | `TEXT1 = 0` : 54 250 lignes, dont **54 193 avec `PROF1` vide** (sol homogène, lecture de la documentation) et **57 avec `PROF1` renseigné** (campagnes 2005 à 2015 ; `PROF1` de 0 à 8 dm ; `TEXT2` de 0 à 9). Ces 57 cas sont lus comme le dictionnaire le dit : **horizon supérieur sans terre fine** (« absence »), d'épaisseur `PROF1`, qui compte 0 mm de réserve utile ; l'horizon `TEXT2` couvre `PROF2 - PROF1`. Lecture du code (`ru_from_texture()`, `compute_gradients()`), non confirmée par l'IGN : **à vérifier**. Aucun de ces 57 cas dans les 100 placettes de `inst/extdata`. |

Commande d'extraction du dictionnaire (R, depuis `data/cache/ifn/`, après
`unzip export_dataifn_2005_2025.zip metadonnees.csv`) :

```r
l <- readLines("metadonnees.csv", encoding = "UTF-8"); l[1] <- sub("^﻿", "", l[1])
du <- grep("^// Définition des unités", l); dm <- grep("^// Définition des modalités", l)
sp <- function(x) do.call(rbind, strsplit(sub(";$", "", x), ";", fixed = TRUE))
u <- sp(grep("^TEXT[12];", l[(du + 2):(dm - 1)], value = TRUE))    # TEXTi;unite;campagnes;...
m <- sp(grep("^TEXT1?;", l[(dm + 2):length(l)], value = TRUE))     # unite;code;libelle;definition
per <- tapply(u[, 3], u[, 2], function(z) z[1])
out <- data.frame(unite = m[, 1], campagnes = trimws(per[m[, 1]]), code = m[, 2],
                  libelle = m[, 3], definition = m[, 4])
write.table(out, "ifn_texture_dictionnaire.csv", sep = ";", quote = TRUE, row.names = FALSE,
            fileEncoding = "UTF-8")
```
| Charge en cailloux | **vérifié** | `metadonnees.csv`, lignes 441-463 | `k` = 1 à 9 : de (10k - 5) % à (10k + 5) % ; `0` : moins de 5 % ; `10` : plus de 95 % ; `X` : absence (2017-). Le code prend le centre de la classe (2,5 %, 10k %, 97,5 %). |

## 23. Climat SAFRAN (SIM2 quotidien, Météo-France) : vérifié

| Point | État | Commande / source | Résultat |
|---|---|---|---|
| Jeu de données | **vérifié** | `https://www.data.gouv.fr/api/1/datasets/6569b27598256cc583c917a7/` | « Données changement climatique - SIM quotidienne », **licence `lov2`** (Licence Ouverte 2.0), 84 ressources. Mention : « Source : Météo-France ». |
| Fichiers | **vérifié** | même API | Un fichier par année, `https://meteofrance.s3.sbg.io.cloud.ovh.net/data/REF_CC/SIM/QUOT_SIM2_AAAA.csv.gz`, de 1958 à 2026 (+ `QUOT_SIM2_latest.csv.gz`), environ **137 Mo** par année (2024 : 137 936 316 octets ; 2015 : 136 900 395). Grille : `coordonnees_grille_safran_lambert-2-etendu.csv` (`LAMBX (hm);LAMBY (hm);LAT_DG;LON_DG`), `SIM2.shp`. Paramètres : `sim-quotidienne-parametres-20260331.pdf`. |
| Colonnes | **vérifié** | `zcat QUOT_SIM2_1996.csv.gz \| head -1` | `LAMBX;LAMBY;DATE;PRENEI;PRELIQ;T;FF;Q;DLI;SSI;HU;EVAP;ETP;PE;SWI;SSWI_10J;DRAINC;RUNC;RESR_NEIGE;RESR_NEIGE6;HTEURNEIGE;HTEURNEIGE6;HTEURNEIGEX;SNOW_FRAC;ECOULEMENT;WG_RACINE;WGI_RACINE;TINF_H;TSUP_H`, décimale point. `DATE` AAAAMMJJ ; `PRENEI`, `PRELIQ` précipitations solides et liquides (mm) ; `ETP` évapotranspiration potentielle Penman-Monteith (mm). **Sans le suffixe `_Q`** que supposent les défauts de `biljouR::safran_to_meteo()` (écart 19). |
| Coordonnées | **vérifié** | document des paramètres | `LAMBX`, `LAMBY` : Lambert II étendu en **hectomètres** (× 100 → EPSG:27572), maille 8 km. Mailles de l'emprise test (avec 8 km de marge) : **12** ; mailles des 100 placettes de `inst/extdata` : **9** (distance placette-centre de maille : 632 à 5 231 m). |
| Miroir INRAE | **vérifié : vide** | `biljouR::safran_dataverse_files()` (DOI `10.57745/BAZ12C`) | Deux fichiers seulement : `data-access.html`, `grid-SIM.gpkg`. **Aucun NetCDF par variable** : `biljouR::safran_download()` ne trouve rien à télécharger. Passer par les CSV annuels ci-dessus. |
| Cache | **fait** | `QUOT_SIM2_1996` à `2025` dans `data/cache/safran/` (hors dépôt), filtrés aux 12 mailles (`emprise_AAAA.csv`, 4 381 ou 4 393 lignes par année) | Période de calcul retenue : **1996-2025** (30 ans complets les plus récents, couvrant les campagnes IFN 2005-2025) : choix provisoire. |
| Extrait déposé | **fait** | `inst/extdata/safran_sim2_extrait.csv` | Maille `9640_23690` (centre de l'emprise, environ x = 1 014 550, y = 6 799 283 en Lambert-93), 2003-2004 (731 jours), colonnes `LAMBX;LAMBY;DATE;PRENEI;PRELIQ;ETP`, 21 Ko. |

## 24. Paquets de la chaîne hydrique : `soiltexture`, `euptf2`, `biljouR` : vérifié (exécuté)

| Point | État | Résultat |
|---|---|---|
| `soiltexture` | **vérifié** | CRAN, version **1.5.3**, licence AGPL (>= 3). `TT.get("FR.AISNE.TT")` : 29 sommets (`tt.points`, colonnes `CLAY`, `SILT`, `SAND` en fractions), 15 polygones (`tt.polygons`, `name`, `points`), limites granulométriques `0, 2, 50, 2000` µm (mêmes que `euptf2`). Les 15 polygones couvrent exactement le triangle (somme des aires 0,5 dans le plan argile-limon). `TT.points.in.classes(tri.data, class.sys, PiC.type = "t")` place le centre de gravité de chaque classe dans sa classe. |
| `euptf2` | **vérifié** | `remotes::install_github("tkdweber/euptf2")`, version **1.0.0**, commit `5075f33`, GPL-3. Szabó B., Weynants M., Weber T. K. D. (2021), *Geoscientific Model Development* 14 : 151-175 (prépublication `10.5194/gmd-2020-36`). Cibles (vignette) : `FC_2` θ à -100 cm (pF 2,0), `FC` à -330 cm (pF 2,5), `WP` à -15 000 cm (pF 4,2), `AWC_2` = `FC_2` - `WP`, `AWC` = `FC` - `WP`, en cm³/cm³. Prédicteurs : `USSAND`, `USSILT`, `USCLAY` (%), `DEPTH_M` (**profondeur moyenne en cm**, malgré le nom). `which_PTF()` rend **PTF01** pour granulométrie + profondeur. |
| `euptf2`, pièges | **vérifié** | `euptfFun()` et `load_PTF_object()` appellent `data()` sans `package =` : **échouent si le paquet n'est pas attaché** (« object 'suggested_PTF' not found ») et écrivent dans l'environnement global. Contournement exécuté : `utils::data(list = "AWC_2_PTF01", package = "euptf2", envir = e)` puis `euptf2::ptfFun.pred(e$AWC_2_PTF01, df)` ; mêmes valeurs qu'`euptfFun()` (0,2060 et 0,1563 sur deux points d'essai). `ranger` 0.18.0 avertit « Forest grown in ranger version <0.11.5, converting ». |
| `biljouR` | **vérifié** | `remotes::install_github("pobsteta/biljouR")`, version **0.1.0**, commit `b0dade7`, GPL-3, « réimplémentation indépendante, ni produite ni validée par l'INRAE ». `biljou_soil(ewm, roots = NULL, macro = NULL, micro = NULL, init = 1)` (1 à 3 couches, `ewm` > 0 en mm) ; `biljou_run(meteo, soil, lai_max, forest_type = c("broadleaved", "coniferous"), budburst = NULL, leaf_fall = NULL, rew_c = 0.4, k = 0.5, et_max_ratio = 1.2, wet_canopy_factor = 0.2, interception_coef = NULL)` ; `biljou_indices(run)` : par année, `NJstress` (jours REW < 0,4), `Istress` = somme (0,4 - REW) / 0,4 sur les jours de stress (définition de l'outil en ligne), `is_1999` (Granier et al. 1999, éq. 5), `DEBstress` ; pour les feuillus, sur la période feuillée seulement. `safran_to_meteo(df, cols = list(date = "DATE", rain_liq = "PRELIQ_Q", rain_sol = "PRENEI_Q", pet = "ETP_Q", ...))`. |

---

# Passe 5 (mission 020, 2026-11-18) : descente d'échelle hydrique

## 25. Descente d'échelle hydrique : moduler BILJOU par la topographie

> Note du 2026-11-18 : ce paragraphe a été rédigé pour la grille de 25 m. Depuis l'ADR 0007, lire
> `resolution_m` (20 m) ; les mesures historiques à 25 m sont laissées telles quelles.

- **Décision éclairée :** quelle grandeur la mission 021 module par la topographie (RU, ETP,
  rayonnement, apports latéraux) pour la carte de l'indice `Istress` à 25 m, par quelle
  équation, sans coefficient inventé.
- **Propriétaire :** Pascal (délégué à l'orchestrateur). Rédigé par l'agent `acquereur`,
  mission 020, consultation le **2026-11-18**.
- **Outils et limites :** `WebFetch` (pages résumées par un petit modèle : le code de
  `biljouR` n'a pas été recopié mot à mot, les signatures et constantes ci-dessous sont
  celles rendues par ce résumeur, à relire dans le source) et `WebSearch` ; un PDF lu **en
  images** (Dyer 2009, pages 391-400 sur 391-403) ; métadonnées des DOI par l'API Crossref
  (`https://api.crossref.org/works/<DOI>`). **Pas de R, rien d'exécuté.** **Refusés :**
  `hal.science` et `hal.archives-ouvertes.fr` (page anti-robot « Anubis », à chaque requête :
  les articles de Piedallu et Gégout n'ont pas été lus en texte intégral) ; `link.springer.com`
  (redirection vers authentification).

### 25.1 Ce que `biljouR` sait faire (commit `b0dade79d229817072d047724a47b2d6a8fa5970`)

Arbre lu par `https://api.github.com/repos/pobsteta/biljouR/git/trees/HEAD?recursive=1` :
61 entrées, 11 fichiers `R/`, 25 fichiers `man/`. Sources lues par
`https://raw.githubusercontent.com/pobsteta/biljouR/b0dade7…/R/<fichier>` : `simulate.R`,
`soil.R`, `fluxes.R`, `penman.R`, `io.R`, `safran.R`, `grid.R` (7 sur 11 ; non lus :
`biljouR-package.R`, `indices.R`, `plots.R`, `stats.R` ; aucun des 25 `.Rd` ne porte un nom
topographique).

| Point | État | Résultat |
|---|---|---|
| Terme topographique | **vérifié : absent** | Aucun argument ni calcul de pente, d'exposition, d'ombre, de ruissellement ou d'apport latéral dans `biljou_run()`, `biljou_soil()`, `safran_to_meteo()`, `penman_pet()`, `biljou_run_grid()`. Le drainage est l'excès au-dessus de la capacité au champ (`.infiltrate()`, corps non lu) ; il sort du profil. |
| ETP | **vérifié** | `biljou_run()` prend `meteo$pet` tel quel (colonnes requises `pet`, `rain`, et `date` ou `doy`) : **toute modulation de l'ETP se fait en amont, dans la table `meteo`.** |
| Point d'entrée du rayonnement | **vérifié** | `safran_to_meteo(df, cols = list(date = "DATE", rain_liq = "PRELIQ_Q", rain_sol = "PRENEI_Q", pet = "ETP_Q", tmean = "T_Q", rg = "SSI_Q", wind = "FF_Q", rh = "HU_Q"), compute_pet = FALSE, latitude = NULL, altitude = 0, keep_raw = FALSE)`. Avec `compute_pet = TRUE` (exige `latitude`), l'ETP est recalculée par `penman_pet()` avec le vent ramené à 2 m par `wind_to_2m(wind, 10)`. |
| `penman_pet()` | **vérifié** (résumé) | `penman_pet(tmean, rg, wind, rh = NULL, ea = NULL, vpd = NULL, doy = NULL, latitude = NULL, altitude = 0, albedo = 0.2)` ; `rg` en **MJ m⁻² j⁻¹** (la doc dit : valeurs Météo-France en J cm⁻² × 0,01) ; fonction du vent `6.43 * (1 + 0.536 * wind)` ; références Penman 1948, Shuttleworth 1993, FAO-56 (Allen et al. 1998) pour le rayonnement net. Rayonnement extraterrestre calculé sur **surface horizontale** (latitude, jour) ; `altitude` ne sert qu'à la pression et au ciel clair. Sans `doy` ou `latitude` : grandes ondes nulles, avertissement. |
| Grille | **vérifié** | `biljou_run_grid(points, meteo, soil, lai_max, forest_type, budburst = NULL, leaf_fall = NULL, indicators = c("NJstress", "Istress", "DEBstress", "min_rew", "drainage"), years = NULL, id_col = "id", lon_col = "lon", lat_col = "lat", verbose = TRUE, ...)` ; `meteo`, `soil`, `lai_max`… acceptent une valeur, une fonction par point ou une liste nommée par identifiant. `biljou_grid_to_raster(grid, indicator = NULL, year = NULL, crs = "EPSG:4326")` suppose une grille régulière. **Coordonnées en lon/lat par défaut, non contrôlées** : en Lambert-93, passer `crs = "EPSG:2154"`. |
| SAFRAN | **vérifié** | Les colonnes `T`, `FF`, `HU`, `SSI` existent dans les CSV SIM2 (§ 23), sans suffixe `_Q` (écart 19). Unité de `SSI` : J cm⁻² selon la doc de `penman_pet()` et selon un tiers (`https://geop4th-d6fd42.gitlab.io/4_workflows/dataset_workflows/sim2.html`) ; **le document de Météo-France (`sim-quotidienne-parametres-20260331.pdf`) n'a pas été relu : à vérifier.** Relu le 2026-11-18 (mission 021) : J/cm2 confirmé, voir § 25.8. |

### 25.2 Méthodes publiées, comparées (CQQCOQP)

| | **A. Rayonnement topographique → ETP** (retenue) | **B. Rayonnement horizontal mesuré → pente** (outil de A) | **C. Apports latéraux par l'indice topographique (TOPMODEL)** | **D. Hauteur au-dessus du drainage (HAND)** |
|---|---|---|---|---|
| **Pourquoi** | Demande en eau selon l'exposition | Passer du `SSI` SAFRAN (horizontal, nuageux) à la pente | Eau reçue de l'amont | Proximité de la nappe |
| **Qui, quoi** | Dyer J. M. (2009), « Assessing topographic patterns in moisture use and stress using a water balance approach », *Landscape Ecology* 24 : 391-403, DOI `10.1007/s10980-008-9316-6`, PDF de l'auteur `https://people.ohio.edu/dyer/WB/Dyer_2009_LandEcol.pdf` (lu, p. 391-400) | Allen R. G., Trezza R., Tasumi M. (2006), « Analytical integrated functions for daily solar radiation on slopes », *Agricultural and Forest Meteorology* 139 : 55-73, DOI `10.1016/j.agrformet.2006.05.012` (**résumé seulement**, relayé par recherche) ; GRASS `r.sun` : Šúri M., Hofierka J. (2004), « A New GIS-based Solar Radiation Model and Its Application to Photovoltaic Assessments », *Transactions in GIS* 8(2) : 175-190, DOI `10.1111/j.1467-9671.2004.00174.x` (Crossref) | Beven K. J., Kirkby M. J. (1979), *Hydrological Sciences Bulletin* 24(1) : 43-69, DOI `10.1080/02626667909491834` (Crossref, non lu) ; relu dans Beven, Kirkby, Freer, Lamb (2021), « A history of TOPMODEL », *HESS* 25 : 527-549, DOI `10.5194/hess-25-527-2021`, CC BY 4.0 (100 000 premiers caractères sur 149 060) | Nobre A. D. et al. (2011), « Height Above the Nearest Drainage – a hydrologically relevant new terrain model », *Journal of Hydrology* 404(1-2) : 13-29, DOI `10.1016/j.jhydrol.2011.03.051` (Crossref, non lu) |
| **Grandeur modulée** | ETP (via le rayonnement global reçu par la pente) | Rayonnement global journalier | Déficit de stockage local (apport) | Aucune dans BILJOU ; classe d'engorgement |
| **Variable topo** | Pente, exposition, ombres portées | Pente, exposition, latitude, ombres (`r.sun`), part diffuse | ln(a / tan β) (TWI) | HAND |
| **Équation** | Dyer, éq. (1) p. 396 (Turc 1961) : PET = 0,013 [T / (T + 15)] (R_s + 50), PET mensuelle (mm), T (°C), **R_s rayonnement global reçu par la cellule (cal cm⁻²)**, calculé par l'outil « Solar Radiation » d'ArcGIS (pente, exposition, ombres), paramètres de part diffuse D et transmissivité T calés sur une mesure (pas 0,1 ; D 0,2-0,7 ; T 0,3-0,7) | `r.sun` (manuel GRASS 8.5, `https://grass.osgeo.org/grass-stable/manuals/r.sun.html`) : `glob_rad` (Wh m⁻² j⁻¹) = direct + diffus + réfléchi, entrées `elevation`, `slope`, `aspect` (convention : **270 = sud**), `linke` (défaut 3,0), `albedo` (défaut 0,2), `day`, `step` (défaut 0,5 h) ; ombres par défaut (`-p` les retire) ; ciel réel par `coeff_bh`, `coeff_dh` (0-1, « fraction of the respective clear-sky radiations reduced by atmospheric factors »), formule renvoyée à Šúri et Hofierka 2004, § 3.2 (non lu). Allen et al. 2006 : conversion du rayonnement horizontal mesuré vers la pente, **équations non lues** | Flux q = T₀ tan β exp(−D / m) (éq. 6) ; saturation si ln(a / tan β) > D̄ / m + λ (éq. 7, signe à relire sur le PDF) ; d'où D_i = D̄ − m [ln(a / tan β) − λ] (**dérivé, pas écrit dans l'article**). `m` (profondeur) et T₀ **à caler par bassin** | Classes calées en Amazonie (seuils non lus) |
| **Où, résolution** | Ohio (MNT 0,7 m) et Caroline du Nord, Coweeta (3,5 m), forêts feuillues tempérées | Ponctuel à MNT | Petits bassins versants à sol mince | Amazonie centrale |
| **Validation** | Humidité du sol mesurée, mensuelle : r = 0,92 à 0,97 (9 sondes, Caroline du Nord) ; 0,75 à 0,98, moyenne 0,90, 17 sur 19 significatives après décalage d'un mois (Ohio) (p. 398-399). Contraste mesuré par le modèle : PET 926 mm (versant SE 30°) contre 656 mm (N 34°), −29 % ; 865 contre 692 mm (−20 %) (p. 398-399) | Allen : deux sites américains (résumé) | Beven et al. 2021 : hypothèses valides pour **un sous-ensemble** de bassins ; inadaptées aux sols profonds et zones plates ; en période sèche, c'est l'évapotranspiration qui commande l'humidité de surface | — |
| **Ce qu'en dit le terrain** | Dyer p. 399-400 : **aucune relation** entre la position topographique et l'écart modèle-mesure ; « the inclusion of topographic augmentation of available water into the model via upslope drainage is not warranted, at least if a goal is to model soil moisture patterns during the growing season » (p. 400), en citant Western et al. 2002 (non lu) | — | Voir A : apports non décelés en saison de croissance, période qui fait `Istress` | — |
| **Code R** | Aucun paquet : à écrire (Turc) ou **remplacer Turc par `biljouR::penman_pet()`** | GRASS `r.sun` (GRASS déjà utilisé pour le MRVBF, `R/terrain.R`) ; pas de paquet R vérifié | `topmodel` (CRAN) **archivé le 2024-11-11** ; TWI déjà calculé (`twi`) | HAND déjà calculé (`hauteur_reseau`) |
| **Licence du code** | — | GRASS : licence **à vérifier** (non relue ce jour) | — | — |

**Contexte français, lu en notice seulement.** Piedallu C., Gégout J.-C. (2008), « Efficient
assessment of topographic solar radiation to improve plant distribution models »,
*Agricultural and Forest Meteorology* 148(11) : 1696-1706, DOI
`10.1016/j.agrformet.2008.06.001` (Crossref) : sur la France entière avec un MNT de 50 m, le
rayonnement **avec nébulosité** s'ajuste mieux au rayonnement annuel mesuré que le ciel clair
(R² 0,78 contre 0,46 ; 88 stations), et le sinus ou cosinus de l'exposition fait mal sur de
grandes surfaces (chiffres relayés par la recherche web depuis la notice HAL `hal-00835905`,
**article non lu**). Piedallu C., Gégout J.-C., Perez V., Lebourgeois F. (2013), « Soil water
balance performs better than climatic water variables in tree species distribution
modelling », *Global Ecology and Biogeography* 22(4) : 470-482, DOI `10.1111/geb.12012`
(résumé Crossref lu) : bilan hydrique du sol à **1 km** sur la France, meilleur que les
proxys climatiques pour 82 % des modèles d'espèces ; **ce n'est pas une descente à 25 m.**
Piedallu C., Gégout J.-C., Bruand A., Seynave I. (2011), *Geoderma* 160(3-4) : 355-366, DOI
`10.1016/j.geoderma.2010.10.004` (carte de réserve utile ; titre seul lu). Piedallu C.,
Gégout J.-C. (2007), « Multiscale computation of solar radiation for predictive vegetation
modelling », *Annals of Forest Science* 64(8) : 899-909, DOI `10.1051/forest:2007072`
(Crossref ; article non lu : HAL refusé, Springer derrière authentification).

**RU modulée par la topographie : aucune méthode publiée simple trouvée.** Aucune source
lue ne donne un coefficient reliant la réserve utile à la pente, à la position ou au TWI en
forêt tempérée française. Un tel lien ne peut pas être appris sur les placettes IFN avec des
variables extraites du MNT (règle des 700 m). Seule piste qui respecte la règle : les
observations **notées sur place** par l'IFN (`PENT2`, `TOPO`, référentiels § 7,
`obs_pente`, `obs_topo` de `R/pipeline_reel.R`) ; mais la correspondance entre les codes
`TOPO` et une position calculée sur le MNT n'est publiée nulle part : **piste, ne pas coder.**

### 25.3 Variables de sylvostation : entrées présentes et manquantes

`derive_terrain()` (`R/terrain.R`, l. 112-162) rend 14 couches par défaut : `pente`,
`exposition_cos`, `exposition_sin`, `courbure`, `courbure_plan`, `courbure_profil`, `tpi_100`,
`tpi_300`, `tpi_1000`, `twi`, `surface_drainee`, `mrvbf`, `hauteur_reseau`, `rayonnement`.

| Entrée de la méthode A | Dans sylvostation | Manque |
|---|---|---|
| Pente, exposition | `pente` (degrés), `exposition_cos/sin` (azimut depuis le nord, horaire) | Conversion vers `r.sun` (270 = sud ; azimut GRASS déduit = (450 − azimut horaire depuis le nord) mod 360 : **à vérifier**) |
| Rayonnement par jour ou par mois sur la pente | `rayonnement` : **somme annuelle**, direct seul, **hors atmosphère, sans ombres ni diffus** (l. 89-92) | Rayonnement global (direct + diffus) **par jour type ou par mois**, avec ombres portées : `r.sun` |
| Rayonnement horizontal de référence | — | Même calcul, pente nulle (`slope_value = 0`) |
| `SSI`, `T`, `FF`, `HU` SAFRAN | lus seulement `PRELIQ`, `PRENEI`, `ETP` (`hydric_stress()`, `R/hydrique.R` l. 451) | Lire `SSI`, `T`, `FF`, `HU` des CSV SIM2 (§ 23) |
| RU sur la grille de 25 m | **aucune source** : `ru_from_texture()` ne vaut qu'aux placettes ; § 18 : BDGSF 1/1 000 000 trop grossière, GlobalSoilMap 90 m non lu | **Entrée manquante, sans source à 25 m** |
| TWI, HAND, MRVBF (méthodes C, D) | `twi`, `hauteur_reseau`, `mrvbf` | Rien pour BILJOU : non retenues |

### 25.4 Recommandation : méthode A, rayonnement par `r.sun`, ETP par `biljouR`

**Adaptation non validée de Dyer 2009** : **moduler l'ETP par le rayonnement global reçu par
la pente**, sans apport latéral (Dyer 2009, p. 400). Dyer valide une ETP de Turc mensuelle
(éq. 1, p. 396) avec un rayonnement **en ciel réel**, dont la part diffuse D et la
transmissivité T sont calées sur des mesures (p. 396). Ici, k est calculé en ciel clair, puis
l'ETP par le Penman de `biljouR` : rien de ce passage n'est validé (§ 25.5). Dans ce Penman,
seul le terme radiatif suit `rg` ; le terme aérodynamique n'est pas modulé. Selon la
relecture du 2026-11-18 (non relu par l'acquéreur dans le source), le rapport `rg/rso` des
grandes ondes y utilise un rayonnement extraterrestre horizontal, plafonné à 1 : modifier
`rg` modifie donc aussi les grandes ondes. Le seul changement dans BILJOU est la colonne
`pet` de `meteo`.

1. Facteur topographique mensuel, par cellule `x` de la grille de 25 m et par mois `j` (jour
   type) : k(x, j) = G_r.sun(x ; pente, exposition, ombres) / G_r.sun(x ; pente 0), avec
   `r.sun` en ciel clair (`coeff_bh`, `coeff_dh` absents).
2. Rayonnement du jour d sur la cellule : rg(x, d) = SSI(maille, d) × 0,01 × k(x, mois de d)
   (SSI en J cm⁻² → MJ m⁻², unité à vérifier, § 25.1).
3. ETP du jour : `biljouR::penman_pet(tmean = T, rg = rg(x, d), wind = wind_to_2m(FF, 10),
   rh = HU, doy, latitude, altitude)`, c'est-à-dire `safran_to_meteo(..., compute_pet = TRUE)`
   sur une colonne `SSI` remplacée. Pour que la seule différence entre cellules soit
   topographique, le plat de référence est calculé **par la même formule** (k = 1), pas pris
   dans l'`ETP` SAFRAN (Penman-Monteith, § 23).
4. `Istress(x)` = BILJOU(ETP(x), P(maille), RU(x)). Calcul : table par maille SAFRAN sur une
   suite de RU **et** une suite de k (extension de l'interpolation de `hydric_stress()`).

**Ce que la méthode ne capte pas (limites).** (a) Les apports latéraux et l'engorgement des
fonds de vallon : un vallon frais n'y est plus humide que par l'ombre ; l'engorgement reste
à porter par `hauteur_reseau`, `twi` ou `mrvbf` hors de BILJOU. (b) Le ratio de ciel clair
appliqué au rayonnement nuageux surestime le contraste d'exposition (la part diffuse, moins
sensible à l'exposition, croît avec la nébulosité) : c'est ce que corrigent Allen et al. 2006
et les `coeff_bh`, `coeff_dh` de `r.sun`, non lus. Dyer (2009, p. 400) en fait la mise en
garde : les estimations fondées sur la pente, l'exposition et la latitude « often represent
"clear sky" estimates. Especially in humid environments, the diffuse proportion and
transmittivity parameters can be significantly different than clear sky conditions. » (c) La température et le vent SAFRAN sont
ceux de la maille de 8 km (pas de correction d'altitude ni de vent local). (d) Dyer valide
sur deux sites américains, Turc mensuel, une année chacun ; **aucune validation française à
25 m n'a été lue.** (e) La RU à 25 m n'a pas de source (§ 25.3).

### 25.5 Valeurs provisoires (à nommer « provisoire » dans le code)

| Valeur | Proposée | Pourquoi provisoire |
|---|---|---|
| Ciel clair pour k (`coeff_bh`, `coeff_dh` absents) | oui | Ciel réel non lu (Šúri et Hofierka 2004, § 3.2 ; Allen et al. 2006) ; Dyer calcule en ciel réel (D, T calés, p. 396) et met en garde contre le ciel clair en milieu humide (p. 400) |
| Passage de Turc (Dyer, éq. 1) au Penman de `biljouR` | oui | Non validé : Dyer ne valide que Turc mensuel ; dans Penman, le terme aérodynamique n'est pas modulé et `rg` touche aussi les grandes ondes (§ 25.4) |
| Trouble de Linke | 3,0 (défaut du manuel `r.sun`) | Valeur par défaut, pas une mesure vosgienne |
| Albédo | 0,2 (défaut de `r.sun` et de `penman_pet()`) | Surface de référence, pas la forêt |
| Jour type par mois | jours de Klein 1977 (`.JOURS_TYPES`, `R/terrain.R` l. 315) | Choix d'échantillonnage, k constant dans le mois |
| Unité `SSI` | J cm⁻² (× 0,01) | Document de Météo-France non relu ; **vérifié le 2026-11-18** (§ 25.8), la valeur n'est plus provisoire |
| RU de la grille | aucune proposée par cette mission | **à trancher** : pas de source à 25 m |
| Pas des suites de RU et de k | — | Réglage de calcul, à mesurer (écart à un calcul cellule par cellule) |

### 25.6 Règle bloquante

`k(x, j)`, `pente`, `exposition` et tout `r.sun` sont des **variables fines** : elles ne
s'appliquent qu'à la grille de 25 m et aux points de `loc_precision_m` ≤ 25 m, **jamais aux
placettes IFN** (`assert_no_fine_extract_on_ifn()`). Aux placettes IFN, `Istress` reste
calculé sur la maille SAFRAN et la RU de la placette, sans k (`hydric_stress()` actuel). La
carte modulée et les placettes ne sont donc pas sur la même échelle : l'écart attendu doit
être dit dans l'état de preuve.

### 25.7 Trois points au sol (à choisir par Pascal dans la SER D11)

1. **Deux versants opposés de même sol**, raides (plus de 30°), sud et nord : la modulation y
   est la plus forte. Aucun écart chiffré n'est attendu : les contrastes de Dyer ne se
   transposent pas (son −20 % de l'Ohio compare une crête exposée à l'est, pente 2°, à un
   vallon exposé au nord, pente 24° ; p. 398-399). Juger si l'écart de flore suit.
2. **Un fond de vallon étroit** (TWI fort, `hauteur_reseau` faible) : la méthode A ne lui
   donne aucun apport ; si la flore y est hygrophile alors que la carte le dit sec, c'est la
   limite (a).
3. **Une crête ou un col dégagé face à un versant encaissé au nord** : c'est là que `r.sun`
   (avec ombres) et la couche `rayonnement` actuelle (sans ombres) divergent le plus.

### 25.8 Vérifié en mission 021 (2026-11-18, exécuté en R)

| Point | État | Résultat |
|---|---|---|
| Unité de `SSI` | **vérifié** | Document Météo-France, titre exact en tête de page « Données quotidiennes SIM » (pas de titre dans les métadonnées du PDF ; 2 pages, auteur Marie PRALAT, créé le 2026-03-31, 340 950 octets, SHA-256 `8f1ec72f…4c8b`), lu dans le cache local `data/cache/safran/params.pdf` (hors dépôt) ; **adresse de téléchargement à vérifier** (non relevée lors du téléchargement du 2026-11-17 ; nom probable `sim-quotidienne-parametres-20260331.pdf`, § 25.1) : `SSI` « Rayonnement visible », **J/cm2**, cumul quotidien ]00UTC-00UTC] ; `DLI` « Rayonnement atmosphérique », J/cm2 ; `FF` vent, **m/s**, moyenne quotidienne ; `HU` humidité relative, **%** ; `T` °C ; `ETP` « formule de Penman-Monteith FAO-56 », mm. Conversion : × 0,01 vers MJ m⁻². Hauteur du vent `FF` non donnée par le document (biljouR suppose 10 m) : **à vérifier**. Le libellé « visible » est lu comme le rayonnement global de courte longueur d'onde : **à vérifier**. Sur l'extrait de 12 mailles (2003-2004), `SSI` va de 64,8 à 3 225,4 J/cm2 et ne dépasse jamais le rayonnement extraterrestre du jour (FAO-56). |
| `r.sun` (GRASS 8.4.2) | **vérifié** (`r.sun --help`) | `aspect_value` « 270 is south » ; `-p` retire les ombres ; `linke_value` 3,0 et `albedo_value` 0,2 par défaut ; `nprocs`. Latitude calculée par `r.sun` depuis la projection du projet (EPSG:2154) : rayonnement du plat de 6,3 MJ m⁻² environ à 48° N à la mi-janvier, plausible. Conversion d'exposition (450 − azimut) mod 360 **vérifiée par test** : sur un relief synthétique à 30°, k de janvier = 2,2 au versant sud, 0,24 au versant nord, environ 1 au plat ; juin : 0,99 et 0,80. |
| Coût de `r.sun` | **mesuré** | 3 fils : 4,1 s par jour type avec ombres et 0,9 s pour le plat sur 360 000 cellules de 25 m (225 dalles), soit environ une minute pour 12 mois ; à 5 m (9 M cellules), plus de 10 min 47 s pour un seul jour (arrêté) : calcul à 25 m retenu. |
| `biljouR::penman_pet()` (0.1.0) | **vérifié** (source affichée en R) | `rg` en MJ m⁻² j⁻¹ ; `safran_to_meteo(compute_pet = TRUE)` passe `rg` tel quel (aucune conversion d'unité) et ramène le vent à 2 m par `wind_to_2m(FF, 10)` ; `ratio = pmin(rg / rso, 1)` avec `rso = (0,75 + 2e-5 altitude) Ra` : au-delà de `rso`, les grandes ondes ne suivent plus `rg`. |
| Écart table / calcul direct | **mesuré** | Run hors ligne (une dalle réduite, maille `9640_23610`, 2003-2004, 4 cellules de contrôle) : écart moyen 0,06, maximal 0,16 pour un Istress de 77,6 (0,08 %). Relief synthétique à 30° (6 084 cellules, 30 cellules de contrôle) : écart moyen 0,004, maximal 0,015 pour 24,1. Aucun seuil bloquant. |

---

# Passe 6 (mission 024, 2026-11-18) : cartes de comparaison

## 26. Cartes de comparaison (stations, habitats, végétation) sur l'emprise test

- **Décision éclairée :** quelle référence ouverte, au format SIG, sert à comparer la carte des
  stations de D11 sur l'emprise test, et selon quel protocole (matrice de confusion par types
  regroupés ou corrélation des gradients).
- **Rédigé par :** agent `acquereur`, le 2026-11-18. **Propriétaire :** Pascal (délégué à
  l'orchestrateur).
- **Outils :** `WebSearch`, `WebFetch` (résumeur : les `numberMatched` et `timeStamp` sont ceux
  du serveur ; les listes d'entités de 140 lignes au plus sont comptées par le résumeur), PDF
  enregistrés par l'outil et lus en image page par page. **Rien d'exécuté en R, rien téléchargé
  dans le dépôt.** GeoPackage de Pascal (`guides-stations-forestieres.gpkg`) : **lu par
  l'orchestrateur et le relecteur (`ogrinfo`)** ; les identifiants, titres, dates, statuts et URL
  des guides viennent de cette lecture, transmise à l'agent.
- **Règle des 700 m : non concernée.** La comparaison se fait de grille à grille ; aucune
  extraction n'a lieu aux placettes IFN, et les relevés des CBN qui entraînent CarHab ne sont pas
  utilisés.
- **Hôtes joints :** `data.geopf.fr` (WFS, CSW, WMS-R), `www.ecologie.gouv.fr`, `www.patrinat.fr`,
  `assets.patrinat.fr`, `digitale.cbnhdf.fr`, `inventaire-forestier.ign.fr`, `cloud.cnpf.fr`.
  **Refusés ou muets :** `inpn.mnhn.fr` (HTTP 500 ou page « Visualisateur CarHab » vide, y compris
  pour la notice du Haut-Rhin), `hal.science` (page anti-robots « Access Denied »),
  `www.grand-est.developpement-durable.gouv.fr` (HTTP 403 sur les PDF des DOCOB),
  `cartes.gouv.fr` (page vide sans JavaScript).
- Abréviation : `EMPRISE` = `CQL_FILTER=INTERSECTS(geom,SRID=2154;POLYGON((1007000 6790000,1022000 6790000,1022000 6805000,1007000 6805000,1007000 6790000)))`.

### 26.1 Cartes trouvées

| Carte | État | Producteur, année | Format, accès vérifié | Licence | Échelle | Nomenclature | Part de l'emprise |
|---|---|---|---|---|---|---|---|
| **CarHab, habitats du Haut-Rhin (68)** | **vérifié** (service interrogé) | PatriNat (OFB-MNHN-CNRS-IRD), IGN, EVS (univ. Saint-Étienne), CBN ; métadonnée publiée le 2023-06-01 ; livrable départemental « Version : Juin 2024 » (dictionnaire de l'Aisne, p. 4, même série) | WFS `WFS&REQUEST=GetFeature&TYPENAMES=Carhab_habitat:habitats_carhab` (trouvé par `GetCapabilities&NAMESPACE=Carhab_habitat` : un seul type, `DefaultCRS` EPSG:2154) ; GeoPackage départemental `https://assets.patrinat.fr/files/donnees/carhab/CarHab_68_Haut-Rhin.zip` (répond ; **528 030 697 octets**, environ 528 Mo, d'après le `content-length` relevé par l'orchestrateur ; contenu non ouvert ; **jamais dans `inst/extdata`** ; la page PatriNat dit ces liens « temporaires » et annonce une redirection vers `https://inpn.mnhn.fr/donnees-outils/donnees-SIG/CarHab` d'ici début 2027) ; téléchargement Géoplateforme `https://data.geopf.fr/telechargement/resource/CARHAB` (lu dans la métadonnée, non ouvert) | **Licence Ouverte / Open License** (Etalab), métadonnée CSW `https://data.geopf.fr/csw?SERVICE=CSW&VERSION=2.0.2&REQUEST=GetRecordById&ID=INPN-CARHAB_HABITATS&OUTPUTSCHEMA=http://www.isotc211.org/2005/gmd&ELEMENTSETNAME=full` ; `useLimitation` « Aucune contrainte » | 1/25 000 ; variables au pas de 10 m ; polygones d'au moins 0,5 ha (5 000 m²) | 1 habitat = 1 physionomie (code à 4 chiffres, 26 postes) × 1 biotope (code à 6 chiffres, 8 paramètres : littoralité, étage de végétation, ombroclimat, variante bioclimatique, enneigement, continentalité, **acidité édaphique**, **humidité édaphique**) ; correspondances EUNIS 2012 et HIC dans un GeoPackage séparé du livrable | **97,47 % de l'emprise** (part du département, § 5 : 219,302 / 225 km²), toute l'emprise avec 67 et 88 ; décomptes au § 26.2 |
| CarHab, Bas-Rhin (67) et Vosges (88) | **vérifié** (lien de téléchargement listé) ; présence dans le WFS **non attribuée** | idem | `https://assets.patrinat.fr/files/donnees/carhab/CarHab_67_Bas-Rhin.zip`, `…/CarHab_88_Vosges.zip` (liens lus sur la page PatriNat, non ouverts) | idem | idem | idem | 67 : 3,931 km², 88 : 1,768 km² (§ 5). Dans le WFS, `layer LIKE 'CarHab_67%'` et `'CarHab_88%'` → 0 ; **126** polygones de l'emprise ont `layer` = `habitats_carhab` (93) ou vide (33) : département non dit. |
| Cartes d'habitats des DOCOB Natura 2000 « Hautes-Vosges » (secteurs Tanet-Deux Lacs, Hohneck, etc.) | **piste** (titres de PDF par la recherche ; PDF refusés, 403) | PNR des Ballons des Vosges, 2005-2008 (ex. « Réalisation : PNRBV / FD - Fonds de carte IGN - Janvier 2007 », extrait de recherche) | **PDF seulement** ; aucune couche SIG publiée trouvée (data.gouv.fr, DataGrandEst non trouvés) | non dite | non dite | Habitats d'intérêt communautaire (codes Natura 2000) | **Non mesurée** : aucun secteur n'a pu être situé par rapport à l'emprise (le secteur Tanet-Deux Lacs est probablement à l'ouest, hors emprise : déduction, non vérifiée). |
| BDGveg_FR (carte de la végétation du CNRS numérisée) | **piste** (résumés : Leguédois et al., *Cybergeo* 2011, `https://hal.archives-ouvertes.fr/hal-01018998/file/LeguedoisCybergeo2011.pdf`, non lu) | CNRS, feuilles de 1947-1991 | scan géoréférencé 1/200 000 ; vecteur harmonisé de végétation potentielle 1/1 000 000 ; diffusion actuelle non vérifiée | non vérifiée | 1/200 000 et 1/1 000 000 | Séries de végétation | Toute l'emprise, mais trop grossière pour une grille de 25 m. |
| Carte prédictive AgroParisTech (Gégout et al. 2008) | **non diffusée** (§ 21) | AgroParisTech | — | — | 50 m | 59 types | Le massif vosgien ; référence du brief (§ 9), non ouverte. |

**Rien trouvé** : aucune carte de stations forestières levée sur le terrain (ONF, CNPF) publiée au
format SIG sur l'emprise ; les recherches web ne renvoient que des documents d'aménagement en PDF.

### 26.2 CarHab sur l'emprise : décomptes (WFS, 2026-11-18, entre 11:10 et 11:13 UTC)

Polygones **qui recoupent** le carré (non découpés : un polygone à cheval compte en entier). Ce
sont des **nombres de polygones, pas des surfaces** : les surfaces exigent le téléchargement.

| Requête (`WFS&REQUEST=GetFeature&TYPENAMES=Carhab_habitat:habitats_carhab&RESULTTYPE=hits&…`) | `numberMatched` |
|---|---|
| `BBOX=1007000,6790000,1022000,6805000,EPSG:2154` | 6 378 |
| `EMPRISE` | **6 376** |
| `EMPRISE AND layer LIKE 'CarHab_68%'` | 6 250 (reste 126, voir § 26.1) |
| `EMPRISE AND occupation='foret'` | **3 103** |

Forêt (`occupation='foret'`, 3 103 polygones), par modalité (sommes vérifiées : 3 103 chacune) :

| Paramètre | Modalités (nombre de polygones) |
|---|---|
| `acidite_edaphique` | `très acide` 1 166 ; `légèrement acide` 1 375 ; `neutre` 495 ; `basique` 67 |
| `humidite_edaphique` | `assez sec` 786 ; `mésique` 1 416 ; `humide à nappe circulante` 761 ; `légèrement humide` 127 ; `détrempé à nappe stagnante` 13 (ces deux derniers comptés par le résumeur sur 140 entités renvoyées) |
| `etage_de_vegetation` | `collinéen` 1 970 ; `montagnard` 1 130 (= 3 103 − 1 970 − 3) ; `subalpin` 3 (biotope `132022`, très acide, mésique) |

**Schéma** (`DescribeFeatureType`, 36 éléments) : `id_polygone_carhab`, `code_hab_carhab`,
`nom_complet_hab`, `nom_simplifie_hab`, `code_biotope`, `littoralite`, `etage_de_vegetation`,
`ombroclimat`, `continentalite`, `variante_bioclimatique`, `acidite_edaphique`,
`humidite_edaphique`, `enneigement`, `code_physio`, `nom_physio`, `physio_source`,
`physio_info_comp`, `physio_majoritaire`, `pourc_physio_maj`, `occupation`, `milieu`,
`biotope_minoritaire`, `pourc_biot_min`, `cd_biot_mod`, `surface` (double), `commentaire`,
`cd_hab`, `id_sinp_evenement`, `id_sinp_habitat`, `layer`, `path`, `geom`
(`gml:MultiSurfacePropertyType`), `conformite_physio_departementale`,
`conformite_biotope_departementale`, `commentaire_conformite_physio_departementale`,
`commentaire_conformite_biotope_departementale`. Tous texte sauf `surface` et `geom`. Les quatre
champs de conformité sont `null` sur les 20 entités lues (`BBOX=1013000,6797000,1014000,6798000`) ;
leur décompte sur l'emprise a échoué (le serveur a renvoyé une page de métriques Prometheus) :
**non vérifié**.

**Méthode CarHab** (webinaire du ministère, `https://www.ecologie.gouv.fr/sites/default/files/documents/Me%CC%81thodologie_CarHab.pdf`, 20 avril 2023, diapositives 6, 8, 14, 21, 22 ; dictionnaire de l'Aisne,
`https://digitale.cbnhdf.fr/aide/CarHab_02_Aisne_LISEZ_MOI_metadonnees_dictionnaire.pdf`, juin 2024, p. 4-9) :
biotopes prédits par forêt aléatoire supervisée sur des polygones d'entraînement des CBN, à partir
de **RGE ALTI 5 m, BD TOPAGE, AURELHY 1971-2000, géologie BRGM 1/50 000 harmonisée, SoilGrids
250 m** ; physionomies par Sentinel-2, BD Ortho IRC, BD Forêt V2, BD TOPO, RPG. Le ministère écrit :
« Cartes des Biotopes et Physionomies de végétation = Cartes prédictives », à utiliser « comme une
information de potentialité », « pas adapté » « pour des analyses fines au niveau communal ».
**Notice du Haut-Rhin** (`https://inpn.mnhn.fr/viewer-carto/CarHab/geoserver/www/CarHab_68_Haut-Rhin_Notice.pdf`) :
**inaccessible** à l'agent ; d'après les extraits du moteur de recherche seulement (non lus) :
juin 2024, « 34 biotopes » traités sur « 54 présents », les 20 autres aquatiques et amphibies.

### 26.3 Guides du GeoPackage de Pascal qui recoupent l'emprise

| id | Titre (consigne) | Statut (consigne) | Lien | État du lien | Contenu |
|---|---|---|---|---|---|
| 94 | Le choix des essences forestières dans les Vosges alsaciennes (1993) | actif | `https://cloud.cnpf.fr/index.php/s/d4y6bMj9r5TeZei` | **répond** ; partage Nextcloud d'un fichier nommé **`ClimVosges.pdf`** (taille et date non affichées) : le nom ne correspond pas au titre, **à vérifier** | non lu |
| 95 | même titre | obsolète | `https://inventaire-forestier.ign.fr/typologie_stations/typo/consultation/GS_vosges-alsaciennes.pdf` | **répond**, fichier de plus de 10 Mo (limite de l'outil), non lu | non lu |
| 97 | Le choix des essences forestières dans les Vosges cristallines lorraines (1995) | obsolète | `https://inventaire-forestier.ign.fr/typologie_stations/typo/consultation/GS_vosges-cristallines-lorraines.pdf` | **vérifié** : PDF scanné, 52 pages, lu en image p. 1-14 | Guide du CRPF de Lorraine-Alsace. **Clé de détermination et fiches, pas de carte des stations** (« la clé de détermination des stations forestières, la carte d'identité de ces stations », p. 3 ; la seule carte, p. 5, est la zone d'utilisation et trois ensembles de roches). Zone : « Hautes-Vosges lorraines cristallines », limitée à l'est « par la ligne de crêtes séparant les départements du Haut-Rhin et des Vosges » (p. 4) : dans l'emprise, au plus la partie vosgienne (1,768 km², § 5). Groupes indicateurs (p. 11) : « station très acide », « acide », « peu acide », « assez riche », « riche » ; eau : « sol gorgé d'eau en permanence », « sol temporairement inondé ». |
| 83 | Ried de l'Ill et Nonnenbruch (1996) | actif (`est_actif` = 1, `a_stations` = 1, gpkg) | `https://inventaire-forestier.ign.fr/typologie_stations/typo/consultation/GS_ried-ill-nonnenbruch.pdf` ; `https://grandest.cnpf.fr/sites/grandest/files/2022-02/guide_nonnenbruch.pdf` | IGN : HTTP 200, PDF (relevé par l'orchestrateur) ; pour l'agent, fichier de plus de 10 Mo, **non lu**. CNPF : refusé à l'orchestrateur, et `ECONNREFUSED` pour l'agent le 2026-11-18 : **à revérifier** | **Carte jointe : non vérifié** (PDF non lu). Guide de plaine ; dans l'emprise, au plus la part hors massif (C41 : 0,879 km², L2 : 2,437 km², § 1). |

Les codes de stations des guides (couche `stations`) n'ont pas été lus : ils ne servent pas à la
comparaison cartographique (aucun guide n'a de carte), seulement à l'étape 6 du brief (lecture
forestière).

### 26.4 Correspondance avec nos gradients (proposée, à valider)

| Notre gradient | Champ CarHab | Ordre proposé (1 = bas) | Ce qui permet | Ce qui empêche |
|---|---|---|---|---|
| Trophique | `acidite_edaphique` | `très acide` 1, `légèrement acide` 2, `neutre` 3, `basique` 4, `hyperbasique` 5 (absent de l'emprise) ; modalités lues sur la diapositive 6 du webinaire (lecture d'image : liste exhaustive **à vérifier** dans la notice nationale). **Décision provisoire de l'orchestrateur (2026-11-18) :** `neutre` est une classe à part entière, **jamais fusionnée avec `basique`** sur roche cristalline (même si la légende simplifiée les regroupe) | Échelle ordinale, même sens que notre gradient | Acidité seule (pas l'azote) ; SoilGrids 250 m et géologie 1/50 000 entrent dans les deux modèles |
| Hydrique | `humidite_edaphique` | `assez sec` 1, `mésique` 2, `légèrement humide` 3, `humide à nappe circulante` 4, `détrempé à nappe stagnante` 5. **Décision provisoire de l'orchestrateur (2026-11-18) :** ordre gardé, **provisoire, il mêle réserve en eau et engorgement** | Ordinal pour la part « sec → humide » | Mélange réserve en eau et engorgement (« nappe circulante / stagnante ») ; RGE ALTI et BD TOPAGE entrent dans les deux modèles |
| Bioclimat | `etage_de_vegetation` (et `ombroclimat`) | `collinéen` 1, `montagnard` 2, `subalpin` 3 | Trois classes présentes | Classes larges ; AURELHY 1971-2000 contre SAFRAN 1996-2025 |

### 26.5 Recommandation et protocole (proposés)

**Référence ouverte retenue : CarHab 68**, polygones `occupation='foret'`. C'est la seule carte
SIG ouverte qui couvre toute l'emprise et porte nos trois axes. Ce n'est **pas** une carte de
stations, et elle n'est **pas indépendante** de la nôtre (écart 27) : on s'en sert pour une
**comparaison par gradient**. Une matrice de confusion sur nos types serait trompeuse, parce que
les nomenclatures diffèrent et que nos seuils sont provisoires (`R/typologie.R`). La carte
AgroParisTech reste la référence du brief (§ 9), et les relevés GNSS restent l'arbitre.

1. **Acquisition** (mission `dev`) : le GeoPackage départemental (`CarHab_68_Haut-Rhin.zip`) ou le
   WFS paginé (`EMPRISE AND occupation='foret'`, 3 103 entités), mis en cache hors dépôt
   (`data/cache/`), **jamais dans `inst/extdata`** sans décision. La licence le permettrait
   (Licence Ouverte), mais le volume ne s'y prête pas.
2. **Grille** : rasteriser à la résolution de `config.yml` (`resolution_m`, 20 m depuis la
   décision de Pascal du 2026-11-18), au centre de cellule, en ne gardant que les cellules forestières
   des deux côtés (notre masque MHC et CarHab `foret`) ; noter la part de l'emprise retenue.
3. **Par gradient** : codage ordinal du § 26.4, puis corrélation de rang de Spearman entre notre
   gradient continu et la classe CarHab, avec boîtes à moustaches de notre gradient par classe.
   Ensuite, discrétiser notre gradient en autant de classes que CarHab, aux **mêmes proportions
   de surface**, pour ne pas dépendre de nos seuils, et calculer le kappa pondéré et l'accord à
   une classe près.
4. **Types regroupés** (contrôle seulement) : nos types sont projetés sur la légende simplifiée
   CarHab (acide ou basique × sec, mésique ou humide × étage). On en tire une matrice de
   confusion **en surface**, sans conclusion sur la justesse.
5. **Désaccords** : les ventiler par formation BD Charm-50 (§ 5), tranche d'altitude et position
   topographique, puis placer une part des relevés GNSS dans ces zones (brief § 9, étape 5).

**Trois points au sol** (Pascal) :

1. Polygone forestier **`habitats_carhab.3446233`** (plantation forestière, 30,0 ha ;
   **x 1 013 345–1 014 021, y 6 797 836–6 798 796**, lu le 2026-11-18 par `FEATUREID`) : CarHab y
   donne « neutre », montagnard, hyperhumide, mésique (biotope `338802`, « substrat basique » en
   légende simplifiée), sur un massif cristallin. (Le point x 1 013 500, y 6 797 500 proposé
   d'abord tombe dans `habitats_carhab.3533621`, milieu ouvert, d'après le relecteur.)
   Regarder les espèces indicatrices de richesse (Aspérule, Mercuriale contre Luzule blanchâtre,
   Myrtille, guide 97 p. 11) et la roche.
2. **x 1 008 095–1 008 755, y 6 795 550–6 796 490** : les 3 seuls polygones forestiers
   « subalpin » de l'emprise (biotope `132022`, très acide, mésique ; le plus grand fait
   15,4 ha). Regarder si c'est une hêtraie-sapinière d'altitude (montagnard) ou une forêt de crête
   subalpine : c'est la limite du gradient bioclimatique.
3. **Coin nord-ouest, x 1 006 363–1 007 932, y 6 803 760–6 804 940** (emprise des polygones
   relevée par le relecteur, **en partie hors de l'emprise test**) : 5 polygones de
   résineux « détrempé à nappe stagnante », très acides, montagnards (biotope `324966`, de 1,8 à
   4,0 ha). Leurs identifiants (`habitats_carhab.126025xx`) ne sont pas de la série des polygones
   du 68 lus ici (`344xxxx` à `353xxxx`), d'où un département **à vérifier** (écart 25). Regarder s'il y a de
   la tourbe ou un gley près de la surface, là où notre gradient hydrique (réserve utile, TWI) peut
   dire autre chose.

### 26.6 Complément du 2026-11-19 (mission 031) : lecture réelle du WFS, exécutée en R

- **Lecture paginée vérifiée** (`sf::read_sf` sur l'URL `GetFeature`, `SRSNAME=EPSG:2154`,
  `SORTBY=id_polygone_carhab`, `COUNT=500`, `STARTINDEX` par pas de 500) : **3 103 polygones**
  `occupation='foret'`, soit le `numberMatched` du § 26.2. Modalités lues (aucune absente de
  l'ordre du § 26.4, aucune valeur vide) : acidité `très acide` 1 166, `légèrement acide` 1 375,
  `neutre` 495, `basique` 67 ; humidité `assez sec` 786, `mésique` 1 416, `humide à nappe
  circulante` 761, `légèrement humide` 127, `détrempé à nappe stagnante` 13 : les
  décomptes de `légèrement humide` et `détrempé à nappe stagnante`, qui reposaient sur 140
  entités, sont **confirmés**. Étage : `collinéen` 1 970, `montagnard` 1 130, `subalpin` 3.
- **Pièges de lecture** : GDAL ne rend pas le CRS du GML (`st_crs` absent : on pose 2154,
  `DefaultCRS` du § 26.1, puis on vérifie la plausibilité des x et y) ; la géométrie est une
  `MULTISURFACE` (WKB 12), que GEOS refuse (`ParseException`) : conversion en `MULTIPOLYGON` par
  `ogr2ogr -nlt MULTIPOLYGON` (`sf::gdal_utils`), après quoi les 3 103 géométries sont valides ;
  une page a échoué par moments (`Failed to read TopoJSON data`, panne passagère, constatée deux fois) :
  nouvel essai.
- **Surface** : les 3 103 polygones entiers (non découpés) font 18 162,7 ha d'après le champ
  `surface` (18 162,2 ha d'après la géométrie). Champ `layer` des 3 103 : `CarHab_68_Haut-Rhin_Habitats_CarHab`
  2 978, `habitats_carhab` 93, vide 32.
- **Décalage du chiffre de 26.1** : 126 polygones (93 + 33) sont de département non dit sur
  toutes occupations ; en forêt, 93 + 32 = 125. Le département reste **à vérifier**.

---

## Écarts relevés entre sources

1. Le brief cite la couche `IGNF_LIDAR-HD_METADONNEE:metadata` : elle existe, l'écart est
   nul. Le brief parle d'un « nom de dalle » : le champ réel est `coordonnees_nw`.
2. Le brief situe les vols des Vosges à « l'hiver 2021-2022 ». La métadonnée donne
   janvier **et avril** 2022 : 116 des 225 dalles ont été volées le 2022-04-21 (fin de
   l'hiver ou début du débourrement selon l'altitude). C'est un écart de saison à noter
   pour la hauteur des feuillus.
3. SER : **résolu.** 86 SER + 5 SER d'alluvions récentes, dans deux couches qui se
   superposent (IGN, `ser_l93.zip` et `ser_ar_l93.zip`). Le brief (§ 1) écrit « 91 SER » :
   c'est 86 + 5, pas un découpage de 91 SER exclusives. L'IFN code ses placettes sur les
   86 SER seulement (`metadonnees.csv`).
4. Le BBOX du WFS de la Géoplateforme compte 289 dalles pour une emprise qui en contient
   225 : il faut filtrer à nouveau.
5. Le brief donne `C30` comme exemple de code SER à côté de `D11` : `C30` existe mais
   c'est « Plaines et dépressions argileuses du Nord-Est » (GRECO C), pas une SER
   vosgienne. La GRECO D n'a que deux SER, `D11` et `D12`.
6. Aucune couche SER n'existe en WFS sur la Géoplateforme ; data.gouv.fr ne diffuse les SER
   qu'en WMTS (image). La seule source vecteur trouvée est le site de l'Inventaire
   forestier (fichiers de 2011).
7. GBIF : le jeu IFN déclare une incertitude de 1 m sur 1 800 de ses 2 150 occurrences de
   l'emprise, alors que l'IGN publie ses placettes à 700 m près. Le filtre « ≤ 25 m » de la
   règle bloquante laisse donc passer des placettes IFN : il faut exclure le jeu
   `e5f16d86-e225-4822-97be-a64ce17079c7` par sa clé.
8. GBIF : la clé `7707728` de Tracheophyta est celle de l'ancien référentiel ; `rgbif`
   3.9.0 travaille par défaut sur Catalogue of Life où la clé est `TP`. L'API brute avec
   `checklistKey` Catalogue of Life et `taxonKey=7707728` renvoie 0 occurrence.
9. BD Charm-50 : `CODE` n'est pas stable d'un département à l'autre (même `NOTATION`,
   `CODE` différents) ; joindre par `NOTATION`.
10. Licences : IFN « Licence Ouverte 2.0 » sur son site, `fr-lo` (1.0) sur data.gouv.fr ;
    TAXREF `fr-lo` sur la fiche MNHN et `lov2` sur la fiche SIB ; BD Charm-50 et régolithe
    sans licence nommée (`notspecified`) malgré la mention « Données ouvertes ».
11. Le site InfoTerre est fermé depuis le 2026-10-21 ; les archives BD Charm-50 restent
    servies à leur ancienne adresse, la page de formulaire citée par data.gouv.fr répond 404.
12. La flore IFN est codée en TAXREF v13.0 ; la version courante est **v18 (2025)** (§ 15,
    passe 3) : cinq versions d'écart, **aucune table de passage trouvée**.
13. LiDAR HD, classe 65 : la révision de juillet 2026 du descriptif de l'IGN n'a **pas** de
    classe 65 (11 classes : 1, 2, 3, 4, 5, 6, 9, 17, 64, 66, 67) ; un résultat de recherche en
    attribue une à une version antérieure (« Artefact »), non vérifié (§ 17).
14. Régolithe : service muet le 2026-11-16, **joignable le 2026-11-17** (§ 19). Sur
    `REGOLITHES_AUTOCH_S_1M`, `hits` sans filtre = 0 mais 1 entité avec une boîte : décompte
    brut peu fiable.
15. Licences des valeurs indicatrices : Zenodo (Tichý et al.) **CC BY 4.0** contre
    **CC BY-SA 2.0** annoncée par Tela Botanica pour les données de Baseflor, dont le fichier
    Zenodo reprend les valeurs françaises de Julve ; non résolu (§ 14).
16. BD TOPAGE : **748** tronçons (millésime 2025) contre **752** (BD TOPO courante) dans la
    même boîte WGS84 ; licence selon le millésime : Licence Ouverte 1.0 (2022) puis 2.0
    (2023, 2024) (§ 16).
17. MRVBF : le brief technique (l. 75) cite l'indice ; **il n'existe pas dans `whitebox`**
    (§ 20).
18. Texture IFN : le dictionnaire (`metadonnees.csv`) donne au code `0` le sens « absence de
    terre fine », la documentation (`IGN_DB_doc_ecologie.pdf`, p. 6) écrit « TEXT1 = 0 » pour un
    sol homogène ; sur l'extrait, `TEXT1 = 0` va avec `PROF1` vide (36 placettes) : sol homogène.
    Sur toute l'archive, 57 lignes ont `TEXT1 = 0` **et** `PROF1` renseigné : lues comme un
    horizon supérieur sans terre fine (§ 22, à vérifier).
    Le code 8 cite `Als`, classe du triangle du GEPPA, absente du triangle de l'Aisne (§ 22). La
    correspondance provisoire de la mission 015 (5 = LA, LAS, **LSA** ; 6 = LL, LM, **LMS**) était
    fausse : LSA et LMS sont au code 4.
19. SAFRAN : les CSV de meteo.data.gouv.fr nomment `PRELIQ`, `PRENEI`, `ETP` ; `biljouR`
    attend par défaut `PRELIQ_Q`, `PRENEI_Q`, `ETP_Q`. Le miroir NetCDF de l'INRAE (DOI
    `10.57745/BAZ12C`) cité par `biljouR` ne contient plus que la grille (§ 23).
20. Réserve utile : sur les 97 placettes calculables, `euptf2` (FC_2 - WP) donne en moyenne
    **plus** que Bruand et al. 2004 (colonne défaut) ; les deux sont très corrélées (chiffres au
    rendu de la mission 019).
21. Descente d'échelle (§ 25) : le choix (c) de Pascal dit « RU modulée par la topographie » ;
    **aucune source lue** ne publie une telle modulation simple, et les méthodes publiées et
    validées en forêt tempérée modulent l'**ETP par le rayonnement** (Dyer 2009).
22. Apports latéraux : TOPMODEL (Beven et Kirkby 1979) les fonde sur le TWI ; Dyer (2009,
    p. 399-400) ne les retrouve pas dans l'humidité mesurée en saison de croissance, et
    Beven et al. (2021) bornent TOPMODEL aux sols minces et pentus.
23. ETP : SAFRAN publie une ETP Penman-Monteith (§ 23) ; `biljouR::penman_pet()` calcule une
    ETP de Penman (1948). Même sur le plat, les deux diffèrent : la référence plate de la
    modulation doit venir de la même formule que la cellule modulée (§ 25.4).
24. Rayonnement : la couche `rayonnement` de sylvostation est hors atmosphère, sans ombres
    ni diffus ; Piedallu et Gégout (2008, notice) trouvent le rayonnement avec nébulosité bien
    meilleur que le ciel clair (R² 0,78 contre 0,46).
25. CarHab, emprise : le WFS compte 6 378 polygones par `BBOX` et 6 376 par `INTERSECTS` ; seuls
    6 250 portent `layer` = `CarHab_68_…` ; les 126 autres (`habitats_carhab` ou vide) ne disent
    pas leur département, et aucun ne porte `CarHab_67` ni `CarHab_88` alors que l'emprise touche
    ces deux départements (§ 26.2).
26. CarHab, acidité : 495 polygones forestiers « neutre » et 67 « basique » sur un massif dont les
    plus grandes formations sont des gneiss et granites (§ 5). Pas forcément faux (champ de
    fractures de Ribeauvillé, colluvions), mais la légende simplifiée range « neutre » avec
    « basique » (« Habitat forestier sur substrat basique et mésique », biotope `338802`,
    montagnard, hyperhumide ; polygone forestier `habitats_carhab.3446233`, 30 ha,
    x 1 013 345–1 014 021, y 6 797 836–6 798 796 ; le point x 1 013 500, y 6 797 500 d'abord proposé
    tombe en milieu ouvert) : à confronter à la géologie.
27. CarHab, indépendance : les biotopes sont prédits avec RGE ALTI, BD TOPAGE, géologie BRGM et
    SoilGrids, sources proches des nôtres (§ 5, § 16, § 18). Une concordance avec CarHab ne prouve
    pas que nos gradients sont justes ; seuls les relevés des CBN qui l'entraînent sont une
    source distincte.
28. Guide 94 (consigne : actif, 1993) : le lien CNPF partage un fichier nommé `ClimVosges.pdf`,
    nom sans rapport apparent avec le titre (§ 26.3).
29. Notice CarHab du Haut-Rhin : le moteur de recherche cite une mention de la Moselle dans son
    texte (copie possible d'une autre notice) ; notice non lue, inaccessible à l'agent.

## Dépendances et statut du jour (2026-11-17)

- Vérifié le 2026-11-16 (passes 1 et 2) : § 1, 2, 3, 4, 5, 7, 8, 10, 12, 13 ; § 11 pour les
  lignes antérieures à la passe 3.
- Vérifié le 2026-11-17 (passe 3) : § 15 (version v18 et lien de téléchargement seulement),
  § 16, § 17, § 19, § 20 (lecture des sources, rien exécuté), § 18 (SoilGrids, BDGSF,
  Bruand et al. 2004).
- Vérifié le 2026-11-17 (passe 4, mission 019, exécuté en R) : § 22 (dictionnaire IFN des
  textures ; triangle de l'Aisne **déduit** des abréviations, `Als` hors triangle), § 23
  (SAFRAN SIM2), § 24 (`soiltexture`, `euptf2`, `biljouR`).
- Vérifié le 2026-11-18 (passe 5, mission 020, lecture seule, rien exécuté) : § 25 (code de
  `biljouR` au commit `b0dade7` par résumeur ; Dyer 2009 lu en images ; DOI par Crossref ;
  manuel `r.sun` de GRASS 8.5). **Lu en résumé seulement** : Piedallu et al. 2013 (Crossref).
  **Non lus** : Piedallu et Gégout 2007 (§ 25.2), Piedallu et Gégout 2008, Piedallu et al.
  2011 (HAL refusé), Allen et al. 2006 (résumé seul), Šúri et Hofierka 2004 § 3.2, Nobre et al. 2011,
  document des paramètres SIM2 (unité de `SSI`).
- Vérifié le 2026-11-18 (mission 021, exécuté en R) : § 25.8 (unité de `SSI` dans le document
  de Météo-France, options de `r.sun` de GRASS 8.4.2, source de `penman_pet()`, coût de
  `r.sun`, écart table / calcul direct).
- Vérifié le 2026-11-18 (passe 6, mission 024, WebFetch seul, rien exécuté ni téléchargé) :
  § 26 (WFS CarHab `Carhab_habitat:habitats_carhab`, schéma, décomptes de l'emprise, licence
  par la métadonnée CSW ; guide 97 lu en image p. 1-14). **Non lus** : notice CarHab du Haut-Rhin
  (INPN muet), notice nationale (HAL refusé), guides 94 et 95, contenu des zip CarHab, PDF des
  DOCOB (403). **Pistes** : DOCOB Natura 2000 Hautes-Vosges, BDGveg_FR.
- **Pistes, à ne pas coder** : Baseflor (§ 14), EcoPlant (§ 14), contenu du zip TAXREF v18
  (§ 15), GlobalSoilMap France pH, texture et réserve utile 90 m (§ 18), fiches de la
  référence AgroParisTech voisines (§ 21).
- **Non vérifié** : colonnes de toutes les valeurs indicatrices (§ 14) ; table de passage
  TAXREF v13 vers v18 (§ 15) ; format du raster de stations AgroParisTech (§ 21) ; `lidarHD`
  (hors GitHub ?), `rgbif::occ_download` (compte GBIF requis) ; § 6 : **réserve levée**
  (service joignable, § 19), reste la licence sans nom.
- **Non exécuté en passe 3** : tout R (`install_whitebox()`, `args()`), tout téléchargement
  (zip TAXREF, fichier Zenodo de 19,5 Mo, GeoPackage).
- Dépendances : l'URL BD Charm-50 dépend de la refonte d'InfoTerre (fin 2026 annoncée) ;
  le nom de l'archive IFN change à chaque campagne ; l'URL `url_npl` du LiDAR contient la
  date d'édition (2024-12-20) ; la page PatriNat de TAXREF v18 sera retirée « dans les
  prochains mois » ; le millésime est dans le nom des couches TOPAGE.

## 26. Sentinel-2 : grille et bandes à 20 m (mission 025)

Source vérifiée le 2026-11-18 : SentiWiki, https://sentiwiki.copernicus.eu/web/s2-products et
https://sentiwiki.copernicus.eu/web/s2-mission (aucun téléchargement de données).

- **Tuiles** : produits L1C et L2A découpés en tuiles de 110 km x 110 km, définies en
  **UTM/WGS84** sur un pas de 100 km (recouvrement de 10 km). Le CRS n'est donc **pas** EPSG:2154.
- **Bandes à 20 m** : B5 (705 nm), B6 (740 nm), B7 (783 nm), B8a (865 nm), B11 (1610 nm), B12
  (2190 nm). Bandes à 10 m : B2, B3, B4, B8 ; à 60 m : B1, B9, B10.
- **Conséquence** : une grille Lambert-93 de 20 m ne se superpose pas pixel à pixel aux tuiles
  (projections différentes) ; les bandes à 20 m se **rééchantillonnent** sur notre grille
  (ADR 0007). Fuseau UTM de la SER D11 (Vosges, environ 7 degrés est, donc 32N) : **à vérifier**.
- **Non vérifié** : nom des produits Sentinel-2 L2A servis par le fournisseur retenu, URL et
  licence d'accès (mission 023), méthode de rééchantillonnage conseillée (bilinéaire ou moyenne).

## 27. SOPHY (banque de données phytosociologiques) : accès fermé, localisation grossière (mission 030)

- **Décision éclairée :** intégrer ou non SOPHY à la composante régionale (maille large) de la
  typologie, GRECO D et SER D11.
- **Propriétaire :** Pascal (délégué à l'orchestrateur). **Rédigé par :** agent `acquereur`,
  mission 030, le 2026-11-18. **Outils :** `WebFetch` (pages résumées par un petit modèle ;
  les deux PDF ont été enregistrés par l'outil et **lus en image page par page**) et
  `WebSearch`. Rien téléchargé dans le dépôt, rien exécuté en R.
- **URL consultées le 2026-11-18 :**
  [A] Garbolino E., De Ruffray P., Brisse H., Grandjouan G. (2012). *The phytosociological
  database SOPHY as the basis of plant socio-ecology and phytoclimatology in France.*
  Biodiversity & Ecology 4 : 177-184, DOI 10.7809/b-e.00074,
  https://www.biodiversity-plants.de/biodivers_ecol/publishing/b-e.00074.pdf (fiche GIVD p. 178,
  « Information as of 2012-09-23 ») ;
  [B] fiche GIVD en ligne https://www.givd.info/ID/EU-FR-003 (« Last update 2024-02-19 ») ;
  [C] site SOPHY https://sophy.tela-botanica.org/ et ses pages `locrel.htm`, `bilan.htm`,
  `historique01.htm`, `tabphyto.htm`, `nblocal.htm` (« Mise à jour du 10 janvier 1999 ») ;
  [D] EVA, accueil https://euroveg.org/eva-database/ , liste des bases
  https://euroveg.org/eva-database/databases, procédure
  https://euroveg.org/eva-database/obtaining-data, règles
  https://euroveg.org/download/eva-rules.pdf (« approved … Vienna on 26 May 2012 », PDF du
  2022-11-08, 4 p.) ;
  [E] GBIF : https://api.gbif.org/v1/dataset/search?q=SOPHY ,
  https://api.gbif.org/v1/dataset/f823053d-0d53-4b3b-b52e-fb85fe847dd0 , recherche
  d'occurrences du même jeu (facette `coordinateUncertaintyInMeters`, et rectangle
  lon 5,5-8,5, lat 47,3-49,2) ;
  [F] fiche GIVD de VegFrance https://www.givd.info/ID/EU-FR-004.
  **Refusée :** https://www.idiv.de/en/sdiv/working-groups/wg-pool/splot/consortium-and-contributing-databases.html
  (404) ; le chiffre sPlot 209 864 n'est connu que par l'extrait du moteur de recherche (non vérifié).

| Point | État | Source | Résultat |
|---|---|---|---|
| Producteur | **vérifié** | [A] p. 177-178 ; [B] | Créée par H. Brisse et P. de Ruffray (Strasbourg, puis Univ. Paul Cézanne, Marseille), démarrée en 1978 ([C] `historique01.htm`). Propriétaires : « Henry Brisse, Patrice de Ruffray, Emmanuel Garbolino et TELA-BOTANICA (private) » ([A] p. 178) ; même liste sans « (private) » en [B]. Gardien EVA : E. Garbolino ([D]). |
| Code GIVD | **vérifié** | [A] p. 177 ; [B] ; [D] | `EU-FR-003`. |
| Accès | **vérifié** | [A] p. 178 ; [C] ; [D] | « Availability: according to a specific agreement », « Online upload: no », « Online search: no » ([A] p. 178). Le site [C] n'offre **aucun téléchargement de relevés** ni de conditions d'usage (seule une liste de référence `impaldoc.exe`). Dans EVA : « SOPHY (209 900 plots, semi-restricted access) » ([D] liste). Régime 2 semi-restreint : réservé aux « data contributors only (i.e. custodians of databases included in EVA or persons approved by one of the custodians) » ([D] règles, art. 4, p. 2) ; délai d'au moins trois semaines ([D] procédure). |
| Licence | **vérifié : aucune licence ouverte** | [A] ; [B] ; [C] ; [D] art. 5 p. 3 | Aucune licence publiée pour la base. Par EVA : « The applicants are not allowed to pass any data obtained from EVA … to third parties », « non-commercial purposes only », mandat de trois ans après livraison ([D] art. 5, p. 3). **Incompatible avec un dépôt public** et avec le test du successeur. Les relevés sont des transcriptions de tableaux publiés ([A] p. 177 ; [C] `tabphyto.htm`) : les droits des publications d'origine restent à considérer (non vérifié). |
| Citation | **vérifié** | [A] p. 177 | Garbolino et al. 2012, Biodiversity & Ecology 4 : 177-184, DOI 10.7809/b-e.00074. EVA impose en plus la citation de Chytrý et al. 2016, Applied Vegetation Science 19 : 173-180 ([D], page d'accueil EVA, lue en résumé seulement). |
| Version, volume national | **vérifié (chiffres discordants, voir écarts)** | [A] p. 178 ; [B] ; [C] `bilan.htm` ; [D] | 212 244 relevés, 4 500 sources, 4 598 taxons valides, plots de 1 à 400 m², pays BE 14,0 %, CH 1,0 %, ES 5,0 %, FR 79,0 %, IT 1,0 % ([A] p. 178). Statut « ongoing capture ». [B] : 212 244 (mise à jour 2024-02-19). [D] : 209 900. [C] : 192 352 relevés en janvier 2009 (dernière ligne du bilan). Part forestière : 52 731 relevés « Shadow — Forests of temperate Europe with sciaphilous plants » sur l'ensemble de la base ([A] tableau 1, p. 183 ; classes hiérarchiques, non additives). |
| Dates des relevés | **vérifié** | [A] p. 178 | Période 1915-2010. < 1919 : 0,1 % ; 1920-29 : 0,7 ; 1930-39 : 2,2 ; 1940-49 : 1,0 ; 1950-59 : 6,0 ; 1960-69 : 12,0 ; 1970-79 : 19,0 ; 1980-89 : 23,0 ; 1990-99 : 25,0 ; 2000-09 : 10,5 ; inconnu : 0,5 (total 100,0). **64,0 % des relevés sont antérieurs à 1990** (somme calculée par l'agent). |
| Précision de localisation | **vérifié (documentation)** ; **non vérifié sur des relevés de D11** (inaccessibles) | [C] `locrel.htm` ; [A] p. 178 ; [E] | Trois niveaux : « 1. 100 à 500m ; 2, 0,5 à 5 km ; 3, plus de 5 km » ; niveau 1 = coordonnées fournies ou relevé situé sur une carte ; 2 = lieu-dit (« centre de gravité visuel du lieu ») ; 3 = « coordonnées du chef-lieu de la commune » ([C] `locrel.htm`). Coordonnées en « grades et milligrades » ; légende du tableau : « Latitude en grades et milligrades (Paris) » (méridien de Paris indiqué par la source ; datum, NTF probable, **à vérifier**). GIVD 2012 : « point coordinates less precise than GPS, up to 1 km: 70% ; small grid (not coarser than 10 km): 20% ; political units or only on a coarser scale (>10 km): 10% » ([A] p. 178). Contrôle interne : erreur signalée si l'écart entre centroïde de commune et coordonnées dépasse 10 km ([A] p. 178). **Aucun relevé n'atteint 25 m.** |
| Deuxième source de précision | **vérifié** | [E] | Seul jeu trouvé sur GBIF : jeu GBIF « ACQUISITION_CBNMC - SOPHY » (PatriNat, DOI 10.15468/ky7a8n, CC BY 4.0, créé 2022-10-18, « Données communiquées par H. BRISSE »), 93 019 occurrences. `coordinateUncertaintyInMeters`, décompte complet (14 valeurs, somme 93 019) : 2 821 m : 90 007 ; 61 556 : 1 553 ; 57 689 : 532 ; 51 572 : 440 ; 62 239 : 288 ; 47 236 : 138 ; 6 674 : 30 ; 5 000 : 17 ; 3 949 : 4 ; 6 250 : 3 ; 3 467 : 2 ; 3 775 : 2 ; 4 277 : 2 ; 5 226 : 1. **Aucune occurrence sous 2 821 m.** Emprise : lat 44,26-46,77, lon 2,06-5,16 (Massif central) ; **0 occurrence** dans le rectangle lon 5,5-8,5, lat 47,3-49,2 (Vosges). |
| Volume GRECO D, SER D11 | **inaccessible** | [A] fig. 1 p. 179 ; [C] | Aucun décompte régional publié. La carte nationale ([A] fig. 1) montre des relevés dans le Nord-Est ; le site cite une classification des relevés des « Hautes-Vosges » ([C] `historique01.htm`). Le décompte exige une demande au gardien. À comparer : IFN, GRECO D 9 392 lignes `PLACETTE`, D11 6 475 (§ 7). |
| Référentiel taxonomique | **vérifié (documentation)** ; correspondance TAXREF **non vérifiée** | [A] p. 177 ; [B] ; [C] `tabphyto.htm` | Codes CFVVF (Brisse et Grandjouan 1971), puis Flora Europaea, puis Index de Kerguélen (Brisse et Kerguélen 1994), puis BDNFF (Bock 2004) ([A] p. 177). [B] annonce encore Fournier 1961. Pseudo-taxons par classe d'abondance ([A] p. 178). Passage BDNFF → TAXREF `CD_NOM` : **à vérifier** (pas de table de correspondance trouvée). |
| Format | **vérifié** | [A] p. 177-178 ; [C] `tabphyto.htm` | Tableaux texte au format de la publication source, en-tête `NREF`, `TA`, `NB`, titre ; lignes : code CFVVF et coefficients d'abondance-dominance ; fin de tableau `9999`. Base MySQL, export « plain text file ». Identifiant de relevé à 8 chiffres RéféTbRl. |

**Règle des 700 m (CLAUDE.md).** SOPHY ne peut jamais servir à une extraction fine (précision
toujours > 25 m). À maille large, seuls les relevés de niveau 1 (100 à 500 m) sont au moins
aussi bien placés que les placettes IFN (700 m) ; les niveaux 2 et 3, et les 30 % de la base
localisés au-delà de 1 km, dont 20 % sur une grille de 10 km au plus et 10 % au-delà de 10 km
([A] p. 178), dépassent le rayon de 700 m de la géologie dominante.
**Décision de l'orchestrateur (relecture 030, 2026-11-18) :** niveaux 2 et 3 refusés (plus de
700 m) ; seul le niveau 1 serait convertible (`loc_precision_m` = 500, tiré du champ de
précision par relevé), comme le code le fait déjà pour GBIF.

**Recommandation : écarter pour la calibration ; piste éventuelle : nommer les types, sous
convention avec le gardien, sans dépôt.**

**Ce que SOPHY ajouterait aux placettes IFN.** Des relevés phytosociologiques complets (toutes
strates, coefficients d'abondance-dominance) et nommés par leurs auteurs (syntaxons), utiles
pour **nommer** les types ; mais protocole et surface hétérogènes (1-400 m²), relevés anciens
(64 % avant 1990), part non forestière, et localisation le plus souvent moins bonne que l'IFN.
Pour **calibrer** la composante régionale, l'IFN (protocole fixe, 2005-2025, Licence Ouverte)
reste supérieur.

**Bases comparables.** EcoPlant `EU-FR-005` : 5 030 relevés,
« restricted access » ([D] ; déjà écarté au § 14). VegFrance `EU-FR-004` : 3 058 relevés,
« semi-restricted access » ([D]) ; 25 341 selon [F] (mise à jour 2025-11-25) ; couverture
régionale et part forestière non publiées. EVA : mêmes règles que ci-dessus (pas de
transmission à des tiers, usage non commercial). Toutes fermées à un dépôt public.

**Écarts relevés entre sources (§ 27).**
1. Volume : 212 244 ([A] 2012, [B] 2024) ; 209 900 ([D]) ; 209 864 (sPlot, extrait de moteur
   de recherche, page 404) ; 192 352 en janvier 2009 ([C]). Cause probable : dates différentes
   et doublons retirés à l'entrée dans EVA (non vérifié).
2. Précision : [C] annonce un niveau 1 « 100 à 500 m », [A] « up to 1 km » pour 70 % ; le seul
   jeu trouvé sur GBIF ([E]) n'a **aucune** occurrence sous 2 821 m. Cause probable : PatriNat a
   attribué une incertitude par défaut (communale ?) au lieu du niveau SOPHY (non vérifié).
3. Nomenclature : BDNFF (Bock 2004) dans [A], Fournier 1961 dans [B] (fiche GIVD jamais
   mise à jour sur ce champ ?).
4. VegFrance : 3 058 relevés ([D]) contre 25 341 ([F]) : EVA n'a sans doute reçu qu'une partie.
5. Numérotation de ce document : deux sections portent le n° 26 (cartes de comparaison,
   Sentinel-2).

## 28. MRVBF et HAND sur MNT LiDAR à 5 m : paramètres et diagnostic (mission 027)

Diagnostic du 2026-11-18 sur les 4 dalles du run de la mission 018 (MNT à 5 m,
`1013-6798`, `1014-6797`, `1014-6798`, `1014-6799`, 4 km² ; 30 tronçons TOPAGE, 4,3 km, soit
1,08 km/km²). Références vérifiées par Crossref (titre, revue, volume, pages) le 2026-11-18 :
Gallant et Dowling 2003, *Water Resources Research* 39(12), doi:10.1029/2002WR001426 ; Rennó
et al. 2008, *Remote Sensing of Environment* 112, 3469-3481, doi:10.1016/j.rse.2008.03.018 ;
Nobre et al. 2011, *Journal of Hydrology* 404, 13-29, doi:10.1016/j.jhydrol.2011.03.051 ;
Barnes, Lehman et Mulla 2014, *Computers & Geosciences* 62, 117-127,
doi:10.1016/j.cageo.2013.04.024. Le texte des articles n'a pas été lu (résumés seulement).

### 28.1 MRVBF (`r.valley.bottom`, extension GRASS, lue en entier le 2026-11-18)

| Point | État | Source | Constat |
|---|---|---|---|
| Seuil de pente `t_slope` | **vérifié** (manuel) | `~/.grass8/addons/docs/html/r.valley.bottom.html` | Défaut 16 (%), « conçu pour un MNT de 25 m » ; « divisé par 2 à chaque pas (grossissement x 3) au-dessus de 25 m » ; exemple : MNT de 6 m, `t_slope=40`. |
| Seuil aux mailles fines | **provisoire, à vérifier** | prolongement de la règle du manuel | t = 16 x 2^(log3(25 / maille)) : **44,2 à 5 m**, 18,4 à 20 m, 39,4 à 6 m (le manuel donne 40). |
| `t_vf` | **vérifié** (code) | script `r.valley.bottom`, ligne `t_vf = float(options["t_rf"])` | Défaut documenté 0,3, mais le script lit `t_rf` (0,35). sylvostation passe `t_vf=0.3 t_rf=0.3`. |
| Niveaux | **vérifié** (exécuté) | message `step` de l'extension | 8 pas sur le MNT de 5 m (5, 5, 15, 45, 135, 405, 1 215, 3 645 m) ; le seuil est divisé par 2 à chaque pas. |
| Cause du MRVBF quasi nul | **vérifié** (exécuté) | calcul de contrôle | Pente médiane des cellules du réseau TOPAGE à 5 m : **23 %** (12,95°), au-dessus du seuil de 16 % (8 % au pas 2) : aplanissement < 0,5 même en fond de vallon. Ce n'est ni l'unité, ni la lecture de la sortie (Float64), ni la marge de `NA` (résultat identique sans marge). |

Chiffres (MNT à 5 m, 160 000 cellules) :

| | médiane | q90 | max | part >= 0,5 | part >= 1,5 | médiane sur le réseau | réseau >= 0,5 |
|---|---|---|---|---|---|---|---|
| avant (`t_slope=16`, `t_vf`=0,35) | 5,4e-7 | 0,18 | 2,96 | 3,6 % | 0,5 % | 0,004 | 28 % |
| après (`t_slope=44,2`, `t_vf=0,3`) | 0,17 | 1,32 | 3,98 | 23,8 % | 7,9 % | 1,04 | 68 % |
| `t_slope=44,2`, `t_vf`=0,35 | 0,10 | 0,77 | 3,96 | 15,0 % | 4,5 % | 0,87 | 62 % |

Calcul à la maille de la grille (décision de l'orchestrateur du 2026-11-18 : MNT agrégé à
20 m, `t_slope` = 18,4 %, `t_vf` = 0,3, résultat rééchantillonné en bilinéaire sur 5 m ;
`derive_terrain(mrvbf_res = 20)`), mêmes 4 dalles, même emprise (160 000 cellules à 5 m) :

| | médiane | q90 | max | part >= 0,5 | part >= 1,5 | médiane sur le réseau | réseau >= 0,5 |
|---|---|---|---|---|---|---|---|
| avant (16 %, 5 m) | 0,0 | 0,18 | 2,96 | 3,6 % | 0,5 % | 0,004 | 28 % |
| 5 m, 44,2 % | 0,17 | 1,32 | 3,98 | 23,8 % | 7,9 % | 1,03 | 68 % |
| 20 m, 18,4 % | 0,0 | 0,39 | 2,90 | 7,6 % | 0,8 % | 0,60 | 58 % |

Sur la grille de 20 m (moyenne des valeurs à 5 m, 10 000 cellules) : part >= 0,5 de 2,7 %
(018), 24,1 % (5 m), 7,4 % (20 m) ; sur le réseau : 13,6 %, 73,8 %, 52,7 % ; corrélation 5 m /
20 m : 0,85. **Lecture** : à 20 m, le MRVBF est plus sélectif (7,4 % des cellules >= 0,5,
contre 24 %), reste net sur le réseau (médiane 0,6) et sort du domaine extrapolé ; il
**perd les fonds étroits** (< 40 à 60 m de large, part >= 1,5 : 0,8 % contre 7,9 %). Aucune
des deux mailles n'est validée sur le terrain ; le calcul à 5 m reste la référence de
comparaison. Durée GRASS (machine chargée) : 3,9 min à 20 m, 4,4 min à 5 m.

Le manuel situe le fond de vallon à partir de 0,5 (0,5 à 1,5 : fonds étroits et pentus ;
> 1,5 : fonds larges). Valeurs de 0 à environ 4 ici : relief vosgien à vallons étroits.

### 28.2 HAND (`hauteur_reseau`)

| Point | État | Constat |
|---|---|---|
| Part de `NA` (21,8 % à 20 m, 23,5 % à 5 m) | **vérifié** (exécuté) | 70 % des `NA` finissaient dans **40 cuvettes intérieures** du MNT (directions D8 sans remplissage ; jusqu'à 6 589 cellules, 16 ha, par cuvette), 30 % sortaient du MNT. **Défaut corrigé** : franchissement des cuvettes par leur col (`.route_pits`, inondation prioritaire, Barnes et al. 2014). Reste : l'eau qui sort de l'emprise avant de rencontrer le réseau (`NA` légitime ; moindre sur 225 dalles). |
| Valeurs de 200 à 325 m | **vérifié** (exécuté) | Ce n'est pas un défaut de calcul : corrélation 0,93 entre HAND et distance au réseau ; les cellules > 200 m (16 %) sont à 555 m médians du réseau, à 817 m d'altitude médiane (MNT de 504 à 919 m). Le réseau TOPAGE (1,08 km/km²) ne remonte pas jusqu'aux têtes de bassin. |
| Densification par seuil d'accumulation | **piste, non retenue** (aucun seuil sourcé) | Réseau TOPAGE + cellules de surface drainée D8 >= S (MNT non rempli) ; voir 28.3. Le HAND publié (Rennó 2008, Nobre 2011) part d'un réseau extrait du MNT par seuil : valeur du seuil **à lire** dans ces articles avant de choisir. |

### 28.3 Avant et après sur les 4 dalles (MNT à 5 m, sortie agrégée à 20 m)

Grille de 20 m (10 000 cellules renseignées), moyenne des valeurs à 5 m comme
`real_terrain()`. Le recalcul « avant » reproduit exactement l'objet `terrain` du store de 018.

| | MRVBF médiane | q90 | max | part >= 0,5 | HAND médiane | q90 | max | `NA` |
|---|---|---|---|---|---|---|---|---|
| avant | 2,5e-6 | 0,24 | 1,84 | 2,7 % | 88,7 m | 238 m | 325 m | 21,8 % |
| après | 0,21 | 1,19 | 3,95 | 24,2 % | 86,8 m | 227 m | 325 m | 10,1 % |

Sensibilité du HAND à une densification (MNT à 5 m, cuvettes franchies) :

| Seuil S | cellules réseau | `NA` | médiane | q90 | max |
|---|---|---|---|---|---|
| TOPAGE seul | 0,47 % | 11,0 % | 86,6 m | 227 m | 325 m |
| + 50 ha | 0,51 % | 7,1 % | 86,3 m | 224 m | 325 m |
| + 10 ha | 0,68 % | 2,6 % | 74,3 m | 182 m | 318 m |
| + 5 ha | 0,83 % | 2,6 % | 68,7 m | 164 m | 318 m |
| + 2 ha | 1,21 % | 1,2 % | 59,1 m | 149 m | 318 m |

### 28.4 Vallons des 4 dalles à confronter à une vue QGIS (Lambert-93, x = est, y = nord)

Dalles du run (convention LiDAR HD, § 2 : la dalle `XXXX-YYYY` couvre x de XXXX à XXXX+1 km et
y de YYYY-1 à YYYY km) : `1013-6798` (x 1013-1014, y 6797-6798), `1014-6797` (y 6796-6797),
`1014-6798` (y 6797-6798), `1014-6799` (y 6798-6799) ; emprise du MNT lue sur le raster :
x 1 013 000-1 015 000, y 6 796 000-6 799 000. (Les dalles `1013-6803` à `1014-6804` citées dans
d'autres notes sont d'un autre jeu, hors de ces 4 dalles.) Toponymes : champ `TopoOH` de
TOPAGE. Valeurs lues sur les rasters de MRVBF (cellule de 5 m contenant le point, `terra::extract`),
altitude lue sur le MNT :

| Lieu | x (est) | y (nord) | Dalle | Cellule de 5 m (index) | Altitude | MRVBF 5 m (44,2 %) | MRVBF 20 m (18,4 %) |
|---|---|---|---|---|---|---|---|
| Ruisseau le Strengbach, fond de vallon (26 cellules de 20 m >= 1,5 aux deux mailles, toutes sur ce ruisseau) | 1 013 470 | 6 797 810 | 1013-6798 | 95 295 | 735,2 m | 3,97 | 2,84 |
| Ruisseau l'Adelsbach | 1 014 790 | 6 798 790 | 1014-6799 | 17 159 | 538,5 m | 2,87 | 1,51 |
| Ruisseau le Muesbach | 1 014 330 | 6 796 730 | 1014-6797 | 181 867 | 608,4 m | 1,15 | 1,25 |
| Crête (contrôle : point haut à plus de 150 m de tout tronçon) | 1 014 390 | 6 796 090 | 1014-6797 | 233 079 | 904,8 m | 0,00 | 0,00 |

Les cellules sont indexées sur le MNT de 5 m (1 ligne = 400 cellules, du nord au sud). À
confronter : le fond du Strengbach doit apparaître comme un fond plat bordé de versants, la
crête non. Les moyennes à 20 m de la grille (Strengbach 3,65 à 5 m, 2,78 à 20 m) diffèrent
de ces valeurs de cellule.

# Passe 7 (mission 029, 2026-11-18) : plan d'échantillonnage GNSS

Outils : `curl` et R (`sf`), exécutés par l'agent `dev` de la mission 029. Fichiers
temporaires hors dépôt, rien n'entre dans `inst/extdata`.

## 29. BD TOPO : tronçons de route (accès au terrain) : vérifié

| Point | État | Commande ou source | Résultat |
|---|---|---|---|
| Couche et champs | **vérifié** | `WFS&REQUEST=DescribeFeatureType&TYPENAMES=BDTOPO_V3:troncon_de_route` | Géométrie `geometrie` ; champs utiles : `cleabs`, `nature`, `fictif`, `etat_de_l_objet`, `importance`, `prive`, `acces_vehicule_leger`, `acces_pieton`, `piste_dfci` (et 80 autres). Titre au GetCapabilities : « BD TOPO® : Tronçons de route », résumé « BD TOPO® V3 2026-09-15 » ; `DefaultCRS` EPSG:4326, EPSG:2154 en `OtherCRS`. Pas de `MetadataURL`. |
| Décompte sur l'emprise test | **vérifié** | `WFS&REQUEST=GetFeature&TYPENAMES=BDTOPO_V3:troncon_de_route&BBOX=1007000,6790000,1022000,6805000,urn:ogc:def:crs:EPSG::2154&RESULTTYPE=hits` (2026-11-18T15:22:57Z) | `numberMatched` = **17 316** (le BBOX déborde, § 2 : boîte des tronçons lus x 1 005 604–1 023 089, y 6 788 913–6 805 896). |
| Lecture complète | **vérifié** | même requête, `&SRSNAME=EPSG:2154&OUTPUTFORMAT=application/json&COUNT=5000&STARTINDEX=0,5000,10000,15000` | 17 316 tronçons, 17 316 `cleabs` distincts, lus par `sf` en EPSG:2154. |
| Modalités de `nature` | **vérifié** (inventaire complet de l'emprise) | décompte `table()` | Bretelle 2 ; **Chemin 3 667** ; Escalier 30 ; Rond-point 138 ; **Route à 1 chaussée 5 893** ; Route à 2 chaussées 69 ; **Route empierrée 3 857** ; **Sentier 3 660**. |
| Modalités de `acces_vehicule_leger` | **vérifié** | idem | A péage 7 ; Libre 13 106 ; Physiquement impossible 3 760 (dont les 3 660 sentiers et les 30 escaliers, 64 routes à 1 chaussée, 4 routes empierrées, 2 chemins) ; Restreint aux ayants droit 443 (231 routes à 1 chaussée, 151 routes empierrées, 61 chemins). |
| Autres champs | **vérifié** | idem | `prive` : FALSE 17 298, TRUE 1, NA 17 ; `fictif` : FALSE 17 313, TRUE 3 ; `etat_de_l_objet` : En service 17 314, En projet 2. |
| Licence | **vérifié** | `https://www.data.gouv.fr/api/1/datasets/?q=BD%20TOPO` | Jeu « BD TOPO® » (id `61489083dc4223219e50cc35`, organisation IGN) : `license` = **`lov2`** (Licence Ouverte 2.0). La licence propre à la couche WFS `BDTOPO_V3` n'est pas lue (pas de `MetadataURL`, CSW de la Géoplateforme en erreur 500 sur les requêtes `GetRecords` essayées) ; on suppose la même. |

**Règle d'accès retenue (mission 029, décision du 2026-11-18) :** `nature` parmi Route à 1
chaussée, Route à 2 chaussées, Bretelle, Rond-point, Route empierrée, Chemin
(`ACCESS_NATURES`) ; on écarte Sentier, Escalier, `fictif` vrai, `etat_de_l_objet` différent
de « En service » et `acces_vehicule_leger` = « Physiquement impossible ». Le privé
(`prive`), « Restreint aux ayants droit » et « A péage » sont **signalés**
(`acces_restreint`), pas exclus.

## 30. Paquet `clhs` (hypercube latin conditionné) : vérifié (exécuté)

| Point | État | Commande | Résultat |
|---|---|---|---|
| Installation | **vérifié** | `install.packages("clhs", repos = "https://cloud.r-project.org")` (bibliothèque utilisateur, 2026-11-18) | Version **0.9.2**, publiée sur le CRAN le 2025-10-20 ; licence GPL (>= 2) ; dépend de `ggplot2`, `sf`, `raster`, `reshape2`, `plyr`, `cluster`, `Rcpp`. |
| Signature | **vérifié** | `args(clhs:::clhs.data.frame)` | `clhs(x, size, must.include = NULL, can.include = NULL, cost = NULL, iter = 10000, use.cpp = TRUE, temp = 1, tdecrease = 0.95, weights = list(numeric = 1, factor = 1, correlation = 1), eta = 1, obj.limit = -Inf, length.cycle = 10, simple = TRUE, progress = TRUE, track = NULL, use.coords = FALSE, ...)` ; méthodes pour `data.frame`, `sf`, `SpatRaster`, `SpatVector`, `Raster*`, `SpatialPointsDataFrame`. |
| Variante à coût | **vérifié** (aide et code lus) | `?clhs`, `deparse(clhs:::clhs.data.frame)` | Aide : « associate a cost to each individual and take it into account during the optimisation process (Roudier et al., 2012) ». `cost` = nom ou indice de la colonne de coût ; avec `use.cpp = TRUE` (défaut), le coût passe au C++ (`CppLHS(..., cost_mode = TRUE)`), les coûts infinis sont ramenés à 1000. |
| `can.include` | **vérifié** (aide) | `?clhs` | « The algorithm will use all of `x` as the reference distribution, but will only select samples from [can.include] » ; seulement en C++. C'est ce qui permet de garder toute la forêt comme référence et de ne tirer que les cellules accessibles et homogènes. |
| Facteurs | **vérifié** (exécuté, tests de la mission 029) | — | Une colonne `factor` (géologie) est traitée comme catégorielle (`weights$factor`). |
| Reproductibilité | **vérifié** (exécuté) | `set.seed(2)` deux fois, puis `set.seed(3)` | Mêmes indices avec la même graine, indices différents avec une autre : le C++ suit le générateur de R. |
| Références | Minasny et McBratney 2006, DOI `10.1016/j.cageo.2005.12.009` (fiche de mission) ; Roudier et al. 2012 (cité par l'aide, **non lu**). | | |

## 31. Échelle de Braun-Blanquet : **à vérifier**

| Point | État | Source | Résultat |
|---|---|---|---|
| Échelle d'abondance-dominance (`r`, `+`, `1` à `5`) | **à vérifier** (non lue) | Braun-Blanquet J., 1964, *Pflanzensoziologie*, 3e éd., Springer, Wien | Formule usuelle : `r` un ou très peu d'individus ; `+` peu abondant, recouvrement très faible ; `1` nombreux, recouvrement < 5 % ; `2` 5 à 25 % ; `3` 25 à 50 % ; `4` 50 à 75 % ; `5` > 75 %. Citée de mémoire, sans accès à l'ouvrage (mission 029). |

## 32. Descente d'échelle du climat SAFRAN (mission 033, 2026-11-19)

| Point | État | Source | Résultat |
|---|---|---|---|
| Grille SAFRAN-SIM2 | **vérifié** (§ 25, lu en mission 020) | `LAMBX`, `LAMBY` en hm, Lambert II étendu (EPSG:27572), mailles de 8 km | Les centres sont les nœuds de l'interpolation ; la conversion se fait en EPSG:27572 puis Lambert-93 (x = est, y = nord). |
| Interpolation bilinéaire entre centres de mailles | **à vérifier** (aucune référence publiée lue) | Choix de la mission 033 | Pondération des quatre mailles voisines ; bord d'extrait : poids renormalisés (extrapolation constante). Le champ est continu et lissé à 8 km. Ce n'est pas une méthode de descente d'échelle physique : aucune information de relief. |
| Réseau de calcul de 1 km pour BILJOU | **à vérifier** (compromis coût / lissage) | `hydric_node_res_m: 1000` | Le saut résiduel entre nœuds voisins (médiane de |ΔIstress| 1,9 sur 20 m) vient de ce pas ; réversible par la config. |
| Gradient vertical de température (option A) | **différée** | Γ mesuré dans le plan de 033 : −0,19 à −0,50 °C/100 m selon la maille (instable) ; aucune valeur publiée lue | Non implémentée : aucune correction d'altitude. Mission d'acquisition à prévoir (Γ, altitudes de maille). |
| CHELSA (option C), RU par géologie (option D) | **différées** | Plan de 033 | À acquérir ou à évaluer ; la RU reste uniforme par maille et cause le saut résiduel d'Istress à la limite. |
| RU de maille à moins de 5 placettes | **provisoire** | `ru_min_placettes: 5` | Repli sur la médiane des mailles de l'emprise (D11 : une maille sur 9, 2 placettes, `9720_23610`). Seuil non sourcé. |
| Règle des 700 m | **respectée** | CLAUDE.md | Climat et RU : variables larges, croisables avec les placettes IFN ; k (r.sun) reste refusé aux placettes (`assert_no_fine_extract_on_ifn()`). |

## 33. Relevés floristiques ouverts, localisés à 25 m ou mieux, en D11 et GRECO D (mission 036)

- **Décision éclairée :** peut-on calibrer le lien entre gradients (trophique, hydrique) et relief
  fin LiDAR sur des relevés ou occurrences **ouverts**, sans EcoPlant ni SOPHY (accès sur demande,
  refusés par Pascal) ; et laquelle des sources trouvées entre dans la chaîne.
- **Propriétaire :** Pascal (délégué à l'orchestrateur). **Rédigé par :** agent `acquereur`,
  mission 036, le 2026-11-19. **Outils :** `WebFetch` (pages résumées par un petit modèle ; les
  décomptes de l'API GBIF sont ceux du serveur, les **dépouillements de facettes** de plus de
  30 entrées sont comptés par le résumeur, donc approchés), `WebSearch`, lecture en image de
  trois PDF enregistrés par l'outil. **Pas de `curl`, pas de R** : aucun polygone SER croisé,
  aucun fichier téléchargé, rien dans `inst/extdata`, aucun compte, aucune demande d'accès.
- **Emprise des décomptes GBIF :** rectangle lon 6,6-7,4, lat 47,8-48,6 (consigne), plantes
  vasculaires (`taxonKey=7707728`), `hasCoordinate=true`, `hasGeospatialIssue=false`, **toutes
  années**, `coordinateUncertaintyInMeters=0,25`, requêtes du 2026-11-19. **Ce rectangle n'est
  pas D11** : il contient la plaine d'Alsace et une part de la Lorraine, et ignore l'ouest de
  D11 (lon < 6,6). Sensibilité : (a) cœur de massif lon 6,8-7,2, lat 47,9-48,5 : 40 757
  occurrences à ≤ 25 m ; (b) bande ouest lon 6,2-6,6 : 19 554, dont **13 136 IFN** et 50 + 5
  des deux jeux utiles ci-dessous (l'ouest n'ajoute rien d'exploitable). Part en D11 des
  chiffres ci-dessous : **non mesurée** (croisement avec `ser_l93.shp` à faire en R).
- **URL consultées le 2026-11-19 :** API GBIF `https://api.gbif.org/v1/occurrence/search` (facettes
  `datasetKey`, `eventDate`, `locality`, `speciesKey`, `year`, `coordinateUncertaintyInMeters`) et
  `https://api.gbif.org/v1/dataset/<clé>` ; Sabatini et al. 2021, *Global Ecol. Biogeogr.* 30 :
  1740-1764, DOI 10.1111/geb.13346 (PDF `https://www.africamuseum.be/publication_docs/Sabatini et al 2021 GEB.pdf`,
  pages 1-20 lues en image) ; `https://doi.org/10.25829/idiv.3474-40-3292` (redirige vers
  `https://idata.idiv.de/ddm/Data/ShowData/3474`) ; `https://www.idiv.de/en/splot/splotopen.html` ;
  `https://ces-unsw-edu-au.github.io/cesdata/docs/vegetation-plots/global/sPlotOpen` ; Dietz L.
  et al. 2023, *Rev. For. Fr.* 74(4) : 481-, `https://revueforestierefrancaise.agroparistech.fr/article/download/7899/33491`
  (pages 2-5) ; `https://b2find.eudat.eu/dataset/edb097c4-268f-5959-a44a-529394c4124b` ;
  métadonnées INRAE Nancy SapVF
  `https://appgeodb.nancy.inrae.fr/donnees/documentations/bdd/db_phyto/source_complementaire/SapVF/SapVF_metadonnees_pour_BDD.pdf`.
  **Inaccessibles :** `entrepot.recherche.data.gouv.fr` (API et OAI : page « Access Denied » du
  filtre Anubis, non contourné), `hal.inrae.fr` (idem), `isidore.science` (403),
  `search-data.ubfc.fr` (Anubis), `agroenvgeo.data.inra.fr` (hôte introuvable),
  `appgeodb.nancy.inra.fr` (hôte introuvable), `inpn.mnhn.fr` (hôte non ouvert, § « hôtes refusés »).

### 33.1 Décompte GBIF à ≤ 25 m déclarés, par jeu (96 350 occurrences)

Somme des jeux = 96 350 (vérifiée). Licences : § 8 et pages `dataset/<clé>` (relues ici pour les
jeux CardObs, naturgucker).

| Jeu (`datasetKey`) | n à ≤ 25 m | Licence | Lecture |
|---|---|---|---|
| IFN (`e5f16d86-…`) | 40 144 (41,7 %) | CC BY 4.0 | **Exclu** : placettes à 700 m déclarées à 1 m (§ 8). |
| Pl@ntNet automatically identified (`14d5676a-…`) | 23 694 | CC BY 4.0 | **Écarté** : identification automatique, non validée. |
| Observation.org (`8a863029-…`) | 11 777 | **CC BY-NC 4.0** | **Écarté** (licence). |
| Pl@ntNet observations (`7a3679ef-…`) | 6 222 | CC BY 4.0 | Une photo = une espèce ; dates : 11 jours à ≥ 5 occurrences, 2 à ≥ 10 ; pas de `recordedBy` ; **non échantillonné** (facettes seules). Non retenu comme relevé. |
| **naturgucker (NABU)** (`6ac3f774-…`) | **6 143** | CC BY 4.0, DOI 10.15468/uc1apo | Voir 32.2. |
| iNaturalist (`50c9509d-…`) | 4 879 | **CC BY-NC 4.0** | **Écarté** (licence). |
| **CardObs** (11 jeux d'observateurs, dont `7d2dc1b9-…`) | **≈ 3 007** | CC BY 4.0 (pages de jeux relues) | Voir 32.2. |
| INPN Espèces (`7247dc2e-…`) | 448 | CC BY 4.0 | Incertitude 10 m ; 3 observateurs, points isolés (20 lus : 1 espèce par point, vignes, prairies) : **pas des relevés**. |
| Autres (11 jeux) | 36 | — | Non examinés. |

**Jeux régionaux de flore : aucun à ≤ 25 m.** Flore d'Alsace (SBA, `72b6bac4-…`) : 199 435
occurrences dans le rectangle, incertitudes de 1 529 m à 7 997 m (30 premières valeurs, 112 467
occurrences), **583 à ≤ 1 000 m**. CBAL (`69580c67-…`) : 26 077 ; incertitudes 1 583 m à 7 997 m,
**95 à ≤ 1 000 m**. Ce sont les données des CBN en diffusion ouverte : **floutées à la commune**
(cohérent avec les CBN de Brest, qui diffusent sur OpenObs « à la commune ou à la maille 5x5 km
selon sensibilité », recherche web, non lu à la source). Les occurrences sans valeur
d'incertitude sont refusées par la règle du projet.

### 33.2 Les deux jeux qui passent le filtre

**CQQCOQP.** *Pourquoi :* observations naturalistes, pas des relevés de calibration. *Qui :*
naturgucker = réseau social de NABU (citoyens), CardObs = outil de PatriNat (OFB, MNHN, CNRS, IRD),
naturalistes expérimentés. *Quoi :* occurrences d'espèces (humaines, `HUMAN_OBSERVATION`).
*Comment :* point par espèce (naturgucker) ; liste d'espèces posée sur un point de lieu-dit
(CardObs). *Où :* voir ci-dessous. *Quand :* naturgucker 2007-2026 (2021 : 2 683 sur 6 143) ;
CardObs principal 2007-2021. *Combien :* incertitude **déclarée**, jamais mesurée par la source.

| Point | naturgucker | CardObs (jeu principal `7d2dc1b9-…`, DOI 10.15468/gc267b) |
|---|---|---|
| Occurrences ≤ 25 m, rectangle ; cœur de massif | 6 143 ; 1 162 | 1 196 ; 412 |
| Incertitude déclarée | **25,0 m** sur tous les enregistrements lus (40) | **5,0 m** sur les 20 lus |
| Regroupement possible | `recordedBy` : **un seul code haché pour 6 050 occurrences sur 6 143** (observateurs non séparables) ; 400 jours, dont 156 à ≥ 10, 85 à ≥ 20, 39 à ≥ 50 occurrences | 1 observateur dominant ; 30 jours (18 à ≥ 10, 13 à ≥ 20) ; **45 lieux-dits, 25 à ≥ 10 espèces, 17 à ≥ 20** |
| Géométrie lue | 20 + 20 enregistrements : points **individuels**, étalés sur 1,2 à 2 km par jour ; au plus 3-4 espèces aux mêmes coordonnées (Senones 2022-06-14 : 4 espèces à 3 m, 3 à 1 m) ; Thann 2021-10-20 : 20 points distincts | 12 espèces aux **mêmes coordonnées** (48,34486 ; 7,38116, lieu-dit « Neuematten ») le 2012-06-09, puis 6 + 1 + 1 aux deux autres lieux-dits |
| `locality` | **n'est pas un lieu** : cellule UTM de 25 km (17 valeurs, `UTM25_32T_0350_5275`…), à ne pas confondre avec les « 25 m » | nom de lieu-dit |
| Qualité de détermination | non renseignée | « Non réalisable » (la plupart), « Probable » (3 sur 20) |
| Autres jeux CardObs (à ≤ 25 m) | — | `0200e5ab-…` 678 (une seule année, 2023, 9 jours) ; `aa79690b-…` 466 (2012, 2018 ; lieux dont Lac de Sewen 108) ; `c9147f19-…` 340 ; `130eea59-…` 148 ; `99ce61d0-…` 66 ; `0c7bfc03-…` 43 |

**Volume utile.** naturgucker + 8 jeux CardObs : 9 080 occurrences, **1 017 espèces** ; 281 espèces
à ≥ 10 points, **61 à ≥ 30, aucune à ≥ 100** (dépouillement de facettes par le résumeur :
somme 8 607 ≠ 9 080, voir écarts).

**Deux sources pour la précision.** (1) déclaration : 25 m et 5 m ; (2) géométrie des points :
naturgucker met bien des points distincts (3 m entre deux espèces d'une même mare, 570 m entre
deux stations) : **cohérent avec un pointage au GPS ou sur carte, incompatible avec un calage sur
grille**. CardObs : les 12 espèces du point « Neuematten » mêlent source (`Caltha palustris`,
`Chrysosplenium alternifolium`), lande sèche (`Genista sagittalis`, `Festuca trachyphylla`) et
hêtre : **cette liste couvre plus que 5 m** ; le point est un centre de lieu-dit, pas une
placette. La précision de 5 m vaut pour la coordonnée, pas pour l'étendue du relevé.
**Aucune des deux précisions n'est vérifiée contre un repère de terrain.**

### 33.3 sPlotOpen (Sabatini et al. 2021) : écart avec le § 27

| Point | État | Source | Résultat |
|---|---|---|---|
| Contenu | **vérifié** | article p. 6, 11 | 95 104 relevés de 105 jeux, 114 pays, 1888-2015, surface 0,03 à 40 000 m² (médiane 100 m²), espèces vasculaires. Rééchantillonné pour équilibrer l'espace climatique : **non représentatif d'une région** (p. 18). |
| France | **vérifié** | tableau 1 p. 14 | **Un seul jeu français : `EU-FR-003` SOPHY, 7 986 relevés en accès ouvert** (custodien E. Garbolino, suppléant P. De Ruffray). **Ni EcoPlant (`EU-FR-005`), ni VegFrance (`EU-FR-004`).** Vosges : part **non comptée** (fichier non téléchargé). |
| Précision | **vérifié (documentation)** | tableau 2 p. 17 ; p. 9 | `Location_uncertainty` **1 à 2 750 m**, renseigné pour 95 075 relevés ; les relevés au-dessus de **3 km** ont été retirés avant le rééchantillonnage. Pour SOPHY, niveaux 100-500 m, 0,5-5 km (§ 27) : **aucun relevé à 25 m attendu** ; minimum du jeu français **non lu**. Pour les jeux de l'iDiv, une valeur manquante est remplacée par la médiane du jeu avec un signe négatif (recherche web sur le code `splot3_build`, non lu à la source) : à tester sur le fichier. |
| Licence | **non vérifié pour les fichiers** | page iData sans licence ; article CC BY 4.0 | Les propriétaires ont **donné permission d'ouvrir** les relevés (p. 10). Licence de `sPlotOpen.zip` : **à lire sur la page iData** (version 2.0, 2023) avant tout usage. |
| Accès | **vérifié** | DOI ; page du guide CES | `https://idata.idiv.de/ddm/Data/DownloadZip/3474?version=5047` (taille non publiée) ; tables `header`, `DT`, `CWM_CWV`, `metadata`, `references`, fichiers texte à tabulations ; `Latitude`/`Longitude` WGS84. Taxons harmonisés sur un référentiel propre à sPlot (pas TAXREF). |

**Écart avec le § 27 :** le § 27 conclut « accès fermé, aucune licence ouverte » ; sPlotOpen publie
7 986 relevés de la même base SOPHY. Les deux sont vrais : SOPHY entière reste fermée, ce
sous-ensemble a été ouvert par ses propriétaires. Il **n'améliore pas la précision** (toujours
> 25 m, donc inutilisable pour la calibration fine), mais il peut servir à **nommer les types**
à maille large (niveau 1 de SOPHY, 100-500 m) **sans demande d'accès**. Dernier contrôle
nécessaire : lire `Location_uncertainty`, `Country` et les coordonnées dans l'en-tête
(un téléchargement de l'orchestrateur, hors mission 036).

### 33.4 Réseaux de placettes, sols, jeux de recherche

| Source | État | Résultat |
|---|---|---|
| RENECOFOR (ONF) | **piste, non vérifiée** | 102 placettes en forêt publique (source secondaire) ; relevés floristiques décennaux. **Aucun jeu ouvert avec coordonnées trouvé** (recherche web ; `onf.fr/renecofor` non ouvert). Part vosgienne inconnue. Non retenu. |
| RMQS (GIS Sol) | **piste, source primaire inaccessible** | Grille de 16 km ; les jeux publiés utiliseraient les coordonnées du **centre de maille** (« erreur » d'attribuer la valeur à la parcelle), licence Etalab 2.0 pour les cartes (extrait de recherche d'un jeu AgroEnvGeo, page non lue). **Écarté** (maille 16 km, pas de coordonnées réelles). |
| **Dietz et al. : trouées de la tempête de 1999 et peuplements voisins** (DOI 10.15454/AZNS3A, UMR Silva, 2020, **Etalab 2.0**) | **piste sérieuse, contenu non vu** | 139 placettes de 20 m de diamètre en trouée (relevés floristiques 2002 et 2018) + 139 en forêt non perturbée (2018), températures, altitude, surface ; **145 sites dans la GRECO Grand Est** dont la partie vosgienne (carte, fig. 1 p. 483 de l'article ; points en D11 **non comptés**) ; **pH eau de l'horizon 0-5 cm** mesuré à chaque site (p. 485), fosse pédologique. **Précision des coordonnées non publiée** sur les pages lues ; l'entrepôt est derrière un filtre anti-robot (non contourné). Données **ouvertes, sans demande** : à télécharger depuis un navigateur. Biais : trouées de tempête, sites ciblés sur des problèmes de régénération. |
| INRAE Nancy, essais de fertilisation de la sapinière (SapVF) | **piste faible** | 4 sites (Vologne et Mortagne, versant lorrain, grès ; Grendelbruch et Russ, versant alsacien, granite de Kagenfels) × 10 placettes de 30 m de côté ; relevé de 1985-1990. Pas de coordonnées dans les 4 pages lues ; conditions d'accès non lues. |
| Prairies de fauche Jura-Vosges (2020) | **piste, non vue** | « données ouvertes », 66 + 66 relevés (2005-2009, 2019) selon un extrait de recherche ; prairies, pas forêt ; page bloquée (Anubis). |

### 33.5 Recommandation classée

1. **Aucune source ouverte trouvée ne fournit, à ce jour, de vrais relevés forestiers à ≤ 25 m
   en D11 en nombre suffisant.** Les relevés précis restent fermés (EcoPlant, SOPHY) ; les jeux
   ouverts précis sont des occurrences, les jeux de relevés ouverts sont flous.
2. **Calibration « par espèce » sur GBIF (naturgucker + CardObs, CC BY 4.0)** : la seule voie
   immédiate et libre. Le lien relief-gradient se teste **espèce par espèce** (pour chaque espèce
   à ≥ 30 points, 61 espèces en tout, distribution du TWI, de la position et de la pente au
   point, comparée à la valeur indicatrice de l'espèce, § 14), pas relevé par relevé. À faire
   **après** croisement avec le polygone D11, filtre `loc_precision_m` ≤ 25 (valeurs déclarées : 25 et 5),
   exclusion de l'IFN. Limites : échantillonnage opportuniste (chemins, bords de route),
   déterminations non validées, un code observateur haché unique sur naturgucker, précision
   **déclarée**.
3. **Pseudo-relevés GBIF : trop peu pour calibrer** (≈ 25 lieux-dits à ≥ 10 espèces dans CardObs ;
   naturgucker pose des points isolés) et, pour CardObs, la liste couvre plus que le point.
   À garder comme **contrôle visuel**, pas comme jeu de calibration.
4. **Dietz et al. (Etalab 2.0)** : meilleure piste pour les **relevés avec pH mesuré** ; à
   ouvrir par un humain depuis un navigateur : lire les coordonnées, leur précision, le nombre de
   sites en D11 et la colonne du pH. Si les coordonnées sont au GPS : jeu de calibration trophique
   de quelques dizaines de sites.
5. **sPlotOpen** : pas pour la calibration fine (> 25 m) ; utile pour **nommer les types** à maille
   large, après lecture de `Location_uncertainty` et de la licence des fichiers.
6. **Écartés :** jeux CC BY-NC (Observation.org, iNaturalist), Pl@ntNet identifié par
   algorithme, jeux de CBN floutés (Alsace), INPN Espèces (points isolés), RMQS (maille 16 km),
   IFN (700 m).
7. **Licence et dépôt public :** seuls naturgucker et CardObs (CC BY 4.0) pourraient donner un
   extrait dans `inst/extdata`, avec DOI dans `SOURCES.md` (10.15468/uc1apo ; 10.15468/gc267b et
   un DOI par jeu CardObs) ; **ne pas recopier `recordedBy`** (noms d'observateurs dans CardObs,
   données personnelles). Dietz : Etalab 2.0, compatible, DOI 10.15454/AZNS3A.

### 33.5 bis Mise en œuvre dans `clean_occ()` (mission 037, 2026-11-19)

`clean_occ()` écarte par défaut, dans cet ordre (chaque occurrence n'est comptée que par le premier motif
qui l'écarte) : (1) les licences non commerciales (code normalisé `CC_BY_NC*`, y compris « CC BY-NC 4.0 »
écrit en toutes lettres) ; (2) les jeux Pl@ntNet `14d5676a-2c54-4f94-9023-1e8dcd822aa0` (« automatically
identified ») et `7a3679ef-5582-4aaa-81f0-8c2545cafc81` (« observations »), clés lues au § 8 ;
(3) les licences absentes, `UNSPECIFIED`, `UNSUPPORTED` ou hors famille CC BY et CC0 (la fiche 037 veut du CC
BY seulement ; paramètre `exclude_unknown_licence`).

**Écart avec le § 33.5 :** le § 33.5 n'écarte que le jeu Pl@ntNet identifié par algorithme (`14d5676a-…`) et
classe le jeu d'observations `7a3679ef-…` comme « non retenu comme relevé ». L'exclusion de `7a3679ef-…`
vient de la **fiche 037** et va au-delà du § 33.5 ; les deux jeux restent écartés.
`PLANTNET_GBIF_DATASET_KEYS` est une liste **non exhaustive hors emprise (à vérifier)**. Les effectifs par
motif sont rendus (message et attribut `ecartees`).

### 33.6 Écarts relevés entre sources (§ 33)

1. IFN : 41,7 % des occurrences à ≤ 25 m ici (rectangle, toutes années) contre 40,5 % au § 8
   (emprise test, 2000-2026) ; 96 350 toutes années contre 96 151 depuis 2000 (199 avant 2000).
2. § 27 (SOPHY fermée, sans licence ouverte) contre sPlotOpen (7 986 relevés SOPHY ouverts) :
   voir 32.3.
3. CardObs : 5 m déclarés contre une liste d'espèces qui couvre une source et une lande sèche.
4. naturgucker : `coordinateUncertaintyInMeters` = 25 et `locality` = cellule UTM de 25 km : même
   nombre, deux sens ; la valeur « 25 m » n'a pas pu être confirmée par une documentation du jeu
   (description sans précision de localisation).
5. Dépouillements de facettes par le résumeur : espèces 8 607 contre 9 080 (473 occurrences
   sans `speciesKey` ou erreur de comptage) ; CardObs `aa79690b-…` : jours 432 contre 466.
6. Numérotation : deux sections portent déjà le n° 26 (§ 27, écart 5) ; ce § 33 suit le dernier
   numéro lu (§ 31).

### 33.7 Trois points au sol (à vérifier par Pascal)

1. **Senones, mare ou prairie humide, 48,308254 ; 6,965473** (naturgucker, 2022-06-14) : quatre
   espèces à 3 m (`Lysimachia nummularia`, `L. vulgaris`, `Caltha palustris`, `Juncus acutiflorus`) ;
   et **48,307926 ; 6,973337**, trois espèces de pelouse sèche (`Briza media`, `Bromus erectus`,
   `Genista sagittalis`) à 570 m. Y a-t-il bien une zone humide ici et de la pelouse là, à ≤ 25 m
   du point ?
2. **Thann (Haut-Rhin), 47,837933 ; 7,061987 et 47,840321 ; 7,061588** (naturgucker, 2021-10-20) :
   `Aruncus dioicus` et `Lunaria rediviva`, espèces de ravins frais. Les points tombent-ils bien
   dans un ravin ou en bas de versant ? C'est le test du lien relief-gradient en miniature.
3. **Lieu-dit « Neuematten », 48,34486 ; 7,38116** (CardObs, 2012-06-09) : 12 espèces à un même
   point, dont source et lande sèche. Le point est-il une placette ou un centre de lieu-dit ?
   **Ce point est peut-être hors de D11** (piémont de Villé, polygone non croisé).

**Question de contrôle :** quelle décision cette donnée va-t-elle éclairer ? Si la calibration
relief-gradient se fait sur des occurrences GBIF à 25 m (espèce par espèce) faute de relevés
ouverts, ou s'il faut attendre le jeu de Dietz et al. ou l'accès fermé.

## 34. Richesse chimique continue du substrat : données géochimiques ouvertes en D11 et GRECO D (mission 038)

- **Décision éclairée :** retient-on, comme prédicteur à maille large du niveau trophique, une
  richesse chimique continue du substrat (équivalent du rapport Si/(Ca+Mg+Fe) de Piedallu et al.
  2006, brief § 2.4) tirée de données ouvertes, ou garde-t-on la lithologie de la BD Charm-50
  (§ 5) classée par rang.
- **Propriétaire :** Pascal (délégué à l'orchestrateur). **Rédigé par :** agent `acquereur`,
  mission 038, le 2026-11-19. **Outils :** `WebSearch`, `WebFetch` (pages résumées par un petit
  modèle), lecture en image de PDF enregistrés par l'outil (R 39979, RP-57133-FR, plaquette IRM,
  avis BOAMP 25-44109). **Pas de `curl`, pas de R** : aucun fichier de données téléchargé, aucun
  décompte de points en D11 (pas de croisement avec `ser_l93.shp`), rien dans `inst/extdata`,
  aucun compte, aucune demande d'accès. **Liste de contrôle** : non jointe à la consigne.
- **Surfaces de référence (§ 1) :** D11 5 319,0 km² ; D12 4 017,9 km² ; GRECO D 9 336,9 km².
  Les « points attendus » ci-dessous sont **la densité publiée multipliée par la surface** :
  ordres de grandeur, pas des décomptes.
- **URL et documents consultés le 2026-11-19 :**
  `https://infoterre.brgm.fr/rapports/RP-57133-FR.pdf` (Cary, Maton, Piantone, BRGM, déc. 2008,
  188 p. ; pages 5-6, 19-28 lues en image), `http://infoterre.brgm.fr/rapports//RR-39979-FR.pdf`
  (BRGM R 39979, déc. 1997, 21 p. + figures en volume séparé ; pages 1-8, 13-16 lues),
  `https://www.horbourg-wihr.fr/wp-content/uploads/2025/05/Plaquette-BRGM-inventaire-national-ressources-minerales.pdf`
  (BRGM, 2025, 6 p.), `https://www.boamp.fr/telechargements/FILES/PDF/2025/04/25-44109.pdf`
  (avis BRGM Explore n° 25-44109, 17/04/2025, pages 1-6 lues),
  `https://www.bgs.ac.uk/geology-projects/applied-geochemistry/international-geochemistry/foregs/`,
  `https://dev.s3webdav.containers.wur.nl/projects/wosis/repository/not_imported/ZZ-FOREGS/ForegsData.php.htm`
  et `…/disclaimer.php` (**copie** de la page du GTK, pas l'original), `https://gemas.eurogeosurveys.org/`,
  recherche web sur Nédeltcheva et al. 2006 (*Chem. Geol.* 231 : 1-15, DOI
  10.1016/j.chemgeo.2005.12.012, résumé seulement).
  **Inaccessibles ou sans résultat :** `weppi.gtk.fi` (certificat expiré, deux essais),
  `sigminesfrance.brgm.fr` (hôte introuvable), `infoterre.brgm.fr/page/geoservices-ogc` (404),
  `geoservices.brgm.fr/geologie` (erreur MapServer), `core.ac.uk/download/9697177.pdf` (403),
  API `data.gouv.fr` pour « géochimie sédiments » (0 jeu ; une seule requête), `RP-61745-FR.pdf`
  (9 Mo, texte non extrait : **non lu**).

### 34.1 Les sources, classées (CQQCOQP condensé)

| Source | Pourquoi / Qui | Quoi, éléments | Où, densité | Quand, précision | Licence, accès | Verdict |
|---|---|---|---|---|---|---|
| **A. BRGM, Inventaire minier : sédiments de ruisseau et sols** (base géochimique, ex-SIG Mines France) | Prospection de gîtes métalliques par le BRGM (service public), pas de la fertilité. | ICP-AES multi-éléments ; en Vosges, R 39979 p. 13-14 cartographie Ag, As, Ba, Cd, Cr, Cu, **Fe₂O₃** (0,1 %), Mo, **MnO**, Ni, **P₂O₅**, Pb, Sb, Sn, W, Zn : **ni Si, ni Ca, ni Mg, ni K** dans cette étude. La liste des couches d'InfoTerre (capture p. 24 de RP-57133, lisibilité moyenne) montre aussi **Calcium, Magnésium, Fer, Lithium, Phosphore**… ; la fiche d'échantillon (p. 25) porte des colonnes d'oxydes **illisibles** à cette résolution. | **Vosges couvertes** (RP-57133 p. 22 : massifs hercyniens « Massifs central et armoricain, Vosges » ; figure 7 p. 23 : carrés noirs sur le massif vosgien). Base nationale : > 280 000 échantillons + ≈ 60 000 SNEAP (2008) ; **0,5 à 3 échantillons par km²**, couverture < 20 % du territoire. Si cette densité vaut pour D11 : **≈ 2 700 à 16 000 points** (à mesurer). Cours d'eau de 2ᵉ ordre ≤ 1 km, bassin de quelques km² (R 39979 p. 13). | Campagnes 1975-1991 (RP-57133 p. 21) ; « plus de 15 ans » (R 39979) ; la plaquette de 2025 dit « 1970 et 1995 ». Limites de détection 10-20 ppm « élevées ». Localisation : « système de géoréférencement variable suivant les zones » (p. 21-22) : **précision non publiée**. Échantillon = **un point de cours d'eau intégrant un bassin**, pas une placette. | **Sans licence nommée** dans ce qui a été lu. RP-57133 : « Document public » ; « les données brutes […] visualisables sur InfoTerre ou **librement téléchargeables** sur sigminesfrance » (p. 24, texte de 2008). Rapports « © BRGM, ne peut être reproduit […] sans l'autorisation expresse du BRGM ». **Aucun téléchargement ouvert vérifié aujourd'hui** : InfoTerre fermé depuis le 21 oct. 2026 (§ 5), `sigminesfrance` introuvable, `data.gouv.fr` : 0 jeu. | **Seule source avec la densité et Ca, Mg, Fe. Accès et licence à établir par un humain avant tout usage.** |
| **B. BRGM, nouvel Inventaire des ressources minérales (IRM)** | Actualisation pour les métaux critiques (France 2030, ANR). | Sédiments de ruisseau + géophysique héliportée ; cibles Sn, W, Sb, Ba, F, Mo, Au, Pb-Zn. Éléments majeurs non précisés. | **Vosges = 1 des 5 zones** (plaquette p. 4, carte : un secteur au nord-est, étendue exacte non lue). Avis 25-44109 : lots Cévennes, Morvan-Brévenne, Massif central, Guyane ; **pas de lot Vosges** dans cet avis (autre avis non trouvé). | Départ fin 2024, 5 ans ; 18 mois de prélèvements pour les lots de 2025. Densité non publiée. | « La publication régulière de résultats tout au long du processus » (plaquette p. 4) ; licence et dates **inconnues**. | **À surveiller, pas utilisable aujourd'hui.** |
| **C. FOREGS (Atlas géochimique de l'Europe, 2005)** | Fond géochimique européen, EuroGeoSurveys, publié par le GTK. | Sédiment de ruisseau, eau, sol de surface (0-25 cm), sous-sol, humus, plaine d'inondation ; XRF (majeurs, dont probablement Si, Ca, Mg, Fe : **liste d'éléments non lue**), ICP-MS, ICP-AES. | **≈ 1 station pour 4 700 km²** (BGS) : **≈ 1 station en D11, ≈ 2 en GRECO D** (non comptées). | Coordonnées converties de systèmes nationaux en coordonnées géographiques (page « disclaimer ») ; précision non publiée. Fichiers de 2006-2007. | Fichiers zip (Excel) gratuits, un fichier par milieu, pays extractible par un champ de code. **Pas de licence nommée** ; copyright EuroGeoSurveys/GTK ; citation de Salminen (2005) et mention de l'atlas imposées. | **Contrôle seulement** : trop clairsemé pour une carte en D11. |
| **D. GEMAS (sols agricoles et prairies, 2014)** | EuroGeoSurveys + Eurometaux. | 39-42 éléments par XRF (totaux), 52-53 après eau régale. | **1 site pour 2 500 km²** (≈ 2 en D11) ; 2 211 + 2 118 échantillons. **France dans le jeu : non confirmé** (un code « FRA » vu dans une légende de brochure). | 2008-2009 (non lu à la source). Sols **cultivés** : peu de forêt. | **Pas d'accès libre vérifié** : contrat avec le président du groupe d'experts, résultats « librement » disponibles deux ans après le rapport qualité (date non lue). Le CC BY 4.0 de data.gov.ie ne vaut **que** pour la copie irlandaise. | **Écartée** (densité, sols cultivés, accès). |
| **E. Analyses de roches (CRPG Nancy, GEOROC, thèses)** | Pétrologie ; base citée par le brief pour Piedallu et al. 2006. | Roches totales, majeurs (SiO₂, CaO, MgO, Fe₂O₃). | Points isolés par faciès. | — | **Aucune base ouverte vosgienne trouvée** (CRPG : page historique de 1989-1990 seulement ; GEOROC : rien de vosgien dans les résultats). **Absence non prouvée** : GEOROC et les annexes de thèses (HAL, ex. tel-00755354) n'ont pas été interrogés à la source. | **Non retenue**, piste à fouiller par recherche directe. |
| **F. Eaux de ruisseaux** (Nédeltcheva et al. 2006) | Étude INRAE/AgroParisTech de 95 bassins forestiers sur granite. | Ca, Mg, K, Na, Si, SO₄, ANC, pH à l'étiage. | 95 bassins, granite vosgien seul. | Jeu **non trouvé en accès ouvert**. | — | **Pas une source de données ; une validation** (34.3). |

**Aucune source ouverte et téléchargeable n'a été vérifiée aujourd'hui qui donne Si, Ca, Mg et Fe à
une densité utile en D11.** Le rapport Si/(Ca+Mg+Fe) de Piedallu et al. **n'est pas reproductible**
avec le jeu de l'étude vosgienne de 1997 (pas de Si, Ca, Mg).

### 34.2 Règle des 700 m et système de coordonnées

- Compatible **à une condition** : un échantillon de sédiment de ruisseau représente un bassin de
  quelques km², pas un point de 25 m. Il ne doit donc jamais être extrait aux coordonnées d'une
  placette comme variable fine ; il se traite comme un prédicteur à maille large (valeur moyenne
  par bassin ou par formation de la BD Charm-50), croisable avec l'IFN comme la « géologie
  dominante dans un rayon de 700 m ». `loc_precision_m` : **valeur inconnue** pour A, C, D ;
  ne pas la renseigner par défaut, la poser à `NA` tant qu'elle n'est pas lue (la règle refuse
  alors l'extraction fine, ce qui est voulu).
- Coordonnées : A et B en système national de l'époque (Lambert II étendu visible p. 24 de
  RP-57133, capture d'écran) à reprojeter en EPSG:2154 à l'import ; C en géographique (système non
  nommé, supposé WGS84 : **à vérifier**).

### 34.3 Deux sources par point : ce qui concorde, ce qui diverge

1. **Le substrat règle la chimie du ruisseau.** Nédeltcheva et al. 2006 (95 bassins, granites
   vosgiens) : le calcium s'explique par la teneur en hornblende, le magnésium par celle de la
   biotite et de la hornblende, Si suit Na ; Ca, Mg et le pH baissent avec les précipitations.
   RP-57133 p. 23 : les signaux des sédiments de ruisseau et des sols sont « relativement
   comparables à l'échelle locale ». Deux sources d'origine différente (eaux d'étiage, sédiments)
   disent la même chose : **le ruisseau lit la roche**. Concordance : on peut avancer.
2. **Le Fer des sédiments n'est pas la richesse du substrat.** R 39979 p. 3 : les fortes
   teneurs en Pb, Zn, Cu, Ag, As se concentrent dans les districts de **Sainte-Marie-aux-Mines**,
   **La Croix-aux-Mines**, **Plancher-les-Mines**, **Auxelles**, **Giromagny** ; p. 15 : le fer
   se trouve en pyrite et en oxydes autant que dans les minéraux ferromagnésiens. Un Fe de
   sédiment élevé peut venir d'une minéralisation, pas de biotite. **Écart de sens** : à traiter en
   ne gardant que Ca et Mg (non confirmés en Vosges), ou en excluant les bassins miniers.
3. **Le rapport de Piedallu n'a pas été retrouvé.** La recherche web n'a trouvé ni Si/(Ca+Mg+Fe)
   ni Stussi 1995 ni la base du CRPG ; ce que dit le brief à ce sujet reste **non vérifié par
   l'acquéreur**.

### 34.4 Écarts relevés entre sources (§ 34)

1. Période de l'inventaire minier : 1975-1991 (RP-57133) ; « plus de 15 ans » (R 39979) ;
   1970-1995 (plaquette 2025).
2. Taille de la base : > 280 000 échantillons (RP-57133, 2008, lu) contre 343 067 échantillons de
   sédiments de ruisseau + 96 924 de géochimie (résumé de moteur de recherche d'un rapport
   BRGM, **RP-61745-FR non lu**).
3. GEMAS : 2 211 + 2 118 échantillons (site du projet) contre 2 108 + 2 023 (résumés EGU 2014) ;
   39 contre 41-42 éléments en XRF ; 53 contre 52 après eau régale.
4. FOREGS : 1 station pour 4 700 km² (BGS, GEUS) contre 1 pour 5 000 km² (cible du réseau de
   référence mondial).
5. Fiche d'échantillon de l'inventaire : la capture de RP-57133 (fig. 9) cite « Arnault (88) » ;
   commune non vérifiée (lecture d'une capture d'écran, à confirmer sur l'original).
6. Le CC BY 4.0 de la copie irlandaise de GEMAS ne s'étend pas à l'original (aucune licence
   nommée sur le site du projet).

### 34.5 Recommandation classée

1. **Ne pas bâtir de raster de richesse chimique continue à partir de données ouvertes
   aujourd'hui** : rien de téléchargeable et libre n'a été vérifié pour Si, Ca, Mg, Fe en D11.
2. **Garder la lithologie de la BD Charm-50 (§ 5) comme prédicteur de substrat**, classée
   par rang de richesse (ordinal, avec l'incertitude affichée). Appui publié : Nédeltcheva et al.
   2006 (hornblende → Ca, biotite → Mg). Le classement par minéraux est **une proposition à
   valider**, non une nomenclature.
3. **Piste à ouvrir par un humain (Pascal) : l'Inventaire minier du BRGM** (source A) : seule
   source avec ≈ 0,5 à 3 points par km² et Ca, Mg, Fe. Vérifier : (a) un téléchargement existe-t-il
   encore après la refonte d'InfoTerre (bêta annoncée fin décembre 2026) ; (b) la licence ; (c) les
   colonnes Ca, Mg, Si, K ; (d) la précision des coordonnées. Si oui : **moyenne par formation
   BD Charm-50**, sans extraction aux coordonnées des placettes ; un extrait dans `inst/extdata`
   seulement avec licence nommée.
4. **IRM (source B)** : relancer la recherche quand les premiers résultats Vosges seront publiés.
5. **FOREGS** : un contrôle de sens (1 station en D11) ; **GEMAS, F, E** : écartées pour l'instant.

### 34.6 Trois points au sol (à vérifier par Pascal)

Aucune coordonnée n'est donnée : le référentiel ne permet pas de les établir sans inventer.

1. **Granite de Kaysersberg (`h3M2Ka`) contre gneiss à sillimanite (`Smæsill`)**, emprise test
   (§ 5, 21,45 et 27,16 km²) : deux roches cristallines voisines, l'une riche en biotite,
   l'autre en sillimanite. Le sol et le sous-bois diffèrent-ils (humus, pH, espèces acidiphiles) ?
   C'est le test de ce que le substrat cristallin apporte au-delà de « cristallin ».
2. **Grès vosgien contre granite de Kagenfels**, sites d'essais de fertilisation de l'INRAE (§ 33.4 :
   Vologne et Mortagne sur grès ; Grendelbruch et Russ sur granite) : le sol sur granite est-il
   franchement plus riche que sur grès ? Si la différence est faible, une échelle ordinale à
   deux classes suffit.
3. **Districts miniers de Sainte-Marie-aux-Mines et La Croix-aux-Mines** (R 39979) : y a-t-il, à
   l'échelle du versant, des teneurs en fer et en métaux sans lien avec la richesse du sol
   forestier ? Si oui, le Fe des sédiments ne doit pas servir de proxy de richesse.

**Question de contrôle :** quelle décision cette donnée va-t-elle éclairer ? Si le trophique à
maille large s'appuie sur une richesse chimique mesurée, ce qui exige l'accès à l'Inventaire minier
du BRGM, ou sur la lithologie de la BD Charm-50 classée par rang.


# Passe 8 (mission 035, 2026-11-19) : calibration sur toute la GRECO D

## 35. Calibration régionale sur la GRECO D : effectifs, géologie, pH SoilGrids, encodages

Mesures exécutées le 2026-11-19 sur les placettes IFN de la GRECO D (store du run 018 en lecture
seule pour `ifn`, `indicateurs` ; SAFRAN, BD Charm-50 et SoilGrids lus avec le code de la
branche `mission-035-calibration-greco`). Scripts et sorties : scratchpad de la session, non
versés. R² par blocs spatiaux : blocs de 8 358 m (portée estimée en 018), 5 plis, `ranger` 500
arbres, **moyenne de 5 affectations de blocs aux plis** (graines 1 à 5) ; IC à 95 % et gain par
bootstrap de blocs (1 000 tirages, graine de plis 1). Réponse : indice trophique de Tichý
(historique), sauf mention.

### 35.1 Effectifs : où se perdaient les placettes

| Étape | n | Perdues | Cause |
|---|---|---|---|
| lignes `PLACETTE` de la GRECO D (D11 6 475, D12 2 917) | 9 392 | | une ligne par visite |
| avec relevé `ECOLOGIE` | 5 354 | 4 038 | la 2e visite n'a ni écologie ni flore |
| relevé en saison (avril à septembre) | 3 024 | 2 330 | `filter_releves(months = 4:9)` |
| sans incident récent | 2 923 | 101 | `NINCID`, `INCID` |
| trophique calculable | **2 894** (D11 2 116, D12 778) | 29 | aucune espèce à valeur indicatrice |
| avec climat SAFRAN | 187 en 018 ; **2 894** ici | 2 707 en 018 | **cache SAFRAN périmé** |
| avec lithologie (disque couvert à 50 % ou plus) | 2 893 | 1 | disque hors des 7 départements |
| apprentissage trophique final (avec pH SoilGrids) | 2 893 | | |
| apprentissage hydrique | 2 827 | 67 | réserve utile ou BILJOU manquant |

Le « 187 » de 018 n'était pas une limite des données : la cible `safran` demande la boîte de
toutes les placettes de la GRECO, mais `fetch_safran()` renvoyait tout fichier
`emprise_<année>.csv` existant sans regarder l'emprise, donc les 12 mailles lues en 017.
Corrigé : le nom du fichier porte désormais l'emprise (`emprise_<année>_x<boîte>_m<marge>.csv`).
**À vérifier** : le mécanisme exact dans le run 018 (confirmé par la lecture du code et par la
chute à une seule étape, non par un nouveau `tar_make` complet).

### 35.2 SAFRAN sur la GRECO D

| Point | Résultat |
|---|---|
| Emprise lue | boîte des placettes (909 550 à 1 060 558 est ; 6 723 356 à 6 912 236 nord) + marge de 5,66 km : **497 mailles** (182 portent des placettes) |
| Coût | 30 `.csv.gz` complets déjà en cache (aucun téléchargement) ; filtrage en R : **25 min** ; 30 fichiers filtrés de 284 Mo au total (colonnes lues seulement) ; `read_safran` 72 s et 436 Mo en mémoire (5 446 126 lignes) ; `safran_climate` 65 s ; `ifn_real_gradients` 126 s |
| Résultat | 2 894 placettes avec climat bilinéaire (033) ; hydrique 2 827 |

### 35.3 BD Charm-50 : 4 départements ajoutés

Téléchargés le 2026-11-19 depuis `https://infoterre.brgm.fr/telechargements/BDCharm50/GEO050K_HARM_0DD.zip`
(même motif que § 5 ; `unzip -t` sans erreur) : 054 (12 327 478 octets), 057 (20 790 543),
070 (25 721 862), 090 (4 906 068). Avec 067, 068, 088 : 39 643 polygones, **666 formations**
(`NOTATION`), lecture 64 s. Le site InfoTerre est annoncé fermé (§ 5) : copie locale dans
`data/cache/bdcharm`, hors dépôt. **Placette `DEP` = 52 (1) : non couverte** (département non lu).

Lithologie dominante dans 700 m (règles provisoires 008, non validées) : 2 893 placettes avec
géologie. Classes dominantes : grès 744, conglomérat 740, granite 502, `non_classe` 296,
gneiss/migmatite 227, marne/argile 144, alluvions 133, colluvions/éboulis 28, glaciaire 41,
calcaire 18, lœss 18, roche basique 2.

**Formations sans règle (jamais affectées)** : 170 formations (1 465 km² sur 25 774 km² lus) ;
155 d'entre elles tombent dans les disques (435 km²) ; 296 placettes ont `non_classe` pour classe
dominante. Les plus étendues dans les disques : `h2-3LãER` (leucogranite d'Épinal et de Remiremont,
32 km²), `h2PK` et `h2PK3` (complexe volcanique de Plancher-Bas, 31 et 21 km²), `h2ã4CFS` (granodiorite du
Champ-du-Feu, 21 km²), `h2-3ã3Sn` (monzogranite de Senones), `h2öáq`, `d-h`, `h2Góá` (volcanites),
`P` (épandages de piémont), `o-s` (schistes de Steige), `FzI` (limons de l'Ill). Les règles
provisoires manquent surtout les roches cristallines dont la description ne commence pas par
« granite » (« leucogranite », « massif granitique », « monzogranite »). **Décision de Pascal**
(règles à ajouter, jamais par défaut). Défauts observés des règles actuelles, non corrigés ici :
« Grès vosgien … souvent conglomératique » (`t1b`) → `conglomerat` (règle 1 avant grès) ;
« Calcaires oolithiques … marnes » (`j2b2`) → `marne_argile` (règle 11 avant calcaire).

### 35.4 pH SoilGrids 2.0 (`phh2o`, 0-5 cm)

| Point | État | Résultat |
|---|---|---|
| Source | **vérifié** (lu en 019, § 18 ; relu le 2026-11-19) | `https://files.isric.org/soilgrids/latest/data/phh2o/phh2o_0-5cm_mean.vrt` (3,5 Mo, `HTTP 200`), Homolosine, 250 m, `Int16`, pH × 10, `NoDataValue` −32768, CC BY 4.0 (ISRIC) à citer |
| Lecture d'une fenêtre | **vérifié** (exécuté) | `terra::rast("/vsicurl/…")`, `crop` sur la fenêtre transformée, `project` bilinéaire vers Lambert-93 à 250 m : **9 s, 1,8 Mo** pour la GRECO D (772 × 621 cellules, 6,7 % sans valeur), pH de 4,15 à 7,3 |
| Moyenne dans 700 m | fait | `soilgrids_disk_mean()` : fenêtre circulaire de 5 × 5 cellules de 250 m (coins exclus) ; `raster_at_points()` : interpolation bilinéaire, règle des 700 m appelée avant |
| Exactitude sur la France | **non évaluée** | SoilGrids est modélisé avec le climat et le relief comme covariables (fiche ISRIC) : information partagée avec nos prédicteurs, non indépendante ; aucune confrontation à des mesures françaises ici |
| Corrélation | mesurée | pH SoilGrids (moyenne 700 m) et indice trophique : **0,35** sur 2 893 placettes (0,06 à 0,09 sur les 96 placettes de la seule fenêtre du plan) |

### 35.5 R² par blocs spatiaux

| Jeu | Prédicteurs | R² (moyenne de 5) | Gain, IC 95 % (graine 1) |
|---|---|---|---|
| 2 894 placettes | climat bilinéaire (033) | **-0,127** [-0,199 ; -0,088] | |
| 2 893 | climat | -0,129 | |
| 2 893 | + lithologie provisoire, facteur | 0,146 | +0,288 [0,235 ; 0,347] |
| 2 893 | + lithologie encodée (classe, hors pli) | 0,090 | +0,219 [0,160 ; 0,279] |
| 2 893 | + lithologie encodée (classe, toute la partie d'apprentissage) | 0,151 | |
| 2 021 (3 départements) | climat / + facteur / + encodée hors pli | -0,101 / 0,124 / 0,073 | +0,216 [0,164 ; 0,266] / +0,181 [0,113 ; 0,245] |
| 2 893 | + classe encodée + pH SoilGrids | 0,170 | pH : +0,084 [0,049 ; 0,122] sur classe hors pli |
| 2 893 | formation encodée (k = 10) | 0,196 [0,135 ; 0,243] | +0,121 [0,069 ; 0,168] sur la classe hors pli |
| 2 893 | formation encodée (k = 30) | 0,193 | |
| 2 893 | classe + formation | 0,212 | +0,134 [0,087 ; 0,178] |
| 2 893 | **classe (toute la partie) + formation (hors pli) + pH** | **0,270** | **+0,405 [0,333 ; 0,480]** sur le climat seul ; R² [0,199 ; 0,311] (graine 1 : 0,259) |
| 2 893 | idem, formation non hors pli | 0,242 | |
| 2 893 | **sans aucun prédicteur climatique** (classe + formation + pH) | 0,265 | le climat apporte +0,005 (climat de la maille ou bilinéaire : 0,270 dans les deux cas) |
| 2 893 | contrôle : roche observée IFN (`ROCHE`, encodée) | 0,056 | |
| 2 893 | contrôle : `ROCHE` + classe | 0,129 | +0,035 [0,009 ; 0,058] sur la classe seule |
| 2 893 | **contrôle : humus observé (`HUMUS`, encodé) + classe** | **0,406** | non utilisable pour la carte |

**Taille des blocs (correction de la relecture 1).** Tous les R² ci-dessus sont calculés avec
des blocs de **8 358 m** (portée estimée en 018 sur l'emprise test). Le pipeline, lui, publie
par défaut (`cv_block_m: null`) la **portée estimée sur la réponse, 22 121 m pour le trophique de
la GRECO D (37 blocs)**, le chiffre le plus prudent :

| Blocs | Modèle final (classe + formation + pH) | Climat seul | Gain sur le climat seul |
|---|---|---|---|
| **portée estimée, 22 121 m (publié)** | **0,193** [0,087 ; 0,275] | -0,263 | +0,449 [0,290 ; 0,621] |
| 8 358 m (sensibilité, `cv_block_sensibilite_m`) | 0,270 [0,199 ; 0,311] | -0,129 | +0,405 [0,333 ; 0,480] |

(moyennes de 5 affectations de plis ; IC et gain : bootstrap de blocs, graine de plis 1 ;
le modèle final contient la même géologie et le même pH dans les deux cas). Le R² du pipeline
est donc d'environ **0,19** et non 0,27 : les blocs plus grands retirent l'autocorrélation
spatiale résiduelle. Les deux lignes figurent dans `val_stats` et le rapport.

**Hydrique : même sensibilité, et alerte.** Relance réelle de 018 avec la calibration (2026-11-20,
2 827 placettes, prédicteurs climatiques seuls ; IC par bootstrap de blocs, calculés sur les
prédictions de `cvs` du store du run pour la portée estimée, hors store pour 8 358 m) :

| Blocs | R² hydrique | IC 95 % | Blocs occupés |
|---|---|---|---|
| portée estimée, 76 736 m (publié) | 0,285 | [-0,288 ; 0,385] | **8** |
| 8 358 m (sensibilité) | **0,358** (5 graines : 0,355 à 0,369) | [0,248 ; 0,442] | 162 |
| 20 000 m (non publié) | 0,309 | | |

À la portée estimée, 8 blocs se partagent 5 plis et un pli de 240 placettes (R² -1,62) porte le
chiffre global : R² par pli -0,18 / 0,12 / 0,04 / -1,62 / 0,16. La portée n'est pas plafonnée
(ce serait un changement de méthode) ; la table de validation porte `blocs`, `k`,
`blocs_insuffisants` (seuil `cv_min_blocs_par_pli` = 4 blocs par pli, **provisoire, à
vérifier**) et une alerte en clair, et la sensibilité à blocs fixes est calculée pour chaque
gradient. Trophique à titre de comparaison : 37 blocs (publié, 0,194) et 163 blocs (0,272).

Lecture : le climat seul n'a aucun pouvoir (R² < 0) ; la géologie (formation) et le pH de sol
apportent presque tout ; la formation (`NOTATION`, 666 niveaux) bat la classe lithologique
provisoire à 12 niveaux ; la carte géologique explique plus que la roche notée par l'IFN
(0,196 contre 0,056). L'**humus**, relevé sur le terrain, explique le trophique (0,41) parce qu'il
est lui-même une conséquence de la richesse du sol que reflète la flore : **contrôle de plafond,
jamais prédicteur de carte**, circularité possible avec l'indice floristique. Le R² (0,19 à blocs prudents, 0,27 à blocs de 8 358 m) reste
sous la référence de 0,36 (Vosges ; autre méthode, autres données).

**Climat plus proche voisin contre bilinéaire (033)** : sur les mêmes 2 893 placettes, le climat
seul donne +0,045 avec la valeur de la maille (166 valeurs distinctes de `t_moy`) et -0,129 avec
l'interpolation bilinéaire (1 628 valeurs) ; avec la lithologie (classe hors pli) : 0,130 et
0,090. L'interpolation bilinéaire, lissée à 8 km, n'ajoute pas d'information et dégrade la
validation par blocs. Une fois la géologie et le pH dans le modèle, les deux climats donnent le
même R² (0,270) et le modèle **sans climat** 0,265 : à l'échelle de la GRECO D, avec des mailles
de 8 km, le climat SAFRAN n'apporte quasiment rien au modèle régional ; il reste utile comme
variable explicite pour les scénarios (brief § 2). **À trancher avec la relecture de 033** (clé
`safran_interpolation`).

### 35.6 Réponse trophique : ancienne et nouvelle côte à côte

Indice de Tichý (moyenne de `ph` et `azote` des espèces à valeur indicatrice) : **y0** historique ;
**y1** sans les essences arborées (`espar-cdref13.csv`, 192 `CD_REF`) ; **y2** sans essences et
pondéré par l'abondance-dominance `ABOND` (milieux de classes 2,5 ; 15 ; 37,5 ; 62,5 ; 87,5 % :
**à vérifier**, non sourcés) ; **y3** pondéré seul.

| Réponse | n | Corrélation avec y0 | R² climat | R² climat + classe (hors pli) | R² + humus encodé |
|---|---|---|---|---|---|
| y0 | 2 894 | 1 | -0,129 | 0,090 | 0,406 |
| y1 | 2 854 | 0,962 | -0,122 | 0,118 | 0,436 |
| y2 | 2 854 | 0,940 | -0,112 | 0,110 | 0,445 |
| y3 | 2 894 | 0,956 | -0,117 | 0,090 | 0,403 |
| y2, modèle final (classe + formation + pH) | 2 853 | | | **0,286** [0,218 ; 0,332] (y0 : 0,270) | |

Retirer les essences perd 40 placettes (aucune autre espèce indicatrice) et change peu l'indice
(corrélation 0,96) : le peuplement pèse peu dans l'indice de Tichý ici. Le R² de y1 et y2 est un
peu plus haut (+0,02 à +0,03) sans que les IC se séparent. **Les R² de réponses différentes ne
sont pas strictement comparables** (variances différentes). Non activée dans `_targets.R`
(décision de Pascal : réponse historique conservée jusqu'à arbitrage) ; la variante est
disponible (`compute_gradients(exclude_cd_ref = read_tree_cd_ref(), abundance_weights = TRUE)`).

### 35.7 À vérifier

- Mécanisme exact du « 187 » dans le run 018 (cache SAFRAN resservi) : relire par un `tar_make`
  complet sur copie, non fait ici (coût LiDAR).
- Règles de lithologie (008) : provisoires, non validées ; 170 formations sans règle ; défauts
  `t1b`, `j2b2` ; règles à décider par Pascal avant tout usage hors comparaison.
- Aucune correction de la table de lithologie appliquée aux départements 054, 057, 070, 090.
- Exactitude de SoilGrids sur la France ; redondance avec le climat (covariables du modèle).
- Poids d'abondance (milieux de classes `ABOND`) ; poids `litho_encoding_k = 10` (valeurs
  provisoires, k = 30 donne 0,193 contre 0,196).
- Codes `ROCHED0` (2005-2024) et `ROCHED2` (2025) : mêmes codes à trois exceptions (312, 316, 932
  absents de `ROCHED2`, rares) : joints tels quels.
- Placette `DEP` 52 : sans géologie (département 052 non lu).


## 36. Contrôle par essence et sensibilité : sources, seuils, mesures (mission 037, 2026-11-20)

- **Décision éclairée :** vérifier que le trophique prédit ne contredit pas les essences en place, et
  chiffrer ce que l'essence ajouterait, sans jamais la mettre dans la carte (ADR 0008).
- **Propriétaire :** Pascal (délégué à l'orchestrateur). **Rédigé par :** `dev`, mission 037, partie 2.

### 36.1 Sources

| Élément | Source | État |
|---|---|---|
| Essence et pondération | IGN, IFN, table `ARBRE` : `ESPAR`, `C13` (circonférence, m), `W` (coefficient de pondération), `VEGET` (0 vivant, 1 chablis vivant) | **vérifié** (`metadonnees.csv`) |
| Dictionnaire ESPAR | `espar-cdref13.csv` (`ifn_espar_cdref.csv`, code d'essence sans zéro de tête → `CD_REF`) pour les jointures ; lignes `ESPAR1` de `metadonnees.csv` (campagnes 2009 et suivantes) : `inst/extdata/ifn_espar_codes.csv`, 195 lignes, Licence Ouverte 2.0, qui en complète le nom latin de l'unité ESPAR1 (`inst/extdata/SOURCES.md`) | **vérifié** ; le code `332G` de `ARBRE` n'y figure pas ; les campagnes 2005-2008 (unités `ESPAR`, `ESPAR0`) : même codage constaté sur la GRECO D, **à vérifier** |
| Optimum de l'essence, repère | Tichý et al. (valeurs d'indicateur, Zenodo), `ph` et `azote` de l'espèce arborée dans la table qui sert au trophique | **indicatif seulement, jamais la base d'une alerte** : Spearman 0,15 par placette, 0,29 à 0,38 par essence, contre 0,25 et 0,60 pour le trophique observé ; hêtre 5,7 contre 4,2 observé sans les arbres ; douglas et chêne rouge absents ; chêne sessile sans `ph` ni `azote` |
| Optimum forestier publié | Rameau et al., *Flore forestière française* ; EcoPlant ; Landmann | **à vérifier, non lus** |
| Alerte | moyenne d'essence apprise hors pli sur le trophique observé sans les essences : **47 taxons** des 344 de la table de Tichý, retirés par jointure sur `CD_REF` avec `read_tree_cd_ref()` (`espar-cdref13.csv`, TAXREF v13.0 ; cette table liste les arbres et quelques arbustes, dont *Juniperus communis*) | mesure du dépôt (pas une source externe) |
| Regroupements BD Forêt | `FF1G01-01` (chênes décidus), `FF2G61-61` (sapin ou épicéa) ; `FF2G53-53` et `FF2-90-90` fusionnés | correspondance ESPAR **hypothèse, à vérifier** (§ 33, plan 037) |
| Licence BD Forêt | Licence Ouverte (data.gouv.fr, `lov2`) contre « conditions générales d'utilisation des fichiers IGN » (métadonnées livrées, 2022-09-14) | **contradictoire** : option désactivée, cache hors dépôt, seules des moyennes par classe publiées |

### 36.2 Seuils : valeur provisoire, sans source, à vérifier

`essence_part_pure` 0,75 ; `essence_min_placettes` 15 ; `essence_alerte_ecart` 0,5 point (environ la moitié du
RMSE de la validation croisée, 0,93) ; `essence_alerte_ratio` 0,5 ; `essence_alerte_pente` 0,2 ;
`bdforet_tampon_m` 50. Choisis par le `dev`, modifiables dans `config.yml` ; aucune source ne les fonde.

### 36.3 Mesures sur le run réel 035 (store `wt035run`, blocs 22 121 m et 8 358 m)

- **Effectifs** : 2 893 placettes d'apprentissage, 2 795 avec arbres vivants, 98 sans arbre, **1 323 pures**,
  1 472 mixtes ; 10 essences à au moins 15 placettes pures (1 246 placettes) : sapin pectiné 383, hêtre 276,
  épicéa 264, chêne sessile 101, pin sylvestre 71, douglas 64, aulne glutineux 28, bouleau verruqueux 26,
  chêne pédonculé 18, érable sycomore 15.
- **Contrôle** : accord d'ordre (Spearman prédit hors pli contre moyenne d'essence apprise hors pli) 0,344
  (blocs de 22 121 m) et 0,338 (8 358 m), contre **0,357 et 0,376** pour le trophique observé (ratio 0,96 et 0,90) ; **pente prévu contre observé par essence
  0,31 / 0,36 : prédictions écrasées vers la moyenne** ; trois essences en alerte d'écart (> 0,5) aux deux
  tailles : pin sylvestre (+0,89), aulne glutineux (-1,02), érable sycomore (-0,86). R² de la prédiction
  par l'essence (essences à au moins 15 placettes) 0,17 / 0,15 contre 0,22 pour le trophique sans arbres.
- **Sensibilité** (essence encodée dans chaque pli) : R² 0,194 -> 0,255 (**+0,061**) aux blocs de 22 121 m
  et 0,272 -> 0,330 (**+0,058**, groupes BD Forêt : 0,326, +0,054) aux blocs de 8 358 m ; **placebo**
  (essences mélangées) : +0,010 et +0,007, soit un gain net de l'ordre de 0,05. Le gain est positif dans les
  cinq plis des deux tailles. C'est bien moins que les -0,1 à -0,25 que chiffrait l'ADR 0008.
  **La cible de la sensibilité (`y0`, trophique du pipeline) contient les arbres** : le gain est donc un peu
  circulaire ; l'effet reste faible (retirer les essences de l'indice change peu l'indice, corrélation 0,96,
  § 35.6).
- **Comparaison à la carte (BD Forêt)**, emprise de 15 km, intérieur à 50 m, 295 polygones purs : moyennes par
  classe de 4,69 (pin sylvestre) à 5,07 (autres feuillus), Spearman 0,94 avec la moyenne IFN sur 6 classes
  seulement ; le hêtre y est placé sous le sapin-épicéa, à l'inverse des placettes. Lecture, pas validation.

**Limites** : une seule répartition en plis ; le contrôle n'est pas une validation indépendante (essences
liées au climat et à la roche que le modèle voit) ; les alertes pointent surtout l'absence de relief fin,
attendue sous la règle des 700 m ; plantations (douglas, épicéa) lues « pauvres » : limite visée par l'ADR 0008.

## 37. Bioclimat et réserve utile plus fins : température corrigée du relief, MNT de 250 m, RU apprise, bilan latéral (mission 039, 2026-11-20)

- **Décision éclairée :** rendre au bioclimat et à la RU de la carte le relief et les sols, sans croiser de
  variable fine avec les placettes IFN.
- **Propriétaire :** Pascal (délégué à l'orchestrateur, arbitrages du 2026-11-20). **Rédigé par :** `dev`, mission 039.

### 37.1 Sources

| Élément | Source | État |
|---|---|---|
| MNT de 250 m | BD ALTI (IGN), fiche `IGNF_BD-ALTI` (`https://data.geopf.fr/csw?REQUEST=GetRecordById&SERVICE=CSW&VERSION=2.0.2&OUTPUTSCHEMA=http://standards.iso.org/iso/19115/-3/mdb/2.0&elementSetName=full&ID=IGNF_BD-ALTI`) : **Licence Ouverte / Open License** (Etalab) | **vérifié** le 2026-11-20 (fiche lue) |
| Accès | WMS raster de la Géoplateforme, `https://data.geopf.fr/wms-r/wms`, couche `ELEVATION.ELEVATIONGRIDCOVERAGE` (titre « MNT BDAlti V1 », résumé « BDAlti V1 au pas de 25m »), `FORMAT=image/geotiff` : GeoTIFF Float32, `CRS=EPSG:2154`, `BBOX=xmin,ymin,xmax,ymax`, 5 010 pixels au plus par côté | **vérifié** (requête exécutée, `HTTP 200`, altitudes plausibles : 182 à 1 205 m autour de l'emprise test) |
| Pas de 250 m | le flux de téléchargement `https://data.geopf.fr/telechargement/resource/BDALTI` ne propose que le pas de 25 m par département (106 entrées lues) : le 250 m est demandé au WMS à 125 m puis moyenné 2 × 2 (`fetch_mnt_large()`) | rééchantillonnage du service **non documenté, à vérifier** |
| Volume, temps | GRECO D et emprise, marge 12 km : 701 × 852 cellules, **2,4 Mo, 6 s** | mesuré |
| Contrôle | écart au MNT de 250 m des mesures du plan (provenance non tracée alors) : moyenne 0 m, écart-type 10 m | mesuré : c'était la BD ALTI |
| Textures SoilGrids | SoilGrids 2.0 (ISRIC, CC BY 4.0), `clay`, `sand`, `silt` (g/kg, stockés × 10), `cfvo` (cm³/dm³, × 10), moyenne, six horizons (0-5 à 100-200 cm), `https://files.isric.org/soilgrids/latest/data/<propriété>/<couche>.vrt` (même accès que le pH, § 35.4) | **vérifié** (lu) ; 24 couches, 45 Mo pour la GRECO D ; exactitude sur la France **non évaluée** |
| Fonction de pédotransfert | euptf2 PTF01 (FC_2 − WP, pF 2,0 − 4,2), comme `ru_from_texture()` (ADR 0006) | appliquée telle quelle ; environ 3,2 mm/cm pour un limon à 20 % d'argile sans cailloux (RU à 1 m de 212 à 261 mm sur l'emprise) : valeur haute, **à vérifier** |
| Gradient de comparaison | −0,55 °C/100 m, Rolland (2003) | **à vérifier** (non lu ; repère seulement) |
| Altitude de référence de SAFRAN | altitude moyenne de la maille (Vidal et al. 2010, doi 10.1002/joc.2003) | **à vérifier** sur le texte ; les mesures vont dans ce sens (§ 37.2) |
| Bilan latéral | Piedallu et al. (2006), HAL `hal-00835906`, tableau 20 (p. 53 imprimée), tableau 21, équivalents −30 / 0 / +60 mm (p. 54) | lu (copie locale, non versée au dépôt) ; coefficients **à vérifier** (unités de la courbure, calcul de l'indice de Moore, MNT de 50 m non donnés) |

### 37.2 Température : méthode retenue et écart à la fiche

La fiche nommait meteoland (Thornton 1997). Mesure (validation croisée, une maille SAFRAN laissée de côté,
erreur sur sa T moyenne, GRECO D) :

| Méthode | RMSE, toutes mailles | RMSE, mailles en relief |
|---|---|---|
| Bilinéaire (avant 039) | 0,22 °C | 0,76 °C |
| Gradient fixe −0,55 °C/100 m | 0,11 °C | 0,17 °C |
| **Gradient lu dans SAFRAN, maille exclue** | **0,11 °C** | **0,16 °C** |
| meteoland 2.2.8 (75 mailles à moins de 40 km, 2011-2020) | 0,12 °C | non séparé |

(Mesures du plan, reproduites par `t_correction_validation()` sur la BD ALTI : 0,224 / 0,112 / 0,111 °C ;
0,764 / 0,171 / 0,157 °C en relief, 16 mailles. CHELSA V2.1, 1 km, contrôle indépendant : écart-type de
l'erreur 0,55 °C en bilinéaire contre 0,23 °C avec gradient.)

**Retenu (arbitrage du 2026-11-20) :** `T = T_bilinéaire + G × (z − z_bilinéaire)`, G estimé par
`T ~ z_moy + x + y` sur les mailles de la SER (`safran_lapse_rate()`) : **−0,486 °C/100 m** sur la GRECO D
(erreur type 0,007, R² 0,92, 475 mailles). Altitude des mailles = **moyenne** du MNT sur la maille
(`safran_cell_altitude()`) : RMSE 0,11 contre 0,34 °C avec l'altitude du centre. meteoland n'entre pas dans
`DESCRIPTION` : même justesse, sans dépendance ni coefficient extérieur.

### 37.3 Règle des 700 m

| Couche | Rôle | Classe |
|---|---|---|
| `coarse_t_corr_700m` | T corrigée sur la BD ALTI 250 m, moyennée dans un disque de 700 m | **large** : placettes IFN (bioclimat, hydrique, trophique si `trophique_climat: corrige`) |
| `t_corr` | T corrigée sur le MNT de la grille | **fine** (`FINE_VARIABLES`) : carte seulement (bioclimat appliqué à la cellule) |
| `t_corr_250`, `mnt_250` | intermédiaires | **fines** |
| `coarse_cu_*_700m` | capacité en eau SoilGrids par horizon, moyennée dans 700 m | **large** |
| `curv150`, `idr_1500`, `moore`, `p_*`, `bilan_lateral`, `ru_bilan_lateral` | bilan latéral | **fines** |

Coût du changement d'échelle (emprise test, cellules de 20 m) : la moyenne dans 700 m porte 94 % de la
variance de la T corrigée (résidu : écart-type 0,26 °C) ; 0,29 % des cellules hors de la plage
d'apprentissage. Tests : `coarse_t_corr_700m` passe l'assertion, `t_corr` la déclenche.

### 37.4 RU de la carte

RU SoilGrids brute (diagnostic seulement, `ru_soilgrids()`, `ru_soilgrids_diagnostic()`), 2 846 placettes :
à 1 m, **biais +137 mm** (244 mm contre 107), RMSE 148 mm, corrélation 0,27, écart-type 13 mm contre 58 ;
à 50 cm, biais +18 mm, corrélation 0,26. La RU IFN dépend surtout de la profondeur de sondage
(corrélation 0,66 avec `PROF2`), que SoilGrids ignore. **Retenue :** RU des placettes apprise
(`ru_learned_data()`, forêt aléatoire) sur la lithologie et la formation encodées dans 700 m et les six
capacités SoilGrids moyennées dans 700 m ; cellules sans prédicteur complétées par la RU de la maille
(`ru_fill_by_cell()`). R² par blocs : § 37.6.

### 37.5 Bilan latéral (option C)

Câblé (`lateral_balance()`), **désactivé par défaut** (`bilan_lateral: false`), jamais ajouté à la RU de
BILJOU. Appliqué tel quel à l'emprise test (mesure de la mission 034) : **53 % d'apports** (+60 mm) et 0 à
0,1 % de départs, contre **27,6 % d'apports** et 25,9 % de départs observés en calibration (tableau 21) ;
le modèle d'origine ne reclasse bien que 57,4 % des relevés (pseudo-R² 0,112). Coefficients dans
`config.yml` (`bilan_lateral_coef`), à vérifier ; à recalibrer sur les points GNSS (mission 029).

### 37.6 Mesures avant / après (store du run réel 035, 5 graines)

Deux séries de cinq graines, sur le store du run 035 (2 893 placettes trophique, 2 827 hydrique, 2 754
bioclimat ; RU : 2 892). **Graines de la forêt seules** (plis fixes) : écart-type du R² 0,001 à 0,005,
négligeable. **Graines et décalage de la grille des blocs** (origine décalée de 0, 1/5, ... 4/5 du bloc :
les plis changent) : c'est la série qui permet de lire un écart sous 0,03.

| Gradient | Variante | Bloc publié (portée) | Bloc 8 358 m |
|---|---|---|---|
| Trophique | sans climat | 0,235 ± 0,009 (22 121 m) | 0,274 ± 0,008 |
| Trophique | climat actuel (bilinéaire) | 0,231 ± 0,023 | 0,272 ± 0,014 |
| Trophique | climat corrigé | 0,245 ± 0,024 | 0,292 ± 0,011 |
| Hydrique (réponse BILJOU des placettes inchangée) | T bilinéaire | 0,280 ± 0,009 (76 736 m) | 0,368 ± 0,009 |
| Hydrique | T corrigée | **0,328 ± 0,004** | **0,381 ± 0,009** |
| Bioclimat contre l'indice floristique T (Tichý 2023) | T bilinéaire | −0,060 ± 0,040 (47 373 m) | −0,004 ± 0,010 |
| Bioclimat | T corrigée | **0,036 ± 0,020** | **0,079 ± 0,013** |
| RU apprise (géologie + SoilGrids 700 m) | — | 0,114 ± 0,010 (41 030 m) | 0,141 ± 0,005 |

Écarts appariés (même partition, cinq graines) : bioclimat corrigé − actuel +0,097 ± 0,038 (portée) et
+0,083 ± 0,013 (8 358 m) ; hydrique +0,048 ± 0,011 et +0,014 ± 0,009 ; trophique corrigé − sans climat
**+0,009 ± 0,024** (de −0,026 à +0,040) au bloc publié, +0,018 ± 0,005 à 8 358 m ; trophique actuel − sans
climat −0,005 ± 0,022 et −0,002 ± 0,007. Au bloc publié, les trois variantes du trophique ne se
distinguent pas : l'écart de la mesure du plan (0,231 contre 0,194, une partition) tenait à la partition.
**Décision de Pascal (2026-11-20) : climat retiré du trophique** (`trophique_climat: sans`, défaut) ;
`actuel` et `corrige` restent des options de `config.yml`.
La RU apprise est validée sans réencodage de la lithologie dans les plis (encodage par le trophique, comme
la carte) : 0,114 à 0,141, contre 0,099 pour la médiane de la maille, placette exclue, non spatiale (optimiste).

Cartes avant / après (emprise test) :

| Couche | q5 / q50 / q95 | Écart-type |
|---|---|---|
| T annuelle, bilinéaire (avant) | 8,8 / 9,4 / 10,5 °C | 0,57 |
| T annuelle corrigée, cellule (après) | 7,6 / 9,5 / 10,7 °C | 0,93 |
| Bioclimat avant / après (corrélation 0,84) | −1,1 / −0,07 / 1,6 ; −1,7 / 0,07 / 1,6 | 0,93 ; 1,00 |
| RU de la carte : maille (avant) / apprise (après) | 49 / 64 / 110 mm ; 70 / 94 / 115 mm | 23 ; 14 |
| Istress avant / T corrigée seule / T corrigée et RU apprise | 13 / 35 / 51 ; 12 / 34 / 50 ; 12 / 27 / 47 | 11,1 ; 11,2 ; 10,4 |

La T corrigée suit les vallées et les crêtes, sans rectangle de maille. Sur l'emprise, le décalage de T
des nœuds BILJOU de 1 km va de −1,7 à +1,2 °C ; la variation d'Istress due à la seule correction de T
est corrélée à 0,89 avec le décalage de T (+2,9 points d'Istress par °C). La RU apprise n'a plus les
rectangles de 8 km mais montre des motifs circulaires (moyennes dans 700 m apprises par la forêt
aléatoire) et des limites franches de formations géologiques ; elle est plus haute (médiane 94 contre
64 mm), d'où un Istress plus bas (médiane 27 contre 35). Calcul BILJOU avec la RU apprise : 2 927 s sur
une machine chargée, contre 583 s pour le run 035 (dix valeurs de RU par nœud au lieu d'une).

### 37.7 À vérifier

- Rééchantillonnage du WMS BD ALTI ; Vidal et al. (2010) pour l'altitude de référence de SAFRAN ; Rolland (2003).
- Gradient constant chaque jour dans BILJOU : inversions hivernales ignorées.
- Capacités euptf2 à pF 2,0 (environ 3,2 mm/cm pour un limon) ; exactitude de SoilGrids en France.
- Coefficients du tableau 20 (unités, indice de Moore lu comme le TWI).

## 40. Table lithologique : 155 formations non classées de la GRECO D (mission 040, 2026-11-20)

**Décision de Pascal (journal, 2026-11-20)** : table acceptée (option b) hors 7 cas tranchés
un par un ; trois classes nouvelles ; règles complétées ; défauts `t1b` et `j2b2` corrigés ;
10 formations laissées `non_classe`. Fichiers : `inst/extdata/lithologie_regles.csv` (27 règles,
priorités décimales), `inst/extdata/lithologie_notations.csv` (156 notations + 42 gelées, voir 40.2 : codes, classes,
origine, départements `dep`, source ; **aucune description BRGM**), `recode_lithology(overrides = )` et
`read_lithology_notations()`. Source : BD Charm-50 (BRGM) ; les pages de l'annexe 1 de Piedallu
et al. (2006) ne sont que citées. Les classes marquées « à vérifier » (notices départementales
067, 068 non lues) restent à confirmer. Codage par `NOTATION` seule pour les règles (décision de l'orchestrateur :
aucun gain mesuré à coder département + `NOTATION`) ; **les lignes `table` et `gele` ne valent que dans
les départements de leur colonne `dep`** (54, 57, 67, 68, 70, 88, 90 selon la notation ; `list_formations()`
porte le département du plus grand polygone, sans zéro de tête) : hors de ces départements,
seules les règles s'appliquent ; si le département de la formation est inconnu (pas de colonne `dep`,
ou `NA`), la ligne vaut quand même. **Limite :** le département retenu est celui du plus grand
polygone de la notation (celui dont vient la description), pas l'ensemble de ses départements : une
notation dont le plus grand polygone est hors de la colonne `dep` n'est pas touchée par la ligne, même si
elle a des polygones dans ces départements. Les 156 notations
sont propres à la GRECO D (`dep` fourni par `read_geology()`, champ `dep` de la BD Charm-50).

**Décompte final par origine (198 lignes) : table 8 ; regle 138 ; gele 42 ; laisse 10.**

### 40.1 Rejeu des motifs (store du run réel 035, 667 formations)

Chaque motif a été rejoué avec `recode_lithology()` sur les descriptions de `geol_classes_placettes`
(description du plus grand polygone, comme dans le pipeline). **Résultat : les décomptes faits à
la main de la proposition sont exacts** (règle gagnante, première qui correspond) : 10.1 : 27 ;
10.2 : 7 ; 10.3 : 13 ; 10.4 : 51 ; 10.5 : 9 ; 9.1 : 8 ; 9.2 : 4 ; 9.3 : 3 ; 11.1 : 4 ; 11.2 : 2 ;
12.1 : 2 ; 6 notations par la table (+ `j1`, `rB` fixées par la table, `h2MK3(1)` reste `roche_basique` par la règle 10.5, comme dans la proposition acceptée : la décision 1 de Pascal « h2PK3, h2MK3 → volcanite » ne vise que `h2MK3(2)` (arbitrage de l'orchestrateur, 2e aller-retour ; **question à poser à Pascal**) ; 10 laissées. **Seul écart** :
10.6 (10 notations) est scindée par la décision de Pascal sur la granodiorite du Champ-du-Feu
(Piedallu : c) : 5 `h2ã4*` vont à `plutonite_intermediaire` par une règle 10.35 `granodiorit`
(placée après 10.2, pour que « granodiorite du Hohwald » des schistes de Steige reste dans
`schiste_grauwacke`) ; 5 restent `granite`. Les motifs « seuls » (hors ordre) captent plus que
leurs décomptes (ex. 10.4 : 59 dans la liste) : c'est l'ordre qui les départage.

### 40.2 Effets hors de la liste des 156 notations : candidates soumises à Pascal

Les règles s'appliquent à toutes les formations lues (667). Rejouées, elles changeraient la
classe de **46 formations hors liste (2 557 km²)**, plus que la proposition ne l'annonçait
(règle 10.9 : 22 formations de `marne_argile` à `calcaire`, 1 599 km² ; règle 11.2 : 9 de
`calcaire` à `marne_argile`, 197 km² ; correction de la règle 1 : t1b, t2a, rD ; etc.).
**Arbitrage de l'orchestrateur (délégation totale, choix prudent et réversible) : seuls les
effets annoncés entrent**, soit t1b (décision de Pascal : grès vosgien, 522 km²), j2b2, l1-2 et
I1-2a (annoncés pour 10.9). Les 42 autres formations **gardent la classe qu'elles avaient avant la mission 040** : elles sont
« gelées » dans `lithologie_notations.csv` (`origine = gele`). Le gel n'impose pas une classe fixe :
il applique à **la description de la formation** le jeu de règles d'avant,
`inst/extdata/lithologie_regles_avant040.csv` (relecture, 2e aller-retour : une classe fixe, calculée
sur la variante du plus grand polygone, aurait fait passer `e` de `calcaire` à `marne_argile` dans la 068, sur
l'emprise de la carte). La colonne `classe` est indicative (variante dominante dans la GRECO D), `classe_regle`
donne ce que dirait la règle actuelle, `surface_km2` la surface lue. Pour accepter
un changement, supprimer la ligne de la notation. `d-h2(1)` (qui perdait sa classe,
`conglomerat` → `non_classe`) garde `conglomerat`. Surfaces : emprise lue des 7 départements.

| Notation | Classe actuelle (conservée, variante dominante) | Classe que donnerait la règle | Surface (km²) |
|---|---|---|---|
| `j2a-b` | marne_argile | calcaire | 271,77 |
| `t2a` | conglomerat | gres | 160,48 |
| `j3a` | marne_argile | calcaire | 141,51 |
| `l3b` | calcaire | marne_argile | 82,01 |
| `l2-3` | marne_argile | calcaire | 72,50 |
| `j2OM` | marne_argile | calcaire | 46,20 |
| `t3CMT` | gres | calcaire | 39,44 |
| `t4b-c` | calcaire | marne_argile | 34,95 |
| `j2c2` | marne_argile | calcaire | 29,36 |
| `l3b-c` | marne_argile | calcaire | 27,67 |
| `j5CH` | marne_argile | calcaire | 26,80 |
| `t4c` | calcaire | marne_argile | 24,21 |
| `rD` | conglomerat | gres | 23,81 |
| `t3BG` | calcaire | marne_argile | 22,85 |
| `j1b` | calcaire | marne_argile | 14,37 |
| `l3a1` | marne_argile | calcaire | 14,16 |
| `j5cC` | marne_argile | calcaire | 13,02 |
| `j6a` | marne_argile | calcaire | 11,82 |
| `l3c` | calcaire | marne_argile | 10,04 |
| `j3-4` | marne_argile | calcaire | 9,41 |
| `d7` | marne_argile | schiste_grauwacke | 8,34 |
| `j5a1` | calcaire | marne_argile | 4,85 |
| `j7` | marne_argile | calcaire | 3,64 |
| `GPx-y` | glaciaire | colluvions_eboulis | 3,56 |
| `j5c` | marne_argile | calcaire | 2,99 |
| `t3B` | calcaire | marne_argile | 2,96 |
| `j4` | marne_argile | calcaire | 2,94 |
| `e` | marne_argile | calcaire | 1,60 |
| `h2goO` | non_classe | schiste_grauwacke | 0,93 |
| `rE-F` | gres | schiste_grauwacke | 0,92 |
| `j3aC` | calcaire | marne_argile | 0,88 |
| `d5br(ö)` | non_classe | volcanite | 0,88 |
| `j6a-c` | marne_argile | calcaire | 0,85 |
| `FJw-x` | non_classe | alluvions | 0,53 |
| `dW` | non_classe | schiste_grauwacke | 0,25 |
| `o-sÕ` | non_classe | schiste_grauwacke | 0,17 |
| `g1-2` | marne_argile | calcaire | 0,11 |
| `j6aC` | marne_argile | calcaire | 0,08 |
| `g2CD` | marne_argile | calcaire | 0,06 |
| `d-h2(1)` | conglomerat | non_classe | 0,04 |
| `dS` | marne_argile | schiste_grauwacke | 0,01 |
| `döq` | non_classe | volcanite | 0,01 |

Total : 42 formations, 1113 km².

Les 4 notations non gelées (t1b, j2b2, l1-2, I1-2a) changent bien : t1b `conglomerat` → `gres`,
j2b2, l1-2 et I1-2a `marne_argile` → `calcaire`. Les 6 formations qui étaient `non_classe`
hors des disques (h2goO, d5br(ö), FJw-x, dW, o-sÕ, döq) et qu'une règle classerait restent
`non_classe`, listées ci-dessus.

**Contrôle sur les deux emprises** (store `wt035run`, lecture seule) : rejeu du jeu de règles d'avant
(sans table) contre la version actuelle. `geol_placettes` : 667 formations, 150 changent, **0 hors
changements annoncés** ; `geol_sf` (emprise de la carte) : 108 formations, 7 changent, **0 hors
annoncés** (`e` et `j1` y figurent, sur 0,05 km² chacune). Un test sur l'extrait réel vérifie le même
invariant (`test-geologie.R`).

### 40.3 Décompte `non_classe`, avant et après

| | Avant | Après |
|---|---|---|
| Formations `non_classe` (667 lues, 25 774 km²) | 171 (1 466 km²) | 26 (205 km²), dont 6 gelées (voir 40.2) |
| Formations `non_classe` dans les disques de 700 m | 155 (434,9 km²) | **10 (11,65 km²)** |
| Placettes touchant ces formations (somme par formation) | 2 002 | 333 |
| Placettes dont la classe dominante est `non_classe` | 296 | **0** |

Les 10 restantes : `hydro` (183 placettes), `Hydro` (3), `X` (25), `fm` (59), `Q` (39), `Fn` (11),
`my` (8), `Tx-y` (3), `Lz` (1), `D` (1).
Classes dominantes dans 700 m après (2 893 placettes) : grès 1 034, granite 545, conglomérat 451,
gneiss/migmatite 228, marne/argile 152, alluvions 144, volcanite 143, schiste/grauwacke 46,
glaciaire 38, plutonite intermédiaire 37, calcaire 23, colluvions/éboulis 27, loess 17,
roche basique 8.

### 40.4 R² du trophique, avant et après

Mesure hors pipeline (script du scratchpad), modèle final (climat + classe + formation + pH),
2 893 placettes, même code que `_targets.R` (035), 3 graines d'affectation des plis.
« Avant » reproduit le store (0,1938 et 0,2723, graine 1). « Après » : table et règles avec
les 42 formations gelées de 40.2.

| Blocs | Avant (graines 1, 2, 3 ; moyenne) | Après (graines 1, 2, 3 ; moyenne) | Écart |
|---|---|---|---|
| portée estimée, 22 121 m | 0,1938 ; 0,1925 ; 0,1914 ; **0,1926** | 0,2067 ; 0,2034 ; 0,2068 ; **0,2056** | +0,013 |
| 8 358 m | 0,2723 ; 0,2721 ; 0,2729 ; **0,2724** | 0,2770 ; 0,2776 ; 0,2785 ; **0,2777** | +0,005 |

Les gains restent **dans le bruit** (IC à 22 km : [0,087 ; 0,275], § 35.5) : la table ne dégrade
pas le R² et n'en apporte pas de significatif. Son bénéfice est ailleurs : plus de placette à
classe dominante `non_classe` (296 → 0), classes lisibles par un forestier. Les R² de § 35.5 ne
sont pas remplacés (le run réel n'a pas été relancé).

## 41. Carte trophique locale contre régionale : règle de remplacement (mission 037, 2026-11-20)

- **Décision éclairée :** le modèle local (ancrages GBIF, 50 m) remplace-t-il la carte trophique régionale
  (placettes IFN) ? **Propriétaire :** Pascal (a tranché, option b : seulement s'il fait mieux en validation
  croisée). **Rédigé par :** `dev`, mission 037.
- **Règle :** sur les mêmes ancrages et les mêmes plis, gain = R²(local hors pli) - R²(régional lu aux
  ancrages, brut). Le local remplace si la borne basse de l'IC du gain (bootstrap de blocs, 95 % bilatéral,
  1 000 tirages) dépasse 0,02. **Valeur provisoire, choix prudent de l'orchestrateur au lieu de 0, sans source, à
  vérifier** (20 ancrages et 10 blocs minimaux : même statut). En repère seulement, les écarts-types
  du R² sur 5 partitions mesurés en 039 (± 0,009 à 0,024, § 37 de 039) donnent un ordre de grandeur du
  bruit de répartition des plis ; ce n'est **pas une calibration** du 0,02.
- **Portée de l'IC :** il est **conditionnel aux prédictions hors pli figées** (une seule répartition en
  plis, un seul ajustement) : il rend compte du choix des blocs d'ancrages, pas de la variabilité de
  l'ajustement du local. `n_tirages` donne le nombre de tirages valides.
- **Variables égales :** le local reprend les prédicteurs, sauf les variables climatiques de maille large que
  le régional trophique n'utilise pas (`local_trophic_vars()` ; `trophique_climat: sans` : aucune, donc
  pas de `coarse_t_corr_700m`).
- **Asymétries :** (a) décalage de domaine (flore IFN sur 700 m contre listes de 50 m) : défavorise le
  régional ; un régional recalibré hors pli est rendu pour information, **jamais comme critère** ; (b) fuite
  possible en faveur du régional (placettes IFN d'apprentissage voisines des ancrages) : règle plus dure pour
  le local ; (c) ancrages non représentatifs de la carte (chemins, lisières) : part de la carte dans la zone
  d'applicabilité du local rendue.
- **Mesure :** sur l'emprise test de 018, 2 ancrages valides après `clean_occ` (§ 33.5 bis) : la comparaison est
  impossible et la carte régionale reste publiée. Aucun remplacement n'est mesuré sur données réelles à ce jour.
