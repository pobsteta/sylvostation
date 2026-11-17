# Incrément 1 : chaîne LiDAR HD sur 4 dalles réelles du massif test

Mission 003. Compte rendu **écrit par `inst/scripts/increment1.R`** le 2026-11-16 ; les chiffres ci-dessous sont mesurés, pas estimés, sauf les lignes marquées « extrapolation ».

## Ce qui a tourné

- Emprise : `1014000 6792000 1016000 6794000` (EPSG:2154, xmin ymin xmax ymax), carré 2 x 2 de dalles contiguës du massif test (relief : voir les altitudes ci-dessous).
- `list_tiles()` (WFS `IGNF_LIDAR-HD_METADONNEE:metadata`, `CQL_FILTER=WITHIN`) : 4 dalles en 0.9 s.
- `run_lasr()` : téléchargement des URL `url_npl` (COPC LAZ), calcul `lasR` (triangulation des classes 2, 9, 66 ; MNT et MHC à 1 m ; 3 cœurs, `buffer = 20`), LAZ supprimés après calcul (`keep_laz = FALSE`) : 0 LAZ restant dans `laz/`.
- Contrôle : MNT IGN 0,5 m (`url_mnt`, WMS) téléchargé pour les 4 dalles, ré-échantillonné
  (bilinéaire) sur la grille 1 m recalculée, écarts = recalculé - IGN.

## Dalles et dates de vol

| dalle | date_debut | date_fin | points | url_npl |
|---|---|---|---|---|
| 1014-6793 | 2022-01-13 | 2022-04-21 | 30 976 520 | LHD_FXX_1014_6793_PTS_LAMB93_IGN69.copc.laz |
| 1014-6794 | 2022-01-13 | 2022-04-21 | 33 820 890 | LHD_FXX_1014_6794_PTS_LAMB93_IGN69.copc.laz |
| 1015-6793 | 2022-01-13 | 2022-01-13 | 26 952 795 | LHD_FXX_1015_6793_PTS_LAMB93_IGN69.copc.laz |
| 1015-6794 | 2022-01-13 | 2022-01-13 | 37 212 793 | LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz |

## Temps et volumes (mesurés)

| etape | duree_s | par_dalle_s |
|---|---|---|
| Liste des dalles (WFS) | 1 |  |
| Téléchargement des 4 LAZ | 45 | 11 |
| Calcul lasR (MNT + MHC) | 384 | 96 |
| Téléchargement des 4 MNT IGN de contrôle | 32 | 8 |
| Total du script | 466 |  |

- LAZ téléchargés : 753.3 Mo (188.3 Mo par dalle) ; débit 16.9 Mo/s.
- Pic de disque temporaire : 753.3 Mo (les 4 LAZ présents ensemble pour que le tampon de 20 m voie les voisines), puis 0 Mo.
- Produits gardés : 19.5 Mo pour 4 MNT + 4 MHC GeoTIFF float32 compressés DEFLATE (4.9 Mo par dalle, MNT + MHC).
- Mémoire résidente maximale du processus R (VmHWM, lasR compris) : 5.0 Gio.
- Disque libre dans le dossier de travail : 28.6 Go avant, 28.6 Go après.

### Extrapolation aux 225 dalles de l'emprise (calcul, pas mesure)

- Calcul lasR : 6.0 h à 3 cœurs (96 s par dalle mesurées) ; la durée dépend du nombre de points par dalle (de 15,7 à 65,8 millions de points, de 62 à 359 Mo, docs/referentiels.md § 13).
- Téléchargement : 45.1 min pour 45,7 Go au débit mesuré.
- Produits : 1.1 Go pour 225 MNT + 225 MHC à 1 m.

## Produits

| dalle | vol | cellules | mnt_na | mnt_min_max | mhc_moy_max | mhc_na | mhc_min | mhc_neg | mnt_mo | mhc_mo |
|---|---|---|---|---|---|---|---|---|---|---|
| 1014-6793 | 2022-01-13 -> 2022-04-21 | 1 000 000 | 0.00 % | 287.7 ; 534.2 | 11.9 ; 47.4 | 0.41 % | -1.28 | 0.000 % | 2.1 | 2.6 |
| 1014-6794 | 2022-01-13 -> 2022-04-21 | 1 000 000 | 0.00 % | 358.8 ; 620.7 | 18.0 ; 54.6 | 0.03 % | 0.00 | 0.000 % | 2.2 | 2.8 |
| 1015-6793 | 2022-01-13 -> 2022-01-13 | 1 000 000 | 0.00 % | 272.6 ; 553.3 | 10.1 ; 60.9 | 0.09 % | -0.03 | 0.000 % | 2.1 | 2.7 |
| 1015-6794 | 2022-01-13 -> 2022-01-13 | 1 000 000 | 0.00 % | 399.1 ; 652.0 | 16.0 ; 41.7 | 0.03 % | 0.00 | 0.000 % | 2.1 | 2.8 |

