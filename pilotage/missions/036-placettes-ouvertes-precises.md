# Mission 036 — trouver des relevés floristiques ouverts et précisément localisés

## Mission

**En une phrase (quoi, et pourquoi) :** inventorier les sources ouvertes de relevés ou
d'occurrences floristiques localisés à 25 m ou mieux dans la SER D11 (ou la GRECO D), pour
calibrer le lien entre gradients et relief fin comme Piedallu et al. (2006) le faisait avec
EcoPlant, sans demande d'accès (Pascal, 2026-11-19 : « trouve une autre solution »).

## Pistes à vérifier (rien n'est acquis)

- sPlotOpen (Sabatini et al. 2021) : relevés ouverts, licence par jeu, champ d'incertitude de
  localisation ; part française et vosgienne ?
- GBIF : regrouper les occurrences à ≤ 25 m (même observateur, même date, même lieu) en
  pseudo-relevés ; combien dans D11, combien d'espèces par groupe ?
- OpenObs / INPN (SINP), données des CBN en diffusion ouverte : précision réelle (floutage ?).
- Réseaux de placettes à coordonnées publiques : RENECOFOR, autres réseaux forestiers.
- Données de pH ou de sol à placettes publiques (RMQS : coordonnées publiées ou non ?).

## L'Homme

- **Agent :** `acquereur` · **Temps de la main :** donner.

## Harnais

- **Peut :** écrire une section datée de `docs/referentiels.md` (CQQCOQP, plusieurs sources par
  point, URL consultées, licences) ; rien dans `inst/extdata`.
- **Ne doit pas :** demander un accès, créer un compte, télécharger plus qu'un extrait de
  contrôle ; présenter une précision non vérifiée sur données.

## Attendus

Pour chaque source : licence, volume dans D11 et GRECO D, précision de localisation (vérifiée
sur un extrait), date, protocole, recommandation. Recommandation finale classée.

## Qui veille, qui tranche

Relecteur, puis l'orchestrateur.
