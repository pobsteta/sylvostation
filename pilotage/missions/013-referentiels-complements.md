# Mission 013 — compléments de référentiels pour le mode réel

## Mission

**En une phrase (quoi, et pourquoi) :** vérifier et écrire dans `docs/referentiels.md`
les sources encore « non vérifiées » dont le mode réel a besoin, pour que les missions 014
à 016 ne codent aucune URL, aucune couche et aucune colonne inventée.

**Redite par l'agent :** vérifier, avec le réseau, les sources encore « non vérifiées » du mode réel et les écrire dans `docs/referentiels.md`, pour que 014 à 016 ne codent ni URL, ni couche, ni colonne inventées.

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : méthode de `docs/referentiels.md` (commande, résultat, date), CQQCOQP, au moins deux sources comparées | |
| Les moyens ? | oui : réseau ouvert sur le poste de Pascal (la session cloud du 2026-11-16 ne l'avait pas) | |

**Temps de la main :** donner. **Degré :** le chef tranche (l'orchestrateur, par délégation).

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16)._

## L'Homme

- **Agent :** `acquereur` · **Modèle :** opus (justesse des données)
- **Ce qui ne lui est pas demandé :** écrire du code R.

## Harnais

- **Peut (périmètre) :** `docs/referentiels.md` uniquement.
- **Câblé :** pas de push vers `main` (hook) ; journal en ajout seul.
- **Ne doit pas :** inventer une URL, une couche ou une colonne. Ce qui reste invérifiable porte « non vérifié » et la commande essayée.
- **Sources autorisées :** les sites des producteurs (IGN Géoplateforme, Sandre/OFB, MNHN/INPN, EcoPlant AgroParisTech, Tela Botanica, INRAE GlobalSoilMap/Gis Sol, BRGM, r-universe et CRAN).

## Points à établir (chacun : URL, couche ou fichier, colonnes, licence, date, commande)

1. **Valeurs indicatrices** : Baseflor (Julve) et EcoPlant (AgroParisTech). Pour chacune : source primaire, licence, colonnes pH/azote/humidité (Ellenberg R, N, F ou équivalent), clé taxonomique (CD_NOM, CD_REF ou nom latin). Dire laquelle peut entrer dans un dépôt public.
2. **TAXREF** : version courante et URL de téléchargement ; table de passage v13 (IFN) → courante.
3. **BD TOPAGE** : service WFS (Sandre ou IGN), nom de la couche des tronçons hydrographiques, colonnes, licence.
4. **Classes LiDAR HD** : nomenclature officielle IGN (dont 64, 65, 66, 67), pour trancher l'exclusion des classes 65 et 66 du MHC.
5. **Sols** : GlobalSoilMap France (pH, réserve utile) ou couche équivalente ouverte : URL, résolution, licence ; base de pédotransfert publiée pour la réserve utile (classes de texture → RU par cm, par ex. Jamagne 1977, Bruand et al. 2004), avec la table et sa source.
6. **WhiteboxTools** : installation sous R (`whitebox::install_whitebox()`), nom exact de l'outil MRVBF et signature R.
7. **Régolithe** (§ 6) : reprendre le point si le service répond.
8. **Référence AgroParisTech** : tout ce qui est publié du format des rasters de stations (couches, codage des 59 types, code à 3 chiffres).

## Journal

Une ligne par rendu, proposée à l'orchestrateur.

## Valeur provisoire (chiffre, réglage)

Aucune.

## Dépend de / rouge attendu jusqu'à

Aucune. Précède 014, 015 et 016.

## Tests

Chaque point porte une commande reproductible et son résultat daté.

## Terrain

Aucun.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur par délégation.
