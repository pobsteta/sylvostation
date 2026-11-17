# Mission 012 — release, tags, version calendaire, badges

## Mission

**En une phrase (quoi, et pourquoi) :** doter le dépôt d'une CI de tests, d'une release
automatique à version calendaire `vAAAA.MM.N` (comme marculus) déclenchée par une CI verte
sur `main`, et de badges dans le README, pour que chaque état fusionné soit testé, daté,
identifiable et téléchargeable (demande de Pascal du 2026-11-17).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : modèle éprouvé dans `~/dev/marculus` (`.github/workflows/ci.yml`, `release.yml`, `.github/scripts/*.sh` sur `origin/main`), r-lib/actions | |
| Les moyens ? | oui : shell, R, gh en lecture | |

**Temps de la main :** appuyer.

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) ; demande explicite de Pascal du 2026-11-17 : « comme marculus »._

## L'Homme

- **Agent :** `dev`
- **Ce qui ne lui est pas demandé :** pousser, créer des tags, toucher au code métier de `R/`.

## Harnais

- **Peut :** `.github/**`, `README.md`, `DESCRIPTION` (champ Version), `NEWS.md`, `.Rbuildignore`, `tests/` des scripts shell, `docs/adr/0003-*.md`.
- **Ne doit pas :** modifier `R/`, `inst/extdata`, le journal, le kanban ; pousser.

## Attendus

1. **Version calendaire** `vAAAA.MM.N` (N = compteur du mois en UTC, qui repart à 1) : reprendre `version-calendaire.sh` et `release-necessaire.sh` de marculus (version `origin/main`) dans `.github/scripts/`, adaptés à R. Les fichiers qui ne comptent pas pour une release : `pilotage/`, `docs/`, `*.md`, `.github/badges/`, `tests/`, `.github/scripts/test-*.sh`. Ajouter les deux scripts de test shell.
2. **CI** (`.github/workflows/ci.yml`, qui remplace `R-CMD-check.yaml`) : se déclenche sur un push de `main` et sur les PR. Elle lance `R CMD check` (r-lib/actions, dépôt r-lidar r-universe pour lasR) et les tests shell des scripts. Sur un push de `main` : couverture `covr` et badge SVG de couverture commité dans `.github/badges/` par la CI (`[skip ci]`), sans service externe.
3. **Release** (`.github/workflows/release.yml`) : `workflow_run` après une CI verte sur un push de `main`. La version est calculée par le script, et la release n'est créée que si elle est nécessaire. Le tag annoté est posé sur le `head_sha`. La release GitHub joint le tarball `R CMD build` (`sylvostation_AAAA.MM.N.tar.gz`), dont la `Version` de DESCRIPTION a été réécrite à la volée. Le changelog vient des commits depuis le tag précédent.
4. **DESCRIPTION** : `Version` au format calendaire valide pour R (par ex. `2026.11.0`, valeur de développement), avec la convention documentée.
5. **README** : badges CI, Release, Version (shields `github/v/release`), Couverture, R, Licence GPL-3, et une section « Versions et releases ».
6. **ADR 0003** (crible FRANCE) : version calendaire et release automatique.

## Valeur provisoire

N sans zéros de remplissage (`v2026.11.1`), comme marculus.

## Tests

Les scripts de test shell passent en local ; `devtools::test()` reste vert ; YAML valide.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur par délégation.
