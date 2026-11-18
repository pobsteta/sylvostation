# Mission 023 — site pkgdown et page de résultats sur le massif test vosgien

## Mission

**En une phrase (quoi, et pourquoi) :** créer le site pkgdown du paquet, publié par GitHub
Pages, avec un article qui présente le résultat du pipeline réel sur une partie des Vosges
(emprise test de la SER D11, mission 018) : données d'entrée, calculs, cartes et limites,
pour que le résultat soit consultable sans installer R (demande de Pascal du 2026-11-18).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : pkgdown (`usethis::use_pkgdown_github_pages()`, workflow r-lib/actions `pkgdown.yaml`) ; vignette existante `vignettes/massif-test.Rmd` (mode démo) | |
| Les moyens ? | après 018 (sorties réelles sous `data/sorties/D11/`) et 022 (rapport PDF, même périmètre `DESCRIPTION`) | attend 018 et 022 |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : « ajoute une page pkgdown qui présente le résultat sur une partie des vosges »._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `_pkgdown.yml`, `.github/workflows/pkgdown.yaml`, `vignettes/articles/` (article non construit au `R CMD check`), `vignettes/articles/figures/` (images et petites tables précalculées issues de 018), `README.md` (lien et badge du site), `DESCRIPTION` (`URL`, `Suggests: pkgdown`), `.Rbuildignore`, `docs/pipeline.md`.
- **Câblé :** l'article ne lance aucun calcul ni téléchargement en CI : il lit des figures et tables précalculées, produites par un script versionné (`inst/scripts/` ou `vignettes/articles/`) depuis les sorties de 018 ; chaque figure dit sa source, sa date de run et son emprise ; licences : seules des données dérivées de sources ouvertes (LiDAR HD, IFN, SAFRAN, TOPAGE, BRGM sous Licence Ouverte ; GBIF avec DOI) ; aucune donnée AgroParisTech ; le site se déploie seulement depuis `main`.
- **Ne doit pas :** présenter un chiffre synthétique comme réel ; versionner les rasters complets (images réduites seulement, < 2 Mo au total) ; pousser.

## Attendus

1. Site pkgdown : référence des fonctions groupée par étape, la vignette `massif-test` (démo), l'article « Résultats sur le massif test vosgien (D11) ».
2. Article : emprise (carte de situation, EPSG:2154), données d'entrée (tableau), chaîne de calcul (schéma), cartes des types, du gradient hydrique 25 m et d'incertitude, état de preuve chiffré, limites, lien vers le rapport PDF (022) s'il est joint à la release.
3. Workflow `pkgdown.yaml` : construction sur PR (sans déploiement) et déploiement sur `gh-pages` après push sur `main`.
4. Construction locale `pkgdown::build_site()` sans erreur ; taille des images contrôlée.

## Valeur provisoire (chiffre, réglage)

Aucune.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 018 (sorties réelles) et 022 (fusionnée d'abord, `DESCRIPTION`).

## Tests

`pkgdown::check_pkgdown()` et `build_site()` sans erreur ; `.claude/test-command` vert ; `R CMD check` sans nouvel avertissement.

## Terrain

Pascal ouvre la page et juge si elle se lit sans aide.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur. L'activation de GitHub Pages dans les réglages du dépôt revient à Pascal si elle est nécessaire.
