# Modèles de gradients et validation croisée spatiale (mission 008).
# Aucun réseau, aucun effet de bord : tout est renvoyé en valeur.

utils::globalVariables(".poids")

.coords_xy <- function(data) {
  if (inherits(data, "sf")) {
    assert_crs_2154(data)
    if (any(!as.character(sf::st_geometry_type(data)) %in% "POINT")) {
      stop("`data` doit contenir des points.", call. = FALSE)
    }
    m <- sf::st_coordinates(data)
    return(cbind(x = unname(m[, 1]), y = unname(m[, 2])))
  }
  if (is.data.frame(data) && all(c("x", "y") %in% names(data))) {
    # x = est, y = nord, supposés en Lambert-93 (EPSG:2154), non vérifiable ici.
    return(cbind(x = as.numeric(data$x), y = as.numeric(data$y)))
  }
  stop("`data` doit \u00eatre un objet sf (EPSG:2154) ou un tableau avec colonnes x (est) et y (nord).",
       call. = FALSE)
}

.drop_geom <- function(data) {
  if (inherits(data, "sf")) data <- sf::st_drop_geometry(data)
  as.data.frame(data)
}

.gam_formula <- function(response, predictors, train) {
  termes <- vapply(predictors, function(v) {
    x <- train[[v]]
    nu <- length(unique(x))
    if (is.numeric(x) && nu >= 6L) sprintf("s(%s, k = %d)", v, min(6L, nu - 1L)) else v
  }, character(1))
  stats::as.formula(paste(response, "~", paste(termes, collapse = " + ")))
}

#' Ajuster le modèle d'un gradient (forêt aléatoire ou GAM)
#'
#' Ajuste un gradient (par exemple un indice d'humidité ou de fertilité) sur des
#' prédicteurs. **Appelle d'abord [assert_no_fine_extract_on_ifn()]** : des
#' prédicteurs fins sont refusés si les points sont des placettes IFN ou si leur
#' précision de localisation (`loc_precision_m`) est absente ou supérieure à 25 m.
#'
#' @param data Objet `sf` de points en EPSG:2154 (ou tableau avec colonnes `x`, `y`),
#'   portant la réponse, les prédicteurs et `loc_precision_m`.
#' @param response Nom de la colonne réponse (numérique).
#' @param predictors Noms des colonnes prédictrices.
#' @param method `"ranger"` (forêt aléatoire, écart-type par quantiles) ou `"gam"`
#'   (mgcv, erreur-type du modèle).
#' @param weights Poids des observations (`NULL` ou vecteur de la longueur de `data`).
#' @param points_source `NULL` (on se fie à `data`) ou `"ifn"` : les points sont alors
#'   marqués par [mark_ifn()] avant la règle bloquante.
#' @param num_trees Nombre d'arbres de la forêt (200 par défaut).
#' @param seed Graine du générateur (`NULL` : pas de graine).
#' @return Un objet de classe `sylvo_gradient` (liste).
#' @examples
#' set.seed(1)
#' d <- data.frame(x = 1:40, y = 1, loc_precision_m = 10, coarse_a = rnorm(40))
#' d$g <- d$coarse_a + rnorm(40, sd = 0.1)
#' if (requireNamespace("ranger", quietly = TRUE)) {
#'   m <- fit_gradient(d, "g", "coarse_a", num_trees = 50)
#'   class(m)
#' }
#' @export
fit_gradient <- function(data, response, predictors, method = c("ranger", "gam"),
                         weights = NULL, points_source = NULL, num_trees = 200L,
                         seed = NULL) {
  method <- match.arg(method)
  if (!is.null(points_source)) {
    if (!identical(points_source, "ifn")) {
      stop("`points_source` doit \u00eatre NULL ou \"ifn\".", call. = FALSE)
    }
    data <- mark_ifn(data)
  }
  # Règle bloquante : avant toute autre chose.
  assert_no_fine_extract_on_ifn(data, predictors)
  if (method == "ranger" && !requireNamespace("ranger", quietly = TRUE)) {
    stop("Le paquet 'ranger' est requis pour method = \"ranger\".", call. = FALSE)
  }
  if (method == "gam" && !requireNamespace("mgcv", quietly = TRUE)) {
    stop("Le paquet 'mgcv' est requis pour method = \"gam\".", call. = FALSE)
  }
  df <- .drop_geom(data)
  manq <- setdiff(c(response, predictors), names(df))
  if (length(manq)) stop("Colonnes absentes : ", paste(manq, collapse = ", "), ".", call. = FALSE)
  if (!is.numeric(df[[response]])) stop("La r\u00e9ponse doit \u00eatre num\u00e9rique.", call. = FALSE)
  if (!is.null(weights) && length(weights) != nrow(df)) {
    stop("`weights` doit avoir la longueur de `data`.", call. = FALSE)
  }
  w <- if (is.null(weights)) rep(1, nrow(df)) else as.numeric(weights)
  ok <- stats::complete.cases(df[, c(response, predictors), drop = FALSE]) & !is.na(w)
  if (any(!ok)) {
    warning(sum(!ok), " ligne(s) avec NA \u00e9cart\u00e9e(s) de l'ajustement.", call. = FALSE)
  }
  train <- df[ok, c(response, predictors), drop = FALSE]
  w <- w[ok]
  if (nrow(train) < 20L) stop("Moins de 20 observations compl\u00e8tes.", call. = FALSE)

  if (method == "ranger") {
    fit <- ranger::ranger(
      x = train[, predictors, drop = FALSE], y = train[[response]],
      num.trees = num_trees, quantreg = TRUE, importance = "impurity",
      case.weights = w, seed = seed, num.threads = 1L
    )
    imp <- fit$variable.importance[predictors]
    imp[!is.finite(imp) | imp < 0] <- 0
    weight_var <- if (sum(imp) > 0) imp / sum(imp) else
      stats::setNames(rep(1 / length(predictors), length(predictors)), predictors)
  } else {
    tr <- train
    tr$.poids <- w
    fit <- mgcv::gam(.gam_formula(response, predictors, train), data = tr,
                     weights = .poids, method = "REML", select = TRUE)
    weight_var <- stats::setNames(rep(1 / length(predictors), length(predictors)), predictors)
  }
  structure(list(
    fit = fit, method = method, response = response, predictors = predictors,
    train = train[, predictors, drop = FALSE], weight_var = weight_var,
    n = nrow(train), points_source = points_source,
    synthetic = isTRUE(any(as.logical(df[["synthetic"]])))
  ), class = "sylvo_gradient")
}

