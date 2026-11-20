# ADR 0008 — Le gradient trophique de la carte ne dépend pas du peuplement actuel

- **Date :** 2026-11-19
- **Statut :** acceptée (délégation : « Fais ce qu'il y a de mieux », Pascal, 2026-11-19 ;
  Pascal peut reprendre la main)
- **Proposée par :** mission 037 (plan), orchestrateur
- **Tranchée par :** l'orchestrateur, par délégation

## La décision en une phrase

Aucune variable décrivant le peuplement actuel (essence relevée par l'IFN, type de formation
végétale de la BD Forêt, composition dans 700 m) n'entre dans les prédicteurs du gradient
trophique qui fait la carte des stations ; l'essence sert seulement de **contrôle** (accord
entre trophique prédit et essences en place) et de **test de sensibilité** publié à part.

## Contexte

Mesure de 037 (2026-11-19) : sur 1 519 placettes IFN pures de la GRECO D, l'essence (groupes
de la nomenclature BD Forêt v2) explique 27 % de la variance du trophique (blocs de 20 km :
0,26), sans circularité (indice sans les arbres). C'est plus que la lithologie dans 700 m
(+0,16, mission 035). Mais un catalogue de stations sert à choisir l'essence adaptée à la
station : la station doit être décrite par le milieu (climat, roche, sol, relief), pas par ce
qu'on y a planté. Épicéa et douglas sont souvent plantés ; un épicéa sur station riche
abaisserait le trophique prédit, et le catalogue recommanderait ce qui est déjà en place. La BD
Forêt v2 date de 2007 à 2010 (photos) et sa licence est contradictoire (à vérifier).

## Le crible FRANCE

| Lettre | Question | Réponse | Ce que ça coûte | Prêts à payer ? |
|---|---|---|---|---|
| **F**rugale | Plus simple qui tienne ? | Prédicteurs du milieu seuls | R² trophique plus bas | oui |
| **R**esponsable | Qui fait quoi ? | 035 : prédicteurs du milieu ; 037 : contrôle par essence | — | — |
| **A**nticiper | Si l'imprévu arrive ? | Le test de sensibilité « avec essence » reste calculé et publié | un modèle de plus | oui |
| **N**ovateur | Toutes les idées ? | Essence comme prédicteur (écartée), essences spontanées seules (écartée : la composition reste gérée), ancrages BD Forêt (R² attendu ≈ 0,05, écartée) | — | — |
| **C**oût | Coût complet ? | Perte possible de ≈ 0,1 à 0,25 de R² trophique | justesse | oui |
| **É**cologique | Réutilisation ? | La carte reste utilisable pour choisir les essences, y compris sous scénario climatique | — | — |

## Conséquences

- 035 n'ajoute pas la composition BD Forêt dans 700 m aux prédicteurs (retirée de ses ajouts).
- 037 : corriger `clean_occ` (licences CC BY-NC et Pl@ntNet exclues) ; produire le contrôle
  « trophique prédit contre essences en place » et le modèle de sensibilité avec essence, publiés
  comme tels, jamais comme la carte.

## Réversibilité

Forte : une ADR nouvelle suffit pour réintroduire l'essence ; le modèle de sensibilité en donne
le gain chiffré.

## Valeurs sacrifiées

La justesse statistique immédiate du trophique, au profit de l'indépendance de la station
vis-à-vis de la gestion passée.

## Addendum (mission 037, partie 2, 2026-11-20) : gain mesuré

Le modèle de sensibilité mesuré sur le run réel 035 donne +0,061 de R² (blocs de 22 121 m) et +0,058
(8 358 m) quand on ajoute l'essence dominante ; le placebo (essences mélangées) donne +0,010 et +0,007,
soit un gain net de l'ordre de 0,05. La « perte possible de ≈ 0,1 à 0,25 » du crible était une
surestimation : la lithologie, le pH et le climat captent déjà une partie du signal d'essence. Le contrôle
par essence relève trois alertes (pin sylvestre prédit trop riche, aulne et érable trop pauvres) et un
défaut d'amplitude (pente 0,31). Voir `docs/referentiels.md` § 36.
