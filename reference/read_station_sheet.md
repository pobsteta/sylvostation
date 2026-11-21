# Lire et valider la saisie des stations

Contrôle le gabarit `inst/terrain/gabarit_station.csv` rempli (une ligne
par relevé) : colonnes attendues, Lambert-93, précision au plus 25 m,
`rang_utilise` dans 0, 1, 2, forme d'humus vide ou dans
[HUMUS_FORMS](https://pobsteta.github.io/sylvostation/reference/HUMUS_FORMS.md),
`tariere_refus` vide, `oui` ou `non`, recouvrements de strate
(`rec_strate_*`) vides ou compris entre 0 et 100 %.

## Usage

``` r
read_station_sheet(path, max_precision_m = 25, epsg = 2154)
```

## Arguments

- path:

  Chemin du CSV (séparateur virgule, point décimal, UTF-8).

- max_precision_m:

  Précision maximale admise (25 m).

- epsg:

  Système des colonnes `x`/`y` : 2154 (défaut) ou 4326, reprojeté en
  2154 dès la lecture (les colonnes `x`/`y` du résultat sont alors en
  Lambert-93).

## Value

`sf` de points en EPSG:2154, `source = "gnss"`.

## Examples

``` r
if (FALSE) { # \dontrun{
read_station_sheet("releves_station.csv")
} # }
```
