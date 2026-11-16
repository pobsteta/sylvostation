make_synth_sol <- function(res, nom, valeur_x = TRUE) {
  r <- terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
                   resolution = res, crs = "EPSG:2154")
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  terra::values(r) <- if (valeur_x) (xy[, 1] - 1007000) / 1000 else 7
  names(r) <- nom
  f <- tempfile(pattern = paste0("synth_", nom), fileext = ".tif")
  terra::writeRaster(r, f)
  f
}

grille_25 <- function() {
  terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
              resolution = 250, crs = "EPSG:2154")
}

test_that("stack_soil_layers : préfixe coarse_ selon la maille native, sur la grille", {
  fin <- make_synth_sol(30, "fin", FALSE)
  gros <- make_synth_sol(1000, "gros")
  g <- grille_25()
  s <- stack_soil_layers(c(ph_fin = fin, ph_gros = gros), g)
  expect_equal(names(s), c("ph_fin", "coarse_ph_gros"))
  expect_equal(terra::res(s), terra::res(g))
  expect_equal(as.vector(terra::ext(s)), as.vector(terra::ext(g)))
  expect_equal(terra::nlyr(s), 2)
  # point connu : x = 1 012 125 (cellule de 250 m dont le centre est 1 012 125)
  v <- terra::extract(s, cbind(1012125, 6795125))
  expect_equal(v[["ph_fin"]], 7)
  expect_equal(v[["coarse_ph_gros"]], 5.5, tolerance = 0.6)  # 5,5 au centre de la maille de 1 km
})

test_that("stack_soil_layers : nom du fichier par défaut, seuil réglable, erreurs", {
  f <- make_synth_sol(1000, "gros")
  s <- stack_soil_layers(f, grille_25())
  expect_match(names(s), "^coarse_synth_gros")
  expect_equal(names(stack_soil_layers(c(a = f), grille_25(), coarse_res_m = 2000)), "a")
  expect_error(stack_soil_layers(file.path(tempdir(), "absent.tif"), grille_25()),
               "introuvable")
  expect_error(stack_soil_layers(f, 3), "SpatRaster")
  expect_error(stack_soil_layers(character(0), grille_25()), "chemins")
  g4326 <- terra::rast(xmin = 6, xmax = 7, ymin = 47, ymax = 48, crs = "EPSG:4326")
  expect_error(stack_soil_layers(f, g4326))
  expect_error(stack_soil_layers(c(a = f, a = f), grille_25()), "double")
})
