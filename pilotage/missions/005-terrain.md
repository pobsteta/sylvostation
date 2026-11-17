# Mission 005 — variables dérivées du MNT

## Mission

**En une phrase (quoi, et pourquoi) :** coder `aggregate_dtm()` et `derive_terrain()` (pente, exposition en cos/sin, courbures, TPI 100/300/1000 m, TWI, surface drainée, MRVBF, hauteur au-dessus du réseau, rayonnement potentiel), pour fournir les prédicteurs fins de l'étape 5.

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étape 2 ; `terra` (terrain, focal), `whitebox` si installé | |
| A-t-il les moyens ? | oui : un MNT d'essai (réel réduit de 003 ou synthétique `synth_dtm.tif` : surface analytique connue, pour tester pente et exposition par valeurs exactes) | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/terrain.R`, tests, `inst/extdata/synth_dtm.tif` (≤ 1 Mo).
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `aggregate_dtm(dtm, res = c(5, 25))` : agrégation par moyenne (brief : indices sur 5 et 25 m, pas sur 1 m).
- `derive_terrain(dtm, tpi_radii = c(100, 300, 1000), streams = NULL)` → `SpatRaster` multicouche nommé (noms = constantes de `FINE_VARIABLES`).
- Pente, exposition, courbures : `terra` ; TPI : `focal` sur disque ; TWI, surface drainée, MRVBF : `whitebox` si installé, sinon TWI par `terra` (flowdir/flowAccumulation, si disponibles dans la version installée : **à vérifier**) et MRVBF marqué non calculé ; hauteur au-dessus du réseau : distance verticale au réseau BD TOPAGE fourni ; rayonnement : modèle simple documenté (source citée) ou `whitebox`.
- Tests sur la surface analytique : pente d'un plan incliné de 10 % ≈ 5,71° ; exposition d'un plan orienté sud ≈ 180° ; TPI nul sur un plan.

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** rayons TPI 100/300/1000 m (brief) ; résolutions 5 et 25 m (brief).
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 002 intégrée ; 003 facultative (MNT réel).
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** la carte de pente et de TPI d'une dalle réelle du massif test (si 003 a tourné).

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.
