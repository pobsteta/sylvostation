# Mission 009 — typologie, caractérisation des types et clé terrain

## Mission

**En une phrase (quoi, et pourquoi) :** coder `discretise()`, `merge_rare()`, `cluster_check()`, `indicator_species()`, `fertility_by_type()` et `build_key()`, pour passer des trois gradients aux types, à leurs fiches et à une clé terrain de 4 à 5 niveaux.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étapes 6 à 8, § 7 | |
| A-t-il les moyens ? | oui : rasters et placettes synthétiques ; vegan, cluster, rpart installés ; indicspecies si installé | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/typologie.R`, `R/caracterisation.R`, `R/cle.R`, tests.
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `discretise(gradients, thresholds)` : seuils par gradient ; `default_thresholds()` renvoie des seuils **provisoires** (quantiles) marqués comme tels.
- `merge_rare(types, area_min = 0.01, n_min = 15, gradients)` : fusion avec la combinaison voisine la plus proche (distance dans l'espace des classes), traçabilité des fusions.
- `cluster_check(gradients, k = 2:20)` : PAM + silhouette ; comparaison (indice de Rand ajusté ou kappa) avec la typologie par seuils.
- `indicator_species(flore, types)` : IndVal (`indicspecies::multipatt`, sinon calcul direct documenté).
- `fertility_by_type(arbres, types)` : hauteur dominante à âge de référence, par essence et par type (placettes IFN : hauteurs et âges mesurés).
- `build_key(data, observables, maxdepth = 5)` : CART (`rpart`), taux de bon classement publié ; si < 70 %, liste des types confondus à fusionner (`merge_suggestions`).

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** seuils par quantiles (4 trophiques, 3 hydriques, nombre bioclimatique selon amplitude) ; 1 % / 15 placettes (brief) ; profondeur 5.
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 002 intégrée.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** la clé imprimée (texte) et la table des types.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
