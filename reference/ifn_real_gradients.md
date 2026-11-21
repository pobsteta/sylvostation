# Gradients réels des placettes IFN (trophique, hydrique, bioclimatique)

Enchaîne, sans aucune variable fine (règle des 700 m) :
[`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md)
(niveau trophique par les valeurs indicatrices, climat kilométrique), la
réserve utile par la texture
([`ru_from_texture()`](https://pobsteta.github.io/sylvostation/reference/ru_from_texture.md))
et la contrainte hydrique BILJOU
([`hydric_stress()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress.md),
ADR 0006, « plus haut = plus humide »), puis l'axe bioclimatique
([`bioclim_axis()`](https://pobsteta.github.io/sylvostation/reference/bioclim_axis.md)).

## Usage

``` r
ifn_real_gradients(
  ifn,
  indicateurs,
  climat,
  safran,
  ru_source = "euptf2",
  annees = NULL,
  interpolation = "bilineaire",
  exclude_cd_ref = NULL,
  abundance_weights = FALSE,
  t_layer = NULL
)
```

## Arguments

- ifn:

  Résultat de
  [`filter_releves()`](https://pobsteta.github.io/sylvostation/reference/filter_releves.md).

- indicateurs:

  Résultat de
  [`load_indicator_values()`](https://pobsteta.github.io/sylvostation/reference/load_indicator_values.md).

- climat:

  `SpatRaster` de
  [`safran_climate()`](https://pobsteta.github.io/sylvostation/reference/safran_climate.md).

- safran:

  `data.frame` de
  [`read_safran()`](https://pobsteta.github.io/sylvostation/reference/read_safran.md).

- ru_source:

  Source de la réserve utile (`"euptf2"`, défaut ADR 0006).

- annees:

  Années SAFRAN gardées (`NULL` : toutes).

- interpolation:

  Séries SAFRAN aux placettes : `"bilineaire"` (défaut, mission 033) ou
  `"proche"`
  ([`hydric_stress()`](https://pobsteta.github.io/sylvostation/reference/hydric_stress.md)).

- exclude_cd_ref, abundance_weights:

  Indice trophique sans les essences arborées et/ou pondéré par
  l'abondance (mission 035) : voir
  [`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md).

- t_layer:

  `NULL` ou `SpatRaster` `coarse_t_corr_700m`
  ([`coarse_t_corr_layer()`](https://pobsteta.github.io/sylvostation/reference/coarse_t_corr_layer.md),
  mission 039) : sa valeur aux placettes (règle des 700 m appelée) est
  ajoutée en colonne et l'axe bioclimatique est appris sur elle au lieu
  de `coarse_t_moy`.

## Value

Un `sf` (une ligne par placette retenue avec flore) : `id_placette`,
`source`, `loc_precision_m`, `grad_trophique`, `ru_mm`, `grad_hydrique`,
`is_biljou`, `coarse_p_etp_sv`, `coarse_t_moy`, `bioclim`, `trophic`,
`hydric`. Attributs `methode_hydrique`, `bioclim_axis`,
`taxa_non_apparies`, `ru_source`.

## Examples

``` r
# \donttest{
if (all(vapply(c("euptf2", "soiltexture", "ranger"), requireNamespace, TRUE,
               quietly = TRUE))) {
ex <- system.file("extdata", package = "sylvostation")
ifn <- filter_releves(load_ifn(ex))
ind <- load_indicator_values("tichy", file.path(ex, "tichy_2023_extrait.csv"),
                             file.path(ex, "taxref_v18_extrait.csv"),
                             taxa = unique(ifn$flore$CD_REF))
s <- read_safran(file.path(ex, "safran_sim2_12mailles_extrait.csv"))
g <- suppressWarnings(ifn_real_gradients(ifn, ind, safran_climate(s), s))
summary(g$hydric)
}
#> Warning: no DISPLAY variable so Tk is not available
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.     NAs 
#> -70.873 -45.314 -31.642 -33.305 -20.559  -4.385       1 
# }
```
