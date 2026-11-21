# Fiche de tournée — novembre 2026

> **Mission 041** · établie le 2026-11-21 par l'afficheur · à imprimer en paysage (A4), un crayon, un point à cocher par ligne.

| | |
|---|---|
| **Question** | Le code a-t-il raison sur la roche et sur la réserve utile (RU) ? |
| **Pour qui** | Pascal, sur le terrain, avec un GPS ou un téléphone (fichier GPX) |
| **À montrer** | 15 points de roche (6 groupes) et 6 points de RU (2 zones) |
| **Comparaison** | ce que le code affirme / ce que vous voyez |
| **Source, date** | BD Charm-50 (BRGM, cache `data/cache/bdcharm`) ; terrain et masque forestier du store `wt035run` · 2026-11-21 |
| **Mise à jour** | relancer le script de génération (hors dépôt) si la table lithologique ou les points changent |

**Fichiers jumeaux** : `docs/terrain/tournee-2026-11.gpx` (waypoints) et `docs/terrain/tournee-2026-11.csv` (mêmes 21 identifiants, mêmes coordonnées).

## Matériel et gestes

- HCl dilué (10 %) en flacon-pipette, tarière, couteau, mètre ruban, eau, crayon, fiche sous pochette plastique.
- **Effervescence** : 0 = rien ; + = faible, bulles isolées ; ++ = franche et durable. Tester la roche fraîche (le sol de surface peut être décarbonaté) et noter la profondeur du test.
- **Texture** au toucher : sableuse, limoneuse, argileuse (collante), ou mélange. **Cailloux** : % à vue, anguleux ou arrondis. **Hydromorphie** : profondeur d'apparition des taches rouille ou grises (cm), ou « aucune ».
- **Cadre** : un point est un **repère** : la carte est au 1/50 000, les limites de polygones sont imprécises. Les points de roche sont pris à l'intérieur des polygones, à distance du bord indiquée (colonne « bord »). Si une roche voisine apparaît, le noter.
- **Coordonnées** : Lambert-93 (EPSG:2154, x = est, y = nord) et WGS84 (EPSG:4326, degrés décimaux). Commune : « à vérifier » (pas de couche communes en cache, rien téléchargé).

## Partie 1 — Roche : ce que le code affirme

Le code classe chaque formation par sa NOTATION (clé de jointure), pas par chaque description locale. Classes lues sur `recode_lithology(list_formations(...))` rejoué sur la BD Charm-50 du cache.

### A · l3b dans le 57 (Moselle) — classe du code : `marne_argile`

