# Pipeline `targets` (mission 010)

Source : `_targets.R`, paramétré par `config.yml`. Ce fichier décrit seulement ce qui n'est
pas évident dans le code ; les décisions restent dans `docs/adr/`.

## Mode démo (`demo: true`)

Sans réseau. Emprise : carré de 2 500 m au sud-ouest de `emprise_test` (100 x 100 cellules
de 25 m, Lambert-93, origine multiple de 50 m). Ce qui est **réel réduit** : contour SER
simplifié, extrait BD Charm-50, 100 placettes IFN. Tout le reste est **synthétique**
(fonctions `synth_demo_*` de `R/demo.R`) : MNT (plan de `synth_dtm.tif` + relief lisse),
climat de 1 km, points d'ancrage et « relevés GNSS », flore, arbres, carte de référence
(`inst/extdata/synth_reference.tif`, fabriquée par `inst/scripts/synth_reference.R`).

Choix de conception :

- les cibles qui portent des `SpatRaster` sont enregistrées « emballées » (`terra::wrap`),
  par un format `targets` personnalisé défini en tête de `_targets.R` ;
- le pipeline appelle `sylvostation::...` : pour utiliser le paquet chargé par
  `devtools::load_all()`, lancer `tar_make(callr_function = NULL)` (sinon le sous-processus
  charge le paquet installé) ;
- la cible `rapport` n'existe que si le paquet `quarto` et le CLI Quarto sont disponibles ;
- les trois gradients (`trophic`, `hydric`, `bioclim`) sont modélisés sur les points
  synthétiques ; un modèle régional sur les placettes IFN (couches à maille large
  seulement) est validé à part ;
- le bloc « ancrage » (mission 007 : `get_gbif`, `clean_occ`, `grid_bioindication`,
  `load_gnss`) est intégré au paquet (`R/ancrage.R`) mais non branché au pipeline démo : `synth_demo_points()` le remplace.

## Mode réel (`demo: false`)

Non branché : `_targets.R` s'arrête avec un message. À brancher : téléchargement de la SER
(`get_ser(source = "download")`), tableau d'assemblage et dalles LiDAR HD (`list_tiles`,
`run_lasr`), ancrage GBIF et relevés GNSS (mission 007), couches de sols, seuils de la
référence AgroParisTech.

## À vérifier

- Format réel des rasters de référence (noms de couches, codage des 59 types) et ordre des
  chiffres du code à trois chiffres (`recode_3digits()`).
- Correspondance « réserve utile = gradient hydrique » pour le repère de R² de 0,43.
- Pilote COG : les balises `terra::metags` ne sont pas conservées ; la marque synthétique
  est le préfixe `synth_` du nom de fichier.