#' @export
print.sylvo_gradient <- function(x, ...) {
  cat("<sylvo_gradient> ", x$method, " ; r\u00e9ponse : ", x$response, " ; n = ", x$n,
      " ; pr\u00e9dicteurs : ", paste(x$predictors, collapse = ", "),
      if (x$synthetic) " [DONN\u00c9ES SYNTH\u00c9TIQUES]" else "", "\n", sep = "")
  invisible(x)
}

# Prédiction + écart-type pour un data.frame de prédicteurs.
.predict_df <- function(model, newdata) {
  nd <- newdata[, model$predictors, drop = FALSE]
  if (model$method == "ranger") {
    q <- stats::predict(model$fit, data = nd, type = "quantiles",
                        quantiles = c(0.1587, 0.8413), num.threads = 1L)$predictions
    m <- stats::predict(model$fit, data = nd, num.threads = 1L)$predictions
    data.frame(pred = as.numeric(m), sd = as.numeric((q[, 2] - q[, 1]) / 2))
  } else {
    p <- stats::predict(model$fit, newdata = nd, se.fit = TRUE)
    data.frame(pred = as.numeric(p$fit), sd = as.numeric(p$se.fit))
  }
}

# Portée de l'autocorrélation : première distance où le semi-variogramme empirique
# atteint 95 % de la variance (palier). NA si non atteinte.
.estimate_range <- function(xy, z, n_bins = 15L) {
  ok <- is.finite(z)
  xy <- xy[ok, , drop = FALSE]
  z <- z[ok]
  if (length(z) < 20L) return(NA_real_)
  if (length(z) > 600L) {
    i <- round(seq(1, length(z), length.out = 600L))
    xy <- xy[i, , drop = FALSE]
    z <- z[i]
  }
  d <- as.matrix(stats::dist(xy))
  g <- outer(z, z, function(a, b) 0.5 * (a - b)^2)
  up <- upper.tri(d)
  d <- d[up]
  g <- g[up]
  br <- seq(0, max(d) / 2, length.out = n_bins + 1L)
  sv <- tapply(g, cut(d, br, include.lowest = TRUE), mean)
  h <- (br[-1] + br[-length(br)]) / 2
  hit <- which(sv >= 0.95 * stats::var(z))
  if (!length(hit)) NA_real_ else h[hit[1]]
}

