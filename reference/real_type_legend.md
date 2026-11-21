# Légende des types du mode réel

Ajoute à la légende de
[`type_raster()`](https://pobsteta.github.io/sylvostation/reference/type_raster.md)
la colonne logique `azonal`. Aucune station azonale n'est reconnue par
le pipeline à ce jour : `azonal = FALSE` partout (déclaré dans les
limites du rapport) ; tout type de moins de 1 % est donc fusionné par
[`merge_rare()`](https://pobsteta.github.io/sylvostation/reference/merge_rare.md).

## Usage

``` r
real_type_legend(legend)
```

## Arguments

- legend:

  `data.frame` (`id`, `type`).

## Value

`legend` avec `azonal`.

## Examples

``` r
real_type_legend(data.frame(id = 1:2, type = c("T1-H1-B1", "T2-H1-B1")))
#>   id     type azonal
#> 1  1 T1-H1-B1  FALSE
#> 2  2 T2-H1-B1  FALSE
```
