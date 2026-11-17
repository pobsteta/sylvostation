# ADR 0003 — Jeux d'essai réduits, réels quand c'est possible, synthétiques et marqués sinon

- **Date :** 2026-11-16
- **Statut :** acceptée par délégation (Claude, orchestrateur, pour Pascal)
- **Proposée par :** Claude (orchestrateur)
- **Tranchée par :** Pascal, par délégation totale du 2026-11-16

## La décision en une phrase

Les tests n'utilisent que des fichiers de `inst/extdata` de moins de 5 Mo au total ;
ce sont des extraits réels quand la source est accessible et la licence ouverte, sinon
des données synthétiques préfixées `synth_` et portant `synthetic = TRUE`.

## Contexte

Le brief interdit tout téléchargement dans les tests et demande une dalle LiDAR réduite,
une centaine de placettes et un extrait géologique (consignes). Plusieurs sources ne
sont pas accessibles dans la session (compte GBIF, rasters AgroParisTech, relevés GNSS).

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | Petits fichiers ouverts (GeoPackage, GeoTIFF, CSV, LAZ) | — | — |
| **R**esponsable | Qui fait quoi ? | Le `dev` fabrique (correction du 2026-11-16 : il n'y a pas de `testeur` par mission) ; le `testeur` de la mission 011 écrit les tests de la règle bloquante ; le relecteur vérifie le marquage | — | — |
| **A**nticiper | Si l'imprévu arrive ? | Un test vert sur données synthétiques ne prouve rien sur le réel : dit dans chaque rendu | Fausse confiance possible | oui, avec le marquage |
| **N**ovateur | Toutes les idées ? | Données réelles téléchargées à la volée écartées (brief) | — | — |
| **C**oût | Coût complet ? | Dépôt léger | — | — |
| **É**cologique | Réutilisation ? | Extraits IGN/BRGM sous Licence Ouverte Etalab réutilisables | Citer la source | oui |

## Licence de chaque extrait (ajout du 2026-11-16, objection B3 de la mission 000)

Chaque extrait réel est inscrit dans `inst/extdata/SOURCES.md` avec sa source, sa date,
sa licence et, pour GBIF, le DOI du téléchargement ou la requête exacte. Le dépôt étant
public, un extrait sous licence non ouverte (CC BY-NC, conditions particulières) n'entre
pas : il est remplacé par un jeu synthétique.

## Valeurs sacrifiées

**Anticiper** en partie : la représentativité des jeux d'essai. Accepté parce que le
marquage `synth_` rend la limite visible.

## Sources

`docs/brief-technique.md`, consignes (« Tests », « Données »).

## Question de contrôle

Cette décision tient-elle nos six valeurs ? Oui, au prix d'une validation sur données
réelles reportée au massif test.
