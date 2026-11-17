# Mission 017 — tests d'acceptation du mode réel

## Mission

**En une phrase (quoi, et pourquoi) :** écrire, sans lire le code de la mission 016, les
tests d'acceptation du mode réel tirés du § 7 du brief technique et de `docs/spec.md`, pour
que le branchement du réel ne soit pas validé par celui qui l'a codé.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : fiche 016 (interface : clés de config, entrées optionnelles), `docs/pipeline.md`, `man/` | |
| Les moyens ? | oui : testthat, extraits réels de `inst/extdata` | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale._

## L'Homme

- **Agent :** `testeur` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** lire `R/pipeline_reel.R` ou `_targets.R`.

## Harnais

- **Peut (périmètre) :** `tests/testthat/test-acceptation-mode-reel.R` uniquement.
- **Ne doit pas :** lire le code de 016 ; télécharger.

## Cas à couvrir

En mode réel : aucune sortie ne porte `synth_` ni `synthetic = TRUE` ; GNSS absent → critère de validation « non atteint (entrée absente) » dans l'état de preuve ; référence absente → comparaison sautée et signalée ; aucune extraction fine aux placettes IFN (assertion levée si on force) ; toutes les sorties en EPSG:2154 ; chaque type ≥ 1 % de la surface ou marqué azonal ; rapport avec la section « Limites ».

## Valeur provisoire (chiffre, réglage)

Aucune.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** fiche 016 seulement. **Rouge attendu :** jusqu'à la fusion de 016.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
