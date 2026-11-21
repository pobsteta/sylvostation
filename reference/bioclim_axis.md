# Axe bioclimatique des placettes

Le bioclimat combine le bilan hydrique climatique de la saison de
végétation (P - ETP) et la température moyenne (brief technique, étape
5). Ces deux variables sont centrées-réduites sur les placettes, puis
résumées par leur **premier axe principal** (choix provisoire, mission
016), orienté pour que la valeur croisse avec la température (« plus
haut = plus chaud ») ; sans température, l'axe est `-(P - ETP)` réduit
(« plus haut = plus sec »).

## Usage

``` r
bioclim_axis(data, t_var = "coarse_t_moy")
```

## Arguments

- data:

  Tableau avec `coarse_p_etp_sv` et, si possible, la température
  `t_var`.

- t_var:

  Colonne de température (`"coarse_t_moy"` par défaut).

## Value

Une liste : `vars`, `center`, `scale`, `loadings`, `sens`,
`variance_expliquee`.

## Details

Depuis la mission 039, la température peut être la température corrigée
du relief moyennée dans 700 m (`t_var = "coarse_t_corr_700m"`,
[`coarse_t_corr_layer()`](https://pobsteta.github.io/sylvostation/reference/coarse_t_corr_layer.md))
; l'axe s'applique alors à la carte sur la température de la cellule
(`t_corr`, variable fine) par l'argument `layers` de
[`apply_bioclim()`](https://pobsteta.github.io/sylvostation/reference/apply_bioclim.md).

## Examples

``` r
d <- data.frame(coarse_p_etp_sv = c(100, 300, 500), coarse_t_moy = c(10, 8, 6))
bioclim_axis(d)$sens
#> [1] "plus haut = plus chaud (axe 1 de P - ETP et T, centrés-réduits)"
```
