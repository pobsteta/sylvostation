# R² et RMSE par gradient, comparés aux repères publiés

Réunit les résultats de
[`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
de chaque gradient. Les repères sont ceux du brief technique (étape 9 et
§ 9) : R² de 0,36 (trophique), 0,52 (bioclimat) et 0,43 (réserve utile,
associée ici au gradient hydrique : lecture à confirmer). Un gradient
dont le nom n'est pas `trophic`, `bioclim` ou `hydric` n'a pas de repère
(`NA`). Le R² est celui de la validation croisée **spatiale par blocs**
(jamais un tirage aléatoire simple). Un R² supérieur au repère sur des
données synthétiques ne prouve rien : l'attribut `synthetic` le
rappelle.

## Usage

``` r
validate_stats(
  cv_results,
  reperes = .REPERES_R2,
  synthetic = FALSE,
  min_blocs_par_pli = 4
)
```

## Arguments

- cv_results:

  Liste **nommée** (un élément par gradient) de résultats de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md).

- reperes:

  Vecteur nommé des repères de R² (défaut : ceux du brief).

- synthetic:

  `TRUE` si les données sont synthétiques (balise reprise en attribut et
  en colonne).

- min_blocs_par_pli:

  Nombre minimal de blocs occupés **par pli** pour que le R² soit
  interprétable (4 par défaut ; **valeur provisoire, à vérifier**,
  `cv_min_blocs_par_pli` de config.yml). Un R² calculé avec moins de
  `min_blocs_par_pli * k` blocs dépend de quelques blocs seulement.

## Value

Un `data.frame` : `gradient`, `n`, `r2`, `rmse`, `r2_repere`, `ecart_r2`
(R² moins repère), `atteint` (R² \>= repère ; `NA` sans repère),
`block_size`, `blocs` (blocs occupés, `NA` si plis fournis), `k`,
`blocs_insuffisants` (`TRUE` si `blocs < min_blocs_par_pli * k`),
`alerte` (texte en clair, vide sinon), `synthetic`.

## Examples

``` r
set.seed(1)
d <- data.frame(x = runif(100, 1007000, 1012000), y = runif(100, 6790000, 6795000),
                loc_precision_m = 10, coarse_a = rnorm(100))
d$g <- d$coarse_a + rnorm(100, sd = 0.3)
if (requireNamespace("mgcv", quietly = TRUE)) {
  cv <- spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 1000)
  validate_stats(list(trophic = cv), synthetic = TRUE)
}
#>   gradient   n        r2      rmse r2_repere  ecart_r2 atteint block_size blocs
#> 1  trophic 100 0.8977123 0.3157231      0.36 0.5377123    TRUE       1000    24
#>   k blocs_insuffisants alerte synthetic
#> 1 5              FALSE             TRUE
```
