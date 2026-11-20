# Mission 039 : RU tiree de SoilGrids (diagnostic) et RU apprise, MNT BD ALTI de 250 m,
# bilan lateral (Piedallu et al. 2006, tableau 20). Rasters fabriques en memoire ou dans
# tempdir() (aucun telechargement : lecteurs et telechargeurs remplaces).

grille_sg <- function(v = 1, nl = 1) {
  terra::rast(xmin = 1000000, xmax = 1010000, ymin = 6800000, ymax = 6810000,
              resolution = 250, crs = "EPSG:2154", nlyrs = nl, vals = v)
}
cu_const <- function(v = 1) {
  r <- grille_sg(v, 6)
  names(r) <- sprintf("cu_%d_%d", c(0, 5, 15, 30, 60, 100), c(5, 15, 30, 60, 100, 200))
  r
}
pts_ifn <- function(x, y, ...) {
  mark_ifn(sf::st_sf(id_placette = paste0("p", seq_along(x)), ...,
                     geometry = sf::st_sfc(lapply(seq_along(x), function(i) sf::st_point(c(x[i], y[i]))),
                                           crs = 2154)))
}

test_that("coarse_disk_mean : couche coarse_, maille >= 250 m, rayon >= 700 m", {
  r <- grille_sg(3)
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  terra::values(r) <- ifelse(xy[, 1] < 1005000, 2, 4)          # ouest 2, est 4 (x = est)
  m <- coarse_disk_mean(r, name = "coarse_x_700m")
  expect_identical(names(m), "coarse_x_700m")
  expect_equal(raster_at_points(pts_ifn(1002000, 6805000), m)$coarse_x_700m, 2)
  expect_equal(raster_at_points(pts_ifn(1008000, 6805000), m)$coarse_x_700m, 4)
  expect_error(coarse_disk_mean(r, name = "x_700m"), "coarse_")
  expect_error(coarse_disk_mean(r, 500, name = "coarse_x"), "700")
  expect_error(coarse_disk_mean(terra::disagg(r, 5), name = "coarse_x"), "250")
  # soilgrids_disk_mean garde son nom (mission 035)
  expect_identical(names(soilgrids_disk_mean(r)), "coarse_ph_soilgrids_700m")
})

test_that("fetch_soilgrids_texture : 24 couches, URL par propriete, pourcentages", {
  d <- tempfile("sgt")
  urls <- character(0)
  lecteur <- function(url) {
    urls <<- c(urls, url)
    c3035 <- sf::st_coordinates(sf::st_transform(
      sf::st_sfc(sf::st_point(c(1001000, 6801000)), crs = 2154), 3035))
    r <- terra::rast(xmin = c3035[1] - 50000, xmax = c3035[1] + 50000, ymin = c3035[2] - 50000,
                     ymax = c3035[2] + 50000, resolution = 1000, crs = "EPSG:3035",
                     vals = 250)                                  # 25 % x 10
    terra::metags(r) <- c(synthetic = "TRUE")
    r
  }
  bb <- c(1000000, 6800000, 1002000, 6802000)
  f <- fetch_soilgrids_texture(bb, d, reader = lecteur)
  expect_length(f, 24)
  expect_true(all(c("clay_0-5cm", "cfvo_100-200cm") %in% names(f)))
  expect_true(any(grepl("/clay/clay_0-5cm_mean\\.vrt$", urls)))
  expect_true(any(grepl("/cfvo/cfvo_60-100cm_mean\\.vrt$", urls)))
  v <- terra::values(terra::rast(f[["sand_30-60cm"]]), mat = FALSE)
  expect_equal(unique(round(v[!is.na(v)], 6)), 25)
  expect_error(fetch_soilgrids_ph(bb, d, layer = "bdod_0-5cm_mean"), "layer")
})

test_that("soilgrids_cu : euptf2 par horizon, cailloux retranches", {
  skip_if_not_installed("euptf2")
  mk <- function(cf) {
    L <- lapply(c("clay", "sand", "silt", "cfvo"), function(p) {
      r <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000500, ymin = 6.8e6,
                       ymax = 6800500, crs = "EPSG:2154", nlyrs = 6,
                       vals = switch(p, clay = 20, sand = 40, silt = 40, cfvo = cf))
      names(r) <- paste0(p, "_", c("0-5", "5-15", "15-30", "30-60", "60-100", "100-200"), "cm_mean")
      r
    })
    do.call(c, L)
  }
  a <- soilgrids_cu(mk(0))
  b <- soilgrids_cu(mk(50))
  expect_identical(names(a), sprintf("cu_%d_%d", c(0, 5, 15, 30, 60, 100), c(5, 15, 30, 60, 100, 200)))
  va <- terra::values(a)
  expect_true(all(va > 0.3 & va < 5))   # mm d'eau par cm de sol (pF 2,0 - 4,2)
  expect_equal(terra::values(b), va / 2)
  expect_error(soilgrids_cu(mk(0)[[1:10]]), "absentes")
})

test_that("ru_soilgrids : somme capacite x epaisseur jusqu'a la profondeur", {
  expect_equal(ru_soilgrids(matrix(1, 2, 6), c(50, 100)), c(50, 100))
  expect_equal(ru_soilgrids(matrix(1, 1, 6), 200), 200)
  r <- ru_soilgrids(cu_const(1.5), 100)
  expect_identical(names(r), "ru_soilgrids_100cm")
  expect_equal(unique(terra::values(r)[, 1]), 150)
  expect_error(ru_soilgrids(matrix(1, 1, 6), 300), "200")
  expect_error(ru_soilgrids(matrix(1, 1, 5), 50), "six")
})

