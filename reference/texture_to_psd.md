# Granulométrie représentative d'un code de texture IFN

Pour chaque code de texture IFN, rend les pourcentages d'argile (\< 2
µm), de limon (2-50 µm) et de sable (50-2000 µm) du **centre de
gravité** de la réunion des polygones de ses classes dans le triangle de
l'Aisne (`soiltexture`, `FR.AISNE.TT`, mêmes limites granulométriques
que les fonctions de pédotransfert `euptf2`). Le centre de la réunion
est la moyenne des centres des classes pondérée par leur aire ; il est
calculé dans le plan (argile, limon), image affine du triangle, qui
conserve centres et rapports d'aires. Les classes hors du triangle
(`Als`, code 8) ne sont pas comptées (colonne `hors_triangle`).

## Usage

``` r
texture_to_psd(code, dictionnaire = read_texture_dictionary())
```

## Arguments

- code:

  Vecteur de codes de texture IFN (`"0"` à `"9"`, `"H"`).

- dictionnaire:

  Résultat de
  [`read_texture_dictionary()`](https://pobsteta.github.io/sylvostation/reference/read_texture_dictionary.md).

## Value

Un `data.frame`, une ligne par élément de `code` : `code`, `argile`,
`limon`, `sable` (%), `classes` (classes de l'Aisne retenues),
`hors_triangle`, `aire` (part de l'aire du triangle). `NA` pour `0`,
`H`, un code vide ou inconnu.

## Details

C'est une valeur **représentative**, pas une mesure : la texture IFN est
estimée au toucher et la classe couvre une plage (voir `aire`, part du
triangle couverte).

## Examples

``` r
texture_to_psd(c("1", "4", "6", "9", "H"))
#>   code    argile     limon    sable        classes hors_triangle   aire
#> 1    1  4.444444  7.777778 87.77778              S               0.0300
#> 2    4 12.274775 50.472973 37.25225 LS,LSA,LMS,LLS               0.1850
#> 3    6  8.750000 83.750000  7.50000          LM,LL               0.0525
#> 4    9 58.200883 20.651214 21.14790          A,ALO               0.3775
#> 5    H        NA        NA       NA           <NA>          <NA>     NA
```
