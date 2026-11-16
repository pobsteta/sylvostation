# Mission 002 — squelette du package et règle bloquante

## Mission

**En une phrase (quoi, et pourquoi) :** créer le squelette du package R `sylvostation`
(DESCRIPTION, LICENSE GPL-3, config, utilitaires, tests, CI) avec l'assertion qui
interdit les extractions fines sur les placettes IFN, pour que toutes les missions
suivantes partent d'une base qui passe `R CMD check`.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 6, ADR 0001, `CLAUDE.md` | |
| Les moyens ? | oui : R 4.3.3, devtools, roxygen2, testthat installés | |

**Temps de la main :** appuyer.

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16)._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** coder les étapes de l'algorithme.

## Harnais

- **Peut :** créer `DESCRIPTION`, `NAMESPACE` (roxygen), `LICENSE`/`LICENSE.md` (GPL-3),
  `R/config.R`, `R/utils.R`, `R/sylvostation-package.R`, `tests/testthat.R`,
  `tests/testthat/test-utils.R`, `test-config.R`, `config.yml`, `.Rbuildignore`,
  `.gitignore`, `README.md`, `.github/workflows/R-CMD-check.yaml`, `_targets.R` (squelette
  vide qui charge la config), `inst/extdata/.gitkeep`.
- **Ne doit pas :** toucher à `docs/`, `pilotage/`, `.claude/`, `CLAUDE.md` ; ajouter une
  dépendance non citée dans l'ADR 0001.
- **Sources autorisées :** `docs/brief-technique.md` (consignes, § 6), `docs/spec.md`,
  `docs/adr/0001*`, `CLAUDE.md`.

## Contenu attendu

- `DESCRIPTION` : `Imports` légers (`sf`, `terra`, `yaml`, `stats`, `utils`) ;
  `Suggests` : `testthat (>= 3.0.0)`, `targets`, `lidR`, `lasR`, `rgbif`, `happign`,
  `ranger`, `mgcv`, `rpart`, `vegan`, `ade4`, `indicspecies`, `cluster`, `blockCV`,
  `CAST`, `whitebox`, `quarto` ; `Additional_repositories: https://r-lidar.r-universe.dev`
  (pour `lasR`) ; `Config/testthat/edition: 3` ; `Language: fr`.
- `config.yml` (paquet `yaml`, pas `config`) : `ser_code: "D11"` **à vérifier (mission 001)**,
  `emprise_test` (xmin 1007000, ymin 6790000, xmax 1022000, ymax 6805000, EPSG:2154),
  `buffer_m: 5000`, `resolution_m: 25`, `crs: 2154`, dossiers `data_dir: data`,
  `laz_dir`, `out_dir`, `ifn_precision_m: 700`.
- `read_config(path)` : lit et valide (types, CRS = 2154, emprise cohérente).
- `assert_crs_2154(x)` : erreur si `sf`/`SpatRaster` n'est pas en EPSG:2154.
- `assert_no_fine_extract_on_ifn(points, variables)` : erreur explicite si `points` est
  marqué comme placettes IFN (attribut `attr(x, "source") == "ifn"` ou colonne `source`
  valant `"ifn"`) et que `variables` contient une variable fine. La liste des variables
  fines est une constante exportée `FINE_VARIABLES` (pente, exposition, courbures, TPI,
  TWI, MRVBF, hauteur au-dessus du réseau, rayonnement, métriques LiDAR, MNT/MHC) ; une
  variable est « large » si elle porte le préfixe `coarse_` ou figure dans `COARSE_VARIABLES`.
  Ajouter `mark_ifn(x)` qui pose le marquage.
- Tests : la règle bloquante bloque (et laisse passer les variables larges) ; CRS ;
  config invalide refusée.
- CI GitHub Actions : `r-lib/actions/setup-r@v2` + `check-r-package@v2`.
- Documentation roxygen2 en français ; `devtools::document()` lancé.

## Valeur provisoire (chiffre, réglage)

- `resolution_m: 25` et `buffer_m: 5000` : provisoires (brief : 10–25 m, 5–10 km),
  choisis par délégation (prudence calcul) ; gel avant la phase 1.

## Dépend de / rouge attendu jusqu'à

Aucune. `ser_code` reste « à vérifier » jusqu'à la mission 001.

## Tests

`Rscript -e 'devtools::test()'` vert ; `R CMD check --no-manual` sans erreur ni warning
(notes admises, à lister).

## Terrain

Pascal lira `config.yml` et le message d'erreur de la règle bloquante.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

`R CMD check` passe ; le test de la règle bloquante échoue si on la retire.
