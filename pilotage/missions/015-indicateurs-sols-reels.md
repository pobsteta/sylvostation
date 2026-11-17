# Mission 015 — valeurs indicatrices et pédotransfert réels

## Mission

**En une phrase (quoi, et pourquoi) :** remplacer les valeurs indicatrices et les
coefficients de réserve utile synthétiques par les référentiels publiés (Baseflor ou
EcoPlant, table de pédotransfert), parce que la bioindication et le gradient hydrique ne
valent rien tant qu'ils reposent sur des valeurs fabriquées.

**Redite par l'agent :** _à compléter par l'agent._

## Les trois questions (règle de staffing)

| Question | Réponse | Conséquence |
|---|---|---|
| Redire en une phrase ? | oui | |
| Sait-il comment faire ? | oui après 013 (§ valeurs indicatrices, § sols) | dépend de 013 |
| Les moyens ? | oui si 013 trouve une source joignable ; sinon chargeur prêt et valeurs synthétiques gardées | |

**Temps de la main :** donner. **Degré :** le chef tranche.

## Ma réponse d'abord

_Délégation totale._

## L'Homme

- **Agent :** `dev` · **Modèle :** sonnet

## Harnais

- **Peut (périmètre) :** `R/indicateurs.R` (nouveau), `R/sols.R`, `R/placettes.R` (coefficients de RU, `ru_verifie`), `R/ancrage.R` (jointure des valeurs indicatrices), leurs tests, `inst/extdata/` (seulement des extraits sous licence ouverte, avec `SOURCES.md`), `DESCRIPTION`, `NAMESPACE`, `man/`.
- **Câblé :** pas de `main` ; journal en ajout seul.
- **Ne doit pas :** versionner un extrait sous licence non ouverte (il se télécharge à l'exécution dans `data/`) ; toucher à `_targets.R`.
- **Sources autorisées :** `docs/referentiels.md`, `docs/brief-technique.md` (étapes 2 et 4), mission 006 et 007.

## Attendus

`load_indicator_values(source = c("ecoplant", "baseflor"), path)` : table au format de
`synth_indicateurs.csv` (jointure TAXREF `CD_NOM` puis `CD_REF`, non-appariés listés) ;
`ru_coefficients(source)` : table publiée citée ; l'attribut `ru_verifie` passe à TRUE
quand la table publiée est utilisée ; taux d'appariement des espèces des 100 placettes IFN
réelles dans le compte rendu.

## Valeur provisoire (chiffre, réglage)

Aucune nouvelle ; les coefficients publiés remplacent les provisoires.

## Dépend de / rouge attendu jusqu'à

- **Dépend de :** 013. **Ordre de fusion :** 013 → 015 (indépendante de 014 : aucun fichier commun).

## Tests

Un test par fonction ; non-appariés listés, jamais supprimés.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
