# Lire la table TAXREF (colonnes utiles)

Lit `TAXREFv18.txt` (tabulations, guillemets, UTF-8 ; colonnes vérifiées
sur le fichier `TAXREF_v18_2025.zip`, voir `docs/referentiels.md` § 15),
l'archive zip qui le contient, ou un extrait CSV de mêmes colonnes
(séparateur `;` ou tabulation). Ne garde que `CD_NOM`, `CD_REF`,
`LB_NOM`, `RANG` (en texte).

## Usage

``` r
read_taxref(path)
```

## Arguments

- path:

  Chemin du `.txt`, du `.csv` ou du `.zip`. Aucun téléchargement n'est
  fait ici.

## Value

Un `data.frame` (`CD_NOM`, `CD_REF`, `LB_NOM`, `RANG`).

## Examples

``` r
f <- system.file("extdata", "taxref_v18_extrait.csv", package = "sylvostation")
head(read_taxref(f))
#>   CD_NOM CD_REF             LB_NOM RANG
#> 1  84112  84112     Arum maculatum   ES
#> 2  83751  84112 Arisarum maculatum   ES
#> 3  84106  84112        Arum idaeum   ES
#> 4 162307  84112   Arum immaculatum   ES
#> 5  84107  84112   Arum immaculatum   ES
#> 6  84114  84112         Arum malyi   ES
```
