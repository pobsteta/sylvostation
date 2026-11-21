# Coefficients de réserve en eau par classe de texture IFN

Table par défaut de
[`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md)
: millimètres d'eau utilisable par centimètre de terre fine, par code de
texture IFN (`TEXT1`, `TEXT2`, modalités de `metadonnees.csv` : 0
absence de terre fine, 1 sable, 2 sable limoneux, 3 sable argileux, 4
limon sableux, 5 limon argileux, 6 limon, 7 argile limoneuse, 8 argile
sablo-limoneuse, 9 argile, H texture organique).

## Usage

``` r
ru_coefficients(source = c("bruand2004", "provisoire"))
```

## Arguments

- source:

  `"bruand2004"` ou `"provisoire"`.

## Value

`"bruand2004"` : liste `haut`, `bas` ; `"provisoire"` : vecteur nommé
par code de texture. Dans les deux cas, attributs `verifie`, `source`,
`unite` (`"mm/cm"`).

## Details

**`source = "bruand2004"` (défaut)** : table publiée. Bruand A., Duval
O., Cousin I. (2004), « Estimation des propriétés de rétention en eau
des sols à partir de la base de données SOLHYDRO : une première
proposition combinant le type d'horizon, sa texture et sa densité
apparente », *Étude et Gestion des Sols* 11(3) : 323-332, **tableau 2,
p. 328**, colonnes « sans prise en compte de la densité apparente »
(valeurs relues par le relecteur de la mission 013,
`docs/referentiels.md` § 18). On retient la réserve en eau utile **«
défaut »** (θ à pF 2,0 moins θ à pF 4,2), la plus basse des deux, par
prudence. La table distingue l'horizon **A** (`TEXT1`, horizon
supérieur) et les horizons **E, B, C** (`TEXT2`) : le résultat est une
liste `list(haut = , bas = )` de deux vecteurs nommés, acceptée par
l'argument `ru_table` de
[`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md).
Attribut `verifie = TRUE` (le tableau lui-même est relu).

**Correspondance codes IFN → classes de l'Aisne** (mission 019) : lue
dans le dictionnaire des données brutes de l'IFN
([`read_texture_dictionary()`](https://pobsteta.github.io/sylvostation/reference/read_texture_dictionary.md),
extrait de `metadonnees.csv`), qui définit chaque code par les
abréviations des classes du triangle de l'Aisne : 1 = S, 2 = SL, 3 = SA,
4 = LS, LSA, LMS, LLS, 5 = LA, LAS, 6 = LM, LL, 7 = AL, 8 = AS (et
`Als`, hors du triangle de l'Aisne, sans valeur chez Bruand), 9 = A,
ALO. Attribut `correspondance_verifiee = TRUE`. Un code qui couvre
plusieurs classes prend la **moyenne simple** des classes qui ont une
valeur (choix du code, non publié) ; avec cette correspondance, chaque
code 1 à 9 a au moins une classe renseignée pour chaque type d'horizon
(l'ancien repli d'un type d'horizon sur l'autre est retiré ; un code
sans valeur rendrait `NA`). Une hypothèse reste du code : `TEXT1` est
pris pour un horizon A, `TEXT2` pour un horizon E, B ou C. Les écarts
types de l'article (0,14 à 0,53 mm/cm) ne sont pas propagés. `H` vaut
`NA` (la couche organique n'est pas comptée), `0` vaut 0. La réserve
utile de référence est désormais celle de
[`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md)
(euptf2) ; cette table sert de contre-vérification.

**`source = "provisoire"`** : ordres de grandeur **non publiés** de la
mission 005 (vecteur unique pour les deux horizons), attribut
`verifie = FALSE` ; conservés pour la comparaison.

## Examples

``` r
ru_coefficients()
#> $haut
#>        0        1        2        3        4        5        6        7 
#> 0.000000 0.600000 1.310000 1.280000 1.626667 1.700000 2.130000 1.360000 
#>        8        9        H 
#> 1.730000 1.240000       NA 
#> 
#> $bas
#>     0     1     2     3     4     5     6     7     8     9     H 
#> 0.000 0.730 1.160 1.030 1.615 1.485 2.070 1.130 0.950 1.025    NA 
#> 
#> attr(,"verifie")
#> [1] TRUE
#> attr(,"correspondance_verifiee")
#> [1] TRUE
#> attr(,"source")
#> [1] "Bruand, Duval et Cousin (2004), Etude et Gestion des Sols 11(3), 323-332, tableau 2 p. 328, colonne defaut, sans Da"
#> attr(,"unite")
#> [1] "mm/cm"
#> attr(,"correspondance")
#> attr(,"correspondance")$`1`
#> [1] "S"
#> 
#> attr(,"correspondance")$`2`
#> [1] "SL"
#> 
#> attr(,"correspondance")$`3`
#> [1] "SA"
#> 
#> attr(,"correspondance")$`4`
#> [1] "LS"  "LSA" "LMS" "LLS"
#> 
#> attr(,"correspondance")$`5`
#> [1] "LA"  "LAS"
#> 
#> attr(,"correspondance")$`6`
#> [1] "LM" "LL"
#> 
#> attr(,"correspondance")$`7`
#> [1] "AL"
#> 
#> attr(,"correspondance")$`8`
#> [1] "AS"  "ALS"
#> 
#> attr(,"correspondance")$`9`
#> [1] "A"   "ALO"
#> 
ru_coefficients("provisoire")
#>   0   1   2   3   4   5   6   7   8   9   H 
#> 0.0 0.7 1.0 1.1 1.4 1.6 1.7 1.5 1.3 1.4  NA 
#> attr(,"verifie")
#> [1] FALSE
#> attr(,"source")
#> [1] "provisoire (non publié)"
#> attr(,"unite")
#> [1] "mm/cm"
```
