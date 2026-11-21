# Lire le dictionnaire IFN des codes de texture

Lit l'extrait du fichier `metadonnees.csv` des données brutes de l'IFN
(archive `export_dataifn_2005_2025.zip`, Licence Ouverte 2.0) qui
définit les modalités des unités `TEXT` (campagnes 2005-2016) et `TEXT1`
(campagnes 2017 et suivantes), utilisées par les colonnes `TEXT1` et
`TEXT2` d'`ECOLOGIE` (`docs/referentiels.md`, § 22). Chaque code 1 à 9 y
est défini par une liste d'abréviations de classes de texture (par
exemple `4` : « Ls, Lsa, Lms, Lls : limon dominant + sable »). Les
abréviations sont lues dans la définition (texte avant « : »), jamais
recopiées à la main.

## Usage

``` r
read_texture_dictionary(
  path = system.file("extdata", "ifn_texture_dictionnaire.csv", package = "sylvostation"),
  unite = c("TEXT1", "TEXT")
)
```

## Arguments

- path:

  Chemin de l'extrait (par défaut
  `inst/extdata/ifn_texture_dictionnaire.csv`).

- unite:

  `"TEXT1"` (2017 et suivantes, avec le code `H`) ou `"TEXT"`
  (2005-2016).

## Value

Un `data.frame` : `unite`, `campagnes`, `code`, `libelle`, `definition`,
`classes` (abréviations en majuscules, séparées par des virgules),
`classes_aisne` (celles du triangle de l'Aisne), `hors_triangle`. Codes
`0` (absence de terre fine) et `H` (texture organique) : classes vides.

## Details

Les abréviations sont celles du **triangle de l'Aisne** (Jamagne, 1967 ;
classes de `soiltexture::TT.get("FR.AISNE.TT")`) : les 15 classes de ce
triangle y figurent chacune une fois, et les codes 1 à 9 en forment une
partition. L'IFN ne nomme pas le triangle : l'identification est faite
par les abréviations. Une abréviation n'appartient pas au triangle de
l'Aisne : `Als` (code 8, « argile limono-sableuse » du triangle du
GEPPA) ; elle est rendue dans `hors_triangle`.

## Examples

``` r
read_texture_dictionary()[, c("code", "libelle", "classes_aisne")]
#>    code                libelle  classes_aisne
#> 1     0                absence               
#> 2     1                  sable              S
#> 3     2         sable limoneux             SL
#> 4     3         sable argileux             SA
#> 5     4          limon sableux LS,LSA,LMS,LLS
#> 6     5         limon argileux         LA,LAS
#> 7     6                  limon          LM,LL
#> 8     7       argile limoneuse             AL
#> 9     8 argile sablo-limoneuse             AS
#> 10    9                 argile          A,ALO
#> 11    H      Texture organique               
```
