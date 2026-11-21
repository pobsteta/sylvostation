# Mission 041 — fiche de tournée : les points à vérifier sur le terrain

## Mission

**En une phrase (quoi, et pourquoi) :** rassembler en une fiche imprimable, avec un fichier GPS,
les points que Pascal doit vérifier sur le terrain ou sur carte géologique, pour que chaque
affirmation du code non vérifiable au bureau soit confrontée au réel et la réponse notée.

**Redite par l'agent :** Produire une fiche de tournée imprimable, avec GPX et CSV de mêmes points, pour que Pascal confronte sur le terrain les classes lithologiques du code (l3b, h2PK3, e, rD) et la carte de RU apprise ; chaque point de roche est contrôlé dans un polygone de sa NOTATION.

## Sources

- Journal `pilotage/journal.md` (entrées du 2026-11-20 et 2026-11-21) et `docs/referentiels.md`
  §§ 37, 40, 40.2 : ce que le code affirme pour chaque point.
- Points à couvrir (liste fermée, décidée avec Pascal le 2026-11-21) :
  1. Lithologie (BD Charm-50, `data/cache/bdcharm`, lecture seule ; `R/geologie.R`,
     `list_formations()`, `read_lithology_notations()`) :
     - `l3b` en 57, 88 et 54 (codée `marne_argile` ; décrite « Calcaires marneux » en 54) ;
     - `h2PK3` (codée `volcanite`, complexe volcanique de Plancher-Bas) ;
     - `e` dans le 68 (reclassée, seule des 34 formations reclassées présente sur la carte) ;
     - `rD` dans le 90 (« Conglomérats », codée `gres`).
     Pour chaque formation et département : 2 ou 3 points en forêt, accessibles si possible
     (près d'un chemin ou d'une route, si la donnée est disponible sans téléchargement nouveau),
     pris à l'intérieur des polygones (pas leur centroïde s'il tombe dehors).
  2. Carte de RU apprise (mission 039) : versants autour de x = 1 009 000, y = 6 796 000 ;
     fond de vallée vers x = 1 016 000, y = 6 791 000. Valeur de RU de la carte en chaque point
     si le store `.claude/worktrees/wt035run/_targets` (lecture seule) ou `data/sorties/D11/`
     (lecture seule) la donnent ; sinon « à lire sur la carte ».

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui | pas de plan |
| Les moyens ? | oui : données en cache, store en lecture seule, R + sf + terra | |

**Temps de la main :** donner. **Degré :** l'orchestrateur tranche (délégation totale).

## L'Homme

- **Agent :** `afficheur` · **Modèle :** sonnet

## Harnais

- **Peut :** créer `docs/terrain/tournee-2026-11.md` (fiche), `docs/terrain/tournee-2026-11.gpx`
  et `docs/terrain/tournee-2026-11.csv` (mêmes points), et un script de génération dans le
  scratchpad (pas dans `R/`).
- **Câblé :** chaque point porte un identifiant, x/y en Lambert-93 (EPSG:2154) et lat/lon WGS84
  (EPSG:4326, reprojetés par sf), le département, la commune si disponible sans réseau, ce que
  le code affirme (classe ou valeur, avec sa source : fichier et ligne ou entrée du journal),
  ce qu'il faut regarder sur place (roche, effervescence à l'acide, texture, cailloux,
  hydromorphie…), et une case réponse vide. Aucune donnée inventée : ce qui n'est pas lu
  porte « à vérifier ».
- **Ne doit pas :** toucher `R/`, `_targets.R`, `config.yml`, `inst/extdata`, `tests/`,
  `wt035run`, `data/sorties/` ; copier du texte sous licence (descriptions BD Charm : citer le
  code NOTATION et un résumé, pas la notice) ; télécharger.

## Attendus

1. La fiche, le GPX et le CSV, cohérents entre eux (mêmes identifiants, mêmes coordonnées).
2. Un contrôle : chaque point de lithologie retombe bien dans un polygone de sa NOTATION.

## Tests

Pas de code du package touché : la suite n'est pas exigée ; le contrôle de l'attendu 2 est
écrit au rapport.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
