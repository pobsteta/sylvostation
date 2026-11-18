synth_path <- function() {
  system.file("extdata", "synth_dtm.tif", package = "sylvostation")
}
dt <- function(...) suppressWarnings(derive_terrain(...))

test_that(".get_metag lit les deux formes renvoyées par terra::metags", {
  gm <- sylvostation:::.get_metag
  # forme vecteur nommé (anciennes versions)
  expect_equal(gm(c(synthetic = "TRUE"), "synthetic"), "TRUE")
  expect_null(gm(c(autre = "x"), "synthetic"))
  expect_null(gm(character(0), "synthetic"))
  # forme data.frame (versions récentes)
  df <- data.frame(name = c("a", "synthetic"), value = c("1", "TRUE"),
                   domain = "", stringsAsFactors = FALSE)
  expect_equal(gm(df, "synthetic"), "TRUE")
  expect_null(gm(df, "absente"))
  expect_null(gm(df[0, ], "synthetic"))
  # raster réel
  r <- terra::rast(nrows = 2, ncols = 2)
  expect_null(gm(r, "synthetic"))
  terra::metags(r) <- c(synthetic = "TRUE")
  expect_equal(gm(r, "synthetic"), "TRUE")
})
inner <- function(r, k = 3) terra::crop(r, terra::ext(r) - k * terra::res(r)[1])

test_that("synth_dtm.tif est synthetique, en EPSG:2154, origine multiple de 50 m", {
  skip_if(!nzchar(synth_path()))
  d <- terra::rast(synth_path())
  expect_true(startsWith(basename(synth_path()), "synth_"))
  expect_equal(sylvostation:::.get_metag(d, "synthetic"), "TRUE")
  assert_crs_2154(d)
  e <- terra::ext(d)
  expect_equal(unname(e$xmin %% 50), 0); expect_equal(unname(e$ymin %% 50), 0)
  expect_equal(terra::values(d, mat = FALSE),
               terra::values(make_synth_dtm(), mat = FALSE), tolerance = 1e-4)
})

test_that("un point connu tombe dans la bonne cellule (x = est, y = nord)", {
  d <- make_synth_dtm()
  cell <- terra::cellFromXY(d, cbind(980012.5, 6800012.5))
  expect_equal(unname(terra::rowColFromCell(d, cell)), cbind(240, 1))  # coin sud-ouest
  expect_equal(d[cell][[1]], 500 + 0.1 * 12.5)
})

test_that("pente d'un plan de 10 % = 5,71 degres, exposition plein sud", {
  skip_if(!nzchar(synth_path()))
  out <- dt(terra::rast(synth_path()), tpi_radii = 100)
  i <- inner(out)
  expect_equal(range(terra::values(i$pente)), rep(atan(0.1) * 180 / pi, 2),
               tolerance = 1e-5)
  expect_equal(atan(0.1) * 180 / pi, 5.71, tolerance = 1e-3)
  expo <- atan2(terra::values(i$exposition_sin), terra::values(i$exposition_cos)) *
    180 / pi
  expect_equal(as.vector(expo %% 360), rep(180, length(expo)), tolerance = 1e-6)
  expect_equal(terra::values(i$exposition_cos)[1], -1, tolerance = 1e-6)
})

test_that("exposition plein est : plan descendant vers l'est = 90 degres", {
  d <- make_synth_dtm(nc = 60, fun = function(x, y) 500 - 0.1 * (x - 980000))
  out <- dt(d, tpi_radii = 100)
  expect_equal(terra::values(out$exposition_sin)[1470], 1, tolerance = 1e-6)
  expect_equal(terra::values(out$exposition_cos)[1470], 0, tolerance = 1e-6)
})

test_that("TPI nul sur un plan (hors bords), noms tpi_<rayon>", {
  d <- make_synth_dtm(nc = 200)  # 5 km : le disque de 1000 m tient
  out <- dt(d, tpi_radii = c(100, 300, 1000))
  expect_true(all(c("tpi_100", "tpi_300", "tpi_1000") %in% names(out)))
  for (n in c("tpi_100", "tpi_300", "tpi_1000")) {
    v <- terra::values(out[[n]])
    expect_gt(sum(!is.na(v)), 0)
    expect_lt(max(abs(v), na.rm = TRUE), 1e-3)
  }
  # le disque qui sort du MNT donne NA
  expect_true(is.na(terra::values(out$tpi_1000)[1]))
})

