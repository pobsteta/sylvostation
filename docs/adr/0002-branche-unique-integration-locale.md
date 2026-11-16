# ADR 0002 — Une branche poussée, une branche locale par mission

- **Date :** 2026-11-16
- **Statut :** acceptée par délégation (Claude, orchestrateur, pour Pascal)
- **Proposée par :** Claude (orchestrateur)
- **Tranchée par :** Pascal, par délégation totale du 2026-11-16

## La décision en une phrase

Chaque mission travaille dans son worktree et sa branche locale ; l'orchestrateur
l'intègre après relecture sur `claude/admiring-cerf-hq7t8l`, seule branche poussée, avec
une seule PR brouillon vers `main` que Pascal fusionnera.

## Contexte

La méthode veut « une mission = une branche = une PR ». La session cloud n'autorise le
push que sur `claude/admiring-cerf-hq7t8l`, et le dépôt n'avait aucun commit. Options :
une PR par mission (impossible : push refusé ailleurs), tout coder sur une branche sans
découpage (perd la traçabilité), branches locales intégrées (retenu).

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | Une PR unique, un commit d'intégration par mission | PR volumineuse | oui |
| **R**esponsable | Qui fait quoi ? | Agents : leur branche ; relecteur : chaque mission ; orchestrateur : intégration ; Pascal : fusion vers `main` | Pascal relit tout d'un coup | oui, journal et fiches l'aident |
| **A**nticiper | Si l'imprévu arrive ? | Chaque mission est un commit identifiable (`Mission NNN`), réversible par `git revert` | — | — |
| **N**ovateur | Toutes les idées ? | PR empilées écartées (non poussables) | — | — |
| **C**oût | Coût complet ? | Aucun outil en plus | Relecture finale plus longue | oui |
| **É**cologique | Réutilisation ? | Historique lisible par un successeur | — | — |

## Valeurs sacrifiées

**Responsable** (en partie) : Pascal ne valide pas chaque PR au fil de l'eau (porte n° 3
franchie par délégation). Il la franchit en une fois, à la fusion de la PR brouillon.

## Sources

Consignes de la session cloud (branche de développement imposée) ; `pilotage/journal.md`.

## Question de contrôle

Cette décision tient-elle nos six valeurs ? Oui, au prix d'une relecture humaine groupée.
