# Changelog

## sylvostation 2026.11.0 (développement)

Versionnage calendaire `AAAA.MM.N` : voir `README.md` (« Versions et
releases ») et
`docs/adr/0005-version-calendaire-release-automatique.md`. Le `N` de
`DESCRIPTION` reste à 0 en développement ; la release automatique y
écrit le compteur du mois dans le tarball. Le changelog de chaque
release est généré à partir des commits depuis le tag précédent.

### Mission 039 : bioclimat et RU plus fins

- **Changement d’interface :**
  [`lateral_balance()`](https://pobsteta.github.io/sylvostation/reference/lateral_balance.md)
  exige désormais `coef` (sans valeur par défaut) ; les coefficients du
  tableau 20 de Piedallu et al. (2006), à vérifier, sont lus dans
  `config.yml` (`bilan_lateral_coef`, valeur par défaut de
  [`read_config()`](https://pobsteta.github.io/sylvostation/reference/read_config.md)).
  Mission 039b.

### Mission 025 : grille de 20 m (ADR 0007)

- `resolution_m: 20` (au lieu de 25), grille en Lambert-93 dont les
  bords sont des multiples de 20 m.
- Noms de sortie sans résolution : le fichier `hydrique_25m.tif`
  s’appelle désormais `hydrique.tif` (et `synth_hydrique.tif`) ; la
  couche `grad_hydrique_25m` s’appelle `grad_hydrique_carte`
  (`FINE_VARIABLES`). Les anciens noms ne sont plus produits.
- [`evidence_table()`](https://pobsteta.github.io/sylvostation/reference/evidence_table.md)
  accepte `resolution_m` ;
  [`evidence_table_real()`](https://pobsteta.github.io/sylvostation/reference/evidence_table_real.md)
  lit le fait `resolution_m`.
- La comparaison à la référence (50 m) se fait à 100 m (plus petit
  multiple commun).
