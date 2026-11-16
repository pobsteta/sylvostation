# Mission 006 — placettes IFN, gradients par placette et couches de sols

## Mission

**En une phrase (quoi, et pourquoi) :** coder `load_ifn()`, `filter_releves()`, `compute_gradients()` et `stack_soil_layers()`, pour calculer les gradients trophique, hydrique et bioclimatique par placette en ne croisant que des prédicteurs à maille large.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 3, § 4 étape 3 ; colonnes IFN et accès Baseflor dans `docs/referentiels.md` | |
| A-t-il les moyens ? | oui : extrait réel IFN (≤ 100 placettes, si 001 l'a obtenu) sinon `synth_ifn_*.csv` marqué ; valeurs indicatrices réelles si accessibles sinon `synth_indicateurs.csv` | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/placettes.R`, `R/sols.R`, tests, `inst/extdata/`.
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `load_ifn(dir, files = c("PLACETTE","ECOLOGIE","FLORE","ARBRE"))` : lecture (séparateur et colonnes vérifiés en 001), jointure par identifiant de placette, `sf` en EPSG:2154, **`mark_ifn()` systématique**.
- `filter_releves(ifn, min_occ = 3, months = 4:9)` : flore en saison, espèces dans ≥ 3 relevés, exclusion des perturbations récentes (colonne vérifiée ou « à vérifier »).
- `compute_gradients(ifn, indicateurs, climat = NULL)` : trophique = moyenne des valeurs indicatrices (pH/richesse) des espèces présentes, à défaut axe 1 d'AFC (`ade4::dudi.coa`) ; hydrique = réserve utile par pédotransfert (fonction citée, ex. Jamagne et al. 1977 ou Baize 1988 : **source à donner, sinon « à vérifier »**) + engorgement ; bioclimat = P − ETP saison de végétation et T moyenne si un raster climat est fourni (extraction autorisée : maille kilométrique).
- `stack_soil_layers(paths, grid)` : empile les couches de sols disponibles (GlobalSoilMap, pH SILVAE…) sur la grille ; préfixe `coarse_` pour celles de maille ≥ 90 m.

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** mois de relevé valides 4 à 9 ; seuil de 3 relevés (brief) ; fonction de pédotransfert.
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 001 et 002 intégrées.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** les gradients calculés sur 10 placettes, à comparer à la description de terrain.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.

## Compléments (mission 000, I5)

- Jointure des noms d'espèces (IFN, Baseflor, GBIF) par TAXREF `CD_NOM` → `CD_REF`, version de TAXREF dans `config.yml` ; `unmatched_taxa()` renvoie les noms non appariés (publiés dans le rapport).
- Toute table de points porte `loc_precision_m` ; `load_ifn()` appelle `mark_ifn()`.
