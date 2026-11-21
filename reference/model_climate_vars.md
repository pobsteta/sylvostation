# Variables climatiques des modèles régionaux

Variables à maille large des modèles trophique et hydrique selon
`config.yml` (mission 039) : `climat_temperature` (`"corrigee"` :
`coarse_t_corr_700m` ; `"bilineaire"` : `coarse_t_moy`) pour l'hydrique
et le bioclimat ; `trophique_climat` (`"actuel"` : `coarse_p_etp_sv` et
`coarse_t_moy`, état d'avant 039 ; `"corrige"` : `coarse_p_etp_sv` et
`coarse_t_corr_700m` ; `"sans"` : aucune). Défaut du pipeline : `"sans"`
(climat retiré du trophique, décision de Pascal du 2026-11-20) ; les
deux autres variantes restent des options.

## Usage

``` r
model_climate_vars(
  temperature = c("corrigee", "bilineaire"),
  trophique = c("sans", "actuel", "corrige")
)
```

## Arguments

- temperature:

  `"corrigee"` ou `"bilineaire"`.

- trophique:

  `"sans"` (défaut, décision de Pascal du 2026-11-20), `"actuel"` ou
  `"corrige"`.

## Value

Une liste : `t_var` (température du bioclimat et de l'hydrique),
`trophic`, `hydric`, `toutes`.

## Examples

``` r
model_climate_vars("corrigee", "actuel")
#> $t_var
#> [1] "coarse_t_corr_700m"
#> 
#> $trophic
#> [1] "coarse_p_etp_sv" "coarse_t_moy"   
#> 
#> $hydric
#> [1] "coarse_p_etp_sv"    "coarse_t_corr_700m"
#> 
#> $toutes
#> [1] "coarse_p_etp_sv"    "coarse_t_moy"       "coarse_t_corr_700m"
#> 
```
