synth <- synth_modeles()
pts <- synth$points
prd <- c("coarse_climat", "pente", "twi")

test_that("le jeu synthétique est marqué et en Lambert-93", {
  expect_true(all(pts$synthetic))
  expect_error(assert_crs_2154(pts), NA)
})

test_that("fit_gradient bloque les variables fines sur des placettes IFN", {
  skip_if_not_installed("ranger")
  expect_error(fit_gradient(pts, "gradient", prd, points_source = "ifn"), "interdite")
  expect_error(fit_gradient(mark_ifn(pts), "gradient", prd), "interdite")
  # précision absente : refus aussi
  sans <- pts
  sans$loc_precision_m <- NULL
  expect_error(fit_gradient(sans, "gradient", prd), "interdite")
  # maille large seule : permis sur IFN
  m <- fit_gradient(pts, "gradient", "coarse_climat", points_source = "ifn",
                    num_trees = 20, seed = 1)
  expect_s3_class(m, "sylvo_gradient")
})

test_that("spatial_cv applique la règle bloquante (via fit_gradient)", {
  skip_if_not_installed("ranger")
  expect_error(spatial_cv(pts, "gradient", prd, points_source = "ifn", block_size = 4000),
               "interdite")
})

test_that("fit_gradient ranger et gam : poids, NA, marquage synthétique", {
  skip_if_not_installed("ranger")
  skip_if_not_installed("mgcv")
  m1 <- fit_gradient(pts, "gradient", prd, num_trees = 50, seed = 1,
                     weights = rep(c(1, 2), length.out = nrow(pts)))
  m2 <- fit_gradient(pts, "gradient", prd, method = "gam")
  expect_true(m1$synthetic)
  expect_equal(sum(m1$weight_var), 1)
  expect_s3_class(m2$fit, "gam")
  expect_output(print(m1), "SYNTHÉTIQUES")
  expect_error(fit_gradient(pts, "gradient", prd, weights = 1), "longueur")
  pn <- pts
  pn$twi[1] <- NA
  expect_warning(fit_gradient(pn, "gradient", prd, num_trees = 20), "NA")
})

test_that("les blocs gardent chaque bloc dans un seul pli, plis équilibrés", {
  xy <- sf::st_coordinates(pts)
  f <- .block_folds(xy, 4000, 5)
  bloc <- paste(floor(xy[, 1] / 4000), floor(xy[, 2] / 4000))
  expect_true(all(tapply(f, bloc, function(z) length(unique(z))) == 1))
  expect_equal(sort(unique(f)), 1:5)
  expect_lt(max(table(f)) / min(table(f)), 2.5)
  expect_error(.block_folds(xy, 100000, 5), "blocs")
})

test_that("la portée estimée est plausible sur un champ autocorrélé", {
  xy <- sf::st_coordinates(pts)
  r <- .estimate_range(xy, pts$coarse_climat)
  expect_true(is.na(r) || (r > 500 && r < 15000))
})

test_that("CV par blocs : R2 > 0,5 et <= R2 de la CV aléatoire (autocorrélation)", {
  skip_if_not_installed("ranger")
  cv_b <- spatial_cv(pts, "gradient", prd, block_size = 5000, k = 5,
                     num_trees = 100, seed = 1)
  set.seed(3)
  alea <- sample(rep(1:5, length.out = nrow(pts)))
  cv_a <- spatial_cv(pts, "gradient", prd, folds = alea, num_trees = 100, seed = 1)
  expect_gt(cv_b$global[["r2"]], 0.5)
  expect_lte(cv_b$global[["r2"]], cv_a$global[["r2"]])
  expect_equal(nrow(cv_b$par_pli), 5)
  expect_named(cv_b$par_pli, c("pli", "n", "r2", "rmse"))
  expect_equal(sum(cv_b$par_pli$n), nrow(pts))
  expect_true(cv_b$global[["rmse"]] > 0)
})

