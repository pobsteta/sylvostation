# Mission 040 — table lithologique : classer les formations non classées de la GRECO D

## Mission

**En une phrase (quoi, et pourquoi) :** faire entrer dans le dépôt la table de classes
lithologiques acceptée par Pascal le 2026-11-20 (option b), pour que les 155 notations
aujourd'hui `non_classe` dans les disques des placettes GRECO et dans l'emprise reçoivent une
classe sourcée, et mesurer l'effet sur le R² trophique.

**Redite par l'agent :** _à compléter par l'agent._

## Sources

- Proposition acceptée (acquereur-litho, 2026-11-20), lecture seule, à recopier dans le
  scratchpad de l'agent dès le départ (dossier volatil) :
  `/tmp/claude-1000/-home-pascal-dev-sylvostation/3d37db41-ab41-4386-adda-0d0c87e7d32a/scratchpad/litho/`
  - `proposition_classes.csv` : notation → classe, avec source et justification ;
  - `proposition_regles.md` : motifs PCRE proposés, priorités décimales ;
  - `decisions_cas_difficiles.csv` : les 8 cas tranchés par Pascal un par un.
- Décision de Pascal (journal, 2026-11-20) : table acceptée hors 8 cas difficiles ; 3 classes
  nouvelles (`volcanite`, `schiste_grauwacke`, `plutonite_intermediaire`) ; règles complétées ;
  défauts `t1b` et `j2b2` corrigés ; 10 formations laissées `non_classe`.
- Décision de l'orchestrateur (2026-11-20, mesure des homonymes) : codage par NOTATION seule
  gardé ; aucun gain mesuré à coder département + NOTATION.
- Code : `R/geologie.R` (`list_formations()`, `recode_lithology()`, `rasterize_geol(table = )`).
- Piedallu et al. (2006), annexe 1, p. 87-89 : citée, **jamais copiée dans le dépôt**.

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui | pas de plan, code direct |
| Les moyens ? | oui : proposition prête, store du run réel `.claude/worktrees/wt035run/_targets` en lecture seule | |

**Temps de la main :** donner. **Degré :** l'orchestrateur tranche (délégation totale).

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut :** `R/geologie.R`, la table de règles et une table notation → classe sous `inst/extdata`
  (seulement des codes et des classes, aucun texte sous licence ; source BD Charm-50 BRGM citée
  dans `SOURCES.md`), les nouvelles classes dans le tableau de richesse correspondant, leurs
  tests, `docs/referentiels.md` (section datée), `docs/pipeline.md`.
- **Câblé :** rejouer chaque motif avec `recode_lithology()` et comparer aux décomptes de la
  proposition (les décomptes ont été faits à la main) ; tout écart est écrit au rapport de
  mission ; chaque classe porte sa source ; les 10 `non_classe` restent listés, jamais supprimés.
- **Ne doit pas :** toucher `_targets.R`, `config.yml`, `R/config.R` (037d et 039 y travaillent),
  `wt035run`, `data/sorties/`.

## Attendus

1. Table et règles intégrées, tests verts.
2. Décompte avant/après des formations `non_classe` (surface et placettes).
3. R² trophique par blocs (22 km estimés et 8 358 m) avant et après, mesuré dans le scratchpad
   sur le store du run réel (lecture seule).

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
