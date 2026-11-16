#' Agréger un MNT à des résolutions plus grossières
#'
#' Agrège un modèle numérique de terrain par la **moyenne** (brief technique, § 4
#' étape 2 : indices de terrain sur 5 et 25 m, pas sur 1 m). Le facteur d'agrégation
#' doit être entier ; si la maille d'origine est alignée sur un multiple de `res`
#' (ADR 0004 : origine de la grille de 25 m sur un multiple de 50 m), la grille
#' agrégée l'est aussi.
#'
#' @param dtm `SpatRaster` à une couche, en Lambert-93 (EPSG:2154), à maille carrée.
#' @param res Résolutions cibles, en mètres. Une résolution égale à celle du MNT le
#'   renvoie tel quel ; une résolution plus fine est refusée.
#' @return Une liste nommée (`res_5`, `res_25`, ...) de `SpatRaster`.
#' @examples
#' r <- terra::rast(nrows = 100, ncols = 100, xmin = 980000, xmax = 980100,
#'                  ymin = 6800000, ymax = 6800100, crs = "EPSG:2154")
#' terra::values(r) <- seq_len(terra::ncell(r))
#' names(aggregate_dtm(r, res = c(5, 25)))
#' @export
aggregate_dtm <- function(dtm, res = c(5, 25)) {
  .check_dtm(dtm)
  if (!is.numeric(res) || !length(res) || anyNA(res) || any(res <= 0)) {
    stop("`res` doit \u00eatre un vecteur de r\u00e9solutions positives (m).", call. = FALSE)
  }
  r0 <- terra::res(dtm)[1]
  out <- lapply(res, function(r) {
    f <- r / r0
    if (f < 1 - 1e-6) {
      stop("R\u00e9solution demand\u00e9e (", r, " m) plus fine que celle du MNT (", r0,
           " m).", call. = FALSE)
    }
    if (abs(f - round(f)) > 1e-6) {
      stop("La r\u00e9solution ", r, " m n'est pas un multiple entier de celle du MNT (",
           r0, " m).", call. = FALSE)
    }
    if (round(f) == 1) return(dtm)
    terra::aggregate(dtm, fact = round(f), fun = "mean", na.rm = FALSE)
  })
  stats::setNames(out, paste0("res_", format(res, trim = TRUE)))
}

# Contrôles communs : une couche, EPSG:2154, maille carrée.
.check_dtm <- function(dtm) {
  if (!inherits(dtm, "SpatRaster")) {
    stop("`dtm` doit \u00eatre un SpatRaster.", call. = FALSE)
  }
  if (terra::nlyr(dtm) != 1L) stop("`dtm` doit avoir une seule couche.", call. = FALSE)
  assert_crs_2154(dtm)
  rs <- terra::res(dtm)
  if (abs(rs[1] - rs[2]) > 1e-6 * rs[1]) {
    stop("`dtm` doit avoir une maille carr\u00e9e.", call. = FALSE)
  }
  invisible(dtm)
}

