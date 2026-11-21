# Lire les règles de recodage lithologique

Lire les règles de recodage lithologique

## Usage

``` r
read_lithology_rules(
  path = system.file("extdata", "lithologie_regles.csv", package = "sylvostation")
)
```

## Arguments

- path:

  Chemin d'un CSV de règles (colonnes `priorite`, `motif`, `classe`,
  `commentaire`). Par défaut, `inst/extdata/lithologie_regles.csv`.

## Value

Un `data.frame` de règles, trié par priorité.

## Examples

``` r
read_lithology_rules()$classe
#>  [1] "conglomerat"             "gres"                   
#>  [3] "granite"                 "gneiss_migmatite"       
#>  [5] "roche_basique"           "granite"                
#>  [7] "loess"                   "colluvions_eboulis"     
#>  [9] "alluvions"               "alluvions"              
#> [11] "colluvions_eboulis"      "glaciaire"              
#> [13] "glaciaire"               "schiste_grauwacke"      
#> [15] "schiste_grauwacke"       "plutonite_intermediaire"
#> [17] "plutonite_intermediaire" "volcanite"              
#> [19] "roche_basique"           "granite"                
#> [21] "calcaire"                "marne_argile"           
#> [23] "marne_argile"            "marne_argile"           
#> [25] "calcaire"                "calcaire"               
#> [27] "gres"                   
```
