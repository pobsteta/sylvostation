# Ajuster le modèle d'un gradient (forêt aléatoire ou GAM)

Ajuste un gradient (par exemple un indice d'humidité ou de fertilité)
sur des prédicteurs. **Appelle d'abord
[`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)**
: des prédicteurs fins sont refusés si les points sont des placettes IFN
ou si leur précision de localisation (`loc_precision_m`) est absente ou
supérieure à 25 m.

## Usage

``` r
fit_gradient(
  data,
  response,
  predictors,
  method = c("ranger", "gam"),
  weights = NULL,
  points_source = NULL,
  num_trees = 200L,
  seed = NULL,
  ifn_precision_m = 700
)
```

## Arguments

- data:

  Objet `sf` de points en EPSG:2154, ou tableau avec colonnes `x` (est)
  et `y` (nord) **supposées en Lambert-93** : il est converti en `sf`
  EPSG:2154 puis contrôlé par
  [`assert_crs_2154()`](https://pobsteta.github.io/sylvostation/reference/assert_crs_2154.md)
  (des coordonnées hors de la France métropolitaine, par exemple x/y
  inversés ou degrés, sont refusées). Porte la réponse, les prédicteurs
  et `loc_precision_m`.

- response:

  Nom de la colonne réponse (numérique).

- predictors:

  Noms des colonnes prédictrices.

- method:

  `"ranger"` (forêt aléatoire, écart-type par quantiles) ou `"gam"`
  (mgcv, erreur-type du modèle).

- weights:

  Poids des observations (`NULL` ou vecteur de la longueur de `data`).

- points_source:

  `NULL` (on se fie à `data`) ou `"ifn"` : les points sont alors marqués
  par
  [`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md)
  avant la règle bloquante.

- num_trees:

  Nombre d'arbres de la forêt (200 par défaut).

- seed:

  Graine du générateur (`NULL` : pas de graine).

- ifn_precision_m:

  Précision de localisation posée par
  [`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md)
  quand `points_source = "ifn"` (700 m par défaut ; dans le pipeline, la
  valeur vient de `read_config()$ifn_precision_m`).

## Value

Un objet de classe `sylvo_gradient` (liste).

## Examples

``` r
set.seed(1)
d <- data.frame(x = 1007000 + 100 * (1:40), y = 6790000, loc_precision_m = 10,
                coarse_a = rnorm(40))
d$g <- d$coarse_a + rnorm(40, sd = 0.1)
if (requireNamespace("ranger", quietly = TRUE)) {
  m <- fit_gradient(d, "g", "coarse_a", num_trees = 50)
  class(m)
}
#> [1] "sylvo_gradient"
```
