# Trophique observé sans les arbres

Recalcule l'indice trophique des placettes (moyenne de la moyenne de
`ph` et de la moyenne d'`azote` des espèces de la flore, comme
[`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md))
**sans les essences de l'IFN** : les `CD_REF` de
[`read_tree_cd_ref()`](https://pobsteta.github.io/sylvostation/reference/read_tree_cd_ref.md)
(table `espar-cdref13.csv`, TAXREF v13, même référentiel que la flore)
sont retirés par jointure sur `CD_REF`. Sert de référence au contrôle
par essence : l'indice complet contient l'essence elle-même. La table
des essences liste les arbres et quelques arbustes de l'inventaire.

## Usage

``` r
trophic_without_trees(flore, indicateurs, tree_cd_ref, ids, min_taxa = 3)
```

## Arguments

- flore:

  `data.frame` de la flore IFN : `id_placette`, `CD_REF`.

- indicateurs:

  Valeurs indicatrices (`cd_ref`, `ph`, `azote`).

- tree_cd_ref:

  Vecteur de `CD_REF` des essences
  ([`read_tree_cd_ref()`](https://pobsteta.github.io/sylvostation/reference/read_tree_cd_ref.md)).

- ids:

  Identifiants de placettes à rendre, dans cet ordre.

- min_taxa:

  Nombre minimal d'espèces indicatrices restantes (3).

## Value

Un vecteur numérique aligné sur `ids` (`NA` sous `min_taxa`), attribut
`n_taxons_arbres` (taxons de `indicateurs` retirés, comptés et jamais
retirés en silence).

## Examples

``` r
fl <- data.frame(id_placette = "p", CD_REF = 1:4)
ind <- data.frame(cd_ref = 1:4, ph = c(5.7, 3, 4, 5), azote = c(5, 4, 6, 5))
trophic_without_trees(fl, ind, tree_cd_ref = 1, ids = "p", min_taxa = 2)
#> [1] 4.5
#> attr(,"n_taxons_arbres")
#> [1] 1
```
