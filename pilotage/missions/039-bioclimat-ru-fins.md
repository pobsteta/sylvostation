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
