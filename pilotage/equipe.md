# Équipe de sylvostation

> Produit par l'orchestrateur avec `/imperatrice:mission`. Règle de staffing : un agent
> par mission qui passe les trois questions, jamais un agent « par principe ».

- **Statut :** validée par délégation
- **Validée par :** Claude (orchestrateur), par délégation totale de Pascal, 2026-11-16

## Plafond humain

- **Missions en relecture en même temps, au plus :** 3
- **Rythme de relecture de Pascal :** une fois, à la fusion de la PR brouillon (ADR 0002)
- **Relecture :** le `relecteur` relit chaque mission avant intégration ; critère d'arrêt
  3 allers-retours, au-delà l'orchestrateur tranche par délégation et l'écrit au journal.

## Le vivier (catalogue, pas une équipe)

| Agent | A / plan | Modèle | Écrit du code ? |
|---|---|---|---|
| `contradicteur` | Abstraction · Polos | opus | non |
| `acquereur` | Acquisition · Ponos | sonnet | non (référentiels et données) |
| `archiviste` | Archivage · Pontos | sonnet | non (docs) |
| `analyste` | Analyse · Ponos | sonnet | non |
| `afficheur` | Affichage · Ponos | sonnet | oui (interface) |
| `dev` | réalisation · Ponos | sonnet | oui |
| `testeur` | réalisation · Ponos | sonnet | oui (tests) |
| `relecteur` | contrôle · C3 | opus | non (lecture seule) |

## Missions

| Mission | Agent | Modèle | Temps de la main | Les 3 questions | Cycle |
|---|---|---|---|---|---|
| [000 critique du brief et des ADR](missions/000-critique-brief.md) | `contradicteur` | opus | appuyer | oui · oui · oui | 1 |
| [001 référentiels de données](missions/001-referentiels.md) | `acquereur` | opus | appuyer | oui · oui · oui (réseau ouvert) | 1 |
| [002 squelette du package](missions/002-squelette.md) | `dev` | sonnet | appuyer | oui · oui · oui | 1 |
| [003 emprise et LiDAR HD](missions/003-emprise-lidar.md) | `dev` | sonnet | appuyer | oui · oui après 001 · oui | 2 |
| [004 géologie](missions/004-geologie.md) | `dev` | sonnet | appuyer | oui · oui après 001 · oui | 2 |
| [005 terrain](missions/005-terrain.md) | `dev` | sonnet | appuyer | oui · oui · oui | 2 |
| [006 placettes et sols](missions/006-placettes-sols.md) | `dev` | sonnet | appuyer | oui · oui après 001 · oui (synthétique) | 3 |
| [007 ancrage](missions/007-ancrage.md) | `dev` | sonnet | appuyer | oui · oui · non (compte GBIF) → synthétique | 3 |
| [008 modèles](missions/008-modeles.md) | `dev` | sonnet | appuyer | oui · oui · oui (synthétique) | 3 |
| [009 typologie, caractérisation, clé](missions/009-typologie-cle.md) | `dev` | sonnet | appuyer | oui · oui · oui (synthétique) | 4 |
| [010 validation, référence, sorties, pipeline](missions/010-pipeline-sorties.md) | `dev` | sonnet | appuyer | oui · oui · oui | 4 |

Pas de mission `testeur` séparée par mission de développement : le `dev` écrit ses tests
et le `relecteur` les contrôle (décision déléguée, prix au journal). Le test de la règle
bloquante est écrit dans la mission 002, avant tout code d'extraction.
