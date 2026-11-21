# Fertilité observée par essence et par type

Hauteur dominante à un âge de référence (indice de fertilité), par
essence et par type, sur les placettes dont les hauteurs et âges sont
**mesurés** (IFN ; la hauteur LiDAR ne peut pas être rattachée à ces
placettes). Méthode simple et **provisoire**, à valider avec un
sylviculteur :

1.  par placette et essence, hauteur dominante = moyenne des `n_dom`
    arbres les plus hauts, âge = moyenne de leurs âges ;

2.  par essence, courbe guide `h = a + b ln(âge)` ajustée sur toutes les
    placettes (au moins `n_min_guide` placettes et un âge variable,
    sinon `NA`) ;

3.  indice de fertilité de la placette = `h + b (ln(age_ref) - ln(âge))`
    (courbe guide translatée par l'observation), puis résumé par type.

Les noms de colonnes de l'IFN n'étant pas vérifiés, ils sont passés en
argument (à vérifier). L'âge de référence par défaut (50 ans) est
provisoire.

## Usage

``` r
fertility_by_type(
  arbres,
  types,
  cols = c(plot = "plot", species = "species", height = "height", age = "age"),
  age_ref = 50,
  n_dom = 3L,
  n_min_guide = 10L
)
```

## Arguments

- arbres:

  Tableau d'arbres : placette, essence, hauteur (m), âge (ans).

- types:

  Type de chaque placette : tableau avec les colonnes `plot` (même nom
  que dans `arbres`) et `type`, ou vecteur de types nommé par
  identifiant de placette.

- cols:

  Noms des colonnes de `arbres`, vecteur nommé `plot`, `species`,
  `height`, `age`.

- age_ref:

  Âge de référence en années (hauteur dominante attendue à cet âge :
  c'est l'âge auquel l'indice de fertilité est exprimé). Un nombre,
  appliqué à toutes les essences, ou un vecteur **nommé par essence**
  (une essence absente du vecteur reçoit `NA` et un avertissement).
  Défaut provisoire : 50 ans, à fixer avec un sylviculteur ; il est
  repris dans la colonne `age_ref` du résultat et de l'attribut `plots`,
  pour que chaque indice reste lié à son âge de référence.

- n_dom:

  Nombre d'arbres dominants par placette et essence (3, provisoire).

- n_min_guide:

  Nombre minimal de placettes pour ajuster la courbe guide (10).

## Value

Un `data.frame` par essence x type : `species`, `type`, `n_plots`,
`fertilite_moy`, `fertilite_med`, `fertilite_sd`, `age_ref`. Attributs :
`plots` (indice par placette), `guide` (coefficients par essence),
`provisoire = TRUE`.

## Examples

``` r
set.seed(1)
ar <- data.frame(plot = rep(1:30, each = 4), species = "chene",
                 age = rep(runif(30, 30, 120), each = 4), height = NA)
ar$height <- 8 * log(ar$age) - 10 + rep(rnorm(30, sd = 2), each = 4) + rnorm(120, sd = 0.5)
ty <- data.frame(plot = 1:30, type = rep(c("a", "b"), 15))
fertility_by_type(ar, ty)
#>   species type n_plots fertilite_moy fertilite_med fertilite_sd age_ref
#> 1   chene    a      15      21.45071      21.47511     1.687882      50
#> 2   chene    b      15      21.82789      21.55929     1.564916      50
```