- **Le code affirme** : formation `l3b` = `marne_argile` (marnes du Domérien inférieur).
- **Source** : inst/extdata/lithologie_notations.csv:160 (règle 11.2) ; docs/referentiels.md:2072 ; pilotage/journal.md (2026-11-20, l. 368 : « l3b en 57 et 88 ajoutée à l'échantillon à vérifier sur carte géologique »).
- **À regarder** : Roche fraîche ou fragment sous l'horizon décarbonaté : marne (tendre, se délite, argile collante) ou calcaire (dur, effervescence franche) ? Part de calcaire dur et de marne ?

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **A1** | 930 582 | 6 937 451 | 49.494593 | 6.182398 | 57 | 4.46 | 244 | à vérifier |
| **A2** | 928 555 | 6 924 622 | 49.380108 | 6.147398 | 57 | 3.82 | 155 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **A1** | | | | | | |
| **A2** | | | | | | |

### B · l3b dans le 88 (Vosges) — classe du code : `marne_argile`

- **Le code affirme** : formation `l3b` = `marne_argile` (marno-calcaires gréseux ou silteux du Domérien supérieur (description dominante de la formation)).
- **Source** : inst/extdata/lithologie_notations.csv:160 (règle 11.2) ; docs/referentiels.md:2072 ; pilotage/journal.md:368.
- **À regarder** : Marne ou marno-calcaire ? Présence de grès fins ou silts (grain au toucher) ? Effervescence à HCl franche, faible ou nulle ?

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **B1** | 913 169 | 6 812 314 | 48.376145 | 5.879348 | 88 | 9.95 | 222 | à vérifier |
| **B2** | 901 471 | 6 796 697 | 48.239450 | 5.714219 | 88 | 3.93 | 148 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **B1** | | | | | | |
| **B2** | | | | | | |

### C · l3b dans le 54 (Meurthe-et-Moselle) — classe du code : `marne_argile`

- **Le code affirme** : formation `l3b` = `marne_argile` (calcaires marneux, gréseux ou silteux du Domérien supérieur ; 40,30 km² codés marne_argile alors que la description locale commence par « calcaires »).
- **Source** : inst/extdata/lithologie_notations.csv:160 ; docs/referentiels.md:2089 ; pilotage/journal.md:386 (2026-11-21 : classe de la description dominante gardée, option 2).
- **À regarder** : Point clé de la fiche : bancs de calcaire durs (effervescence franche) ou marne tendre ? Le code dit marne_argile : le sol et la roche l'appuient-ils ?

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **C1** | 941 137 | 6 858 458 | 48.781097 | 6.282611 | 54 | 3.39 | 340 | à vérifier |
| **C2** | 934 994 | 6 842 246 | 48.637667 | 6.190167 | 54 | 2.11 | 168 | à vérifier |
| **C3** | 931 371 | 6 865 780 | 48.850472 | 6.153789 | 54 | 2.29 | 193 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **C1** | | | | | | |
| **C2** | | | | | | |
| **C3** | | | | | | |

### D · h2PK3 dans le 70 (Haute-Saône) — classe du code : `volcanite`

- **Le code affirme** : formation `h2PK3` = `volcanite` (complexe volcanique de Plancher-Bas et de Malvaux (laves, tufs, dolérites, spilites ; Viséen)).
- **Source** : inst/extdata/lithologie_notations.csv:123 (règle 10.4) ; docs/referentiels.md:1715 et :2050 (décision de Pascal « h2PK3 → volcanite ») ; pilotage/journal.md:344.
- **À regarder** : Roche volcanique (sombre, grain fin, pas d'effervescence) ? Ou granite, grès, calcaire ? Cailloux anguleux ? Sol : texture, cailloux, hydromorphie.

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **D1** | 969 864 | 6 757 014 | 47.857991 | 6.610058 | 70 | 12.02 | 314 | à vérifier |
| **D2** | 980 085 | 6 745 031 | 47.745979 | 6.739001 | 70 | 0.69 | 129 | à vérifier |
| **D3** | 969 184 | 6 747 758 | 47.775052 | 6.595340 | 70 | 2.41 | 182 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **D1** | | | | | | |
| **D2** | | | | | | |
| **D3** | | | | | | |

### E · e dans le 68 (Haut-Rhin) — classe du code : `calcaire`

- **Le code affirme** : formation `e` = `calcaire` (Éocène indifférencié : calcaire lacustre, parfois bréchique, grains sidérolithiques).
- **Source** : inst/extdata/lithologie_notations.csv:28 (règle 10.9) ; docs/referentiels.md:2094 (seule des 34 formations reclassées présente sur la carte) ; pilotage/journal.md:345.
- **À regarder** : Calcaire lacustre ou argile rouge ? Effervescence à HCl ? Grains rougeâtres (sidérolithique) ? Polygone petit : vérifier la position à 25 m près.

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **E1** | 1 019 349 | 6 791 658 | 48.147083 | 7.296026 | 68 | 0.05 | 38 | oui |
| **E2** | 1 013 208 | 6 719 357 | 47.500264 | 7.162349 | 68 | 0.06 | 64 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **E1** | | | | | | |
| **E2** | | | | | | |

### F · rD dans le 90 (Territoire de Belfort) — classe du code : `gres`

- **Le code affirme** : formation `rD` = `gres` (conglomérats (Permien) ; 4,74 km², codés gres comme la formation (dominante en 70 : grès conglomératiques)).
- **Source** : inst/extdata/lithologie_notations.csv:181 ; docs/referentiels.md:2090 ; pilotage/journal.md:386 et :348.
- **À regarder** : Galets arrondis dans une matrice (conglomérat) ou grès à grains ? Effervescence à HCl (attendue faible ou nulle) ? Taille et nature des galets.

| Id | x (L93) | y (L93) | lat | lon | Dép. | Polygone (km²) | Bord (m) | Forêt |
|---|---:|---:|---:|---:|---|---:|---:|---|
| **F1** | 992 431 | 6 742 549 | 47.718292 | 6.901916 | 90 | 2.01 | 217 | à vérifier |
| **F2** | 989 537 | 6 743 034 | 47.723932 | 6.863680 | 90 | 1.11 | 130 | à vérifier |
| **F3** | 990 912 | 6 742 708 | 47.720395 | 6.881785 | 90 | 1.29 | 144 | à vérifier |

| Id | Roche vue | HCl (0 / + / ++) | Texture | Cailloux (%) | Hydromorphie | Le code a raison ? (oui / non / doute) |
|---|---|---|---|---|---|---|
| **F1** | | | | | | |
| **F2** | | | | | | |
| **F3** | | | | | | |

## Partie 2 — Carte de RU apprise (mission 039)

- **Le code affirme** : la carte de RU est apprise par forêt aléatoire sur la lithologie, la formation et la capacité en eau SoilGrids, **moyennées dans 700 m** ; médiane 94 mm contre 64 mm avant ; des motifs circulaires viennent de ces moyennes (docs/referentiels.md:1949, § 37.4 ; pilotage/journal.md:337). Pascal l'a gardée « à juger sur le terrain » (pilotage/journal.md:369).
- **Valeur de la carte au point** : **à lire sur la carte** (couche `ru_apprise`). Elle n'est ni dans le store `wt035run` (antérieur à la mission 039), ni dans `data/sorties/D11/` : aucune valeur n'est inventée ici.
- **À regarder** : profondeur de sol exploitable (tarière), texture, cailloux, hydromorphie ; en conclure faible / moyenne / forte et comparer à la carte.
- **Zones** : versants autour de (1 009 000 ; 6 796 000) ; fond de vallée vers (1 016 000 ; 6 791 000), Lambert-93. Le point nominal du fond de vallée tombe hors masque forestier ; les points ci-dessous sont les cellules forestières proches, de pente faible et près du réseau hydrographique.

### G · versant (pente de 20 à 35°, forêt, à moins de 1,5 km du point nominal)

| Id | x (L93) | y (L93) | lat | lon | Alt. (m) | Pente (°) | Expo. | Roche BD Charm | RU carte (mm) |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| **G1** | 1 008 990 | 6 796 010 | 48.191175 | 7.160016 | 1 038 | 24.0 | S | `h2ã3sc` | à lire sur la carte |
| **G2** | 1 010 090 | 6 794 970 | 48.181308 | 7.174058 | 807 | 21.7 | E | `h2ã3sc` | à lire sur la carte |
| **G3** | 1 008 550 | 6 794 570 | 48.178444 | 7.153084 | 1 045 | 24.2 | S | `h2ã3sc` | à lire sur la carte |

| Id | Profondeur de sol (cm) | Texture | Cailloux (%) | Hydromorphie | RU estimée (faible / moyenne / forte) | La carte est-elle plausible ? |
|---|---|---|---|---|---|---|
| **G1** | | | | | | |
| **G2** | | | | | | |
| **G3** | | | | | | |

### H · fond de vallée (pente ≤ 8°, ≤ 3 m au-dessus du réseau, forêt, à moins de 1,5 km du point nominal)

| Id | x (L93) | y (L93) | lat | lon | Alt. (m) | Pente (°) | Expo. | Roche BD Charm | RU carte (mm) |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| **H1** | 1 016 210 | 6 790 950 | 48.142250 | 7.253368 | 285 | 6.1 | N | `h3M2Ka` | à lire sur la carte |
| **H2** | 1 014 910 | 6 792 030 | 48.152582 | 7.236694 | 291 | 2.1 | NE | `Fy-zV` | à lire sur la carte |
| **H3** | 1 016 610 | 6 791 770 | 48.149424 | 7.259333 | 301 | 5.4 | SO | `h3M2Ka` | à lire sur la carte |

| Id | Profondeur de sol (cm) | Texture | Cailloux (%) | Hydromorphie | RU estimée (faible / moyenne / forte) | La carte est-elle plausible ? |
|---|---|---|---|---|---|---|
| **H1** | | | | | | |
| **H2** | | | | | | |
| **H3** | | | | | | |

## Contrôles faits avant impression

- **Lithologie** : 15 points sur 15 retombent dans un polygone de leur NOTATION et de leur département (BD Charm-50 du cache, EPSG:2154 ; test `st_covers` sur les coordonnées arrondies au mètre) ; chacun est à 38 m ou plus du bord de son polygone ; un seul polygone recouvre chaque point.
- **RU** : les 6 points sont dans des cellules forestières du masque du pipeline (20 m).
- **Fichiers** : le GPX et le CSV portent les mêmes 21 identifiants ; les coordonnées WGS84 reviennent en Lambert-93 à moins de 1 m.
- **Forêt et accès des points de roche** : à vérifier sur place (le masque forestier du pipeline ne couvre que l'emprise 1 007 000–1 022 000 / 6 790 000–6 805 000 ; aucune couche de routes ou de chemins en cache). Seul le point E1 y est (et il est en forêt selon ce masque).

## Après la tournée

Rendre la fiche remplie à l'orchestrateur (photo ou scan). Chaque « non » ou « doute » sur un groupe devient une question à Pascal : changer la classe de la formation, ou coder département + NOTATION (ADR nécessaire, voir docs/referentiels.md:2094).
