# Optimum trophique de Tichý des essences (repère indicatif)

Pour chaque essence ESPAR, moyenne de `ph` et `azote` de l'espèce dans
la table des valeurs indicatrices (Tichý et al., celle qui sert au
trophique), appariée par **`CD_REF`** grâce à la table essence -\>
`CD_REF` de l'IFN
([`read_espar_cdref()`](https://pobsteta.github.io/sylvostation/reference/read_espar_cdref.md)).
**Repère indicatif, jamais la base d'une alerte** : la table décrit
l'espèce, non la station forestière, et contredit les placettes (hêtre
5,7 contre 4,2 observé sans les arbres). Les optimums forestiers publiés
(Rameau et al., *Flore forestière française* ; EcoPlant) sont **à
vérifier, non lus**.

## Usage

``` r
species_optima(espar, indicateurs, espar_cdref, codes = NULL)
```

## Arguments

- espar:

  Codes ESPAR.

- indicateurs:

  Valeurs indicatrices (`cd_ref`, `ph`, `azote`).

- espar_cdref:

  Résultat de
  [`read_espar_cdref()`](https://pobsteta.github.io/sylvostation/reference/read_espar_cdref.md).

- codes:

  Facultatif : résultat de
  [`read_espar_codes()`](https://pobsteta.github.io/sylvostation/reference/read_espar_codes.md)
  (ajoute `latin_espar1`, nom latin de l'unité ESPAR1 des métadonnées,
  qui complète le nom du taxon de `espar_cdref`).

## Value

Un `data.frame` : `espar`, `nom` (libellé de l'essence), `latin` (nom du
taxon), `cd_ref`, `optimum_tichy` (`NA` si l'espèce n'a ni `ph` ni
`azote`, ou n'est pas dans la table), `n_lignes`, et `latin_espar1` si
`codes` est fourni.

## Examples

``` r
ind <- data.frame(cd_ref = 97947, ph = 5.7, azote = NA_real_)
species_optima(c("09", "64"), ind, read_espar_cdref(system.file("extdata",
               package = "sylvostation")))
#>   espar     nom                 latin cd_ref optimum_tichy n_lignes
#> 1    09   Hêtre       Fagus sylvatica  97947           5.7        1
#> 2    64 Douglas Pseudotsuga menziesii 116216            NA        0
```
