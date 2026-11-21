# Groupe de la nomenclature BD Forêt d'une essence IFN

Regroupe les codes ESPAR comme la nomenclature TFV de la BD Forêt v2
(hêtre, chênes décidus, châtaignier, sapin ou épicéa, pin sylvestre,
douglas, mélèze, autres conifères, autres feuillus). **Correspondance
partielle, hypothèse à vérifier** (regroupements `G01` et `G61` non lus
; chênes décidus = ESPAR 02, 03, 04, 05, 07, 34).

## Usage

``` r
espar_group_tfv(espar)
```

## Arguments

- espar:

  Codes ESPAR (caractères).

## Value

Un vecteur de caractères (`NA` si `espar` est `NA`).

## Examples

``` r
espar_group_tfv(c("09", "62", "13G", NA))
#> [1] "Hêtre"           "Sapin ou épicéa" "Autres feuillus" NA               
```
