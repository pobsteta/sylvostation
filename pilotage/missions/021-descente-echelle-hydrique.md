# Mission 021 — carte hydrique à 25 m : Is biljouR modulé par la topographie

## Mission

**En une phrase (quoi, et pourquoi) :** produire la grille 25 m de l'indice de contrainte
hydrique en appliquant la méthode retenue par la mission 020 (RU, ETP ou rayonnement
modulés par la topographie) au bilan `biljouR` sur SAFRAN, pour que la carte des stations
porte une composante hydrique locale et pas seulement climatique à 8 km.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui, avec réserve : `docs/referentiels.md` § 25.4 à 25.6 (méthode A, adaptation non validée de Dyer 2009) ; `biljouR::safran_to_meteo`, `penman_pet` ; GRASS `r.sun` | plan d'abord |
| Les moyens ? | oui : dalles réduites et extraits SAFRAN de `inst/extdata`, R, biljouR | |

**Temps de la main :** donner — plan d'abord. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : choix (c), puis « Oui » au montage recommandé : ETP modulée par le rayonnement de la pente dans l'Is, TWI, MRVBF et HAND gardés à part comme prédicteurs, RU uniforme par maille._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus

## Harnais

- **Peut (périmètre) :** `R/hydrique.R`, `R/terrain.R` (rayonnement `r.sun` mensuel), `R/pipeline_reel.R`, `_targets.R` (mode réel seulement), `config.yml`/`R/config.R` (nouvelles clés), leurs tests, `NAMESPACE`, `man/`, `inst/extdata` (extrait SAFRAN complété de `SSI`, `T`, `FF`, `HU` si Licence Ouverte, + `SOURCES.md`), `docs/referentiels.md` (§ 25 : ce qui a été vérifié), `docs/pipeline.md`.
- **Ne doit pas :** moduler la RU par la topographie ; mettre TWI, MRVBF ou HAND dans BILJOU ; appliquer k aux placettes IFN ; toucher au mode démo.
- **Câblé :** `assert_no_fine_extract_on_ifn()` ; EPSG:2154 ; tests sans réseau.

## Attendus

1. **Plan d'abord** (temps « donner ») : fonctions, cibles `targets`, coût de calcul de `r.sun` sur 225 dalles, repli sans GRASS.
2. `solar_factor(dtm, ...)` : k(x, mois) = G_r.sun(pente, exposition, ombres) / G_r.sun(pente 0), ciel clair, 12 couches ; conversion d'exposition vers la convention `r.sun` vérifiée par un test (versant sud connu : k > 1 en hiver) ; repli signalé si GRASS absent (k = 1, méthode « climatique »).
3. Lecture SAFRAN de `SSI`, `T`, `FF`, `HU` ; unité de `SSI` vérifiée (source datée) ou « à vérifier ».
4. `hydric_stress_grid()` : Istress 25 m = BILJOU(ETP Penman biljouR avec rg × k, P maille, RU maille) ; plat de référence par la même formule (k = 1) ; table par maille sur suites de k et de RU, écart à un calcul direct mesuré sur un échantillon de cellules.
5. **RU uniforme par maille SAFRAN** (provisoire, dit dans l'état de preuve) : médiane des RU euptf2 des placettes IFN de la maille (variable de sol à maille large, croisable avec l'IFN), sinon médiane de l'emprise ; jamais de modulation topographique.
6. TWI, MRVBF et `hauteur_reseau` restent des prédicteurs distincts du modèle de stations, à côté d'Istress ; vérifier qu'ils sont bien dans les groupes de prédicteurs du mode réel (`_targets.R`, l. 78) et les y ajouter sinon.
7. Placettes IFN : Istress inchangé (`hydric_stress()` sans k), `assert_no_fine_extract_on_ifn()` ; l'écart d'échelle entre carte et placettes écrit dans l'état de preuve.
8. Valeurs provisoires du § 25.5 nommées « provisoire » dans le code et la doc.

## Valeur provisoire (chiffre, réglage)

Celles du § 25.5 (ciel clair, Turc → Penman, Linke 3,0, albédo 0,2, jours de Klein, unité SSI, pas des suites) et la RU uniforme par maille ; mesurées sur les trois points au sol du § 25.7 ; gel avant la phase 1.

## Tests

Un test par fonction, sans réseau ; un test : versant sud > plat > versant nord pour k en hiver ; un test : la règle des 700 m bloque k aux placettes IFN ; mode démo inchangé.

## Terrain

Les trois points du § 25.7, à nommer par Pascal dans D11.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 020. **Précède :** 018.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
