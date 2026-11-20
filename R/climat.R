# Descente d'echelle du climat SAFRAN (mission 033) : interpolation bilineaire entre les
# centres des mailles de 8 km, sur un reseau de 1 km. Le champ obtenu est lisse a l'echelle
# de 8 km : c'est un climat kilometrique (variable large), croisable avec les placettes IFN
# (CLAUDE.md, regle des 700 m). Aucune correction d'altitude (option A differee, journal
# du 2026-11-19).
# A VERIFIER : l'interpolation bilineaire (aucune reference publiee lue) et le pas de 1 km
# sont des choix de la mission 033, provisoires (docs/referentiels.md section 32).

#' Poids d'interpolation bilinéaire entre les centres des mailles SAFRAN
#'
#' Pour chaque point (Lambert-93, x = est, y = nord), les quatre mailles SAFRAN qui
#' l'entourent sur la grille de 8 km (Lambert II étendu, `LAMBX`, `LAMBY` en hm) et leurs
#' poids bilinéaires. Une maille voisine absente de `safran` (bord de l'extrait) reçoit un
#' poids nul et les autres poids sont renormalisés : hors de l'enveloppe des centres, la
#' valeur est celle du bord (extrapolation constante). Un point à plus d'une
#' demi-diagonale (5,66 km) de toute maille fournie n'a pas de poids (ligne de `NA`),
#' comme pour la maille la plus proche. Au centre d'une maille, son poids vaut 1.
#' L'interpolation bilinéaire est un choix de la mission 033, aucune référence publiée
#' lue : à vérifier.
#'
#' @param x,y Coordonnées en Lambert-93 (EPSG:2154), x = est, y = nord (m).
#' @param safran `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).
#' @return Une matrice (points x mailles) de poids de somme 1 (ou `NA`), colonnes
#'   nommées par maille (`"LAMBX_LAMBY"`), dans l'ordre de `.mailles_safran()`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' w <- safran_weights(1014550, 6799283, s)   # centre de la maille 9640_23690
#' round(w[, w > 0.001], 3)
#' @export
safran_weights <- function(x, y, safran) {
  if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y)) {
    stop("`x` et `y` doivent \u00eatre des coordonn\u00e9es num\u00e9riques de m\u00eame longueur.",
         call. = FALSE)
  }
  if (!is.data.frame(safran) || !all(c("LAMBX", "LAMBY") %in% names(safran))) {
    stop("`safran` doit avoir les colonnes LAMBX et LAMBY.", call. = FALSE)
  }
  .safran_poids(x, y, .mailles_safran(.safran_norm(safran)))
}

# Poids bilineaires (points x mailles). `mailles` : resultat de .mailles_safran().
# Matrice dense, pour un petit nombre de points (reseau de 1 km, placettes) ; une grille fine
# passe par .safran_poids4() (forme creuse, mission 039).
.safran_poids <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  n <- length(x)
  W <- matrix(0, n, nrow(mailles), dimnames = list(NULL, mailles$maille))
  if (!n) return(W)
  P <- .safran_poids4(x, y, mailles, dmax)
  for (c in 1:4) {
    ok <- !is.na(P$j[, c]) & P$w[, c] > 0
    W[cbind(which(ok), P$j[ok, c])] <- W[cbind(which(ok), P$j[ok, c])] + P$w[ok, c]
  }
  W[P$hors, ] <- NA_real_
  W
}