#' Variables dérivées du MNT (prédicteurs fins)
#'
#' Calcule les prédicteurs de terrain de l'étape 2 du brief technique. Toutes les
#' couches sont des variables **fines** (voir [FINE_VARIABLES]) : elles ne doivent
#' jamais être extraites aux coordonnées des placettes IFN (appeler
#' [assert_no_fine_extract_on_ifn()] avant toute extraction).
#'
#' Couches (noms stables) :
#' * `pente` (degrés, Horn 1981, via `terra::terrain`) ;
#' * `exposition_cos`, `exposition_sin` : cosinus et sinus de l'exposition (azimut de
#'   la descente, depuis le nord, sens horaire). `NA` sur terrain plat ;
#' * `courbure`, `courbure_profil`, `courbure_plan` (1/m) : Zevenbergen et Thorne
#'   (1987), signes d'ESRI : `courbure = -2 (D + E)` (positive en convexe) ; profil
#'   et plan comme dans la documentation ArcGIS « Curvature » ;
#' * `tpi_<rayon>` (m) : altitude moins moyenne des cellules du disque de ce rayon
#'   (centre exclu). `NA` là où le disque sort du MNT. Au-delà de 40 cellules de
#'   rayon, la moyenne est calculée sur une version agrégée puis rééchantillonnée
#'   (bilinéaire) pour borner le temps de calcul : approximation, **à vérifier** sur
#'   données réelles ;
#' * `twi` : ln(a / tan(pente)), `a` = surface drainée spécifique (m) ; pente minimale
#'   de 0,1 degré pour éviter les infinis ;
#' * `surface_drainee` (m2) : accumulation D8 (O'Callaghan et Mark 1984) calculée en R,
#'   **sans remplissage des cuvettes** (elles retiennent l'eau). Sur un MNT réel,
#'   prétraitement hydrologique **à vérifier** ;
#' * `mrvbf` : **non calculé** (`NA` et avertissement de classe
#'   `sylvostation_non_calcule`) : demande WhiteboxTools, binaire absent ;
#' * `hauteur_reseau` (m) : altitude moins celle de la cellule de cours d'eau la plus
#'   proche (distance horizontale) ; `NA` avec avertissement si `streams` est `NULL` ;
#' * `rayonnement` (kWh/m2/an) : rayonnement direct potentiel **hors atmosphère et sans
#'   ombres portées**, 12 jours types (Klein 1977), pas de 30 min, formules d'incidence
#'   de Duffie et Beckman (*Solar Engineering of Thermal Processes*, éq. 1.6.2 et
#'   1.10.3). Indice relatif d'exposition, non un flux au sol.
#'
#' Choisir la résolution en amont avec [aggregate_dtm()] (5 ou 25 m, ADR 0004). Le
#' pourtour d'une cellule du MNT est `NA` pour la pente, l'exposition et les courbures.
#'
#' @param dtm `SpatRaster` à une couche, EPSG:2154, maille carrée, altitudes en mètres.
#' @param tpi_radii Rayons du TPI, en mètres.
#' @param streams Réseau hydrographique (BD TOPAGE) : `SpatVector` ou `sf` de lignes en
#'   EPSG:2154, ou `NULL`.
#' @return Un `SpatRaster` multicouche nommé.
#' @examples
#' f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
#' if (nzchar(f)) {
#'   d <- terra::rast(f)   # surface synthétique
#'   suppressWarnings(names(derive_terrain(d, tpi_radii = 100)))
#' }
#' @export
derive_terrain <- function(dtm, tpi_radii = c(100, 300, 1000), streams = NULL) {
  .check_dtm(dtm)
  if (!is.numeric(tpi_radii) || !length(tpi_radii) || anyNA(tpi_radii) ||
      any(tpi_radii <= 0)) {
    stop("`tpi_radii` doit \u00eatre un vecteur de rayons positifs (m).", call. = FALSE)
  }
  if (!is.null(streams)) {
    if (inherits(streams, "sf")) streams <- terra::vect(streams)
    if (!inherits(streams, "SpatVector") || terra::geomtype(streams) != "lines") {
      stop("`streams` doit \u00eatre un SpatVector ou sf de lignes.", call. = FALSE)
    }
    assert_crs_2154(streams)
  }
  names(dtm) <- "z"
  L <- terra::res(dtm)[1]

  slope <- terra::terrain(dtm, "slope", unit = "degrees", neighbors = 8)
  asp <- terra::terrain(dtm, "aspect", unit = "radians", neighbors = 8)
  curv <- .curvatures(dtm)
  acc <- .flow_accumulation(dtm)
  twi <- log((acc * L) / tan(terra::clamp(slope, lower = 0.1, values = TRUE) * pi / 180))

  tpis <- lapply(tpi_radii, function(r) .tpi(dtm, r))
  tpi_names <- paste0("tpi_", format(tpi_radii, trim = TRUE))

  if (is.null(streams)) {
    .warn_non_calcule("`streams` absent : `hauteur_reseau` non calcul\u00e9e (NA).")
    hand <- dtm * NA
  } else {
    hand <- .height_above_streams(dtm, streams)
  }
  .warn_non_calcule("`mrvbf` non calcul\u00e9 (NA) : WhiteboxTools indisponible, \u00e0 v\u00e9rifier.")
  mrvbf <- dtm * NA

  ray <- .radiation_layer(dtm, slope, asp)

  out <- c(slope, cos(asp), sin(asp), curv, terra::rast(tpis), twi, acc * L^2,
           mrvbf, hand, ray)
  names(out) <- c("pente", "exposition_cos", "exposition_sin", "courbure",
                  "courbure_plan", "courbure_profil", tpi_names, "twi",
                  "surface_drainee", "mrvbf", "hauteur_reseau", "rayonnement")
  out
}

