# Mission 010 — validation, comparaison à la référence, sorties et pipeline

## Mission

**En une phrase (quoi, et pourquoi) :** coder `validate_stats()`, `validate_maps()`, `load_reference()`, `recode_3digits()`, `compare_gradients()`, `write_outputs()`, le pipeline `_targets.R`, le gabarit de rapport Quarto et la vignette, pour que le catalogue s'exécute de bout en bout sur les jeux d'essai.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étapes 9-10, § 9 ; fonctions des missions 003 à 009 | |
| A-t-il les moyens ? | oui : targets installé (sinon pipeline écrit et testé par `targets::tar_validate()` quand il le sera) ; rasters de référence AgroParisTech absents → `synth_reference.tif` marqué | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/validation.R`, `R/reference.R`, `R/sorties.R`, `_targets.R`, `inst/rapport/rapport.qmd`, `vignettes/massif-test.Rmd`, tests, `README.md` (section usage).
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `validate_stats(cv_results)` : R², RMSE par gradient, comparés aux repères du brief (0,36 / 0,52 / 0,43).
- `validate_maps(pred_types, field_types)` : matrice de confusion, kappa, accord exact et à une classe près.
- `load_reference(path)`, `recode_3digits(types, thresholds_ref)`, `compare_gradients(ours, ref, res = 50)` : protocole § 9 (corrélation de rang, carte des écarts).
- `write_outputs(...)` : GeoTIFF (COG si GDAL le permet), GeoPackage, CSV dans `out_dir/<ser_code>/`.
- `_targets.R` : lit `config.yml`, enchaîne les étapes ; mode `demo: true` qui utilise `inst/extdata` (synthétique) et tourne sans réseau.
- Rapport Quarto : gradients, types, fiches, validation, **limites explicites** (§ 7).

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** aucune nouvelle (reprend celles de 002 à 009).
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 003 à 009 intégrées.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** le rapport HTML produit en mode démo, avec ses limites.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
