#' Agréger un MNT à des résolutions plus grossières
#'
#' Agrège un modèle numérique de terrain par la **moyenne** (brief technique, § 4
#' étape 2 : indices de terrain sur 5 m puis résumés à la maille de sortie, pas sur 1 m). Le facteur d'agrégation
#' doit être entier ; si la maille d'origine est alignée sur un multiple de `res`
#' (ADR 0007 : grille de `resolution_m`, 20 m, d'origine multiple de 20 m), la grille
#' agrégée l'est aussi.
#'
#' @param dtm `SpatRaster` à une couche, en Lambert-93 (EPSG:2154), à maille carrée.
#' @param res Résolutions cibles, en mètres. Une résolution égale à celle du MNT le
#'   renvoie tel quel ; une résolution plus fine est refusée.
#' @return Une liste nommée (`res_5`, `res_20`, ...) de `SpatRaster`.
#' @examples
#' r <- terra::rast(nrows = 100, ncols = 100, xmin = 980000, xmax = 980100,
#'                  ymin = 6800000, ymax = 6800100, crs = "EPSG:2154")
#' terra::values(r) <- seq_len(terra::ncell(r))
#' names(aggregate_dtm(r, res = c(5, 20)))
#' @export
aggregate_dtm <- function(dtm, res = c(5, 20)) {
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
#' * `mrvbf` : indice multi-résolution de fond de vallée (Gallant et Dowling 2003), par
#'   l'extension GRASS `r.valley.bottom` (`whitebox` n'a pas d'outil MRVBF, référentiels
#'   § 20). Seuil de pente initial adapté à la maille (mission 027) : 16 % à 25 m
#'   (Gallant et Dowling 2003), divisé par 2 par grossissement x 3 (manuel de
#'   l'extension), règle prolongée aux mailles fines (44,2 % à 5 m, **provisoire, à
#'   vérifier**) ; `t_vf = 0,3` (défaut documenté) ; autres paramètres par défaut. Avec
#'   16 % à 5 m, le MRVBF était quasi nul partout sur les dalles vosgiennes. `NA` et avertissement
#'   de classe `sylvostation_non_calcule` si `mrvbf = FALSE` ou si GRASS (`grass`) ou
#'   l'extension est absent. Calcul lent (2 à 4 minutes mesurées pour 1 600 à 57 600
#'   cellules) ;
#' * `hauteur_reseau` (m), voir [height_above_network()] : HAND (altitude moins celle de
#'   la première cellule du réseau atteinte en suivant les directions D8 de
#'   `surface_drainee`, les cuvettes intérieures étant franchies par leur col). `NA` si
#'   l'écoulement n'atteint pas le réseau dans l'emprise ; jamais négatif ;
#'   `NA` avec avertissement si `streams` est `NULL` ;
#' * `rayonnement` (kWh/m2/an) : rayonnement direct potentiel **hors atmosphère et sans
#'   ombres portées**, 12 jours types (Klein 1977), pas de 30 min, formules d'incidence
#'   de Duffie et Beckman (*Solar Engineering of Thermal Processes*, éq. 1.6.2 et
#'   1.10.3). Indice relatif d'exposition, non un flux au sol.
#'
#' Choisir la résolution en amont avec [aggregate_dtm()] (5 m puis `resolution_m`, ADR 0007). Le
#' pourtour d'une cellule du MNT est `NA` pour la pente, l'exposition et les courbures.
#'
#' @param dtm `SpatRaster` à une couche, EPSG:2154, maille carrée, altitudes en mètres.
#' @param tpi_radii Rayons du TPI, en mètres.
#' @param mrvbf `TRUE` pour calculer le MRVBF par GRASS (lent : 2 à 4 minutes mesurées pour 1 600 à
#'   57 600 cellules) ; `FALSE` (défaut) laisse la couche à `NA` avec
#'   avertissement. Le pipeline en mode réel doit passer `TRUE`.
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
derive_terrain <- function(dtm, tpi_radii = c(100, 300, 1000), streams = NULL,
                           mrvbf = FALSE) {
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
  tg <- .d8_targets(dtm)
  acc <- .flow_accumulation(dtm, tg)
  twi <- log((acc * L) / tan(terra::clamp(slope, lower = 0.1, values = TRUE) * pi / 180))

  tpis <- lapply(tpi_radii, function(r) .tpi(dtm, r))
  tpi_names <- paste0("tpi_", format(tpi_radii, trim = TRUE))

  if (is.null(streams)) {
    .warn_non_calcule("`streams` absent : `hauteur_reseau` non calcul\u00e9e (NA).")
    hand <- dtm * NA
  } else {
    hand <- .height_above_streams(dtm, streams, tg)
  }
  if (isTRUE(mrvbf)) {
    mrvbf_r <- .mrvbf_grass(dtm)
  } else {
    .warn_non_calcule("`mrvbf` non demand\u00e9 (`mrvbf = FALSE`) : NA (calcul GRASS lent).")
    mrvbf_r <- dtm * NA
  }

  ray <- .radiation_layer(dtm, slope, asp)

  # terra renvoie 90 degres sur terrain plat : exposition indefinie => NA
  asp <- terra::ifel(slope == 0, NA, asp)
  out <- c(slope, cos(asp), sin(asp), curv, terra::rast(tpis), twi, acc * L^2,
           mrvbf_r, hand, ray)
  names(out) <- c("pente", "exposition_cos", "exposition_sin", "courbure",
                  "courbure_plan", "courbure_profil", tpi_names, "twi",
                  "surface_drainee", "mrvbf", "hauteur_reseau", "rayonnement")
  out
}

# TRUE si l'extension GRASS `ext` est installee (`g.extension -a`), sans chemin en dur.
.grass_has_extension <- function(ext = "r.valley.bottom", grass = Sys.which("grass")) {
  if (!nzchar(grass)) return(FALSE)
  res <- suppressWarnings(system2(grass, c("--tmp-project", "EPSG:2154", "--exec",
                                           "g.extension", "-a"), stdout = TRUE, stderr = TRUE))
  ext %in% trimws(res)
}

# Seuil de pente initial du MRVBF (%) pour une maille `res_m` (m). Manuel de
# r.valley.bottom (GRASS 8.4.2) : 16 pour un MNT de 25 m (Gallant et Dowling 2003), divise
# par 2 a chaque pas de grossissement x 3 au-dessus de 25 m. En dessous de 25 m, la meme
# regle est prolongee (x 2 par affinement x 3) : 44,2 a 5 m, 18,4 a 20 m. Prolongement
# provisoire, a verifier ; coherent avec l'exemple du manuel (MNT de 6 m, t_slope = 40).
# Mission 027 : avec 16 a 5 m, la pente mediane des cellules du reseau (23 %) depasse le
# seuil et le MRVBF est quasi nul partout.
.mrvbf_t_slope <- function(res_m) {
  if (!is.numeric(res_m) || length(res_m) != 1L || is.na(res_m) || res_m <= 0) {
    stop("`res_m` doit être une résolution positive (m).", call. = FALSE)
  }
  16 * 2^(log(25 / res_m, base = 3))
}

# Commande r.valley.bottom. t_vf = 0,3 (defaut documente par le manuel de l'extension) :
# le script lit t_vf dans l'option t_rf (`t_vf = float(options["t_rf"])`, lu le
# 2026-11-18, defaut 0,35), d'ou t_rf = 0,3 aussi (MRRTF non calcule).
.mrvbf_command <- function(t_slope) {
  paste0("r.valley.bottom elevation=dem mrvbf=mrvbf t_slope=",
         format(round(t_slope, 2), nsmall = 1), " t_vf=0.3 t_rf=0.3 --quiet")
}

# MRVBF par GRASS (extension r.valley.bottom) dans un projet temporaire : le MNT est
# ecrit en GeoTIFF, lu par r.in.gdal, le resultat relu par terra. Sans GRASS, ou si
# l'extension echoue : NA et avertissement `sylvostation_non_calcule`. Seuil de pente
# adapte a la maille (.mrvbf_t_slope).
.mrvbf_grass <- function(dtm, grass = Sys.which("grass"),
                         t_slope = .mrvbf_t_slope(terra::res(dtm)[1])) {
  na_out <- function(msg) {
    .warn_non_calcule(paste0("`mrvbf` non calcul\u00e9 (NA) : ", msg))
    dtm * NA
  }
  if (!nzchar(grass)) return(na_out("GRASS GIS (`grass`) introuvable, \u00e0 installer."))
  dir <- tempfile("mrvbf_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  inp <- file.path(dir, "in.tif")
  outp <- file.path(dir, "out.tif")
  terra::writeRaster(dtm, inp, datatype = "FLT8S")
  sh <- file.path(dir, "run.sh")
  writeLines(c("set -e",
               paste0("r.in.gdal input='", inp, "' output=dem --quiet"),
               "g.region raster=dem",
               .mrvbf_command(t_slope),
               paste0("r.out.gdal input=mrvbf output='", outp,
                      "' format=GTiff --overwrite --quiet -c -m")), sh)
  res <- suppressWarnings(system2(grass, c("--tmp-project", shQuote(inp), "--exec", "sh",
                                           shQuote(sh)), stdout = TRUE, stderr = TRUE))
  if (!file.exists(outp)) {
    return(na_out(paste0("\u00e9chec de GRASS ou de l'extension `r.valley.bottom` (",
                         "g.extension extension=r.valley.bottom) : ",
                         paste(utils::tail(res, 2), collapse = " "))))
  }
  m <- terra::rast(outp)
  if (!all(c(terra::nrow(m), terra::ncol(m)) == c(terra::nrow(dtm), terra::ncol(dtm))) ||
      !isTRUE(all.equal(as.vector(terra::ext(m)), as.vector(terra::ext(dtm))))) {
    return(na_out("grille de sortie de GRASS diff\u00e9rente de celle du MNT."))
  }
  out <- dtm * NA
  terra::values(out) <- terra::values(m, mat = FALSE)
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

# Directions D8 sans remplissage : index lineaire (colonnes) de la cellule cible, 0 = puits.
# La cible est toujours strictement plus basse que la cellule.
.d8_targets <- function(dtm) {
  nr <- terra::nrow(dtm); nc <- terra::ncol(dtm)
  L <- terra::res(dtm)[1]
  z <- matrix(terra::values(dtm, mat = FALSE), nr, nc, byrow = TRUE)
  zp <- matrix(NA_real_, nr + 2, nc + 2)
  zp[2:(nr + 1), 2:(nc + 1)] <- z
  best <- matrix(0, nr, nc)   # meilleure pente descendante
  tgt <- matrix(0L, nr, nc)
  for (di in -1:1) for (dj in -1:1) {
    if (di == 0 && dj == 0) next
    nb <- zp[(2:(nr + 1)) + di, (2:(nc + 1)) + dj]
    sl <- (z - nb) / (L * sqrt(di^2 + dj^2))
    ok <- !is.na(sl) & sl > best
    best[ok] <- sl[ok]
    tgt[ok] <- (((col(z) + dj) - 1L) * nr + (row(z) + di))[ok]
  }
  as.vector(tgt)
}

# Accumulation D8 (nombre de cellules, cellule comprise), sans remplissage.
.flow_accumulation <- function(dtm, tg = .d8_targets(dtm)) {
  nr <- terra::nrow(dtm); nc <- terra::ncol(dtm)
  zc <- matrix(terra::values(dtm, mat = FALSE), nr, nc, byrow = TRUE)
  a <- ifelse(is.na(as.vector(zc)), NA_real_, 1)
  for (i in order(as.vector(zc), decreasing = TRUE, na.last = NA)) {
    t <- tg[i]
    if (t > 0L) a[t] <- a[t] + a[i]
  }
  out <- terra::rast(dtm)
  terra::values(out) <- as.vector(t(matrix(a, nr, nc)))
  names(out) <- "acc"
  out
}

# HAND : pour chaque cellule, altitude moins celle de la premiere cellule du reseau
# atteinte en suivant les directions D8, les cuvettes interieures etant franchies par
# leur col de debordement (.route_pits, mission 027). NA si l'ecoulement n'atteint pas le
# reseau (sortie du MNT, cellule en aval du reseau). Une cellule de cuvette plus basse que
# le reseau atteint vaut 0 (jamais negatif).
.height_above_streams <- function(dtm, streams, tg = .d8_targets(dtm)) {
  nr <- terra::nrow(dtm); nc <- terra::ncol(dtm)
  out <- dtm * NA
  sr <- terra::rasterize(streams, dtm, field = 1, touches = TRUE)
  zr <- terra::values(dtm, mat = FALSE)
  is_s <- !is.na(terra::values(sr, mat = FALSE)) & !is.na(zr)
  if (!any(is_s)) {
    .warn_non_calcule("Aucune cellule de cours d'eau dans l'emprise : `hauteur_reseau` NA.")
    return(out)
  }
  # tg est en index lineaire par colonnes ; terra range par lignes : permutation
  perm <- as.vector(matrix(seq_len(nr * nc), nr, nc, byrow = TRUE))
  z_cm <- zr[perm]
  s_cm <- is_s[perm]
  tg2 <- .route_pits(z_cm, nr, nc, tg, s_cm)
  ref <- .first_on_path(z_cm, s_cm, tg2)
  h <- numeric(nr * nc)
  h[perm] <- pmax(z_cm - ref, 0)
  terra::values(out) <- h
  out
}

# Altitude de la premiere cellule `stop` atteinte en suivant `tg` (index lineaire par
# colonnes, 0 = fin), par doublement de pointeurs (vectoriel, ne suppose pas que la cible
# soit plus basse). NA si le chemin finit sans rencontrer `stop`.
.first_on_path <- function(z, stop, tg, max_iter = 64L) {
  val <- ifelse(stop, z, NA_real_)
  nxt <- ifelse(stop | is.na(z), 0L, as.integer(tg))
  for (k in seq_len(max_iter)) {
    act <- which(is.na(val) & nxt > 0L)
    if (!length(act)) break
    j <- nxt[act]
    val[act] <- val[j]
    nxt[act] <- nxt[j]
  }
  val
}

# Franchissement des cuvettes pour le HAND (mission 027). Sur le MNT LiDAR, les directions
# D8 sans remplissage finissent dans des cuvettes interieures (remblais, artefacts) : leur
# bassin restait NA. Chaque cuvette (puits D8 ni sur le reseau, ni au bord du MNT) est
# reliee, par son col de debordement, au bassin voisin. Le col est choisi comme dans un
# remplissage par inondation prioritaire (Barnes, Lehman et Mulla 2014, Computers &
# Geosciences 62, 117-127) : arbre couvrant minimal des bassins (poids = altitude du col,
# max des deux cellules), les exutoires (reseau, bord, NA) etant relies a une racine. Le
# puits pointe alors vers la cellule de l'autre cote du col. `z`, `stop`, `tg` sont en
# index lineaire par colonnes ; renvoie les cibles modifiees.
.route_pits <- function(z, nr, nc, tg, stop) {
  n <- nr * nc
  ok <- !is.na(z)
  term <- rep(NA_integer_, n)
  for (i in order(z, na.last = NA)) {          # cibles toujours plus basses
    t <- tg[i]
    term[i] <- if (t > 0L) term[t] else i
  }
  # bord : une des 8 voisines est NA ou hors du MNT
  zm <- matrix(z, nr, nc)
  zp <- matrix(NA_real_, nr + 2, nc + 2)
  zp[2:(nr + 1), 2:(nc + 1)] <- zm
  edge <- matrix(FALSE, nr, nc)
  for (di in -1:1) for (dj in -1:1) {
    edge <- edge | is.na(zp[(2:(nr + 1)) + di, (2:(nc + 1)) + dj])
  }
  edge <- as.vector(edge)
  pits <- which(ok & tg == 0L & !stop & !edge)
  if (!length(pits)) return(tg)
  # paires de cellules voisines (8-connexite) de bassins differents
  is_out <- function(l) stop[l] | edge[l]
  tm <- matrix(term, nr, nc)
  pr <- function(r1, c1, r2, c2) {   # decalage traite a part : memoire bornee
    if (!length(r1) || !length(c1)) return(NULL)
    a <- as.vector(tm[r1, c1, drop = FALSE]); b <- as.vector(tm[r2, c2, drop = FALSE])
    k <- which(!is.na(a) & !is.na(b) & a != b)
    k <- k[!(is_out(a[k]) & is_out(b[k]))]
    if (!length(k)) return(NULL)
    rr <- rep(r1, length(c1))[k]; cc <- rep(c1, each = length(r1))[k]
    i1 <- (cc - 1L) * nr + rr
    i2 <- (cc + (c2[1] - c1[1]) - 1L) * nr + rr + (r2[1] - r1[1])
    cbind(i1, i2)
  }
  s1 <- seq_len(nr - 1L); s2 <- seq_len(nc - 1L)
  p <- rbind(pr(seq_len(nr), s2, seq_len(nr), s2 + 1L),
             pr(s1, seq_len(nc), s1 + 1L, seq_len(nc)),
             pr(s1, s2, s1 + 1L, s2 + 1L),
             pr(s1, s2 + 1L, s1 + 1L, s2))
  if (is.null(p) || !nrow(p)) return(tg)
  la <- term[p[, 1]]; lb <- term[p[, 2]]
  w <- pmax(z[p[, 1]], z[p[, 2]])
  # un seul col (le plus bas) par paire de bassins
  key <- pmin(la, lb) * (n + 1) + pmax(la, lb)
  o <- order(w)
  o <- o[!duplicated(key[o])]
  p <- p[o, , drop = FALSE]; la <- la[o]; lb <- lb[o]
  # union-find sur les bassins ; racine 0 = exutoires
  labs <- unique(c(la, lb))
  ix <- function(l) match(l, labs)
  parent <- seq_along(labs)
  parent[is_out(labs)] <- 0L
  find <- function(i) {
    while (i != 0L && parent[i] != i) {
      if (parent[i] != 0L) parent[i] <<- if (parent[parent[i]] == 0L) 0L else parent[parent[i]]
      i <- parent[i]
    }
    i
  }
  a <- ix(la); b <- ix(lb)
  mst <- logical(length(a))
  reste <- sum(parent != 0L)
  for (k in seq_along(a)) {
    if (!reste) break
    ra <- find(a[k]); rb <- find(b[k])
    if (ra == rb) next
    if (ra == 0L) parent[rb] <- 0L else parent[ra] <- rb
    reste <- reste - 1L
    mst[k] <- TRUE
  }
  # orientation vers les exutoires (parcours en largeur)
  ea <- a[mst]; eb <- b[mst]; ca <- p[mst, 1]; cb <- p[mst, 2]
  vu <- is_out(labs)
  file <- which(vu)
  tg2 <- tg
  while (length(file)) {
    u <- file[1]; file <- file[-1]
    for (k in which((ea == u & !vu[eb]) | (eb == u & !vu[ea]))) {
      if (ea[k] == u) { v <- eb[k]; tgt <- ca[k] } else { v <- ea[k]; tgt <- cb[k] }
      if (vu[v]) next
      vu[v] <- TRUE
      tg2[labs[v]] <- tgt   # le puits du bassin v deborde vers l'autre cote du col
      file <- c(file, v)
    }
  }
  tg2
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

# Azimut de l'exposition (degres depuis le nord, sens horaire : convention de terra et de
# `exposition_cos/sin`) vers la convention de GRASS `r.sun` (degres depuis l'est, sens
# antihoraire : 90 = nord, 180 = ouest, 270 = sud ; `r.sun --help`, GRASS 8.4.2,
# « 270 is south »). Formule : (450 - azimut) mod 360 ; NA conserve.
.aspect_to_rsun <- function(az) {
  (450 - az) %% 360
}

#' Facteur topographique de rayonnement mensuel (GRASS `r.sun`, ciel clair)
#'
#' Pour chaque cellule `x` et chaque mois `j` (jour type de Klein 1977) :
#' k(x, j) = G(x ; pente, exposition, ombres portées) / G(x ; pente 0, sans ombres), où
#' G est le rayonnement global journalier (`glob_rad`, direct + diffus + réfléchi,
#' Wh m⁻² j⁻¹) de GRASS `r.sun` (Šúri et Hofierka 2004) **en ciel clair** (`coeff_bh`,
#' `coeff_dh` absents). C'est la méthode A de `docs/referentiels.md` § 25.4 (adaptation
#' **non validée** de Dyer 2009) : k multiplie le rayonnement SAFRAN dans l'ETP de
#' [hydric_stress_grid()].
#'
#' * Pente et exposition : `terra::terrain` (Horn 1981), comme la couche `pente` de
#'   [derive_terrain()] ; l'exposition (depuis le nord, sens horaire) est convertie vers
#'   la convention de `r.sun` (270 = sud) par (450 - azimut) mod 360. Terrain plat :
#'   pente 0. Pourtour du MNT (pente inconnue) : `NA`.
#' * Numérateur avec ombres portées (défaut de `r.sun`) ; dénominateur `r.sun -p
#'   slope_value=0` (plat, sans ombres).
#' * Valeurs **provisoires** (§ 25.5) : ciel clair, trouble de Linke 3,0, albédo 0,2
#'   (défauts du manuel), jours types de Klein, pas de 0,5 h. Les ombres portées par le
#'   relief situé hors du MNT fourni ne sont pas vues (bord de l'emprise).
#' * **Repli** : sans GRASS (`grass` introuvable) ou si `r.sun` échoue, k = 1 partout
#'   (méthode « climatique », attribut `methode`), avertissement de classe
#'   `sylvostation_non_calcule`.
#'
#' Coût mesuré (GRASS 8.4.2, 3 fils, 2026-11-18, mission 021) : 4,1 s par jour type
#' avec ombres et 0,9 s pour le plat sur 360 000 cellules de 25 m (225 dalles), soit
#' environ une minute pour les 12 mois ; plus de 10 minutes par jour à 5 m. Mesure de la
#' mission 025 (2026-11-18, machine chargée, 1 cœur disponible, 12 mois avec ombres) : 36 s
#' pour 90 000 cellules de 20 m et 301 s pour 562 500 cellules de 20 m (225 dalles).
#'
#' k est une variable **fine** (`k_01` à `k_12`, voir [FINE_VARIABLES]) : jamais aux
#' placettes IFN ([assert_no_fine_extract_on_ifn()]).
#'
#' @param dtm `SpatRaster` à une couche, EPSG:2154, maille carrée (`resolution_m` dans le pipeline),
#'   altitudes en mètres.
#' @param days Jours de l'année des 12 mois (jours types de Klein 1977).
#' @param linke,albedo Trouble de Linke et albédo de `r.sun` (provisoires).
#' @param step Pas de temps de `r.sun` (heures, provisoire).
#' @param nprocs Nombre de fils de `r.sun`.
#' @param grass Exécutable GRASS (`""` : absent, repli).
#' @return `SpatRaster` à 12 couches `k_01` à `k_12` sur la grille de `dtm`, attributs
#'   `methode` (`"r.sun"` ou `"climatique"`), `repli` (raison du repli) et `parametres`.
#' @examples
#' f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
#' d <- terra::rast(f)   # surface synthétique
#' k <- suppressWarnings(solar_factor(d, grass = ""))   # sans GRASS : repli k = 1
#' attr(k, "methode")
#' @export
solar_factor <- function(dtm, days = .JOURS_TYPES, linke = 3, albedo = 0.2, step = 0.5,
                         nprocs = 1, grass = Sys.which("grass")) {
  .check_dtm(dtm)
  if (!is.numeric(days) || length(days) != 12L || anyNA(days) || any(days < 1 | days > 365)) {
    stop("`days` doit contenir 12 jours de l'ann\u00e9e (1 \u00e0 365).", call. = FALSE)
  }
  param <- list(ciel = "clair", linke = linke, albedo = albedo, step_h = step,
                jours = days, statut = "provisoire (r\u00e9f\u00e9rentiels \u00a7 25.5)")
  noms <- sprintf("k_%02d", 1:12)
  repli <- function(msg) {
    .warn_non_calcule(paste0("Facteur de rayonnement k = 1 (m\u00e9thode climatique) : ", msg))
    un <- terra::ifel(is.na(dtm), NA, 1)
    out <- terra::rast(rep(list(un), 12))
    names(out) <- noms
    attr(out, "methode") <- "climatique"
    attr(out, "repli") <- msg
    attr(out, "parametres") <- param
    out
  }
  if (!nzchar(grass)) return(repli("GRASS GIS (`grass`) introuvable, \u00e0 installer."))

  names(dtm) <- "z"
  slope <- terra::terrain(dtm, "slope", unit = "degrees", neighbors = 8)
  az <- terra::terrain(dtm, "aspect", unit = "degrees", neighbors = 8)
  asp <- terra::ifel(slope == 0, 270, .aspect_to_rsun(az))   # plat : exposition sans effet

  dir <- tempfile("rsun_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  f <- function(n) file.path(dir, n)
  terra::writeRaster(dtm, f("dem.tif"), datatype = "FLT8S")
  terra::writeRaster(slope, f("slope.tif"), datatype = "FLT8S")
  terra::writeRaster(asp, f("aspect.tif"), datatype = "FLT8S")
  cmd <- c("set -e",
           paste0("r.in.gdal input='", f("dem.tif"), "' output=dem --quiet"),
           paste0("r.in.gdal input='", f("slope.tif"), "' output=sl --quiet"),
           paste0("r.in.gdal input='", f("aspect.tif"), "' output=as --quiet"),
           "g.region raster=dem")
  for (i in 1:12) {
    opts <- paste0(" linke_value=", linke, " albedo_value=", albedo, " day=", days[i],
                   " step=", step, " nprocs=", nprocs, " --quiet --overwrite")
    out_g <- f(sprintf("g%02d.tif", i))
    out_p <- f(sprintf("p%02d.tif", i))
    cmd <- c(cmd,
             paste0("r.sun elevation=dem slope=sl aspect=as glob_rad=g", i, opts),
             paste0("r.sun -p elevation=dem slope_value=0 glob_rad=p", i, opts),
             paste0("r.out.gdal input=g", i, " output='", out_g,
                    "' format=GTiff type=Float64 --overwrite --quiet -c -m"),
             paste0("r.out.gdal input=p", i, " output='", out_p,
                    "' format=GTiff type=Float64 --overwrite --quiet -c -m"))
  }
  writeLines(cmd, f("run.sh"))
  res <- suppressWarnings(system2(grass, c("--tmp-project", shQuote(f("dem.tif")), "--exec",
                                           "sh", shQuote(f("run.sh"))),
                                  stdout = TRUE, stderr = TRUE))
  sorties <- f(c(sprintf("g%02d.tif", 1:12), sprintf("p%02d.tif", 1:12)))
  if (!all(file.exists(sorties))) {
    return(repli(paste0("\u00e9chec de GRASS `r.sun` : ",
                        paste(utils::tail(res, 2), collapse = " "))))
  }
  n <- terra::ncell(dtm)
  vals <- vapply(1:12, function(i) {
    g <- terra::rast(sorties[i])
    p <- terra::rast(sorties[12 + i])
    if (!all(c(terra::nrow(g), terra::ncol(g)) == c(terra::nrow(dtm), terra::ncol(dtm)))) {
      return(rep(NA_real_, n))
    }
    gv <- terra::values(g, mat = FALSE)
    pv <- terra::values(p, mat = FALSE)
    ifelse(is.finite(gv) & is.finite(pv) & pv > 0, gv / pv, NA_real_)
  }, numeric(n))
  if (all(is.na(vals))) return(repli("grille de sortie de GRASS diff\u00e9rente de celle du MNT."))
  vals[is.na(terra::values(slope, mat = FALSE)), ] <- NA_real_   # pourtour : pente inconnue
  out <- terra::rast(dtm, nlyrs = 12)
  terra::values(out) <- vals
  names(out) <- noms
  attr(out, "methode") <- "r.sun"
  attr(out, "parametres") <- param
  out
}
