# Fiche de relevé floristique GNSS

**Statut : à relire par Pascal avant toute sortie** (mission 029). Protocole :
`protocole.md`. Saisie : `gabarit_station.csv` (une ligne par relevé) et
`gabarit_flore.csv` (une ligne par espèce).

## Relevé

| Champ | Valeur |
|---|---|
| Identifiant du relevé (`id`) | |
| Point du plan (`id_plan`, ex. `P07` ou `P07-R1`) | |
| Rang utilisé (0, 1, 2) et raison du remplacement | |
| Date, observateur | |
| x (est), y (nord) en Lambert-93, m | |
| Précision GNSS affichée (`loc_precision_m`, m ; ≤ 25 exigé, ≤ 5 visé) | |
| Nombre de mesures moyennées | |

## Placette : cercle de 400 m² (rayon 11,28 m)

| Strate | Recouvrement (%) |
|---|---|
| Arborescente | |
| Arbustive | |
| Herbacée | |
| Muscinale | |

Seuils de hauteur des strates : à confirmer par Pascal.

## Sol

| Champ | Valeur |
|---|---|
| Forme d'humus (Mull, Moder, Mor, Amphi, Tangel ; à vérifier) | |
| Tarière : profondeur atteinte (cm) | |
| Refus de tarière (oui, non) | |
| Texture et observations (en clair) | |
| Photos (noms de fichier) | |

## Flore : liste complète des espèces vasculaires

Coefficient de Braun-Blanquet par strate : `r` rare ; `+` peu abondant, recouvrement très
faible ; `1` abondant, recouvrement faible ; `2` 5 à 25 % ; `3` 25 à 50 % ; `4` 50 à 75 % ;
`5` plus de 75 %. Une ligne par espèce ; case vide si absente de la strate.

| Espèce (nom latin) | CD_NOM | Arbo. | Arbu. | Herb. | Musc. |
|---|---|---|---|---|---|
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |

Remarques :
