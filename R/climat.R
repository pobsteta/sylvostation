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
.safran_poids <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  n <- length(x)
  W <- matrix(0, n, nrow(mailles), dimnames = list(NULL, mailles$maille))
  if (!n) return(W)
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
  for (cn in coins) {
    w <- (if (cn[1]) tx else 1 - tx) * (if (cn[2]) ty else 1 - ty)
    k <- paste(x0 + (i0 + cn[1]) * pas, y0 + (j0 + cn[2]) * pas, sep = "_")
    j <- match(k, cle)
    ok <- !is.na(j) & w > 0
    W[cbind(which(ok), j[ok])] <- W[cbind(which(ok), j[ok])] + w[ok]
  }
  # poids residuels d'arrondi (centre d'une maille : 1 et 1e-14) ramenes a 0
  W[W < 1e-9] <- 0
  s <- rowSums(W)
  proche <- .maille_proche_vec(x, y, mailles, dmax)
  hors <- is.na(proche) | s <= 0
  W[!hors, ] <- W[!hors, , drop = FALSE] / s[!hors]
  W[hors, ] <- NA_real_
  W
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
