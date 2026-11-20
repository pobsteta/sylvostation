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

# --- SoilGrids : pH de l'horizon superficiel, a maille large (mission 035) -----------------
# Source : SoilGrids 2.0 (ISRIC), `phh2o`, 250 m, pH x 10, CC BY 4.0 (docs/referentiels.md,
# section 18 puis 35). Exactitude sur la France : NON EVALUEE (a verifier).

.URL_SOILGRIDS <- "https://files.isric.org/soilgrids/latest/data/phh2o/%s.vrt"

#' Lire le pH SoilGrids sur une emprise et le mettre en cache (Lambert-93, 250 m)
#'
#' Lit une fenêtre du raster virtuel SoilGrids 2.0 `phh2o` (pH × 10, 250 m, projection
#' Goode interrompue de Homolosine), la reprojette en Lambert-93 à 250 m (bilinéaire), divise
#' par 10 et écrit un GeoTIFF dans `cache_dir`. **Le nom du fichier porte la couche et
#' l'emprise** : un fichier d'une autre emprise n'est jamais resservi. Seule la fenêtre
#' est lue (quelques Mo), jamais le raster mondial. Licence CC BY 4.0 (ISRIC), à citer.
#' Exactitude sur la France non évaluée.
#'
#' @param bbox Emprise `c(xmin, ymin, xmax, ymax)` ou `bbox` en Lambert-93 (EPSG:2154).
#' @param cache_dir Dossier de cache.
#' @param layer Couche (`"phh2o_0-5cm_mean"` par défaut : 0-5 cm, moyenne).
#' @param margin_m Marge autour de `bbox` (m), pour que la moyenne dans 700 m des placettes du
#'   bord soit complète.
#' @param offline `TRUE` : aucun accès au réseau (seul le cache sert).
#' @param reader Fonction `function(url)` renvoyant un `SpatRaster` (par défaut
#'   `terra::rast` sur `/vsicurl/` ; remplaçable dans les tests).
#' @return Le chemin du GeoTIFF (pH en unités de pH, EPSG:2154, 250 m).
#' @examples
#' \dontrun{
#' fetch_soilgrids_ph(c(909550, 6723356, 1060558, 6912236), "data/cache/soilgrids")
#' }
#' @export
fetch_soilgrids_ph <- function(bbox, cache_dir, layer = "phh2o_0-5cm_mean", margin_m = 2000,
                               offline = FALSE, reader = NULL) {
  b <- .as_bbox(bbox)
  if (!is.character(layer) || length(layer) != 1L || !grepl("^phh2o_[0-9]+-[0-9]+cm_mean$", layer)) {
    stop("`layer` doit \u00eatre une couche phh2o_<profondeur>cm_mean de SoilGrids.", call. = FALSE)
  }
  cle <- paste(round(c(b[["xmin"]], b[["ymin"]], b[["xmax"]], b[["ymax"]])), collapse = "_")
  out <- file.path(cache_dir, sprintf("%s_x%s_m%d.tif", layer, cle, round(margin_m)))
  if (file.exists(out)) return(out)
  if (offline) {
    stop("Mode hors ligne : fichier SoilGrids absent du cache (", basename(out), ").", call. = FALSE)
  }
  if (is.null(reader)) {
    reader <- function(url) {
      old <- Sys.getenv("CPL_VSIL_CURL_ALLOWED_EXTENSIONS", NA)
      Sys.setenv(CPL_VSIL_CURL_ALLOWED_EXTENSIONS = ".vrt,.tif")
      on.exit(if (is.na(old)) Sys.unsetenv("CPL_VSIL_CURL_ALLOWED_EXTENSIONS") else
        Sys.setenv(CPL_VSIL_CURL_ALLOWED_EXTENSIONS = old), add = TRUE)
      terra::rast(paste0("/vsicurl/", url))
    }
  }
  r <- reader(sprintf(.URL_SOILGRIDS, layer))
  fen <- sf::st_as_sfc(sf::st_bbox(c(xmin = b[["xmin"]] - margin_m, ymin = b[["ymin"]] - margin_m,
                                     xmax = b[["xmax"]] + margin_m, ymax = b[["ymax"]] + margin_m),
                                   crs = sf::st_crs(2154)))
  # fenetre dans la projection de la source (marge de 1 km pour la reprojection)
  fen_src <- sf::st_transform(sf::st_buffer(fen, 1000), terra::crs(r))
  x <- terra::crop(r, terra::ext(terra::vect(fen_src)))
  gabarit <- terra::rast(xmin = floor((b[["xmin"]] - margin_m) / 250) * 250,
                         xmax = ceiling((b[["xmax"]] + margin_m) / 250) * 250,
                         ymin = floor((b[["ymin"]] - margin_m) / 250) * 250,
                         ymax = ceiling((b[["ymax"]] + margin_m) / 250) * 250,
                         resolution = 250, crs = "EPSG:2154")
  p <- terra::project(x, gabarit, method = "bilinear") / 10
  names(p) <- layer
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(out, ".part.tif")
  terra::writeRaster(p, tmp, overwrite = TRUE, datatype = "FLT4S")
  file.rename(tmp, out)
  out
}

