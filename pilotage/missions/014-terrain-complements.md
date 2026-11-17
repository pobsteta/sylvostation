# Mission 014 — MRVBF et hauteur au-dessus du réseau

## Mission

**En une phrase (quoi, et pourquoi) :** ajouter à `derive_terrain()` le MRVBF (WhiteboxTools)
et la hauteur au-dessus du réseau hydrographique (BD TOPAGE), aujourd'hui à NA, parce que
ce sont deux prédicteurs clés du gradient hydrique (brief technique, étape 3).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui après 013 (§ BD TOPAGE, § WhiteboxTools) | dépend de 013 |
| Les moyens ? | oui : MNT réel de l'incrément 1 (`data/increment1/`), réseau ouvert, `whitebox` installable | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `R/terrain.R`, `R/hydro.R` (nouveau), `tests/testthat/test-terrain.R`, `tests/testthat/test-hydro.R`, `inst/extdata/` (extrait BD TOPAGE du massif test s'il est sous licence ouverte, avec `SOURCES.md`), `DESCRIPTION`, `NAMESPACE`, `man/`.
- **Câblé :** pas de `main` ; journal en ajout seul.
- **Ne doit pas :** toucher à `_targets.R` (mission 016) ; inventer une couche.
- **Sources autorisées :** `docs/referentiels.md`, `docs/brief-technique.md` (étape 3), ADR 0001 à 0005.

## Attendus

`get_hydro_network(emprise)` (BD TOPAGE, Lambert-93), `height_above_network(dtm, network)`,
MRVBF via `whitebox` (saut propre si absent : NA + avertissement, comme aujourd'hui) ; tests
sans réseau sur un extrait ; contrôle sur le MNT réel de l'incrément 1 (valeurs, temps) dans le compte rendu.

## Valeur provisoire (chiffre, réglage)

Paramètres MRVBF par défaut de WhiteboxTools, provisoires jusqu'à comparaison avec la carte de référence.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 013. **Ordre de fusion :** 013 → 014.

## Tests

Un test par fonction ; un point connu tombe dans la bonne cellule ; check sans warning.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
