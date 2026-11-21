# Encodage d'une variable catégorielle par la moyenne de la réponse (rétrécie)

Pour chaque niveau de `x` (par exemple la lithologie ou la formation
géologique dominante dans 700 m), moyenne de `y` sur les placettes du
niveau, **rétrécie vers la moyenne générale** :
`(n * moyenne + k * moyenne_generale) / (n + k)`. Un niveau rare (n
petit) est tiré vers la moyenne générale ; un niveau fréquent garde sa
moyenne (mission 035). L'encodage utilise la réponse : **il ne doit
jamais être calculé sur les lignes qu'il sert à prédire**
([`oof_target_encoding()`](https://pobsteta.github.io/sylvostation/reference/oof_target_encoding.md)
pour l'apprentissage, et
[`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
avec `encode` pour la validation croisée sans fuite).

## Usage

``` r
target_encoding(x, y, k = 10)
```

## Arguments

- x:

  Vecteur de niveaux (texte ou facteur) ; `NA` ignoré.

- y:

  Réponse numérique.

- k:

  Poids de la moyenne générale, en nombre de placettes équivalentes (10
  par défaut, valeur provisoire).

## Value

Un `data.frame` (`niveau`, `n`, `moyenne`, `valeur`) ; attributs
`generale` (moyenne générale) et `k`.

## Examples

``` r
target_encoding(c("a", "a", "a", "b"), c(1, 2, 3, 10), k = 2)
#>   niveau n moyenne valeur
#> 1      a 3       2    2.8
#> 2      b 1      10    6.0
```
