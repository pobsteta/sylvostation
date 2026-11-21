# Pile de prédicteurs du mode démo

Assemble, sur la grille du MNT, les couches fines de
[`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md)
(pente, TWI, TPI, `mnt`) et les couches **à maille large** du climat
(`coarse_p_etp_sv` = P - ETP, `coarse_t_moy`), ces dernières
ré-échantillonnées de 1 km à la grille par interpolation bilinéaire. Les
noms `coarse_` signalent les couches autorisées aux placettes IFN
([`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)).

## Usage

``` r
demo_predictors(terrain, dtm, climat)
```

## Arguments

- terrain:

  `SpatRaster` de
  [`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md).

- dtm:

  `SpatRaster` du MNT (même grille que `terrain`).

- climat:

  `SpatRaster` de
  [`synth_demo_climat()`](https://pobsteta.github.io/sylvostation/reference/synth_demo_climat.md)
  (`p_sv`, `etp_sv`, `t_moy`).

## Value

Un `SpatRaster` : `mnt`, `pente`, `twi`, `tpi_100`, `tpi_300` si
présents, `coarse_p_etp_sv`, `coarse_t_moy`.

## Examples

``` r
if (FALSE) { # \dontrun{
demo_predictors(derive_terrain(dtm), dtm, climat)
} # }
```
