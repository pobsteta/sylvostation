# Mission 043 — TAR_ASK posé par les tests eux-mêmes

## Mission

**En une phrase (quoi, et pourquoi) :** faire poser `TAR_ASK = "false"` par les tests qui lisent
un store `_targets` qu'ils ont créés, pour que la suite reste verte en local après une mise à
jour de `targets`, sans dépendre de la variable posée dans la CI.

**Redite par l'agent :** _à compléter par l'agent._

## Sources

- Journal 2026-11-21 (PR #5, 3e passage de CI) : la version de `targets` de la CI (plus récente
  que la 1.12.1 locale) refuse de lire un store contenant du code `tar_format()` hors session
  interactive ; échecs à `test-acceptation-039.R:36` et dans `test-acceptation-mode-reel.R`.
  Correction provisoire : `TAR_ASK: "false"` sur l'étape « Tests depuis la racine » de
  `.github/workflows/ci.yml`.
- Fichiers qui appellent `tar_make`/`tar_read` : `tests/testthat/test-pipeline-reel.R`,
  `test-pipeline.R`, `test-acceptation-mode-reel.R`, `test-acceptation-039.R`.

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui | pas de plan |
| Les moyens ? | oui | |

**Temps de la main :** donner. **Degré :** l'orchestrateur tranche (délégation totale).

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut :** les 4 fichiers de test ci-dessus, ou un helper `tests/testthat/helper-*.R` commun
  (portée limitée : `withr::local_envvar(TAR_ASK = "false")` dans chaque test qui lit un store
  créé par le test, pas un `Sys.setenv` global à toute la suite).
- **Câblé :** les stores lus sont toujours ceux que le test a créés (dossier temporaire) ; le
  `TAR_ASK` de `.github/workflows/ci.yml` est laissé en place (double sécurité) ; un commentaire
  dit pourquoi.
- **Ne doit pas :** toucher `R/`, `_targets.R`, `config.yml`, `.github/`, `wt035run`,
  `data/sorties/`.

## Attendus

1. Les 4 fichiers de test verts en local (`LC_ALL=C.UTF-8`).
2. Si possible, la preuve que la protection marche : les mêmes tests verts avec une version de
   `targets` récente installée dans une bibliothèque temporaire (sans toucher la bibliothèque
   de Pascal) ; sinon, l'écrire au rapport.

## Tests

Fichiers touchés verts.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
