# Kanban de sylvostation

> Cinq colonnes (fiche n° 8). Chaque carte renvoie à sa fiche dans `pilotage/missions/`.
> **Une carte qui ne bouge pas est souvent la mauvaise nouvelle à dire tout de suite.**

**Dernier cycle :** 5 (2026-11-17, délégation totale)

## Bac à sable

- Mode réel du pipeline (`demo: false`) : SER entière, LiDAR HD sur 225 dalles, ancrage GBIF branché, sols réels
- Valeurs indicatrices réelles (Baseflor / EcoPlant), coefficients de pédotransfert publiés
- Rasters de référence AgroParisTech, relevés GNSS de terrain (30 à 50)
- MRVBF (WhiteboxTools) et hauteur au-dessus du réseau (BD TOPAGE)

## Validé

- 037d local contre régional ([fiche 037](missions/037-ancrages-gbif-bdforet.md)) · cycle 5 · dev · code écrit, tests et commit à faire









## Planifié






## Terminé

- [039-bioclimat-ru-fins](missions/039-bioclimat-ru-fins.md) · cycle 5 · dev · T corrigée par gradient SAFRAN (0,22 → 0,11 °C) ; bioclimat R² +0,08 à +0,10, hydrique +0,01 à +0,05 ; RU apprise 0,11-0,14 ; trophique sans climat ; suite 039b (mineurs, test hors ligne de la branche corrigée)
- [040-table-lithologique](missions/040-table-lithologique.md) · cycle 5 · dev · non_classe dans les disques 155 → 10, placettes à classe dominante non_classe 296 → 0 ; R² trophique ≈ +0,01 (bruit) ; 42 formations gelées candidates pour Pascal
- [037-ancrages-gbif-bdforet](missions/037-ancrages-gbif-bdforet.md) · cycle 5 · dev · ancrages GBIF 5 → 2 (licences) ; contrôle par essence : pente 0,31, 3 alertes ; gain net de l'essence ≈ 0,05 (ADR 0008 maintenue)
- [035-calibration-greco](missions/035-calibration-greco.md) · cycle 5 · dev · 187 → 2 893 placettes ; R² trophique 0,19 [0,09 ; 0,28] (blocs estimés 22 km), 0,27 [0,20 ; 0,31] (8 358 m)
- [034-predicteurs-piedallu](missions/034-predicteurs-piedallu.md) · cycle 5 · dev · plan rendu, code absorbé par 035
- [033-empreinte-safran](missions/033-empreinte-safran.md) · cycle 5 · dev · maille : type modal 0,90 → 0,53 ; trophique sans pouvoir prédictif jusqu'à 035

- [038-geochimie-brgm](missions/038-geochimie-brgm.md) · cycle 5 · acquereur · aucune géochimie ouverte téléchargeable en D11

- [036-placettes-ouvertes-precises](missions/036-placettes-ouvertes-precises.md) · cycle 5 · acquereur · aucun relevé ouvert à ≤ 25 m en D11

- [032-cache-lidar](missions/032-cache-lidar.md) · cycle 5 · dev · cache par dalle, lidar_files hors de cfg

- [023-page-pkgdown-vosges](missions/023-page-pkgdown-vosges.md) · cycle 5 · dev · site pkgdown, article D11 (à refaire après 033 et 034)

- [031-comparaison-carhab](missions/031-comparaison-carhab.md) · cycle 5 · dev · aucune concordance avec CarHab 68

- [029-plan-echantillonnage-gnss](missions/029-plan-echantillonnage-gnss.md) · cycle 5 · dev · plan GNSS prêt, tirage réel après relecture de Pascal

- [027-diagnostic-mrvbf-hand](missions/027-diagnostic-mrvbf-hand.md) · cycle 5 · dev · MRVBF à 20 m, HAND cuvettes franchies

- [028-cout-hydrique](missions/028-cout-hydrique.md) · cycle 5 · dev · BILJOU vectorisé ×38 à ×59

- [030-sophy](missions/030-sophy.md) · cycle 5 · acquereur

- [025-grille-20m](missions/025-grille-20m.md) · cycle 5 · dev

- [026-robustesse-run-reel](missions/026-robustesse-run-reel.md) · cycle 5 · dev

- [022-rapport-pdf](missions/022-rapport-pdf.md) · cycle 5 · dev

- [024-cartes-comparaison](missions/024-cartes-comparaison.md) · cycle 5 · acquereur

- [021-descente-echelle-hydrique](missions/021-descente-echelle-hydrique.md) · cycle 5 · dev

- [020-sources-descente-echelle-hydrique](missions/020-sources-descente-echelle-hydrique.md) · cycle 5 · acquereur

- [016-mode-reel](missions/016-mode-reel.md) · cycle 5 · dev (opus) · mode réel branché, hors ligne sans réseau
- [019-gradient-hydrique-biljour](missions/019-gradient-hydrique-biljour.md) · cycle 5 · dev · RU par texture, Is biljouR
- [014-terrain-complements](missions/014-terrain-complements.md) · cycle 5 · dev · MRVBF GRASS, HAND TOPAGE
- [015-indicateurs-sols-reels](missions/015-indicateurs-sols-reels.md) · cycle 5 · dev · Tichý 77,7 % des occurrences, RU provisoire
- [017-tests-mode-reel](missions/017-tests-mode-reel.md) · cycle 5 · testeur · 9 tests sautés jusqu'à 016
- [013-referentiels-complements](missions/013-referentiels-complements.md) · cycle 5 · acquereur · passe 3 des référentiels
- [012-release-versionnage](missions/012-release-versionnage.md) · cycle 5 · dev · CI, release vAAAA.MM.N, badges

- [000-critique-brief](missions/000-critique-brief.md) · cycle 1 · contradicteur
- [001-referentiels](missions/001-referentiels.md) · cycle 1 · acquereur (fini par un agent généraliste)
- [002-squelette](missions/002-squelette.md) · cycle 1 · dev
- [003-emprise-lidar](missions/003-emprise-lidar.md) · cycle 2 · dev · incrément 1 sur 4 dalles **réelles**
- [004-geologie](missions/004-geologie.md) · cycle 2 · dev · BD Charm-50 **réelle** (extrait)
- [005-terrain](missions/005-terrain.md) · cycle 2 · dev · contrôlé sur MNT **réel**
- [011-tests-regle-bloquante](missions/011-tests-regle-bloquante.md) · cycle 2 · testeur
- [006-placettes-sols](missions/006-placettes-sols.md) · cycle 3 · dev · 100 placettes IFN **réelles**, sols synthétiques
- [007-ancrage](missions/007-ancrage.md) · cycle 3 · dev · mesure GBIF **réelle** (API publique), indicateurs synthétiques
- [008-modeles](missions/008-modeles.md) · cycle 3 · dev · synthétique
- [009-typologie-cle](missions/009-typologie-cle.md) · cycle 4 · dev · synthétique
- [010-pipeline-sorties](missions/010-pipeline-sorties.md) · cycle 4 · dev · pipeline démo de bout en bout (contrat d'interface)

## Abandonné

## Livraisons

- PR #1 fusionnée dans `main` le 2026-11-17 (0ab9b02) : 889 tests verts, 16 sautés ; pipeline démo 47 cibles.
