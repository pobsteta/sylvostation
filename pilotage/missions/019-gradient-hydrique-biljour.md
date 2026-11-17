# Mission 019 — gradient hydrique par biljouR, réserve utile par texture

## Mission

**En une phrase (quoi, et pourquoi) :** calculer la réserve utile depuis les codes de
texture IFN par une chaîne publiée (dictionnaire IFN → `soiltexture` → `euptf2`) puis le
gradient hydrique comme indice de contrainte `biljouR` sur climat SAFRAN (ADR 0006), pour
que le gradient hydrique ne repose plus sur une correspondance inventée ni sur la seule
taille du réservoir.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : ADR 0006 ; `biljouR` (github pobsteta/biljouR : `biljou_soil`, `biljou_run`, `biljou_run_grid`, `safran_*`, `biljou_indices`) ; `soiltexture` (`TT.points.in.classes`, `FR.AISNE.TT`) ; `euptf2` (github tkdweber/euptf2, `which_PTF`) | |
| Les moyens ? | oui : réseau (archive IFN avec son dictionnaire, SAFRAN), R | |

**Temps de la main :** donner — l'agent rend d'abord le dictionnaire des codes TEXT1/TEXT2 et sa source, puis code. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-17 : « Oui utilise biljouR. Cherche sur internet et peut-être un package R qui réponde à ta question »._

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (justesse des données)

## Harnais

- **Peut (périmètre) :** `R/placettes.R` (RU), `R/hydrique.R` (nouveau), leurs tests, `inst/extdata/` (extraits sous licence ouverte + `SOURCES.md`, dont le dictionnaire IFN des codes de texture), `DESCRIPTION` (Suggests : `biljouR` via `Remotes`, `soiltexture`, `euptf2`), `NAMESPACE`, `man/`, `docs/referentiels.md` (§ nouveau : dictionnaire IFN, SAFRAN, euptf2).
- **Câblé :** pas de `main` ; journal en ajout seul ; `assert_no_fine_extract_on_ifn()` (SAFRAN 8 km = maille large, croisable avec l'IFN).
- **Ne doit pas :** inventer un code ou une classe ; toucher à `_targets.R` (mission 016).

## Attendus

1. Dictionnaire des codes `TEXT1`/`TEXT2` lu dans l'archive IFN (fichier de métadonnées), écrit dans `docs/referentiels.md` avec la commande ; triangle de référence des classes IFN.
2. `texture_to_psd(code)` : pourcentages représentatifs de la classe (centre du polygone, `soiltexture`).
3. `ru_from_texture()` : eau disponible par `euptf2` × épaisseur × (1 − cailloux) ; contre-vérification par Bruand (`ru_coefficients`) : écart rendu par placette ; `ru_verifie = TRUE` seulement si la chaîne est entièrement sourcée.
4. `hydric_stress(ru, safran, ...)` : appel `biljouR`, indice Is et jours de stress, par placette (maille SAFRAN) et sur grille ; repli sur la RU si SAFRAN ou biljouR absent, signalé.
5. Chiffres sur les 100 placettes IFN réelles : RU (euptf2 contre Bruand), Is, corrélation avec l'humidité bioindiquée (Tichý `humidite`, mission 015).

## Valeur provisoire (chiffre, réglage)

Paramètres BILJOU par défaut (LAI, profondeur d'enracinement) : provisoires, mesurés par comparaison à l'humidité bioindiquée ; gel avant la phase 1.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 015 (intégrée). Précède 016. **Ordre de fusion :** 019 → 016.

## Tests

Un test par fonction, sans réseau (extrait SAFRAN d'une maille en `inst/extdata` si licence ouverte, sinon `synth_`).

## Terrain

Échantillon pour Pascal : 5 placettes, RU et Is calculés, à confronter à ce qu'il sait de ces sols.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
