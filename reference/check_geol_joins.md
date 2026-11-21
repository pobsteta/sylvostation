# Contrôler les raccords entre feuilles et départements

Repère les polygones voisins (à moins de `tol` m l'un de l'autre) qui
appartiennent à deux groupes différents (champ `dep` ou `CARTE`, s'ils
existent) : à chaque limite, on liste la paire de notations et la
longueur de contact. Une notation différente de part et d'autre est un
**changement d'unité à la limite**, à examiner (raccord de feuille ou de
département mal harmonisé) ; une même notation avec des `CODE`
différents est signalée aussi (`code_differe`). Si aucun champ de groupe
n'existe, renvoie un tableau vide avec un message.

## Usage

``` r
check_geol_joins(geol, fields = c("dep", "CARTE"), tol = 10, min_length = 50)
```

## Arguments

- geol:

  Objet `sf` polygonal en Lambert-93 avec `NOTATION` (et `CODE`).

- fields:

  Champs de groupe à examiner.

- tol:

  Distance de voisinage, en mètres (les géométries de l'extrait sont
  simplifiées à 5 m).

- min_length:

  Longueur de contact minimale retenue, en mètres.

## Value

Un `data.frame` : `champ`, `groupe_a`, `groupe_b`, `notation_a`,
`notation_b`, `longueur_m`, `unite_change` (notations différentes),
`code_differe`. Un avertissement est émis s'il y a des changements
d'unité.

## Examples

``` r
g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
                             package = "sylvostation"), quiet = TRUE)
nrow(suppressWarnings(check_geol_joins(g)))
#> [1] 44
```
