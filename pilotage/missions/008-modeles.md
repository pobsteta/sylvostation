# Mission 008 — modèles de gradients et validation croisée spatiale

## Mission

**En une phrase (quoi, et pourquoi) :** coder `fit_gradient()`, `spatial_cv()` et `predict_raster()` (forêt aléatoire et GAM, validation par blocs, zone d'applicabilité), pour spatialiser chaque gradient avec une erreur honnête.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étape 5, § 6 (ranger, mgcv, blockCV, CAST) | |
| A-t-il les moyens ? | oui : données synthétiques à relation connue (`synth_gradients.gpkg` + raster de prédicteurs), ranger et mgcv installés ; blockCV/CAST si installés, sinon blocs maison documentés | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/modeles.R`, tests, `inst/extdata/`.
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `fit_gradient(data, response, predictors, method = c("ranger","gam"), weights = NULL, points_source)` : **appelle `assert_no_fine_extract_on_ifn()`** quand les points sont des placettes IFN et que des prédicteurs fins sont demandés.
- `spatial_cv(data, ..., block_size, k = 5)` : blocs spatiaux (jamais de tirage aléatoire simple) ; renvoie R², RMSE par pli et global.
- `predict_raster(model, predictors, aoa = TRUE)` : prédiction, écart-type (quantiles ranger ou se GAM), zone d'applicabilité (`CAST::aoa` si installé).
- Test : sur données synthétiques à relation connue, R² en CV par blocs > 0,5 ; la CV par blocs donne un R² ≤ CV aléatoire sur données autocorrélées.

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** k = 5 plis ; taille de bloc = portée de l'autocorrélation estimée, à défaut 5 km.
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 002 intégrée.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** la carte d'un gradient et sa carte d'incertitude sur le massif test (synthétique tant que 006/007 n'ont pas de données réelles).

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
