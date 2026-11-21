# Lire et valider la saisie de la flore

Contrôle le gabarit `inst/terrain/gabarit_flore.csv` rempli (une ligne
par couple relevé-espèce) : colonnes attendues, coordonnées en
Lambert-93 (x = est, y = nord), un seul emplacement par relevé,
précision `loc_precision_m` au plus `max_precision_m` (25 m),
recouvrements au code de Braun-Blanquet
([BRAUN_BLANQUET](https://pobsteta.github.io/sylvostation/reference/BRAUN_BLANQUET.md))
avec au moins une strate renseignée, pas d'espèce en double dans un
relevé. Lit ensuite le fichier par
[`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md),
le lecteur du pipeline (`gnss_path`).

## Usage

``` r
read_field_sheet(path, max_precision_m = 25, epsg = 2154)
```

## Arguments

- path:

  Chemin du CSV (séparateur virgule, point décimal, UTF-8).

- max_precision_m:

  Précision maximale admise (25 m).

- epsg:

  Système des colonnes `x`/`y` : 2154 (défaut) ou 4326 (longitude,
  latitude), reprojeté en 2154 dès la lecture
  ([`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md)).

## Value

Le `sf` de
[`load_gnss()`](https://pobsteta.github.io/sylvostation/reference/load_gnss.md).

## Examples

``` r
if (FALSE) { # \dontrun{
read_field_sheet("releves_flore.csv")
} # }
```
