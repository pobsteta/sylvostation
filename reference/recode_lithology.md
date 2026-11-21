# Recoder les formations en classes lithologiques

Applique des règles de mots-clés (expressions régulières sur la
description, en minuscules et sans accents) dans l'ordre de `priorite` :
la **première** règle qui correspond donne la classe. Une formation sans
règle reçoit `non_classe` : elle n'est **jamais** affectée par défaut,
et un avertissement la liste. Les formations dont la notation figure
dans `overrides` (lignes `origine = "table"` ou `"gele"`, voir
[`read_lithology_notations()`](https://pobsteta.github.io/sylvostation/reference/read_lithology_notations.md))
reçoivent d'abord la classe de la table, avec le statut `table`. Les
règles fournies sont **provisoires** (`validated = FALSE` jusqu'à
relecture).

## Usage

``` r
recode_lithology(
  formations,
  rules = read_lithology_rules(),
  overrides = read_lithology_notations(),
  rules_gele = read_lithology_rules(system.file("extdata",
    "lithologie_regles_avant040.csv", package = "sylvostation"))
)
```

## Arguments

- formations:

  `data.frame` de
  [`list_formations()`](https://pobsteta.github.io/sylvostation/reference/list_formations.md)
  (colonne `description`).

- rules:

  `data.frame` de règles, voir
  [`read_lithology_rules()`](https://pobsteta.github.io/sylvostation/reference/read_lithology_rules.md).

- overrides:

  `data.frame` notation -\> classe prioritaire sur les règles
  ([`read_lithology_notations()`](https://pobsteta.github.io/sylvostation/reference/read_lithology_notations.md)
  par défaut) ; `NULL` pour n'appliquer que les règles. Si `formations`
  porte une colonne `dep`
  ([`list_formations()`](https://pobsteta.github.io/sylvostation/reference/list_formations.md)),
  une ligne ne vaut que dans les départements de sa colonne `dep` ; sans
  `dep`, elle vaut partout.

- rules_gele:

  Règles d'avant la mission 040, appliquées aux lignes `gele`.

## Value

`formations` avec les colonnes `classe`, `statut` (`regle`, `table`,
`gele` ou `non_classe`) et `validated` (`FALSE`).

## Examples

``` r
f <- data.frame(notation = c("a", "b"), description = c("Granite de X", "Remblais"))
suppressWarnings(recode_lithology(f, read_lithology_rules()))
#>   notation  description     classe     statut validated
#> 1        a Granite de X    granite      regle     FALSE
#> 2        b     Remblais non_classe non_classe     FALSE
```
