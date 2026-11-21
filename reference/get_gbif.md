# Obtenir les occurrences GBIF de plantes vasculaires d'une emprise

Mode `"download"` (par défaut, brief technique § 4 étape 4 et § 5) :
demande un téléchargement
[`rgbif::occ_download()`](https://docs.ropensci.org/rgbif/reference/occ_download.html)
(plantes vasculaires, clé 7707728, coordonnées présentes, sans anomalie
géographique, depuis `year_min`, incertitude au plus `max_uncertainty`),
l'attend, l'importe et **conserve le DOI** (attributs `doi` et
`download_key`). Il exige un compte GBIF : `user`, `pwd`, `email`, ou
les variables d'environnement `GBIF_USER`, `GBIF_PWD`, `GBIF_EMAIL`.
Sans identifiants, la fonction échoue avec un message clair, avant tout
accès au réseau.

## Usage

``` r
get_gbif(
  emprise,
  user = Sys.getenv("GBIF_USER"),
  pwd = Sys.getenv("GBIF_PWD"),
  email = Sys.getenv("GBIF_EMAIL"),
  method = c("download", "search"),
  year_min = 2000,
  max_uncertainty = 25,
  keep_unknown = FALSE,
  limit = 1e+05,
  path = tempdir(),
  wait = TRUE,
  format = c("SIMPLE_CSV", "DWCA")
)
```

## Arguments

- emprise:

  Objet `sf`/`sfc` en EPSG:2154, ou `c(xmin, ymin, xmax, ymax)` en
  EPSG:2154 (x = est, y = nord). Seule sa boîte englobante est utilisée,
  reprojetée en WGS84 (rectangle dont les côtés sont des droites en
  degrés).

- user, pwd, email:

  Identifiants GBIF (mode `"download"`).

- method:

  `"download"` ou `"search"`.

- year_min:

  Première année retenue (2000).

- max_uncertainty:

  Incertitude maximale en mètres (25). `NULL` : aucun filtre
  d'incertitude (utile pour dénombrer les occurrences sans incertitude,
  que
  [`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
  traite ensuite).

- keep_unknown:

  En mode `"download"`, garder aussi les occurrences sans incertitude
  (`FALSE` par défaut, conforme au brief).

- limit:

  Mode `"search"` : nombre maximal d'occurrences (≤ 100 000).

- path:

  Dossier du fichier téléchargé (mode `"download"`).

- wait:

  Mode `"download"` : attendre et importer (`TRUE`) ou rendre seulement
  la clé de téléchargement.

- format:

  Mode `"download"` : format du téléchargement, `"SIMPLE_CSV"` (défaut,
  celui du brief technique, léger : une table à plat) ou `"DWCA"`.
  **`DWCA` apporte les colonnes `dataGeneralizations` et
  `informationWithheld`**, qui permettent à
  [`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
  de reconnaître les données généralisées (`loc_precision_m = NA`) ;
  avec `SIMPLE_CSV`, ces colonnes sont absentes (présence **à vérifier**
  au premier téléchargement réel) et seule l'incertitude déclarée
  décide. Choisir `"DWCA"` si l'on garde les points sans incertitude
  (`keep_unknown = TRUE`).

## Value

Un `data.frame` d'occurrences (colonnes Darwin Core de GBIF, coordonnées
en WGS84 : `decimalLongitude`, `decimalLatitude`), avec les attributs
`method`, et pour `"download"` `doi` et `download_key`. Passer ensuite
par
[`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md).

## Details

Mode `"search"` : **aperçu non exhaustif** par
[`rgbif::occ_search()`](https://docs.ropensci.org/rgbif/reference/occ_search.html),
au plus `limit` occurrences (jamais plus de 100 000, plafond de l'API),
sans compte et sans DOI. À réserver aux essais et aux comptages.

La clé taxonomique 7707728 relève du référentiel « GBIF Backbone
Taxonomy » (`docs/referentiels.md`, § 8) ; `occ_search()` l'emploie avec
ce référentiel. Le comportement d'`occ_download()` avec cette clé et ce
`checklistKey` n'a **pas pu être vérifié** (compte requis) : à vérifier
au premier téléchargement réel (nombre attendu dans l'emprise test : 18
538 sans filtre d'incertitude).

## Examples

``` r
if (FALSE) { # \dontrun{
occ <- get_gbif(c(1007000, 6790000, 1022000, 6805000), method = "search",
                limit = 1000)
} # }
```
