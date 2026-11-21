# Tableau « état de preuve » du mode réel

Une ligne par étape : `etat` vaut `réel`, `réel réduit` (extrait réel de
`inst/extdata`, mode `offline: true`), `non exécuté`,
`non atteint (entrée absente)` (critère dont l'entrée manque : relevés
GNSS) ou `sautée (entrée absente)` (étape sautée : comparaison à la
référence). Jamais `synthétique` : le mode réel n'utilise aucun jeu
fabriqué.

## Usage

``` r
evidence_table_real(f)
```

## Arguments

- f:

  Liste de faits du run : `offline`, `ser_code`, `n_tiles`, `n_ifn`,
  `greco`, `mrvbf` (couche calculée ?), `empty_layers`, `hydro_n`,
  `methode_hydrique`, `n_gbif` (`NA` hors ligne), `soils` (logique),
  `forest_mask` (logique), `n_cells`, `n_types`, `key` (logique), `gnss`
  (logique), `reference` (logique), `taxref_version`, `safran_annees`,
  et pour la carte hydrique (mission 021) et `resolution_m` (m,
  `config.yml`) `methode_hydrique_carte`, `k_methode`, `ru_origine`
  (texte), `ecart_moyen_abs`, `ecart_max_abs`, `n_controle`. Sans
  `methode_hydrique_carte`, la ligne « 6 bis » dit que la carte n'a pas
  été calculée.

## Value

Un `data.frame` : `etape`, `etat`, `dans_ce_run`, `detail`.

## Examples

``` r
evidence_table_real(list(offline = TRUE, ser_code = "D11", n_tiles = 1, n_ifn = 100,
                         gnss = FALSE, reference = FALSE))[, 1:2]
#>                                                             etape
#> 1                                            1. Emprise et grille
#> 2                                              2. LiDAR HD et MNT
#> 3                                           3. Dérivés du terrain
#> 4                                       4. Géologie (BD Charm-50)
#> 5                             5. Placettes IFN (lecture, filtres)
#> 6                                      6. Gradients des placettes
#> 7         6 bis. Carte hydrique (BILJOU, rayonnement de la pente)
#> 8                                      7. Points d'ancrage (GBIF)
#> 9                                                         8. Sols
#> 10                                9. Masque forestier (MHC > 5 m)
#> 11 10. Modèles, validation croisée spatiale, zone d'applicabilité
#> 12                 11. Typologie (seuils, fusion des types rares)
#> 13                                  12. Caractérisation des types
#> 14                               13. Clé de détermination terrain
#> 15       14. Validation statistique (validation croisée spatiale)
#> 16        15. Validation thématique par relevés GNSS indépendants
#> 17             16. Comparaison à la référence AgroParisTech (§ 9)
#> 18                                         17. Sorties et rapport
#>                            etat
#> 1                   réel réduit
#> 2                   réel réduit
#> 3                   réel réduit
#> 4                   réel réduit
#> 5                   réel réduit
#> 6                   réel réduit
#> 7                   non exécuté
#> 8                   non exécuté
#> 9                   non exécuté
#> 10                  non exécuté
#> 11                  réel réduit
#> 12                  réel réduit
#> 13                  réel réduit
#> 14                  non exécuté
#> 15                  réel réduit
#> 16 non atteint (entrée absente)
#> 17      sautée (entrée absente)
#> 18                  réel réduit
```
