# Mission 039 — bioclimat et réserve utile plus fins : SAFRAN corrigé du relief, exposition, bilan latéral, RU SoilGrids

## Mission

**En une phrase (quoi, et pourquoi) :** rendre au bioclimat et à la réserve utile l'effet du
relief et des sols, en corrigeant la température SAFRAN par l'altitude (meteoland), en ajoutant
exposition et bilan latéral à la cellule et en tirant la RU des textures SoilGrids. Aujourd'hui,
le bioclimat du run réel 035 est un dégradé lisse et la RU forme des rectangles de 8 km (mailles
SAFRAN), loin des cartes 11 à 14 de Piedallu et al. (2006).

**Redite par l'agent :** _à compléter par l'agent._

## Sources

- Comparatif des jeux climatiques (acquereur, 2026-11-20) :
  `/tmp/claude-1000/-home-pascal-dev-sylvostation/3d37db41-ab41-4386-adda-0d0c87e7d32a/scratchpad/acquisition-climat.md`.
  SAFRAN gardé (RMSE journalier de la température d'environ 0,6 °C, Vidal 2010,
  doi 10.1002/joc.2003, erreur liée à l'altitude d'environ 0,5 °C par 100 m). E-OBS écarté
  (environ 11 km, licence non commerciale). CHELSA-daily V2.1 (1 km, CC0, ERA5) en contrôle seulement.
- nemeton (lecture seule, ne rien y modifier) : `nemeton/R/meteoland_grid.R:329`
  (`meteoland_daily_grid()`, mailles SAFRAN en pseudo-stations, altitude lue au MNT, méthode
  de Thornton 1997, calibration désactivée), `nemeton/R/soil_water.R:83, 182`
  (RU SoilGrids, Saxton et Rawls 2006), `nemeton/R/load_biljou.R` (accès GéoSAS).
- biljouR 0.1.0 (pobsteta/biljouR, GPL-3) : sylvostation réutilise ses composantes dans
  `.biljou_cols()` (R/hydrique.R) ; un sol à une couche, aucune correction de température.
- Piedallu et al. (2006), HAL `hal-00835906`, copie locale en lecture seule (**ne pas copier
  dans le dépôt**) : `/home/pascal/dev/nemetonplateforme/docs/Piedallu_al_2006_etude_CAS.pdf`,
  tableaux 12 (bioclimat), 18 (RU), 20 (bilan latéral).
- Plan de 034 (exposition et bilan latéral pour la carte seulement) : `pilotage/missions/034-predicteurs-piedallu.md`.

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | en partie : plan d'abord | plan rendu avant tout code |
| Les moyens ? | oui : meteoland 2.2.8 installé, MNT du pipeline, SoilGrids (035), store du run réel `.claude/worktrees/wt035run/_targets` (lecture seule) | |

**Temps de la main :** donner. **Degré :** l'orchestrateur tranche après le plan (délégation totale).

## Ma réponse d'abord

_Décidé avec Pascal le 2026-11-20 (« Oui vas-y »)._ Périmètre :