# Poids bilineaires sous forme creuse (mission 039) : au plus quatre mailles par point.
# Rend une liste : `j` (points x 4, rang de la maille dans `mailles`, NA si absente), `w`
# (points x 4, poids renormalises de somme 1, 0 pour un coin absent) et `hors` (point sans
# poids : plus d'une demi-diagonale de toute maille, ou aucun coin fourni). Memoire en
# O(points), au lieu de O(points x mailles) pour la matrice dense.
.safran_poids4 <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  n <- length(x)
  J <- matrix(NA_integer_, n, 4)
  Wt <- matrix(0, n, 4)
  if (!n) return(list(j = J, w = Wt, hors = logical(0)))
  # coordonnees des points sur la grille SAFRAN (Lambert II etendu, hm)
  p <- sf::st_as_sf(data.frame(x = x, y = y), coords = c("x", "y"), crs = 2154)
  q <- sf::st_coordinates(sf::st_transform(p, 27572)) / 100
  pas <- 80                                   # 8 km en hm
  x0 <- min(mailles$LAMBX)
  y0 <- min(mailles$LAMBY)
  fx <- (q[, 1] - x0) / pas
  fy <- (q[, 2] - y0) / pas
  i0 <- floor(fx)
  j0 <- floor(fy)
  tx <- fx - i0
  ty <- fy - j0
  cle <- paste(mailles$LAMBX, mailles$LAMBY, sep = "_")
  coins <- list(c(0, 0), c(1, 0), c(0, 1), c(1, 1))
  dmin <- rep(Inf, n)
  for (c in seq_along(coins)) {
    cn <- coins[[c]]
    w <- (if (cn[1]) tx else 1 - tx) * (if (cn[2]) ty else 1 - ty)
    k <- paste(x0 + (i0 + cn[1]) * pas, y0 + (j0 + cn[2]) * pas, sep = "_")
    j <- match(k, cle)
    # distance (Lambert-93) au centre de ce coin : la maille la plus proche d'un point est
    # toujours un coin de sa case (toute autre maille est a 8 km ou plus)
    a <- !is.na(j)
    dmin[a] <- pmin(dmin[a], sqrt((mailles$x[j[a]] - x[a])^2 + (mailles$y[j[a]] - y[a])^2))
    ok <- a & w > 0
    J[ok, c] <- j[ok]
    Wt[ok, c] <- w[ok]
  }
  # poids residuels d'arrondi (centre d'une maille : 1 et 1e-14) ramenes a 0
  Wt[Wt < 1e-9] <- 0
  J[Wt == 0] <- NA_integer_
  s <- rowSums(Wt)
  hors <- dmin > dmax | s <= 0
  Wt[!hors, ] <- Wt[!hors, , drop = FALSE] / s[!hors]
  Wt[hors, ] <- 0
  J[hors, ] <- NA_integer_
  list(j = J, w = Wt, hors = hors)
}

# Valeur interpolee aux points (forme creuse) d'une valeur par maille `v` (meme ordre que
# `mailles`) : NA pour un point hors grille ou dont un coin de poids positif est NA.
.interp4 <- function(P, v) {
  out <- numeric(nrow(P$j))
  manque <- P$hors
  for (c in 1:4) {
    j <- P$j[, c]
    a <- !is.na(j)
    val <- rep(0, length(j))
    val[a] <- v[j[a]]
    manque <- manque | (a & is.na(val))
    val[is.na(val)] <- 0
    out <- out + P$w[, c] * val
  }
  out[manque] <- NA_real_
  out
}

# Series SAFRAN en tableau large : une matrice (jours x mailles) par variable, jours tries.
.safran_large <- function(s, vars, mailles) {
  cle <- paste(s$LAMBX, s$LAMBY, sep = "_")
  dates <- sort(unique(s$DATE))
  i <- match(s$DATE, dates)
  j <- match(cle, mailles$maille)
  out <- lapply(vars, function(v) {
    m <- matrix(NA_real_, length(dates), nrow(mailles), dimnames = list(NULL, mailles$maille))
    ok <- !is.na(j)
    m[cbind(i[ok], j[ok])] <- s[[v]][ok]
    m
  })
  names(out) <- vars
  list(DATE = dates, v = out)
}

# Serie interpolee (jours x points) d'une variable : somme ponderee des mailles. Une maille
# de poids nul ne propage pas ses NA ; une maille de poids positif sans valeur donne NA.
.safran_interp <- function(m, W) {
  W0 <- W
  W0[is.na(W0)] <- 0
  m0 <- m
  m0[is.na(m0)] <- 0
  # arrondi a 1e-9 : une moyenne de valeurs egales reste egale (la pluie SAFRAN est au
  # dixieme de mm ; BILJOU intercepte toute pluie <= 1 mm, seuil sensible au bruit
  # d'arrondi de la somme ponderee)
  out <- round(m0 %*% t(W0), 9)
  manque <- (is.na(m) * 1) %*% t((W0 > 0) * 1) > 0
  out[manque] <- NA_real_
  out[, apply(is.na(W), 1, all)] <- NA_real_
  out
}

