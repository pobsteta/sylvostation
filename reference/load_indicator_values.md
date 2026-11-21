# Valeurs indicatrices (pH, azote, humidité) jointes à TAXREF

Charge les valeurs indicatrices de type Ellenberg de Tichý et al. (2023)
(Zenodo, CC BY 4.0) et les joint à TAXREF **par le nom latin**
(`LB_NOM`), car la source suit Euro+Med et non TAXREF. Sortie au format
de `synth_indicateurs.csv` : `cd_ref`, `nom`, `ph` (colonne `REACTION`),
`azote` (`NUTRIENTS`), `humidite` (`MOISTURE`), `synthetic = FALSE`. Les
valeurs ne sont **pas** des mesures de pH : ce sont des indices ordinaux
(réaction, 1 à 9 ; nutriments, 1 à 9 ; humidité, 1 à 12).

## Usage

``` r
load_indicator_values(
  source = c("tichy", "ecoplant", "baseflor"),
  path,
  taxref,
  taxa = NULL,
  synonymes = FALSE,
  agregats = TRUE
)
```

## Arguments

- source:

  `"tichy"` (Tichý et al. 2023, seule source joignable). `"baseflor"`
  (non joignable, `docs/referentiels.md` § 14) et `"ecoplant"` (sur
  demande, AgroParisTech, jamais dans le dépôt) lèvent une erreur
  explicite.

- path:

  Chemin du classeur Zenodo `.xlsx` (téléchargé à l'exécution, cache
  hors dépôt) ou de l'extrait CSV, voir
  [`read_tichy()`](https://pobsteta.github.io/sylvostation/reference/read_tichy.md).

- taxref:

  `data.frame` de
  [`read_taxref()`](https://pobsteta.github.io/sylvostation/reference/read_taxref.md)
  ou chemin du fichier TAXREF.

- taxa:

  Codes à résoudre (facultatif), voir plus haut.

- synonymes:

  En mode `taxa` seulement. `FALSE` (défaut, prudent) : le nom retenu
  est celui du `CD_REF` v18. `TRUE` : à défaut, les **synonymes** TAXREF
  de rang espèce (autres `LB_NOM` de même `CD_REF`) sont essayés ;
  `appariement` vaut alors `"synonyme"`. Risque : un synonyme TAXREF
  peut être un nom mal appliqué (même libellé, autre taxon dans la
  source) ; à n'utiliser qu'en le disant.

- agregats:

  En mode `taxa` seulement, `TRUE` par défaut : à défaut d'autre
  appariement, une espèce ou un taxon infra-spécifique s'apparie à
  l'agrégat « binôme aggr. » de la source (`appariement = "agregat"`,
  `nom` = libellé de l'agrégat). **Approximation signalée** : l'agrégat
  englobe plusieurs espèces proches (par exemple *Dryopteris
  carthusiana* aggr. englobe *D. dilatata*, dont l'écologie diffère) ;
  la valeur est celle de l'agrégat, pas de l'espèce.

## Value

Un `data.frame`, attributs `source`, `licence`, `non_apparies`.

## Details

Deux modes :

- `taxa = NULL` : une ligne par taxon de la source apparié, `cd_ref` =
  `CD_REF` TAXREF v18 du nom (en cas de synonymes de la source sur un
  même `cd_ref`, moyenne) ;

- `taxa` = codes à résoudre (par exemple `CD_REF` de la flore IFN,
  TAXREF v13) : un `CD_NOM` ne change pas d'une version à l'autre pour
  un nom donné (méthode TAXREF, `docs/referentiels.md` § 15) ; chaque
  code est cherché comme `CD_NOM` dans TAXREF v18, son nom (celui du
  `CD_REF` v18) est apparié à la source ; **repli** pour un taxon
  infra-spécifique (sous-espèce, variété) sur son binôme. Une ligne par
  code résolu, `cd_ref` = le code **tel que donné** (jointure directe
  avec `flore$CD_REF`), colonnes `cd_ref_taxref` (v18) et `appariement`
  (`"nom"`, `"binome"`, `"synonyme"` ou `"agregat"`).

Les non-appariés ne sont jamais supprimés en silence : attribut
`non_apparies` (`data.frame` ; en mode `taxa`, colonnes `cd_ref`, `nom`,
`rang`, `motif`).

## Examples

``` r
tx <- read_taxref(system.file("extdata", "taxref_v18_extrait.csv", package = "sylvostation"))
ti <- system.file("extdata", "tichy_2023_extrait.csv", package = "sylvostation")
ind <- load_indicator_values("tichy", ti, tx)
head(ind)
#>   cd_ref                   nom  ph azote humidite synthetic
#> 1  79319            Abies alba 5.3   5.5      6.1     FALSE
#> 2  79734        Acer campestre 7.3   5.4       NA     FALSE
#> 3  79779      Acer platanoides 6.5   6.3      5.6     FALSE
#> 4  79783   Acer pseudoplatanus 5.8   6.6       NA     FALSE
#> 5  80183 Adenostyles alliariae 6.0   7.8      6.2     FALSE
#> 6  80591   Agrostis capillaris 3.5   3.3      4.9     FALSE
```
