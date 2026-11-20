# Mission 039 : temperature SAFRAN corrigee du relief, RU apprise, bilan lateral.
# Extrait reel de 12 mailles SAFRAN (2003-2004, Licence Ouverte 2.0) et jeux fabriques en
# memoire (aucun fichier synthetique ecrit, aucun telechargement).

safran12r <- function() {
  read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv", package = "sylvostation"))
}

# centre d'une maille SAFRAN en Lambert-93 (x = est, y = nord)
centre_r <- function(lambx, lamby) {
  p <- sf::st_as_sf(data.frame(x = lambx * 100, y = lamby * 100), coords = c("x", "y"),
                    crs = 27572)
  unname(sf::st_coordinates(sf::st_transform(p, 2154))[1, ])
}

# SAFRAN fabrique sur les 12 mailles de l'extrait : T = 12 - 0,006 z + 0,002 x_km (deux jours),
# altitudes connues ; synthetic = TRUE (jeu fabrique, jamais presente comme reel)
safran_lineaire <- function(G = -0.006) {
  m <- sylvostation:::.mailles_safran(safran12r())
  z <- seq(200, 1300, length.out = nrow(m))
  z <- z[c(5, 2, 9, 12, 1, 7, 3, 11, 6, 10, 4, 8)]
  t <- 12 + G * z + 0.002 * m$x / 1000
  s <- data.frame(LAMBX = rep(m$LAMBX, 2), LAMBY = rep(m$LAMBY, 2),
                  DATE = rep(c(20030101, 20030701), each = nrow(m)), T = rep(t, 2),
                  synthetic = TRUE)
  list(s = s, alt = data.frame(maille = m$maille, z_moy = z), m = m, t = t)
}

point_ifn <- function(x, y) {
  mark_ifn(sf::st_sf(id_placette = "p", geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154)))
}

test_that(".safran_poids4 (creux) rend les memes poids que la matrice dense", {
  s <- safran12r()
  m <- sylvostation:::.mailles_safran(s)
  set.seed(1)
  x <- stats::runif(400, min(m$x) - 9000, max(m$x) + 9000)   # x = est
  y <- stats::runif(400, min(m$y) - 9000, max(m$y) + 9000)   # y = nord
  W <- sylvostation:::.safran_poids(x, y, m)
  P <- sylvostation:::.safran_poids4(x, y, m)
  D <- matrix(0, length(x), nrow(m))
  for (c in 1:4) {
    ok <- !is.na(P$j[, c])
    D[cbind(which(ok), P$j[ok, c])] <- P$w[ok, c]
  }
  D[P$hors, ] <- NA
  expect_equal(unname(D), unname(W))
  expect_true(any(P$hors) && any(!P$hors))
  v <- seq_len(nrow(m)) * 1.5
  W0 <- W
  W0[is.na(W0)] <- 0
  ref <- as.numeric(W0 %*% v)
  ref[P$hors] <- NA
  expect_equal(sylvostation:::.interp4(P, v), ref)
})

test_that("safran_cell_altitude : un relief connu tombe dans la bonne maille (Lambert-93)", {
  s <- safran12r()
  m <- sylvostation:::.mailles_safran(s)
  dem <- terra::rast(xmin = min(m$x) - 8000, xmax = max(m$x) + 8000, ymin = min(m$y) - 8000,
                     ymax = max(m$y) + 8000, resolution = 250, crs = "EPSG:2154", vals = 0)
  c0 <- centre_r(9640, 23690)
  expect_lt(max(abs(c0 - c(1014550, 6799283))), 2)           # x = est, y = nord
  xy <- terra::xyFromCell(dem, seq_len(terra::ncell(dem)))
  terra::values(dem) <- ifelse(abs(xy[, 1] - c0[1]) < 2000 & abs(xy[, 2] - c0[2]) < 2000, 1000, 0)
  a <- safran_cell_altitude(s, dem)
  expect_named(a, c("maille", "LAMBX", "LAMBY", "x", "y", "z_moy", "couverture"))
  expect_gt(a$z_moy[a$maille == "9640_23690"], 200)
  expect_true(all(a$z_moy[a$maille != "9640_23690"] == 0))
  expect_true(all(a$couverture > 0.99))
  # maille hors du MNT : altitude NA, couverture 0
  petit <- terra::crop(dem, terra::ext(c0[1] - 3000, c0[1] + 3000, c0[2] - 3000, c0[2] + 3000))
  b <- safran_cell_altitude(s, petit)
  expect_true(is.na(b$z_moy[b$maille == "9560_23530"]))
  expect_lt(min(b$couverture), 0.01)
  expect_error(safran_cell_altitude(s, terra::project(dem, "EPSG:4326")), "2154|Lambert")
  expect_error(safran_cell_altitude(data.frame(a = 1), dem), "LAMBX")
})

