# Rasteriser un champ CarHab sur notre grille (centre de cellule)

Le polygone est rasterisé par le centre de la cellule
(`touches = FALSE`) ; un polygone à cheval sur la grille est donc
découpé par elle. Le champ texte est recodé en rang ordinal
([`carhab_recode()`](https://pobsteta.github.io/sylvostation/reference/carhab_recode.md)).

## Usage

``` r
carhab_rasterize(
  polys,
  grid,
  champ = c("acidite_edaphique", "humidite_edaphique")
)
```

## Arguments

- polys:

  `sf` de polygones CarHab, EPSG:2154.

- grid:

  `SpatRaster` de la grille (EPSG:2154).

- champ:

  `"acidite_edaphique"` ou `"humidite_edaphique"`.

## Value

Un `SpatRaster` à une couche (rang ordinal, `NA` hors polygone) sur
`grid`.
