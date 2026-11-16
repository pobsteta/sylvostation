# La référence est SYNTHÉTIQUE (inst/extdata/synth_reference.tif).

grille_ref <- function(res = 25, n = 8, valeurs = NULL, nom = "trophic") {
  r <- terra::rast(nrows = n, ncols = n, xmin = 1007000, xmax = 1007000 + n * res,
                   ymin = 6790000, ymax = 6790000 + n * res, crs = "EPSG:2154")
  terra::values(r) <- if (is.null(valeurs)) seq_len(n * n) else valeurs
  names(r) <- nom
  r
}

test_that("load_reference lit le jeu synthétique : EPSG:2154, couches, balise", {
  f <- system.file("extdata", "synth_reference.tif", package = "sylvostation")
  expect_true(nzchar(f))
  expect_lt(file.size(f), 200 * 1024)
  r <- load_reference(f)
  expect_equal(names(r), c("trophic", "hydric", "bioclim"))
  expect_error(assert_crs_2154(r), NA)
  expect_equal(terra::res(r), c(50, 50))
  expect_equal(unname(terra::metags(r)["synthetic"]), "TRUE")
  # origine multiple de 50 m (ADR 0004)
  expect_equal(terra::xmin(r) %% 50, 0)
  expect_equal(terra::ymin(r) %% 50, 0)
  # `layers` exige des couches, il ne sélectionne pas
  expect_equal(names(load_reference(f, layers = "hydric")), names(r))
})

test_that("load_reference : erreurs", {
  expect_error(load_reference(tempfile(fileext = ".tif")), "introuvable")
  f <- tempfile(fileext = ".tif")
  terra::writeRaster(grille_ref(nom = "autre"), f)
  expect_error(load_reference(f), "Aucune couche reconnue")
  g <- tempfile(fileext = ".tif")
  terra::writeRaster(grille_ref(), g)
  expect_error(load_reference(g, layers = "hydric"), "absentes")
  expect_false(isTRUE(unname(terra::metags(load_reference(g))["synthetic"]) == "TRUE"))
  # mauvais CRS
  h <- tempfile(fileext = ".tif")
  r4 <- terra::rast(nrows = 2, ncols = 2, xmin = 6, xmax = 7, ymin = 48, ymax = 49,
                    crs = "EPSG:4326")
  terra::values(r4) <- 1:4
  names(r4) <- "trophic"
  terra::writeRaster(r4, h)
  expect_error(load_reference(h), "EPSG:2154|incorrect")
})

test_that("recode_3digits : seuils de la référence, ordre trophique-bioclimat-eau", {
  g <- data.frame(trophic = c(-1, 0.5, 2, NA), hydric = c(0, 1, 1, 0), bioclim = c(0, 0, 1, 0))
  th <- list(trophic = c(-0.5, 0.5), bioclim = 0.5, hydric = c(0.5, 2))
  r <- recode_3digits(g, th)
  # trophic : -1 -> 1 ; 0,5 (= seuil) -> 3 ; 2 -> 3 ; bioclim : 0 -> 1, 1 -> 2 ;
  # hydric : 0 -> 1, 1 -> 2
  expect_equal(r$code3, c("111", "312", "322", NA))
  expect_equal(r$trophic_ref, c(1L, 3L, 3L, NA))
  expect_equal(r$bioclim_ref, c(1L, 1L, 2L, 1L))
  # ordre explicite
  expect_equal(recode_3digits(g, th, order = c("hydric", "trophic", "bioclim"))$code3[1], "111")
  expect_equal(recode_3digits(g, th, order = c("hydric", "trophic", "bioclim"))$code3[2], "231")
})

test_that("recode_3digits : erreurs", {
  g <- data.frame(trophic = 1, hydric = 1, bioclim = 1)
  expect_error(recode_3digits(g, list(trophic = 0)), "contenant")
  expect_error(recode_3digits(g["trophic"], list(trophic = 0, bioclim = 0, hydric = 0)),
               "absents")
  expect_error(recode_3digits(g, list(trophic = c(1, 0), bioclim = 0, hydric = 0)),
               "croissants")
  expect_error(recode_3digits(g, list(trophic = 1:9, bioclim = 0, hydric = 0)), "9 classes")
})

test_that("compare_gradients : rho = 1 pour une carte identique, -1 pour l'inverse", {
  a <- grille_ref(25, 8)
  r <- compare_gradients(a, terra::aggregate(a, fact = 2), res = 50)
  expect_equal(r$correlation$rho, 1)
  expect_equal(r$correlation$n, 16)   # 8 x 8 cellules de 25 m -> 4 x 4 de 50 m
  expect_equal(unname(terra::res(r$ours)), c(50, 50))
  expect_equal(as.numeric(terra::global(abs(r$ecarts), "max", na.rm = TRUE)[1, 1]), 0)
  inv <- compare_gradients(a, grille_ref(25, 8, rev(seq_len(64))), res = 50)
  expect_equal(inv$correlation$rho, -1)
})

test_that("compare_gradients : agrégation à 50 m, cellule connue, écarts standardisés", {
  a <- grille_ref(25, 8)
  # référence à 50 m, même emprise, affine en (ligne, colonne) comme notre moyenne
  # (8 * ligne + colonne) : après centrage-réduction, les deux cartes sont identiques
  v8 <- as.vector(t(outer(1:4, 1:4, function(i, j) 8 * i + j)))
  b <- grille_ref(50, 4, valeurs = v8)
  r <- compare_gradients(a, b, res = 50)
  # Le point (1007060, 6790190) est à l'est de x=1007000 : colonne 2 (60 / 50) ; au nord de
  # y = 6790000 : 190 m depuis le bas = 10 m sous le haut (6790200) : ligne 1 (en haut).
  cel <- terra::cellFromXY(r$ours, cbind(1007060, 6790190))
  expect_equal(unname(terra::rowColFromCell(r$ours, cel)), cbind(1, 2))
  # moyenne de nos 4 cellules de 25 m (lignes 1-2, colonnes 3-4 de la grille 8 x 8) :
  # valeurs 3, 4, 11, 12 -> 7,5
  expect_equal(r$ours[cel][[1]], 7.5)
  # mêmes rangs que la référence : rho = 1 ; écart standardisé nul
  expect_equal(r$correlation$rho, 1)
  expect_equal(r$ecarts[cel][[1]], 0, tolerance = 1e-12)
  expect_equal(names(r$ecarts), "ecart_trophic")
  # une référence de grille différente est rééchantillonnée
  d <- grille_ref(50, 4, valeurs = v8)
  terra::ext(d) <- terra::ext(1007010, 1007210, 6790010, 6790210)
  expect_gt(compare_gradients(a, d, res = 50)$correlation$rho, 0.9)
})

test_that("compare_gradients : erreurs et balise synthétique", {
  a <- grille_ref(25, 8)
  expect_error(compare_gradients(a, "x"), "SpatRaster")
  expect_error(compare_gradients(a, grille_ref(nom = "autre")), "commune")
  expect_error(compare_gradients(a, a, res = 30), "multiple")
  expect_error(compare_gradients(a, a, res = -1), "positif")
  mauvais <- a
  terra::crs(mauvais) <- "EPSG:4326"
  expect_error(compare_gradients(mauvais, a), "EPSG|incorrect|implausibles")
  s <- a
  terra::metags(s) <- c(synthetic = "TRUE")
  expect_true(compare_gradients(s, a)$synthetic)
  expect_false(compare_gradients(a, a)$synthetic)
})
