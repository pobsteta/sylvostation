# Lire la BD Charm-50 (formations géologiques) de plusieurs sources

Lit des GeoPackage (extrait du dépôt) ou des archives départementales
`GEO050K_HARM_0DD.zip` (couche `S_FGEOL`, encodage WINDOWS-1252, CRS
posé à 2154 : docs/referentiels.md § 5), les réunit et les recoupe à
l'emprise. Les départements se joignent par `NOTATION`, jamais par
`CODE`.

## Usage

``` r
read_geology(paths, emprise = NULL)
```

## Arguments

- paths:

  Chemins des `.gpkg` ou des `.zip`.

- emprise:

  Emprise (EPSG:2154) ou `NULL`.

## Value

Un `sf` (EPSG:2154) avec `dep`, `CARTE`, `CODE`, `CODE_LEG`, `NOTATION`,
`DESCR`.

## Examples

``` r
g <- read_geology(system.file("extdata", "bdcharm50_emprise_test.gpkg",
                              package = "sylvostation"))
nrow(g)
#> [1] 661
```
