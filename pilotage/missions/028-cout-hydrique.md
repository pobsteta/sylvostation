# Mission 028 — coût de calcul de la carte hydrique et des gradients IFN

## Mission

**En une phrase (quoi, et pourquoi) :** mesurer pourquoi `hydric_grid` prend 4 min 36 s pour
10 000 cellules et `ifn_gradients` 19 min pour 9 392 placettes, et réduire ces coûts sans
changer les résultats, pour que le run des 225 dalles (≈ 56 fois plus de cellules) ne
dure pas des heures de plus.

**Redite par l'agent :** Réduire le temps de la carte hydrique et des gradients IFN en refaisant la boucle BILJOU en vecteurs, sans changer un résultat, pour que le run des 225 dalles ne coûte pas des heures de plus ; chiffres dans `docs/pipeline.md`.

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `R/hydrique.R` (`hydric_stress_grid`, `hydric_stress`), profilage (`profvis` ou `Rprof`), parallélisme (`parallel` de base R) | |
| Les moyens ? | oui : extraits SAFRAN, jeux d'essai | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale ; défaut relevé par 018 (point d'étape du 2026-11-18)._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `R/hydrique.R`, ses tests, `DESCRIPTION` (Imports : `parallel`, paquet de base), `config.yml` et `R/config.R` (nombre de cœurs si utile), `docs/pipeline.md`.
- **Ne doit pas :** changer un résultat (tolérance numérique écrite et testée) ; toucher au worktree de 018.

## Attendus

1. Profil : où va le temps (BILJOU par nœud, interpolation par cellule, extraction, I/O).
2. Projection : coût de `hydric_grid` sur 562 500 cellules et de `ifn_gradients` avant et après.
3. Réduction : par exemple mise en cache des passes BILJOU identiques, vectorisation de l'interpolation, parallélisme par maille ou par placette ; résultats identiques à la tolérance près (test).

## Dépend de / rouge attendu jusqu'à

- Peut tourner pendant le run des 225 dalles ; périmètre disjoint de 027.

## Tests

`.claude/test-command` vert ; test d'égalité des résultats avant/après.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
