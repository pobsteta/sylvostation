# sylvostation

Package R et pipeline `targets` qui produisent, pour une sylvoécorégion (SER) donnée
par son seul code, un catalogue de stations forestières.

Voir `docs/brief.md` (ce qu'on construit), `docs/spec.md`, `docs/adr/`.

## Règles à retenir

- Coordonnées en Lambert-93 (EPSG:2154) partout, x = est, y = nord.
- Aucune variable fine (pente, TWI, LiDAR...) extraite aux placettes IFN
  (précision 700 m) : voir `assert_no_fine_extract_on_ifn()`.

## Tests

    Rscript -e 'devtools::document(); devtools::test()'

Licence : GPL-3.
