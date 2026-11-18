# Protocole de relevé floristique GNSS (une page)

**Statut : à relire par Pascal avant toute sortie** (mission 029). Plan tiré par
`inst/scripts/plan_gnss.R` ; méthode dans `docs/echantillonnage.md`.

1. **Saison.** Fin mai à juillet. **La flore vernale manque** à cette saison (géophytes de
   printemps : ficaire, anémone, etc.) : la noter si elle se voit encore, sans la chercher.
2. **Aller au point.** Charger `plan_gnss.gpx` (WGS84) dans le GNSS. Partir du tronçon le
   plus proche. Un point marqué `acces_restreint` (route privée ou réservée aux ayants droit)
   demande une autorisation **avant** la sortie.
3. **Point inaccessible ou hors station** (falaise, coupe rase, route, clairière, eau,
   lisière à moins de 15 m) : prendre le remplaçant `-R1`, puis `-R2`, jamais un point
   choisi à vue. Noter le rang utilisé (`rang_utilise` : 0, 1 ou 2) et la raison.
4. **Position.** Au centre de la placette, moyenner le GNSS (au moins 60 positions, ou le
   mode moyenne de l'appareil) en visant une **précision ≤ 5 m**. Noter la précision affichée
   (`loc_precision_m`) et le nombre de mesures. **Au-delà de 25 m, le relevé est refusé par
   le pipeline** : refaire la mesure plus loin des troncs ou à un autre moment.
   Coordonnées saisies en **Lambert-93 (EPSG:2154), x = est, y = nord**, en mètres ; si
   l'appareil ne donne que du WGS84, convertir avant saisie (jamais de degrés dans x et y).
5. **Placette.** Cercle de **400 m²**, rayon **11,28 m** (horizontal ; en pente, allonger
   la corde dans le sens de la pente).
6. **Flore.** Liste **complète** des espèces vasculaires de la placette, nom latin (TAXREF ;
   `cd_nom` si connu). Pour chaque espèce, le coefficient de **Braun-Blanquet** (`r`, `+`,
   `1` à `5`) dans chaque strate où elle est présente : arborescente, arbustive, herbacée,
   muscinale (seuils de hauteur des strates : **à confirmer par Pascal**). Une seule ligne
   par espèce ; une espèce douteuse est notée au genre et récoltée ou photographiée.
7. **Station.** Recouvrement de chaque strate ; forme d'humus en **grande forme seulement**
   (Mull, Moder, Mor, Amphi, Tangel ; à vérifier) ; tarière au centre si possible
   (profondeur atteinte, refus oui/non, texture en clair) ; photos (vers le nord, le sol,
   l'humus) avec leurs noms de fichier.
8. **Saisie** le soir même dans `gabarit_flore.csv` et `gabarit_station.csv`, contrôlés par
   `read_field_sheet()` et `read_station_sheet()`. Le fichier de flore est l'entrée
   `gnss_path` du pipeline.

**Durée (provisoire, à confirmer) :** 60 min de relevé, 20 min de tarière, marche à 2 km/h
hors piste, route à 30 km/h ; `field_time()` donne le total et les jours.
