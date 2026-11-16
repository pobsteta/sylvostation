# Référentiels de données vérifiés

- **Propriétaire :** Pascal (délégué à l'orchestrateur).
- **Rédigé par :** agent `acquereur`, mission 001, le 2026-11-16.
- **Décision éclairée :** quelles URL, couches, champs et signatures les `dev` des missions
  003 à 007 peuvent écrire dans le code sans les inventer, et si l'emprise du massif test
  (`1007000 6790000 1022000 6805000`, EPSG:2154) est conservée.
- **Moyens réellement disponibles pendant cette mission :** WebFetch et WebSearch
  seulement. L'agent n'avait **ni Bash, ni curl, ni Rscript, ni git**. WebFetch n'a joint
  que `data.geopf.fr`. `www.data.gouv.fr` et `inventaire-forestier.ign.fr` ont répondu
  `getaddrinfo ENOTFOUND` (hôtes hors du réseau autorisé de la session). Ensuite, l'agent
  n'a plus essayé d'autre hôte : `api.gbif.org`, `infoterre.brgm.fr`,
  `geoservices.brgm.fr`, `github.com` et `cloud.r-project.org` n'ont pas été testés.
- **Mise en garde sur le procédé :** WebFetch transmet la page à un petit modèle qui la
  résume. Les valeurs ci-dessous sont recopiées de ses réponses. Les **décomptes**
  (`numberMatched`) sont des nombres renvoyés par le serveur, donc fiables. Les **listes**
  ont été recoupées avec ces décomptes. À relancer par `curl` dès que Bash sera disponible
  (commandes fournies).

Légende des états : **vérifié** (URL exacte consultée le 2026-11-16, résultat noté) ;
**non vérifié** (avec la raison) ; **piste** (relevée par une recherche web, source
primaire non consultée, ne pas coder).

Racine WFS utilisée : `https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0` (abrégée
`WFS` ci-dessous).

---

## 1. SER et GRECO

| Point | État | Source / commande | Résultat |
|---|---|---|---|
| Couche SER sur la Géoplateforme (WFS) | **non vérifié** : couche non trouvée | `WFS&REQUEST=GetCapabilities` (5 381 253 caractères), lu par tranches de 100 000 | Les FeatureTypes sont triés par **titre**. La tranche 4 500 000–4 600 000 passe de « Stock de carbone… » à « Table à modif atelier » : aucun titre ne commence par « Sylvo… ». Aucune tranche lue ne contient SYLVO, GRECO ni ECOREGION. Tranches lues : 0 à 2 700 000, 4 400 000 à 4 700 000, 4 900 000 à 5 000 000, 5 200 000 à 5 300 000. Les autres tranches n'ont pas été lues. |
| Couche WMS `LANDCOVER.SYLVOECOREGIONS` | **non vérifié** : le nom testé n'existe pas | `https://data.geopf.fr/wms-v/ows?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=LANDCOVER.SYLVOECOREGIONS&…` | `Could not find layer LANDCOVER.SYLVOECOREGIONS` |
| Jeu data.gouv.fr « Sylvoécorégions » (86 SER) et « Sylvoécorégions d'alluvions récentes » (5 SER) | **piste** | WebSearch ; `https://www.data.gouv.fr/api/1/datasets/sylvoecoregions/` → `ENOTFOUND` | Deux jeux distincts, selon les extraits de recherche. Version, date, URL des fichiers et champs : non lus. |
| WFS INRAE `inrae:ser_l93`, `https://geodata.inrae.fr/geoserver/inrae/ows` | **piste** | Fiche GeoDataINRAE `67044273-ec7e-4487-afe7-fa5dda5fa2bd` (vue par recherche, non consultée) | Couche annoncée en EPSG:2154, source IGN Inventaire forestier. Hôte hors liste, non testé. |
| Champ du code SER, champ du libellé | **non vérifié** | — | Aucune couche consultée. |
| Codes des SER vosgiennes (GRECO D), existence de `C30` | **non vérifié** | — | Aucun code n'est écrit ici, pour n'en inventer aucun. |
| Surface de l'emprise test par SER | **non vérifié** | — | Pas de couche SER, pas de R. |

**Conséquence pour les dev :** `get_ser()` ne peut pas encore figer sa source. Dans le
code : « à vérifier ».

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
| Taille d'une dalle | **non vérifié** pour la taille en octets (pas de requête HEAD possible sans curl) | `nombre_points`, même requête `COUNT=3` | Nombre de points : 37 644 004 (`1007-6793`, dans l'emprise) ; 57 177 173 et 50 759 494 pour deux dalles voisines hors emprise. Commande à lancer : `curl -sI <url_npl>` et lire `Content-Length`. |

## 3. MNT, MNS, MNH LiDAR HD à 50 cm (contrôle) : vérifié

