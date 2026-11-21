# Filtrer les relevés floristiques IFN

Garde les relevés floristiques **en saison** (mois de `DATEECO`, date de
validation du levé écologique et floristique, dans `months`), sans
**perturbation récente** (incident des 5 dernières années : `NINCID` de
1 à 5, ou `INCID` \>= 1 ; codes de `metadonnees.csv`, `NINCID` n'existe
qu'à partir de la campagne 2015 et `INCID` de 2009 : en deçà, la
perturbation est inconnue et le relevé est conservé), puis les espèces
présentes dans au moins `min_occ` relevés retenus. Les lignes de `FLORE`
signalées incohérentes (`INCO_FLOR` renseigné : eau, artefact, lisière,
roche, autre) sont écartées. Les placettes ne sont pas supprimées :
elles gagnent les colonnes `mois_releve`, `en_saison`, `perturbe` et
`retenu`.

## Usage

``` r
filter_releves(ifn, min_occ = 3, months = 4:9, exclude_incidents = TRUE)
```

## Arguments

- ifn:

  Résultat de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md).

- min_occ:

  Nombre minimal de relevés retenus où une espèce doit figurer.

- months:

  Mois (1 à 12) valides.

- exclude_incidents:

  Exclure les relevés perturbés récemment.

## Value

`ifn`, avec `placettes` complétée et `flore` filtrée ; l'attribut
`filtre` résume les effectifs.

## Details

Valeurs provisoires : mois 4 à 9 et seuil de 3 relevés (brief
technique), règle de perturbation (à geler avant la phase 1).

## Examples

``` r
ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
f <- filter_releves(ifn)
attr(f, "filtre")
#> $n_placettes
#> [1] 100
#> 
#> $n_en_saison
#> [1] 51
#> 
#> $n_perturbees
#> [1] 5
#> 
#> $n_retenues
#> [1] 49
#> 
#> $n_lignes_flore_avant
#> [1] 2238
#> 
#> $n_lignes_flore_apres
#> [1] 1156
#> 
#> $n_especes
#> [1] 116
#> 
#> $min_occ
#> [1] 3
#> 
#> $months
#> [1] 4 5 6 7 8 9
#> 
```
