# Mission 027 — diagnostic du MRVBF et de la hauteur au-dessus du réseau sur MNT réel

## Mission

**En une phrase (quoi, et pourquoi) :** comprendre pourquoi le MRVBF calculé par GRASS
`r.valley.bottom` sur les 4 dalles réelles est quasi nul partout (médiane 2,5e-6, max 1,84)
et pourquoi `hauteur_reseau` atteint 200 à 325 m avec 22 % de NA, et corriger si c'est un
défaut, pour que ces prédicteurs topographiques décrivent bien les fonds de vallon vosgiens.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `R/terrain.R` (`.mrvbf_grass`, `.height_above_streams`), `R/hydro.R`, manuel de `r.valley.bottom` (Gallant & Dowling 2003, DOI 10.1029/2002WR001426), sorties du run 4 dalles (`/home/pascal/dev/sylvostation/.claude/worktrees/agent-a39039d71f8e997e4/data/sorties/D11/` et le store `_targets/` de ce worktree, en lecture) | plan d'abord si la cause n'est pas évidente |
| Les moyens ? | oui : MNT réels en cache (`data/lidar`), GRASS 8.4.2 | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale ; défaut relevé par 018 (point d'étape du 2026-11-18)._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (justesse des données)

## Harnais

- **Peut (périmètre) :** `R/terrain.R`, `R/hydro.R`, leurs tests, `docs/referentiels.md` (§ MRVBF, HAND), `docs/pipeline.md`.
- **Ne doit pas :** écrire dans le worktree de 018 ni dans son store `_targets/` (run des 225 dalles en cours) ; changer la méthode sans source.

## Attendus

1. MRVBF : comparer à l'échelle attendue (classes 0 à environ 8, Gallant & Dowling 2003) ; vérifier unités, paramètres (`t_slope`, résolution d'entrée, MNT à 5 m ou 20 m), et lecture de la sortie GRASS ; un calcul de contrôle sur un vallon réel des dalles en cache ; cause écrite, correction testée si défaut.
2. HAND : vérifier la densité du réseau TOPAGE (30 tronçons sur 6 km²) et l'effet sur les valeurs de 200 à 325 m ; part de NA (hors bassin du réseau) ; proposer une densification sourcée (seuil d'accumulation sur le MNT, ou réseau TOPAGE complet) si défaut.
3. Chiffres avant et après sur les 4 dalles ; un test par correction, sans réseau.

## Dépend de / rouge attendu jusqu'à

- Peut tourner pendant le run des 225 dalles ; l'aval du run sera relancé après intégration.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
