# Mission 018 — exécution sur la SER pilote

## Mission

**En une phrase (quoi, et pourquoi) :** exécuter le pipeline réel, d'abord sur 4 dalles
puis sur l'emprise test complète (225 dalles), et rendre l'état de preuve chiffré, pour
savoir lesquels des critères du § 7 sont atteints sans relevés de terrain.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui après 016 (`docs/pipeline.md`) | |
| Les moyens ? | oui : ≈ 42 Go de LAZ, ≈ 6 h de calcul (extrapolation de l'incrément 1), 187 Go libres | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** corriger le code (un défaut trouvé devient une mission).

## Harnais

- **Peut (périmètre) :** `data/` (non versionné), `config.yml` (clés d'exécution seulement), un compte rendu `docs/execution-ser-pilote.md`.
- **Ne doit pas :** versionner des données ; présenter un chiffre synthétique comme réel.

## Valeur provisoire (chiffre, réglage)

Seuils et résolution de config.yml, provisoires.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 016 et 017 fusionnées.

## Contrôles reportés des missions 014 et 019

- MRVBF et `hauteur_reseau` sur le MNT réel : valeurs, temps de calcul, part de cellules négatives de `hauteur_reseau`, contrôle dans un vallon vosgien connu.
- Décompte des classes LiDAR 64 et 67 sur les dalles réelles (exclusion du MHC à trancher).

## Tests

État de preuve : chaque critère du § 7 « atteint », « non atteint » ou « non atteint (entrée absente) », chiffre et source.

## Terrain

Échantillon pour Pascal : 10 cellules de la carte des types à confronter au terrain.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.

## Complément du 2026-11-18 (orchestrateur)

- Depuis 021 : la carte hydrique à 25 m (`hydrique_25m.tif`, méthode `biljou_topo`) fait partie du run ; contrôler `k_sv` et `is_topo` sur relief réel (contraste nord/sud, pourtour), et l'écart table/calcul direct.
- Le worktree n'a pas `data/` : créer un lien `data -> /home/pascal/dev/sylvostation/data` pour réutiliser le cache (SAFRAN, etc.) ; ne jamais versionner `data/`.
- Ne pas exécuter dans le dépôt principal (son code peut changer pendant le run).
- **Pour la mission 023 (page pkgdown)** : laisser les sorties sous `data/sorties/D11/` et inscrire dans le compte rendu leur chemin, la liste des fichiers et l'emprise exacte (EPSG:2154).
- Ordre : 4 dalles d'abord ; rendre un point d'étape (chiffres, durée) avant les 225.

## Relance du 2026-11-18 (après 026 et 025)

- Grille à 20 m (ADR 0007) ; sorties renommées (`hydrique.tif`, `grad_hydrique_carte`) ; reprise réseau active (`download_retries: 3`) ; `gbif_anchors` vide signalé.
- Point d'étape du premier essai : `anchors` en erreur sur 4 dalles, LiDAR 2,8 min par dalle, `ifn_gradients` 21 min (journal).
- Réglages d'exécution à reprendre : `demo: false`, `max_tiles: 4`, `tichy_path: "data/cache/Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx"` (non commités).
- Le premier worktree de 018 (code d'avant 026 et 025) n'est plus à utiliser.
