# Mission 034 — prédicteurs du trophique et variables de Piedallu et al. (2006) compatibles avec la règle des 700 m

## Mission

**En une phrase (quoi, et pourquoi) :** donner au modèle trophique ses prédicteurs édaphiques
(géologie en classes de richesse chimique) et ajouter les variables de Piedallu et al. (2006)
qui respectent la règle des 700 m, parce que le trophique du run 018 repose sur 2 variables
climatiques de maille (R² ≈ 0, 11 valeurs distinctes) alors que le brief (étape 5) prévoit
géologie, pédopaysage et pH, et que le modèle de référence vosgien atteint R² 0,36.

**Redite par l'agent :** _à compléter par l'agent._

## Source

Piedallu C., Gégout J.-C., Cornu J.-F., Cluzeau C. (2006), *Cartographie prédictive des
stations forestières du massif vosgien. Élaboration, validation et applications*, rapport
ENGREF-IFN, HAL `hal-00835906`. Copie locale (lecture seule, **ne pas copier dans le dépôt**,
licence non précisée) : `/home/pascal/dev/nemetonplateforme/docs/Piedallu_al_2006_etude_CAS.pdf`.
Passages utiles : § 2.4 (classes de richesse a à e, rapport Si/(Ca+Mg+Fe)), § 2.5 (définition
des indices), § 3.2 (tableaux 6, 12, 18, 20 : variables retenues), § 3.2.3.3-3.2.3.4 (bilan
latéral −30/0/+60 mm, classes de réserve en eau), annexe 1 (appartenance des roches aux classes).

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | en partie : plan d'abord | plan rendu avant tout code |
| Les moyens ? | oui : rapport ci-dessus, BD Charm-50 (`read_geology()`, recodage provisoire), `geologie_700m`, sorties de 018 | |

**Temps de la main :** donner. **Degré :** le chef tranche, après le plan.

## Ma réponse d'abord

_Décidé avec Pascal le 2026-11-19 (« oui, ouvre la mission et intègre-la à la 034 »)._ Périmètre :

1. **Trophique** : classes de richesse a à e des roches, reprises de l'annexe 1 et appariées
   aux formations BD Charm-50 de l'emprise (table de correspondance proposée, formations non
   classées listées, jamais affectées par défaut ; la table reste une décision réservée à Pascal,
   brief technique l. 12) ; dominante dans 700 m pour les placettes IFN.
2. **Bioclimat** : latitude ; cosinus de l'exposition à la cellule de la carte seulement (pas
   aux placettes IFN) ; indices de Gams (corrigé Michallet 1991, « à vérifier ») et de
   De Martonne, jours de gel, Tmin/Tmax, calculés depuis le climat de maille (033).
3. **Relief à large rayon** : dénivelé ID 2000 m, seulement si l'agent démontre qu'un rayon
   de 2 000 m rend la variable insensible à un déplacement de 700 m (mesure, pas affirmation) ;
   sinon : carte seulement.
4. **Bilan latéral** (carte seulement) : formulation de Piedallu (courbure 150 m, IDR 1500 m,
   indice de Moore → −30/0/+60 mm). Les coefficients du tableau 20 ont été calibrés sur
   EcoPlant dans les Vosges : leur reprise telle quelle est un choix à exposer au plan.
5. Région naturelle : à discuter au plan (une seule SER dans l'emprise test).

Hors périmètre : ID 250, IDR 250, distance à la crête calibrés aux placettes (exigent des
placettes localisées à 150 m : EcoPlant, GNSS 029) ; tout extrait du rapport dans `inst/extdata`.

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (plan d'abord)

## Harnais

- **Peut (périmètre) :** au plan, lire et mesurer (scratchpad) ; après validation :
  `R/geologie.R`, `R/modeles.R`, `R/pipeline_reel.R` (prédicteurs), `R/terrain.R` (nouveaux
  indices), `R/utils.R` (`FINE_VARIABLES`, `COARSE_VARIABLES`), `_targets.R`, `config.yml`,
  `R/config.R`, leurs tests, `docs/pipeline.md`, `docs/referentiels.md` (section datée).
- **Câblé :** règle des 700 m (tout nouvel indice de relief entre dans `FINE_VARIABLES` sauf
  démonstration chiffrée) ; chaque formule citée avec sa page du rapport ou marquée « à
  vérifier » ; R² trophique et bioclimatique avant/après, par blocs.
- **Ne doit pas :** toucher au worktree de 018 ni réécrire `data/sorties/D11/` ; affecter une
  formation géologique à une classe sans source ; copier le PDF ou ses tableaux dans le dépôt.

## Attendus

1. Plan : variables retenues, table de correspondance roches → classes (brouillon), test de
   sensibilité de l'ID 2000 m au déplacement de 700 m, coût, prix, recommandation.
2. Après validation : prédicteurs testés et câblés ; R² avant/après.

## Dépend de / rouge attendu jusqu'à

- 033 (climat de maille descendu, mêmes fichiers `_targets.R`, `R/hydrique.R`) : code après
  l'intégration de 033 ; le plan peut commencer avant.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur ; la table roches → classes, Pascal.