# Tableau SAFRAN d'un point interpole (colonnes de `large`, DATE), pret pour .meteo_topo().
.safran_point <- function(large, w) {
  d <- data.frame(DATE = large$DATE)
  for (v in names(large$v)) d[[v]] <- as.numeric(.safran_interp(large$v[[v]], rbind(w)))
  d
}

# Agregats climatiques par maille (saison de vegetation `months`) : p_sv, etp_sv, t_moy.
.climat_mailles <- function(safran, months) {
  d <- as.data.frame(safran)
  d$an <- as.integer(substr(as.character(d$DATE), 1, 4))
  d$mois <- as.integer(substr(as.character(d$DATE), 5, 6))
  d$cle <- paste(d$LAMBX, d$LAMBY, sep = "_")
  sv <- d[d$mois %in% months, , drop = FALSE]
  p <- stats::aggregate(cbind(p = PRELIQ + PRENEI, etp = ETP) ~ cle + an, data = sv, FUN = sum)
  p <- stats::aggregate(cbind(p, etp) ~ cle, data = p, FUN = mean)
  if ("T" %in% names(d) && any(!is.na(d$T))) {
    t <- stats::aggregate(T ~ cle + an, data = d, FUN = mean)
    t <- stats::aggregate(T ~ cle, data = t, FUN = mean)
  } else {
    t <- data.frame(cle = p$cle, T = NA_real_)
  }
  m <- unique(d[, c("cle", "LAMBX", "LAMBY")])
  merge(merge(m, p, by = "cle"), t, by = "cle", all.x = TRUE)
}

# Remplit le raster kilometrique `r` (EPSG:2154) par interpolation bilineaire des agregats
# de maille `m` (colonnes p, etp, T) entre les centres des mailles.
.climat_bilineaire <- function(r, m) {
  mailles <- .mailles_safran(m[, c("LAMBX", "LAMBY")])
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))   # x = est, y = nord
  W <- .safran_poids(xy[, 1], xy[, 2], mailles)
  val <- m[match(mailles$maille, m$cle), c("p", "etp", "T")]
  v <- vapply(val, function(z) as.numeric(.safran_interp(rbind(z), W)), numeric(nrow(xy)))
  v <- matrix(v, ncol = 3)
  if (all(is.na(val$T))) v[, 3] <- NA_real_
  terra::values(r) <- v
  r
}

# ---- Temperature corrigee du relief (mission 039) ----------------------------------------
# Methode retenue (plan 039, arbitrage du 2026-11-20) : T = T_bilineaire + G x (z - z_bilineaire),
# G estime sur les mailles SAFRAN de la SER (T ~ altitude moyenne + x + y). Validation croisee en
# laissant une maille de cote (GRECO D) : RMSE 0,11 degC contre 0,23 en bilineaire et 0,12 pour
# meteoland (Thornton 1997) ; docs/referentiels.md section 37.

# T moyenne de chaque maille (moyenne des moyennes annuelles des jours de `months`).
.t_mailles <- function(safran, months = 1:12) {
  d <- .safran_norm(safran)
  if (!"T" %in% names(d) || all(is.na(d$T))) {
    stop("`safran` n'a pas de température (colonne T ou T_Q).", call. = FALSE)
  }
  d <- d[!is.na(d$T), , drop = FALSE]
  d$an <- as.integer(substr(as.character(d$DATE), 1, 4))
  d$mois <- as.integer(substr(as.character(d$DATE), 5, 6))
  d <- d[d$mois %in% months, , drop = FALSE]
  if (!nrow(d)) stop("Aucune journée SAFRAN pour les mois demandés.", call. = FALSE)
  d$maille <- paste(d$LAMBX, d$LAMBY, sep = "_")
  # moyenne annuelle par maille, puis moyenne des annees (tapply : rapide sur 30 ans)
  ma <- tapply(d$T, list(d$maille, d$an), mean)
  data.frame(maille = rownames(ma), T = rowMeans(ma, na.rm = TRUE), stringsAsFactors = FALSE)
}