test_that("TPI positif au sommet d'un dome, negatif dans une cuvette", {
  dome <- function(x, y) 1000 - 0.0001 * ((x - 981000)^2 + (y - 6801000)^2)
  d <- make_synth_dtm(nc = 80, fun = dome)
  c0 <- terra::cellFromXY(d, cbind(981012.5, 6801012.5))
  expect_gt(dt(d, tpi_radii = 100)$tpi_100[c0][[1]], 0)
  cuvette <- make_synth_dtm(nc = 80, fun = function(x, y) -dome(x, y))
  expect_lt(dt(cuvette, tpi_radii = 100)$tpi_100[c0][[1]], 0)
})

test_that("courbures exactes sur un paraboloide z = a (x^2 + y^2)", {
  a <- 1e-3
  par <- function(s) function(x, y) s * a * ((x - 980200)^2 + (y - 6800200)^2)
  d <- make_synth_dtm(nc = 40, res = 10, fun = par(1))
  out <- dt(d, tpi_radii = 50)
  c1 <- terra::cellFromXY(d, cbind(980305, 6800255))  # hors du centre
  expect_equal(out$courbure[c1][[1]], -4 * a, tolerance = 1e-6)
  expect_equal(out$courbure_profil[c1][[1]], -2 * a, tolerance = 1e-6)
  expect_equal(out$courbure_plan[c1][[1]], 2 * a, tolerance = 1e-6)
  # dome (signe oppose) : courbure positive
  dd <- dt(make_synth_dtm(nc = 40, res = 10, fun = par(-1)), tpi_radii = 50)
  expect_gt(dd$courbure[c1][[1]], 0)
})

test_that("surface drainee : plan descendant au sud, D8 exact", {
  d <- make_synth_dtm(nc = 30, res = 10)
  out <- dt(d, tpi_radii = 50)
  # colonne du milieu : la ligne i depuis le nord draine i cellules de 100 m2
  m <- matrix(terra::values(out$surface_drainee, mat = FALSE) / 100, 30, 30,
              byrow = TRUE)
  expect_equal(m[, 15], as.numeric(1:30))
})

test_that("TWI fini sur plan et croissant avec la surface drainee", {
  d <- make_synth_dtm(nc = 30, res = 10)
  out <- dt(d, tpi_radii = 50)
  tw <- matrix(terra::values(out$twi, mat = FALSE), 30, 30, byrow = TRUE)
  expect_true(all(is.finite(tw[2:29, 2:29])))
  expect_true(all(diff(tw[2:29, 15]) > 0))
  # ligne 10 : a = 10 cellules * 10 m ; tan(pente) = 0,1 -> ln(a / 10 / 0,1)... a = acc * L
  expect_equal(tw[10, 15], log(10 * 10 / 0.1), tolerance = 1e-5)
})

test_that("hauteur au-dessus du reseau (HAND) : plan et ruisseau a y connu", {
  d <- make_synth_dtm(nc = 40, res = 10)
  y0 <- 6800000 + 195  # centre d'une rangee de cellules
  ln <- terra::vect(cbind(id = 1, part = 1, x = c(980000, 980400), y = c(y0, y0)),
                    type = "lines", crs = "EPSG:2154")
  out <- dt(d, tpi_radii = 50, streams = ln)
  c_n <- terra::cellFromXY(d, cbind(980205, y0 + 50))  # 50 m au nord
  c_s <- terra::cellFromXY(d, cbind(980205, y0 - 50))
  expect_equal(out$hauteur_reseau[c_n][[1]], 5, tolerance = 1e-6)
  expect_true(is.na(out$hauteur_reseau[c_s][[1]]))   # en aval du reseau : jamais negatif
  out2 <- dt(d, tpi_radii = 50, streams = sf::st_as_sf(ln))
  expect_equal(out2$hauteur_reseau[c_n][[1]], 5, tolerance = 1e-6)
  expect_error(dt(d, streams = terra::vect(cbind(980000, 6800000), crs = "EPSG:2154")),
               "lignes")
})

