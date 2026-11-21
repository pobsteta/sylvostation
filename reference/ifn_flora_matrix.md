# Matrice de présence de la flore IFN (placettes x espèces)

Matrice de présence de la flore IFN (placettes x espèces)

## Usage

``` r
ifn_flora_matrix(flore, ids)
```

## Arguments

- flore:

  `ifn$flore` (colonnes `id_placette`, `CD_REF`).

- ids:

  Placettes à garder, dans cet ordre.

## Value

Une matrice 0/1 (lignes = `ids`, colonnes = `CD_REF`).

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
dim(ifn_flora_matrix(ifn$flore, unique(ifn$flore$id_placette)[1:5]))
#> [1]  5 57
```