| Point | État | Source | Résultat |
|---|---|---|---|
| Service et couche du MNT | **vérifié** (URL lue dans le champ `url_mnt` du tableau d'assemblage ; aucun GeoTIFF téléchargé) | requête `COUNT=3` du § 2 | WMS-R `https://data.geopf.fr/wms-r`, couche `IGNF_LIDAR-HD_MNT_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93`, `FORMAT=image/geotiff`, `CRS=EPSG:2154`, 2000 × 2000 px pour 1 km (50 cm). Nom de fichier, par exemple `LHD_FXX_1007_6793_MNT_O_0M50_LAMB93_IGN69.tif`. La BBOX de l'URL est décalée d'un quart de pixel (`1006999.75,6792000.25,…`). |
| MNS, MNH | **vérifié** (même source) | idem | `IGNF_LIDAR-HD_MNS_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93`, `IGNF_LIDAR-HD_MNH_ELEVATION.ELEVATIONGRIDCOVERAGE.LAMB93` (champs `url_mns`, `url_mnh`). |

## 4. BD Forêt V2 : vérifié pour la couche, non vérifié pour la part de forêt

| Point | État | Commande | Résultat |
|---|---|---|---|
| Couche et champs | **vérifié** | `WFS&REQUEST=DescribeFeatureType&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale` | `id`, `code_tfv`, `tfv`, `tfv_g11`, `essence` (string), `geom` (MultiSurface). Type de formation végétale : `code_tfv` (code) et `tfv` (libellé). `tfv_g11` est un regroupement en 11 postes. |
| Contenu dans l'emprise | **vérifié** | `WFS&REQUEST=GetFeature&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale&SRSNAME=EPSG:2154&BBOX=1007000,6790000,1022000,6805000,EPSG:2154&OUTPUTFORMAT=application/json&COUNT=5` | `numberMatched` = 1073 polygones (BBOX, qui peut déborder comme au § 2). Valeurs vues : `FF0` « Forêt fermée sans couvert arboré » ; `FF2-00-00` « Forêt fermée à mélange de conifères » ; `FF1-00` « Forêt fermée de feuillus purs en îlots » ; `LA4` « Lande » (essence `NC`). **La couche contient des landes** : le masque forestier doit filtrer sur `code_tfv`. La liste complète des codes n'a pas été lue. |
| Part de forêt dans l'emprise | **non vérifié** | — | Calcul de surface impossible sans R ou sf. |

## 5. BD Charm-50 (BRGM) : non vérifié

Hôte `infoterre.brgm.fr` non testé (voir l'en-tête). URL par département (67, 68, 88),
couches, champs (code, notation, description) : rien n'a été vérifié. La présence de grès
et de roches cristallines dans l'emprise n'est **pas mesurée**.

## 6. Régolithe 1/1 000 000 (BRGM) : non vérifié

`geoservices.brgm.fr` non testé. Aucun titre « Géologie… » n'a été cherché dans les
GetCapabilities de la Géoplateforme (tranches de G non lues).

## 7. Données brutes IFN : non vérifié

`inventaire-forestier.ign.fr` → `getaddrinfo ENOTFOUND` (2026-11-16). `www.data.gouv.fr` →
`ENOTFOUND` par WebFetch. URL, format, colonnes de `PLACETTE`, `ECOLOGIE`, `FLORE`,
`ARBRE`, système de coordonnées, codes d'espèces de `FLORE` et correspondance TAXREF
(CD_NOM/CD_REF) : rien n'a été vérifié. Version de TAXREF : non vérifiée.

Accès à `www.data.gouv.fr` par curl (point 4 de l'orchestrateur) : **non vérifié**, pas de
Bash dans cette session. Par WebFetch : `ENOTFOUND`.

## 8. GBIF : non vérifié

`api.gbif.org` non testé. La clé Tracheophyta (`7707728` dans le brief) reste
« à confirmer ». Rien n'a été compté : ni les occurrences à incertitude ≤ 25 m, ni celles
sans incertitude, ni les données généralisées (`dataGeneralizations`,
`informationWithheld`). Licences des jeux de données : non lues.

Commandes prêtes à lancer (non exécutées) :
`curl -s 'https://api.gbif.org/v1/species/match?name=Tracheophyta'` ;
`curl -s 'https://api.gbif.org/v1/occurrence/search?limit=0&geometry=<WKT WGS84>&taxonKey=<clé>&hasCoordinate=true&hasGeospatialIssue=false&coordinateUncertaintyInMeters=0,25&year=2000,2026'`.

## 9. Baseflor : non vérifié

Pas de source consultée.

## 10. Signatures des paquets R : non vérifié

Pas de Rscript dans cette session. `lasR`, `lidR`, `rgbif`, `happign`, `lidarHD` : aucune
signature n'est garantie. Les esquisses du brief § 5 restent non exécutées.

## 11. Licences : non vérifié

Aucune page de licence consultée (IGN, BRGM, IFN, Baseflor, GBIF). Rien à coder tant que
ce n'est pas lu.

---

## Écarts relevés entre sources

1. Le brief cite la couche `IGNF_LIDAR-HD_METADONNEE:metadata` : elle existe, l'écart est
   nul. Le brief parle d'un « nom de dalle » : le champ réel est `coordonnees_nw`.
2. Le brief situe les vols des Vosges à « l'hiver 2021-2022 ». La métadonnée donne
   janvier **et avril** 2022 : 116 des 225 dalles ont été volées le 2022-04-21 (fin de
   l'hiver ou début du débourrement selon l'altitude). C'est un écart de saison à noter
   pour la hauteur des feuillus.
3. SER : selon les extraits de recherche, le découpage compte 86 SER plus 5 SER
   d'alluvions (data.gouv.fr, INRAE), contre 91 SER dans une autre source (arXiv 2512.11524).
   L'écart n'est pas résolu : source primaire non lue.
4. Le BBOX du WFS de la Géoplateforme compte 289 dalles pour une emprise qui en contient
   225 : il faut filtrer à nouveau.
