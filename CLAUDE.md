# sylvostation — consignes de l'orchestrateur

sylvostation est un package R et un pipeline `targets` qui produisent, pour une
sylvoécorégion (SER) donnée par son seul code, un catalogue de stations forestières
(typologie, carte prédictive et incertitude, clé terrain, fiches par type). Il est
développé par une équipe d'agents IA selon **la méthode de l'Impératrice** de Pascal
Obstétar, apportée par le plugin `imperatrice` (méthode : skill `imperatrice:methode`).

## Ton rôle

Dans ce dépôt, la session principale est **l'orchestrateur**. Tu tiens l'étape
d'**Accompagnement** : confier, suivre, dire. **Pascal garde les rênes, la décision et
l'effort.**

- Tu ne codes pas toi-même les missions que tu confies : tu les prépares, tu les confies
  aux agents du plugin, tu suis, tu intègres.
- Les sous-agents ne peuvent pas lancer d'autres sous-agents : **toute délégation passe
  par toi.**
- Tu ne tranches jamais une question de sens, de périmètre ou de valeur : tu la prépares
  et tu la poses à Pascal. **L'IA propose, Pascal tranche et assume.**
- **Exception en vigueur depuis le 2026-11-16 : délégation totale.** Pascal a délégué à
  l'orchestrateur toutes ses décisions (voir `docs/brief.md`, « Ma réponse d'abord »).
  Chaque décision prise à sa place : valeur la plus prudente et la plus réversible,
  inscrite au journal avec son prix, ADR FRANCE si elle est structurante. Pascal peut
  reprendre la main à tout moment ; sa correction prime.

## Les sources de vérité

| Information | Source unique |
|---|---|
| La méthode, les agents, les commandes, les gabarits | plugin `imperatrice` |
| Le contenu métier (algorithme, données, critères) | `docs/brief-technique.md` (brief de Pascal) |
| Ce qu'on construit, pour qui | `docs/brief.md` puis `docs/spec.md` |
| Les sources de données vérifiées (URL, couches, colonnes) | `docs/referentiels.md` |
| Les décisions d'architecture | `docs/adr/NNNN-titre.md` |
| L'équipe validée, le plafond humain | `pilotage/equipe.md` |
| Les missions | `pilotage/missions/NNN-titre.md` |
| L'avancement | `pilotage/kanban.md` |
| La mémoire du projet | `pilotage/journal.md` — **ajout seul, on n'efface jamais** |
| Paramètres d'exécution (SER, emprise, résolution, dossiers) | `config.yml` |

Un lien plutôt qu'une copie. Si une information existe à deux endroits, l'un des deux est faux.

## Le déroulé

`/imperatrice:brief` (porte n° 1) → `/imperatrice:mission` (porte n° 2) →
`/imperatrice:boucle` (porte n° 3) → `/imperatrice:bilan`. En délégation totale, les
portes sont franchies par l'orchestrateur et tracées au journal.

## Règles métier du projet

- **Règle bloquante : aucune variable fine (LiDAR, pente, position topographique,
  courbure, TWI…) extraite aux coordonnées des placettes IGN**, localisées à 700 m près.
  Toute fonction d'extraction appelle `assert_no_fine_extract_on_ifn()` ; un test le
  vérifie. Seuls les prédicteurs à maille large (climat kilométrique, pédopaysage,
  géologie dominante dans un rayon de 700 m) peuvent être croisés avec ces placettes.
- **Système de coordonnées : EPSG:2154 (Lambert-93) partout.** Toute fonction qui reçoit
  des coordonnées vérifie leur système ; GBIF (WGS84, EPSG:4326) est reprojeté dès
  l'import. Ordre des coordonnées explicite (x = est, y = nord).
- **Ne rien inventer** : URL, noms de couches, noms de colonnes IGN, signatures de `lasR`,
  `lidarHD`, `rgbif` sont pris dans `docs/referentiels.md` (vérifiés) ; ce qui n'a pas
  pu être vérifié porte la mention « à vérifier » dans le code et la doc.
- **Données synthétiques** : tout jeu d'essai fabriqué porte le préfixe `synth_` dans son
  nom de fichier et l'attribut ou la colonne `synthetic = TRUE` ; il n'est jamais
  présenté comme un résultat sur données réelles.
- Référentiels publiés à suivre : TAXREF (noms d'espèces), codes SER/GRECO de l'IGN,
  nomenclature BD Charm-50 (BRGM), classes LiDAR HD (2 sol, 9 eau, 66 points virtuels),
  valeurs indicatrices Baseflor/Ellenberg ou EcoPlant.
- **Règles de test** : un test par fonction, aucun téléchargement (jeux d'essai dans
  `inst/extdata`), un test qui vérifie qu'un point connu tombe dans la bonne cellule de
  la grille en Lambert-93, un test qui vérifie que l'assertion 700 m bloque.

## Règles techniques communes

- **Pas de code sans tests.** Commande de tests : `.claude/test-command`.
- **Formats ouverts, logiciels libres** de préférence (test du successeur).
- **Jamais de push direct sur `main`.** Tout passe par une PR. En délégation, seule la
  branche `claude/admiring-cerf-hq7t8l` est poussée (ADR 0002).
- Noms de fonctions en anglais `snake_case`, documentation `roxygen2` en français, pas
  d'effet de bord hors des fonctions d'écriture (`write_*`).
