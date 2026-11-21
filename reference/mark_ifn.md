# Marquer des points comme placettes IFN

Pose `attr(x, "source") <- "ifn"` et, pour un tableau, deux colonnes :
`source = "ifn"` et `loc_precision_m` (700 m par défaut ; dans le
pipeline, la valeur vient de `read_config()$ifn_precision_m`). Les
colonnes survivent aux sous-ensembles, à `rbind` et aux jointures,
l'attribut non toujours.

## Usage

``` r
mark_ifn(x, precision_m = 700)
```

## Arguments

- x:

  Un objet (`data.frame`, `sf`, ...).

- precision_m:

  Précision de localisation, en mètres (nombre positif).

## Value

`x`, marqué.

## Examples

``` r
p <- mark_ifn(data.frame(x = 1, y = 2))
p$loc_precision_m
#> [1] 700
```
