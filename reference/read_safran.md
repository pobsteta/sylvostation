# Lire des fichiers SAFRAN (SIM2 quotidien)

Lit un ou plusieurs CSV (`;`, décimale point, `.csv` ou `.csv.gz`) au
format de meteo.data.gouv.fr (docs/referentiels.md, § 23) et garde
`LAMBX`, `LAMBY`, `DATE`, `PRENEI`, `PRELIQ`, `ETP` et, s'ils existent,
`T` (°C), `FF` (vent, m/s), `HU` (humidité relative, %) et `SSI`
(rayonnement, J/cm², cumul quotidien ; unités du document « Données
quotidiennes SIM » de Météo-France du 2026-03-31, mission 021).

## Usage

``` r
read_safran(paths)
```

## Arguments

- paths:

  Chemins des fichiers.

## Value

Un `data.frame`.

## Examples

``` r
s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
                              package = "sylvostation"))
length(unique(paste(s$LAMBX, s$LAMBY)))
#> [1] 12
```
