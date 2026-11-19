# Mission 035 — calibrer les modèles régionaux sur toute la GRECO D

## Mission

**En une phrase (quoi, et pourquoi) :** calibrer les modèles trophique et hydrique sur toutes les
placettes IFN de la GRECO D (≈ 2 900 avec relevé, contre 187 aujourd'hui), comme le prévoit le
brief technique (§ 2 : « calibrés à l'échelle de la GRECO »), parce que les prédicteurs à maille
large ne sont calculés que sur l'emprise de la carte et que 187 placettes ne suffisent pas
(R² CV trophique ≈ 0 en 018, −0,23 après 033).

**Redite par l'agent :** _à compléter par l'agent._

## Ma réponse d'abord

_Pascal, 2026-11-19 : pas de demande d'accès à EcoPlant ni à SOPHY, « trouve une autre solution ».
Choix de l'orchestrateur : données ouvertes seulement._ Prédicteurs aux placettes, tous à maille
large (règle des 700 m) : climat SAFRAN (interpolé, 033), lithologie dominante dans 700 m
(BD Charm-50 sur les départements de la GRECO D), pH SoilGrids 2.0 (CC BY 4.0, 250 m, § 18 de
referentiels.md) moyenné dans 700 m. Absorbe le câblage de `geologie_700m` prévu en 034.

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (plan d'abord)
- **Temps de la main :** donner. **Degré :** le chef tranche, après le plan.

## Harnais

- **Peut :** au plan, lire et mesurer (scratchpad, caches existants) ; après validation :
  `_targets.R` (cibles placettes et prédicteurs), `R/pipeline_reel.R`, `R/geologie.R`,
  `R/modeles.R`, `R/sols.R`, `config.yml`, `R/config.R`, tests, `docs/pipeline.md`,
  `docs/referentiels.md` (section datée).
- **Câblé :** règle des 700 m ; validation croisée par blocs spatiaux ; R² avant/après ; coût
  en temps et en disque de l'extension (SAFRAN, BD Charm-50, SoilGrids sur la GRECO).
- **Ne doit pas :** toucher au worktree de 018 ni à `data/sorties/D11/` ; affecter une
  formation géologique sans règle ; télécharger dans les tests.

## Attendus

1. Plan : pourquoi 187 placettes seulement (où se perdent les autres), effectif atteignable,
   prédicteurs, coût, mesure rapide du gain sur un échantillon, recommandation.
2. Après validation : calibration GRECO câblée, R² par blocs avant/après.

## Dépend de

033 (intégration) pour le code ; le plan peut commencer.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
