# Comparer un gradient à un paramètre CarHab sur le domaine commun

Domaine = cellules où notre gradient et le rang CarHab existent (et, si
`aoa` est donné, où la zone d'applicabilité vaut 1). Les cellules
écartées sont comptées. Calcule Spearman
([`carhab_spearman()`](https://pobsteta.github.io/sylvostation/reference/carhab_spearman.md)),
classes de notre gradient aux proportions CarHab
([`carhab_quantile_classes()`](https://pobsteta.github.io/sylvostation/reference/carhab_quantile_classes.md)),
kappa pondéré, matrice de confusion et résumé par modalité.

## Usage

``` r
carhab_compare(gradient, carhab, aoa = NULL, ...)
```

## Arguments

- gradient:

  `SpatRaster` à une couche (notre gradient), EPSG:2154.

- carhab:

  `SpatRaster` du rang ordinal CarHab sur la même grille
  ([`carhab_rasterize()`](https://pobsteta.github.io/sylvostation/reference/carhab_rasterize.md)).

- aoa:

  `SpatRaster` (1 = dans la zone d'applicabilité) ou `NULL`.

- ...:

  Arguments passés à
  [`carhab_spearman()`](https://pobsteta.github.io/sylvostation/reference/carhab_spearman.md).

## Value

Une liste : `comptes` (cellules), `spearman`, `kappa` (linéaire),
`kappa_quad`, `classes` (`rangs`, `parts`, `parts_obtenues`, `coupes`),
`par_modalite` (`data.frame`), `domaine` (`data.frame` `cx`, `cy`, `x`,
`ref`, `classe`).
