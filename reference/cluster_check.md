# Contrôle de la typologie par classification non supervisée (PAM)

Variante de contrôle du brief : classification PAM sur les gradients
centrés réduits pour chaque nombre de groupes `k`, choix de `k` par la
largeur moyenne de silhouette, et comparaison avec la typologie par
seuils par l'**indice de Rand ajusté** (1 = partitions identiques, ~0 =
accord dû au hasard). Au-delà de `max_n` lignes, un sous-échantillon
aléatoire (graine `seed`) est utilisé, le PAM étant quadratique. Les
lignes incomplètes sont écartées.

## Usage

``` r
cluster_check(gradients, k = 2:20, types = NULL, max_n = 1500L, seed = 1L)
```

## Arguments

- gradients:

  Tableau de gradients numériques.

- k:

  Nombres de groupes à essayer (2 à 20 par défaut).

- types:

  Typologie par seuils (vecteur de la longueur de `gradients`, ou
  tableau avec colonne `type`) ; `NULL` : pas de comparaison.

- max_n:

  Taille maximale du sous-échantillon (1500 par défaut).

- seed:

  Graine du sous-échantillonnage.

## Value

Une liste : `silhouette` (tableau `k`, `largeur`), `k_best`, `clusters`
(groupes du meilleur `k`), `rows` (indices des lignes utilisées), `ari`
(Rand ajusté pour `k_best`, ou `NA`), `ari_par_k` (idem pour chaque
`k`).

## Examples

``` r
set.seed(1)
g <- data.frame(a = c(rnorm(40), rnorm(40, 5)), b = c(rnorm(40), rnorm(40, 5)))
cluster_check(g, k = 2:4)$k_best
#> [1] 2
```
