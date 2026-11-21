# Tableau « état de preuve » du pipeline démo

Pour chaque étape du brief technique : ce qui a tourné sur données
`réel`, `réel réduit` (extrait réel de `inst/extdata`) ou `synthétique`
(jeu fabriqué, préfixe `synth_`), ou n'a pas tourné (`non exécuté`).
Spécification : `docs/spec.md` (objection B1 de la mission 000). Les
critères du § 7 du brief restent « non atteints » tant qu'ils n'ont pas
tourné sur données réelles.

## Usage

``` r
evidence_table(n_ifn = NA_integer_, resolution_m = NA_real_)
```

## Arguments

- n_ifn:

  Nombre de placettes IFN lues (pour le détail ; `NA` si inconnu).

- resolution_m:

  Résolution de la grille (m), `resolution_m` de `config.yml` ; `NA` si
  inconnue (le texte dit alors « grille de sortie »).

## Value

Un `data.frame` : `etape`, `etat`, `dans_ce_run` (`oui` si l'étape a
tourné dans le pipeline démo, `non` sinon : une ligne réelle non
exécutée ici reste réelle mais hors de ce run), `detail`.

## Examples

``` r
evidence_table()
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
#>    dans_ce_run
#> 1          oui
#> 2          non
#> 3          oui
#> 4          oui
#> 5          oui
#> 6          oui
#> 7          oui
#> 8          non
#> 9          oui
#> 10         oui
#> 11         oui
#> 12         oui
#> 13         oui
#> 14         oui
#> 15         oui
#>                                                                                                                                detail
#> 1              Contour SER simplifié (ser_extrait.gpkg) ; grille de la résolution configurée calculée sur l'emprise de démonstration.
#> 2          4 dalles réelles traitées lors de la mission 003, hors pipeline démo ; la démo utilise un MNT synthétique (synth_dtm.tif).
#> 3                           Calculés sur le MNT synthétique ; MRVBF et hauteur au réseau non calculés (WhiteboxTools/TOPAGE absents).
#> 4                                               Extrait BD Charm-50 de l'emprise test ; recodage lithologique provisoire, non validé.
#> 5                                                                                  placettes IFN de inst/extdata (localisées à 700 m)
#> 6                                       Valeurs indicatrices et climat synthétiques sur des placettes réelles : résultat synthétique.
#> 7  Points fabriqués ; fonctions d'ancrage intégrées au paquet (mission 007), non branchées au pipeline démo ; aucun relevé GNSS réel.
#> 8                                                                                                Couches de sols absentes de la démo.
#> 9                                    Ajustés sur les points synthétiques ; le modèle régional IFN utilise des gradients synthétiques.
#> 10                                                                     Seuils provisoires par quantiles, non validés par un écologue.
#> 11                                                                                                         Flore et arbres fabriqués.
#> 12                                                                                                             Observables fabriqués.
#> 13                                                           Validation croisée et « terrain » synthétiques ; aucun relevé GNSS réel.
#> 14                                                   Référence synthétique (synth_reference.tif) ; rasters AgroParisTech non obtenus.
#> 15                                                                                                          Fichiers préfixés synth_.
```