test_that("spatial_cv avec GAM, taille de bloc estimée, entrées invalides", {
  skip_if_not_installed("mgcv")
  cv <- spatial_cv(pts, "gradient", prd, method = "gam")
  expect_true(cv$block_size > 0)
  expect_gt(cv$global[["r2"]], 0.5)
  expect_error(spatial_cv(pts, "gradient", prd, method = "gam", block_size = -1), "positif")
  expect_error(spatial_cv(pts, "gradient", prd, method = "gam", folds = 1:3), "longueur")
  expect_error(spatial_cv(data.frame(a = 1), "a", "b"), "sf")
})

test_that("predict_raster : couches, CRS, point connu, AOA", {
  skip_if_not_installed("ranger")
  m <- fit_gradient(pts, "gradient", prd, num_trees = 100, seed = 1)
  r <- predict_raster(m, synth$rasters, use_cast = FALSE)
  expect_equal(names(r), c("pred", "sd", "di", "aoa"))
  expect_equal(terra::crs(r), terra::crs(synth$rasters))
  # Un point connu tombe dans la bonne cellule (x = est, y = nord, EPSG:2154) :
  # (1010250, 6790250) : colonne 21 (10250 / 500 = 20,5), ligne 20 (9750 / 500 = 19,5
  # depuis le bord nord 6800000).
  p <- cbind(1010250, 6790250)
  cel <- terra::cellFromXY(r, p)
  expect_equal(unname(terra::rowColFromCell(r, cel)), cbind(20, 21))
  attendu <- .predict_df(m, terra::extract(synth$rasters, p))
  expect_equal(terra::extract(r, p)$pred, attendu$pred)
  expect_gt(stats::cor(terra::values(r$pred)[, 1],
                       terra::values(synth$rasters$coarse_climat)[, 1]), 0.5)
  expect_true(all(terra::values(r$sd) >= 0))
  expect_true(all(terra::values(r$aoa) %in% c(0, 1)))
  expect_gt(mean(terra::values(r$aoa)), 0.8)
  expect_equal(sylvostation:::.get_metag(r, "synthetic"), "TRUE")
})

test_that("AOA : une zone hors domaine est signalée hors zone", {
  skip_if_not_installed("ranger")
  m <- fit_gradient(pts, "gradient", prd, num_trees = 50, seed = 1)
  hors <- synth$rasters
  hors[["coarse_climat"]] <- hors[["coarse_climat"]] + 50
  r <- predict_raster(m, hors, use_cast = FALSE)
  expect_equal(mean(terra::values(r$aoa)), 0)
  skip_if_not_installed("CAST")
  rc <- predict_raster(m, hors)
  expect_equal(mean(terra::values(rc$aoa)), 0)
  rc2 <- predict_raster(m, synth$rasters)
  expect_gt(mean(terra::values(rc2$aoa)), 0.8)
})

test_that("predict_raster : GAM, sans AOA, erreurs", {
  skip_if_not_installed("mgcv")
  m <- fit_gradient(pts, "gradient", prd, method = "gam")
  r <- predict_raster(m, synth$rasters, aoa = FALSE)
  expect_equal(names(r), c("pred", "sd"))
  expect_error(predict_raster(m, synth$rasters[[1:2]]), "absentes")
  expect_error(predict_raster(m, "x"), "SpatRaster")
  expect_error(predict_raster(list(), synth$rasters), "fit_gradient")
  mauvais <- synth$rasters
  terra::crs(mauvais) <- "EPSG:4326"
  expect_error(predict_raster(m, mauvais), "EPSG|incorrect")
})

# --- Compléments mission 010 (relecture 008) ---------------------------------------

