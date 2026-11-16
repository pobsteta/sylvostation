# Mission 001 — référentiels de données vérifiés

## Mission

**En une phrase (quoi, et pourquoi) :** vérifier sur les sources réelles les URL, noms de
couches, champs et signatures de fonctions dont le code aura besoin, et les consigner
dans `docs/referentiels.md`, pour que les `dev` n'inventent rien.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : liste ci-dessous, R installé, réseau ouvert vers les hôtes nommés | |
| Les moyens ? | oui : `curl`, `Rscript` (sf, terra, happign si installé), WebFetch | |

**Temps de la main :** appuyer.

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16)._

## L'Homme

- **Agent :** `acquereur` · **Modèle :** opus (justesse des données)
- **Ce qui ne lui est pas demandé :** écrire du code du package ; télécharger des volumes
  supérieurs à 50 Mo.

## Harnais

- **Peut :** interroger les services (GetCapabilities, DescribeFeatureType, petites
  requêtes GetFeature avec `count` ≤ 10), télécharger de petits fichiers de métadonnées
  dans le bloc-notes, lire la doc des paquets R installés (`?fonction`, `args()`).
  Hôtes ouverts : data.geopf.fr, api.gbif.org, infoterre.brgm.fr, geoservices.brgm.fr,
  inventaire-forestier.ign.fr, www.data.gouv.fr, static.data.gouv.fr, cloud.r-project.org,
  r-lidar.r-universe.dev, github.com.
- **Ne doit pas :** inventer une URL ou une colonne ; écrire hors de `docs/referentiels.md`
  (et éventuellement `inst/extdata/` pour un extrait réel ≤ 2 Mo avec sa source).
- **Sources autorisées :** `docs/brief-technique.md` § 3, 5, 9 ; services publics ci-dessus.

## À vérifier (une ligne par point : état vérifié / non vérifié, source, date)

1. Couche WFS des **SER** et des **GRECO** sur data.geopf.fr : nom exact, champs (code
   SER, libellé), et **les codes des SER vosgiennes** (GRECO D).
2. **Tableau d'assemblage LiDAR HD** : couche WFS (brief : `IGNF_LIDAR-HD_METADONNEE:metadata`,
   à confirmer, ou autre nom réel), champs (nom de dalle, URL de téléchargement LAZ, date
   d'acquisition) ; dalles disponibles dans l'emprise test
   `xmin 1007000, ymin 6790000, xmax 1022000, ymax 6805000` (EPSG:2154) : nombre, dates,
   taille d'une dalle.
3. **MNT LiDAR HD IGN** à 50 cm : service ou couche permettant d'en récupérer une dalle (contrôle).
4. **BD Forêt V2** : couche WFS, champ du type de formation végétale.
5. **BD Charm-50** : URL de téléchargement par département (68, 88, 67), noms des couches
   et des champs (code, notation, description) — consulter infoterre.brgm.fr.
6. **Régolithe 1/1 000 000** (BRGM) : service et couche.
7. **Données brutes IFN** : URL réelle (inventaire-forestier.ign.fr ou data.gouv.fr),
   format, **colonnes** de `PLACETTE`, `ECOLOGIE`, `FLORE`, `ARBRE` (télécharger
   l'archive si ≤ 50 Mo, sinon lire la doc des métadonnées), système de coordonnées.
8. **GBIF** : clé taxonomique de Tracheophyta (`/v1/species/match?name=Tracheophyta`),
   paramètres de `occ_download` (rgbif, si installé), nombre d'occurrences dans l'emprise
   test avec incertitude ≤ 25 m depuis 2000 (requête de comptage `limit=0`, sans compte).
9. **Baseflor** (Julve) : où l'obtenir, licence, colonnes des valeurs indicatrices.
10. Signatures des paquets installés : `lasR` (reader, dtm, chm, exec ou équivalents réels),
    `lidR` (`readLAScatalog`, `plot_metrics`), `rgbif`, `happign` (`get_wfs`), `lidarHD`
    (dépôt GitHub, fonctions) — ne rien affirmer pour un paquet non installé : « non vérifié ».
11. Licences : Licence Ouverte Etalab pour IGN, BRGM, IFN ? GBIF : licence par jeu de données.

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** emprise du massif test ci-dessus (225 km², Ribeauvillé –
  Brézouard – Taennchel, choisie par délégation). **Mesurée par :** cette mission (dalles
  LiDAR disponibles, présence de grès et de roches cristallines selon la BD Charm-50 si
  vérifiable). Si l'emprise est mauvaise (pas de LiDAR HD, un seul substrat), proposer
  une autre emprise de 100 à 300 km² dans les Vosges, avec ses raisons.

## Dépend de / rouge attendu jusqu'à

Aucune.

## Tests

Chaque ligne de `docs/referentiels.md` porte la commande ou l'URL réellement exécutée,
la date et le résultat ; liste de contrôle passée.

## Terrain

Pascal vérifiera une dalle LiDAR et la carte géologique de l'emprise test.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les `dev` des missions 003 à 007 n'ont aucune URL ni colonne à deviner.
