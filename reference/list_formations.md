# Lister les formations géologiques d'une couche

Regroupe les polygones d'une couche BD Charm-50 par `NOTATION` (jamais
par `CODE`, qui n'est pas comparable d'un département à l'autre ;
`docs/referentiels.md`, § 5).

## Usage

``` r
list_formations(
  geol,
  notation = "NOTATION",
  description = "DESCR",
  code = "CODE",
  dep = "dep"
)
```

## Arguments

- geol:

  Objet `sf` polygonal en Lambert-93 (EPSG:2154) portant les champs
  `NOTATION`, `DESCR` et `CODE` (nom des champs réglable ci-dessous).

- notation, description, code, dep:

  Noms des champs (`dep` : facultatif).

## Value

Un `data.frame` trié par surface décroissante : `notation`, `code` (les
`CODE` distincts, séparés par `/`), `description` (celle du plus grand
polygone de la notation), `n_poly`, `area_km2` (surface des polygones
**dans l'emprise de la couche**, calculée sur la géométrie fournie) et,
si la couche porte le champ `dep`, `dep` : département du plus grand
polygone (celui dont vient la description), sans zéro de tête (`"67"`).

## Examples

``` r
g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
                             package = "sylvostation"), quiet = TRUE)
head(list_formations(g), 3)
#>   notation    code
#> 1  Smæsill 232/226
#> 2   h2ã3sc     197
#> 3   h3M2Ka     226
#>                                                                                                                                  description
#> 1 Série métamorphique de Sainte-Marie-aux-Mines - Gneiss à sillimanite fibreuse et gneiss rubanés laminés - (Protolithe cambro-ordovicien ?)
#> 2                                       Granites des Vosges moyennes et méridionales -  Granite syncinématique du Bilstein - (Viséen 335 Ma)
#> 3                            Migmatites et granites migmatitiques - Granite migmatitique de Kaysersberg - Granite du Hohrodberg - (Namurien)
#>   n_poly area_km2 dep
#> 1     24 27.67452  68
#> 2      9 24.70362  68
#> 3      9 21.46401  68
```