Colonnes : `mnt_na` = part des cellules sans valeur ; `mnt_min_max` en m (IGN69) ; `mhc_moy_max` en m ; 
`mhc_na` = part des cellules du MHC sans valeur (aucun point retenu dans la cellule de 1 m) ; `mhc_min` = minimum en m ; `mhc_neg` = part des cellules < 0 (bruit sous le MNT, non écrêté). Le minimum de -1,28 m (dalle 1014-6793) concerne quelques cellules : la part négative, affichée « 0.00 % » dans une version antérieure du tableau, est un effet d'arrondi (0,000 % à trois décimales, ce n'est pas zéro cellule).

Calcul de toute l'emprise (décision provisoire, par délégation) : par blocs de 3 x 3 dalles contiguës (environ 1,7 Go de LAZ au pic, le tampon de 20 m voit les voisines du bloc). Aucune fonction d'enchaînement n'est écrite dans cette mission : `run_lasr()` est appelée bloc par bloc.

## Écart MNT recalculé (1 m) moins MNT IGN (0,5 m)

| dalle | n_cellules | ecart_moyen_m | ecart_type_m | mediane_m | part_abs_sup_05 | p99_abs_m |
|---|---|---|---|---|---|---|
| 1014-6793 | 1 000 000 | -0.020 | 0.050 | -0.019 | 0.08 % | 0.16 |
| 1014-6794 | 999 997 | -0.014 | 0.046 | -0.012 | 0.01 % | 0.15 |
| 1015-6793 | 1 000 000 | -0.019 | 0.046 | -0.017 | 0.03 % | 0.16 |
| 1015-6794 | 1 000 000 | -0.015 | 0.037 | -0.013 | 0.00 % | 0.12 |

Ensemble des 4 dalles (3 999 997 cellules) : écart moyen -0.017 m ; part de |écart| > 0,5 m : 0.03 %.

Par classe de pente du MNT recalculé (degrés, voisinage 8) :

| dalle | pente_deg | cellules | ecart_moyen_m | ecart_type_m | part_abs_sup_05 |
|---|---|---|---|---|---|
| 1014-6793 | < 10 | 286 419 | -0.026 | 0.043 | 0.14 % |
| 1014-6793 | 10-25 | 342 899 | -0.020 | 0.040 | 0.01 % |
| 1014-6793 | > 25 | 366 686 | -0.015 | 0.061 | 0.09 % |
| 1014-6794 | < 10 |  69 742 | -0.021 | 0.032 | 0.00 % |
| 1014-6794 | 10-25 | 406 825 | -0.014 | 0.037 | 0.00 % |
| 1014-6794 | > 25 | 519 434 | -0.014 | 0.053 | 0.01 % |
| 1015-6793 | < 10 | 226 615 | -0.021 | 0.028 | 0.01 % |
| 1015-6793 | 10-25 | 520 978 | -0.020 | 0.037 | 0.00 % |
| 1015-6793 | > 25 | 248 411 | -0.015 | 0.069 | 0.11 % |
| 1015-6794 | < 10 |  68 581 | -0.020 | 0.029 | 0.00 % |
| 1015-6794 | 10-25 | 708 907 | -0.015 | 0.034 | 0.00 % |
| 1015-6794 | > 25 | 218 516 | -0.013 | 0.045 | 0.00 % |

## Limites et points « à vérifier »

- Le MNT IGN est un produit à 0,5 m dont la méthode d'interpolation et les classes retenues ne sont 
  pas décrites dans `docs/referentiels.md` : à vérifier. Un écart n'est donc pas une erreur de l'un des deux.
- Le MHC exclut les classes 65 et 66 (filtre `Classification %out% 65 66`) : la liste complète des classes 
  LiDAR HD n'est pas dans `docs/referentiels.md` ; à vérifier.
- Aucune dalle du carré n'est volée entièrement en avril : deux sont volées le 2022-01-13, deux entre le 2022-01-13 et le 2022-04-21 (à cheval) ; le choix de dalles « pur avril » n'a pas été fait (le carré 2 x 2 retenu est celui qui contient la frontière janvier / avril du tableau d'assemblage).
- Les dalles de la mission `22LHDVosgesRF` sont volées entre le 2022-01-12 et le 2022-04-21 : 
  la date de vol est à garder comme covariable (brief technique, § 5).
- Le MHC est la hauteur maximale par cellule de 1 m, sans lissage ni remplissage des trous.
- Le repli `lidR` n'est testé que sur l'extrait de 80 m (tests unitaires), pas sur ces 4 dalles.

## Fichiers gardés (hors dépôt, `data/` est ignoré par git)

- `data/increment1/sorties/mnt_<dalle>.tif` et `mhc_<dalle>.tif` (EPSG:2154, 1 m, rognés à l'emprise de 1 km de la dalle) ; MNT IGN de contrôle dans `data/increment1/ign_mnt/`. Dossier par défaut de `inst/scripts/increment1.R` (`<data_dir>/increment1`). Les chiffres ont été mesurés avec un dossier de travail dans `/tmp`, puis les GeoTIFF ont été recopiés sans relancer le calcul.
