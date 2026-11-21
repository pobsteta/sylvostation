# Dictionnaire des codes ESPAR de l'IFN

Lit l'extrait `inst/extdata/ifn_espar_codes.csv` (lignes `ESPAR1` de
`metadonnees.csv`, campagnes 2009 et suivantes, Licence Ouverte 2.0) :
code ESPAR, nom français, nom latin. Le code `332G`, présent dans la
table ARBRE, n'y figure pas (traité comme « autre »).

## Usage

``` r
read_espar_codes(
  path = system.file("extdata", "ifn_espar_codes.csv", package = "sylvostation")
)
```

## Arguments

- path:

  Chemin du fichier (défaut : celui du paquet).

## Value

Un `data.frame` : `code`, `nom`, `latin`.

## Examples

``` r
head(read_espar_codes(), 3)
#>   code             nom                          latin
#> 1   02 Chêne pédonculé       Quercus robur var. robur
#> 2   03   Chêne sessile Quercus petraea subsp. petraea
#> 3   04     Chêne rouge                  Quercus rubra
```