test_that("safran_lapse_rate : retrouve le gradient d'un champ lineaire", {
  f <- safran_lineaire(-0.006)
  g <- safran_lapse_rate(f$s, f$alt)
  expect_equal(g$gradient, -0.006, tolerance = 1e-8)
  expect_equal(g$gradient_100m, -0.6, tolerance = 1e-6)
  expect_equal(g$n, 12L)
  expect_gt(g$r2, 0.999)
  expect_error(safran_lapse_rate(f$s, f$alt[1:4, ]), "minimum")
  expect_error(safran_lapse_rate(f$s[, c("LAMBX", "LAMBY", "DATE")], f$alt), "temp")
  expect_error(safran_lapse_rate(f$s, data.frame(maille = 1)), "z_moy")
})

test_that("t_corrected : point connu en Lambert-93, altitude des mailles = bilineaire", {
  f <- safran_lineaire(-0.006)
  c0 <- centre_r(9640, 23690)
  dem <- terra::rast(xmin = c0[1] - 1000, xmax = c0[1] + 1000, ymin = c0[2] - 1000,
                     ymax = c0[2] + 1000, resolution = 250, crs = "EPSG:2154")
  z0 <- f$alt$z_moy[f$alt$maille == "9640_23690"]
  t0 <- f$t[f$m$maille == "9640_23690"]
  terra::values(dem) <- z0 + 100
  r <- t_corrected(dem, f$s, f$alt, -0.0055)
  expect_identical(names(r), "t_corr")
  # cellule qui contient le centre de la maille : T de la maille - 0,55 degC
  v <- terra::extract(r, matrix(c0, 1))[[1]]
  b <- t_corrected(dem * 0 + z0, f$s, f$alt, -0.0055)            # meme altitude : bilineaire
  vb <- terra::extract(b, matrix(c0, 1))[[1]]
  expect_equal(v - vb, -0.55, tolerance = 1e-9)
  # champ lineaire en z et x : avec le vrai gradient, la correction retrouve le champ
  ex <- t_corrected(dem, f$s, f$alt, -0.006)
  expect_lt(abs(terra::extract(ex, matrix(c0, 1))[[1]] - (t0 - 0.6)), 0.05)
  # blocs : meme resultat quel que soit `chunk`
  expect_equal(terra::values(t_corrected(dem, f$s, f$alt, -0.0055, chunk = 7L)),
               terra::values(r))
  # liste de safran_lapse_rate() acceptee
  expect_equal(terra::values(t_corrected(dem, f$s, f$alt, list(gradient = -0.0055))),
               terra::values(r))
  expect_error(t_corrected(dem, f$s, f$alt, "a"), "gradient")
  expect_error(t_corrected(1, f$s, f$alt, -0.0055), "SpatRaster")
})

test_that("coarse_t_corr_layer passe l'assertion des 700 m ; t_corr la declenche", {
  f <- safran_lineaire()
  c0 <- centre_r(9640, 23690)
  dem <- terra::rast(xmin = c0[1] - 3000, xmax = c0[1] + 3000, ymin = c0[2] - 3000,
                     ymax = c0[2] + 3000, resolution = 250, crs = "EPSG:2154", vals = 500)
  ct <- coarse_t_corr_layer(dem, f$s, f$alt, -0.0055)
  expect_identical(names(ct), "coarse_t_corr_700m")
  p <- point_ifn(c0[1], c0[2])
  v <- raster_at_points(p, ct)
  expect_true(is.finite(v$coarse_t_corr_700m))
  expect_silent(assert_no_fine_extract_on_ifn(p, "coarse_t_corr_700m"))
  # t_corr a la cellule (MNT fin) : variable fine, refusee aux placettes IFN
  tc <- t_corrected(dem, f$s, f$alt, -0.0055)
  expect_error(raster_at_points(p, tc), "IFN|interdite")
  expect_error(assert_no_fine_extract_on_ifn(p, "t_corr"), "IFN")
  expect_error(assert_no_fine_extract_on_ifn(p, "mnt_250"), "IFN")
  # un MNT plus fin que 250 m est refuse pour la couche large
  fin <- terra::disagg(dem, 5)
  expect_error(coarse_t_corr_layer(fin, f$s, f$alt, -0.0055), "250")
})

test_that("model_climate_vars : choix de config.yml", {
  a <- model_climate_vars("corrigee", "actuel")
  expect_identical(a$t_var, "coarse_t_corr_700m")
  expect_identical(a$trophic, c("coarse_p_etp_sv", "coarse_t_moy"))
  expect_identical(a$hydric, c("coarse_p_etp_sv", "coarse_t_corr_700m"))
  expect_setequal(a$toutes, c("coarse_p_etp_sv", "coarse_t_moy", "coarse_t_corr_700m"))
  expect_identical(model_climate_vars("bilineaire", "actuel")$hydric,
                   c("coarse_p_etp_sv", "coarse_t_moy"))
  expect_length(model_climate_vars("corrigee", "sans")$trophic, 0)
  expect_identical(model_climate_vars("corrigee", "corrige")$trophic,
                   c("coarse_p_etp_sv", "coarse_t_corr_700m"))
  expect_error(model_climate_vars("x"))
})

