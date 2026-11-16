# sylvostation — brief

> Rédigé par Claude (orchestrateur) en **délégation totale** : Pascal a délégué le
> 2026-11-16 toutes les décisions qui lui sont réservées (voir « Ma réponse d'abord »).
> Les rubriques ci-dessous reprennent le brief technique de Pascal,
> [`docs/brief-technique.md`](brief-technique.md), **source unique** du contenu métier :
> en cas de doute, c'est lui qui fait foi. Ce qui est tranché ici par Claude à la place
> de Pascal est marqué **[délégué]** et inscrit au journal avec son prix.

## Ma réponse d'abord (fiche n° 15)

> « lis et code selon la méthode de l'impératrice le brief joint. Quelle commande dois-je
> te passer pour que le code aille jusqu'au bout sans que j'ai besoin de répondre à l'une
> de tes questions, c'est toi qui choisit lorsque le cas se présente ? »
>
> « Applique la méthode de l'Impératrice au brief joint, en délégation totale : je te
> délègue toutes les décisions réservées à Pascal (brief, ADR, équipe, temps de la main,
> massif test, table lithologique, seuils, fusion des types, relecture des PR). À chaque
> décision : choisis la valeur par défaut la plus prudente et la plus réversible,
> inscris-la au journal avec son prix (ADR FRANCE si elle est structurante) et continue
> sans me demander. […] »
>
> — Pascal, le 16 novembre 2026, recopié mot pour mot (message complet dans le journal,
> première inscription).

## Le problème, et pour qui (Abstraction)

- **Problème** : les catalogues de stations forestières sont produits à la main, SER par
  SER, et ne couvrent pas tout le territoire ; ils ne sont pas reproductibles ni
  recalculables sous un autre climat (brief technique, § 1 et § 2).
- **Bénéficiaires** : d'abord les forestiers gestionnaires qui choisissent les essences et
  diagnostiquent les stations sur le terrain ; ensuite les rédacteurs de catalogues et
  les analystes de la vulnérabilité climatique **[délégué : la finalité principale
  (§ 11) reste à trancher par Pascal ; par défaut, « choix des essences »]**.
- **Coût complet aujourd'hui** : inconnu.

## Ce que fait sylvostation

- **En une phrase** : un package R et un pipeline `targets` qui produisent, pour une SER
  donnée par son seul code, une typologie de stations, une carte prédictive avec son
  incertitude, une clé terrain et des fiches par type.
- **Les gestes sur le terrain** : le forestier lit la carte pour orienter son diagnostic,
  puis confirme le type avec la clé (topographie, humus, texture, profondeur, plantes
  indicatrices) et un sondage à la tarière ; 30 à 50 relevés GNSS par massif test
  servent de validation indépendante.
- **Ce qu'il produit** : rasters (types, trois gradients, incertitude) en GeoTIFF/COG,
  table des types (CSV/GeoPackage), fiches et rapport de validation Quarto (§ 10).

## Ce qu'il ne fait pas (hors périmètre)

- Il ne remplace pas le sondage à la tarière : la carte oriente le diagnostic (§ 10).
- Il n'extrait **jamais** de variable fine (LiDAR, pente, position topographique) aux
  coordonnées des placettes IGN, localisées à 700 m près (règle bloquante).
- Il ne stocke aucune donnée volumineuse dans le dépôt.
- Hors de cette session : relevés GNSS de terrain, rasters de référence AgroParisTech,
  conventions IGN ou conservatoires (§ 11).

## Contraintes connues

- R, EPSG:2154 partout, fonctions en anglais `snake_case`, roxygen2 en français, une
  fonction par tâche, tests `testthat` sans téléchargement (§ consignes).
- Données IFN : coordonnées dégradées à 700 m (§ 3, encadré).
- LiDAR HD : vols d'hiver 2021-2022 dans le Nord-Est, diffusion incomplète (§ 5).
- Dépôt privé tant que la licence des données de référence n'est pas réglée (§ 6).
- Ressources de la session : 4 cœurs, environ 30 Go de disque libre ; pas de compte GBIF.
