# Lire les placettes IFN

Lit les fichiers bruts DataIFN (séparateur `;`, UTF-8 avec ou sans BOM)
d'un dossier : `PLACETTE.csv`, `ECOLOGIE.csv`, `FLORE.csv`, `ARBRE.csv`,
ou les extraits du dépôt `ifn_placette.csv`, etc.
(`docs/referentiels.md`, § 7). `PLACETTE` et `ECOLOGIE` sont joints par
(`CAMPAGNE`, `IDP`) ; le résultat est un objet `sf` en Lambert-93
(EPSG:2154, `XL` = est, `YL` = nord). Les tables sont marquées par
[`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md)
: `source = "ifn"` et `loc_precision_m` (700 m), donc **toute extraction
de variable fine y est interdite**
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)).

## Usage

``` r
load_ifn(
  dir,
  files = c("PLACETTE", "ECOLOGIE", "FLORE", "ARBRE"),
  precision_m = 700
)
```

## Arguments

- dir:

  Dossier contenant les fichiers.

- files:

  Fichiers à lire. `PLACETTE` est obligatoire ; `ECOLOGIE` est
  nécessaire à
  [`compute_gradients()`](https://pobsteta.github.io/sylvostation/reference/compute_gradients.md).

- precision_m:

  Précision de localisation en mètres, à passer depuis
  `read_config()$ifn_precision_m` (700 par défaut).

## Value

Une liste de classe `sylvo_ifn` : `placettes` (`sf`, une ligne par
placette et campagne, avec `id_placette` = `CAMPAGNE_IDP` et les
colonnes d'`ECOLOGIE`), `flore` et `arbre` (`data.frame`, `NULL` si non
lus), tous marqués IFN.

## Details

Seules les clés sont converties (`CAMPAGNE`, `IDP`, `XL`, `YL`,
`VISITE`, `CD_REF`, `ABOND`, dates `DATEPOINT` et `DATEECO`) ; les
autres colonnes restent en caractères, car les codes d'une même colonne
changent de nomenclature selon la campagne (`metadonnees.csv`). La flore
n'est relevée qu'en première visite.

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
nrow(ifn$placettes)
#> [1] 100
```
