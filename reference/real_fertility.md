# Fertilité par type, ou table vide si aucun arbre n'a d'âge

Appelle
[`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)
; si aucun arbre n'a à la fois une hauteur et un âge (cas de l'extrait
IFN du dépôt), renvoie une table vide avec l'attribut `motif`, au lieu
d'arrêter le pipeline.

## Usage

``` r
real_fertility(trees, types)
```

## Arguments

- trees:

  Résultat de
  [`ifn_trees()`](https://pobsteta.github.io/sylvostation/reference/ifn_trees.md).

- types:

  `data.frame` (`plot`, `type`).

## Value

Le résultat de
[`fertility_by_type()`](https://pobsteta.github.io/sylvostation/reference/fertility_by_type.md)
ou un `data.frame` vide.

## Examples

``` r
real_fertility(data.frame(plot = "a", species = "x", height = 20, age = NA),
               data.frame(plot = "a", type = "T1"))
#> [1] species       type          n_plots       fertilite_moy
#> <0 rows> (or 0-length row.names)
```
