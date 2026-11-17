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

## 6. Régolithe 1/1 000 000 (BRGM) : partiellement vérifié

| Point | État | Commande | Résultat |
|---|---|---|---|
| Jeux et couches | **vérifié** (catalogue) | `curl -s "https://www.data.gouv.fr/api/1/datasets/?q=regolithe&page_size=10"` | Deux jeux BRGM : « Etat des lieux de la connaissance du régolithe **allochtone** au millionième » (id `66631d4a67b5b112fafd0f8b`, couche WMS `REGOLITHES_ALLOCH_S_1M`) et « … **autochtone** au millionième » (id `66631d4b67b5b112fafd0f8d`, couche WMS `REGOLITHES_AUTOCH_S_1M`, modifié le 2026-08-26). Service annoncé : `https://mapsref.brgm.fr/wxs/infoterre/regolithe?SERVICE=WMS&REQUEST=GetCapabilities`. |
| Service joignable, couches réelles, champs, WFS | **non vérifié** | `curl` sur `mapsref.brgm.fr` → aucune réponse (code 000, hôte hors des hôtes ouverts) ; `https://geoservices.brgm.fr/geologie?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities` (et WFS) → page « Request Rejected » du pare-feu BRGM | Ni GetCapabilities, ni champs, ni existence d'un WFS lus. À relancer avec `mapsref.brgm.fr` ouvert. |
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

## 9. Baseflor, TAXREF : non vérifié pour Baseflor, partiel pour TAXREF

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
| TAXREF | `fr-lo` (fiche MNHN) et `lov2` (fiche SIB) sur data.gouv.fr ; source primaire non lue | § 9 |
| Baseflor | **non vérifié** | § 9 |

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
12. La flore IFN est codée en TAXREF v13.0 ; la version courante de TAXREF n'a pas pu être
    lue.

## Dépendances et statut du jour (2026-11-16)

- Vérifié aujourd'hui : § 1, 2, 3, 4, 5, 7, 8, 10, 11 (sauf Baseflor), 12, 13.
- Non vérifié : § 6 (service régolithe : `mapsref.brgm.fr` et `geoservices.brgm.fr`
  inaccessibles), § 9 (Baseflor ; version courante de TAXREF : `inpn.mnhn.fr` et
  `taxref.mnhn.fr` non ouverts), `lidarHD` (hors GitHub ?), `rgbif::occ_download` (compte
  GBIF requis).
- Dépendances : l'URL BD Charm-50 dépend de la refonte d'InfoTerre (fin 2026 annoncée) ;
  le nom de l'archive IFN change à chaque campagne ; l'URL `url_npl` du LiDAR contient la
  date d'édition (2024-12-20).
