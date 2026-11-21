# Recoder des gradients en code à trois chiffres de la référence

Applique les seuils de la référence (et non les nôtres) aux gradients,
puis forme le code à trois chiffres de la carte de Gégout et al. : un
chiffre par axe (6 classes trophiques, 5 bioclimatiques, 4 classes
d'eau, soit 120 combinaisons ; 59 types retenus par la carte). **L'ordre
des chiffres** (`order`) et les **seuils** de la référence ne sont pas
vérifiés (article de la Revue forestière française à obtenir) : à
vérifier. Une valeur égale à un seuil tombe dans la classe supérieure ;
une valeur manquante donne `NA`.

## Usage

``` r
recode_3digits(
  gradients,
  thresholds_ref,
  order = c("trophic", "bioclim", "hydric")
)
```

## Arguments

- gradients:

  `data.frame` (ou `sf`) avec une colonne numérique par gradient.

- thresholds_ref:

  Liste nommée de seuils croissants par gradient (voir
  [`default_thresholds()`](https://pobsteta.github.io/sylvostation/reference/default_thresholds.md)
  pour la forme). Au plus 9 classes par axe.

- order:

  Ordre des gradients dans le code (défaut : trophique, bioclimat, eau).

## Value

Un `data.frame` : colonnes `<gradient>_ref` (classe entière) et `code3`
(chaîne de trois chiffres, `NA` si un axe manque).

## Details

Écart à la fiche : le premier argument s'appelle `gradients` (valeurs
des gradients) et non `types`, car recoder avec d'autres seuils exige
les valeurs, pas des classes.

## Examples

``` r
g <- data.frame(trophic = c(-1, 0, 2), hydric = c(0, 1, 1), bioclim = c(0, 0, 1))
th <- list(trophic = c(-0.5, 0.5), bioclim = 0.5, hydric = 0.5)
recode_3digits(g, th)$code3
#> [1] "111" "212" "322"
```
