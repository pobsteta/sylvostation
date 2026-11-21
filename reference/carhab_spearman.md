# Spearman avec intervalle tenant compte de l'autocorrélation spatiale

Deux estimations, méthode écrite :

1.  **bootstrap par blocs** : la zone est découpée en blocs carrés de
    `bloc_m` mètres (Lambert-93), les blocs sont tirés avec remise, le
    Spearman est recalculé sur les cellules des blocs tirés ; intervalle
    = quantiles 2,5 % et 97,5 % ;

2.  **sous-échantillon espacé** : réseau fixe, les cellules dont le
    centre tombe sur une maille régulière de `pas_m` mètres à partir de
    `origine` (une cellule sur `pas_m / résolution` en x et en y), ce
    qui garantit un écartement d'au moins `pas_m` ; Spearman et
    intervalle de Bonett-Wright (`se = sqrt((1 + rho^2 / 2) / (n - 3))`
    sur la transformée de Fisher), valable si les cellules gardées sont
    quasi indépendantes (`pas_m` à comparer à la portée de
    l'autocorrélation, à justifier à l'appel).

## Usage

``` r
carhab_spearman(
  x,
  y,
  cx,
  cy,
  bloc_m = 1000,
  pas_m = 500,
  nboot = 300L,
  seed = 1L,
  origine = c(min(cx), min(cy))
)
```

## Arguments

- x, y:

  Valeurs (numériques, mêmes longueurs, sans `NA`).

- cx, cy:

  Coordonnées des cellules (Lambert-93 : `cx` = est, `cy` = nord, en m).

- bloc_m:

  Côté des blocs (m).

- pas_m:

  Pas du sous-échantillon espacé (m), arrondi à un multiple de la
  résolution.

- nboot:

  Nombre de tirages.

- seed:

  Graine (l'état du générateur aléatoire de l'appelant est restitué).

- origine:

  Centre `c(x, y)` d'une cellule de la grille (défaut : minimum de `cx`,
  `cy`) ; pour la grille d'un `SpatRaster`,
  `c(xmin + res / 2, ymin + res / 2)`.

## Value

Une liste : `rho`, `bloc` (`ic_bas`, `ic_haut`, `n_blocs`), `espace`
(`rho`, `ic_bas`, `ic_haut`, `n`).

## Examples

``` r
set.seed(1); xy <- expand.grid(cx = 1007010 + 20 * 0:49, cy = 6790010 + 20 * 0:49)
v <- xy$cx + rnorm(nrow(xy), sd = 300)
carhab_spearman(v, xy$cx, xy$cx, xy$cy, bloc_m = 200, pas_m = 100, nboot = 50)$rho
#> [1] 0.6932217
```
