# Mission 037 — ancrages trophiques bien localisés : GBIF et peuplements purs de la BD Forêt v2

## Mission

**En une phrase (quoi, et pourquoi) :** multiplier les points d'ancrage localisés à 25 m ou mieux
qui portent une valeur trophique, en comprenant pourquoi le run 018 n'a gardé que 5 ancrages
GBIF sur ≈ 9 000 occurrences ouvertes à ≤ 25 m (§ 33), et en testant l'idée de Pascal : la
relation essence → trophique apprise à l'intérieur des placettes IFN (sans leur position),
appliquée aux polygones de peuplements purs de la BD Forêt v2.

## Ma réponse d'abord

Mesure de l'orchestrateur (journal, 2026-11-19) : sur 1 520 placettes pures de la GRECO D,
l'essence explique 24 % de la variance du trophique ; extrêmes nets (pin sylvestre 3,12 ;
aulne glutineux 5,78), milieu flou (sapin, hêtre, épicéa : écart-type 0,8 à 1,0 pour 1,01 au
total). Quatre limites à vérifier : nomenclature TFV de la BD Forêt v2 (regroupements
d'essences : chênes, sapin-épicéa, « autres feuillus » ?), sylviculture (épicéa, douglas
plantés), circularité (l'indice trophique contient-il les arbres ?), hétérogénéité des
polygones (≥ 0,5 ha ; n'en garder que l'intérieur).

## L'Homme

- **Agent :** `dev` · **Modèle :** opus (plan d'abord)
- **Temps de la main :** donner. **Degré :** le chef tranche, après le plan.

## Harnais

- **Peut :** au plan, lire et mesurer (scratchpad, caches, store de 018 en lecture) ; après
  validation : `R/ancrage.R`, `_targets.R` (cibles d'ancrage), `config.yml`, `R/config.R`,
  tests, `docs/pipeline.md`, `docs/referentiels.md` (section datée).
- **Câblé :** règle des 700 m (la relation essence → trophique s'apprend aux placettes IFN
  sans aucune variable fine ; les variables fines ne s'extraient qu'aux ancrages précis) ;
  `loc_precision_m` sur toute table de points ; licences (CC BY seulement pour GBIF, BD Forêt
  sous licence ouverte à vérifier).
- **Ne doit pas :** toucher au worktree de 018 ni à `data/sorties/D11/` ; utiliser des
  occurrences CC BY-NC, Pl@ntNet ou IFN republiées dans GBIF.

## Attendus

1. Plan : (a) diagnostic des 5 ancrages (effectif à chaque filtre et cause) ; (b) nomenclature
   TFV vérifiée à la source, essences séparables ; (c) relation essence → trophique sans les
   arbres dans l'indice ; (d) nombre d'ancrages BD Forêt dans D11 (intérieur des polygones) ;
   (e) gain mesuré sur le trophique de la carte (ou, à défaut, accord avec CarHab et avec les
   ancrages GBIF) ; coût, prix, recommandation.
2. Après validation : ancrages câblés, testés.

## Dépend de

033 (intégration) pour le code ; le plan peut commencer.

## Tests

`.claude/test-command` vert.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
