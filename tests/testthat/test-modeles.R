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
  expect_equal(unname(terra::metags(r)["synthetic"]), "TRUE")
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
