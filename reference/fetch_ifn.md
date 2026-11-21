# Télécharger et décompresser l'archive des données brutes IFN

Archive `export_dataifn_*.zip` (docs/referentiels.md § 7, Licence
Ouverte 2.0), mise en cache, puis extraction de `PLACETTE.csv`,
`ECOLOGIE.csv`, `FLORE.csv` et `ARBRE.csv`, ainsi que
`espar-cdref13.csv` (essences et leur `CD_REF`), dans `cache_dir/ifn`.

## Usage

``` r
fetch_ifn(url, cache_dir, offline = FALSE, downloader = utils::download.file)
```

## Arguments

- url:

  Adresse de l'archive (`cfg$ifn_archive_url`).

- cache_dir:

  Dossier de cache.

- offline, downloader:

  Voir
  [`fetch_cached()`](https://pobsteta.github.io/sylvostation/reference/fetch_cached.md).

## Value

Le dossier des CSV, à passer à
[`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md).

## Examples

``` r
if (FALSE) { # \dontrun{
load_ifn(fetch_ifn(read_config()$ifn_archive_url, "data/cache"))
} # }
```
