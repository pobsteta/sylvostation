# Mission 025 — grille de 20 m alignée pour Sentinel-2

## Mission

**En une phrase (quoi, et pourquoi) :** passer la grille de sortie à 20 m, en Lambert-93,
avec une origine sur des multiples de 20 m, et rendre le code indépendant de la résolution
(noms de couches et de fichiers, masque forestier), pour que les bandes Sentinel-2 à 20 m
se rééchantillonnent sur notre grille sans changement d'échelle (décision de Pascal du
2026-11-18).

**Redite par l'agent :** passer la grille de sortie à 20 m en Lambert-93 (origine sur des multiples de 20 m) et rendre le code indépendant de la résolution (noms de couches et de fichiers, textes, masque forestier), pour que les bandes Sentinel-2 à 20 m se rééchantillonnent sur notre grille.

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `resolution_m` de `config.yml`, `build_grid()`, `real_grid()` ; noms figés « 25m » dans `R/hydrique.R`, `R/pipeline_reel.R`, `R/utils.R`, `_targets.R`, `inst/rapport/` | |
| Les moyens ? | oui : tests, run hors ligne | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : « oui on part sur 20m aligné sentinel 2 »._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `config.yml` (`resolution_m: 20`, clé d'alignement si utile), `R/config.R`, `R/grille*.R` ou la fonction de grille existante, `R/hydrique.R`, `R/pipeline_reel.R`, `R/utils.R` (FINE_VARIABLES), `R/terrain.R`, `R/sorties.R`, `_targets.R`, `inst/rapport/`, tests, `docs/pipeline.md`, `docs/referentiels.md` (§ Sentinel-2 : grille, CRS des tuiles, bandes à 20 m, sources vérifiées), `docs/adr/0007-grille-20m-sentinel2.md` (FRANCE).
- **Câblé :** EPSG:2154 partout (pas d'UTM) ; seuil de précision d'extraction fine `loc_precision_m` ≤ 25 m inchangé (règle de CLAUDE.md) ; mode démo cohérent ; noms de sorties sans résolution figée.
- **Ne doit pas :** télécharger Sentinel-2 ; changer les méthodes de calcul.

## Attendus

1. Grille : origine (xmin, ymax) arrondie au multiple de `resolution_m` inférieur/supérieur ; un test : un point connu (x = est, y = nord, EPSG:2154) tombe dans la bonne cellule de 20 m, et les bords de la grille sont des multiples de 20.
2. Noms indépendants de la résolution : `hydrique_25m.tif` → `hydrique.tif` (ou `hydrique_<res>m.tif` calculé), `grad_hydrique_25m` → nom générique inscrit dans FINE_VARIABLES ; anciens noms cités dans NEWS.md.
3. Masque forestier : « au moins la moitié de la cellule » suit `resolution_m` ; test.
4. Toutes les mentions « 25 m » du code, de la doc et du rapport qui désignent la cellule passent par `resolution_m` ; celles qui désignent le seuil de précision restent.
5. ADR 0007 : 20 m alignée en Lambert-93 plutôt qu'UTM (pixel à pixel impossible en EPSG:2154 ; rééchantillonnage de S2 sur la grille), prix et réversibilité.
6. Coûts mesurés à 20 m (run hors ligne, `r.sun` extrapolé à 225 dalles).

## Valeur provisoire (chiffre, réglage)

`resolution_m: 20` provisoire, à geler avant la phase 1.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 022 (intégrée d'abord : `_targets.R`, `inst/rapport/`). **Précède :** la phase 225 dalles de 018, et 023.

## Tests

`.claude/test-command` vert ; run hors ligne vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
