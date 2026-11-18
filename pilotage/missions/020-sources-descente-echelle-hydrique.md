# Mission 020 — sources : descente d'échelle de l'indice hydrique par la topographie

## Mission

**En une phrase (quoi, et pourquoi) :** trouver, comparer et vérifier les méthodes publiées
qui modulent par la topographie (rayonnement selon pente et exposition, apports latéraux,
position, profondeur de sol) la réserve utile, l'ETP ou le bilan hydrique BILJOU, pour que
la carte hydrique à 25 m (choix (c) de Pascal, 2026-11-18) repose sur une méthode sourcée et
non sur une modulation inventée.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : pistes à vérifier, pas à reprendre telles quelles — Piedallu et Gégout (rayonnement topographique, bilan hydrique et distribution des essences, AgroParisTech/LERFoB), Granier et al. 1999 (BILJOU), indice d'humidité topographique (Beven et Kirkby 1979), HAND (Nobre et al. 2011), ce que `biljouR` (github pobsteta/biljouR) expose déjà | |
| Les moyens ? | oui : web, lecture du dépôt | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18, à la question R8 : « C » — descente d'échelle d'Is par biljouR avec
une RU modulée par la topographie._

## L'Homme

- **Agent :** `acquereur` · **Modèle :** opus (justesse des sources)

## Harnais

- **Peut (périmètre) :** `docs/referentiels.md` (nouveau § 25, « Descente d'échelle hydrique »), rendu dans la conversation.
- **Ne doit pas :** écrire du code, toucher à `R/`, au journal, au kanban ; inventer un coefficient.

## Attendus

1. Au moins deux méthodes publiées, comparées (CQQCOQP) : quelle grandeur est modulée (RU, ETP, rayonnement, apports), par quelle variable topographique, avec quelle équation ou quel coefficient, à quelle résolution, validée où (forêts tempérées françaises de préférence).
2. Pour chacune : référence complète (DOI), page ou équation exacte, licence du code s'il existe, package R qui l'implémente (nom, version, fonction).
3. Ce que `biljouR` sait déjà faire à cet égard (rayonnement, correction de pente, grille) : fonctions et arguments lus dans le code.
4. Les variables topographiques déjà produites par sylvostation (`R/terrain.R`, `R/hydro.R` : pente, exposition, TWI, MRVBF, HAND…) qui servent d'entrée, et celles qui manquent.
5. Une recommandation : la méthode la plus simple qui soit publiée, avec ses limites (ce qu'elle ne capte pas), et les valeurs qui resteraient provisoires.
6. La règle bloquante rappelée : la modulation fine ne s'applique qu'à la carte (grille 25 m) et aux points à `loc_precision_m` ≤ 25 m, jamais aux placettes IFN.

## Valeur provisoire (chiffre, réglage)

Aucune : tout coefficient non sourcé est signalé « à vérifier ».

## Dépend de / rouge attendu jusqu'à

- **Précède :** 021 (dev). 018 attend 021.

## Tests

Liste de contrôle passée (jointe).

## Terrain

Un vallon et une crête connus de la SER D11 où Pascal pourra juger le sens de la modulation.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
