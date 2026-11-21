# Mission 029 — plan d'échantillonnage des relevés floristiques GNSS

## Mission

**En une phrase (quoi, et pourquoi) :** produire, à partir des couches fines de la grille,
un plan de 40 à 60 relevés floristiques localisés au GNSS qui couvre les gradients locaux
dans les forêts accessibles de l'emprise test, avec fiche, protocole et format de saisie
relu par le pipeline, pour fournir les ancrages locaux et la validation indépendante qui
manquent (demande de Pascal du 2026-11-18).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : hypercube latin conditionné (paquet `clhs`, Roudier ; Minasny & McBratney 2006, DOI 10.1016/j.cageo.2005.12.009) avec coût d'accès ; accessibilité par la distance aux tronçons de la BD TOPO (WFS de la Géoplateforme, couche à vérifier dans `docs/referentiels.md`) ; format attendu de `gnss_path` (`R/pipeline_reel.R`, `real_sources`) | plan d'abord |
| Les moyens ? | code et tests : oui (jeux synthétiques) ; application : après 027 (MRVBF) et le run des 225 dalles | le plan réel est tiré après |

**Temps de la main :** donner — plan d'abord. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : « prépare le plan d'échantillonnage mais continue sans avec le point 3 »._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (justesse du plan)

## Harnais

- **Peut (périmètre) :** `R/echantillonnage.R` (nouveau), ses tests, `inst/terrain/` (fiche de relevé, protocole d'une page, gabarit de saisie CSV), `DESCRIPTION` (Suggests : `clhs`), `docs/referentiels.md` (§ BD TOPO tronçons, § clhs), `docs/echantillonnage.md`.
- **Câblé :** EPSG:2154 ; points tirés dans les cellules forestières ; variables fines seulement sur la grille, jamais aux placettes IFN ; le gabarit de saisie porte `loc_precision_m` (précision GNSS déclarée, ≤ 25 m exigé à l'usage) et produit des relevés lisibles par le pipeline (`gnss_path`).
- **Ne doit pas :** toucher à `R/terrain.R`, `R/hydro.R` (027), `R/hydrique.R` (028), `_targets.R` ; télécharger dans les tests.

## Attendus

1. `sampling_plan(grid_layers, forest, access, n = 50, cost_max_m = 300, seed)` : hypercube latin conditionné sur les couches fines (k_sv, is_topo, mrvbf, hauteur_reseau, pente, altitude, géologie), coût = distance à un tronçon accessible ; points de remplacement (2 par point) dans la même strate ; sorties GeoPackage et GPX (EPSG:2154 et WGS84 pour le GPX).
2. Diagnostic de couverture : distribution des variables dans l'échantillon contre l'emprise forestière (test de Kolmogorov-Smirnov ou quantiles), carte.
3. Fiche de relevé (placette de 400 m², liste complète des espèces vasculaires avec recouvrement, strates, humus, sol à la tarière si possible, photo, précision GNSS), protocole d'une page, gabarit CSV ; lecture par le pipeline testée.
4. Durée de terrain estimée (relevé + déplacement).
5. Script d'application `inst/scripts/plan_gnss.R` à lancer sur les sorties du run des 225 dalles.

## Dépend de / rouge attendu jusqu'à

- Le code peut partir maintenant ; le tirage réel attend 027 et le run des 225 dalles.

## Tests

Un test par fonction, sans réseau ; un point connu tombe dans la bonne cellule en Lambert-93 ; reproductibilité par `seed`.

## Terrain

Pascal relit la fiche et le protocole avant toute sortie.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
