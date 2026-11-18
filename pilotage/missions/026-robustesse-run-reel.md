# Mission 026 — robustesse du run réel : reprise réseau, ancrage GBIF vide

## Mission

**En une phrase (quoi, et pourquoi) :** ajouter une reprise sur erreur réseau aux
téléchargements (`fetch_cached` et appels voisins) et faire rendre à `gbif_anchors()` un
résultat vide signalé au lieu d'une erreur quand aucune maille n'est bioindiquée, pour que
le run réel de 018 (plus de 10 h sur 225 dalles) ne s'arrête plus sur un incident
passager ni sur une petite emprise.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : point d'étape de 018 (journal du 2026-11-18) : erreur HTTP/2 « Stream error in the HTTP/2 framing layer » sur une dalle ; `R/pipeline_reel.R:1247` `pts$source <- "gbif"` sur un sf de 0 ligne (« replacement has 1 row, data has 0 ») | |
| Les moyens ? | oui : tests sans réseau (téléchargement simulé) | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale ; recommandation du dev de 018 retenue par l'orchestrateur._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `R/pipeline_reel.R` (`fetch_cached`, `gbif_anchors`, lecture Tichý si le bruit « New names » vient de là), `R/indicateurs.R` (même raison), leurs tests, `docs/pipeline.md`.
- **Ne doit pas :** toucher à `_targets.R` ni à `inst/rapport/` (mission 022) ; changer une méthode de calcul.

## Attendus

1. Reprise : 3 tentatives par défaut, attente croissante (par ex. 5, 20, 60 s), fichier partiel supprimé avant chaque reprise, message à chaque tentative ; nombre de tentatives réglable (`config.yml` : `download_retries`, provisoire) ; test avec un téléchargement simulé qui échoue deux fois puis réussit, et un qui échoue toujours (erreur claire après N tentatives).
2. `gbif_anchors()` : grille vide → sf de 0 ligne avec les colonnes attendues (`source`, `loc_precision_m`…), avertissement `sylvostation_non_calcule` ; l'aval (modèle trophique local) accepte ce vide et l'état de preuve dit « non atteint (aucune maille GBIF) » ; test.
3. Message « New names » répété à la lecture du classeur Tichý : supprimé ou réduit à un message unique (`.name_repair` explicite) ; test inchangé.

## Dépend de / rouge attendu jusqu'à

- **Précède :** 025 (même fichier `R/pipeline_reel.R`) puis la relance de 018.

## Tests

`.claude/test-command` vert, sans réseau.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