test_that("couches non calculees : NA et avertissement explicite", {
  d <- make_synth_dtm(nc = 30, res = 10)
  classes <- character()
  out <- withCallingHandlers(derive_terrain(d, tpi_radii = 50), warning = function(w) {
    classes <<- c(classes, class(w)[1])
    invokeRestart("muffleWarning")
  })
  expect_equal(classes, rep("sylvostation_non_calcule", 2))  # mrvbf, hauteur_reseau
  expect_true(all(is.na(terra::values(out$mrvbf))))
  expect_true(all(is.na(terra::values(out$hauteur_reseau))))
})

test_that("rayonnement : sud > plat > nord, et plat = formule de Duffie et Beckman", {
  lat <- 48
  s <- .radiation_potential(c(20, 0, 20), c(180, NA, 0), lat)
  expect_gt(s[1], s[2]); expect_gt(s[2], s[3])
  rad <- pi / 180
  ho <- 0
  for (k in seq_along(.JOURS_TYPES)) {
    n <- .JOURS_TYPES[k]
    dl <- 23.45 * sin(2 * pi * (284 + n) / 365) * rad
    ws <- acos(-tan(lat * rad) * tan(dl))
    h <- 24 * 3600 / pi * 1367 * (1 + 0.033 * cos(2 * pi * n / 365)) *
      (cos(lat * rad) * cos(dl) * sin(ws) + ws * sin(lat * rad) * sin(dl))
    ho <- ho + h / 3.6e6 * .JOURS_MOIS[k]
  }
  expect_equal(s[2], ho, tolerance = 0.01)
})

test_that("derive_terrain : couches nommees, toutes fines, bloquees sur IFN", {
  skip_if(!nzchar(synth_path()))
  out <- dt(terra::rast(synth_path()))
  attendu <- c("pente", "exposition_cos", "exposition_sin", "courbure",
               "courbure_plan", "courbure_profil", "tpi_100", "tpi_300", "tpi_1000",
               "twi", "surface_drainee", "mrvbf", "hauteur_reseau", "rayonnement")
  expect_equal(names(out), attendu)
  expect_true(all(attendu %in% FINE_VARIABLES))
  assert_crs_2154(out)
  p <- mark_ifn(data.frame(x = 980500, y = 6801000))
  expect_error(assert_no_fine_extract_on_ifn(p, names(out)), "IFN")
})

test_that("entrees refusees : CRS, couches, rayons", {
  d <- make_synth_dtm(nc = 20)
  bad <- d; terra::crs(bad) <- "EPSG:4326"
  expect_error(derive_terrain(bad))
  expect_error(derive_terrain(c(d, d)), "une seule couche")
  expect_error(derive_terrain(d, tpi_radii = -1), "rayons")
  expect_error(derive_terrain(1), "SpatRaster")
})

test_that("aggregate_dtm : moyenne, alignement, erreurs", {
  fine <- make_synth_dtm(nc = 100, res = 5, fun = function(x, y) x - 980000)
  ag <- aggregate_dtm(fine, res = c(5, 25))
  expect_named(ag, c("res_5", "res_25"))
  expect_equal(terra::res(ag$res_25), c(25, 25))
  expect_equal(terra::ncell(ag$res_25), 400)
  # moyenne de x sur un bloc de 25 m : centre du bloc
  expect_equal(ag$res_25[1, 1][[1]], 12.5, tolerance = 1e-9)
  e <- terra::ext(ag$res_25)
  expect_equal(unname(c(e$xmin %% 50, e$ymin %% 50)), c(0, 0))
  # point connu -> bonne cellule : 2e colonne, 1re ligne (nord) de la grille a 25 m
  expect_equal(terra::cellFromXY(ag$res_25, cbind(980030, 6800495)), 2)
  expect_error(aggregate_dtm(fine, res = 2), "plus fine")
  expect_error(aggregate_dtm(fine, res = 12), "multiple")
  expect_error(aggregate_dtm(fine, res = -1), "positives")
})

