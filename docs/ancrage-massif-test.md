# Points d'ancrage GBIF sur le massif test : mesure du 2026-11-16

- **Rédigé par :** `dev`, mission 007.
- **Question :** GBIF suffit-il à ancrer le modèle local (trophique, hydrique) sur l'emprise
  test (`1007000 6790000 1022000 6805000`, EPSG:2154, 225 km²) ? Critère du brief technique,
  § 4 étape 4 : nombre de mailles exploitables (au moins 5 espèces indicatrices).
- **Méthode.** API publique `https://api.gbif.org/v1/occurrence/search` (sans compte), plantes
  vasculaires (`taxonKey=7707728`), `hasCoordinate=true`, `hasGeospatialIssue=false`,
  depuis 2000, emprise en WGS84 (WKT du § 8 de `docs/referentiels.md`). Le téléchargement
  `occ_download()` (DOI) n'a **pas** été fait (pas de compte). Les occurrences sont lues
  dans `/tmp/claude-0/gbif/` (hors dépôt, **aucune occurrence réelle n'est versionnée** :
  jeux CC BY-NC présents), puis passées dans `clean_occ()` et `grid_bioindication()`.
  Filtre forêt : BD Forêt V2 par WFS `data.geopf.fr` (couche
  `LANDCOVER.FORESTINVENTORY.V2:formation_vegetale`, 1 073 polygones), codes `FF*` et `FO*`
  hors `FF0` (décision provisoire pour `FP` et `FF0`, voir `clean_occ()`).
- **Limites de la mesure.** (1) Pas de Baseflor : les valeurs indicatrices sont **synthétiques**
  (tirage aléatoire sur les 1 161 espèces vues, graine 1) ; **toute espèce compte comme
  indicatrice**, donc les comptes de mailles ci-dessous sont une **borne haute** (Baseflor ne
  couvre pas toutes les espèces et les noms GBIF et TAXREF diffèrent : à vérifier). Les valeurs
  bioindiquées elles-mêmes ne sont pas interprétables. (2) Pas de filtre canopée (MHC > 5 m) :
  le MHC de l'emprise test n'est pas dans cette branche. (3) Un même point de relevé peut
  apparaître sous plusieurs dates ; les espèces d'une maille sont dédoublonnées, pas les
  relevés.

## Entonnoir (occurrences à chaque étape)

| Étape | Occurrences | Remarque |
|---|---|---|
| Total plantes vasculaires, depuis 2000, sans anomalie géographique | **18 538** | égal au comptage du § 8 de `referentiels.md` |
| Espèce renseignée | 18 349 | 189 sans espèce (rang supérieur) |
| Hors jeu IFN (`e5f16d86-…`) | 16 262 | 2 087 relevés IFN écartés |
| Précision ≤ 25 m (`loc_precision_m`) | **2 608** | voir ci-dessous |
| Dont en forêt BD Forêt (`FF*`, `FO*`, hors `FF0`) | **983** (37,7 %) | forêt FF/FO hors FF0 : 159,2 km² = 70,8 % de l'emprise |

Répartition de l'incertitude (avant exclusion de l'IFN) : ≤ 25 m : 4 440 (dont **1 800 IFN
déclarés à 1 m**, soit 40,5 %, confirmé) ; > 25 m : 11 166 ; absente : 2 932 (350 IFN et
2 582 autres). Occurrences portant `dataGeneralizations` ou `informationWithheld` :
**7 754**, toutes à incertitude > 25 m ou absente (aucune parmi les ≤ 25 m) : le filtre sur
les données généralisées ne retire rien de plus ici, mais protège le mode `keep_unknown`.
Avec `keep_unknown = TRUE` (précision inconnue gardée, `loc_precision_m = NA`, donc refusée
pour toute extraction fine) : 12 868 occurrences, 4 374 en forêt, inutilisables pour les
prédicteurs fins.

## Mailles exploitables (valeurs indicatrices synthétiques, borne haute)

Mailles calées sur l'origine (0, 0) de Lambert-93. « Occupées » : au moins une occurrence.

| Jeu retenu | Maille | Occupées | ≥ 3 espèces | **≥ 5 espèces** |
|---|---|---|---|---|
| Précision ≤ 25 m, hors IFN, toute surface | 50 m | 1 690 | 126 | **31** |
| | 100 m | 1 375 | 183 | **55** |
| **Idem, en forêt** | **50 m** | 660 | 43 | **11** |
| | **100 m** | 556 | 63 | **18** |
| En forêt, hors jeux CC BY-NC | 50 m | 465 | 19 | 4 |
| | 100 m | 403 | 28 | 10 |
| En forêt, sans Pl@ntNet ni iNaturalist | 50 m | 222 | 11 | 4 |
| | 100 m | 197 | 17 | 7 |
| En forêt, sans Pl@ntNet, iNaturalist ni CC BY-NC | 50 m | 48 | 2 | 1 |
| | 100 m | 44 | 3 | 1 |

