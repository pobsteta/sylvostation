# Lire les polygones CarHab de l'emprise (WFS paginé, avec cache)

Si le fichier de cache existe, il est relu sans réseau ; sinon les pages
sont lues par GDAL
([`sf::read_sf`](https://r-spatial.github.io/sf/reference/st_read.html)),
dédoublonnées sur `id_polygone_carhab`, puis écrites dans `cache_dir`
(jamais dans le dépôt). Les polygones qui recoupent l'emprise sont
rendus entiers (non découpés) :
[`carhab_rasterize()`](https://pobsteta.github.io/sylvostation/reference/carhab_rasterize.md)
découpe par la grille.

## Usage

``` r
carhab_fetch(
  bbox,
  cache_dir = file.path("data", "cache", "carhab"),
  occupation = "foret",
  taille_page = 500L,
  reader = sf::read_sf,
  essais = 4L
)
```

## Arguments

- bbox:

  Emprise `c(xmin, ymin, xmax, ymax)` en Lambert-93.

- cache_dir:

  Dossier de cache (par défaut `data/cache/carhab`).

- occupation:

  Voir
  [`carhab_wfs_url()`](https://pobsteta.github.io/sylvostation/reference/carhab_wfs_url.md).

- taille_page:

  Taille de page WFS.

- reader:

  Fonction `url -> sf` (injectable pour les tests ; défaut
  [`sf::read_sf`](https://r-spatial.github.io/sf/reference/st_read.html)).

- essais:

  Nombre d'essais par page.

## Value

Un `sf` en EPSG:2154.
