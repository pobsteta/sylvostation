# Flore et arbres synthétiques par type (mode démo)

Fabrique, pour des points déjà typés, une matrice de présence de 12
espèces fictives (`sp1` à `sp12`, trois par groupe de types :
probabilité 0,8 dans leur groupe, 0,1 ailleurs) et un tableau d'arbres
(essence fictive `essence_a`) dont la hauteur dépend de l'âge et d'un
effet de type. **Aucun lien avec de vraies espèces.**

## Usage

``` r
synth_demo_biotic(types, seed = 5L)
```

## Arguments

- types:

  Vecteur de types (un par point ; `NA` permis).

- seed:

  Graine.

## Value

Une liste : `flore` (matrice 0/1), `arbres` (`plot`, `species`, `age`,
`height`, `synthetic`), `plot_types` (`plot`, `type`).

## Examples

``` r
b <- synth_demo_biotic(rep(c("T1-H1-B1", "T2-H1-B1"), 30))
dim(b$flore)
#> [1] 60 12
```
