# Codes `CD_REF` des essences arborées de l'IFN

Lit la table `espar-cdref13.csv` de l'archive DataIFN (colonnes `espar`,
`lib_espar`, `cd_ref`, `lib_cdref` ; `CD_REF` en TAXREF v13.0, comme la
flore) ou son extrait `ifn_espar_cdref.csv`. Sert à exclure les essences
de l'indice trophique
([`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md),
`exclude_cd_ref`) : l'indice ne décrit alors plus le peuplement (mission
035, ADR 0008). Cette table liste les essences de l'inventaire (arbres,
quelques arbustes) ; elle n'est pas une liste de « strate arborée » de
la flore.

## Usage

``` r
read_tree_cd_ref(dir)
```

## Arguments

- dir:

  Dossier contenant `espar-cdref13.csv` ou `ifn_espar_cdref.csv`.

## Value

Un vecteur numérique trié de `CD_REF`, sans doublon.

## Examples

``` r
head(read_tree_cd_ref(system.file("extdata", package = "sylvostation")))
#> [1] 79319 79323 79325 79327 79333 79345
```
