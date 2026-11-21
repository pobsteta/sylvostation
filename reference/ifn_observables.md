# Observables de terrain des placettes IFN, pour la clé

Variables **notées sur le terrain** par l'IFN (`ECOLOGIE`,
docs/referentiels.md § 7), renommées `obs_*` pour ne jamais être
confondues avec des variables fines extraites d'un raster : `obs_pente`
(`PENT2`, %), `obs_topo` (`TOPO`, code), `obs_humus` (`HUMUS`, code).
Les codes restent ceux de l'IFN (nomenclature selon la campagne).

## Usage

``` r
ifn_observables(placettes)
```

## Arguments

- placettes:

  `ifn$placettes`.

## Value

Un `data.frame` : `id_placette`, `obs_pente`, `obs_topo`, `obs_humus`.

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
head(ifn_observables(ifn$placettes))
#>    id_placette obs_pente obs_topo obs_humus
#> 1 2025_2012026        50        4        21
#> 2 2025_2016787        51        5        20
#> 3 2025_2031206        42        2        20
#> 4 2025_2031924        34        4        30
#> 5 2025_2037335        NA        9        22
#> 6 2025_2046433        15        2        22
```
