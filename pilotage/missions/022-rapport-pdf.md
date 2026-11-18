# Mission 022 — rapport PDF : données d'entrée, calculs, carte produite

## Mission

**En une phrase (quoi, et pourquoi) :** produire, en plus du rapport HTML, un rapport PDF
qui présente les données d'entrée (sources, versions, licences, volumes), les calculs
réalisés (chaîne de traitement, méthodes, valeurs provisoires) et les cartes produites
(types de stations, gradient hydrique à 25 m, incertitude), pour que Pascal et les
gestionnaires disposent d'un document imprimable et diffusable (demande de Pascal du
2026-11-18).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : gabarit existant `inst/rapport/rapport.qmd` (lit seulement les fichiers de `write_outputs()`), cible `rapport` de `_targets.R` ; Quarto 1.8.27 et LaTeX (xelatex) présents sur la machine | |
| Les moyens ? | oui : run hors ligne du mode réel et mode démo, sans réseau | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : « peux-tu faire un pdf en sortie qui présente les données d'entrée, les calculs réalisés et la carte produite ? »_

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet (mise en forme, pas d'architecture)

## Harnais

- **Peut (périmètre) :** `inst/rapport/` (gabarit, éventuel gabarit PDF séparé, styles), la cible `rapport` de `_targets.R`, `R/sorties.R` seulement si une table d'entrée manque aux sorties (ajout, sans changer l'existant), tests du rapport, `docs/pipeline.md`, `DESCRIPTION` (Suggests si besoin).
- **Câblé :** le rapport ne lit que les fichiers écrits ; aucun calcul nouveau dans le rapport ; préfixe `synth_` et mention « données synthétiques » en tête en mode démo ; EPSG:2154 dans les cartes (échelle, nord, légende) ; pas de push.
- **Ne doit pas :** inventer une source ou un chiffre ; toucher aux calculs (`R/hydrique.R`, `R/terrain.R`…) ; rendre le PDF obligatoire (si LaTeX ou Quarto manquent : HTML seul, signalé).

## Attendus

1. `rapport.pdf` écrit à côté de `rapport.html` par la cible `rapport` (format PDF Quarto, moteur xelatex ou typst si plus simple et disponible).
2. **Données d'entrée** : tableau des sources (nom, version, date, licence, URL ou DOI, volume utilisé : dalles LiDAR, placettes IFN, mailles SAFRAN, GBIF, TOPAGE, géologie, TAXREF, Tichý), état réel / synthétique / absent de chacune, pris dans l'état de preuve et `SOURCES.md` / `docs/referentiels.md`.
3. **Calculs réalisés** : la chaîne en étapes numérotées (LiDAR → MNT/MHC → terrain 25 m → gradients → typologie → modèle → carte → clé), pour chacune la méthode, la référence, les valeurs provisoires et la règle des 700 m ; un schéma de la chaîne.
4. **Cartes produites** : carte des types, carte du gradient hydrique 25 m (`hydrique_25m.tif` : `is_topo`, `k_sv`), carte d'incertitude, avec légende, échelle, flèche du nord, système de coordonnées ; limites de la carte dites à côté.
5. Le reste du rapport HTML (état de preuve, types, fiches, clé, validation, limites, reproductibilité) repris dans le PDF.
6. Rendu vérifié sur le mode démo et sur un run hors ligne du mode réel ; le PDF ouvert et ses pages contrôlées (nombre de pages, figures présentes).

## Valeur provisoire (chiffre, réglage)

Aucune.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 021 (intégrée).

## Tests

Un test qui rend le PDF sur le mode démo quand Quarto et LaTeX sont présents (sauté sinon, motif dit), un test du repli HTML seul ; `.claude/test-command` vert.

## Terrain

Pascal lit le PDF du run hors ligne et dit si un gestionnaire le comprend sans aide.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
