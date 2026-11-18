# Plan d'échantillonnage des relevés floristiques GNSS (mission 029)

## But

Les placettes IFN sont localisées à 700 m près : elles ne peuvent pas porter les variables
fines (pente, MRVBF, hauteur au-dessus du réseau, indice hydrique). Il faut donc **40 à 60
relevés localisés au GNSS**, placés pour couvrir les gradients locaux de la forêt accessible.
Ils serviront d'ancrages locaux et de validation indépendante. Le fichier de flore saisi est
l'entrée `gnss_path` du pipeline ([load_gnss()], [gnss_field_gradients()]).

## Méthode

1. **Couches fines** de la grille de 20 m (ADR 0007), lues dans le store du run réel : `pente`,
   `altitude`, `mrvbf`, `hauteur_reseau` (cible `terrain`), `k_sv`, `is_topo` (cible
   `hydric_grid`), `geologie` (cible `geol_rast`, catégorielle). Une couche vide (MRVBF non
   calculé, par exemple) est **écartée avec un avertissement** et nommée dans la sortie,
   jamais remplacée.
2. **Forêt** : couche `foret` de `forest_mask()` (MHC > 5 m).
3. **Accès** : tronçons BD TOPO `BDTOPO_V3:troncon_de_route` (référentiels, § 29) : routes,
   routes empierrées et chemins, sans sentiers, escaliers, tronçons fictifs ni tronçons
   « Physiquement impossible ». L'accès privé, réservé aux ayants droit ou à péage est
   **signalé** (`acces_restreint`), pas exclu. Coût = distance euclidienne de la cellule au
   tronçon le plus proche (`access_cost()`).
4. **Cellules candidates** (`sampling_frame()`) : forestières, toutes couches renseignées, à au
   plus `cost_max_m` = 300 m d'un tronçon, et à **voisinage 3 × 3 homogène**
   (`homogeneous_cells()`) : les 9 cellules sont forestières, chaque couche continue y a un
   écart-type au plus égal à **0,5 fois** son écart-type sur la forêt (seuil **provisoire**),
   et la géologie y prend une seule classe. Raison : une précision GNSS de quelques mètres sur
   une cellule de 20 m peut faire lire la cellule voisine ; dans un voisinage homogène, l'erreur
   ne change pas les valeurs lues. Cela écarte aussi les lisières.
5. **Tirage** (`sampling_plan()`) : hypercube latin conditionné à coût (`clhs` 0.9.2,
   référentiels § 30 ; Minasny et McBratney 2006 ; Roudier et al. 2012). La **distribution de
   référence** est toute la forêt renseignée ; on ne **tire** que parmi les candidates
   (`can.include`) ; le coût est `cout_m`. Chaque point est le **centre** de sa cellule
   (EPSG:2154, x = est, y = nord). La graine `seed` est obligatoire : même graine, même plan.
6. **Remplaçants** : 2 par point, parmi les candidates de **même géologie**, les plus proches
   du point dans l'espace des couches continues centrées-réduites, à au moins 60 m (provisoire)
   de tout autre point du plan. Les points tirés par `clhs` ne sont pas contraints entre eux.
7. **Diagnostic** (`sampling_coverage()`) : pour chaque couche continue, test de
   Kolmogorov-Smirnov (échantillon contre forêt) et quantiles 5 à 95 % pour l'échantillon, les
   candidates et la forêt ; proportions par classe pour la géologie. Un écart entre candidates et
   forêt montre ce que l'accès et l'homogénéité retirent de la forêt.
8. **Durée** (`field_time()`, paramètres **provisoires**, à confirmer par Pascal) : 60 min de
   relevé, 20 min de tarière, marche aller-retour depuis le tronçon à 2 km/h, route entre
   points (ordre du plus proche voisin) à 30 km/h, facteur de détour 1,3, 7 h utiles par jour.
   Le trajet depuis la base n'est pas compté.

## Sorties (`write_sampling_plan()`)

Dans `<out_dir>/<ser_code>/plan_gnss/` : `plan_gnss.gpkg` (couche `plan`, EPSG:2154),
`plan_gnss.gpx` (WGS84, `name` = identifiant), `couverture.csv`, `plan_gnss.png` (carte),
`durees.csv` (écrit par le script). Préfixe `synth_` sur données synthétiques.

## Terrain

`inst/terrain/` : `protocole.md` (une page), `fiche_releve.md`, `gabarit_flore.csv` (une
ligne par couple relevé-espèce, Braun-Blanquet par strate en colonnes : pas de doublon
d'espèce, donc pas de double poids dans `gnss_field_gradients()`), `gabarit_station.csv`
(une ligne par relevé). Contrôles : `read_field_sheet()` (puis `load_gnss()`) et
`read_station_sheet()`. Précision `loc_precision_m` ≤ 25 m exigée à la lecture ; ≤ 5 m visée
au protocole.

## Application

```sh
LC_ALL=C.UTF-8 Rscript inst/scripts/plan_gnss.R 50 29 300   # n, seed, cost_max_m
```

À lancer **après** la mission 027 (MRVBF) et le run des 225 dalles. Le script télécharge une
fois les tronçons BD TOPO dans `cache_dir` (hors dépôt).

Ordre de grandeur, mesuré sur une grille **synthétique** de 750 × 750 cellules (225 km²,
358 875 cellules forestières, 281 441 candidates) : 36 s pour le tirage de 50 points et de
leurs remplaçants (2 fils `terra`).

## Limites

- Seuils provisoires : homogénéité 0,5, distance minimale 60 m, coût maximal 300 m, durées.
- Distance au tronçon à vol d'oiseau : ni la pente ni les obstacles (cours d'eau, falaises)
  ne sont comptés.
- Formes d'humus et seuils de hauteur des strates : **à vérifier** (Référentiel humus de l'AFES
  et Jabiol et al. non lus).
- La flore vernale manque à la saison retenue (fin mai à juillet).
