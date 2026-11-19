# Comparaison de la carte des 225 dalles avec CarHab 68 (mission 031)

**Ce que ce document dit : sur l'emprise test de D11, nos gradients trophique et hydrique ne
reproduisent pas, cellule à cellule, les paramètres d'acidité et d'humidité édaphiques de CarHab
68. Ce qu'il ne dit pas : que notre carte soit juste ou fausse.** CarHab est une carte
**prédictive** (§ 26.2 de `docs/referentiels.md`), pas une vérité terrain ; les relevés GNSS
(mission 029) restent l'arbitre.

Code : `R/carhab.R` (fonctions, tests `tests/testthat/test-carhab.R`) et
`inst/scripts/comparaison_carhab.R` (chaîne complète, 7 à 8 minutes, dont le bootstrap).
Sorties : `data/sorties/D11/comparaison_carhab/` (hors dépôt).

## 1. Données comparées

- **Nos gradients** : `gradients.tif` du run 018 (225 dalles, grille de 20 m, EPSG:2154, emprise
  `x 1 007 000-1 022 000`, `y 6 790 000-6 805 000`), couches `trophic` et `hydric` (hydrique =
  l'opposé de l'indice de stress : plus grand = plus humide). Masque : cellules forestières de
  notre carte (hauteur de canopée > 5 m, seuil provisoire de la mission 016).
- **CarHab** : WFS Géoplateforme, type `Carhab_habitat:habitats_carhab`, `occupation = 'foret'`,
  **3 103 polygones** (lus en pages de 500, cache hors dépôt ; § 26.6 de `referentiels.md`).
- **Recodage ordinal** (provisoire, § 26.4 ; décisions du 2026-11-18) : acidité `très acide` 1,
  `légèrement acide` 2, `neutre` 3, `basique` 4 (`hyperbasique` 5 absent de l'emprise) ; `neutre`
  est une classe propre, jamais fusionnée avec `basique`. Humidité `assez sec` 1, `mésique` 2,
  `légèrement humide` 3, `humide à nappe circulante` 4, `détrempé à nappe stagnante` 5 : **ordre
  provisoire, il mêle réserve en eau et engorgement.**
- **Grille à grille** : chaque polygone est rasterisé sur notre grille de 20 m par le centre de
  la cellule (`terra::rasterize`, `touches = FALSE`) ; un polygone à cheval sur l'emprise est donc
  découpé par la grille. Aucune extraction aux placettes IFN : la règle des 700 m n'est pas
  concernée.

## 2. Domaine de comparaison (cellules de 20 m ; 1 cellule = 0,04 ha)

| | Cellules | Hectares |
|---|---|---|
| Forêt chez nous (trophique) | 395 887 | 15 835 |
| Forêt chez nous (hydrique) | 394 055 | 15 762 |
| Forêt CarHab (rasterisée) | 418 220 | 16 729 |
| Forêt des deux côtés (trophique) | 383 417 | 15 337 |
| Forêt des deux côtés (hydrique) | 381 662 | 15 266 |
| Écartées : hors zone d'applicabilité (`aoa_trophic = 0`) | 101 267 | 4 051 |
| **Retenues, trophique** | **282 150** | **11 286** |
| **Retenues, hydrique** | **381 662** | **15 266** |

La zone d'applicabilité n'existe dans les sorties que pour le trophique (`incertitude.tif`,
couche `aoa_trophic`) : elle est appliquée à lui seul. Le trophique est aussi donné **sans** cette
exclusion (lignes « sans AOA »). Le désaccord de masque forestier n'est pas analysé ici (il est
compté : 395 887 contre 418 220 cellules, soit environ 5 % de plus du côté CarHab).

## 3. Méthodes

**Spearman** (rang) entre notre gradient continu et le rang CarHab, sur le domaine retenu. Les
cellules voisines se ressemblent : un intervalle calculé comme si elles étaient indépendantes
serait trop étroit de plusieurs ordres de grandeur. Deux intervalles, le second contrôlant le
premier :

1. **Bootstrap par blocs** : blocs carrés de 1 000 m (Lambert-93, environ 215 blocs), tirés avec
   remise (500 tirages, graine 1), Spearman recalculé sur les cellules des blocs tirés,
   intervalle = quantiles 2,5 % et 97,5 %. Le côté du bloc (1 km) est un choix **non étalonné** à
   la portée d'autocorrélation réelle ; un bloc plus grand élargirait l'intervalle.
2. **Sous-échantillon espacé** : une cellule tous les 500 m (en x et en y), soit environ 720 à
   840 cellules, intervalle de Bonett-Wright (`se = sqrt((1 + rho²/2)/(n - 3))` sur la
   transformée de Fisher). Valable si 500 m suffit à rendre les cellules quasi indépendantes
   (non vérifié).