# Courbures de Zevenbergen et Thorne (1987), fenêtre 3x3 ; signes ESRI.
.curvatures <- function(dtm) {
  L <- terra::res(dtm)[1]
  f <- function(m) terra::focal(dtm, matrix(m, 3, 3, byrow = TRUE), fun = "sum",
                                na.rm = FALSE)
  # voisins z1 z2 z3 / z4 z5 z6 / z7 z8 z9 (ligne 1 = nord)
  z1 <- f(c(1, 0, 0, 0, 0, 0, 0, 0, 0)); z2 <- f(c(0, 1, 0, 0, 0, 0, 0, 0, 0))
  z3 <- f(c(0, 0, 1, 0, 0, 0, 0, 0, 0)); z4 <- f(c(0, 0, 0, 1, 0, 0, 0, 0, 0))
  z6 <- f(c(0, 0, 0, 0, 0, 1, 0, 0, 0)); z7 <- f(c(0, 0, 0, 0, 0, 0, 1, 0, 0))
  z8 <- f(c(0, 0, 0, 0, 0, 0, 0, 1, 0)); z9 <- f(c(0, 0, 0, 0, 0, 0, 0, 0, 1))
  z5 <- dtm
  D <- ((z4 + z6) / 2 - z5) / L^2
  E <- ((z2 + z8) / 2 - z5) / L^2
  F <- (-z1 + z3 + z7 - z9) / (4 * L^2)
  G <- (-z4 + z6) / (2 * L)
  H <- (z2 - z8) / (2 * L)
  g2 <- G^2 + H^2
  prof <- terra::ifel(g2 < 1e-12, 0, -2 * (D * G^2 + E * H^2 + F * G * H) / g2)
  plan <- terra::ifel(g2 < 1e-12, 0, 2 * (D * H^2 + E * G^2 - F * G * H) / g2)
  out <- c(-2 * (D + E), plan, prof)
  names(out) <- c("courbure", "courbure_plan", "courbure_profil")
  out
}

# TPI : altitude moins moyenne du disque de rayon r (m), centre exclu.
.tpi <- function(dtm, r) {
  L <- terra::res(dtm)[1]
  fact <- if (r / L > 40) ceiling(r / L / 40) else 1
  d <- if (fact > 1) terra::aggregate(dtm, fact, "mean", na.rm = FALSE) else dtm
  w <- terra::focalMat(d, r, "circle")
  w[(nrow(w) + 1) / 2, (ncol(w) + 1) / 2] <- 0
  w <- w / sum(w)
  m <- terra::focal(d, w, fun = "sum", na.rm = FALSE)
  if (fact > 1) m <- terra::resample(m, dtm, method = "bilinear")
  dtm - m
}

# Accumulation D8 (nombre de cellules, cellule comprise), sans remplissage.
.flow_accumulation <- function(dtm) {
  nr <- terra::nrow(dtm); nc <- terra::ncol(dtm)
  L <- terra::res(dtm)[1]
  z <- matrix(terra::values(dtm, mat = FALSE), nr, nc, byrow = TRUE)
  zp <- matrix(NA_real_, nr + 2, nc + 2)
  zp[2:(nr + 1), 2:(nc + 1)] <- z
  best <- matrix(0, nr, nc)   # meilleure pente descendante
  tgt <- matrix(0L, nr, nc)   # index lin\u00e9aire (colonnes) de la cible, 0 = puits
  for (di in -1:1) for (dj in -1:1) {
    if (di == 0 && dj == 0) next
    nb <- zp[(2:(nr + 1)) + di, (2:(nc + 1)) + dj]
    s <- (z - nb) / (L * sqrt(di^2 + dj^2))
    ok <- !is.na(s) & s > best
    best[ok] <- s[ok]
    tgt[ok] <- (((col(z) + dj) - 1L) * nr + (row(z) + di))[ok]
  }
  a <- ifelse(is.na(as.vector(z)), NA_real_, 1)
  tg <- as.vector(tgt)
  for (i in order(as.vector(z), decreasing = TRUE, na.last = NA)) {
    t <- tg[i]
    if (t > 0L) a[t] <- a[t] + a[i]
  }
  out <- terra::rast(dtm)
  terra::values(out) <- as.vector(t(matrix(a, nr, nc)))
  names(out) <- "acc"
  out
}

