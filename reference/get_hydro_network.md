# Réseau hydrographique BD TOPAGE sur une emprise

Lit les tronçons hydrographiques de la BD TOPAGE (Sandre) de Métropole
par le service WFS du Sandre (référentiels, § 16), filtrés par l'emprise
en Lambert-93 (`BBOX=...,urn:ogc:def:crs:EPSG::2154`, x = est puis y =
nord). Le nom de la couche, qui porte le millésime, est lu dans le
`GetCapabilities` (le plus récent). Le service ne sert pas le JSON : la
lecture se fait en GML. Les tronçons fictifs (`TronconFictifTH`) sont
écartés. **Pas de filtre sur la persistance** : la liste des modalités
de `PersistanceTH` n'a pas été lue (à vérifier), les cours d'eau
intermittents sont donc conservés.

## Usage

``` r
get_hydro_network(
  emprise,
  source = c("wfs", "file"),
  path = NULL,
  taille_page = 500L
)
```

## Arguments

- emprise:

  Objet `sf`/`sfc` en EPSG:2154, `bbox`, ou `c(xmin, ymin, xmax, ymax)`
  (x = est, y = nord, EPSG:2154), comme
  [`build_grid()`](https://pobsteta.github.io/sylvostation/reference/build_grid.md).

- source:

  `"wfs"` (réseau) ou `"file"` (lit `path`).

- path:

  Fichier vectoriel local si `source = "file"`.

- taille_page:

  Nombre de tronçons par requête.

## Value

Un `sf` de lignes en EPSG:2154 (colonnes TOPAGE : `CdOH`, `NatureTH`,
`PersistanceTH`, `TronconFictifTH`...). Attribut `couche` : nom de la
couche lue.

## Details

Avec `source = "file"`, la fonction lit un extrait local (aucun réseau)
: c'est le mode des tests (`inst/extdata/topage_troncons_extrait.gpkg`).

## Examples

``` r
f <- system.file("extdata", "topage_troncons_extrait.gpkg", package = "sylvostation")
if (nzchar(f)) {
  r <- get_hydro_network(c(1015000, 6793000, 1016000, 6794000), source = "file", path = f)
  nrow(r)
}
#> [1] 0
```