#' pH SoilGrids moyenné dans un disque de 700 m (couche à maille large)
#'
#' Moyenne circulaire du pH de [fetch_soilgrids_ph()] dans un disque de rayon `radius`
#' (700 m par défaut, la précision de localisation des placettes IFN) : couche
#' `coarse_ph_soilgrids_700m`, prédicteur à maille large permis pour les placettes IFN
#' (règle des 700 m) ; la même couche sert à l'apprentissage et à la carte.
#'
#' @param ph `SpatRaster` en Lambert-93 (EPSG:2154) de pH, maille >= 250 m.
#' @param radius Rayon du disque (m, au moins la précision de localisation, 700).
#' @return Un `SpatRaster` à une couche `coarse_ph_soilgrids_700m`.
#' @examples
#' r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1005000, ymin = 6.8e6,
#'                  ymax = 6805000, crs = "EPSG:2154", vals = 5)
#' terra::values(soilgrids_disk_mean(r))[1:3, 1]
#' @export
soilgrids_disk_mean <- function(ph, radius = 700) {
  if (!inherits(ph, "SpatRaster")) stop("`ph` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(ph)
  if (!is.numeric(radius) || length(radius) != 1L || !is.finite(radius) || radius < 700) {
    stop("`radius` doit \u00eatre un nombre >= 700 m (pr\u00e9cision de localisation des placettes IFN).",
         call. = FALSE)
  }
  rs <- terra::res(ph)
  if (any(rs < 250 - 1e-6)) {
    stop("`ph` doit \u00eatre de maille >= 250 m (maille large), r\u00e9solution ",
         paste(rs, collapse = " x "), " m.", call. = FALSE)
  }
  n <- floor(radius / rs[1])
  off <- -n:n
  w <- outer(off, off, function(i, j) sqrt(i^2 + j^2) * rs[1] <= radius) * 1
  out <- terra::focal(ph[[1]], w = w, fun = "mean", na.rm = TRUE, expand = FALSE)
  names(out) <- "coarse_ph_soilgrids_700m"
  out
}

#' Valeur d'une couche à maille large aux placettes (règle des 700 m)
#'
#' Extrait une couche **à maille large** (préfixe `coarse_`) aux points, par interpolation
#' bilinéaire. La règle bloquante est appelée en premier : une couche non large est
#' refusée pour des placettes IFN ou des points de précision > 25 m, et une maille
#' inférieure à `min_res_m` aussi.
#'
#' @param points `sf` de points en Lambert-93 avec `id_placette` (marqués IFN : [mark_ifn()]).
#' @param layer `SpatRaster` à une couche, nommée `coarse_*`, en EPSG:2154.
#' @param min_res_m Maille minimale (m, 250 par défaut).
#' @return Un `data.frame` : `id_placette` et la couche (même nom).
#' @examples
#' r <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
#'                  ymax = 6802500, crs = "EPSG:2154", vals = 6)
#' names(r) <- "coarse_ph_soilgrids_700m"
#' p <- sf::st_sf(id_placette = "a", geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
#'                                                          crs = 2154))
#' raster_at_points(mark_ifn(p), r)
#' @export
raster_at_points <- function(points, layer, min_res_m = 250) {
  if (!inherits(points, "sf") || !"id_placette" %in% names(points)) {
    stop("`points` doit \u00eatre un sf avec `id_placette`.", call. = FALSE)
  }
  if (!inherits(layer, "SpatRaster") || terra::nlyr(layer) != 1L) {
    stop("`layer` doit \u00eatre un SpatRaster \u00e0 une couche.", call. = FALSE)
  }
  assert_no_fine_extract_on_ifn(points, names(layer))
  assert_crs_2154(points)
  assert_crs_2154(layer)
  if (any(terra::res(layer) < min_res_m - 1e-6)) {
    stop("`layer` doit \u00eatre de maille >= ", min_res_m, " m pour \u00eatre crois\u00e9e avec des placettes IFN.",
         call. = FALSE)
  }
  xy <- sf::st_coordinates(points)  # x = est, y = nord
  v <- terra::extract(layer, xy, method = "bilinear")
  out <- data.frame(id_placette = as.character(points$id_placette), v[[1]], stringsAsFactors = FALSE)
  names(out)[2] <- names(layer)
  out
}
