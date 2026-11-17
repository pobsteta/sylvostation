# ADR 0005 — Version calendaire et release automatique

- **Date :** 2026-11-17
- **Statut :** acceptée par délégation (Claude, orchestrateur, pour Pascal) ; demande explicite de Pascal du 2026-11-17 : « comme marculus »
- **Proposée par :** mission 012 (agent `dev`)
- **Tranchée par :** Pascal, par délégation totale du 2026-11-16
- **Numéro :** la fiche 012 parlait d'« ADR 0003 », mais `0003` est déjà pris (données d'essai synthétiques) ; numéro suivant libre : 0005.

## La décision en une phrase

Chaque état fusionné dans `main` dont la CI est verte et dont le paquet a changé reçoit un tag
annoté `vAAAA.MM.N` (N = compteur du mois en UTC, sans zéro de remplissage) et une release
GitHub portant le tarball `R CMD build`.

## Contexte

Le projet a besoin que chaque état testé soit daté, identifiable et téléchargeable. Le dépôt
marculus a une mécanique éprouvée (scripts `version-calendaire.sh`, `release-necessaire.sh`,
workflows `ci.yml` et `release.yml`) ; on la reprend, adaptée à un paquet R (pas d'APK : la pièce
jointe est le tarball). Alternatives : SemVer à la main (demande un humain à chaque release) ;
release à chaque push (versions vides, bruit).

## Le mécanisme

- `ci.yml` : push sur `main` et PR ; tests des scripts shell, `R CMD check` (r-lib/actions,
  dépôt r-universe de r-lidar pour `lasR`, `_R_CHECK_FORCE_SUGGESTS_: false`). Sur push de
  `main` : couverture `covr` et badge SVG fabriqué localement (`badge-couverture.sh`), commité
  par la CI avec `[skip ci]`. Un échec de `covr` ou du commit du badge ne casse pas la CI.
- `release.yml` : `workflow_run` après une CI verte sur un push de `main`. Décide
  (`release-necessaire.sh`), calcule la version (`version-calendaire.sh`), pose le tag annoté sur
  le `head_sha`, réécrit `Version` de `DESCRIPTION` dans l'espace de travail, construit
  `sylvostation_AAAA.MM.N.tar.gz`, publie la release avec le changelog des commits depuis le tag
  précédent.
- Ne comptent pas pour une release : `pilotage/`, `docs/`, `*.md`, `.github/badges/`, `tests/`,
  `.github/scripts/test-*.sh`. En cas de doute, on publie.
- `DESCRIPTION` : `Version: AAAA.MM.0` en développement (valide pour R).

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | Scripts shell POSIX, aucun service externe (badge SVG local) | — | — |
| **R**esponsable | Qui fait quoi ? | La CI tag et publie ; Pascal ne fait rien à la main | Un bot écrit sur `main` (badge) | oui |
| **A**nticiper | Si l'imprévu arrive ? | CI relancée sur un ancien commit : pas de release (tête dépassée) ; covr en panne : CI verte | Le badge peut être « n/d » | oui |
| **N**ovateur | Toutes les idées ? | SemVer écarté : le projet n'a pas d'API publique stable | — | oui |
| **C**oût | Coût complet ? | Minutes de CI à chaque fusion | Quelques minutes | oui |
| **É**cologique | Réutilisation ? | Mécanique reprise de marculus ; format ouvert (tarball, SVG) | — | — |

## Valeurs sacrifiées

**Novateur** (pas de SemVer, donc pas de signal de rupture dans le numéro) au profit de
**Frugale**. La version ne dit pas la gravité du changement ; le changelog le fait.

## Points d'attention

- **`release.yml` (`workflow_run`) ne s'exécute que s'il est sur la branche par défaut** du
  dépôt. Tant qu'il n'est pas fusionné dans la branche par défaut, aucune release ne part. Le
  dépôt est `pobsteta/sylvostation` ; la branche cible est `main`.
- Le commit du badge pousse directement sur `main` : il échoue (sans casser la CI) si une
  protection de branche l'interdit. Le badge reste alors figé.
- Le tarball est construit avec `--no-build-vignettes` (Quarto et paquets Suggests absents du
  job de release) : les vignettes ne sont pas embarquées. Prix accepté, à revoir si besoin.
- Un 3e chiffre sur deux positions (`2026.01.1`) est valide pour R mais écrit tel quel dans le tag.

## Sources

Dépôt marculus (`.github/workflows/ci.yml`, `release.yml`, `.github/scripts/*.sh` sur `origin/main`) ;
fiche `pilotage/missions/012-release-versionnage.md`.
