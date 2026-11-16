# Jeux synthétiques du mode démo : tout est marqué synthétique.

demo_chaine <- function() {
  grid <- build_grid(c(1007000, 6790000, 1009500, 6792500), 25)
  dtm <- synth_demo_dtm(grid)
  terrain <- suppressWarnings(derive_terrain(dtm, tpi_radii = c(100, 300)))
  climat <- synth_demo_climat(c(1007000, 6790000, 1022000, 6805000))
  pred <- demo_predictors(terrain, dtm, climat)
  list(grid = grid, dtm = dtm, climat = climat, pred = pred, truth = synth_demo_truth(pred))
}

test_that("synth_demo_dtm : sur la grille en Lambert-93, balisé synthétique", {
  g <- build_grid(c(1007000, 6790000, 1008000, 6791000), 25)
  d <- synth_demo_dtm(g)
  expect_equal(as.vector(terra::ext(d)), as.vector(terra::ext(g)))
  expect_equal(terra::res(d), c(25, 25))
  expect_error(assert_crs_2154(d), NA)
  expect_equal(unname(terra::metags(d)["synthetic"]), "TRUE")
  # reproductible, sans toucher à la graine globale
  set.seed(5); a <- stats::runif(1)
  set.seed(5); synth_demo_dtm(g); b <- stats::runif(1)
  expect_equal(a, b)
  expect_equal(terra::values(synth_demo_dtm(g)), terra::values(d))
  # la cellule contenant (est 1007510, nord 6790990) est la dernière ligne du haut
  expect_equal(unname(terra::rowColFromCell(d, terra::cellFromXY(d, cbind(1007510, 6790990)))),
               cbind(1, 21))
  expect_error(synth_demo_dtm("x"), "SpatRaster")
  gros <- build_grid(c(1007000, 6790000, 1014000, 6797000), 25)
  expect_error(synth_demo_dtm(gros), "dépasse")
  expect_error(synth_demo_dtm(build_grid(c(1007000, 6790000, 1008000, 6791000), 50)), "maille")
})

test_that("synth_demo_climat : trois couches de 1 km, convention de compute_gradients", {
  c1 <- synth_demo_climat(c(1007000, 6790000, 1022000, 6805000))
  expect_equal(names(c1), c("p_sv", "etp_sv", "t_moy"))
  expect_equal(terra::res(c1), c(1000, 1000))
  expect_equal(unname(terra::metags(c1)["synthetic"]), "TRUE")
  expect_error(assert_crs_2154(c1), NA)
})

test_that("chaîne démo : prédicteurs, vérité, points ; la règle bloquante s'applique", {
  skip_if_not_installed("ranger")
  s <- demo_chaine()
  expect_true(all(c("mnt", "pente", "twi", "tpi_300", "coarse_p_etp_sv", "coarse_t_moy") %in%
                    names(s$pred)))
  expect_equal(names(s$truth), c("trophic", "hydric", "bioclim"))
  # bioclim décroît avec l'altitude (terme -0,9 z(mnt) dominant)
  expect_lt(stats::cor(terra::values(s$truth[["bioclim"]])[, 1],
                       terra::values(s$pred[["mnt"]])[, 1], use = "complete.obs"), -0.5)

  pts <- synth_demo_points(s$pred, s$truth, n = 100, seed = 3)
  expect_s3_class(pts, "sf")
  expect_true(all(pts$synthetic))
  expect_true(all(pts$loc_precision_m == 10))
  expect_error(assert_crs_2154(pts), NA)
  # x = est, y = nord : les points sont dans l'emprise ; le prédicteur lu est celui de la cellule
  xy <- sf::st_coordinates(pts)
  expect_true(all(xy[, 1] > 1007000 & xy[, 1] < 1009500 & xy[, 2] > 6790000 & xy[, 2] < 6792500))
  expect_equal(pts$mnt, terra::extract(s$pred[["mnt"]], xy)[, 1])
  expect_true(all(c("pente_obs", "humus", "position") %in% names(pts)))
  # reproductible
  expect_equal(sf::st_coordinates(synth_demo_points(s$pred, s$truth, n = 100, seed = 3)), xy)
  # règle bloquante : des points à 700 m ne reçoivent pas de variables fines
  expect_error(synth_demo_points(s$pred, s$truth, n = 10, loc_precision_m = 700), "interdite")
  expect_error(synth_demo_truth(s$pred[[c("mnt", "pente")]]), "absentes")
  expect_error(demo_predictors(suppressWarnings(derive_terrain(s$dtm, tpi_radii = 100)),
                               s$dtm, s$climat[[1:2]]), "couches")
})

test_that("synth_demo_biotic : flore et arbres fabriqués, un type par point", {
  b <- synth_demo_biotic(rep(c("A", "B", "C"), 20))
  expect_equal(dim(b$flore), c(60, 12))
  expect_true(all(b$flore %in% 0:1))
  expect_true(all(b$arbres$synthetic))
  expect_equal(nrow(b$plot_types), 60)
  # sp1 (groupe A) plus fréquente dans A que dans B : par construction (0,8 contre 0,1)
  expect_gt(mean(b$flore[rep(c("A", "B", "C"), 20) == "A", "sp1"]),
            mean(b$flore[rep(c("A", "B", "C"), 20) == "B", "sp1"]))
})

test_that("synth_demo_reference : 50 m, aligné sur la grille de 25 m, balisé", {
  s <- demo_chaine()
  ref <- synth_demo_reference(s$truth, res = 50)
  expect_equal(terra::res(ref), c(50, 50))
  expect_equal(names(ref), names(s$truth))
  expect_equal(unname(terra::metags(ref)["synthetic"]), "TRUE")
  expect_equal(terra::xmin(ref) %% 50, 0)
  expect_error(synth_demo_reference(s$truth, res = 30), "multiple")
})

test_that("synth_reference.tif du dépôt est celui que fabrique le script (même grille)", {
  f <- system.file("extdata", "synth_reference.tif", package = "sylvostation")
  r <- load_reference(f)
  s <- demo_chaine()
  expect_equal(as.vector(terra::ext(r)), as.vector(terra::ext(s$grid)))
})