.check_alt_mailles <- function(alt_mailles) {
  if (!is.data.frame(alt_mailles) || !all(c("maille", "z_moy") %in% names(alt_mailles))) {
    stop("`alt_mailles` doit avoir les colonnes maille et z_moy (safran_cell_altitude()).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Altitude moyenne des mailles SAFRAN
#'
#' Pour chaque maille SAFRAN de 8 km (carré centré sur `LAMBX`, `LAMBY`, en Lambert II
#' étendu, EPSG:27572, reprojeté en Lambert-93), moyenne du MNT `dem` sur la maille et part
#' de la maille couverte par le MNT. SAFRAN analyse le climat à l'altitude moyenne de la
#' maille (Vidal et al. 2010, doi 10.1002/joc.2003, **à vérifier** sur le texte) : la
#' validation croisée de la mission 039 va dans ce sens (RMSE 0,11 °C avec la moyenne contre
#' 0,34 avec l'altitude du centre).
#'
#' @param safran `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).
#' @param dem `SpatRaster` d'altitude (m) en Lambert-93 (EPSG:2154), par exemple la
#'   BD ALTI à 250 m de [fetch_mnt_large()].
#' @return `data.frame` : `maille`, `LAMBX`, `LAMBY`, `x`, `y` (centre, Lambert-93,
#'   x = est, y = nord), `z_moy` (m, `NA` si la maille est hors du MNT), `couverture` (0 à 1).
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' dem <- terra::rast(xmin = min(m$x) - 6000, xmax = max(m$x) + 6000, ymin = min(m$y) - 6000,
#'                    ymax = max(m$y) + 6000, resolution = 250, crs = "EPSG:2154", vals = 400)
#' head(safran_cell_altitude(s, dem))
#' @export
safran_cell_altitude <- function(safran, dem) {
  if (!is.data.frame(safran) || !all(c("LAMBX", "LAMBY") %in% names(safran))) {
    stop("`safran` doit avoir les colonnes LAMBX et LAMBY.", call. = FALSE)
  }
  if (!inherits(dem, "SpatRaster")) stop("`dem` doit être un SpatRaster.", call. = FALSE)
  assert_crs_2154(dem)
  m <- .mailles_safran(.safran_norm(safran))
  sq <- lapply(seq_len(nrow(m)), function(i) {
    x <- m$LAMBX[i] * 100
    y <- m$LAMBY[i] * 100
    sf::st_polygon(list(cbind(c(x - 4000, x + 4000, x + 4000, x - 4000, x - 4000),
                              c(y - 4000, y - 4000, y + 4000, y + 4000, y - 4000))))
  })
  v <- terra::vect(sf::st_transform(sf::st_sfc(sq, crs = 27572), 2154))
  z <- terra::extract(dem[[1]], v, fun = mean, na.rm = TRUE)[, 2]
  cv <- terra::extract(dem[[1]], v, fun = function(x, ...) mean(!is.na(x)))[, 2]
  z[!is.finite(z)] <- NA_real_
  cv[!is.finite(cv)] <- 0
  data.frame(m, z_moy = z, couverture = cv, stringsAsFactors = FALSE)
}

#' Gradient altitudinal de la température entre les mailles SAFRAN
#'
#' Ajuste, sur les mailles SAFRAN de la SER, `T ~ z_moy + x + y` (T moyenne des moyennes
#' annuelles des jours de `months`, `z_moy` de [safran_cell_altitude()], x = est et
#' y = nord du centre en Lambert-93, km) et rend le coefficient de l'altitude. Sur la
#' GRECO D (mission 039) : −0,49 °C/100 m (R² 0,92) ; repère publié −0,55 °C/100 m
#' (Rolland 2003, **à vérifier** dans les Vosges). Choix de la mission 039 (arbitrage du
#' 2026-11-20) : pas de coefficient extérieur, le gradient est lu dans SAFRAN.
#'
#' @param safran `data.frame` SIM2 quotidien (colonnes `LAMBX`, `LAMBY`, `DATE`, `T`).
#' @param alt_mailles `data.frame` de [safran_cell_altitude()].
#' @param months Mois pris en compte (1:12 : température annuelle).
#' @param min_mailles Nombre minimal de mailles avec altitude.
#' @return Une liste : `gradient` (°C/m), `gradient_100m` (°C/100 m), `erreur_type_100m`,
#'   `r2`, `sigma` (°C), `n` (mailles), `months`, `formule`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' a <- data.frame(maille = m$maille, x = m$x, y = m$y, z_moy = seq(200, 900, length.out = nrow(m)))
#' safran_lapse_rate(s, a)$gradient_100m
#' @export
safran_lapse_rate <- function(safran, alt_mailles, months = 1:12, min_mailles = 6L) {
  .check_alt_mailles(alt_mailles)
  t <- .t_mailles(safran, months)
  m <- .mailles_safran(.safran_norm(safran))
  d <- data.frame(maille = m$maille, x = m$x / 1000, y = m$y / 1000)
  d$T <- t$T[match(d$maille, t$maille)]
  d$z <- alt_mailles$z_moy[match(d$maille, alt_mailles$maille)]
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) < min_mailles) {
    stop("Gradient altitudinal : ", nrow(d), " maille(s) avec T et altitude (minimum ",
         min_mailles, ").", call. = FALSE)
  }
  f <- stats::lm(T ~ z + x + y, data = d)
  sf_ <- suppressWarnings(summary(f))   # ajustement parfait (jeu fabrique) : sans objet
  cf <- sf_$coefficients
  if (!"z" %in% rownames(cf) || !is.finite(cf["z", 1])) {
    stop("Gradient altitudinal non estimable (altitudes sans variation).", call. = FALSE)
  }
  list(gradient = cf["z", 1], gradient_100m = 100 * cf["z", 1],
       erreur_type_100m = 100 * cf["z", 2], r2 = sf_$r.squared,
       sigma = sf_$sigma, n = nrow(d), months = months,
       formule = "T ~ z_moy + x + y (mailles SAFRAN de la SER, mission 039)")
}

#' Température corrigée du relief sur un MNT
#'
#' `T(cellule) = T_bilinéaire + G × (z − z_bilinéaire)` : `T_bilinéaire` interpole entre
#' les centres des mailles SAFRAN la T moyenne des mailles (jours de `months`),
#' `z_bilinéaire` interpole de même leur altitude moyenne (`alt_mailles`), `z` est
#' l'altitude de la cellule lue dans `dem`, `G` le gradient de [safran_lapse_rate()].
#' Les poids sont calculés par blocs de cellules, sous forme creuse (quatre mailles par
#' cellule) : la mémoire croît avec le nombre de cellules, non avec celui des mailles.
#'
#' **Règle des 700 m.** Sur le MNT fin de la grille, la couche rendue (`t_corr` par défaut)
#' est une **variable fine** (`FINE_VARIABLES`), jamais extraite aux placettes IFN. Pour
#' l'apprentissage, voir [coarse_t_corr_layer()] (moyenne dans 700 m).
#'
#' @param dem `SpatRaster` d'altitude (m), EPSG:2154.
#' @param safran `data.frame` SIM2 quotidien.
#' @param alt_mailles `data.frame` de [safran_cell_altitude()].
#' @param lapse Gradient (°C/m) ou liste de [safran_lapse_rate()].
#' @param months Mois de la température (1:12 : annuelle).
#' @param name Nom de la couche rendue.
#' @param chunk Nombre de cellules par bloc.
#' @return `SpatRaster` à une couche sur la grille de `dem`, attributs `gradient` (°C/m)
#'   et `months`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' a <- data.frame(maille = m$maille, z_moy = 400)
#' dem <- terra::rast(xmin = m$x[1] - 500, xmax = m$x[1] + 500, ymin = m$y[1] - 500,
#'                    ymax = m$y[1] + 500, resolution = 250, crs = "EPSG:2154", vals = 600)
#' terra::values(t_corrected(dem, s, a, -0.0055))[1:3]
#' @export
t_corrected <- function(dem, safran, alt_mailles, lapse, months = 1:12, name = "t_corr",
                        chunk = 500000L) {
  if (!inherits(dem, "SpatRaster")) stop("`dem` doit être un SpatRaster.", call. = FALSE)
  assert_crs_2154(dem)
  .check_alt_mailles(alt_mailles)
  G <- if (is.list(lapse)) lapse$gradient else lapse
  if (!is.numeric(G) || length(G) != 1L || !is.finite(G)) {
    stop("`lapse` doit être un gradient (°C/m) ou le résultat de safran_lapse_rate().",
         call. = FALSE)
  }
  mailles <- .mailles_safran(.safran_norm(safran))
  t <- .t_mailles(safran, months)
  tm <- t$T[match(mailles$maille, t$maille)]
  zm <- alt_mailles$z_moy[match(mailles$maille, alt_mailles$maille)]
  n <- terra::ncell(dem)
  z <- terra::values(dem[[1]], mat = FALSE)
  out <- rep(NA_real_, n)
  for (a in seq(1, n, by = chunk)) {
    i <- a:min(n, a + chunk - 1L)
    i <- i[!is.na(z[i])]
    if (!length(i)) next
    xy <- terra::xyFromCell(dem, i)          # x = est, y = nord
    P <- .safran_poids4(xy[, 1], xy[, 2], mailles)
    out[i] <- .interp4(P, tm) + G * (z[i] - .interp4(P, zm))
  }
  r <- terra::rast(dem[[1]])
  terra::values(r) <- out
  names(r) <- name
  attr(r, "gradient") <- G
  attr(r, "months") <- months
  r
}

#' Température corrigée moyennée dans 700 m (couche à maille large, apprentissage)
#'
#' [t_corrected()] sur un MNT d'au moins 250 m (BD ALTI), puis moyenne dans un disque de
#' `radius` m ([coarse_disk_mean()]) : couche `coarse_t_corr_700m`, prédicteur à maille large
#' permis aux placettes IFN (règle des 700 m). Sur l'emprise de la GRECO D (mission 039), la
#' moyenne dans 700 m porte 94 % de la variance de la T corrigée à 20 m (écart-type du résidu
#' 0,26 °C) : c'est le coût du changement d'échelle entre l'apprentissage et la carte.
#'
#' @inheritParams t_corrected
#' @param dem `SpatRaster` d'altitude, maille >= 250 m, EPSG:2154.
#' @param radius Rayon du disque (m, >= 700).
#' @return `SpatRaster` `coarse_t_corr_700m`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' dem <- terra::rast(xmin = m$x[1] - 2000, xmax = m$x[1] + 2000, ymin = m$y[1] - 2000,
#'                    ymax = m$y[1] + 2000, resolution = 250, crs = "EPSG:2154", vals = 600)
#' names(coarse_t_corr_layer(dem, s, data.frame(maille = m$maille, z_moy = 400), -0.0055))
#' @export
coarse_t_corr_layer <- function(dem, safran, alt_mailles, lapse, months = 1:12, radius = 700) {
  t <- t_corrected(dem, safran, alt_mailles, lapse, months = months, name = "t_corr_250")
  out <- coarse_disk_mean(t, radius = radius, name = "coarse_t_corr_700m")
  attr(out, "gradient") <- attr(t, "gradient")
  out
}

#' Variables climatiques des modèles régionaux
#'
#' Variables à maille large des modèles trophique et hydrique selon `config.yml` (mission 039) :
#' `climat_temperature` (`"corrigee"` : `coarse_t_corr_700m` ; `"bilineaire"` :
#' `coarse_t_moy`) pour l'hydrique et le bioclimat ; `trophique_climat` (`"actuel"` :
#' `coarse_p_etp_sv` et `coarse_t_moy`, état d'avant 039 ; `"corrige"` : `coarse_p_etp_sv` et
#' `coarse_t_corr_700m` ; `"sans"` : aucune). Défaut du pipeline : `"sans"` (climat retiré du
#' trophique, décision de Pascal du 2026-11-20) ; les deux autres variantes restent des options.
#'
#' @param temperature `"corrigee"` ou `"bilineaire"`.
#' @param trophique `"sans"` (défaut, décision de Pascal du 2026-11-20), `"actuel"` ou `"corrige"`.
#' @return Une liste : `t_var` (température du bioclimat et de l'hydrique), `trophic`,
#'   `hydric`, `toutes`.
#' @examples
#' model_climate_vars("corrigee", "actuel")
#' @export
model_climate_vars <- function(temperature = c("corrigee", "bilineaire"),
                               trophique = c("sans", "actuel", "corrige")) {
  temperature <- match.arg(temperature)
  trophique <- match.arg(trophique)
  t_var <- if (temperature == "corrigee") "coarse_t_corr_700m" else "coarse_t_moy"
  tro <- switch(trophique, actuel = c("coarse_p_etp_sv", "coarse_t_moy"),
                corrige = c("coarse_p_etp_sv", "coarse_t_corr_700m"), sans = character(0))
  hyd <- c("coarse_p_etp_sv", t_var)
  list(t_var = t_var, trophic = tro, hydric = hyd, toutes = unique(c(tro, hyd)))
}

#' Validation croisée de la correction de température (une maille laissée de côté)
#'
#' Pour chaque maille SAFRAN ayant au moins deux voisines directes (8 km au nord, au sud, à
#' l'est ou à l'ouest), sa T moyenne est prédite sans elle : `bilineaire` (moyenne des
#' voisines, la méthode d'avant 039 au centre d'une maille), `gradient_fixe` (voisines
#' ramenées à l'altitude de la maille par −0,55 °C/100 m, Rolland 2003, **à vérifier**),
#' `gradient_ser` (voisines ramenées par le gradient de [safran_lapse_rate()] réestimé sans
#' la maille). Erreur rendue par méthode, sur toutes les mailles et sur celles dont
#' l'altitude s'écarte de plus de 100 m de la moyenne de leurs voisines (« relief »). C'est
#' la comparaison qui justifie, dans le rapport, le choix du gradient lu dans SAFRAN plutôt
#' que meteoland (mesure de la mission 039 sur la GRECO D : 0,11 °C contre 0,23 en
#' bilinéaire et 0,12 pour meteoland).
#'
#' @inheritParams safran_lapse_rate
#' @param fixe Gradient fixe de comparaison (°C/m).
#' @return `data.frame` : `methode`, `n`, `rmse`, `biais`, `n_relief`, `rmse_relief` (°C).
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' a <- data.frame(maille = m$maille, z_moy = seq(200, 900, length.out = nrow(m)))
#' t_correction_validation(s, a)
#' @export
t_correction_validation <- function(safran, alt_mailles, months = 1:12, fixe = -0.0055) {
  .check_alt_mailles(alt_mailles)
  t <- .t_mailles(safran, months)
  m <- .mailles_safran(.safran_norm(safran))
  m$T <- t$T[match(m$maille, t$maille)]
  m$z <- alt_mailles$z_moy[match(m$maille, alt_mailles$maille)]
  m <- m[is.finite(m$T) & is.finite(m$z), , drop = FALSE]
  cle <- paste(m$LAMBX, m$LAMBY, sep = "_")
  P <- matrix(NA_real_, nrow(m), 3, dimnames = list(NULL, c("bilineaire", "gradient_fixe",
                                                           "gradient_ser")))
  dz <- rep(NA_real_, nrow(m))
  for (i in seq_len(nrow(m))) {
    k <- c(paste(m$LAMBX[i] + 80, m$LAMBY[i], sep = "_"), paste(m$LAMBX[i] - 80, m$LAMBY[i], sep = "_"),
           paste(m$LAMBX[i], m$LAMBY[i] + 80, sep = "_"), paste(m$LAMBX[i], m$LAMBY[i] - 80, sep = "_"))
    j <- match(k, cle)
    j <- j[!is.na(j)]
    if (length(j) < 2L) next
    g <- tryCatch(stats::coef(stats::lm(T ~ z + I(x / 1000) + I(y / 1000), data = m[-i, ]))[["z"]],
                  error = function(e) NA_real_)
    P[i, "bilineaire"] <- mean(m$T[j])
    P[i, "gradient_fixe"] <- mean(m$T[j] + fixe * (m$z[i] - m$z[j]))
    P[i, "gradient_ser"] <- mean(m$T[j] + g * (m$z[i] - m$z[j]))
    dz[i] <- m$z[i] - mean(m$z[j])
  }
  do.call(rbind, lapply(colnames(P), function(meth) {
    ok <- is.finite(P[, meth])
    e <- P[ok, meth] - m$T[ok]
    r <- abs(dz[ok]) > 100
    data.frame(methode = meth, n = sum(ok), rmse = if (any(ok)) sqrt(mean(e^2)) else NA_real_,
               biais = if (any(ok)) mean(e) else NA_real_, n_relief = sum(r),
               rmse_relief = if (any(r)) sqrt(mean(e[r]^2)) else NA_real_)
  }))
}
