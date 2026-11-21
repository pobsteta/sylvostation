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

test_that("aggregate_to_km : moyenne à 1000 m, noms conservés, erreurs", {
  f <- make_synth_sol(100, "x")
  r <- terra::rast(f)
  a <- aggregate_to_km(r)
  expect_equal(terra::res(a), c(1000, 1000))
  expect_equal(names(a), names(r))
  # x relatif moyen de la maille de 1 km : 0,5 (x en km)
  expect_equal(terra::extract(a, cbind(1007500, 6790500))[[1]], 0.5)
  expect_equal(terra::res(aggregate_to_km(r, 500)), c(500, 500))
  expect_error(aggregate_to_km(r, 150), "multiple")
  expect_error(aggregate_to_km(r, -1), "positif")
  expect_error(aggregate_to_km(3), "SpatRaster")
})

test_that("une couche agrégée à 1 km passe l'extraction IFN, la couche à 100 m non", {
  r <- terra::rast(make_synth_sol(100, "x"))
  clim <- function(x) { y <- c(x, x, x); names(y) <- c("p_sv", "etp_sv", "t_moy"); y }
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), climat = clim(r)),
               "1000 m")
  expect_no_error(compute_gradients(make_synth_ifn(), make_synth_indic(),
                                    climat = clim(aggregate_to_km(r))))
})

# --- SoilGrids pH (mission 035) : aucun reseau, source fabriquee en memoire ---------------
synth_phh2o <- function(crs = "EPSG:3035") {
  # pH x 10 = 50 a l'ouest, 70 a l'est (x = est) ; Europe LAEA (EPSG:3035), maille de 250 m,
  # centree sur le point (1005000, 6805000) de Lambert-93
  c3035 <- sf::st_coordinates(sf::st_transform(
    sf::st_sfc(sf::st_point(c(1005000, 6805000)), crs = 2154), 3035))
  x0 <- floor(c3035[1] / 250) * 250 - 100000
  y0 <- floor(c3035[2] / 250) * 250 - 100000
  r <- terra::rast(xmin = x0, xmax = x0 + 200000, ymin = y0, ymax = y0 + 200000,
                   resolution = 250, crs = crs)
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  terra::values(r) <- ifelse(xy[, 1] < c3035[1], 50, 70)
  names(r) <- "phh2o_0-5cm_mean"
  terra::metags(r) <- c(synthetic = "TRUE")
  r
}

test_that("fetch_soilgrids_ph : fenetre reprojetee en Lambert-93, pH / 10, cache par emprise", {
  d <- tempfile("sg")
  appels <- 0L
  lecteur <- function(url) {
    appels <<- appels + 1L
    expect_match(url, "phh2o_0-5cm_mean\\.vrt$")
    synth_phh2o()
  }
  # emprise en Lambert-93 autour de Strasbourg-Colmar, dans le raster fabrique
  bb <- c(1000000, 6800000, 1010000, 6810000)
  f <- fetch_soilgrids_ph(bb, d, reader = lecteur)
  expect_equal(appels, 1L)
  r <- terra::rast(f)
  expect_error(assert_crs_2154(r), NA)
  expect_equal(terra::res(r), c(250, 250))
  v <- terra::values(r, mat = FALSE)
  expect_true(all(v[!is.na(v)] >= 5 - 1e-6 & v[!is.na(v)] <= 7 + 1e-6))   # pH, pas pH x 10
  expect_gt(sum(!is.na(v)), 100)
  # meme emprise : le fichier du cache est resservi sans lecture
  expect_identical(fetch_soilgrids_ph(bb, d, reader = lecteur), f)
  expect_equal(appels, 1L)
  # autre emprise : autre fichier, nouvelle lecture (jamais un ancien fichier resservi)
  f2 <- fetch_soilgrids_ph(c(1000000, 6800000, 1020000, 6810000), d, reader = lecteur)
  expect_false(identical(f, f2))
  expect_equal(appels, 2L)
  expect_error(fetch_soilgrids_ph(c(1000000, 6800000, 1000500, 6800500), d, offline = TRUE), "hors ligne")
  expect_error(fetch_soilgrids_ph(bb, d, layer = "../x"), "layer")
})

test_that("soilgrids_disk_mean et raster_at_points : un point connu, regle des 700 m", {
  ph <- terra::rast(xmin = 1000000, xmax = 1010000, ymin = 6800000, ymax = 6810000,
                    resolution = 250, crs = "EPSG:2154")
  xy <- terra::xyFromCell(ph, seq_len(terra::ncell(ph)))
  terra::values(ph) <- ifelse(xy[, 1] < 1005000, 5, 7)    # ouest 5, est 7 (x = est)
  m <- soilgrids_disk_mean(ph, 700)
  expect_identical(names(m), "coarse_ph_soilgrids_700m")
  p <- function(x, y) mark_ifn(sf::st_sf(id_placette = "p", geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154)))
  # loin de la limite : valeur de la zone ; sur la limite : moyenne des deux
  expect_equal(raster_at_points(p(1002000, 6805000), m)$coarse_ph_soilgrids_700m, 5)
  expect_equal(raster_at_points(p(1008000, 6805000), m)$coarse_ph_soilgrids_700m, 7)
  s <- raster_at_points(p(1005000, 6805000), m)$coarse_ph_soilgrids_700m
  expect_gt(s, 5.5)
  expect_lt(s, 6.5)
  # un point fin (variable non coarse_) est refuse sur une placette IFN
  fine <- m
  names(fine) <- "pente_ph"
  expect_error(raster_at_points(p(1002000, 6805000), fine), "IFN|interdite")
  # maille trop fine refusee ; rayon inferieur a 700 m refuse
  expect_error(soilgrids_disk_mean(ph, 500), "700")
  fin <- terra::rast(xmin = 1000000, xmax = 1002000, ymin = 6800000, ymax = 6802000,
                     resolution = 50, crs = "EPSG:2154", vals = 6)
  expect_error(soilgrids_disk_mean(fin, 700), "250")
  expect_error(soilgrids_disk_mean(1), "SpatRaster")
  names(fin) <- "coarse_x"
  expect_error(raster_at_points(p(1002000, 6805000), fin), "maille")
})