1. **Température corrigée du relief** : SAFRAN journalier en pseudo-stations, interpolé par
   meteoland (Thornton 1997, avec l'altitude) sur la grille du MNT. Validation croisée entre
   mailles (laisser une maille de côté) contre l'interpolation bilinéaire actuelle et contre un
   gradient fixe (−0,55 °C par 100 m, Rolland 2003, « à vérifier » dans les Vosges).
   Altitude des pseudo-stations : à justifier (moyenne du MNT sur la maille ou centre).
   Contrôle indépendant : CHELSA, normales 1981-2010.
2. **Exposition et bilan latéral** à la cellule, pour la carte seulement. Formulation de
   Piedallu (tableau 20, −30 / 0 / +60 mm). Les coefficients ont été calibrés sur EcoPlant dans
   les Vosges : les reprendre tels quels est un choix à exposer au plan.
3. **RU tirée des sols** : textures SoilGrids par horizon jusqu'à la profondeur racinaire,
   fonction de pédotransfert euptf2 (déjà utilisée par `ru_from_texture`), plutôt que Saxton et
   Rawls. Comparaison chiffrée avec la RU des placettes IFN et avec la RU par maille actuelle.
4. **BILJOU** recalculé avec la température corrigée (ETP de Penman) et la nouvelle RU.
   Mesurer l'effet sur Istress et NJstress.
5. **Règle des 700 m** : aucune variable fine aux placettes IFN. Le bioclimat apprend sur une
   température agrégée au moins à 1 km (ou dans un disque de 700 m) et s'applique à la cellule.
   Le plan mesure le coût de ce changement d'échelle. La RU SoilGrids, à 250 m, doit être
   classée au regard de la règle avant tout croisement avec l'IFN (moyenne dans 700 m, comme le pH en 035).

Hors périmètre : E-OBS ; microclimf ; changement de source des précipitations (PRELIQ, PRENEI
et ETP de SAFRAN gardés) ; toute modification de nemeton ou de biljouR ; DIGITALIS et AURELHY
(licences non établies), sauf comme repères cités.

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (plan d'abord)

## Harnais

- **Peut (périmètre) :** au plan, lire et mesurer (scratchpad, store du run réel en lecture
  seule) ; après validation : `R/climat.R`, `R/hydrique.R`, `R/sols.R`, `R/terrain.R`,
  `R/pipeline_reel.R`, `R/utils.R` (`FINE_VARIABLES`, `COARSE_VARIABLES`), `_targets.R`,
  `config.yml`, `R/config.R`, `DESCRIPTION` (meteoland en Suggests si nécessaire), leurs tests,
  `docs/pipeline.md`, `docs/referentiels.md` (section datée, § 37).
- **Câblé :** règle des 700 m (toute variable dérivée du MNT fin entre dans `FINE_VARIABLES`) ;
  chaque formule et coefficient cité avec sa source et sa page, ou « à vérifier » ; R² du bioclimat
  et de l'hydrique avant et après, par blocs, aux deux tailles (cv_block_m et cv_block_sensibilite_m) ;
  aucun téléchargement dans les tests.
- **Ne doit pas :** toucher au worktree du run 018 ni à `wt035run`, réécrire `data/sorties/D11/`,
  modifier nemeton ou biljouR, copier le PDF ou ses tableaux dans le dépôt, publier des données
  CHELSA ou SoilGrids dans `inst/extdata` sans licence vérifiée dans `SOURCES.md`.

## Attendus

1. Plan :
   - méthode de correction retenue, avec la validation croisée meteoland, bilinéaire et gradient fixe, mesurée sur l'emprise ;
   - traitement de l'altitude des pseudo-stations ;
   - bilan latéral : coefficients et leur prix ;
   - RU SoilGrids et euptf2 : écart à la RU IFN ;
   - coût de calcul (temps, mémoire, volume) ;
   - prix et recommandation.
2. Après validation : code testé et câblé, R² avant et après, cartes avant et après.

## Dépend de / rouge attendu jusqu'à

- Aucune mission en cours sur les mêmes fichiers. Le correctif n1/n2 de 037 touche `_targets.R`
  (bloc de sortie) : recaler à l'intégration.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur ; les coefficients repris de Piedallu et le choix des seuils, signalés à Pascal.

## Plan (dev, 2026-11-20)

**Redite :** donner au bioclimat et à la RU de la carte le relief et les sols que les mailles SAFRAN
de 8 km effacent (température corrigée de l'altitude, bilan latéral, RU tirée des textures), sans
jamais croiser une variable fine avec les placettes IFN, pour que la carte du run réel cesse d'être
un dégradé lisse et des rectangles de 8 km.

Mesures : scripts et sorties de l'agent précédent (`…/3d37db41…/scratchpad/plan039/`, scripts 00 à 11),
relues ; complétées par deux mesures (`…/192b8d9a…/scratchpad/` : `10_echelle.R` relancé,
`12_ru_prof.R` nouveau). Store du run réel 035 lu seulement. GRECO D, 497 mailles SAFRAN, emprise
test (centre x = 1 014 500, y = 6 797 500, Lambert-93). Une seule graine (1), aucun intervalle de
confiance : les écarts de R² inférieurs à 0,03 sont à lire comme du bruit possible.

### 1. Méthode de correction de la température : validation croisée

Pseudo-stations = mailles SAFRAN, T moyenne 2011-2020 (meteoland, journalier) ou de toute la période
du store (autres méthodes) ; erreur sur la moyenne pluriannuelle de la maille laissée de côté (°C).

| Méthode (altitude des mailles = moyenne du MNT) | RMSE, 471 mailles | RMSE, 75 mailles à ≤ 40 km | RMSE, mailles en relief (\|dz\| > 100 m, n = 9 à 16) |
|---|---|---|---|
| Bilinéaire actuelle (4 voisins) | 0,23 | 0,36 | 0,76 à 0,85 |
| Gradient fixe −0,55 °C/100 m (Rolland 2003, à vérifier) | **0,11** | **0,11** | **0,14 à 0,17** |
| Gradient régional ajusté (maille exclue) | 0,12 | 0,11 | 0,18 à 0,19 |
| Régression locale pondérée (Thornton simplifié, noyau 30 km) | 0,13 | 0,14 | 0,15 à 0,17 |
| meteoland 2.2.8 (Thornton 1997, paramètres par défaut), 75 mailles, 2011-2020 | — | 0,12 (0,12 sur les 43 intérieures) ; MAE journalière 0,22 | non séparé |

T de saison de végétation (avril-septembre) : même classement (bilinéaire 0,27 ; gradient fixe 0,13).
Gradient lu entre mailles SAFRAN de la GRECO : −0,44 °C/100 m (T annuelle, R² 0,84), −0,49 avec x et y
(R² 0,92), −0,53 en saison de végétation.

Contrôle indépendant CHELSA V2.1 bio1 (1981-2010, 1 km, CC0 ; SAFRAN 1996-2010 seulement dans le store,
d'où un biais commun de +0,25 °C), 4 825 cellules de 1 km autour de l'emprise : écart-type de l'erreur
(biais ôté) bilinéaire 0,55, gradient −0,55 : 0,23, gradient −0,45 : 0,23 ; en relief (\|dz\| > 100 m,
1 150 cellules) 0,97 contre 0,28. Gradient de CHELSA lui-même : −0,56 °C/100 m.

Limite de la mesure meteoland : le store n'a que T journalière (Tmin = Tmax = T fournis), le gradient
journalier de Thornton n'a donc pas été éprouvé sur les extrêmes ; aucune calibration.

**Retenu (proposé) :** correction par gradient, `T = T_bilinéaire + G × (z − z_bilinéaire)` où
`z_bilinéaire` est l'altitude moyenne des mailles interpolée avec les mêmes poids. `G` estimé sur les
mailles SAFRAN de la SER (régression T ~ z_moy + x + y, une valeur par variable : annuelle, saison de
végétation), contrôlé contre −0,55 (Rolland, à vérifier) et publié au rapport. Raison : même justesse
que meteoland (0,11 contre 0,12), aucun coefficient extérieur, pas de dépendance nouvelle, calcul
vectoriel. meteoland n'entre pas dans `DESCRIPTION`. **Écart à la fiche** (qui nommait meteoland) :
à trancher (décision 1).

### 2. Altitude des pseudo-stations : moyenne de la maille

| | moyenne du MNT sur la maille (`z_moy`) | centre (`z_ctr`) |
|---|---|---|
| meteoland, RMSE de la T moyenne (75 mailles) | **0,119** | 0,382 |
| gradient fixe, RMSE (471 / relief) | **0,114 / 0,17** | 0,344 / 0,87 |
| R² de T ~ z entre mailles | **0,84** | 0,74 |

Retenu : moyenne. SAFRAN analyse à l'altitude moyenne de la maille (Vidal et al. 2010, à vérifier
sur le texte ; les mesures vont dans ce sens). Écart-type intra-maille de l'altitude : médiane 33 m,
jusqu'à 226 m.

**Source du MNT de 250 m à établir** : le `dem250_l93.tif` des mesures n'a pas de provenance
traçable. Proposé : BD ALTI 250 m de l'IGN (Licence Ouverte, à vérifier dans `docs/referentiels.md`
avant tout code), sinon agrégat du MNT du pipeline là où il existe. Décision 2.

### 3. Règle des 700 m et coût du changement d'échelle

- Apprentissage : `coarse_t_corr_700m` (T corrigée sur le MNT de 250 m puis moyenne dans un disque
  de 700 m, `soilgrids_disk_mean()` généralisée, `raster_at_points()` qui appelle l'assertion).
  Conforme : mesures 09 faites ainsi (2 893 placettes, aucune NA).
- Carte : `t_corr` à la cellule (MNT LiDAR), nom ajouté à `FINE_VARIABLES` (et `t_corr_sv`) ; test qui
  vérifie que l'assertion bloque `t_corr` aux placettes IFN.
- Coût (emprise, 462 400 cellules de 20 m) : la moyenne 700 m porte **94 %** de la variance de T à
  20 m (1 km : 88 %) ; résidu écart-type **0,26 °C** (q5/q95 −0,44 / +0,42) ; **0,29 %** des cellules
  hors de la plage d'apprentissage (6,1 à 11,4 °C). T à 20 m : q5/q95 7,5 / 11,2 °C (bilinéaire 8,8 / 10,7).
- **Écart trouvé** dans les mesures précédentes : le diagnostic `ru_sg_prof2` de `08_ru_sg.R` lisait la
  cellule de 250 m au point IFN (non conforme, diagnostic, rien appris). Refait conforme (CU par horizon
  moyennée dans 700 m) : mêmes chiffres (cor 0,68, biais +57 mm, RMSE 72 mm).

### 4. R² par blocs avant et après (n = 2 893 trophique, 2 827 hydrique, 2 754 bioclimat)

| Gradient | Variante | Bloc publié (portée) | Bloc 8 358 m |
|---|---|---|---|
| Trophique | **sans climat** | **0,231** (22 km) | 0,274 |
| Trophique | climat actuel (bilinéaire) | 0,194 | 0,272 |
| Trophique | climat corrigé | 0,211 | **0,297** |
| Hydrique (réponse BILJOU inchangée) | climat actuel | 0,285 (77 km) | 0,355 |
| Hydrique | T corrigée | **0,316** | **0,373** |
| Bioclimat, contre l'indice floristique T de Tichý (2023) | actuel | −0,102 (47 km) | 0,008 |
| Bioclimat | corrigé | **0,007** | **0,083** |

Corrélation indice floristique T / T de maille : 0,37 (bilinéaire), 0,41 (corrigée).
**Climat dans le trophique :** au bloc publié (22 km), le climat, même corrigé, fait perdre 0,02
(actuel : −0,04) ; au bloc de 8 358 m, le climat corrigé gagne +0,02. Écarts dans le bruit d'une seule
graine. Lecture prudente : **garder le trophique sans climat** (décision 4 à Pascal).
L'hydrique « après » réel demande de recalculer la réponse BILJOU (§ 6) : mesuré à la phase de code.

### 5. Bilan latéral et exposition

Tableau 20 (p. 53 imprimée) : logit multinomial, Curv150, IDR 1 500 m, indice de Moore, N = 1 200
relevés EcoPlant vosgiens, pseudo-R² 0,112, bon reclassement 57,4 % (tableau 21) ; −30 / 0 / +60 mm
viennent d'une synthèse bibliographique non reproduite (p. 54). Appliqué tel quel à l'emprise (mesure de
la mission 034) : départ 0-0,1 %, équilibre 46 %, apports 53-54 %, contre 25,9 / 46,4 / 27,6 % observés.
**Prix de la reprise telle quelle : +60 mm sur la moitié de l'emprise, presque aucun départ** ; les
unités de la courbure, le calcul de Moore et le MNT de 50 m ne sont pas donnés (coefficients à vérifier).
Options : A reprendre tel quel (écartée) ; B ne rien câbler avant les points GNSS de 029 ; C câbler les
trois variables et la formule, coefficients en `config.yml` marqués « à vérifier », désactivé par défaut
(`bilan_lateral: false`), carte de contrôle seule. **Proposé : C.** Décision 3.
Exposition : déjà dans la carte hydrique par le facteur de rayonnement `k` (mission 021) ; pour le
bioclimat, aucun terme d'exposition ajouté (le coefficient cos(exposition) du tableau 12 n'est pas
transposable sans la régression entière) : à noter, non fait.

### 6. RU SoilGrids + euptf2 contre RU IFN et RU par maille

SoilGrids 2.0 (argile, sable, limon, cailloux, 6 horizons, 24 couches, 45 Mo, CC BY 4.0) à 250 m,
euptf2 PTF01 (FC_2 − WP, comme `ru_from_texture`), cailloux retranchés. 2 846 placettes, moyenne 700 m.

| RU | moyenne (mm) | biais vs IFN | RMSE | cor | écart-type |
|---|---|---|---|---|---|
| IFN (référence) | 107 | — | — | — | 58 |
| SoilGrids 0-50 cm | 125 | +18 | 59 | 0,26 | 6 |
| SoilGrids 0-100 cm | 244 | +137 | 148 | 0,27 | 13 |
| SoilGrids 0-200 cm | 477 | +370 | 374 | 0,27 | 26 |
| SoilGrids × profondeur IFN (PROF2), diagnostic | 164 | +57 | 72 | 0,68 | 52 |

Sur l'emprise, RU SoilGrids 100 cm : q5/q50/q95 212 / 234 / 261 mm, écart-type 15 mm (champ presque
plat) ; RU par maille actuelle 49 à 110 mm. Médianes par maille (144 mailles ≥ 5 placettes) : cor 0,53.
La variance de la RU IFN vient de la profondeur (cor RU / PROF2 0,66), que SoilGrids ignore.
RU IFN apprise (forêt aléatoire, blocs) : SoilGrids seul R² 0,05 / 0,06 ; géologie 0,13 / 0,15 ;
géologie + SoilGrids 0,14 / 0,17 ; + climat 0,15 / 0,18 (bloc 41 km / 8 358 m). Médiane de maille
actuelle, placette exclue (non spatial, donc optimiste) : 0,10.
**Prix de la RU SoilGrids à profondeur fixe :** RU doublée (+137 mm à 1 m), stress BILJOU effondré
(§ 7), contraste perdu. **Proposé :** RU de carte = RU IFN apprise sur géologie 700 m + CU SoilGrids
700 m (R² 0,14 à 0,17, mieux que la médiane de maille, plus de rectangles), en option
`ru_source_carte: appris` ; la RU des placettes reste celle de l'IFN. Décision 5.

### 7. Effet BILJOU (maille 9640_23690, 30 ans, Istress et NJstress)

| dz (m) | ΔT (°C) | ETP (mm/an) | Is / NJ, RU 50 | RU 100 | RU 150 |
|---|---|---|---|---|---|
| −300 | +1,65 | 873 | 39,1 / 76 | 28,0 / 69 | 18,8 / 54 |
| 0 | 0 | 780 | 33,8 / 68 | 21,9 / 58 | 13,5 / 40 |
| +300 | −1,65 | 692 | 28,9 / 60 | 16,1 / 45 | 9,6 / 28 |
| +500 | −2,75 | 649 | 25,8 / 55 | 13,2 / 37 | 7,6 / 24 |

Par 150 m : ETP −45 mm/an, Is −3, NJ −6 jours (RU 100). Écart altitude des nœuds de 1 km / altitude
bilinéaire SAFRAN sur l'emprise : écart-type 136 m (−255 à +370 m), donc Is ±5 environ. Passer de
RU 100 à 230 (SoilGrids 1 m) ferait chuter Is sous 10 : c'est le prix du § 6. HU recalculée à pression
de vapeur constante ; correction journalière à gradient constant (inversions hivernales ignorées, à vérifier).

### 8. Coût de calcul (mesuré)

| Étape | Temps | Mémoire | Volume |
|---|---|---|---|
| Altitude des mailles (MNT 250 m) | < 10 s | faible | MNT 2,6 Mo |
| T corrigée à 20 m sur l'emprise | 159 s | **8,6 Go** (poids denses 462 400 × 497) : passer en poids creux ou par tuiles, cible < 1 Go | — |
| meteoland (si retenu) : création 16 s, CV 75 mailles × 10 ans 225 s ; grille complète non mesurée | | | |
| SoilGrids : 24 couches | quelques min (réseau) | | 45 Mo |
| euptf2 sur 447 044 cellules × 6 horizons | 231 s | 1,4 Go | RU 5,6 Mo |
| RU apprise (RF, 4 variantes × 2 blocs) | 8,5 min | 0,8 Go | |
| BILJOU recalculé (référence run 035 : `hydric_grid` 583 s, `ifn_gradients` 53 s) | du même ordre | | |

### 9. Prix et recommandation

Recommandation : (1) gradient G estimé sur les mailles de la SER, altitude moyenne de maille,
`coarse_t_corr_700m` à l'apprentissage, `t_corr` à la cellule (fine) ; (2) BILJOU des nœuds recalculé
avec T corrigée ; (3) RU de carte apprise (géologie + SoilGrids), pas la RU SoilGrids brute ;
(4) bilan latéral câblé désactivé ; (5) trophique sans climat.
Prix : bioclimat encore faible (R² 0,08 au mieux), une dépendance au MNT de 250 m dont la source est à
vérifier, 24 couches SoilGrids à télécharger hors tests, la fiche réécrite sur meteoland et sur la RU.
Si l'on tient la fiche à la lettre (meteoland, RU SoilGrids) : même justesse de T pour plus de calcul,
et une RU fausse de +137 mm qui fait payer l'utilisateur (stress hydrique sous-estimé).

### 10. Fichiers touchés (après validation)

`R/climat.R` (gradient, altitude des mailles, T corrigée par tuiles), `R/sols.R` (SoilGrids texture,
disque 700 m généralisé), `R/hydrique.R` (BILJOU à T corrigée, RU apprise, bilan latéral désactivé),
`R/terrain.R` (Curv150, IDR, Moore), `R/utils.R` (`FINE_VARIABLES` : `t_corr`, `t_corr_sv`,
`curv150`, `idr_1500`, `moore`, `bilan_lateral`), `R/pipeline_reel.R`, `_targets.R`, `config.yml`,
`R/config.R`, tests (`tests/testthat/test-climat.R`, `test-sols.R`, `test-hydrique.R`, `test-terrain.R`,
`test-utils.R` ; jeux `inst/extdata/synth_*`), `docs/pipeline.md`, `docs/referentiels.md` (§ 37).
`DESCRIPTION` inchangé si le gradient est retenu.

### Décisions à trancher

1. Gradient estimé sur SAFRAN plutôt que meteoland (écart à la fiche).
2. Source du MNT de 250 m (BD ALTI 250 m proposée, à vérifier).
3. Bilan latéral : option C (câblé, désactivé) ou B (attendre 029).
4. Climat dans le trophique : non (proposé).
5. RU de carte : apprise (géologie + SoilGrids) plutôt que SoilGrids brute.
