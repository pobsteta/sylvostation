# Nettoyer des occurrences GBIF et les reprojeter en Lambert-93

Étapes (nombre d'occurrences conservé à chacune dans
`attr(, "clean_log")`) :

1.  coordonnées présentes, espèce renseignée ; reprojection de WGS84
    vers EPSG:2154 **dès l'import**
    ([`assert_crs_2154()`](https://pobsteta.github.io/sylvostation/reference/assert_crs_2154.md))
    ;

2.  exclusion des jeux de `exclude_datasets` (par défaut le jeu IFN,
    [IFN_GBIF_DATASET_KEYS](https://pobsteta.github.io/sylvostation/reference/IFN_GBIF_DATASET_KEYS.md))
    : leur incertitude déclarée (1 m) est fausse. Si on les garde
    (`exclude_datasets = character(0)`), ils sont marqués
    `source = "ifn"` et `loc_precision_m = 700` (comme
    [`mark_ifn()`](https://pobsteta.github.io/sylvostation/reference/mark_ifn.md))
    ; 2 bis. licence et Pl@ntNet, **dans cet ordre**, chaque occurrence
    n'étant comptée que par le premier motif qui l'écarte : (i) licence
    non commerciale (code `CC_BY_NC*`, toute variante, URL, code ou
    écriture en toutes lettres) si `exclude_noncommercial` (défaut
    `TRUE`) ; (ii) jeux de `exclude_plantnet` (défaut
    [PLANTNET_GBIF_DATASET_KEYS](https://pobsteta.github.io/sylvostation/reference/PLANTNET_GBIF_DATASET_KEYS.md))
    ; (iii) licence absente, `UNSPECIFIED`, `UNSUPPORTED` ou autre qu'un
    code `CC_BY_<n>` (variantes comprises : la variante NC dépend de
    `exclude_noncommercial`) ou `CC0_1_0` (motif `licence_inconnue`) si
    `exclude_unknown_licence` (défaut `TRUE` : la fiche 037 veut du CC
    BY seulement). Les effectifs par motif sont rendus dans l'attribut
    `ecartees` et dans le message émis (jamais de suppression
    silencieuse) ;

3.  précision : `loc_precision_m` = `coordinateUncertaintyInMeters` ;
    elle vaut `NA` si l'incertitude est absente **ou** si
    `dataGeneralizations` / `informationWithheld` est renseigné (donnée
    généralisée). Sont gardés les points de précision ≤
    `max_uncertainty` ; les `NA` sont écartés sauf `keep_unknown = TRUE`
    (ils sont alors refusés par
    [`assert_no_fine_extract_on_ifn()`](https://pobsteta.github.io/sylvostation/reference/assert_no_fine_extract_on_ifn.md)
    pour toute extraction fine) ;

4.  forêt si `forest` est fourni : polygones BD Forêt avec une colonne
    `code_tfv` ; codes `FF*` et `FO*` hors `FF0` (provisoire : décision
    à prendre pour `FP` et `FF0`, `docs/referentiels.md` § 4) ;

5.  canopée si `canopy` est fourni : hauteur de canopée (MHC)
    strictement supérieure à `min_canopy` m. C'est une **extraction
    fine** : la règle bloquante s'applique (donc erreur si des points de
    précision `NA` ou \> 25 m subsistent).

## Usage

``` r
clean_occ(
  occ,
  max_uncertainty = 25,
  exclude_datasets = IFN_GBIF_DATASET_KEYS,
  exclude_noncommercial = TRUE,
  exclude_plantnet = PLANTNET_GBIF_DATASET_KEYS,
  exclude_unknown_licence = TRUE,
  keep_unknown = FALSE,
  forest = NULL,
  canopy = NULL,
  min_canopy = 5
)
```

## Arguments

- occ:

  `data.frame` d'occurrences GBIF (WGS84) : `decimalLongitude`,
  `decimalLatitude`, `species` ; facultatives : `gbifID` (ou `key` en
  mode `"search"`), `speciesKey`, `datasetKey`, `license`, `year`,
  `coordinateUncertaintyInMeters`, `dataGeneralizations`,
  `informationWithheld`.

- max_uncertainty:

  Précision maximale gardée, en mètres (25).

- exclude_datasets:

  `datasetKey` à écarter.

- exclude_noncommercial:

  Écarter les licences `CC_BY_NC*` (`TRUE`).

- exclude_plantnet:

  `datasetKey` Pl@ntNet à écarter (défaut
  [PLANTNET_GBIF_DATASET_KEYS](https://pobsteta.github.io/sylvostation/reference/PLANTNET_GBIF_DATASET_KEYS.md)
  ; `character(0)` pour les garder).

- exclude_unknown_licence:

  Écarter les licences absentes ou autres que la famille CC BY et CC0
  (`TRUE`).

- keep_unknown:

  Garder les points de précision inconnue (`FALSE`).

- forest:

  Polygones BD Forêt (`sf`, EPSG:2154, colonne `code_tfv`) ou `NULL`.

- canopy:

  `SpatRaster` de hauteur de canopée (EPSG:2154) ou `NULL`.

- min_canopy:

  Hauteur minimale de canopée, en mètres (5).

## Value

Un objet `sf` (points, EPSG:2154) avec `gbif_id`, `species`,
`species_key`, `dataset_key`, `license`, `year`, `loc_precision_m`,
`source`, et les attributs `clean_log` et `ecartees` (`data.frame`
`motif`, `n` : `licence_non_commerciale`, `plantnet`,
`licence_inconnue`).

## Details

La licence de chaque jeu (`license`) est conservée et normalisée en code
de type `CC_BY_4_0`, `CC_BY_NC_4_0` ou `CC0_1_0` (GBIF la donne tantôt
en URL, tantôt en code).

## Examples

``` r
f <- system.file("extdata", "synth_occ.csv", package = "sylvostation")
if (nzchar(f)) {
  p <- clean_occ(utils::read.csv(f))
  attr(p, "clean_log")
}
#> clean_occ : 1 occurrence(s) ecartee(s) pour licence non commerciale, 0 pour Pl@ntNet, 0 pour licence absente ou non reconnue.
#>                   etape  n
#> 1                entree 21
#> 2 coordonnees_presentes 20
#> 3     espece_renseignee 20
#> 4      hors_jeux_exclus 18
#> 5       hors_licence_nc 17
#> 6         hors_plantnet 17
#> 7 hors_licence_inconnue 17
#> 8     precision_retenue 14
```
