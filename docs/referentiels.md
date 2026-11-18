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