**Kappa pondéré** (écrit dans `carhab_kappa()`, aucun paquet de kappa n'est installé ; testé sur
des valeurs calculées à la main) après découpage de notre gradient en autant de classes que
CarHab, **aux mêmes parts de surface** que les modalités CarHab du domaine (quantiles de notre
gradient), pour ne pas dépendre de nos seuils de types. Poids linéaires (kappa de référence) et
quadratiques ; accord exact et accord à une classe près.

**Matrice de confusion** : notre classe (lignes) contre modalité CarHab (colonnes), en cellules
de 20 m.

## 4. Chiffres

| Gradient | Cellules | Spearman | IC blocs 95 % | Spearman espacé [IC 95 %] (n) | Kappa linéaire | Kappa quadratique | Accord exact | À une classe |
|---|---|---|---|---|---|---|---|---|
| Trophique (zone d'applicabilité) | 282 150 | **0,04** | -0,04 ; 0,13 | 0,01 [-0,07 ; 0,08] (719) | **-0,04** | 0,03 | 26,7 % | 80,9 % |
| Trophique (sans exclusion) | 383 417 | 0,02 | -0,06 ; 0,10 | 0,00 [-0,07 ; 0,07] (838) | -0,04 | 0,00 | 29,4 % | 80,6 % |
| Hydrique | 381 662 | **-0,02** | -0,11 ; 0,08 | 0,08 [0,02 ; 0,15] (837) | **-0,11** | -0,14 | 33,5 % | 50,8 % |

**Lecture, sans l'arranger.** Sur le trophique, la concordance est nulle : le Spearman est
indiscernable de zéro avec les deux méthodes, le kappa est à l'aléa. C'est ce que le run annonçait
(R² de validation croisée proche de 0 : le modèle trophique ne prédit pas mieux que la moyenne).
Sur l'hydrique, avec l'ordre provisoire conservé, la concordance est aussi nulle, et le kappa est
**négatif** (moins bon que le hasard) : notre classe la plus sèche tombe aussi souvent sur
« humide à nappe circulante » (38 727 cellules) que sur « assez sec » (37 559), et notre quatrième
classe (sur cinq) tombe surtout sur « mésique » (79 745). Le Spearman espacé (0,08, intervalle au-dessus
de zéro) ne tient pas contre les blocs (intervalle à cheval sur zéro) : à ne pas lire comme un
signal.

### Matrices de confusion (cellules de 20 m ; zone d'applicabilité pour le trophique)

Trophique (4 modalités CarHab ; notre classe 4 est **vide**, voir limites) :

| Notre classe | très acide | légèrement acide | neutre | basique |
|---|---|---|---|---|
| 1 (la plus acide) | 61 817 | 58 491 | 38 376 | 1 019 |
| 2 | 20 557 | 13 264 | 25 534 | 68 |
| 3 | 14 302 | 44 935 | 152 | 3 635 |
| 4 | 0 | 0 | 0 | 0 |

Hydrique (ordre provisoire) :

| Notre classe | assez sec | mésique | légèrement humide | humide à nappe circulante | détrempé à nappe stagnante |
|---|---|---|---|---|---|
| 1 (la plus sèche) | 37 559 | 16 761 | 100 | 38 727 | 0 |
| 2 | 41 941 | 83 140 | 2 088 | 55 128 | 100 |
| 3 | 616 | 2 505 | 38 | 820 | 0 |
| 4 | 13 029 | 79 745 | 1 753 | 7 212 | 150 |
| 5 | 2 | 246 | 0 | 2 | 0 |

La matrice du trophique sans exclusion et les médianes et quartiles par modalité sont dans
`matrice_confusion_trophic_sans_aoa.csv` et `par_modalite_*.csv`.

### Contrôle d'alignement

Pour exclure une erreur de superposition (x/y, décalage de grille), notre axe bioclimatique est
comparé à l'**étage de végétation** CarHab (collinéen 1, montagnard 2, subalpin 3) : Spearman
**-0,59** sur 383 417 cellules (médiane de notre axe 1,43 en collinéen, -0,70 en montagnard). Le
signe est négatif parce que notre axe croît avec la chaleur ; ce qui compte ici est la valeur
absolue : les deux cartes sont bien superposées. L'absence de concordance sur le trophique et
l'hydrique n'est donc pas un défaut de grille. (Cette valeur n'est pas un résultat demandé par la
mission : c'est un contrôle ; son intervalle n'est pas calculé.)

### Sensibilité de l'ordre hydrique (non retenue, à trancher)

L'ordre hydrique mêle réserve en eau et engorgement. Deux lectures, sur les mêmes cellules, après
coup (sans bootstrap, intervalle du sous-échantillon espacé seulement) :

| Lecture | Cellules | Spearman | Spearman espacé [IC 95 %] |
|---|---|---|---|
| Sec → humide seul : `assez sec`, `mésique`, `légèrement humide` (modalités 1 à 3) | 279 523 | **0,43** | 0,40 [0,34 ; 0,46] |
| Engorgement : `humide à nappe circulante` et `détrempé` contre les autres | 381 662 | **-0,28** | -0,22 [-0,28 ; -0,15] |

Notre gradient hydrique suit donc un peu la réserve en eau (0,43 quand l'engorgement est écarté)
et **va dans le sens opposé** de l'engorgement de CarHab (-0,28) : les cellules « à nappe » de
CarHab sont, chez nous, plutôt sèches (médiane -41 contre -28 en « mésique »). Cette lecture est
choisie **après** avoir vu les données et écarte 27 % du domaine : c'est une piste pour décider de
l'ordre, pas un résultat. L'ordre reste provisoire (décision de Pascal).

## 5. Figures (`data/sorties/D11/comparaison_carhab/`)

- `carte_accord_trophic.png`, `carte_accord_hydric.png` : accord exact, à une classe, deux classes
  ou plus ;
- `carte_desaccord_trophic.png`, `carte_desaccord_hydric.png` : écart signé (notre classe moins
  classe CarHab) ; rasters `ecart_classes_*.tif` (Lambert-93, 20 m, pour QGIS) ;
- `distribution_gradient_par_modalite.png` : notre gradient par modalité CarHab (boîtes à
  moustaches) ;
- `zoom_secteur_trophic.png`, `zoom_secteur_hydric.png` : le secteur de contrôle (§ 7).

## 6. Limites, et ce que la comparaison ne permet pas de dire

- **CarHab n'est pas indépendant de notre carte.** Les deux s'appuient sur le RGE ALTI,
  BD TOPAGE, la géologie BRGM et un fond de sol à maille large (§ 26.2, écart 27). Un accord
  n'aurait pas prouvé que nos cartes sont justes ; un désaccord ne prouve pas non plus qu'elles
  sont fausses.
- **CarHab est une carte prédictive** à 1/25 000, polygones d'au moins 0,5 ha, « information de
  potentialité » selon le ministère, « pas adaptée à des analyses fines ». Une comparaison de
  grille à grille à 20 m compare un polygone à des cellules plus petites que sa précision.
- **Les concepts ne sont pas les mêmes** : acidité édaphique contre notre axe trophique (qui ne
  se réduit pas à l'acidité) ; l'ordre de l'humidité est provisoire et mêle réserve en eau et
  engorgement ; les modalités extrêmes sont rares (`basique` 1,7 % du domaine, `détrempé` 0,07 %,
  250 cellules : le kappa à 5 classes repose sur très peu de cellules).
- **Notre gradient trophique a des égalités massives** : 55 valeurs distinctes, 18,2 % des
  cellules à la valeur maximale (5,178). Les quantiles ne peuvent pas séparer ces cellules : la
  quatrième classe (celle de CarHab « basique », 1,7 %) est **vide**, et les cellules au maximum
  sont toutes en classe 3. Le kappa trophique porte donc, en pratique, sur trois classes. Le
  gradient hydrique n'a pas ce défaut.
- **Notre carte hydrique est en blocs** : sur la carte d'accord, de grands aplats rectilignes
  (par exemple une limite verticale vers x 1 010 600) suivent des mailles, pas la topographie.
  Les entrées hydriques venues d'une maille à grande échelle (réserve utile en `ru_maille`, climat
  par maille SAFRAN de 8 km) en sont l'explication probable ; **non vérifié**, à examiner dans la
  mission qui reprendra le calcul hydrique.
- **La zone d'applicabilité du trophique** exclut 101 267 cellules (26 % du domaine commun) ;
  la carte de désaccord montre des bandes d'environ 1 km sans donnée, rectilignes, qui ne
  suivent pas non plus le terrain. Même remarque : à examiner.
- **Le masque forestier est le nôtre** (hauteur de canopée > 5 m), seuil provisoire.
- **Autocorrélation** : le côté de bloc (1 000 m) et le pas du sous-échantillon (500 m) ne sont
  pas étalonnés sur la portée réelle (voir § 3).
- Le contrôle « types regroupés » du § 26.5 (point 4) n'est **pas fait** : il n'était pas dans les
  attendus de la mission.

## 7. Secteur à regarder (Pascal)

**Plantation forestière** (polygone CarHab `6057`, « neutre », montagnard, mésique, biotope
`338802`, environ 30 ha) : **x 1 013 346-1 014 021, y 6 797 837-6 798 797** (Lambert-93, x = est,
y = nord) ; point de contrôle x 1 013 643, y 6 798 321. CarHab y met la classe « neutre » ; **notre
gradient trophique y est dans notre classe la plus acide** sur tout le secteur
(`zoom_secteur_trophic.png`). À regarder sur place : espèces indicatrices de richesse (Aspérule
odorante, Mercuriale pérenne) contre Luzule blanchâtre et Myrtille, et la roche (massif
cristallin). Le zoom `zoom_secteur_hydric.png` est sur la même fenêtre
(x 1 013 000-1 015 000, y 6 797 000-6 799 000).
