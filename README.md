# sylvostation

Package R et pipeline `targets` qui produisent, pour une sylvoécorégion (SER) donnée
par son seul code, un catalogue de stations forestières.

Voir `docs/brief.md` (ce qu'on construit), `docs/spec.md`, `docs/adr/`.

## Règles à retenir

- Coordonnées en Lambert-93 (EPSG:2154) partout, x = est, y = nord.
- Aucune variable fine (pente, TWI, LiDAR...) extraite aux placettes IFN
  (précision 700 m) : voir `assert_no_fine_extract_on_ifn()`.

## Usage : pipeline en mode démonstration

`config.yml` porte `demo: true` : le pipeline `targets` tourne **sans réseau** sur les jeux
d'essai de `inst/extdata` (fichiers `synth_*`, `synthetic = TRUE`). Depuis la racine du
dépôt, avec le paquet chargé (`devtools::load_all()`) :

    Rscript -e 'devtools::load_all(); targets::tar_make(callr_function = NULL)'

Les sorties vont sous `data/sorties/<ser_code>/` (ignoré par git) : GeoTIFF (COG), GeoPackage
des types, CSV et `rapport.html` (Quarto, tableau « état de preuve » et section « Limites »).
Tout y est **synthétique** et les critères d'acceptation du § 7 du brief restent « non
atteints ». Le mode réel (`demo: false`) n'est pas branché. Détails : `docs/pipeline.md`.

## Tests

    Rscript -e 'devtools::document(); devtools::test()'

Licence : GPL-3.
