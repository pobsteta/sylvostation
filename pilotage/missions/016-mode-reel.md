# Mission 016 — mode réel du pipeline

## Mission

**En une phrase (quoi, et pourquoi) :** brancher le mode `demo: false` de `_targets.R`
pour qu'à partir du seul code SER le pipeline télécharge, calcule et produise le catalogue
sur données réelles, avec les entrées absentes (GNSS, référence AgroParisTech) signalées
dans l'état de preuve plutôt que remplacées.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : fonctions des missions 003 à 010 et 014, 015 ; `docs/pipeline.md` ; ADR 0001, 0004 | |
| Les moyens ? | oui : réseau, 8 cœurs, 31 Go, 187 Go libres ; GNSS et AgroParisTech absents → entrées optionnelles | |

**Temps de la main :** prendre — engage l'architecture du pipeline (cache, blocs de dalles, reprise). **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (architecture)

## Harnais

- **Peut (périmètre) :** `_targets.R`, `R/pipeline_reel.R` (nouveau), `R/config.R`, `config.yml` (nouvelles clés, `demo` reste `true` par défaut), `docs/pipeline.md`, `inst/quarto/` ou le gabarit du rapport, tests `test-pipeline-reel.R`, `DESCRIPTION`, `NAMESPACE`, `man/`.
- **Câblé :** pas de `main` ; journal en ajout seul ; `assert_no_fine_extract_on_ifn()` appelée par toute extraction.
- **Ne doit pas :** versionner une donnée téléchargée ; remplacer une entrée absente par du synthétique en mode réel ; toucher aux tests d'acceptation de la mission 017.
- **Sources autorisées :** `docs/`, `R/`, journal.

## Attendus

- Cibles réelles : SER → emprise + tampon → grille ; tableau d'assemblage → dalles → `run_lasr` par blocs de 3 × 3 (ADR/journal 003), reprise si interrompu (cibles dynamiques par dalle) ; terrain ; géologie BD Charm-50 ; IFN (GRECO) ; sols ; GBIF (`occ_search` sans compte, `occ_download` si identifiants en variables d'environnement) ; indicateurs réels (015) ; modèles, typologie, clé, validation, sorties.
- Entrées optionnelles : `gnss_path`, `reference_path` dans `config.yml` ; absentes → critères « non atteint (entrée absente) » dans l'état de preuve.
- Option `max_tiles` pour un essai court (par ex. 4 dalles) avant la SER entière.
- Tests sans réseau : cibles réelles exécutées sur les extraits réels de `inst/extdata` avec les fonctions de téléchargement simulées.

## Valeur provisoire (chiffre, réglage)

Blocs 3 × 3, résolution 25 m, tampon 5 km (config.yml) : provisoires, gel avant la phase 1.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 014, 015 (fusionnées). **Ordre de fusion :** 014, 015 → 016. Les tests de 017 sont rouges jusqu'à 016.

## Tests

Un test par fonction ; 017 vert ; `R CMD check` sans warning.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