test_that("fit_gradient : un tableau x/y est converti en sf EPSG:2154 ou refusé", {
  skip_if_not_installed("ranger")
  d <- sf::st_drop_geometry(pts)
  d$coarse_a <- d$coarse_climat
  ok <- fit_gradient(d, "gradient", "coarse_a", num_trees = 20, seed = 1)
  expect_s3_class(ok, "sylvo_gradient")
  # x/y inversés (nord dans x) : coordonnées implausibles en Lambert-93
  inv <- d
  inv$x <- d$y
  inv$y <- d$x
  expect_error(fit_gradient(inv, "gradient", "coarse_a"), "implausibles")
  # degrés (WGS84) pris pour du Lambert-93
  deg <- d
  deg$x <- 6.9 + seq_len(nrow(d)) / 1e4
  deg$y <- 48.1 + seq_len(nrow(d)) / 1e4
  expect_error(fit_gradient(deg, "gradient", "coarse_a"), "implausibles")
  expect_error(spatial_cv(deg, "gradient", "coarse_a"), "implausibles")
  # ni sf ni colonnes x/y
  expect_error(fit_gradient(data.frame(a = 1:30, g = 1), "g", "a"), "x \\(est\\)")
  # x/y avec NA
  na <- d
  na$x[1] <- NA
  expect_error(fit_gradient(na, "gradient", "coarse_a"), "NA")
})

test_that("fit_gradient : ifn_precision_m est transmis à mark_ifn (défaut 700)", {
  skip_if_not_installed("ranger")
  expect_error(fit_gradient(pts, "gradient", "coarse_climat", points_source = "ifn",
                            ifn_precision_m = -5), "positif")
  expect_equal(formals(fit_gradient)$ifn_precision_m, 700)
  m <- fit_gradient(pts, "gradient", "coarse_climat", points_source = "ifn",
                    ifn_precision_m = 1000, num_trees = 20, seed = 1)
  expect_equal(m$points_source, "ifn")
})

test_that("spatial_cv garde l'écart-type prédit hors pli ; le modèle garde ses lignes", {
  skip_if_not_installed("ranger")
  cv <- spatial_cv(pts, "gradient", prd, block_size = 5000, k = 5, num_trees = 50, seed = 1)
  expect_named(cv$predictions, c("observe", "predit", "sd", "pli"))
  expect_true(all(cv$predictions$sd >= 0, na.rm = TRUE))
  m <- fit_gradient(pts, "gradient", prd, num_trees = 50, seed = 1)
  expect_equal(m$n_input, nrow(pts))
  expect_equal(m$rows, seq_len(nrow(pts)))
})

test_that("predict_raster : sd_cv calibrée sur le RMSE de validation croisée", {
  skip_if_not_installed("ranger")
  cv <- spatial_cv(pts, "gradient", prd, block_size = 5000, k = 5, num_trees = 50, seed = 1)
  m <- fit_gradient(pts, "gradient", prd, num_trees = 50, seed = 1)
  r <- predict_raster(m, synth$rasters, use_cast = FALSE, cv = cv)
  expect_equal(names(r), c("pred", "sd", "sd_cv", "di", "aoa"))
  k <- cv$global[["rmse"]] / sqrt(mean(cv$predictions$sd^2, na.rm = TRUE))
  ok <- terra::values(r$sd)[, 1] > 0 & is.finite(terra::values(r$sd)[, 1])
  expect_equal(terra::values(r$sd_cv)[ok, 1] / terra::values(r$sd)[ok, 1],
               rep(k, sum(ok)), tolerance = 1e-8)
  # sans cv : pas de couche sd_cv
  expect_false("sd_cv" %in% names(predict_raster(m, synth$rasters, use_cast = FALSE)))
  # cv invalide ou d'autres données : refus
  expect_error(predict_raster(m, synth$rasters, cv = list(plis = 1:3)), "spatial_cv")
  cv2 <- cv
  cv2$plis <- cv$plis[1:10]
  expect_error(predict_raster(m, synth$rasters, cv = cv2), "mêmes données")
})