# Hauteur au-dessus de la cellule de cours d'eau la plus proche.
.height_above_streams <- function(dtm, streams) {
  s <- terra::values(terra::rasterize(streams, dtm, field = 1, touches = TRUE),
                     mat = FALSE)
  z <- terra::values(dtm, mat = FALSE)
  cells_s <- which(!is.na(s) & !is.na(z))
  out <- dtm * NA
  if (!length(cells_s)) {
    .warn_non_calcule("Aucune cellule de cours d'eau dans l'emprise : `hauteur_reseau` NA.")
    return(out)
  }
  all_cells <- which(!is.na(z))
  pts <- function(cells) {
    sf::st_as_sf(as.data.frame(terra::xyFromCell(dtm, cells)),
                 coords = c("x", "y"), crs = 2154)
  }
  nn <- sf::st_nearest_feature(pts(all_cells), pts(cells_s))
  v <- rep(NA_real_, length(z))
  v[all_cells] <- z[all_cells] - z[cells_s[nn]]
  terra::values(out) <- v
  out
}

# Jours types (Klein 1977) et nombre de jours par mois.
.JOURS_TYPES <- c(17, 47, 75, 105, 135, 162, 198, 228, 258, 288, 318, 344)
.JOURS_MOIS <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

# Rayonnement direct potentiel annuel (kWh/m2), hors atmosphère, sans ombres.
# pente_deg, expo_deg (depuis le nord, descente) : vecteurs ; lat_deg : scalaire.
.radiation_potential <- function(pente_deg, expo_deg, lat_deg, dt_h = 0.5) {
  rad <- pi / 180
  phi <- lat_deg * rad
  beta <- pente_deg * rad
  beta[is.na(beta)] <- 0
  expo_deg[is.na(expo_deg)] <- 180
  gam <- (expo_deg - 180) * rad          # azimut de surface depuis le sud, ouest +
  edges <- seq(-180, 180, by = 15 * dt_h)
  hs <- (edges[-length(edges)] + 7.5 * dt_h) * rad   # milieux des pas
  total <- numeric(length(beta))
  for (k in seq_along(.JOURS_TYPES)) {
    n <- .JOURS_TYPES[k]
    delta <- 23.45 * sin(2 * pi * (284 + n) / 365) * rad
    I0 <- 1367 * (1 + 0.033 * cos(2 * pi * n / 365))
    day <- numeric(length(beta))
    for (w in hs) {
      if (sin(delta) * sin(phi) + cos(delta) * cos(phi) * cos(w) <= 0) next
      ci <- sin(delta) * sin(phi) * cos(beta) -
        sin(delta) * cos(phi) * sin(beta) * cos(gam) +
        cos(delta) * cos(phi) * cos(beta) * cos(w) +
        cos(delta) * sin(phi) * sin(beta) * cos(gam) * cos(w) +
        cos(delta) * sin(beta) * sin(gam) * sin(w)
      day <- day + I0 * pmax(ci, 0) * dt_h
    }
    total <- total + day * .JOURS_MOIS[k]
  }
  total / 1000
}

.radiation_layer <- function(dtm, slope, asp) {
  e <- terra::ext(dtm)
  ctr <- sf::st_sfc(sf::st_point(c((e$xmin + e$xmax) / 2, (e$ymin + e$ymax) / 2)),
                    crs = 2154)
  lat <- sf::st_coordinates(sf::st_transform(ctr, 4326))[1, 2]
  out <- dtm * NA
  sl <- terra::values(slope, mat = FALSE)
  v <- .radiation_potential(sl, terra::values(asp, mat = FALSE) * 180 / pi, lat)
  v[is.na(sl)] <- NA_real_   # pourtour : pente inconnue, pas de valeur de plat
  terra::values(out) <- v
  out
}

# Avertissement de classe `sylvostation_non_calcule` (couche rendue en NA).
.warn_non_calcule <- function(msg) {
  warning(structure(class = c("sylvostation_non_calcule", "warning", "condition"),
                    list(message = msg, call = NULL)))
}
