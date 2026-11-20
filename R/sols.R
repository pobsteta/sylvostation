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

# propriete puis couche (mission 039 : textures et cailloux en plus du pH)
.URL_SOILGRIDS <- "https://files.isric.org/soilgrids/latest/data/%s/%s.vrt"

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
#' @param layer Couche (`"phh2o_0-5cm_mean"` par défaut : 0-5 cm, moyenne). Depuis la
#'   mission 039, aussi `clay`, `sand`, `silt` (g/kg, rendus en %) et `cfvo` (cm³/dm³,
#'   rendu en % du volume) : toutes ces couches sont stockées × 10 par SoilGrids.
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
  if (!is.character(layer) || length(layer) != 1L ||
      !grepl("^(phh2o|clay|sand|silt|cfvo)_[0-9]+-[0-9]+cm_mean$", layer)) {
    stop("`layer` doit \u00eatre une couche <phh2o|clay|sand|silt|cfvo>_<profondeur>cm_mean de SoilGrids.",
         call. = FALSE)
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
  r <- reader(sprintf(.URL_SOILGRIDS, sub("_.*$", "", layer), layer))
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
  coarse_disk_mean(ph, radius = radius, name = "coarse_ph_soilgrids_700m")
}

#' Moyenne dans un disque de 700 m (couche à maille large)
#'
#' Moyenne circulaire d'une couche d'au moins 250 m dans un disque de rayon `radius`
#' (700 m par défaut, la précision de localisation des placettes IFN) : la couche rendue,
#' nommée `coarse_*`, est un prédicteur à maille large permis aux placettes IFN (règle des
#' 700 m) ; la même couche sert à l'apprentissage et à la carte. Généralise
#' [soilgrids_disk_mean()] (mission 039 : température corrigée, capacité en eau SoilGrids).
#'
#' @param r `SpatRaster` en Lambert-93 (EPSG:2154), maille >= 250 m (première couche lue).
#' @param radius Rayon du disque (m, au moins 700).
#' @param name Nom de la couche rendue, préfixé `coarse_`.
#' @return Un `SpatRaster` à une couche `name`.
#' @examples
#' r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1005000, ymin = 6.8e6,
#'                  ymax = 6805000, crs = "EPSG:2154", vals = 5)
#' names(coarse_disk_mean(r, name = "coarse_x_700m"))
#' @export
coarse_disk_mean <- function(r, radius = 700, name) {
  if (!inherits(r, "SpatRaster")) stop("`r` doit \u00eatre un SpatRaster.", call. = FALSE)
  if (!is.character(name) || length(name) != 1L || !startsWith(name, "coarse_")) {
    stop("`name` doit \u00eatre un nom pr\u00e9fix\u00e9 coarse_ (couche \u00e0 maille large).", call. = FALSE)
  }
  assert_crs_2154(r)
  if (!is.numeric(radius) || length(radius) != 1L || !is.finite(radius) || radius < 700) {
    stop("`radius` doit \u00eatre un nombre >= 700 m (pr\u00e9cision de localisation des placettes IFN).",
         call. = FALSE)
  }
  rs <- terra::res(r)
  if (any(rs < 250 - 1e-6)) {
    stop("La couche doit \u00eatre de maille >= 250 m (maille large), r\u00e9solution ",
         paste(rs, collapse = " x "), " m.", call. = FALSE)
  }
  n <- floor(radius / rs[1])
  off <- -n:n
  w <- outer(off, off, function(i, j) sqrt(i^2 + j^2) * rs[1] <= radius) * 1
  out <- terra::focal(r[[1]], w = w, fun = "mean", na.rm = TRUE, expand = FALSE)
  names(out) <- name
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

# ---- Réserve utile tirée de SoilGrids (mission 039) ----------------------------------------

# Horizons de SoilGrids 2.0 (cm) et noms des couches
.SG_HAUT <- c(0, 5, 15, 30, 60, 100)
.SG_BAS <- c(5, 15, 30, 60, 100, 200)
.SG_PROF <- sprintf("%d-%dcm", .SG_HAUT, .SG_BAS)

#' Lire argile, sable, limon et cailloux de SoilGrids sur une emprise (Lambert-93, 250 m)
#'
#' Lit, par [fetch_soilgrids_ph()], les 24 couches `clay`, `sand`, `silt`, `cfvo` (moyenne)
#' des six horizons de SoilGrids 2.0 (0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm), en
#' pourcentage, à 250 m en Lambert-93, et les met en cache. Licence CC BY 4.0 (ISRIC), à citer.
#' Volume mesuré sur la GRECO D (mission 039) : 45 Mo. Exactitude sur la France non évaluée.
#'
#' @inheritParams fetch_soilgrids_ph
#' @return Un vecteur nommé de chemins (`clay_0-5cm`, ...).
#' @examples
#' \dontrun{
#' fetch_soilgrids_texture(c(909550, 6723356, 1060558, 6912236), "data/cache/soilgrids")
#' }
#' @export
fetch_soilgrids_texture <- function(bbox, cache_dir, margin_m = 2000, offline = FALSE,
                                    reader = NULL) {
  props <- c("clay", "sand", "silt", "cfvo")
  noms <- as.vector(outer(props, .SG_PROF, paste, sep = "_"))
  out <- vapply(noms, function(n) {
    fetch_soilgrids_ph(bbox, cache_dir, layer = paste0(n, "_mean"), margin_m = margin_m,
                       offline = offline, reader = reader)
  }, character(1))
  names(out) <- noms
  out
}

#' Capacité en eau par horizon tirée des textures SoilGrids (euptf2)
#'
#' Pour chaque horizon de SoilGrids, eau disponible θ(pF 2,0) − θ(pF 4,2) par euptf2
#' (PTF01 : sable, limon, argile ramenés à 100 %, profondeur au milieu de l'horizon), comme
#' [ru_from_texture()], réduite par les cailloux : capacité `cu_<horizon>` en mm d'eau par cm
#' de sol. La réserve utile jusqu'à une profondeur est la somme des capacités × épaisseurs
#' ([ru_soilgrids()]). Valeur obtenue : environ 3,2 mm/cm pour un limon à 20 % d'argile sans
#' cailloux, haute pour une eau disponible (pF 2,0 au lieu de 2,5) : **à vérifier**. Calcul mesuré sur la GRECO D : 231 s pour 447 044 cellules × 6
#' horizons, 1,4 Go.
#'
#' @param files Chemins de [fetch_soilgrids_texture()] (ou `SpatRaster` à 24 couches nommées
#'   `clay_0-5cm_mean`, ...), en %, EPSG:2154 ; ou un seul GeoTIFF à 24 couches nommées
#'   (`soilgrids_texture_path`, mode hors ligne), divisé par 10 s'il porte la balise
#'   `echelle = 10` (unités natives de SoilGrids).
#' @return `SpatRaster` à six couches `cu_0_5`, `cu_5_15`, ..., `cu_100_200` (mm/cm).
#' @examples
#' \donttest{
#' if (requireNamespace("euptf2", quietly = TRUE)) {
#' g <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000500, ymin = 6.8e6,
#'                  ymax = 6800500, crs = "EPSG:2154")
#' L <- lapply(c("clay", "sand", "silt", "cfvo"), function(p) {
#'   r <- terra::rast(g, nlyrs = 6)
#'   terra::values(r) <- switch(p, clay = 20, sand = 40, silt = 40, cfvo = 10)
#'   names(r) <- paste0(p, "_", c("0-5", "5-15", "15-30", "30-60", "60-100", "100-200"), "cm_mean")
#'   r
#' })
#' soilgrids_cu(do.call(c, L))
#' }
#' }
#' @export
soilgrids_cu <- function(files) {
  if (inherits(files, "SpatRaster")) {
    r <- files
  } else if (length(files) == 1L && is.null(names(files))) {
    # un seul GeoTIFF a 24 couches nommees (extrait hors ligne, mission 039b) ; balise
    # `echelle = 10` : unites natives de SoilGrids x 10, ramenees en %
    r <- terra::rast(files)
    mt <- terra::metags(r)
    ech <- if (is.data.frame(mt)) mt$value[mt$name == "echelle"] else mt[names(mt) == "echelle"]
    if (length(ech) && identical(as.character(ech[1]), "10")) {
      nm <- names(r)
      r <- r / 10
      names(r) <- nm
    }
  } else {
    r <- terra::rast(unname(files))
    names(r) <- paste0(names(files), "_mean")
  }
  assert_crs_2154(r)
  # ranger : charge l'espace de noms (methode predict des objets d'euptf2)
  for (pk in c("euptf2", "ranger")) {
    if (!.has_pkg(pk)) stop("Le paquet ", pk, " est requis (Suggests).", call. = FALSE)
  }
  noms <- function(p) paste0(p, "_", .SG_PROF, "_mean")
  manque <- setdiff(c(noms("clay"), noms("sand"), noms("silt"), noms("cfvo")), names(r))
  if (length(manque)) {
    stop("Couches SoilGrids absentes : ", paste(manque, collapse = ", "), call. = FALSE)
  }
  out <- terra::rast(r[[1]], nlyrs = 6)
  V <- matrix(NA_real_, terra::ncell(r), 6)
  for (k in 1:6) {
    cl <- terra::values(r[[noms("clay")[k]]], mat = FALSE)
    sa <- terra::values(r[[noms("sand")[k]]], mat = FALSE)
    si <- terra::values(r[[noms("silt")[k]]], mat = FALSE)
    cf <- terra::values(r[[noms("cfvo")[k]]], mat = FALSE)
    tot <- cl + sa + si
    ok <- is.finite(tot) & tot > 0 & is.finite(cf)
    if (!any(ok)) next
    df <- data.frame(USSAND = 100 * sa[ok] / tot[ok], USSILT = 100 * si[ok] / tot[ok],
                     USCLAY = 100 * cl[ok] / tot[ok],
                     DEPTH_M = (.SG_HAUT[k] + .SG_BAS[k]) / 200)
    awc <- .euptf_pred("FC_2", "PTF01", df) - .euptf_pred("WP", "PTF01", df)
    V[ok, k] <- awc * 10 * (1 - pmin(pmax(cf[ok], 0), 100) / 100)   # mm d'eau par cm de sol
  }
  terra::values(out) <- V
  names(out) <- sprintf("cu_%d_%d", .SG_HAUT, .SG_BAS)
  attr(out, "source") <- "SoilGrids 2.0 (CC BY 4.0) + euptf2 PTF01 (FC_2 - WP)"
  out
}

#' Réserve utile SoilGrids jusqu'à une profondeur (diagnostic)
#'
#' Somme des capacités par horizon ([soilgrids_cu()]) × épaisseur jusqu'à `depth_cm`.
#' **Diagnostic seulement** (arbitrage du 2026-11-20) : SoilGrids ne connaît pas la profondeur
#' du sol ; sur la GRECO D, la RU à 1 m surestime la RU des placettes IFN de 137 mm en
#' moyenne (corrélation 0,27), et son champ est presque plat (écart-type 15 mm sur l'emprise).
#' La RU de la carte est la RU apprise ([ru_learned_data()]).
#'
#' @param cu `SpatRaster` de [soilgrids_cu()] ou matrice (points x 6 horizons, mm/cm).
#' @param depth_cm Profondeur (cm, 0 à 200) : un nombre, ou un vecteur (un par point) si
#'   `cu` est une matrice.
#' @return `SpatRaster` `ru_soilgrids_<depth>cm` ou vecteur (mm).
#' @examples
#' ru_soilgrids(matrix(1.5, 2, 6), c(50, 100))
#' @export
ru_soilgrids <- function(cu, depth_cm) {
  if (!is.numeric(depth_cm) || anyNA(depth_cm) || any(depth_cm < 0 | depth_cm > 200)) {
    stop("`depth_cm` doit être entre 0 et 200 cm.", call. = FALSE)
  }
  ep <- function(D) pmax(0, pmin(.SG_BAS, D) - .SG_HAUT)
  if (inherits(cu, "SpatRaster")) {
    if (terra::nlyr(cu) != 6L || length(depth_cm) != 1L) {
      stop("`cu` : six horizons de soilgrids_cu() et une seule profondeur.", call. = FALSE)
    }
    e <- ep(depth_cm)
    out <- sum(cu * e)
    names(out) <- sprintf("ru_soilgrids_%dcm", round(depth_cm))
    return(out)
  }
  cu <- as.matrix(cu)
  if (ncol(cu) != 6L) stop("`cu` doit avoir six colonnes (horizons).", call. = FALSE)
  D <- rep_len(depth_cm, nrow(cu))
  vapply(seq_len(nrow(cu)), function(i) sum(cu[i, ] * ep(D[i])), numeric(1))
}

#' Capacités SoilGrids moyennées dans 700 m (couches à maille large)
#'
#' [coarse_disk_mean()] de chaque horizon de [soilgrids_cu()] : couches
#' `coarse_cu_0_5_700m`, ..., permises aux placettes IFN (règle des 700 m, comme le pH
#' SoilGrids de la mission 035).
#'
#' @param cu `SpatRaster` de [soilgrids_cu()] (250 m).
#' @param radius Rayon (m, >= 700).
#' @return `SpatRaster` à six couches `coarse_cu_*_700m`.
#' @examples
#' cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
#'                   ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
#' names(cu) <- sprintf("cu_%d_%d", c(0, 5, 15, 30, 60, 100), c(5, 15, 30, 60, 100, 200))
#' names(coarse_cu_layers(cu))
#' @export
coarse_cu_layers <- function(cu, radius = 700) {
  if (!inherits(cu, "SpatRaster") || !all(grepl("^cu_", names(cu)))) {
    stop("`cu` doit venir de soilgrids_cu().", call. = FALSE)
  }
  do.call(c, lapply(names(cu), function(n) {
    coarse_disk_mean(cu[[n]], radius = radius, name = paste0("coarse_", n, "_700m"))
  }))
}

#' Valeurs de plusieurs couches à maille large aux placettes (règle des 700 m)
#'
#' [raster_at_points()] couche par couche, colonnes ajoutées à `points` (jointure par
#' `id_placette`). Chaque couche doit être `coarse_*` : l'assertion des 700 m est appelée.
#'
#' @param points `sf` de points (EPSG:2154) avec `id_placette`, `source`, `loc_precision_m`.
#' @param layers `SpatRaster` de couches `coarse_*`.
#' @return `points` avec une colonne par couche.
#' @examples
#' r <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
#'                  ymax = 6802500, crs = "EPSG:2154", vals = 6)
#' names(r) <- "coarse_x_700m"
#' p <- mark_ifn(sf::st_sf(id_placette = "a",
#'   geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)), crs = 2154)))
#' layers_at_points(p, r)$coarse_x_700m
#' @export
layers_at_points <- function(points, layers) {
  if (!inherits(layers, "SpatRaster")) stop("`layers` doit être un SpatRaster.", call. = FALSE)
  assert_no_fine_extract_on_ifn(points, names(layers))
  for (n in names(layers)) {
    v <- raster_at_points(points, layers[[n]])
    points[[n]] <- v[[n]][match(as.character(points$id_placette), v$id_placette)]
  }
  points
}

#' Données d'apprentissage de la RU apprise (placettes IFN)
#'
#' RU de la carte (mission 039, arbitrage du 2026-11-20) : la RU des placettes IFN
#' (`ru_mm`, [ru_from_texture()]) est apprise par une forêt aléatoire ([fit_gradient()]) sur
#' des prédicteurs à maille large : lithologie et formation dominantes encodées dans 700 m
#' (`coarse_litho_enc`, `coarse_formation_enc`) et capacités SoilGrids moyennées dans 700 m
#' ([coarse_cu_layers()]). R² par blocs mesuré sur la GRECO D : 0,14 (41 km) à 0,17 (8 358 m),
#' contre 0,10 (optimiste, non spatial) pour la médiane de la maille SAFRAN.
#'
#' @param train Placettes IFN (`sf`) avec `ru_mm` et les colonnes d'encodage de la
#'   lithologie (`trophic_enc$data` du pipeline).
#' @param cu700 `SpatRaster` de [coarse_cu_layers()].
#' @return Une liste : `data` (placettes complètes), `vars` (prédicteurs), `retirees`
#'   (placettes sans RU ou sans prédicteur).
#' @examples
#' cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
#'                   ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
#' names(cu) <- sprintf("coarse_cu_%d_%d_700m", c(0, 5, 15, 30, 60, 100),
#'                      c(5, 15, 30, 60, 100, 200))
#' p <- mark_ifn(sf::st_sf(id_placette = c("a", "b"), ru_mm = c(80, NA),
#'   coarse_litho_enc = 1, coarse_formation_enc = 2,
#'   geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
#'                         sf::st_point(c(1001500, 6801000)), crs = 2154)))
#' ru_learned_data(p, cu)$vars
#' @export
ru_learned_data <- function(train, cu700) {
  if (!inherits(train, "sf") || !"ru_mm" %in% names(train)) {
    stop("`train` doit être un sf avec ru_mm.", call. = FALSE)
  }
  geol <- intersect(c("coarse_litho_enc", "coarse_formation_enc"), names(train))
  d <- layers_at_points(train, cu700)
  vars <- c(geol, names(cu700))
  ok <- is.finite(d$ru_mm) & stats::complete.cases(sf::st_drop_geometry(d)[, vars, drop = FALSE])
  list(data = d[ok, ], vars = vars, retirees = sum(!ok))
}

#' Écart de la RU SoilGrids à la RU des placettes IFN (diagnostic)
#'
#' Pour chaque profondeur, RU SoilGrids ([ru_soilgrids()] sur les capacités moyennées dans
#' 700 m) aux placettes, comparée à `ru_mm` : moyenne, biais, RMSE, corrélation, écarts-types.
#'
#' @param points Placettes (`sf`) avec `ru_mm`, `id_placette`, `source`, `loc_precision_m`.
#' @param cu700 `SpatRaster` de [coarse_cu_layers()].
#' @param depths Profondeurs (cm).
#' @return `data.frame` : `profondeur_cm`, `n`, `ru_ifn_moy`, `ru_sg_moy`, `biais`, `rmse`,
#'   `correlation`, `sd_ifn`, `sd_sg`, `statut`.
#' @examples
#' cu <- terra::rast(nrows = 10, ncols = 10, xmin = 1e6, xmax = 1002500, ymin = 6.8e6,
#'                   ymax = 6802500, crs = "EPSG:2154", nlyrs = 6, vals = 1)
#' names(cu) <- sprintf("coarse_cu_%d_%d_700m", c(0, 5, 15, 30, 60, 100),
#'                      c(5, 15, 30, 60, 100, 200))
#' p <- mark_ifn(sf::st_sf(id_placette = c("a", "b"), ru_mm = c(80, 120),
#'   geometry = sf::st_sfc(sf::st_point(c(1001000, 6801000)),
#'                         sf::st_point(c(1001500, 6801000)), crs = 2154)))
#' ru_soilgrids_diagnostic(p, cu)
#' @export
ru_soilgrids_diagnostic <- function(points, cu700, depths = c(50, 100, 200)) {
  d <- sf::st_drop_geometry(layers_at_points(points, cu700))
  C <- as.matrix(d[, names(cu700), drop = FALSE])
  do.call(rbind, lapply(depths, function(D) {
    sg <- ru_soilgrids(C, D)
    k <- is.finite(sg) & is.finite(d$ru_mm)
    e <- sg[k] - d$ru_mm[k]
    data.frame(profondeur_cm = D, n = sum(k), ru_ifn_moy = mean(d$ru_mm[k]),
               ru_sg_moy = mean(sg[k]), biais = mean(e), rmse = sqrt(mean(e^2)),
               correlation = if (sum(k) > 2) stats::cor(sg[k], d$ru_mm[k]) else NA_real_,
               sd_ifn = stats::sd(d$ru_mm[k]), sd_sg = stats::sd(sg[k]),
               statut = "diagnostic (mission 039) : RU SoilGrids non utilisée par la carte")
  }))
}