Lecture :

- **11 mailles de 50 m** (18 de 100 m) en forêt comptent au moins 5 espèces, soit 0,03 km²
  (0,18 km²) sur 159 km² de forêt. Poids (nombre d'espèces) : 5 (4 mailles), 6 (2), 7 (2), 8 (2),
  **48 (1)**. La maille à 48 espèces est un seul relevé (CardObs, 2015) : **10 mailles
  indépendantes** de 5 à 8 espèces.
- Le jeu IFN, s'il était gardé sur la foi de son incertitude déclarée (1 m), ferait passer le
  compte à **74** mailles de 50 m en forêt (80 à 100 m) : le filtre IFN retire 63 mailles
  fictives sur 74, soit 85 %. Une mauvaise localisation (700 m) y fabriquerait des ancrages.
- Sans les jeux CC BY-NC (dont iNaturalist et Observation.org), il reste 4 mailles de 50 m. Sans
  les observations citoyennes, une seule.
- Le seuil d'espèces domine : à 3 espèces, 43 mailles de 50 m.

## Jeux de données principaux et licences

Occurrences retenues (précision ≤ 25 m, hors IFN) puis en forêt ; licence lue dans
l'enregistrement GBIF, concordante avec le § 8 de `referentiels.md` :

| datasetKey | Jeu | ≤ 25 m | En forêt | Licence |
|---|---|---|---|---|
| 14d5676a-2c54-4f94-9023-1e8dcd822aa0 | Pl@ntNet, identifications automatiques | 1 258 | 402 | CC BY 4.0 |
| 8a863029-f435-446a-821e-275f4f641165 | Observation.org | 483 | 231 | **CC BY-NC 4.0** |
| 50c9509d-22c7-4a22-a47d-8c48425ef4a7 | iNaturalist Research-grade | 329 | 122 | **CC BY-NC 4.0** |
| 7a3679ef-5582-4aaa-81f0-8c2545cafc81 | Pl@ntNet observations | 313 | 125 | CC BY 4.0 |
| 7d2dc1b9-aee3-4097-953b-f755a41132f4 | CardObs : observations naturalistes | 124 | 48 | CC BY 4.0 |
| 6ac3f774-d9fb-4796-b3e9-92bf6c81c084 | NABU\|naturgucker | 80 | 49 | CC BY 4.0 |
| 7247dc2e-b862-4555-b533-7701d183271b | INPN Espèces | 12 | 6 | CC BY 4.0 |
| autres (CardObs) | 3 jeux | 9 | 0 | CC BY 4.0 |

Les gros jeux de conservatoires de la région (flore d'Alsace, SBA, 7 416 occurrences ; CBAL,
2 085) n'ont **aucune** occurrence à ≤ 25 m : leur incertitude est plus grande ou absente. Aucun jeu ONF
n'y figure non plus. Les ancrages précis viennent donc surtout de la science participative.
Licences : 340 des 983 occurrences en forêt sont CC BY-NC 4.0 : tout extrait versionné ou
produit redistribué doit les écarter ou respecter la clause non commerciale.

## Réponse à la question du brief

Sur le massif test, **GBIF ne suffit pas, de loin** : 11 mailles de 50 m (dont 10
indépendantes) en forêt, au plus 18 à 100 m, sur une borne haute (Baseflor réduira ce compte)
et dont près des deux tiers dépendent de jeux CC BY-NC ou citoyens. Le brief prévoit 30 à 50
relevés GNSS pour validation : le même ordre de grandeur est à produire sur le terrain pour
calibrer. Le seuil de « suffisant » n'est pas fixé par le brief : **à trancher par Pascal**.
Leviers non essayés : relâcher la précision pour les gros jeux de conservatoires (non mesuré,
seuil à choisir), source SINP, seuil de 3 espèces. Dégrader la précision demandée ferait payer la justesse.

## Reproduire

Le code de mesure n'est pas versionné (script jetable). Étapes : lecture de l'API par année,
pages de 100 (les pages de 300 au-delà du rang 10 000 et `occ_search(limit = 100000)` n'ont
pas abouti dans la session, la sortie réseau étant interrompue ou très lente : cause non
diagnostiquée), puis `clean_occ(occ, forest = <BD Forêt>)` et
`grid_bioindication(p, indicateurs, cell = 50, min_species = 5)`. Pour des occurrences à jour et
un DOI, utiliser `get_gbif(emprise, user, pwd, email)` avec un compte GBIF.
