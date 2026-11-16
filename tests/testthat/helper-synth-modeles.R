# Jeu synthétique (synthetic = TRUE) à relation connue et autocorrélée, pour la
# mission 008. Zone fictive de 20 km x 20 km en Lambert-93 (x = est, y = nord).
# Réponse = 1.5 * coarse_climat + sin(pente) + champ caché autocorrélé + bruit.
# Le champ caché (non fourni comme prédicteur) crée l'autocorrélation du résidu.
synth_modeles <- function(n = 250, seed = 42) {
  has_seed <- exists(".Random.seed", envir = globalenv())
  old <- if (has_seed) get(".Random.seed", envir = globalenv())
  on.exit(if (has_seed) assign(".Random.seed", old, envir = globalenv()))
  set.seed(seed)
  ext <- terra::ext(1000000, 1020000, 6780000, 6800000)
  champ <- function(nm) {
    g <- terra::rast(ext, nrows = 6, ncols = 6, crs = "EPSG:2154")
    terra::values(g) <- stats::rnorm(36)
    f <- terra::rast(ext, nrows = 40, ncols = 40, crs = "EPSG:2154")
    r <- terra::resample(g, f, method = "cubicspline")
    names(r) <- nm
    r
  }
  pile <- c(champ("coarse_climat"), champ("pente"), champ("twi"), champ("cache"))
  xy <- cbind(x = stats::runif(n, 1000000, 1020000), y = stats::runif(n, 6780000, 6800000))
  v <- terra::extract(pile, xy)
  d <- data.frame(xy, v)
  d$gradient <- 1.5 * d$coarse_climat + sin(d$pente) + 1.0 * d$cache +
    stats::rnorm(n, sd = 0.2)
  d$cache <- NULL
  d$loc_precision_m <- 10
  d$synthetic <- TRUE
  pts <- sf::st_as_sf(d, coords = c("x", "y"), crs = 2154, remove = FALSE)
  list(points = pts, rasters = pile[[c("coarse_climat", "pente", "twi")]])
}
