# Espèces indicatrices par type (IndVal)

Calcule l'indice de valeur indicatrice de Dufrêne et Legendre, dans sa
version **équilibrée entre groupes** (`IndVal.g` de `indicspecies`) :
pour une espèce et un type, \\A\\ = abondance moyenne dans le type
rapportée à la somme des abondances moyennes de tous les types
(spécificité), \\B\\ = part des relevés du type où l'espèce est présente
(fidélité), `indval` = \\\sqrt{A B}\\. Chaque espèce est attribuée au
type où son indice est maximal. Le calcul est direct (sans dépendance) ;
le test vérifie qu'il coïncide avec
[`indicspecies::multipatt()`](https://emf-creaf.github.io/indicspecies/reference/multipatt.html).
La p-valeur vient de permutations des types entre relevés (non ajustée
pour les tests multiples).

## Usage

``` r
indicator_species(flore, types, nperm = 199L, seed = 1L)
```

## Arguments

- flore:

  Matrice ou tableau relevés (lignes) x espèces (colonnes), présence
  (0/1) ou abondance (\>= 0).

- types:

  Type de chaque relevé (vecteur de la longueur du nombre de lignes).

- nperm:

  Nombre de permutations (199 par défaut ; 0 : pas de p-valeur).

- seed:

  Graine des permutations.

## Value

Un `data.frame` trié par type puis indice décroissant : `species`,
`type`, `A`, `B`, `indval`, `p_value`. Les espèces absentes de tous les
relevés sont omises. Les relevés sans type sont écartés.

## Examples

``` r
set.seed(1)
fl <- matrix(rbinom(60 * 5, 1, 0.4), 60, 5, dimnames = list(NULL, paste0("sp", 1:5)))
fl[1:30, 1] <- 1
head(indicator_species(fl, rep(c("a", "b"), each = 30), nperm = 49))
#>   species type         A         B    indval p_value
#> 1     sp1    a 0.7142857 1.0000000 0.8451543    0.02
#> 2     sp5    a 0.6666667 0.3333333 0.4714045    0.16
#> 3     sp2    b 0.5384615 0.4666667 0.5012804    0.86
#> 4     sp3    b 0.5652174 0.4333333 0.4949015    0.66
#> 5     sp4    b 0.5454545 0.4000000 0.4670994    0.80
```
