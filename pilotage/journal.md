# Journal de sylvostation

> **Règle du sommier : on n'efface pas, on ajoute.**
> Chaque inscription est datée et signée (agent ou personne). Une correction est une
> nouvelle ligne qui renvoie à l'ancienne. Un hook refuse toute modification qui
> supprimerait ou réécrirait une inscription existante.
>
> Format : `AAAA-MM-JJ · auteur · mission · ce qui a été fait / décidé / bloqué`
>
> **Le carnet des écarts** (fiche n° 3), en une ligne marquée `écart` :
> `AAAA-MM-JJ · auteur · mission · écart · attendu : … · vu : … · vérifié : comment (ou « non ») · décision : …`
>
> **Les changements de cap** (fiche n° 13), en une ligne marquée `cap` :
> `AAAA-MM-JJ · auteur · mission · cap · ancien → nouveau · pourquoi : … · fait : …`
>
> **Les décisions déléguées**, en une ligne marquée `délégué` :
> `AAAA-MM-JJ · Claude (orchestrateur) · mission · délégué · décision : … · prix : … · réversible : comment`

2026-11-16 · Pascal · — · cap · validation de chaque décision par Pascal → délégation totale à l'orchestrateur · pourquoi : « Applique la méthode de l'Impératrice au brief joint, en délégation totale : je te délègue toutes les décisions réservées à Pascal (brief, ADR, équipe, temps de la main, massif test, table lithologique, seuils, fusion des types, relecture des PR). À chaque décision : choisis la valeur par défaut la plus prudente et la plus réversible, inscris-la au journal avec son prix (ADR FRANCE si elle est structurante) et continue sans me demander. Points d'arrêt du brief : ne t'arrête pas. Si une donnée, un identifiant, une licence ou le réseau manque, contourne avec des jeux d'essai synthétiques clairement marqués, note le blocage dans pilotage/journal.md et passe à la suite. Tu peux coder les étapes 5 à 10 même si les étapes 1 à 4 n'ont pas tourné sur données réelles. N'invente aucun code, URL ou nom de colonne : marque « à vérifier » ce que tu n'as pas pu contrôler. Travaille sur la branche claude/admiring-cerf-hq7t8l, commit et push à chaque incrément, une PR brouillon. » · fait : méthode installée en mode délégation.
2026-11-16 · Claude (orchestrateur) · — · méthode installée : CLAUDE.md, docs/brief.md, docs/spec.md, docs/brief-technique.md (copie du brief de Pascal), docs/adr/0001-0003, pilotage/equipe.md, kanban.md, missions 000-002.
2026-11-16 · Claude (orchestrateur) · — · réseau de l'environnement ouvert avec l'accord de Pascal : cloud.r-project.org, r-lidar.r-universe.dev, api.gbif.org, infoterre.brgm.fr, geoservices.brgm.fr, inventaire-forestier.ign.fr, www.data.gouv.fr, static.data.gouv.fr (data.geopf.fr déjà ouvert).
2026-11-16 · Claude (orchestrateur) · — · environnement : R 4.3.3 (apt Ubuntu 24.04), sf 1.0.15, terra 1.7.65, testthat 3.2.1, ranger 0.16.0, mgcv 1.9.1, vegan 2.6.4, ade4 1.7.22 ; GDAL 3.8.4, PROJ 9.4.0, GEOS 3.12.1 ; compléments CRAN et lasR en cours d'installation.
2026-11-16 · Claude (orchestrateur) · — · délégué · décision : porte n° 1 franchie, brief et spec validés tels que rédigés · prix : aucune relecture humaine avant la critique du contradicteur (mission 000) · réversible : Pascal corrige docs/brief.md à tout moment.
2026-11-16 · Claude (orchestrateur) · — · délégué · décision : ADR 0001 (package R + targets), 0002 (une branche poussée, branches locales par mission), 0003 (jeux d'essai réels réduits sinon synthétiques marqués synth_) acceptées · prix : renv.lock non figé ; relecture humaine groupée à la fusion · réversible : nouvelle ADR qui remplace.
2026-11-16 · Claude (orchestrateur) · — · délégué · décision : massif test provisoire Ribeauvillé – Brézouard – Taennchel (Haut-Rhin), carré de 15 km (225 km²), EPSG:2154 xmin 1007000 ymin 6790000 xmax 1022000 ymax 6805000, choisi pour couvrir piémont (≈ 250 m) à crêtes (Brézouard ≈ 1 200 m) et grès vosgien / roches cristallines, à confirmer par la mission 001 · prix : choix sur connaissance générale, non vérifié sur la BD Charm-50 ni sur la couverture LiDAR HD au moment du choix · réversible : config.yml.
2026-11-16 · Claude (orchestrateur) · — · délégué · décision : porte n° 2, équipe de 11 missions (pilotage/equipe.md) ; pas de mission testeur séparée, le dev écrit ses tests et le relecteur les contrôle ; plafond 3 missions en relecture · prix : les tests ne sont pas écrits sans lire le code (indépendance moindre que la méthode ne le veut) · réversible : ajouter des missions testeur au bilan.
2026-11-16 · Claude (orchestrateur) · — · délégué · décision : résolution provisoire 25 m, tampon 5 km (bornes prudentes du brief pour le calcul) · prix : moins de détail qu'à 10 m · réversible : config.yml.
