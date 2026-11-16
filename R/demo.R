# Jeux d'essai SYNTHETIQUES du pipeline en mode demo (mission 010).
# Tout ce qui sort d'ici est fabrique : colonne ou balise `synthetic = TRUE`, jamais
# presente comme un resultat sur donnees reelles (ADR 0003). Aucun reseau.
# Ces fonctions servent `_targets.R` (demo: true) et les tests ; elles ne touchent pas
# a la graine globale.

.with_seed <- function(seed, expr) {
  has_seed <- exists(".Random.seed", envir = globalenv())
  old <- if (has_seed) get(".Random.seed", envir = globalenv())
  on.exit(if (has_seed) assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  set.seed(seed)
  force(expr)
}

# Champ aleatoire lisse (grille grossiere reechantillonnee en spline cubique) sur `grid`.
.smooth_field <- function(grid, n = 6L) {
  g <- terra::rast(terra::ext(grid), nrows = n, ncols = n, crs = "EPSG:2154")
  terra::values(g) <- stats::rnorm(n * n)
  terra::resample(g, terra::rast(grid, nlyrs = 1), method = "cubicspline")
}

.tag_synthetic <- function(r) {
  terra::metags(r) <- c(synthetic = "TRUE")
  r
}

#' MNT synthétique du mode démo
#'
#' Prend le plan incliné de `inst/extdata/synth_dtm.tif` (surface analytique
#' synthétique de 240 x 240 cellules de 25 m), en découpe autant de cellules que
#' `grid`, replace le résultat **sur l'emprise de `grid`** (pour que la démo se situe
#' sur le massif test) et y ajoute un relief lisse aléatoire (écart-type 40 m) pour que
#' pente, TWI et TPI varient. **Entièrement synthétique** : balise `synthetic = TRUE`.
#'
#' @param grid `SpatRaster` vide en EPSG:2154 (voir [build_grid()]), de 25 m, pas plus
#'   de 240 x 240 cellules.
#' @param seed Graine du relief aléatoire.
#' @return Un `SpatRaster` à une couche `z` (mètres) sur la grille de `grid`.
#' @examples
#' g <- build_grid(c(xmin = 1007000, ymin = 6790000, xmax = 1008000, ymax = 6791000), 25)
#' terra::res(synth_demo_dtm(g))
#' @export
synth_demo_dtm <- function(grid, seed = 1L) {
  if (!inherits(grid, "SpatRaster")) stop("`grid` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(grid)
  f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
  if (!nzchar(f)) stop("synth_dtm.tif introuvable dans inst/extdata.", call. = FALSE)
  base <- terra::rast(f)
  if (any(abs(terra::res(grid) - terra::res(base)) > 1e-6)) {
    stop("`grid` doit avoir la m\u00eame maille que synth_dtm.tif (", terra::res(base)[1], " m).",
         call. = FALSE)
  }
  if (terra::nrow(grid) > terra::nrow(base) || terra::ncol(grid) > terra::ncol(base)) {
    stop("`grid` d\u00e9passe la taille de synth_dtm.tif (", terra::nrow(base), " x ",
         terra::ncol(base), " cellules).", call. = FALSE)
  }
  e <- terra::ext(base)
  res <- terra::res(base)[1]
  sous <- terra::crop(base, terra::ext(e[1], e[1] + terra::ncol(grid) * res,
                                       e[4] - terra::nrow(grid) * res, e[4]))
  terra::ext(sous) <- terra::ext(grid)  # x = est, y = nord, Lambert-93
  z <- .with_seed(seed, .smooth_field(grid)) * 40 + sous
  names(z) <- "z"
  .tag_synthetic(z)
}

#' Climat synthétique à maille de 1 km pour le mode démo
#'
#' Trois couches nommées selon la convention de [compute_gradients()] : `p_sv`
#' (précipitations de la saison de végétation, mm), `etp_sv` (mm) et `t_moy` (°C), à
#' maille de 1 000 m sur l'emprise, gradient régulier plus un bruit lisse. **Valeurs
#' fabriquées**, sans lien avec le climat réel.
#'
#' @param emprise Vecteur `c(xmin, ymin, xmax, ymax)` en EPSG:2154 (x = est, y = nord).
#' @param res Maille en mètres (1 000 par défaut).
#' @param seed Graine.
#' @return Un `SpatRaster` de trois couches, balisé `synthetic`.
#' @examples
#' terra::nlyr(synth_demo_climat(c(1007000, 6790000, 1022000, 6805000)))
#' @export
synth_demo_climat <- function(emprise, res = 1000, seed = 2L) {
  g <- build_grid(emprise, res)
  .with_seed(seed, {
    xy <- terra::xyFromCell(g, seq_len(terra::ncell(g)))  # x = est, y = nord
    ux <- (xy[, 1] - min(xy[, 1])) / max(1, diff(range(xy[, 1])))
    uy <- (xy[, 2] - min(xy[, 2])) / max(1, diff(range(xy[, 2])))
    mk <- function(v, nom) {
      r <- terra::rast(g)
      terra::values(r) <- v
      names(r) <- nom
      r
    }
    n <- length(ux)
    out <- c(mk(900 + 300 * ux + stats::rnorm(n, sd = 20), "p_sv"),
             mk(430 + 40 * uy + stats::rnorm(n, sd = 5), "etp_sv"),
             mk(9 - 2 * uy + stats::rnorm(n, sd = 0.3), "t_moy"))
  })
  .tag_synthetic(out)
}

#' Pile de prédicteurs du mode démo
#'
#' Assemble, sur la grille du MNT, les couches fines de [derive_terrain()] (pente,
#' TWI, TPI, `mnt`) et les couches **à maille large** du climat (`coarse_p_etp_sv` =
#' P - ETP, `coarse_t_moy`), ces dernières ré-échantillonnées de 1 km à la grille par
#' interpolation bilinéaire. Les noms `coarse_` signalent les couches autorisées aux
#' placettes IFN ([assert_no_fine_extract_on_ifn()]).
#'
#' @param terrain `SpatRaster` de [derive_terrain()].
#' @param dtm `SpatRaster` du MNT (même grille que `terrain`).
#' @param climat `SpatRaster` de [synth_demo_climat()] (`p_sv`, `etp_sv`, `t_moy`).
#' @return Un `SpatRaster` : `mnt`, `pente`, `twi`, `tpi_100`, `tpi_300` si présents,
#'   `coarse_p_etp_sv`, `coarse_t_moy`.
#' @examples
#' \dontrun{
#' demo_predictors(derive_terrain(dtm), dtm, climat)
#' }
#' @export
demo_predictors <- function(terrain, dtm, climat) {
  assert_crs_2154(terrain)
  assert_crs_2154(climat)
  requis <- c("p_sv", "etp_sv", "t_moy")
  if (!all(requis %in% names(climat))) {
    stop("`climat` doit avoir les couches : ", paste(requis, collapse = ", "), ".", call. = FALSE)
  }
  fines <- terrain[[intersect(c("pente", "twi", "tpi_100", "tpi_300"), names(terrain))]]
  mnt <- dtm
  names(mnt) <- "mnt"
  cl <- c(climat[["p_sv"]] - climat[["etp_sv"]], climat[["t_moy"]])
  names(cl) <- c("coarse_p_etp_sv", "coarse_t_moy")
  cl <- terra::resample(terra::crop(cl, terra::ext(terrain) + 2000), terrain[[1]],
                        method = "bilinear")
  out <- c(mnt, fines, cl)
  if (any(is.na(terra::global(cl, "sum")[, 1]))) {
    stop("Le climat ne couvre pas la grille.", call. = FALSE)
  }
  .tag_synthetic(out)
}

#' Gradients « vrais » synthétiques du mode démo
#'
#' Fonctions **fabriquées** des prédicteurs, qui servent de vérité aux jeux
#' synthétiques : `trophic` (climat, pente, TPI), `hydric` (TWI, pente, TPI),
#' `bioclim` (altitude, température). Chaque terme est centré-réduit sur la grille.
#' Rien de cela n'est une loi écologique.
#'
#' @param predictors `SpatRaster` de [demo_predictors()].
#' @return Un `SpatRaster` à trois couches : `trophic`, `hydric`, `bioclim`.
#' @examples
#' \dontrun{
#' synth_demo_truth(predictors)
#' }
#' @export
synth_demo_truth <- function(predictors) {
  need <- c("mnt", "pente", "twi", "tpi_300", "coarse_p_etp_sv", "coarse_t_moy")
  if (!all(need %in% names(predictors))) {
    stop("Couches absentes : ", paste(setdiff(need, names(predictors)), collapse = ", "), ".",
         call. = FALSE)
  }
  z <- function(nm) {
    r <- predictors[[nm]]
    m <- terra::global(r, "mean", na.rm = TRUE)[1, 1]
    s <- terra::global(r, "sd", na.rm = TRUE)[1, 1]
    (r - m) / (if (is.finite(s) && s > 0) s else 1)
  }
  out <- c(0.7 * z("coarse_p_etp_sv") - 0.5 * z("pente") + 0.4 * z("tpi_300"),
           0.8 * z("twi") - 0.4 * z("pente") - 0.3 * z("tpi_300"),
           -0.9 * z("mnt") + 0.3 * z("coarse_t_moy"))
  names(out) <- c("trophic", "hydric", "bioclim")
  .tag_synthetic(out)
}

#' Points synthétiques (ancrage ou relevés « GNSS ») du mode démo
#'
#' Tire `n` points au hasard dans l'emprise des prédicteurs (moins une marge de 350 m), y lit les prédicteurs et
#' les gradients vrais ([synth_demo_truth()]) bruités, et fabrique des observables de
#' terrain (`pente_obs`, `humus`, `position`). Les points portent `loc_precision_m =
#' 10` (points précis : l'extraction fine y est permise) et `synthetic = TRUE`.
#' **La règle bloquante est appliquée** : [assert_no_fine_extract_on_ifn()] est appelée
#' avant l'extraction. Remplace, en démo, les points d'ancrage GBIF (mission 007, non
#' intégrée) et les relevés GNSS (absents).
#'
#' @param predictors `SpatRaster` de [demo_predictors()].
#' @param truth `SpatRaster` de [synth_demo_truth()].
#' @param n Nombre de points.
#' @param noise_sd Écart-type du bruit ajouté aux gradients.
#' @param seed Graine.
#' @param loc_precision_m Précision de localisation (m) posée sur les points.
#' @return Un `sf` de points en EPSG:2154 : `x`, `y`, prédicteurs, gradients,
#'   observables, `loc_precision_m`, `synthetic`.
#' @examples
#' \dontrun{
#' synth_demo_points(predictors, truth, n = 50)
#' }
#' @export
synth_demo_points <- function(predictors, truth, n = 300L, noise_sd = 0.25, seed = 11L,
                              loc_precision_m = 10) {
  assert_crs_2154(predictors)
  pts0 <- data.frame(loc_precision_m = loc_precision_m)
  assert_no_fine_extract_on_ifn(pts0, names(predictors))  # regle bloquante, en premier
  .with_seed(seed, {
    e <- terra::ext(predictors)
    m <- 350  # marge : les TPI de rayon 300 m sont NA sur le pourtour
    d <- data.frame(x = stats::runif(n, e[1] + m, e[2] - m),   # x = est
                    y = stats::runif(n, e[3] + m, e[4] - m))   # y = nord
    v <- terra::extract(c(predictors, truth), as.matrix(d[, c("x", "y")]))
    d <- cbind(d, v)
    d <- d[stats::complete.cases(d), , drop = FALSE]
    n <- nrow(d)
    for (g in names(truth)) d[[g]] <- d[[g]] + stats::rnorm(n, sd = noise_sd)
    d$pente_obs <- d$pente + stats::rnorm(n, sd = 2)
    d$humus <- factor(ifelse(d$trophic + stats::rnorm(n, sd = 0.4) > 0, "mull", "moder"))
    d$position <- cut(d$tpi_300, c(-Inf, stats::quantile(d$tpi_300, c(1/3, 2/3)), Inf),
                      labels = c("fond", "versant", "crete"))
  })
  d$loc_precision_m <- loc_precision_m
  d$synthetic <- TRUE
  sf::st_as_sf(d, coords = c("x", "y"), crs = 2154, remove = FALSE)
}

#' Flore et arbres synthétiques par type (mode démo)
#'
#' Fabrique, pour des points déjà typés, une matrice de présence de 12 espèces
#' fictives (`sp1` à `sp12`, trois par groupe de types : probabilité 0,8 dans leur
#' groupe, 0,1 ailleurs) et un tableau d'arbres (essence fictive `essence_a`) dont la
#' hauteur dépend de l'âge et d'un effet de type. **Aucun lien avec de vraies
#' espèces.**
#'
#' @param types Vecteur de types (un par point ; `NA` permis).
#' @param seed Graine.
#' @return Une liste : `flore` (matrice 0/1), `arbres` (`plot`, `species`, `age`,
#'   `height`, `synthetic`), `plot_types` (`plot`, `type`).
#' @examples
#' b <- synth_demo_biotic(rep(c("T1-H1-B1", "T2-H1-B1"), 30))
#' dim(b$flore)
#' @export
synth_demo_biotic <- function(types, seed = 5L) {
  .with_seed(seed, {
    n <- length(types)
    nv <- as.integer(factor(types))
    nv[is.na(nv)] <- 1L
    K <- max(nv)
    fl <- matrix(0L, n, 12, dimnames = list(NULL, paste0("sp", 1:12)))
    for (j in 1:12) {
      cible <- ((j - 1L) %/% 3L) %% K + 1L
      fl[, j] <- stats::rbinom(n, 1, ifelse(nv == cible, 0.8, 0.1))
    }
    age <- stats::runif(n, 30, 120)
    eff <- (nv - mean(nv)) * 1.5
    arb <- data.frame(plot = rep(seq_len(n), each = 4), species = "essence_a")
    arb$age <- rep(age, each = 4) + stats::rnorm(4 * n, sd = 2)
    arb$height <- 8 * log(rep(age, each = 4)) - 10 + rep(eff, each = 4) +
      stats::rnorm(4 * n, sd = 0.4)
    arb$synthetic <- TRUE
  })
  list(flore = fl, arbres = arb, plot_types = data.frame(plot = seq_len(n), type = types))
}

#' Carte de référence synthétique (trois gradients à 50 m)
#'
#' Agrège les gradients vrais ([synth_demo_truth()]) à `res` mètres et y ajoute un
#' bruit, pour fabriquer un **substitut** de la carte de référence de Gégout et
#' al. (2008), dont les rasters (AgroParisTech) manquent. C'est l'origine de
#' `inst/extdata/synth_reference.tif` (script `inst/scripts/synth_reference.R`).
#'
#' @param truth `SpatRaster` de [synth_demo_truth()].
#' @param res Maille de la référence en mètres (50, comme la carte publiée).
#' @param noise_sd Bruit ajouté.
#' @param seed Graine.
#' @return Un `SpatRaster` `trophic`, `hydric`, `bioclim`, balisé `synthetic`.
#' @examples
#' \dontrun{
#' synth_demo_reference(truth)
#' }
#' @export
synth_demo_reference <- function(truth, res = 50, noise_sd = 0.3, seed = 3L) {
  r0 <- terra::res(truth)[1]
  f <- res / r0
  if (abs(f - round(f)) > 1e-6 || f < 1) {
    stop("`res` doit \u00eatre un multiple entier de la maille de `truth`.", call. = FALSE)
  }
  a <- if (round(f) > 1) terra::aggregate(truth, fact = round(f), fun = "mean") else truth
  .with_seed(seed, {
    terra::values(a) <- terra::values(a) +
      matrix(stats::rnorm(terra::ncell(a) * terra::nlyr(a), sd = noise_sd), ncol = terra::nlyr(a))
  })
  .tag_synthetic(a)
}
