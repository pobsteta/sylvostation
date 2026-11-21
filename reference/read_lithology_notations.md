# Lire la table notation -\> classe de la mission 040

Table de classes lithologiques acceptée par Pascal le 2026-11-20 (option
b) pour les formations de la GRECO D que les règles seules ne classent
pas ou classent mal. Elle est propre aux départements de la colonne
`dep` : ailleurs, seules les règles s'appliquent. Elle ne contient que
des **codes de notation et des classes** (BD Charm-50, BRGM, Licence
Ouverte ; aucune description). La colonne `origine` distingue : `table`
(classe imposée, prioritaire sur les règles : homonymies, descriptions
sans mot-clé, décisions de Pascal), `gele` (formation dont les règles
changeraient la classe sans que la proposition l'ait annoncé : on lui
applique le jeu de règles d'avant la mission 040,
`inst/extdata/lithologie_regles_avant040.csv`, **sur sa propre
description** ; la classe de la colonne `classe` n'est qu'indicative,
`classe_regle` donne ce que dirait la règle actuelle ; candidate soumise
à Pascal, supprimer la ligne pour accepter le changement), `regle`
(classe que les règles retrouvent ; ligne de contrôle) et `laisse`
(formation laissée `non_classe`, listée et jamais supprimée).

## Usage

``` r
read_lithology_notations(
  path = system.file("extdata", "lithologie_notations.csv", package = "sylvostation")
)
```

## Arguments

- path:

  Chemin du CSV. Par défaut `inst/extdata/lithologie_notations.csv`.

## Value

Un `data.frame` : `notation`, `dep` (départements, séparés par `/` et
sans zéro de tête, où la classe a été établie ; vide = partout),
`classe`, `origine`, `regle`, `confiance`, `source`, `decision_pascal`,
`classe_regle` (classe que donnerait la règle, lignes `gele`) et
`surface_km2` (numérique, `NA` hors lignes `gele`).

## Examples

``` r
table(read_lithology_notations()$origine)
#> 
#>   gele laisse  regle  table 
#>      8     10    172      8 
```
