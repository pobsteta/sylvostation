# Taxons de la flore IFN sans valeur indicatrice

Liste les `CD_REF` (TAXREF v13.0 pour l'IFN) présents dans `flore` mais
absents de la table des valeurs indicatrices, avec le nombre de relevés
concernés. Ces taxons ne sont jamais supprimés en silence : à publier
dans le rapport. La jointure se fait directement sur `CD_REF` ; la
correspondance `CD_NOM` vers `CD_REF` d'autres sources exige une table
TAXREF, non disponible à ce jour (à vérifier, mission 007).

## Usage

``` r
unmatched_taxa(flore, indicateurs)
```

## Arguments

- flore:

  `data.frame` de flore (colonnes `CD_REF`, `id_placette`) ou résultat
  de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md)
  /
  [`filter_releves()`](https://pobsteta.github.io/sylvostation/reference/filter_releves.md).

- indicateurs:

  Table des valeurs indicatrices (colonne `cd_ref`).

## Value

Un `data.frame` (`cd_ref`, `n_releves`), vide s'il n'y a rien à
signaler.

## Examples

``` r
fl <- data.frame(CD_REF = c(1, 1, 2), id_placette = c("a", "b", "a"))
unmatched_taxa(fl, data.frame(cd_ref = 1))
#>   cd_ref n_releves
#> 1      2         1
```
