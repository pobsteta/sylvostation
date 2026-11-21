# Kappa pondéré de deux classements ordinaux, accord à une classe près, matrice

Kappa pondéré de Cohen écrit ici (aucun paquet de kappa n'est installé)
: `kappa = (po - pe) / (1 - pe)` avec des poids d'accord
`1 - |i - j| / (k - 1)` (linéaire) ou `1 - ((i - j) / (k - 1))^2`
(quadratique).

## Usage

``` r
carhab_kappa(a, b, k = max(a, b), poids = c("lineaire", "quadratique"))
```

## Arguments

- a, b:

  Classes entières 1..k (mêmes niveaux), sans `NA`.

- k:

  Nombre de classes (défaut : maximum de `a` et `b`).

- poids:

  `"lineaire"` ou `"quadratique"`.

## Value

Une liste : `kappa`, `kappa_simple`, `accord_exact`, `accord_1_classe`,
`matrice` (`a` en lignes, `b` en colonnes, effectifs), `n`.

## Examples

``` r
carhab_kappa(c(1, 2, 3, 3), c(1, 2, 3, 2))$kappa
#> [1] 0.7142857
```
