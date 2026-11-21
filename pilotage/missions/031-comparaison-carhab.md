# Mission 031 — comparaison de la carte des 225 dalles avec CarHab 68

## Mission

**En une phrase (quoi, et pourquoi) :** comparer, gradient par gradient, nos cartes trophique
et hydrique de l'emprise test de D11 (run 018 des 225 dalles) aux paramètres d'acidité et
d'humidité édaphiques de CarHab 68, seule carte SIG ouverte de l'emprise (référentiels § 26),
pour donner à la carte un premier contrôle externe en attendant les relevés GNSS (029).

**Redite par l'agent :** comparer, gradient par gradient (Spearman par blocs, kappa pondéré après découpage aux parts CarHab), nos cartes trophique et hydrique de l'emprise test de D11 (run 018) aux paramètres d'acidité et d'humidité édaphiques de CarHab 68, de grille à grille à 20 m en Lambert-93, pour un premier contrôle externe de la carte, CarHab étant une carte prédictive et non une vérité terrain.

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `sf`, `terra`, WFS Géoplateforme (requêtes exactes au § 26 de `docs/referentiels.md`), corrélation de Spearman, kappa pondéré (paquet à choisir parmi ceux déjà installés, sinon calcul écrit et testé) | |
| Les moyens ? | oui : sorties de 018 sous `data/sorties/D11/` (`gradients.tif`, `hydrique.tif`, `types.tif`, `incertitude.tif`), WFS CarHab | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : carte à composante régionale « comparée à CarHab, limites déclarées »._
_Recommandation de 024 (§ 26) : comparer par gradient (Spearman, kappa pondéré), pas par types ;
CarHab n'est pas indépendant de nos prédicteurs (RGE ALTI, TOPAGE, géologie BRGM)._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** un nouveau fichier `R/carhab.R` (lecture WFS avec cache sous
  `data/cache/carhab/`, recodage ordinal, comparaison), ses tests, un extrait de test
  `inst/extdata/` (quelques polygones CarHab réels sous Licence Ouverte, source et date dans
  `inst/extdata/SOURCES.md`, ou un jeu `synth_`), `docs/comparaison-carhab.md`,
  `docs/referentiels.md` (complément daté au § 26 seulement), un script
  `inst/scripts/comparaison_carhab.R` qui lit les sorties de 018 et écrit tables et figures sous
  `data/sorties/D11/comparaison_carhab/`.
- **Câblé :** ordre ordinal de l'humidité gardé et marqué provisoire ; « neutre » est une classe
  propre, jamais fusionnée avec « basique » (décisions du 2026-11-18) ; seuls les polygones
  `occupation = 'foret'` ; comparaison de grille à grille en EPSG:2154 à la résolution de notre
  grille (20 m), polygone rasterisé par son centre de cellule ; un polygone à cheval sur
  l'emprise est découpé ; zones hors masque forestier et hors zone d'applicabilité (si elle
  existe dans les sorties) écartées et comptées.
- **Ne doit pas :** toucher au worktree de 018 (`agent-a39039d71f8e997e4`) ni réécrire
  `data/sorties/D11/` hors du sous-dossier `comparaison_carhab/` ; extraire une variable fine aux
  placettes IFN (la comparaison est de grille à grille, règle des 700 m non concernée) ;
  versionner le GeoPackage de 528 Mo ; présenter CarHab comme une vérité terrain (c'est une
  carte prédictive, § 26.2).

## Attendus

1. Tableau par gradient : Spearman (avec intervalle, en tenant compte de l'autocorrélation
   spatiale : par blocs, ou sous-échantillon espacé, méthode écrite), kappa pondéré après
   découpage de notre gradient en autant de classes que CarHab (quantiles de surface, méthode
   écrite), matrice de confusion.
2. Deux cartes (accord, désaccord) et une figure de distribution de notre gradient par
   modalité CarHab.
3. `docs/comparaison-carhab.md` : méthode, chiffres, limites (non-indépendance des
   prédicteurs, carte prédictive, échelle 1/25 000, polygones ≥ 0,5 ha), et ce que la
   comparaison ne permet pas de dire.

## Valeur provisoire (chiffre, réglage)

Ordre ordinal de l'humidité CarHab (provisoire, 2026-11-18).

## Dépend de / rouge attendu jusqu'à

- 018 (run des 225 dalles terminé le 2026-11-19, 07:35, sorties sous `data/sorties/D11/`).

## Tests

Un test par fonction, sans réseau (extrait ou jeu `synth_`) ; un point connu tombe dans la bonne
cellule en Lambert-93 ; `.claude/test-command` vert.

## Terrain

Pascal regarde les deux cartes d'accord et de désaccord sur un secteur qu'il connaît.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
