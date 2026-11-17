# sylvostation

[![CI](https://github.com/pobsteta/sylvostation/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/pobsteta/sylvostation/actions/workflows/ci.yml)
[![Release](https://github.com/pobsteta/sylvostation/actions/workflows/release.yml/badge.svg)](https://github.com/pobsteta/sylvostation/actions/workflows/release.yml)
[![Version](https://img.shields.io/github/v/release/pobsteta/sylvostation?label=version)](https://github.com/pobsteta/sylvostation/releases/latest)
[![Couverture](.github/badges/couverture.svg)](https://github.com/pobsteta/sylvostation/actions/workflows/ci.yml)
[![R](https://img.shields.io/badge/R-%E2%89%A5%204.1-276DC3)](https://www.r-project.org/)
[![Licence : GPL-3](https://img.shields.io/badge/licence-GPL--3-blue)](LICENSE.md)

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

## Versions et releases

Chaque fusion dans `main` est testée par la CI (`R CMD check`, tests des scripts shell). Si la
CI est verte et que le paquet a changé, une release est publiée automatiquement, avec une
**version calendaire** `vAAAA.MM.N` : `AAAA.MM` = année et mois (UTC), `N` = compteur du mois,
sans zéro de remplissage, qui repart à 1 chaque mois (`v2026.11.1`, `v2026.11.2`, puis
`v2026.12.1`). Le tag annoté est posé sur le commit testé ; la release joint le tarball
`sylvostation_AAAA.MM.N.tar.gz` (`R CMD build`) et le changelog des commits depuis le tag
précédent. Rien ne part si seuls `pilotage/`, `docs/`, les `*.md`, le badge ou `tests/` ont
changé. Dans le dépôt, `DESCRIPTION` porte `Version: AAAA.MM.0` (valeur de développement) ; la
version publiée est réécrite à la construction du tarball. Installer une version :

    remotes::install_github("pobsteta/sylvostation@v2026.11.1")

Décision : `docs/adr/0005-version-calendaire-release-automatique.md`.

Licence : GPL-3.
