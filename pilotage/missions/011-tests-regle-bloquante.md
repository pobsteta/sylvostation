# Mission 011 — tests d'acceptation de la règle bloquante

## Mission

**En une phrase (quoi, et pourquoi) :** écrire, sans lire le code de `R/utils.R`, les tests
d'acceptation de la règle « aucune extraction fine sur des points localisés à plus de 25 m
ou issus de l'IFN », pour que la règle la plus grave du brief ne soit pas validée par celui
qui l'a codée (mission 000, B2).

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui : `CLAUDE.md` (règles métier), `docs/spec.md`, interface publique documentée (`?assert_no_fine_extract_on_ifn`, `?mark_ifn`) | |
| Les moyens ? | oui : R, testthat, package installable | |

**Temps de la main :** appuyer.

## Ma réponse d'abord

_Délégation totale (journal, 2026-11-16)._

## L'Homme

- **Agent :** `testeur` · **Modèle :** sonnet
- **Ce qui ne lui est pas demandé :** lire ou corriger `R/utils.R`.

## Harnais

- **Peut :** écrire `tests/testthat/test-acceptation-regle-700m.R` ; lire la documentation (`man/`) et `NAMESPACE`.
- **Ne doit pas :** lire `R/` ; modifier un autre fichier.
- **Sources autorisées :** `CLAUDE.md`, `docs/spec.md`, `docs/brief-technique.md` (encadré § 3), `man/`.

## Cas à couvrir

Placettes IFN marquées + variable fine → erreur ; marquage `source` perdu après `rbind`/jointure mais `loc_precision_m = 700` → erreur ; mélange IFN et points à 10 m → erreur ; `loc_precision_m` absente ou NA → erreur ; points à 10 m + variables fines → passe ; IFN + variables larges (`coarse_*`) → passe ; liste de variables fines dont un nom en majuscules ou avec suffixe (`slope_5m`) → à dire si l'interface le prévoit.

## Valeur provisoire (chiffre, réglage)

Seuil 25 m (filtre GBIF du brief), provisoire.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 002 intégrée. **Rouge attendu :** les cas que 002 ne couvre pas : signalés, pas contournés.

## Tests

Les tests passent ou leur rouge est expliqué ; liste de contrôle passée.

## Terrain

Pascal lira la liste des cas.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur par délégation.

## Comment saura-t-on que ça marche ?

Retirer la vérification de précision dans `R/utils.R` fait échouer au moins un test.
