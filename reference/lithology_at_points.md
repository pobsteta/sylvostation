# Lithologie dominante dans un disque autour de points (placettes IFN)

Pour chaque point, la classe lithologique **de plus grande surface**
dans le disque de rayon `radius` (mission 035). C'est le prédicteur
géologique à maille large permis pour les placettes de l'IFN (localisées
à 700 m près) : même résultat que
[`dominant_lithology()`](https://pobsteta.github.io/sylvostation/reference/dominant_lithology.md)
au centre d'une cellule, mais calculé aux seuls points, sans raster de
toute la GRECO. La variable s'appelle `coarse_litho_700m`.

## Usage

``` r
lithology_at_points(points, geol, table, radius = 700, min_cover = 0.5)
```

## Arguments

- points:

  `sf` de points en Lambert-93 (EPSG:2154, x = est, y = nord), avec une
  colonne `id_placette` et, pour les placettes IFN, `loc_precision_m`.

- geol:

  `sf` polygonal en Lambert-93 avec `NOTATION`
  ([`read_geology()`](https://pobsteta.github.io/sylvostation/reference/read_geology.md)).

- table:

  Tableau de recodage avec `notation` et `classe`
  ([`recode_lithology()`](https://pobsteta.github.io/sylvostation/reference/recode_lithology.md)).

- radius:

  Rayon du disque (m, 700 par défaut).

- min_cover:

  Part minimale du disque couverte par `geol` (0,5 par défaut).

## Value

Un `data.frame` (une ligne par point) : `id_placette`,
`coarse_litho_700m` (classe, texte, `NA` sans géologie),
`coarse_formation_700m` (`NOTATION` dominante, pour l'encodage par
formation de
[`target_encoding()`](https://pobsteta.github.io/sylvostation/reference/target_encoding.md)),
`litho_couverture` (part du disque couverte), `litho_part_dominante`
(part de la classe dominante dans la partie couverte). Attributs :
`formations_non_classees` (`notation`, `surface_km2`, `n_points`) et
`radius`.

## Details

La règle des 700 m est appelée en premier
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)),
et un rayon inférieur à la précision de localisation des points
(`loc_precision_m`) est refusé : ce serait une variable fine déguisée.
Pour une placette IFN, la précision est au moins 700 m même si
`loc_precision_m` est absent ou `NA` ; hors IFN, une précision absente
ou `NA` est refusée. Jointure par `NOTATION`, jamais par `CODE` ; une
notation absente de `table` reçoit `non_classe` (jamais une classe par
défaut) et est listée dans l'attribut `formations_non_classees`. Un
point dont le disque est couvert à moins de `min_cover` par la couche
(hors des départements lus) n'a **pas** de lithologie (`NA`) : il est
compté, jamais complété.

## Examples

``` r
g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
                             package = "sylvostation"), quiet = TRUE)
tab <- suppressWarnings(recode_lithology(list_formations(g)))
p <- mark_ifn(sf::st_sf(id_placette = "a",
                        geometry = sf::st_sfc(sf::st_point(c(1014500, 6799300)), crs = 2154)))
lithology_at_points(p, g, tab)
#>   id_placette coarse_litho_700m coarse_formation_700m litho_couverture
#> 1           a           granite               h3-4pã3        0.9996368
#>   litho_part_dominante
#> 1            0.6365002
```
