#' Empiler les couches de sols sur la grille du projet
#'
#' Lit des rasters de sols (GlobalSoilMap, pH SILVAE, pédopaysage...) et les ramène
#' sur `grid` (même emprise, même maille, EPSG:2154) par `terra::project()`. Une
#' couche dont la **maille d'origine** est >= `coarse_res_m` (90 m par défaut) est
#' préfixée `coarse_` : seule cette famille de prédicteurs peut être croisée avec les
#' placettes IFN (règle bloquante, voir [assert_no_fine_extract_on_ifn()]). Le
#' rééchantillonnage ne rend pas une couche grossière plus fine : le préfixe suit la
#' résolution native, jamais celle de `grid`.
#'
#' **Attention** : `coarse_` signifie maille >= 90 m (prédicteurs du modèle local),
#' pas « croisable avec l'IFN ». Avant tout croisement avec des placettes IFN, ces
#' couches doivent être agrégées à 1 km ([aggregate_to_km()]) ; l'extraction exige
#' une maille >= 1000 m.
#'
#' Pour une source en degrés (WGS84), la maille est estimée à 111 320 m par degré
#' (approximation).
#'
#' @param paths Chemins des rasters (vecteur, nommé de préférence ; sinon le nom
#'   du fichier sans extension sert de nom de couche).
#' @param grid `SpatRaster` modèle, en EPSG:2154.
#' @param method Méthode de rééchantillonnage de `terra::project()` (`"bilinear"`
#'   par défaut pour des variables continues ; `"near"` pour des classes).
#' @param coarse_res_m Seuil de maille (m) à partir duquel une couche est `coarse_`.
#' @return Un `SpatRaster` à autant de couches que de rasters sources (un raster
#'   multicouche donne `nom_1`, `nom_2`...), sur la grille de `grid`.
#' @examples
#' f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
#' g <- terra::rast(f)
#' names(stack_soil_layers(c(sol = f), g))
#' @export
stack_soil_layers <- function(paths, grid, method = "bilinear", coarse_res_m = 90) {
  if (!is.character(paths) || !length(paths) || anyNA(paths)) {
    stop("`paths` doit \u00eatre un vecteur de chemins.", call. = FALSE)
  }
  if (!inherits(grid, "SpatRaster")) stop("`grid` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(grid)
  absents <- paths[!file.exists(paths)]
  if (length(absents)) {
    stop("Fichier(s) introuvable(s) : ", paste(absents, collapse = ", "), call. = FALSE)
  }
  noms <- names(paths)
  if (is.null(noms)) noms <- rep("", length(paths))
  noms[!nzchar(noms)] <- sub("\\.[^.]*$", "", basename(paths))[!nzchar(noms)]

  couches <- lapply(seq_along(paths), function(i) {
    r <- terra::rast(paths[[i]])
    if (!nzchar(terra::crs(r))) {
      stop("Syst\u00e8me de coordonn\u00e9es absent : ", paths[[i]], call. = FALSE)
    }
    res_m <- mean(terra::res(r)) * if (terra::is.lonlat(r)) 111320 else 1
    nom <- if (terra::nlyr(r) > 1L) paste0(noms[[i]], "_", seq_len(terra::nlyr(r))) else noms[[i]]
    if (res_m >= coarse_res_m) nom <- paste0("coarse_", sub("^coarse_", "", nom))
    p <- terra::project(r, grid, method = method)
    names(p) <- nom
    p
  })
  s <- do.call(c, couches)
  if (anyDuplicated(names(s))) {
    stop("Noms de couches en double : ", paste(names(s)[duplicated(names(s))], collapse = ", "),
         call. = FALSE)
  }
  s
}

#' Agréger un raster à la maille kilométrique
#'
#' Agrège par la **moyenne** un raster à une maille de `res_m` mètres (1000 par
#' défaut). C'est l'étape obligatoire avant de croiser une couche de sols ou de climat
#' avec des placettes IFN (localisées à 700 m près ; brief technique, étape 5 : pH
#' GlobalSoilMap agrégé à 1 km). `res_m` doit être un multiple entier de la maille de
#' `x`.
#'
#' @param x `SpatRaster` en EPSG:2154, à maille carrée.
#' @param res_m Maille cible, en mètres.
#' @return Un `SpatRaster` de maille `res_m`, de mêmes noms de couches.
#' @examples
#' r <- terra::rast(system.file("extdata", "synth_dtm.tif", package = "sylvostation"))
#' terra::res(aggregate_to_km(r))
#' @export
aggregate_to_km <- function(x, res_m = 1000) {
  if (!inherits(x, "SpatRaster")) stop("`x` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(x)
  if (!is.numeric(res_m) || length(res_m) != 1L || !is.finite(res_m) || res_m <= 0) {
    stop("`res_m` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  fact <- res_m / terra::res(x)
  if (any(abs(fact - round(fact)) > 1e-8) || any(round(fact) < 1)) {
    stop("`res_m` doit \u00eatre un multiple entier de la maille de `x` (",
         paste(terra::res(x), collapse = " x "), " m).", call. = FALSE)
  }
  terra::aggregate(x, fact = round(fact), fun = "mean", na.rm = TRUE)
}
