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
   plus `cost_max_m` = 300 m d'un tronçon, **sans tronçon retenu dans leur voisinage 3 × 3**
   (un relevé ne tombe ni sur la route ni sur son bord : les cellules traversées ou bordées par
   un tronçon sont exclues), et à **voisinage 3 × 3 homogène**
   (`homogeneous_cells()`) : les 9 cellules sont forestières, chaque couche continue y a un
   écart-type au plus égal à **0,5 fois** son écart-type sur la forêt (seuil **provisoire**),
   et la géologie y prend une seule classe. Raison : une précision GNSS de quelques mètres sur
   une cellule de 20 m peut faire lire la cellule voisine ; dans un voisinage homogène, l'erreur
   ne change pas les valeurs lues. Cela écarte aussi les lisières.
5. **Tirage** (`sampling_plan()`) : hypercube latin conditionné à coût (`clhs` 0.9.2,
   référentiels § 30 ; Minasny et McBratney 2006 ; Roudier et al. 2012). La **distribution de
   référence** est toute la forêt renseignée ; on ne **tire** que parmi les candidates
   (`can.include`) ; le coût est `cout_m`, **mis à l'échelle** (`cout_m / cost_max_m`, entre 0 et 1)
   par défaut (`scale_cost = TRUE`) : le plafond de 300 m reste dur, mais `clhs` privilégie la
   représentativité des couches plutôt que la proximité des routes. Chaque point est le **centre** de sa cellule
   (EPSG:2154, x = est, y = nord). La graine `seed` est obligatoire : même graine, même plan.
   **Espacement** : deux points principaux sont à au moins `min_dist_m` = 60 m l'un de l'autre ;
   un point trop proche d'un point précédent est remplacé par la candidate de même géologie la
   plus proche dans l'espace des couches, sinon un avertissement est émis. Au moins deux couches
   renseignées sont nécessaires.
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
au protocole. Format : séparateur virgule, point décimal, UTF-8 (un fichier à point-virgule est
refusé avec un message qui le dit). Coordonnées en Lambert-93 par défaut ; `epsg = 4326`
accepte longitude (x) et latitude (y), reprojetées en 2154 dès la lecture. Le gabarit de
station porte le recouvrement par strate (`rec_strate_*`, %, dont la strate muscinale :
bryophytes en global) et la texture ; le gabarit de flore, par espèce vasculaire, ne porte que
les strates arborescente, arbustive et herbacée. Échelle de Braun-Blanquet : **à vérifier**
(référentiels § 31).

## Application

```sh
LC_ALL=C.UTF-8 Rscript inst/scripts/plan_gnss.R 50 29 300   # n, seed, cost_max_m
```

À lancer **après** la mission 027 (MRVBF) et le run des 225 dalles. Le script télécharge une
fois les tronçons BD TOPO dans `cache_dir` (hors dépôt) ; le fichier de cache porte l'emprise
dans son nom, une autre emprise provoque un nouveau téléchargement.

**Après le tirage réel**, avant toute sortie sur le terrain :

1. lire la **part de cellules candidates** affichée par le script (le seuil d'homogénéité 0,5
   sur 7 couches, l'exclusion des abords de route et le plafond de 300 m peuvent en laisser peu ;
   le script avertit en dessous de 5 % ou de 20 candidates par point) ; si elle est faible,
   remonter le seuil d'homogénéité ou le plafond d'accès : c'est une décision de Pascal ;
2. ouvrir `plan_gnss.gpkg` sur l'**orthophoto** et vérifier **5 points** : au moins un proche
   d'une route, un en clairière apparente et un en lisière, pour confirmer qu'aucun n'est sur
   la route ni hors forêt.

Mesure sur la grille **synthétique** de 40 × 40 cellules des tests (20 points, 6 graines,
3 000 itérations), coût mis à l'échelle ou non : coût moyen tiré 140 m contre 109 m ; D de
Kolmogorov-Smirnov moyen sur les 6 couches continues 0,32 contre 0,36. L'écart à la forêt reste grand
dans les deux cas (3 à 3,5 couches continues sur 6 au-dessous de p = 0,05) : sur ce jeu, la route n'est qu'au
sud et les candidates (35 % de la forêt) ne couvrent pas tout le gradient.

Ordre de grandeur (avant l'exclusion des abords de route), mesuré sur une grille **synthétique** de 750 × 750 cellules (225 km²,
358 875 cellules forestières, 281 441 candidates) : 36 s pour le tirage de 50 points et de
leurs remplaçants (2 fils `terra`).

## Limites

- Seuils provisoires : homogénéité 0,5, distance minimale 60 m, coût maximal 300 m, durées.
- Distance au tronçon à vol d'oiseau : ni la pente ni les obstacles (cours d'eau, falaises)
  ne sont comptés.
- Formes d'humus et seuils de hauteur des strates : **à vérifier** (Référentiel humus de l'AFES
  et Jabiol et al. non lus).
- La flore vernale manque à la saison retenue (fin mai à juillet).
