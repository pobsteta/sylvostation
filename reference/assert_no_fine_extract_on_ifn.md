# Règle bloquante : pas d'extraction fine sans précision de localisation suffisante

Les placettes de l'IFN sont localisées à 700 m près : y extraire une
variable fine (pente, TWI, LiDAR...) produirait un bruit pris pour un
signal. La fonction échoue si une variable fine est demandée et que
`points` est marqué IFN (voir
[`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md))
**ou** que sa précision de localisation n'est pas garantie : colonne
`loc_precision_m` absente, `NA`, ou supérieure à `max_precision_m`.
Ainsi le blocage survit à un `rbind` ou à une jointure qui perdrait le
marquage, et un mélange de placettes IFN et de points précis est refusé
en entier. Par prudence, une variable ni connue comme large ni préfixée
`coarse_` est traitée comme fine ; le préfixe est **sensible à la
casse** (`COARSE_climat` est traité comme fin). Une colonne
`source = "ifn"` seule suffit à bloquer. `variables = character(0)` ou
`NULL` passe (rien n'est extrait). Toute fonction d'extraction doit
l'appeler en premier.

## Usage

``` r
assert_no_fine_extract_on_ifn(points, variables, max_precision_m = 25)
```

## Arguments

- points:

  Points à échantillonner (tableau avec colonne `loc_precision_m`).

- variables:

  Vecteur de noms de variables à extraire.

- max_precision_m:

  Précision maximale admise, en mètres (25 par défaut).

## Value

`TRUE` de façon invisible si l'extraction est permise.

## Examples

``` r
p <- mark_ifn(data.frame(x = 1, y = 2))
assert_no_fine_extract_on_ifn(p, "coarse_climat")
try(assert_no_fine_extract_on_ifn(p, "pente"))
#> Error : Extraction interdite sur les placettes IFN (localisées à 700 m près). Variables fines : pente. Seules les variables à maille large (préfixe `coarse_` ou COARSE_VARIABLES) sont permises.
```