test_that("coarse_cu_layers et layers_at_points : couches larges, regle des 700 m", {
  c7 <- coarse_cu_layers(cu_const(1))
  expect_identical(names(c7), sprintf("coarse_cu_%d_%d_700m", c(0, 5, 15, 30, 60, 100),
                                      c(5, 15, 30, 60, 100, 200)))
  p <- layers_at_points(pts_ifn(1005000, 6805000), c7)
  expect_equal(p$coarse_cu_0_5_700m, 1)
  fine <- cu_const(1)[[1]]
  expect_error(layers_at_points(pts_ifn(1005000, 6805000), fine), "IFN|interdite")
  expect_error(coarse_cu_layers(grille_sg()), "soilgrids_cu")
})

test_that("ru_learned_data et ru_soilgrids_diagnostic : placettes completes, biais mesure", {
  c7 <- coarse_cu_layers(cu_const(1))
  p <- pts_ifn(c(1004000, 1005000, 1006000), c(6805000, 6805000, 6805000),
               ru_mm = c(100, 120, NA), coarse_litho_enc = 1, coarse_formation_enc = 2)
  l <- ru_learned_data(p, c7)
  expect_equal(nrow(l$data), 2)
  expect_equal(l$retirees, 1)
  expect_identical(l$vars, c("coarse_litho_enc", "coarse_formation_enc", names(c7)))
  d <- ru_soilgrids_diagnostic(p[1:2, ], c7, depths = c(50, 100))
  expect_equal(d$ru_sg_moy, c(50, 100))
  expect_equal(d$biais, c(-60, -10))
  expect_equal(d$n, c(2, 2))
  expect_error(ru_learned_data(sf::st_drop_geometry(p), c7), "sf")
})

test_that("fetch_mnt_large : tuiles du WMS BD ALTI agregees a 250 m, cache, hors ligne", {
  d <- tempfile("bdalti")
  appels <- character(0)
  tele <- function(url, destfile) {
    appels <<- c(appels, url)
    w <- as.integer(sub(".*WIDTH=([0-9]+).*", "\\1", url))
    h <- as.integer(sub(".*HEIGHT=([0-9]+).*", "\\1", url))
    r <- terra::rast(nrows = h, ncols = w, xmin = 0, xmax = w, ymin = 0, ymax = h, vals = 300)
    r[1] <- -99999                                           # absence de donnee
    terra::writeRaster(r, destfile, overwrite = TRUE)
  }
  bb <- c(1000000, 6800000, 1004000, 6803000)
  f <- fetch_mnt_large(bb, d, margin_m = 0, downloader = tele)
  expect_length(appels, 1)
  expect_match(appels, "LAYERS=ELEVATION\\.ELEVATIONGRIDCOVERAGE")
  expect_match(appels, "CRS=EPSG:2154")
  expect_match(appels, "BBOX=1000000,6800000,1004000,6803000")
  r <- terra::rast(f)
  expect_equal(terra::res(r), c(250, 250))
  expect_equal(as.vector(terra::ext(r)), c(1000000, 1004000, 6800000, 6803000), ignore_attr = TRUE)
  expect_identical(names(r), "mnt_250")
  v <- terra::values(r)[, 1]
  expect_equal(unique(v), 300)                               # la cellule -99999 est ignoree
  expect_identical(fetch_mnt_large(bb, d, margin_m = 0, downloader = tele), f)
  expect_length(appels, 1)
  expect_error(fetch_mnt_large(c(1100000, 6900000, 1101000, 6901000), d, offline = TRUE), "hors ligne")
  expect_error(fetch_mnt_large(bb, d, res = 10), "50")
})

test_that("lateral_balance : classes 1 a 3, equivalents en RU, couches fines", {
  f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
  skip_if(!nzchar(f))
  dtm <- terra::rast(f)
  cf0 <- sylvostation:::.CONFIG_REEL_DEFAUTS$bilan_lateral_coef
  b <- lateral_balance(dtm, cf0)
  expect_true(all(c("curv150", "idr_1500", "moore", "bilan_lateral", "ru_bilan_lateral") %in% names(b)))
  v <- terra::values(b)
  cl <- v[, "bilan_lateral"]
  expect_true(all(cl[!is.na(cl)] %in% 1:3))
  expect_true(all(v[!is.na(cl), "ru_bilan_lateral"] %in% c(-30, 0, 60)))
  p <- v[stats::complete.cases(v), c("p_depart", "p_equilibre", "p_apports")]
  expect_equal(unname(rowSums(p)), rep(1, nrow(p)))
  expect_equal(sum(attr(b, "parts")), 1)
  for (n in c("curv150", "idr_1500", "moore", "bilan_lateral", "ru_bilan_lateral")) {
    expect_error(assert_no_fine_extract_on_ifn(mark_ifn(data.frame(x = 1)), n), "IFN")
  }
  # coefficient tres favorable au depart : tout part
  cf <- cf0
  cf$depart[["constante"]] <- 50
  expect_equal(attr(lateral_balance(dtm, coef = cf), "parts")[["depart"]], 1)
  expect_error(lateral_balance(dtm, coef = list(depart = 1)), "coef")
  expect_error(lateral_balance(terra::aggregate(dtm, 10), cf0), "50")
  expect_error(lateral_balance(dtm), "coef")
})
