# Table essence ESPAR -\> CD_REF de l'IFN

Lit `espar-cdref13.csv` (archive DataIFN) ou son extrait
`ifn_espar_cdref.csv` : code d'essence `espar`, libellé, `cd_ref`
(TAXREF v13.0, comme la flore) et nom du taxon. Même lecture que
[`read_tree_cd_ref()`](https://pobsteta.github.io/sylvostation/reference/read_tree_cd_ref.md),
qui n'en rend que les `CD_REF`.

## Usage

``` r
read_espar_cdref(dir)
```

## Arguments

- dir:

  Dossier contenant `espar-cdref13.csv` ou `ifn_espar_cdref.csv`.

## Value

Un `data.frame` : `espar`, `lib_espar`, `cd_ref` (numérique),
`lib_cdref`.

## Examples

``` r
head(read_espar_cdref(system.file("extdata", package = "sylvostation")), 3)
#>   espar        lib_espar cd_ref            lib_cdref
#> 1    61    Sapin pectiné  79319           Abies alba
#> 2  29MI           Mimosa 128357 Vachellia farnesiana
#> 3   21C Érable champêtre  79734       Acer campestre
```
