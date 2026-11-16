# Mission 003 — emprise, grille et LiDAR HD (incrément 1)

## Mission

**En une phrase (quoi, et pourquoi) :** coder `get_ser()`, `build_grid()`, `list_tiles()` et `run_lasr()` puis les exécuter sur 4 dalles réelles du massif test, pour régler la chaîne LiDAR et chiffrer temps et stockage avant toute autre étape (brief technique, § 8, premier incrément).

**Redite par l'agent :** _à compléter par l'agent avant d'agir._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : brief technique § 4 étape 1, § 5 ; `docs/referentiels.md` (couches SER, tableau d'assemblage, MNT IGN, signatures lasR/lidR) | |
| A-t-il les moyens ? | oui : R, sf, terra, lidR, lasR si installés ; réseau vers data.geopf.fr ; 30 Go de disque | |

**Temps de la main :** appuyer (branche de worktree, relecteur, intégration par l'orchestrateur — ADR 0002).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16) : Pascal ne remplit pas cette rubrique._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** les étapes des autres missions ; toucher à `docs/` (sauf fichier nommé ci-dessous), `pilotage/`, `.claude/`, `CLAUDE.md`.

## Harnais

- **Peut :** `R/emprise.R`, `R/lidar.R`, leurs tests, `inst/extdata/` (une dalle LAZ réduite ≤ 2 Mo, extraite d'une vraie dalle, et une SER simplifiée, avec leur source dans `inst/extdata/SOURCES.md`), un script `inst/scripts/increment1.R` qui exécute la chaîne sur 4 dalles réelles du massif test et écrit un compte rendu `docs/increment1.md` (dalles, dates de vol, temps, volumes, écart MNT recalculé vs MNT IGN sur au moins une dalle).
- **Ne doit pas :** inventer une URL, une couche, une colonne ou une signature : prendre `docs/referentiels.md`, sinon écrire « à vérifier » dans le code (commentaire) et dans le rendu ; télécharger dans les tests ; ajouter une dépendance hors `DESCRIPTION` sans le dire (Suggests + `requireNamespace()` + `skip_if_not_installed()`).
- **Sources autorisées :** `docs/brief-technique.md`, `docs/spec.md`, `docs/referentiels.md`, `docs/adr/`, `CLAUDE.md`, la doc des paquets installés.

## Contenu attendu

- `get_ser(ser_code, buffer_m, source = c("wfs", "file"), path = NULL)` : contour de la SER (couche vérifiée en 001), tampon, EPSG:2154. Mode `file` pour les tests.
- `build_grid(emprise, res)` : `SpatRaster` vide aligné sur des multiples de `res` en Lambert-93.
- `list_tiles(emprise)` : tableau d'assemblage LiDAR HD (WFS vérifié en 001) → `sf` avec nom, URL, date de vol.
- `run_lasr(laz_files, out_dir, res = 1, ncores, buffer)` : MNT (classes 2, 9, 66) et MHC à 1 m en un passage `lasR` ; repli `lidR` si `lasR` absent ; traitement en flux (téléchargement, calcul, suppression du LAZ, option `keep_laz = FALSE`).
- `point_lidar_metrics(ctg_or_files, points, radius = 15)` : métriques ponctuelles (lidR) ; **appelle `assert_no_fine_extract_on_ifn()`**.
- Test : un point connu en Lambert-93 tombe dans la bonne cellule de `build_grid()` ; `point_lidar_metrics()` refuse des placettes IFN.

Conventions : `CLAUDE.md` (EPSG:2154, `snake_case`, roxygen2 en français, une fonction par tâche, pas d'effet de bord hors `write_*`, jeux synthétiques `synth_` + `synthetic = TRUE`).

## Valeur provisoire (chiffre, réglage)

- **Valeur provisoire :** 4 dalles (brief) ; `buffer = 20` m pour lasR (esquisse du brief) ; `ncores = 3`. Mesurés par le script d'incrément 1.
- **Mesurée par :** cette mission quand c'est possible, sinon le bilan ; **Gel :** avant la phase 1 (SER vosgiennes).

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 001 (référentiels) et 002 (squelette) intégrées.
- **CI rouge attendue :** aucune.

## Tests

`devtools::test()` vert et `R CMD check --no-manual` sans erreur ni warning ; tests de la mission sans réseau ; règle bloquante testée là où une extraction a lieu.

## Terrain

- **Échantillon que Pascal vérifiera :** le MNT et le MHC d'une dalle (GeoTIFF dans `data/`, non versionné) et `docs/increment1.md`.

## Qui veille, qui tranche

- **Relecteur :** `relecteur`, puis l'orchestrateur par délégation. Critère d'arrêt : 3 allers-retours.
- **Qui tranche :** Pascal (délégué à l'orchestrateur).

## Comment saura-t-on que ça marche ?

Les tests passent, et le rendu dit ce qui a tourné sur données réelles et ce qui ne l'a pas fait.

## Compléments (mission 011, questions tranchées par délégation)

Dans `tests/testthat/test-acceptation-regle-700m.R`, remplacer les deux `skip()` par les décisions suivantes, et adapter `R/utils.R` si besoin :
1. Une colonne `source = "ifn"` seule (sans attribut, même avec `loc_precision_m = 10`) **bloque** (comportement actuel, à figer par un test).
2. Le préfixe large est **sensible à la casse** : seul `coarse_` en minuscules déclare une variable large ; `COARSE_climat` est traité comme fin et **bloque** sur des points imprécis (changement de `R/utils.R` nécessaire : aujourd'hui il passe).
3. `variables = character(0)` **passe** (rien n'est extrait) ; `NULL` aussi.

## Compléments (mission 001, docs/referentiels.md)

- SER : pas de WFS ; source vecteur `ser_l93.zip` (86 SER) et `ser_ar_l93.zip` (5 SER d'alluvions, couche superposée) sur inventaire-forestier.ign.fr (URL exactes au § 1 de docs/referentiels.md), champs `codeser`, `NomSER`, encodage WINDOWS-1252. `get_ser()` lit le fichier (téléchargé une fois dans `data_dir`), avec option `alluvial = TRUE` pour la seconde couche. Test avec un extrait réduit (une ou deux SER simplifiées, ≤ 200 Ko, licence au § 11).
- LiDAR HD : couche `IGNF_LIDAR-HD_METADONNEE:metadata`, identifiant `coordonnees_nw`, URL dans `url_npl`, filtrer avec `CQL_FILTER=WITHIN(...)` (le BBOX déborde) ; dates de vol 2022-01-12 à 2022-04-21 ; 225 dalles dans l'emprise, 45,7 Go en tout, environ 200 Mo par dalle : l'incrément 1 sur 4 dalles télécharge environ 1 Go, en flux, LAZ supprimés après calcul.
- MNT IGN de contrôle : champ `url_mnt` de la métadonnée.
- Signatures lasR 0.21.4 et lidR 4.3.3 relevées au § 10.