test_that("terrain plat : exposition NA, pente nulle", {
  d <- make_synth_dtm(nc = 30, res = 10, fun = function(x, y) rep(700, length(x)))
  out <- dt(d, tpi_radii = 50)
  i <- inner(out)
  expect_true(all(terra::values(i$pente) == 0))
  expect_true(all(is.na(terra::values(i$exposition_cos))))
  expect_true(all(is.na(terra::values(i$exposition_sin))))
})

test_that("mrvbf = FALSE (defaut) : NA, avertissement de classe sylvostation_non_calcule", {
  d <- make_synth_dtm(nc = 20, res = 10)
  ln <- terra::vect(cbind(id = 1, part = 1, x = c(980000, 980200), y = c(6800100, 6800100)),
                    type = "lines", crs = "EPSG:2154")   # evite l'avertissement de hauteur_reseau
  expect_warning(out <- derive_terrain(d, tpi_radii = 50, streams = ln),
                 "mrvbf", class = "sylvostation_non_calcule")
  expect_true(all(is.na(terra::values(out$mrvbf))))
})

test_that(".mrvbf_grass : GRASS absent ou en echec => NA et avertissement, sans erreur", {
  d <- make_synth_dtm(nc = 10, res = 25)
  expect_warning(m <- sylvostation:::.mrvbf_grass(d, grass = ""),
                 class = "sylvostation_non_calcule")
  expect_true(all(is.na(terra::values(m))))
  expect_equal(as.vector(terra::ext(m)), as.vector(terra::ext(d)))
  # un executable qui n'ecrit rien : echec detecte, pas d'erreur
  faux <- Sys.which("true")
  skip_if(!nzchar(faux))
  expect_warning(m2 <- sylvostation:::.mrvbf_grass(d, grass = faux),
                 "r.valley.bottom", class = "sylvostation_non_calcule")
  expect_true(all(is.na(terra::values(m2))))
})

test_that(".grass_has_extension : FALSE sans GRASS", {
  expect_false(sylvostation:::.grass_has_extension("r.valley.bottom", grass = ""))
})

test_that("MRVBF GRASS : fond de vallee plat >> versant, grille identique (lent, ~2 min)", {
  skip_if(!nzchar(Sys.which("grass")), "GRASS absent")
  skip_if(!sylvostation:::.grass_has_extension("r.valley.bottom"),
          "extension r.valley.bottom absente (g.extension extension=r.valley.bottom)")
  skip_if(nzchar(Sys.getenv("SYLVOSTATION_SKIP_GRASS")), "SYLVOSTATION_SKIP_GRASS defini")
  # vallee : fond plat (x = 980300 +/- 200 m), versants a 0,3 (17 degres)
  d <- make_synth_dtm(nc = 24, res = 25, fun = function(x, y) {
    100 + 0.3 * pmax(0, abs(x - 980300) - 200) + 0.002 * (y - 6800000)
  })
  m <- sylvostation:::.mrvbf_grass(d)
  expect_equal(as.vector(terra::ext(m)), as.vector(terra::ext(d)))
  expect_equal(terra::res(m), terra::res(d))
  sol <- terra::cellFromXY(d, cbind(980312.5, 6800312.5))     # x = est, y = nord
  vers <- terra::cellFromXY(d, cbind(980012.5, 6800312.5))
  expect_equal(unname(terra::xyFromCell(d, sol)[1, ]), c(980312.5, 6800312.5))
  expect_gt(m[sol][[1]], 1)
  expect_lt(m[vers][[1]], 0.1)
})

# ---- solar_factor (mission 021) -----------------------------------------------------

test_that(".aspect_to_rsun : azimut depuis le nord (horaire) vers r.sun (270 = sud)", {
  # nord, est, sud, ouest (convention de terra) -> 90, 0, 270, 180 (convention r.sun)
  expect_equal(sylvostation:::.aspect_to_rsun(c(0, 90, 180, 270)), c(90, 0, 270, 180))
  expect_equal(sylvostation:::.aspect_to_rsun(360), 90)
  expect_equal(sylvostation:::.aspect_to_rsun(135), 315)   # sud-est
  expect_true(is.na(sylvostation:::.aspect_to_rsun(NA_real_)))
})

