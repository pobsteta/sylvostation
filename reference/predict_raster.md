# Prédire un gradient sur un raster, avec incertitude et zone d'applicabilité

Prédire un gradient sur un raster, avec incertitude et zone
d'applicabilité

## Usage

``` r
predict_raster(model, predictors, aoa = TRUE, use_cast = TRUE, cv = NULL)
```

## Arguments

- model:

  Objet de
  [`fit_gradient()`](https://pobsteta.github.io/sylvostation/reference/fit_gradient.md).

- predictors:

  `SpatRaster` en EPSG:2154 dont les couches portent (au moins) les noms
  des prédicteurs du modèle.

- aoa:

  Calculer la zone d'applicabilité ? Utilise
  [`CAST::aoa()`](https://hannameyer.github.io/CAST/reference/aoa.html)
  si CAST est installé, sinon un calcul maison équivalent simplifié
  (même principe : indice de dissimilarité, seuil des moustaches ; sans
  validation croisée des DI).

- use_cast:

  `FALSE` pour forcer le repli maison même si CAST est installé.

- cv:

  Résultat de
  [`spatial_cv()`](https://pobsteta.github.io/sylvostation/reference/spatial_cv.md)
  sur **les mêmes données** que le modèle (`NULL` : sans). S'il est
  fourni : (1) ses plis spatiaux sont transmis à
  [`CAST::aoa()`](https://hannameyer.github.io/CAST/reference/aoa.html)
  (argument `CVtest`), ce qui calcule le seuil de la zone
  d'applicabilité sur des indices de dissimilarité de validation croisée
  (méthode de Meyer et Pebesma) ; (2) la couche `sd_cv` est calculée.

## Value

Un `SpatRaster` avec les couches `pred`, `sd` (écart-type : quantiles de
la forêt ou erreur-type du GAM, **pas** l'erreur de validation croisée),
si `cv` : `sd_cv` (= `sd` multiplié par RMSE de validation croisée /
racine de la moyenne des `sd^2` hors pli : l'écart-type est recalé pour
que son niveau moyen égale l'erreur mesurée hors blocs ; le **motif**
spatial reste celui de `sd`, le niveau est global, pas local), et si
`aoa` : `di` et `aoa` (1 = dans la zone d'applicabilité, 0 = hors zone :
à ne pas interpréter). Une balise `synthetic` est posée
([`terra::metags`](https://rspatial.github.io/terra/reference/metags.html))
si le modèle vient de données synthétiques.

## Examples

``` r
if (FALSE) { # \dontrun{
cv <- spatial_cv(donnees, "g", predicteurs)
r <- predict_raster(modele, pile_predicteurs, cv = cv)
} # }
```
