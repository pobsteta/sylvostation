# Accord thématique entre types prédits et types de terrain

Compare des types prédits à des types observés (relevés GNSS, cartes de
stations levées) : matrice de confusion, kappa de Cohen, accord exact et
**accord à une classe près**. Les types sont des codes dont les axes
(classes) sont lus dans la chaîne : « 412 » (code à trois chiffres de la
référence, un chiffre par axe) ou « T2-H1-B1 » (nombres successifs).
L'accord à une classe près suppose des classes **ordonnées** par axe ;
il vaut `NA` si les axes ne sont pas lisibles ou ne sont pas en même
nombre partout. Les paires avec `NA` sont écartées et comptées.

## Usage

``` r
validate_maps(pred_types, field_types)
```

## Arguments

- pred_types:

  Types prédits (vecteur).

- field_types:

  Types observés (même longueur).

## Value

Une liste : `confusion` (table, lignes = observé, colonnes = prédit),
`kappa`, `accord_exact`, `accord_une_classe` (tous les axes à au plus
une classe), `par_axe` (`axe`, `accord_exact`, `accord_une_classe`,
`kappa`), `n`, `n_ecartes`.

## Examples

``` r
pred <- c("T1-H1", "T2-H1", "T2-H2", "T1-H2")
field <- c("T1-H1", "T2-H2", "T2-H2", "T1-H1")
validate_maps(pred, field)$accord_exact
#> [1] 0.5
```
