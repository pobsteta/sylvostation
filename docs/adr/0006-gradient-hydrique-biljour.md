# ADR 0006 — Gradient hydrique par bilan hydrique (biljouR)

- **Date :** 2026-11-17
- **Statut :** acceptée
- **Proposée par :** Claude (orchestrateur)
- **Tranchée par :** Pascal (« Oui utilise biljouR », 2026-11-17)

## La décision en une phrase

Le gradient hydrique n'est plus la réserve utile seule mais un indice de contrainte
hydrique (indice Is et nombre de jours de stress) calculé par le modèle de bilan hydrique
journalier BILJOU (paquet `biljouR`, github pobsteta/biljouR) à partir de la réserve utile,
du climat SAFRAN et de la végétation ; la réserve utile devient une entrée.

## Contexte

Le brief technique (étape 5, « Hydrique ») établit le gradient hydrique sur la réserve
utile, l'engorgement et la topographie. La réserve utile ne mesure que la taille du
réservoir ; la flore répond à la contrainte subie, qui dépend aussi du climat. Le point
« réserve utile = gradient hydrique » était resté « à vérifier » (docs/pipeline.md).
La réserve utile elle-même reposait sur une correspondance codes IFN → classes de l'Aisne
non publiée (journal du 2026-11-17, mission 015).

## Chaîne retenue

Code de texture IFN (dictionnaire des données brutes) → classe de texture → pourcentages
argile/limon/sable représentatifs (centre du polygone, paquet `soiltexture`) → eau
disponible par `euptf2` (Szabó et al. 2021) → réserve utile par couche → `biljouR`
(SAFRAN) → indice Is. Bruand et al. 2004 (tableau 2) sert de contre-vérification.

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | La RU seule était plus simple mais ne mesure pas la contrainte | Une dépendance et le climat SAFRAN | oui (Pascal) |
| **R**esponsable | Qui fait quoi ? | biljouR maintenu par Pascal ; sylvostation l'appelle | — | — |
| **A**nticiper | Si l'imprévu arrive ? | SAFRAN ou biljouR absent → repli sur la RU, signalé dans l'état de preuve | Gradient moins juste en repli | oui |
| **N**ovateur | Toutes les idées ? | RU seule ; RU + bilan P−ETP ; BILJOU (retenu) | — | — |
| **C**oût | Coût complet ? | Calcul journalier sur grille SAFRAN 8 km, puis descente d'échelle par la RU et le rayonnement LiDAR | Temps de calcul | oui |
| **É**cologique | Réutilisation ? | Paquets libres (GPL), formats ouverts | — | — |

## Valeurs sacrifiées

Frugale : une chaîne plus longue, et une dépendance de plus.

## Sources

`docs/brief-technique.md` étape 5 ; Granier et al. 1999 (BILJOU) ; Szabó et al. 2021
(euptf2) ; Moeys, soiltexture (CRAN) ; Bruand et al. 2004 ; journal du 2026-11-17.
