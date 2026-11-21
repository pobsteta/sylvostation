# Réserve utile par la texture IFN : euptf2, contre-vérifiée par Bruand et al. (2004)

Chaîne de l'ADR 0006 : code de texture IFN
([`read_texture_dictionary()`](https://pobsteta.github.io/sylvostation/reference/read_texture_dictionary.md))
→ granulométrie représentative
([`texture_to_psd()`](https://pobsteta.github.io/sylvostation/reference/texture_to_psd.md))
→ eau disponible par la fonction de pédotransfert européenne `euptf2`
(Szabó, Weynants et Weber 2021, *Geoscientific Model Development* 14 :
151-175 ; PTF01 : sable, limon, argile et profondeur) → réserve utile
`ru_mm` = somme sur les deux horizons de l'eau disponible × épaisseur,
réduite par la charge en éléments grossiers.

## Usage

``` r
ru_from_texture(
  pl,
  ru_source = c("euptf2", "bruand2004"),
  cible = c("AWC_2", "AWC"),
  ptf = "PTF01",
  dictionnaire = read_texture_dictionary()
)
```

## Arguments

- pl:

  Tableau des placettes (`ifn$placettes` de
  [`load_ifn()`](https://pobsteta.github.io/sylvostation/reference/load_ifn.md),
  `sf` accepté) avec `PROF1`, `PROF2`, `TEXT1`, `TEXT2`, `CAILLOUX`,
  `OBSPEDO` (en caractères).

- ru_source:

  Source de `ru_mm` : `"euptf2"` (défaut) ou `"bruand2004"`.

- cible:

  `"AWC_2"` (pF 2,0, défaut) ou `"AWC"` (pF 2,5).

- ptf:

  Fonction de pédotransfert `euptf2` (`"PTF01"` : granulométrie et
  profondeur).

- dictionnaire:

  Résultat de
  [`read_texture_dictionary()`](https://pobsteta.github.io/sylvostation/reference/read_texture_dictionary.md).

## Value

Un `data.frame` (une ligne par placette, `id_placette` si présent) :
`ep_haut_cm`, `ep_bas_cm`, `code_haut`, `code_bas`, `cailloux`,
`awc_haut`, `awc_bas` (cm3/cm3), `ru_euptf2_mm`, `ru_bruand_mm`,
`ru_mm`, `ecart_mm`, `texture_partielle`. Attributs `ru_verifie`,
`ru_source`, `source`, `cible`, `ptf`.

## Details

- **Eau disponible** : `cible = "AWC_2"` (défaut) = θ à -100 cm (pF 2,0)
  moins θ à -15 000 cm (pF 4,2), comme la colonne « défaut » de Bruand
  et al. ; `"AWC"` : capacité au champ à -330 cm (pF 2,5). Calculée
  comme **différence des fonctions ponctuelles** `FC_2` (ou `FC`) et
  `WP`, comme le recommande le README d'`euptf2`, et non par la fonction
  `AWC_2` directe. Profondeur `DEPTH_M` : milieu de l'horizon.

- **Horizons** : `PROF1` (horizon supérieur, dm) et `PROF2` (profondeur
  de sondage, dm) ; sol homogène (`TEXT1` 0 ou vide, `PROF1` vide) : un
  seul horizon `TEXT2`.

- **Cailloux** : `CAILLOUX` en dixièmes du volume, pris au centre de la
  classe IFN (`0` = moins de 5 % → 2,5 % ; `10` = plus de 95 % → 97,5 %
  ; `X` = absence).

- **Cas particuliers** : sans fosse (`OBSPEDO` 5 ou X), sans `PROF2` ou
  `TEXT2` : `NA` ; horizon organique (`H`) : `NA` (non modélisé) ;
  `OBSPEDO` R (horizon entièrement caillouteux) : 0 ; code `0` (absence
  de terre fine) : 0 pour l'horizon.

**Deux sources** : `ru_euptf2_mm` (chaîne ci-dessus) et `ru_bruand_mm`,
calculée avec les mêmes épaisseurs et cailloux et les coefficients de
[`ru_coefficients()`](https://pobsteta.github.io/sylvostation/reference/ru_coefficients.md)
(Bruand et al. 2004, colonne défaut, horizon A pour `TEXT1`, horizons E,
B, C pour `TEXT2`). `ru_mm` reprend celle de `ru_source` (`"euptf2"` par
défaut, décision de l'orchestrateur du 2026-11-17) ; `ecart_mm` =
`ru_euptf2_mm` - `ru_bruand_mm`. Avec `ru_source = "bruand2004"`,
`euptf2` et `soiltexture` ne sont pas requis (colonnes `euptf2` à `NA`
s'ils manquent).

`ru_verifie` (attribut) vaut `TRUE` seulement si la chaîne est
entièrement sourcée : dictionnaire IFN lu, classes identifiées dans le
triangle de l'Aisne, `euptf2` appelé. La colonne `texture_partielle`
signale les placettes dont un code comporte une classe hors du triangle
(`Als`, code 8), non représentée dans la granulométrie.

## Examples

``` r
# \donttest{
if (all(vapply(c("euptf2", "soiltexture", "ranger"), requireNamespace, TRUE,
               quietly = TRUE))) {
  ifn <- load_ifn(system.file("extdata", package = "sylvostation"),
                  files = c("PLACETTE", "ECOLOGIE"))
  ru <- ru_from_texture(ifn$placettes)
  summary(ru$ru_mm)
}
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.     NAs 
#>    0.00   47.82   69.15   78.11  106.66  216.68       3 
# }
```
