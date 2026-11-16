# Mission 004 — géologie et recodage lithologique

## Mission

**En une phrase (quoi, et pourquoi) :** coder `list_formations()`, `recode_lithology()`, `rasterize_geol()` et `dominant_lithology()` et produire la table de recodage pré-remplie du massif test, pour disposer de 8 à 15 classes lithologiques sur la grille commune.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 3 (BD Charm-50), § 4 étape 1 ; `docs/referentiels.md` (URL, couches, champs BD Charm-50) | |
| A-t-il les moyens ? | oui : sf, terra ; réseau vers infoterre.brgm.fr ; extrait géologique réel ou, à défaut, synthétique marqué | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/geologie.R`, tests, `inst/extdata/` (extrait BD Charm-50 du massif test ≤ 2 Mo ou `synth_geol.gpkg`), `inst/extdata/lithologie_regles.csv` (mots-clés → classe), `inst/extdata/lithologie_massif_test.csv` (table pré-remplie, colonne `validated = FALSE`, colonne `statut` : `regle`/`non_classe`).
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `list_formations(geol)` : code, notation, description, surface dans l'emprise (champs vérifiés en 001).
- `recode_lithology(formations, rules)` : règles sur mots-clés (grès, granite, gneiss, calcaire, marne, argile, alluvions, colluvions, lœss, schiste, conglomérat, volcanique…) → classe ; formations sans règle : `non_classe`, **jamais affectées par défaut**, avec un avertissement qui les liste.
- `rasterize_geol(geol, grid, field)` ; `dominant_lithology(litho_rast, radius = 700)` : classe modale dans un disque de 700 m (pour le croisement avec les placettes IFN).
- Contrôle des raccords : `check_geol_joins(geol)` signale les unités qui changent à une limite de département ou de feuille (si le champ existe).

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** table de recodage et liste de classes : **provisoires, validées par délégation** (`validated = FALSE` jusqu'à relecture de Pascal) ; rayon 700 m (brief).
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 001 et 002 intégrées.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** la table `lithologie_massif_test.csv` et la carte rasterisée.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