test_that("t_correction_validation : le gradient de la SER bat le bilineaire sur un champ lineaire", {
  f <- safran_lineaire(-0.006)
  v <- t_correction_validation(f$s, f$alt)
  expect_identical(v$methode, c("bilineaire", "gradient_fixe", "gradient_ser"))
  expect_true(all(v$n > 0))
  r <- stats::setNames(v$rmse, v$methode)
  expect_lt(r[["gradient_ser"]], r[["gradient_fixe"]])
  expect_lt(r[["gradient_fixe"]], r[["bilineaire"]])
  # le gradient est vrai mais x varie : l'erreur residuelle vient du terme en x seulement
  expect_lt(r[["gradient_ser"]], 0.02)
})

test_that(".t_shift : temperature decalee, pression de vapeur conservee", {
  sm <- data.frame(T = c(10, 20), HU = c(80, 50))
  expect_identical(sylvostation:::.t_shift(sm, 0), sm)
  x <- sylvostation:::.t_shift(sm, -2)
  expect_equal(x$T, c(8, 18))
  es <- function(t) 0.6108 * exp(17.27 * t / (t + 237.3))
  expect_equal(x$HU * es(x$T), sm$HU * es(sm$T))
  expect_true(all(x$HU <= 100))
  expect_equal(sylvostation:::.t_shift(data.frame(T = 5, HU = 99), -5)$HU, 100)
})

test_that("hydric_stress_grid : la T corrigee rafraichit un noeud plus haut que ses mailles", {
  skip_if_not_installed("biljouR")
  s <- safran12r()
  c0 <- centre_r(9640, 23690)
  k <- terra::rast(xmin = c0[1] - 50, xmax = c0[1] + 50, ymin = c0[2] - 50, ymax = c0[2] + 50,
                   resolution = 50, crs = "EPSG:2154", nlyrs = 12, vals = 1)
  names(k) <- sprintf("k_%02d", 1:12)
  m <- sylvostation:::.mailles_safran(s)
  am <- data.frame(maille = m$maille, z_moy = 400)
  ru <- data.frame(maille = "9640_23690", ru_mm = 80)
  alt400 <- k[[1]] * 0 + 400
  h0 <- hydric_stress_grid(k, ru, s, altitude = alt400, n_controle = 0)
  h1 <- hydric_stress_grid(k, ru, s, altitude = alt400, n_controle = 0, t_lapse = -0.0055,
                           alt_mailles = am)
  # noeud a l'altitude des mailles : correction nulle, meme resultat
  expect_equal(terra::values(h1), terra::values(h0))
  expect_equal(attr(h1, "mailles")$dT_moyen, 0)
  h2 <- hydric_stress_grid(k, ru, s, altitude = alt400 + 400, n_controle = 0, t_lapse = -0.0055,
                           alt_mailles = am)
  expect_equal(attr(h2, "mailles")$dT_moyen, -2.2, tolerance = 1e-9)
  expect_lt(mean(terra::values(h2)[, "is_topo"]), mean(terra::values(h0)[, "is_topo"]))
  expect_equal(attr(h2, "parametres")$t_lapse, -0.0055)
  expect_error(hydric_stress_grid(k, ru, s, altitude = alt400, t_lapse = -0.0055), "z_moy")
  expect_error(hydric_stress_grid(k, ru, s, t_lapse = -0.0055, alt_mailles = am), "altitude")
  expect_error(hydric_stress_grid(k, ru, s, altitude = alt400, t_lapse = -0.0055,
                                  alt_mailles = am, interpolation = "proche"), "bilineaire")
})

test_that("ru_fill_by_cell : une cellule sans RU apprise prend la RU de sa maille", {
  s <- safran12r()
  c0 <- centre_r(9640, 23690)
  r <- terra::rast(xmin = c0[1] - 50, xmax = c0[1] + 50, ymin = c0[2] - 50, ymax = c0[2] + 50,
                   resolution = 50, crs = "EPSG:2154", vals = c(NA, 120, 130, NA))
  f <- ru_fill_by_cell(r, data.frame(maille = "9640_23690", ru_mm = 90), s)
  expect_identical(names(f), "ru_carte")
  expect_equal(terra::values(f)[, 1], c(90, 120, 130, 90))
  expect_error(ru_fill_by_cell(r, data.frame(a = 1), s), "maille")
})

test_that("write_layers : couches ecrites, NULL ignore, prefixe synth_", {
  r <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                   resolution = 25, crs = "EPSG:2154", vals = 9)
  names(r) <- "t_corr"
  d <- tempfile("w039")
  w <- write_layers(list(temperature_corrigee = r, rien = NULL), d, "D11", synthetic = TRUE)
  expect_equal(basename(w$fichier), "synth_temperature_corrigee.tif")
  expect_true(file.exists(w$fichier))
  expect_equal(unname(terra::values(terra::rast(w$fichier))[1, 1]), 9)
  expect_equal(nrow(write_layers(list(a = NULL), d, "D11")), 0)
  expect_error(write_layers(list(r), d, "D11"), "nomm")
})
