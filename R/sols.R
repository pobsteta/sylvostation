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
