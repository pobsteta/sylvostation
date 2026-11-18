# Mission 021 — carte hydrique à 25 m : Is biljouR modulé par la topographie

## Mission

**En une phrase (quoi, et pourquoi) :** produire la grille 25 m de l'indice de contrainte
hydrique en appliquant la méthode retenue par la mission 020 (RU, ETP ou rayonnement
modulés par la topographie) au bilan `biljouR` sur SAFRAN, pour que la carte des stations
porte une composante hydrique locale et pas seulement climatique à 8 km.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | après 020 (`docs/referentiels.md` § 25) | plan d'abord |
| Les moyens ? | oui : dalles réduites et extraits SAFRAN de `inst/extdata`, R, biljouR | |

**Temps de la main :** donner — plan d'abord. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : choix (c)._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus

## Harnais

- **Peut (périmètre) :** à fixer après 020 (`R/hydrique.R`, `R/pipeline_reel.R`, `_targets.R`, tests, `docs/`).
- **Câblé :** `assert_no_fine_extract_on_ifn()` ; EPSG:2154 ; tests sans réseau.

## Attendus

À compléter après 020.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 020. **Précède :** 018.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
