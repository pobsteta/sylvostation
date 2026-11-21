# Variables du modèle trophique local : les mêmes variables larges que le régional, plus des fines

Le modèle local (ancrages GBIF) prend **exactement les variables larges
du modèle régional** (`vars_modele$trophic` : climat selon
`trophique_climat`, lithologie, formation, pH) auxquelles s'ajoutent des
variables **fines nommées** (terrain fin non vide, sols) : seule la
finesse des données les distingue, jamais un climat que l'un verrait et
l'autre non. Le local suit donc `trophique_climat` de lui-même.

## Usage

``` r
local_trophic_vars(regional, fines)
```

## Arguments

- regional:

  Variables du modèle trophique régional (`vars_modele$trophic`).

- fines:

  Noms des variables fines ajoutées (couches de terrain fin non vides,
  sols). Une couche préfixée `coarse_` (maille de 90 m ou plus,
  [`stack_soil_layers()`](https://pobsteta.github.io/sylvostation/reference/stack_soil_layers.md))
  est **large** : elle est écartée ici et n'entre dans le local que si
  le régional l'a (`regional`).

## Value

Vecteur de noms de variables du modèle local (sans doublon), les larges
d'abord.

## Examples

``` r
local_trophic_vars(c("coarse_litho_enc", "coarse_formation_enc"), c("pente", "twi"))
#> [1] "coarse_litho_enc"     "coarse_formation_enc" "pente"               
#> [4] "twi"                 
```