test_that("predict_raster transmet les plis spatiaux à CAST::aoa", {
  skip_if_not_installed("ranger")
  skip_if_not_installed("CAST")
  cv <- spatial_cv(pts, "gradient", prd, block_size = 5000, k = 5, num_trees = 50, seed = 1)
  m <- fit_gradient(pts, "gradient", prd, num_trees = 50, seed = 1)
  recu <- new.env()
  testthat::local_mocked_bindings(
    aoa = function(newdata, ..., CVtest = NULL) {
      recu$cv <- CVtest
      list(DI = newdata[[1]], AOA = newdata[[1]] * 0 + 1)
    },
    .package = "CAST")
  r <- predict_raster(m, synth$rasters, cv = cv)
  expect_equal(recu$cv, cv$plis[m$rows])
  expect_true("aoa" %in% names(r))
  recu$cv <- "intact"
  predict_raster(m, synth$rasters)
  expect_null(recu$cv)
})

# --- encodage par la moyenne de la reponse (mission 035) ---------------------------------
test_that("target_encoding : moyenne retrecie vers la moyenne generale, formule exacte", {
  e <- target_encoding(c("a", "a", "a", "b", NA), c(1, 2, 3, 10, 99), k = 2)
  expect_equal(e$niveau, c("a", "b"))
  expect_equal(e$n, c(3L, 1L))
  g <- mean(c(1, 2, 3, 10))   # la ligne NA est ignoree
  expect_equal(attr(e, "generale"), g)
  expect_equal(e$valeur, c((3 * 2 + 2 * g) / 5, (1 * 10 + 2 * g) / 3))
  # k = 0 : moyennes brutes ; niveau rare tire vers g quand k augmente
  expect_equal(target_encoding(c("a", "b"), c(1, 5), k = 0)$valeur, c(1, 5))
  g3 <- 10 / 3   # moyenne generale de (10, 0, 0)
  expect_lt(abs(target_encoding(c("a", "b", "b"), c(10, 0, 0), k = 50)$valeur[1] - g3),
            abs(target_encoding(c("a", "b", "b"), c(10, 0, 0), k = 1)$valeur[1] - g3))
  expect_error(target_encoding(c("a", "b"), c(1, 2, 3)), "longueur")
  expect_error(target_encoding(c("a", "b"), c(1, 2), k = -1), "k")
  expect_error(target_encoding(c(NA, NA), c(1, 2)), "Aucune")
})

test_that("apply_target_encoding : niveau inconnu -> moyenne generale, NA reste NA", {
  e <- target_encoding(c("a", "a", "b"), c(1, 3, 10), k = 1)
  v <- apply_target_encoding(c("a", "b", "z", NA), e)
  expect_equal(v[1:2], e$valeur)
  expect_equal(v[3], attr(e, "generale"))
  expect_true(is.na(v[4]))
  expect_error(apply_target_encoding("a", data.frame(a = 1)), "target_encoding")
})

test_that("oof_target_encoding : la reponse d'une ligne n'entre jamais dans son propre encodage", {
  x <- rep(c("a", "b", "c"), 8)
  y <- as.numeric(1:24)
  f <- rep(1:4, each = 6)
  o1 <- oof_target_encoding(x, y, f, k = 1)
  y2 <- y
  y2[5] <- 1e6
  o2 <- oof_target_encoding(x, y2, f, k = 1)
  expect_equal(o1[5], o2[5])                  # sa propre reponse ne compte pas
  expect_false(isTRUE(all.equal(o1[f != f[5]], o2[f != f[5]])))   # les autres plis, si
  expect_equal(o1[f == f[5]], o2[f == f[5]])
  expect_error(oof_target_encoding(x, y, rep(1, 24)), "plis")
})

