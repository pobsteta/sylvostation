# Mission 024 — cartes SIG publiées pour comparer la carte des stations (D11)

## Mission

**En une phrase (quoi, et pourquoi) :** trouver sur internet les cartes au format SIG
(vecteur ou raster) de stations forestières, d'habitats ou de végétation qui couvrent
l'emprise test de D11, en partant des guides de stations recensés par le fichier
`guides-stations-forestieres.gpkg` fourni par Pascal, pour disposer d'une référence ouverte
avec laquelle comparer nos résultats (demande de Pascal du 2026-11-18).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : guides qui recoupent l'emprise (ids 94, 95, 97, 83 du gpkg) et leurs URL ; pistes à vérifier : cartographies de stations des guides, CarHab (IGN, MNHN), habitats Natura 2000 des DOCOB, cartes de stations ONF publiées, PNR des Ballons des Vosges, data.gouv.fr, géoportails régionaux (DataGrandEst) | |
| Les moyens ? | oui : web, lecture du gpkg (GDAL) | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Pascal, 2026-11-18 : « regarde si à partir de ce fichier tu peux trouver sur internet une carte au format SIG pour comparer avec tes résultats »._

## L'Homme

- **Agent :** `acquereur` · **Modèle :** opus

## Harnais

- **Peut (périmètre) :** `docs/referentiels.md` (nouveau § 26, « Cartes de comparaison »), rendu dans la conversation.
- **Ne doit pas :** télécharger de gros fichiers dans le dépôt ; copier le gpkg de Pascal dans le dépôt (licence inconnue) ; envoyer à un service externe d'information personnelle.

## Attendus

1. Liste de toutes les cartes trouvées qui couvrent tout ou partie de l'emprise test (EPSG:2154 : x 1 007 000 à 1 022 000, y 6 790 000 à 6 805 000) : nom, producteur, année, format (shp, gpkg, WFS, raster…), URL de téléchargement ou de service vérifiée, licence, échelle ou résolution, nomenclature (stations d'un guide, habitats EUNIS/Cahiers d'habitats, CarHab…), part de l'emprise couverte.
2. Pour chacune : ce qui permet la comparaison avec nos types (correspondance de nomenclature, gradients trophique et hydrique), et ce qui l'empêche.
3. Les guides du gpkg qui recoupent l'emprise : contenu (typologie seule ou cartographie jointe), lien vérifié, statut (actif ou obsolète).
4. Recommandation : la meilleure référence ouverte, et le protocole de comparaison (matrice de confusion par types regroupés, ou corrélation des gradients).

## Tests

Liste de contrôle passée (jointe).

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