# Blocs carrés affectés aux plis (équilibrés en effectifs, ordre aléatoire
# reproductible, sans toucher à la graine globale).
.block_folds <- function(xy, block_size, k, seed = 1L) {
  id <- paste(floor(xy[, 1] / block_size), floor(xy[, 2] / block_size))
  tab <- table(id)
  if (length(tab) < k) {
    stop("Moins de blocs (", length(tab), ") que de plis (", k,
         ") : r\u00e9duire `block_size` ou `k`.", call. = FALSE)
  }
  has_seed <- exists(".Random.seed", envir = globalenv())
  old <- if (has_seed) get(".Random.seed", envir = globalenv())
  on.exit(if (has_seed) assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  set.seed(seed)
  ord <- names(tab)[order(-as.integer(tab), stats::runif(length(tab)))]
  charge <- numeric(k)
  pli_bloc <- stats::setNames(integer(length(ord)), ord)
  for (b in ord) {
    f <- which.min(charge)
    pli_bloc[b] <- f
    charge[f] <- charge[f] + tab[[b]]
  }
  as.integer(pli_bloc[id])
}

.r2 <- function(obs, pred) {
  ok <- is.finite(obs) & is.finite(pred)
  1 - sum((obs[ok] - pred[ok])^2) / sum((obs[ok] - mean(obs[ok]))^2)
}

.rmse <- function(obs, pred) {
  ok <- is.finite(obs) & is.finite(pred)
  sqrt(mean((obs[ok] - pred[ok])^2))
}

#' Validation croisée spatiale par blocs
#'
#' Découpe l'espace en blocs carrés (Lambert-93, mètres) affectés à `k` plis ; tous
#' les points d'un bloc sont dans le même pli, ce qui limite la fuite par
#' autocorrélation. **Pas de tirage aléatoire simple par défaut.** Taille de bloc par
#' défaut : portée de l'autocorrélation de la réponse (semi-variogramme empirique,
#' 95 % du palier), à défaut 5 000 m (valeur provisoire, mission 008). Les blocs sont
#' faits maison (aucune dépendance) ; blockCV n'est pas utilisé.
#'
#' @inheritParams fit_gradient
#' @param block_size Taille des blocs en mètres (`NULL` : estimée, sinon 5 000).
#' @param k Nombre de plis (5 par défaut).
#' @param folds Identifiants de plis fournis par l'utilisateur (diagnostic, par
#'   exemple un tirage aléatoire pour mesurer l'optimisme d'une CV non spatiale) ;
#'   `NULL` : blocs spatiaux.
#' @param ... Transmis à [fit_gradient()] (`num_trees`, `seed`, `points_source`).
#' @return Une liste : `par_pli` (pli, n, r2, rmse), `global` (r2, rmse sur toutes les
#'   prédictions hors pli), `predictions`, `block_size`, `k`, `plis`.
#'   R² = 1 - SCR/SCT par rapport à la moyenne observée ; il peut être négatif.
#' @examples
#' set.seed(1)
#' d <- data.frame(x = runif(120, 0, 20000), y = runif(120, 0, 20000) + 6e6,
#'                 loc_precision_m = 10, coarse_a = rnorm(120))
#' d$g <- d$coarse_a + rnorm(120, sd = 0.3)
#' if (requireNamespace("mgcv", quietly = TRUE)) {
#'   spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 5000)$global
#' }
#' @export
spatial_cv <- function(data, response, predictors, method = c("ranger", "gam"),
                       block_size = NULL, k = 5L, weights = NULL, folds = NULL, ...) {
  method <- match.arg(method)
  xy <- .coords_xy(data)
  df <- .drop_geom(data)
  if (!response %in% names(df)) stop("R\u00e9ponse absente de `data`.", call. = FALSE)
  if (is.null(block_size)) {
    r <- .estimate_range(xy, df[[response]])
    block_size <- if (is.finite(r) && r > 0) r else 5000
  }
  if (!is.numeric(block_size) || length(block_size) != 1L || block_size <= 0) {
    stop("`block_size` doit \u00eatre un nombre positif (m\u00e8tres).", call. = FALSE)
  }
  if (is.null(folds)) {
    folds <- .block_folds(xy, block_size, k)
  } else if (length(folds) != nrow(df)) {
    stop("`folds` doit avoir la longueur de `data`.", call. = FALSE)
  }
  ids <- sort(unique(folds))
  if (length(ids) < 2L) stop("Au moins deux plis sont n\u00e9cessaires.", call. = FALSE)
  pred <- rep(NA_real_, nrow(df))
  met <- lapply(ids, function(f) {
    te <- which(folds == f)
    tr <- which(folds != f)
    m <- fit_gradient(data[tr, , drop = FALSE], response, predictors, method = method,
                      weights = if (is.null(weights)) NULL else weights[tr], ...)
    p <- .predict_df(m, df[te, , drop = FALSE])$pred
    pred[te] <<- p
    obs <- df[[response]][te]
    c(pli = f, n = length(te), r2 = .r2(obs, p), rmse = .rmse(obs, p))
  })
  obs <- df[[response]]
  list(
    par_pli = as.data.frame(do.call(rbind, met)),
    global = c(r2 = .r2(obs, pred), rmse = .rmse(obs, pred)),
    predictions = data.frame(observe = obs, predit = pred, pli = folds),
    block_size = block_size, k = length(ids), plis = folds
  )
}

# Zone d'applicabilité maison (indice de dissimilarité de Meyer & Pebesma, simplifié) :
# distance au plus proche point d'apprentissage dans l'espace des prédicteurs
# centrés-réduits et pondérés, divisée par la distance moyenne entre points
# d'apprentissage ; seuil = borne haute des moustaches des DI d'apprentissage.
.aoa_fallback <- function(train, new, weight) {
  v <- names(train)
  mu <- vapply(train, mean, 0)
  s <- vapply(train, stats::sd, 0)
  s[s == 0] <- 1
  sc <- function(d) sweep(sweep(as.matrix(d[, v, drop = FALSE]), 2, mu), 2, s, "/")
  W <- sqrt(weight[v])
  A <- sweep(sc(train), 2, W, "*")
  B <- sweep(sc(new), 2, W, "*")
  dmin <- function(P, Q, self = FALSE) {
    out <- numeric(nrow(P))
    q2 <- rowSums(Q^2)
    for (i0 in seq(1, nrow(P), by = 2000L)) {
      i <- i0:min(nrow(P), i0 + 1999L)
      Pi <- P[i, , drop = FALSE]
      m <- outer(rowSums(Pi^2), q2, "+") - 2 * Pi %*% t(Q)
      if (self) m[cbind(seq_along(i), i)] <- Inf
      out[i] <- sqrt(pmax(apply(m, 1, min), 0))
    }
    out
  }
  idx <- if (nrow(A) > 500L) round(seq(1, nrow(A), length.out = 500L)) else seq_len(nrow(A))
  dbar <- mean(stats::dist(A[idx, , drop = FALSE]))
  thr <- grDevices::boxplot.stats(dmin(A, A, self = TRUE) / dbar)$stats[5]
  di <- rep(NA_real_, nrow(B))
  ok <- stats::complete.cases(B)
  di[ok] <- dmin(B[ok, , drop = FALSE], A) / dbar
  list(DI = di, AOA = as.integer(di <= thr), threshold = thr)
}

#' Prédire un gradient sur un raster, avec incertitude et zone d'applicabilité
#'
#' @param model Objet de [fit_gradient()].
#' @param predictors `SpatRaster` en EPSG:2154 dont les couches portent (au moins) les
#'   noms des prédicteurs du modèle.
#' @param aoa Calculer la zone d'applicabilité ? Utilise `CAST::aoa()` si CAST est
#'   installé, sinon un calcul maison équivalent simplifié (même principe : indice de
#'   dissimilarité, seuil des moustaches ; sans validation croisée des DI).
#' @param use_cast `FALSE` pour forcer le repli maison même si CAST est installé.
#' @return Un `SpatRaster` avec les couches `pred`, `sd` (écart-type : quantiles
#'   de la forêt ou erreur-type du GAM, **pas** l'erreur de validation croisée),
#'   et si `aoa` : `di` et `aoa` (1 = dans la zone d'applicabilité, 0 = hors zone : à
#'   ne pas interpréter). Une balise `synthetic` est posée (`terra::metags`) si le
#'   modèle vient de données synthétiques.
#' @examples
#' \dontrun{
#' r <- predict_raster(modele, pile_predicteurs)
#' }
#' @export
predict_raster <- function(model, predictors, aoa = TRUE, use_cast = TRUE) {
  if (!inherits(model, "sylvo_gradient")) {
    stop("`model` doit venir de fit_gradient().", call. = FALSE)
  }
  if (!inherits(predictors, "SpatRaster")) stop("`predictors` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(predictors)
  manq <- setdiff(model$predictors, names(predictors))
  if (length(manq)) stop("Couches absentes du raster : ", paste(manq, collapse = ", "), ".", call. = FALSE)
  pr <- predictors[[model$predictors]]
  nd <- terra::as.data.frame(pr, cells = TRUE, na.rm = TRUE)
  cells <- nd$cell
  nd$cell <- NULL
  fill <- function(v, nm) {
    r <- terra::rast(pr[[1]])
    terra::values(r) <- NA_real_
    r[cells] <- v
    names(r) <- nm
    r
  }
  p <- .predict_df(model, nd)
  out <- c(fill(p$pred, "pred"), fill(p$sd, "sd"))
  if (aoa) {
    w <- model$weight_var
    if (use_cast && requireNamespace("CAST", quietly = TRUE)) {
      res <- CAST::aoa(newdata = pr, train = model$train, variables = model$predictors,
                       weight = as.data.frame(as.list(w)), verbose = FALSE)
      di <- res$DI
      names(di) <- "di"
      a <- res$AOA
      names(a) <- "aoa"
      out <- c(out, di, a)
    } else {
      res <- .aoa_fallback(model$train, nd, w)
      out <- c(out, fill(res$DI, "di"), fill(res$AOA, "aoa"))
    }
  }
  if (isTRUE(model$synthetic)) terra::metags(out) <- c(synthetic = "TRUE")
  out
}