test_that("spatial_cv(encode) : pas de fuite ; l'encodage naif sur toutes les donnees en a une", {
  skip_if_not_installed("mgcv")
  set.seed(4)
  n <- 240
  d <- data.frame(x = runif(n, 1000000, 1040000), y = runif(n, 6800000, 6840000),
                  loc_precision_m = 10)
  d$lev <- paste0("f", sample(120, n, replace = TRUE))   # ~2 lignes par niveau, sans lien
  d$g <- rnorm(n)                                        # reponse independante du niveau
  naif <- d
  naif$coarse_enc <- apply_target_encoding(d$lev, target_encoding(d$lev, d$g, k = 0))
  r_naif <- spatial_cv(naif, "g", "coarse_enc", method = "gam", block_size = 8000)$global[["r2"]]
  r_ok <- spatial_cv(d, "g", "coarse_enc", method = "gam", block_size = 8000,
                     encode = list(var = "lev", name = "coarse_enc", k = 5))$global[["r2"]]
  expect_gt(r_naif, 0.2)    # fuite : R2 positif alors que la reponse est du bruit
  expect_lt(r_ok, 0.1)      # sans fuite : pas de pouvoir predictif
  expect_error(spatial_cv(d, "g", "coarse_enc", encode = list(var = "absente", name = "coarse_enc")),
               "encode")
  # deux variables encodees : liste de specifications
  d$lev2 <- paste0("h", sample(10, n, replace = TRUE))
  r2 <- spatial_cv(d, "g", c("coarse_enc", "coarse_enc2"), method = "gam", block_size = 8000,
                   encode = list(list(var = "lev", name = "coarse_enc", k = 5),
                                 list(var = "lev2", name = "coarse_enc2", k = 5)))
  expect_true(is.finite(r2$global[["r2"]]))
  expect_lt(r2$global[["r2"]], 0.1)
})

test_that("encode_by_blocks : colonne hors pli, encodage complet, lignes sans niveau retirees", {
  set.seed(2)
  n <- 80
  d <- data.frame(x = runif(n, 1000000, 1030000), y = runif(n, 6800000, 6830000),
                  lev = sample(c("a", "b", "c"), n, TRUE), g = rnorm(n))
  d$lev[1:3] <- NA
  r <- encode_by_blocks(d, "g", "lev", "enc", k = 5, block_size = 8000)
  expect_equal(nrow(r$data), n - 3)
  expect_equal(r$retirees, 3)
  expect_true(all(is.finite(r$data$enc)))
  expect_s3_class(r$data, "sf")
  expect_equal(sf::st_crs(r$data)$epsg, 2154)
  # l'encodage complet reproduit target_encoding sur les lignes gardees
  expect_equal(r$encoding, target_encoding(d$lev[-(1:3)], d$g[-(1:3)], 5))
  # la reponse d'une ligne ne change pas sa propre valeur encodee
  d2 <- d
  d2$g[10] <- 1e6
  r2 <- encode_by_blocks(d2, "g", "lev", "enc", k = 5, block_size = 8000)
  i <- which(rownames(r$data) == "10")
  expect_equal(r$data$enc[i], r2$data$enc[i])
  expect_error(encode_by_blocks(d, "absente", "lev"), "colonnes")
})

test_that("encode oof = FALSE : apprentissage encode avec toutes ses lignes, test sans fuite", {
  skip_if_not_installed("mgcv")
  set.seed(4)
  n <- 240
  d <- data.frame(x = runif(n, 1000000, 1040000), y = runif(n, 6800000, 6840000), loc_precision_m = 10)
  d$lev <- paste0("f", sample(120, n, replace = TRUE))
  d$g <- rnorm(n)
  r <- spatial_cv(d, "g", "coarse_enc", method = "gam", block_size = 8000,
                  encode = list(var = "lev", name = "coarse_enc", k = 5, oof = FALSE))
  expect_lt(r$global[["r2"]], 0.1)     # la reponse du pli de test n'entre jamais dans son encodage
  # encode_by_blocks(oof = FALSE) : encodage complet, y compris pour la ligne elle-meme
  e <- encode_by_blocks(d, "g", "lev", "enc", k = 2, block_size = 8000, oof = FALSE)
  expect_equal(e$data$enc, apply_target_encoding(d$lev, e$encoding))
  o <- encode_by_blocks(d, "g", "lev", "enc", k = 2, block_size = 8000, oof = TRUE)
  expect_false(isTRUE(all.equal(o$data$enc, e$data$enc)))
})
