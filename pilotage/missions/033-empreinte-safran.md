# Mission 033 — sortir la carte de l'empreinte des mailles SAFRAN

## Mission

**En une phrase (quoi, et pourquoi) :** proposer puis réaliser une descente d'échelle du climat
et de la réserve utile qui ne soit plus uniforme par maille SAFRAN de 8 km, parce que la carte
des 225 dalles reproduit pour l'essentiel les 9 mailles climatiques (relecture de 023,
2026-11-19 : la maille explique 84 % de la variance de l'Istress topographique, 78 % du
gradient trophique, 95 % du bioclimat ; 89,6 % des cellules sont dans le type modal de leur
maille).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | en partie : plan d'abord ; pistes à évaluer et sourcer (ne rien inventer) : correction altitudinale des températures et de l'ETP par gradient vertical (MNT LiDAR), interpolation des champs SAFRAN entre centres de mailles, RU portée par la géologie ou le pédopaysage plutôt que par la maille, ou autre méthode publiée | plan rendu avant tout code |
| Les moyens ? | oui : sorties de 018 (`data/sorties/D11/`, `hydrique_mailles.csv`), `R/hydrique.R`, `docs/referentiels.md` § 25 (descente d'échelle hydrique, mission 020) | |

**Temps de la main :** donner. **Degré :** le chef tranche, après le plan.

## Ma réponse d'abord

_Délégation totale ; constat chiffré du relecteur de 023 (scripts maille.R, m2.R), vu aussi par
031. Rappel : 021 a retenu « RU uniforme par maille » (prix déclaré : composante hydrique locale
portée par la seule exposition). La maille compte par son climat autant que par sa RU (Istress
plat contre RU : r = −0,43)._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (plan d'abord)

## Harnais

- **Peut (périmètre) :** au plan, rien que lire et mesurer (scratchpad) ; après validation du
  plan : `R/hydrique.R`, `R/climat*.R` ou fichier équivalent, `_targets.R` (cibles climat et
  hydriques), `config.yml` et `R/config.R`, leurs tests, `docs/pipeline.md`,
  `docs/referentiels.md` (section datée).
- **Câblé :** toute méthode est sourcée (référence vérifiée) ou marquée « à vérifier » ; la
  règle des 700 m s'applique (aucune variable fine aux placettes IFN : la descente d'échelle
  peut servir la carte, pas l'extraction aux placettes) ; mesure avant/après de la part de
  variance expliquée par la maille, avec les mêmes scripts que le relecteur.
- **Ne doit pas :** toucher au worktree de 018 ni réécrire `data/sorties/D11/` ; inventer un
  coefficient.

## Attendus

1. Plan : diagnostic (climat contre RU dans l'empreinte), deux ou trois options sourcées avec
   leur coût, leur prix et ce qu'elles changent, une recommandation.
2. Après validation : la méthode retenue, testée ; part de variance expliquée par la maille
   avant/après sur un extrait des sorties de 018.

## Dépend de / rouge attendu jusqu'à

- Rien. Après 032 pour la relance du run.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
