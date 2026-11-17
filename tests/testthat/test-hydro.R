extrait <- function() {
  system.file("extdata", "topage_troncons_extrait.gpkg", package = "sylvostation")
}
emprise_extrait <- c(xmin = 1014500, ymin = 6792500, xmax = 1016500, ymax = 6794500)

test_that("get_hydro_network (fichier) : lignes en EPSG:2154, colonnes TOPAGE, sans fictifs", {
  skip_if(!nzchar(extrait()))
  r <- get_hydro_network(emprise_extrait, source = "file", path = extrait())
  expect_s3_class(r, "sf")
  expect_gt(nrow(r), 0)
  assert_crs_2154(r)
  expect_true(all(c("CdOH", "NatureTH", "PersistanceTH") %in% names(r)))
  expect_true(all(as.character(sf::st_geometry_type(r)) %in%
                    c("LINESTRING", "MULTILINESTRING")))
  expect_false(any(tolower(as.character(r$TronconFictifTH)) %in% "true"))
  # coordonnees en Lambert-93 (x = est ~ 1,0e6 ; y = nord ~ 6,79e6), pas lon/lat
  bb <- sf::st_bbox(r)
  expect_true(bb[["xmin"]] > 1e6 && bb[["ymin"]] > 6.7e6)
})

test_that("get_hydro_network : le filtre d'emprise ecarte les troncons hors boite", {
  skip_if(!nzchar(extrait()))
  tous <- get_hydro_network(emprise_extrait, source = "file", path = extrait())
  loin <- get_hydro_network(c(1100000, 6900000, 1101000, 6901000), source = "file",
                            path = extrait())
  expect_equal(nrow(loin), 0L)
  b <- sf::st_bbox(tous[1, ])
  un <- get_hydro_network(b, source = "file", path = extrait())
  expect_true(tous$CdOH[1] %in% un$CdOH)
})

test_that("get_hydro_network : entrees refusees", {
  skip_if(!nzchar(extrait()))
  expect_error(get_hydro_network(emprise_extrait, source = "file", path = "absent.gpkg"),
               "path")
  expect_error(get_hydro_network(c(xmin = 1, ymin = 1, xmax = 0, ymax = 0),
                                 source = "file", path = extrait()), "invers")
  wgs <- sf::st_sfc(sf::st_point(c(7.2, 48.2)), crs = 4326)
  expect_error(get_hydro_network(wgs, source = "file", path = extrait()))
})

test_that(".wfs_url : parametres encodes, BBOX Lambert-93 en urn", {
  u <- sylvostation:::.wfs_url("https://exemple.test/wfs",
                               c(SERVICE = "WFS", BBOX = "1,2,3,4,urn:ogc:def:crs:EPSG::2154"))
  expect_match(u, "^https://exemple.test/wfs\\?SERVICE=WFS&BBOX=1%2C2%2C3%2C4%2Curn%3A")
})

test_that(".filter_network ecarte les troncons fictifs seulement", {
  l <- sf::st_sfc(sf::st_linestring(rbind(c(0, 0), c(1, 0))), crs = 2154)
  x <- sf::st_sf(TronconFictifTH = c("false", "true", "FALSE"), geometry = c(l, l, l))
  expect_equal(nrow(sylvostation:::.filter_network(x)), 2L)
})

test_that("height_above_network : plan et ruisseau a y connu, nom de couche", {
  d <- make_synth_dtm(nc = 40, res = 10)
  y0 <- 6800000 + 195   # centre d'une rangee de cellules
  ln <- terra::vect(cbind(id = 1, part = 1, x = c(980000, 980400), y = c(y0, y0)),
                    type = "lines", crs = "EPSG:2154")
  h <- height_above_network(d, ln)
  expect_equal(names(h), "hauteur_reseau")
  expect_equal(as.vector(terra::ext(h)), as.vector(terra::ext(d)))
  c_n <- terra::cellFromXY(d, cbind(980205, y0 + 50))   # x = est, y = nord : 50 m au nord
  c_s <- terra::cellFromXY(d, cbind(980205, y0 - 50))
  c_r <- terra::cellFromXY(d, cbind(980205, y0))        # la cellule du ruisseau
  expect_equal(h[c_n][[1]], 5, tolerance = 1e-6)
  expect_true(is.na(h[c_s][[1]]))   # en aval du reseau : NA, jamais negatif
  expect_equal(h[c_r][[1]], 0, tolerance = 1e-6)
  h2 <- height_above_network(d, sf::st_as_sf(ln))
  expect_equal(terra::values(h2), terra::values(h))
  out <- suppressWarnings(derive_terrain(d, tpi_radii = 50, streams = ln))
  expect_equal(terra::values(out$hauteur_reseau, mat = FALSE), terra::values(h, mat = FALSE))
})

