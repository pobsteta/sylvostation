# Mission 032 — ne plus refaire le LiDAR quand la configuration change

## Mission

**En une phrase (quoi, et pourquoi) :** faire qu'un changement de `config.yml` sans rapport
avec le LiDAR (par exemple l'ajout de `mrvbf_res_m` par 027) ne rende plus `lidar_files`
périmée, et qu'une dalle déjà calculée ne soit pas recalculée, pour qu'une relance du
pipeline sur les 225 dalles ne coûte plus 10 à 16 h de LiDAR.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `targets` suit l'objet global `cfg` en entier ; passer aux cibles des scalaires (globaux dédiés ou cible `cfg_lidar`) ; cache par dalle dans `run_tile_block()` (`R/lidar.R`) | |
| Les moyens ? | oui : jeux d'essai LiDAR de `inst/extdata`, mode hors ligne | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale ; écart relevé le 2026-11-19 (journal) : `tar_outdated()` rendait les 55
cibles, `lidar_files` comprise, après l'ajout d'une clé ; contourné par
`tar_make(names, shortcut = TRUE)`. Le commentaire de `_targets.R` (« une dalle deja calculee
n'est pas refaite ») est faux : `run_tile_block()` n'a pas de cache par dalle._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `_targets.R` (dépendances à `cfg` des cibles d'emprise et de LiDAR :
  `ser`, `emprise`, `tiles`, `tile_blocks`, `lidar_files`, `dtm`), `R/lidar.R`
  (`run_tile_block`), leurs tests, `docs/pipeline.md`.
- **Câblé :** une dalle est réutilisée seulement si ses deux sorties (`mnt_`, `mhc_`) existent,
  se lisent avec `terra`, sont en EPSG:2154 et ont la résolution attendue ; sinon elle est
  recalculée ; une option (argument, défaut `FALSE`) force le recalcul ; le paramétrage qui
  change le calcul (résolution, `buffer`, moteur) doit rendre la cible périmée.
- **Ne doit pas :** toucher au worktree de 018 (`agent-a39039d71f8e997e4`) ni à `data/` ;
  changer un résultat LiDAR ; toucher à `R/carhab.R`, `_pkgdown.yml`, `vignettes/`, `README.md`
  (missions 031 et 023 en cours).

## Attendus

1. Un test (hors ligne, `targets` dans un dossier temporaire) qui montre qu'ajouter une clé sans
   rapport à `config.yml` ne rend pas `lidar_files` périmée, et qu'en changer `lidar_buffer_m`
   la rend périmée.
2. Un test qui montre qu'une dalle déjà calculée n'est pas recalculée (et l'est si un fichier est
   absent ou illisible, ou si l'option de recalcul est posée).
3. Commentaire de `_targets.R` et `docs/pipeline.md` justes.

## Dépend de / rouge attendu jusqu'à

- Rien. Périmètre disjoint de 031 et 023.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
