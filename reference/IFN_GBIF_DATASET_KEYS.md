# Jeu GBIF des relevés de l'inventaire forestier national

`datasetKey` du jeu « Relevés floristiques du protocole de l'Inventaire
National Forestier de l'IGN » dans GBIF (`docs/referentiels.md`, § 8).
Ses occurrences déclarent souvent une incertitude de 1 m alors que l'IGN
publie les placettes à 700 m près :
[`clean_occ()`](https://pobsteta.github.io/sylvostation/reference/clean_occ.md)
l'exclut quelle que soit l'incertitude déclarée.

## Usage

``` r
IFN_GBIF_DATASET_KEYS
```

## Format

Un vecteur de caractères.
