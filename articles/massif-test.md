# Massif test : du code SER au catalogue

> **Données synthétiques.** Ce tutoriel décrit le pipeline en **mode
> démonstration** (`demo: true`). Les jeux d’essai sont fabriqués
> (`synth_*`, `synthetic = TRUE`) ou des extraits réels très réduits ;
> rien de ce qui suit n’est un résultat sur données réelles. Les
> critères d’acceptation du § 7 du brief technique sont **non
> atteints**.

## Le pipeline

Le pipeline `targets` (`_targets.R`, à la racine du dépôt) est paramétré
par `config.yml`. En mode démo, il tourne sans réseau :

``` r

targets::tar_make(callr_function = NULL)   # depuis la racine du dépôt, paquet chargé
```

Les sorties vont sous `out_dir/<ser_code>/` (`data/sorties/D11/`, ignoré
par git) : rasters GeoTIFF (COG si GDAL le permet), GeoPackage de la
carte des types, tables CSV et rapport HTML (Quarto) avec son tableau «
état de preuve » et sa section « Limites ».

## La configuration

``` r

f <- tempfile(fileext = ".yml")
writeLines(c(
  'ser_code: "D11"',
  "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
  "buffer_m: 5000", "resolution_m: 20", "crs: 2154",
  "data_dir: data", "laz_dir: data/laz", "out_dir: data/sorties",
  "ifn_precision_m: 700", "demo: true"), f)
cfg <- read_config(f)
cfg$ser_code
#> [1] "D11"
cfg$demo
#> [1] TRUE
```

## L’état de preuve

Chaque rapport dit ce qui a tourné sur données réelles et ce qui ne l’a
pas fait :

``` r

evidence_table(n_ifn = 100)[, c("etape", "etat")]
#>                                                            etape        etat
#> 1                                           1. Emprise et grille réel réduit
#> 2                               2. LiDAR HD et MNT (incrément 1) réel réduit
#> 3                                          3. Dérivés du terrain synthétique
#> 4                                                    4. Géologie réel réduit
#> 5                            5. Placettes IFN (lecture, filtres) réel réduit
#> 6                                     6. Gradients des placettes synthétique
#> 7                     7. Points d'ancrage (GBIF) et relevés GNSS synthétique
#> 8                                        8. Sols (GlobalSoilMap) non exécuté
#> 9  9. Modèles, validation croisée spatiale, zone d'applicabilité synthétique
#> 10                10. Typologie (seuils, fusion des types rares) synthétique
#> 11                                 11. Caractérisation des types synthétique
#> 12                              12. Clé de détermination terrain synthétique
#> 13                      13. Validation statistique et thématique synthétique
#> 14                          14. Comparaison à la référence (§ 9) synthétique
#> 15                                        15. Sorties et rapport synthétique
```

## La règle bloquante

Les placettes de l’IFN sont localisées à 700 m près ; aucune variable
fine ne leur est croisée :

``` r

p <- mark_ifn(data.frame(x = 1010000, y = 6795000))
assert_no_fine_extract_on_ifn(p, "coarse_t_moy")   # permis : maille large
assert_no_fine_extract_on_ifn(p, "pente")          # refusé
#> Error:
#> ! Extraction interdite sur les placettes IFN (localisées à 700 m près). Variables fines : pente. Seules les variables à maille large (préfixe `coarse_` ou COARSE_VARIABLES) sont permises.
```

## Valider et comparer à la référence

[`validate_stats()`](https://pobsteta.github.io/sylvostation/reference/validate_stats.md)
compare R² et RMSE de la validation croisée spatiale aux repères du
brief (0,36 trophique, 0,52 bioclimat, 0,43 réserve utile) ;
[`validate_maps()`](https://pobsteta.github.io/sylvostation/reference/validate_maps.md)
donne matrice de confusion, kappa et accords ;
[`compare_gradients()`](https://pobsteta.github.io/sylvostation/reference/compare_gradients.md)
suit le protocole du § 9 (corrélation de rang à 50 m, carte des écarts)
contre une référence, ici **synthétique**
(`inst/extdata/synth_reference.tif`) : les rasters d’AgroParisTech n’ont
pas été obtenus.

``` r

ref <- load_reference(system.file("extdata", "synth_reference.tif", package = "sylvostation"))
names(ref)
#> [1] "trophic" "hydric"  "bioclim"
```
