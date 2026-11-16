# Mission 007 — points d'ancrage GBIF et GNSS

## Mission

**En une phrase (quoi, et pourquoi) :** coder `get_gbif()`, `clean_occ()`, `grid_bioindication()` et `load_gnss()` et mesurer sur le massif test le nombre de mailles d'ancrage exploitables, pour savoir si GBIF suffit (brief technique, § 4 étape 4).

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étape 4, § 5 (esquisse rgbif) ; clé Tracheophyta et API dans `docs/referentiels.md` | |
| A-t-il les moyens ? | non pour `occ_download()` (pas de compte GBIF) → `get_gbif()` codé et testé sans réseau ; comptage réel par l'API publique `occurrence/search` (sans compte, plafonné), écrit au journal ; jeux synthétiques marqués pour les tests | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/ancrage.R`, tests, `inst/extdata/synth_occ.csv`, `inst/extdata/synth_gnss.csv`, `docs/ancrage-massif-test.md` (comptages réels).
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `get_gbif(emprise, user, pwd, email, ...)` : `occ_download()` avec les prédicats du brief (clé vérifiée en 001), DOI conservé ; erreur claire sans identifiants. Option `method = "search"` pour un aperçu (≤ 100 000, documenté comme non exhaustif).
- `clean_occ(occ, max_uncertainty = 25, exclude_datasets = <jeux IFN>)` : reprojette en 2154 dès l'import, écarte les relevés IFN dans GBIF (identifiant de jeu vérifié en 001 ou « à vérifier »), garde les points en forêt (BD Forêt et MHC > 5 m si fournis).
- `grid_bioindication(occ, indicateurs, cell = 50, min_species = 5)` : mailles de 50 m, valeurs bioindiquées, poids = nombre d'espèces.
- `load_gnss(path)` : relevés GNSS (format CSV documenté, EPSG:2154 ou 4326 converti).

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** maille 50 m (borne basse du brief, plus fine) ; 5 espèces indicatrices par maille (brief).
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 001 et 002 intégrées ; 006 pour les valeurs indicatrices (format partagé : `synth_indicateurs.csv`).
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** la carte des mailles exploitables du massif test.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