test_that("height_above_network : extrait TOPAGE reel sur un MNT synthetique du meme carre", {
  skip_if(!nzchar(extrait()))
  net <- get_hydro_network(emprise_extrait, source = "file", path = extrait())
  d <- make_synth_dtm(nc = 80, res = 25, xmin = 1014500, ymin = 6792500)  # 2 km, 25 m
  h <- height_above_network(d, net)
  v <- terra::values(h, mat = FALSE)
  expect_true(any(!is.na(v)))
  expect_true(all(v[!is.na(v)] >= 0))
  # un point de troncon tombe sur une cellule de hauteur 0
  pt <- sf::st_coordinates(sf::st_line_sample(sf::st_geometry(net)[1], sample = 0.5))[1, 1:2]
  cell <- terra::cellFromXY(d, cbind(pt[["X"]], pt[["Y"]]))
  skip_if(is.na(cell))
  expect_equal(h[cell][[1]], 0, tolerance = 1e-6)
})

test_that("height_above_network : refus (CRS, type) et aucun troncon => NA avec avertissement", {
  d <- make_synth_dtm(nc = 20, res = 10)
  pts <- terra::vect(cbind(980050, 6800050), crs = "EPSG:2154")
  expect_error(height_above_network(d, pts), "lignes")
  ln_wgs <- terra::vect(cbind(id = 1, part = 1, x = c(7, 7.1), y = c(48, 48)),
                        type = "lines", crs = "EPSG:4326")
  expect_error(height_above_network(d, ln_wgs))
  hors <- terra::vect(cbind(id = 1, part = 1, x = c(1100000, 1100100), y = c(6900000, 6900000)),
                      type = "lines", crs = "EPSG:2154")
  expect_warning(h <- height_above_network(d, hors), class = "sylvostation_non_calcule")
  expect_true(all(is.na(terra::values(h))))
  expect_error(height_above_network(1, hors), "SpatRaster")
})

test_that("HAND : vallon synthetique, trace decale d'une cellule, aucune valeur negative dans le fond", {
  # vallon en V nord-sud : thalweg en x = 980205 (centre de cellule), fond qui descend vers
  # le sud, versants a 0,3. Le trace passe une cellule a l'est du thalweg (x = 980215) :
  # l'erreur de calage typique du reseau. A vol d'oiseau, le fond serait negatif.
  d <- make_synth_dtm(nc = 40, res = 10, xmin = 980000, ymin = 6800000,
                      fun = function(x, y) 100 + 0.3 * abs(x - 980205) + 0.05 * (y - 6800000))
  ln <- terra::vect(cbind(id = 1, part = 1, x = c(980215, 980215), y = c(6800000, 6800400)),
                    type = "lines", crs = "EPSG:2154")
  h <- height_above_network(d, ln)
  v <- terra::values(h, mat = FALSE)
  expect_true(any(!is.na(v)))
  expect_true(all(v[!is.na(v)] >= 0))                    # jamais negatif
  fond <- terra::cellFromXY(d, cbind(980205, seq(6800005, 6800395, by = 10)))
  expect_true(all(is.na(v[fond]) | v[fond] >= 0))         # le fond, plus bas que le trace
  trace <- terra::cellFromXY(d, cbind(980215, 6800205))   # x = est, y = nord
  expect_equal(h[trace][[1]], 0, tolerance = 1e-9)
  versant_est <- terra::cellFromXY(d, cbind(980255, 6800205))   # 4 cellules a l'est du trace
  expect_equal(h[versant_est][[1]], 0.3 * 40, tolerance = 1e-6)
})
