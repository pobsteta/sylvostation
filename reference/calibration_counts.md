# Effectifs de la calibration : où se perdent les placettes

Tableau de l'entonnoir de la mission 035, de toutes les lignes
`PLACETTE` de la GRECO aux placettes d'apprentissage : chaque étape, son
effectif, ce qui est perdu et la cause. Une chute brutale à l'étape «
climat » signale une emprise SAFRAN trop petite (cause de l'effectif de
187 de la mission 018).

## Usage

``` r
calibration_counts(ifn, ifn_gradients, train, litho = NULL, final = NULL)
```

## Arguments

- ifn:

  Résultat de
  [`filter_releves()`](https://pobsteta.github.io/sylvostation/reference/filter_releves.md)
  (`placettes` avec `en_saison`, `retenu`).

- ifn_gradients:

  Résultat de
  [`ifn_real_gradients()`](https://pobsteta.github.io/sylvostation/reference/ifn_real_gradients.md)
  (`coarse_t_moy`).

- train:

  Liste par gradient (`trophic`, `hydric`) des placettes d'apprentissage
  avant la lithologie (climat complet).

- litho:

  Résultat de
  [`lithology_at_points()`](https://pobsteta.github.io/sylvostation/reference/lithology_at_points.md)
  (`NULL` : étape omise).

- final:

  Placettes du modèle trophique final (avec lithologie ; `NULL` : omis).

## Value

Un `data.frame` : `etape`, `n`, `perdues`, `cause`.

## Examples

``` r
ifn <- filter_releves(load_ifn(system.file("extdata", package = "sylvostation")))
calibration_counts(ifn, data.frame(coarse_t_moy = c(1, NA)), list(trophic = 1, hydric = 1))
#>                         etape   n perdues
#> 1 lignes PLACETTE de la GRECO 100      NA
#> 2        avec relevé ECOLOGIE 100       0
#> 3            relevé en saison  51      49
#> 4        sans incident récent  49       2
#> 5        trophique calculable   2      47
#> 6          avec climat SAFRAN   1       1
#> 7      apprentissage hydrique   1       0
#>                                                                             cause
#> 1                                                            une ligne par visite
#> 2                                           la 2e visite n'a ni écologie ni flore
#> 3                                                mois de relevé hors de la saison
#> 4                                              placette perturbée (NINCID, INCID)
#> 5                   aucune espèce à valeur indicatrice après filtrage de la flore
#> 6 hors de l'emprise SAFRAN lue (une emprise trop petite fait chuter cet effectif)
#> 7                             réserve utile ou BILJOU manquant (branche hydrique)
```
