# Seuils provisoires de discrétisation des gradients

Calcule, pour chaque gradient, des seuils par **quantiles** (classes de
même effectif). Ces seuils sont **provisoires** : ils ne sont pas
écologiquement lisibles et doivent être remplacés par des seuils fixés
avec Pascal avant le gel de la phase 1 (SER vosgiennes). L'objet renvoyé
porte l'attribut `provisoire = TRUE`.

## Usage

``` r
default_thresholds(
  gradients,
  n_classes = c(trophic = 4L, hydric = 3L, bioclim = 2L)
)
```

## Arguments

- gradients:

  Tableau de gradients (colonnes numériques).

- n_classes:

  Vecteur nommé : nombre de classes par gradient. Les noms sont ceux des
  colonnes de `gradients`. Défaut provisoire : 4 trophiques, 3
  hydriques, 2 bioclimats (le nombre de bioclimats dépend de l'amplitude
  altitudinale de la SER, 1 à 5 selon le brief).

## Value

Une liste nommée de vecteurs de seuils croissants (une classe de plus
que de seuils), avec l'attribut `provisoire = TRUE`.

## Examples

``` r
set.seed(1)
g <- data.frame(trophic = rnorm(100), hydric = rnorm(100), bioclim = rnorm(100))
default_thresholds(g)
#> $trophic
#> [1] -0.4942425  0.1139092  0.6915454
#> 
#> $hydric
#> [1] -0.4635304  0.2199248
#> 
#> $bioclim
#> [1] -0.001606084
#> 
#> attr(,"provisoire")
#> [1] TRUE
```
