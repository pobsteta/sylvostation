# Plan d'échantillonnage des relevés floristiques GNSS

Tire `n` cellules par hypercube latin conditionné à coût (cLHS, Minasny
et McBratney 2006 ; variante à coût de Roudier et al. 2012 ; paquet
`clhs`, docs/referentiels.md, § 30). La distribution de référence est
l'ensemble des cellules forestières renseignées
([`sampling_frame()`](https://pobsteta.github.io/sylvostation/reference/sampling_frame.md))
; seules les cellules `candidat` peuvent être tirées (`can.include`) ;
le coût est la distance au tronçon accessible (`cout_m`), **mise à
l'échelle** (`cout_m / cost_max_m`, entre 0 et 1 sur les candidates) si
`scale_cost = TRUE`, pour que `clhs` privilégie la représentativité des
couches plutôt que la proximité des routes. Les points principaux sont à
au moins `min_dist_m` les uns des autres : un point trop proche d'un
point déjà retenu est remplacé par la candidate de même classe
catégorielle la plus proche dans l'espace des couches, sinon un
avertissement est émis. Chaque point est le **centre** de sa cellule.
Pour chaque point, `n_replace` remplaçants : cellules candidates de
même(s) classe(s) catégorielle(s) (géologie), les plus proches dans
l'espace des couches continues centrées-réduites, à au moins
`min_dist_m` de tout autre point du plan. Les variables fines sont lues
sur la grille, jamais aux placettes IFN
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
est appelé sur les points du plan).

## Usage

``` r
sampling_plan(
  grid_layers,
  forest,
  access,
  n = 50,
  cost_max_m = 300,
  seed,
  n_replace = 2,
  min_dist_m = 60,
  iter = 10000,
  sd_ratio = .SD_RATIO_PROVISOIRE,
  scale_cost = TRUE
)
```

## Arguments

- grid_layers:

  `SpatRaster` des couches fines (voir
  [`sampling_frame()`](https://pobsteta.github.io/sylvostation/reference/sampling_frame.md)).

- forest:

  `SpatRaster` forestier.

- access:

  `sf` des tronçons accessibles
  ([`get_access_network()`](https://pobsteta.github.io/sylvostation/reference/get_access_network.md)).

- n:

  Nombre de points (50).

- cost_max_m:

  Distance maximale à un tronçon, en mètres (300).

- seed:

  Graine (obligatoire) : même graine, même plan. L'état du générateur
  est restauré.

- n_replace:

  Remplaçants par point (2).

- min_dist_m:

  Distance minimale entre deux points du plan, remplaçants compris (60
  m, provisoire) ; vaut aussi entre points principaux.

- iter:

  Itérations du recuit de `clhs` (10 000).

- sd_ratio:

  Seuil provisoire d'homogénéité (0,5).

- scale_cost:

  Mettre le coût à l'échelle `cout_m / cost_max_m` (`TRUE` par défaut,
  décision du 2026-11-19) ; `FALSE` passe le coût en mètres.

## Value

`sf` de points en EPSG:2154 : `id` (`P01`, `P01-R1`...), `rang` (0
point, 1 et 2 remplaçants), `id_parent`, `cell`, `x`, `y`, les couches,
`cout_m`, `acces_restreint`, `loc_precision_m` (0 : centre exact de
cellule), `source` (`"plan_grille"`). Attributs `seed`, `frame` (base de
sondage), `n_candidats`.

## Examples

``` r
if (FALSE) { # \dontrun{
p <- sampling_plan(couches, foret, troncons, n = 50, seed = 29)
} # }
```
