# Lire des relevés GNSS propres

Lit un CSV de relevés GNSS (30 à 50 points par massif test, brief
technique, § 4 étape 4) : un point par ligne, ou une ligne par couple
point-espèce. Colonnes : `id` (identifiant du point), `x`, `y` (est,
nord ; ou longitude, latitude si `epsg = 4326`), **`loc_precision_m`**
(précision horizontale en mètres, obligatoire, numérique, positive, sans
`NA`) ; facultatives : `species` et toute autre colonne (conservée). Les
relevés sont convertis en EPSG:2154 dès la lecture.

## Usage

``` r
load_gnss(path, epsg = 2154)
```

## Arguments

- path:

  Chemin du CSV (séparateur virgule, UTF-8).

- epsg:

  Système des colonnes `x`/`y` : 2154 (défaut) ou 4326.

## Value

Un `sf` de points en EPSG:2154, avec `source = "gnss"` et
`loc_precision_m`.

## Examples

``` r
f <- system.file("extdata", "synth_gnss.csv", package = "sylvostation")
if (nzchar(f)) nrow(load_gnss(f))
#> [1] 6
```