test_that("solar_factor : sans GRASS, repli k = 1 signale (methode climatique)", {
  d <- make_synth_dtm(nc = 6)
  expect_warning(k <- solar_factor(d, grass = ""), "climatique",
                 class = "sylvostation_non_calcule")
  expect_identical(names(k), sprintf("k_%02d", 1:12))
  expect_true(all(terra::values(k) == 1))
  expect_identical(attr(k, "methode"), "climatique")
  expect_match(attr(k, "repli"), "GRASS")
  expect_match(attr(k, "parametres")$statut, "provisoire")
  expect_error(solar_factor(d, days = 1:3, grass = ""), "12 jours")
  expect_error(solar_factor(terra::project(d, "EPSG:4326"), grass = ""), "2154")
  # un executable qui n'ecrit rien : echec detecte, repli sans erreur
  faux <- Sys.which("true")
  skip_if(!nzchar(faux))
  expect_warning(k2 <- solar_factor(d, grass = faux), "r.sun", class = "sylvostation_non_calcule")
  expect_identical(attr(k2, "methode"), "climatique")
})

test_that("solar_factor (GRASS r.sun) : en hiver, versant sud > plat > versant nord", {
  skip_if(!nzchar(Sys.which("grass")), "GRASS absent")
  skip_if(nzchar(Sys.getenv("SYLVOSTATION_SKIP_GRASS")), "SYLVOSTATION_SKIP_GRASS defini")
  # crete est-ouest a y0 ; au sud, l'altitude croit vers le nord (versant expose au sud,
  # 30 degres), au nord elle decroit (versant expose au nord) ; un plateau plat a l'est.
  xmin <- 1010000
  ymin <- 6795000
  y0 <- ymin + 500
  d <- make_synth_dtm(nc = 40, res = 25, xmin = xmin, ymin = ymin, fun = function(x, y) {
    ifelse(x > xmin + 700, 800, 800 - tan(30 * pi / 180) * abs(y - y0))
  })
  k <- solar_factor(d, nprocs = 1)
  expect_identical(attr(k, "methode"), "r.sun")
  expect_identical(names(k), sprintf("k_%02d", 1:12))
  # points connus, x = est, y = nord (Lambert-93) : centres de cellules de 25 m
  sud <- c(xmin + 312.5, y0 - 237.5)
  nord <- c(xmin + 312.5, y0 + 237.5)
  plat <- c(xmin + 912.5, y0 + 12.5)
  cel <- terra::cellFromXY(k, rbind(sud, nord, plat))
  expect_equal(unname(terra::xyFromCell(k, cel[1])[1, ]), sud)
  expect_equal(unname(terra::rowColFromCell(k, cel[1])[1, ]), c(30, 13))   # ligne 1 = nord
  v <- unname(terra::values(k)[cel, ])
  # janvier (k_01) : versant sud > plat (environ 1) > versant nord
  expect_gt(v[1, 1], 1.5)
  expect_equal(v[3, 1], 1, tolerance = 0.02)
  expect_lt(v[2, 1], 0.6)
  # en juin, le contraste est bien plus faible qu'en janvier
  expect_lt(abs(v[1, 6] - v[2, 6]), abs(v[1, 1] - v[2, 1]))
  # pourtour (pente inconnue) : NA
  expect_true(all(is.na(terra::values(k)[terra::cellFromRowCol(k, 1, 1:40), 1])))
})

test_that("solar_factor : k est une variable fine, refusee aux placettes IFN", {
  ifn <- mark_ifn(data.frame(x = 1015500, y = 6793500))
  expect_error(assert_no_fine_extract_on_ifn(ifn, sprintf("k_%02d", 1:12)), "IFN")
  expect_error(assert_no_fine_extract_on_ifn(ifn, "k_sv"), "IFN")
})
