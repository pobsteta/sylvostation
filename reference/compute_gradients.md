# Calculer les gradients écologiques par placette

Trois familles de gradients, sans aucune variable fine :

## Usage

``` r
compute_gradients(
  ifn,
  indicateurs = NULL,
  climat = NULL,
  ru_table = ru_coefficients(),
  min_res_ifn_m = 1000,
  exclude_cd_ref = NULL,
  abundance_weights = FALSE
)
```

## Arguments

- ifn:

  Résultat de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md)
  (de préférence passé par
  [`filter_releves()`](https://pobsteta.github.io/sylvostation/reference/filter_releves.md)).

- indicateurs:

  `data.frame` des valeurs indicatrices (colonne `cd_ref` en TAXREF
  v13.0, colonnes `ph`, `azote`), ou `NULL` pour l'AFC. Voir
  `inst/extdata/synth_indicateurs.csv` (synthétique).

- climat:

  `SpatRaster` ou `NULL`. Maille d'au moins `min_res_ifn_m`, quel que
  soit le nom des couches ; agréger avant avec
  [`aggregate_to_km()`](https://pobsteta.github.io/sylvostation/reference/aggregate_to_km.md).

- ru_table:

  Vecteur nommé de coefficients mm/cm par code de texture, ou liste
  `haut`, `bas` (horizon supérieur `TEXT1`, horizon inférieur `TEXT2`),
  voir
  [`ru_coefficients()`](https://pobsteta.github.io/sylvostation/reference/ru_coefficients.md).
  `ru_verifie` du résultat vaut `TRUE` seulement si `verifie` est vrai
  et si `correspondance_verifiee` n'est pas faux ; l'attribut
  `correspondance_verifiee` est repris tel quel.

- min_res_ifn_m:

  Maille minimale (m) d'une couche croisée avec des placettes IFN : 1000
  (brief technique, étape 5 : climat et pH agrégés à 1 km).

- exclude_cd_ref:

  `NULL` ou vecteur de `CD_REF` (TAXREF v13) **exclus** de l'indice
  trophique, par exemple les essences arborées
  ([`read_tree_cd_ref()`](https://pobsteta.github.io/sylvostation/reference/read_tree_cd_ref.md))
  : l'indice ne décrit alors plus le peuplement (mission 035, ADR 0008).
  `NULL` : aucune exclusion (comportement historique).

- abundance_weights:

  `TRUE` : moyenne des valeurs indicatrices pondérée par
  l'abondance-dominance `ABOND` (classes 1 à 5, milieux de classes 2,5 ;
  15 ; 37,5 ; 62,5 ; 87,5 % : **à vérifier**) ; `FALSE` : moyenne simple
  (historique).

## Value

Un `sf` (Lambert-93) : `id_placette`, `CAMPAGNE`, `IDP`, `source`,
`loc_precision_m`, `n_taxa_indic`, `grad_ph`, `grad_azote`,
`grad_trophique`, `ru_mm`, `engorg_prof_cm`, `engorgement` et, si
`climat`, les colonnes `coarse_`. Attributs : `methode_trophique`
(`"indicateurs"` ou `"afc"`) et `taxa_non_apparies` (voir
[`unmatched_taxa()`](https://pobsteta.github.io/sylvostation/reference/unmatched_taxa.md)).

## Details

- **trophique** : moyenne, par placette, des valeurs indicatrices
  (colonnes `ph` et `azote` de `indicateurs`) des espèces présentes ;
  `grad_trophique` est la moyenne des colonnes disponibles. Sans table
  `indicateurs`, repli sur l'axe 1 d'une AFC
  ([`ade4::dudi.coa`](https://adeverse.github.io/ade4/reference/dudi.coa.html))
  de la matrice présence/absence : le signe de l'axe est arbitraire.

- **hydrique** : réserve utile `ru_mm` par pédotransfert (texture,
  profondeur, éléments grossiers ; coefficients `ru_table`, par défaut
  [`ru_coefficients()`](https://pobsteta.github.io/sylvostation/reference/ru_coefficients.md)
  **à vérifier**) et engorgement (`engorg_prof_cm`, profondeur du
  premier signe d'hydromorphie ; `engorgement`). Aucun indice composite
  n'est inventé : les deux colonnes sont rendues.

- **bioclimatique** : si `climat` est fourni (`SpatRaster` en EPSG:2154
  de maille au moins 90 m, couches nommées `p_sv`, `etp_sv` (cumuls de
  la saison de végétation, mm) et `t_moy` (°C) ; convention de ce
  paquet), extraction aux placettes : `coarse_p_etp_sv` (P - ETP) et
  `coarse_t_moy`. La règle bloquante est appliquée avant toute
  extraction.

## Examples

``` r
ifn <- filter_releves(load_ifn(system.file("extdata", package = "sylvostation")))
ind <- utils::read.delim(system.file("extdata", "synth_indicateurs.csv",
                             package = "sylvostation"), sep = ";")
g <- compute_gradients(ifn, ind)
head(sf::st_drop_geometry(g)[, c("id_placette", "grad_trophique", "ru_mm")])
#>      id_placette grad_trophique ru_mm
#> 95  2025_2012026       5.060000 67.83
#> 96  2025_2016787       5.148571 15.33
#> 97  2025_2031206       5.090000 45.22
#> 98  2025_2031924       5.065873 41.76
#> 99  2025_2037335       5.165079 93.96
#> 100 2025_2046433       4.934426 14.60
```
