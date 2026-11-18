# Mission 003 : get_ser(), build_grid(), list_tiles(). Aucun test ne touche au réseau.

emprise_test <- c(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000)

# --- build_grid ----------------------------------------------------------------
test_that("build_grid : bords arrondis vers l'extérieur sur des multiples de res", {
  g <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099), res = 25)
  expect_s4_class(g, "SpatRaster")
  expect_equal(as.vector(terra::ext(g)), c(xmin = 1007000, xmax = 1007200, ymin = 6790000, ymax = 6790100))
  expect_equal(terra::res(g), c(25, 25))
  expect_equal(dim(g)[1:2], c(4, 8))
  expect_false(terra::hasValues(g))
  expect_true(sf::st_crs(terra::crs(g)) == sf::st_crs(2154))
})

test_that("build_grid : un point connu en Lambert-93 tombe dans la bonne cellule", {
  g <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099), res = 25)
  # x = 1007030 est dans [1007025 ; 1007050[ (2e colonne), y = 6790080 dans [6790075 ; 6790100[
  # (1re ligne en partant du nord).
  cell <- terra::cellFromXY(g, cbind(1007030, 6790080))
  expect_equal(unname(terra::rowColFromCell(g, cell)), cbind(1, 2))
  expect_equal(unname(terra::xyFromCell(g, cell)[1, ]), c(1007037.5, 6790087.5))
  # Un point au sud-ouest : 4e ligne, 1re colonne.
  cell2 <- terra::cellFromXY(g, cbind(1007001, 6790001))
  expect_equal(unname(terra::rowColFromCell(g, cell2)), cbind(4, 1))
  # Un point hors de la grille n'a pas de cellule.
  expect_true(is.na(terra::cellFromXY(g, cbind(1007300, 6790080))))
})

test_that("build_grid : deux emprises différentes donnent des grilles alignées", {
  g1 <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099), 25)
  g2 <- build_grid(c(xmin = 1007111, ymin = 6790060, xmax = 1007333, ymax = 6790222), 25)
  expect_equal((terra::xmin(g2) - terra::xmin(g1)) %% 25, 0)
  expect_equal((terra::ymin(g2) - terra::ymin(g1)) %% 25, 0)
})

test_that("build_grid accepte sf, sfc et bbox, et refuse CRS et x/y erronés", {
  poly <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099),
                                    crs = sf::st_crs(2154)))
  expect_equal(unname(as.vector(terra::ext(build_grid(poly, 25)))), c(1007000, 1007200, 6790000, 6790100))
  expect_equal(unname(as.vector(terra::ext(build_grid(sf::st_sf(geometry = poly), 25)))),
               c(1007000, 1007200, 6790000, 6790100))
  expect_equal(unname(as.vector(terra::ext(build_grid(sf::st_bbox(poly), 25)))),
               c(1007000, 1007200, 6790000, 6790100))
  # Mauvais CRS
  expect_error(build_grid(sf::st_transform(poly, 4326), 25), "2154")
  # x/y inversés (nord donné comme est)
  expect_error(build_grid(c(xmin = 6790010, ymin = 1007003, xmax = 6790099, ymax = 1007180), 25),
               "implausibles")
  expect_error(build_grid(c(1007180, 6790099, 1007003, 6790010), 25), "vide ou invers")
  expect_error(build_grid(emprise_test, res = 0), "res")
  expect_error(build_grid("1,2,3,4", res = 25), "emprise")
})

# --- get_ser -------------------------------------------------------------------
ser_gpkg <- function() system.file("extdata", "ser_extrait.gpkg", package = "sylvostation")

test_that("get_ser (fichier) : D11 en EPSG:2154 avec champs codeser et NomSER", {
  skip_if(!nzchar(ser_gpkg()))
  d11 <- get_ser("D11", source = "file", path = ser_gpkg())
  expect_s3_class(d11, "sf")
  expect_equal(nrow(d11), 1L)
  expect_equal(d11$codeser, "D11")
  expect_equal(d11$NomSER, "Massif vosgien central")
  expect_true(sf::st_crs(d11) == sf::st_crs(2154))
  # Un point du massif test (1015000, 6797000), en D11 (docs/referentiels.md, § 1)
  pt <- sf::st_sfc(sf::st_point(c(1015000, 6797000)), crs = 2154)
  expect_true(sf::st_intersects(pt, d11, sparse = FALSE)[1, 1])
  # Un point de la plaine d'Alsace (x = 1050000, y = 6800000) n'y est pas
  loin <- sf::st_sfc(sf::st_point(c(1060000, 6800000)), crs = 2154)
  expect_false(sf::st_intersects(loin, d11, sparse = FALSE)[1, 1])
})

test_that("get_ser (fichier) : le tampon agrandit le contour", {
  skip_if(!nzchar(ser_gpkg()))
  a0 <- sf::st_area(get_ser("D12", 0, source = "file", path = ser_gpkg()))
  a5 <- sf::st_area(get_ser("D12", 5000, source = "file", path = ser_gpkg()))
  expect_gt(as.numeric(a5), as.numeric(a0))
  p <- sf::st_sfc(sf::st_point(c(1060000, 6800000)), crs = 2154)
  d0 <- get_ser("D11", 0, source = "file", path = ser_gpkg())
  dist0 <- as.numeric(sf::st_distance(p, d0))
  d5 <- get_ser("D11", 5000, source = "file", path = ser_gpkg())
  expect_equal(as.numeric(sf::st_distance(p, d5)), max(dist0 - 5000, 0), tolerance = 1)
})

test_that("get_ser : code inconnu, tampon négatif, chemin absent", {
  skip_if(!nzchar(ser_gpkg()))
  expect_error(get_ser("ZZ9", source = "file", path = ser_gpkg()), "absente.*D11")
  expect_error(get_ser("D11", buffer_m = -1, source = "file", path = ser_gpkg()), "buffer_m")
  expect_error(get_ser("D11", source = "file"), "path")
  expect_error(get_ser("D11", source = "file", path = "n_existe_pas.zip"), "introuvable")
  expect_error(get_ser(c("D11", "D12"), source = "file", path = ser_gpkg()), "ser_code")
})

test_that("get_ser (shapefile WINDOWS-1252) : accents corrects, synthétique", {
  d <- file.path(tempdir(), "synth_ser_shp")
  dir.create(d, showWarnings = FALSE)
  shp <- file.path(d, "synth_ser.shp")
  carre <- sf::st_sfc(sf::st_polygon(list(rbind(c(1e6, 6.8e6), c(1.01e6, 6.8e6), c(1.01e6, 6.81e6),
                                                c(1e6, 6.81e6), c(1e6, 6.8e6)))), crs = 2154)
  x <- sf::st_sf(codeser = "D12", NomSER = "Collines périvosgiennes et Warndt",
                 synthetic = TRUE, geometry = carre)
  sf::st_write(x, shp, layer_options = "ENCODING=WINDOWS-1252", quiet = TRUE)
  r <- get_ser("D12", source = "file", path = shp)
  expect_equal(r$NomSER, "Collines périvosgiennes et Warndt")
  expect_equal(as.numeric(sf::st_area(r)), 1e4 * 1e4)
})

# --- list_tiles ----------------------------------------------------------------
# Métadonnée synthétique (synthetic = TRUE, géométries décalées de 4,7 mm comme la réelle) imitant les champs de
# IGNF_LIDAR-HD_METADONNEE:metadata : 4 dalles dans l'emprise, 2 qui ne font que la
# toucher, 1 lointaine.
synth_meta <- function() {
  ids <- c("1014-6794", "1015-6794", "1014-6793", "1015-6793", "1016-6794", "1030-6800", "1014-6792")
  x0 <- as.numeric(substr(ids, 1, 4)) * 1000
  y1 <- as.numeric(substr(ids, 6, 9)) * 1000 + 0.0047 # décalage de géométrie comme dans la métadonnée réelle
  geo <- lapply(seq_along(ids), function(i) {
    sf::st_polygon(list(rbind(c(x0[i], y1[i] - 1000), c(x0[i] + 1000, y1[i] - 1000),
                              c(x0[i] + 1000, y1[i]), c(x0[i], y1[i]), c(x0[i], y1[i] - 1000))))
  })
  sf::st_sf(
    coordonnees_nw = ids,
    url_npl = paste0("https://exemple.invalide/LHD_FXX_", sub("-", "_", ids), "_PTS.copc.laz"),
    url_mnt = paste0("https://exemple.invalide/mnt_", ids),
    date_debut_acquisition = as.Date("2022-01-13"),
    date_fin_acquisition = as.Date(c("2022-01-13", "2022-04-21", rep("2022-01-13", 5))),
    nombre_points = 1e7,
    synthetic = TRUE,
    geometry = sf::st_sfc(geo, crs = 2154)
  )
}

test_that("list_tiles (fichier) : dalles qui recoupent l'emprise, pas celles qui la touchent", {
  f <- file.path(tempdir(), "synth_meta.gpkg")
  sf::st_write(synth_meta(), f, quiet = TRUE, delete_dsn = TRUE)
  t <- list_tiles(c(xmin = 1014000, ymin = 6792000, xmax = 1016000, ymax = 6794000),
                  source = "file", path = f)
  expect_s3_class(t, "sf")
  expect_equal(t$tile_id, c("1014-6793", "1014-6794", "1015-6793", "1015-6794"))
  expect_named(t, c("tile_id", "url", "url_mnt", "date_debut", "date_fin", "nombre_points", "geometry"),
               ignore.order = TRUE)
  expect_s3_class(t$date_fin, "Date")
  expect_equal(t$date_fin[t$tile_id == "1015-6794"], as.Date("2022-04-21"))
  expect_match(t$url, "^https://exemple.invalide/LHD_FXX_\\d{4}_\\d{4}_PTS.copc.laz$")
  expect_true(sf::st_crs(t) == sf::st_crs(2154))
  # Le test d'appartenance : la dalle 1015-6794 couvre x [1015000 ; 1016000], y [6793000 ; 6794000]
  pt <- sf::st_sfc(sf::st_point(c(1015500, 6793500)), crs = 2154)
  hit <- sf::st_intersects(pt, t, sparse = FALSE)[1, ]
  expect_equal(t$tile_id[hit], "1015-6794")
})

test_that("list_tiles : aucune dalle, CRS erroné, chemin manquant", {
  f <- file.path(tempdir(), "synth_meta2.gpkg")
  sf::st_write(synth_meta(), f, quiet = TRUE, delete_dsn = TRUE)
  expect_error(list_tiles(c(xmin = 1100000, ymin = 6900000, xmax = 1101000, ymax = 6901000),
                          source = "file", path = f), "Aucune dalle")
  expect_error(list_tiles(sf::st_as_sfc(sf::st_bbox(c(xmin = 5, ymin = 45, xmax = 6, ymax = 46),
                                                    crs = sf::st_crs(4326)))), "2154")
  expect_error(list_tiles(emprise_test, source = "file"), "path")
})

test_that(".tiles_from_meta signale les champs manquants", {
  m <- synth_meta()
  m$url_npl <- NULL
  expect_error(sylvostation:::.tiles_from_meta(m, emprise_test), "url_npl")
})

test_that("build_grid a 20 m : bords multiples de 20, point connu dans la bonne cellule (Lambert-93)", {
  g <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007181, ymax = 6790099), res = 20)
  e <- terra::ext(g)
  expect_equal(unname(as.vector(e)), c(1007000, 1007200, 6790000, 6790100))
  expect_equal(unname(c(e$xmin, e$xmax, e$ymin, e$ymax) %% 20), c(0, 0, 0, 0))
  expect_equal(terra::res(g), c(20, 20))
  expect_equal(terra::crs(g, describe = TRUE)$code, "2154")
  # x = est 1007050 -> colonne floor(50 / 20) + 1 = 3 ; y = nord 6790030 ->
  # ligne floor((6790100 - 6790030) / 20) + 1 = 4 (ligne 1 = nord)
  cel <- terra::cellFromXY(g, cbind(1007050, 6790030))
  expect_equal(unname(terra::rowColFromCell(g, cel)), cbind(4, 3))
  # x et y inverses : hors de la grille
  expect_true(is.na(terra::cellFromXY(g, cbind(6790030, 1007050))))
  # deux emprises decalees : grilles superposables cellule a cellule
  g2 <- build_grid(c(xmin = 1007111, ymin = 6790060, xmax = 1007333, ymax = 6790222), 20)
  expect_equal((terra::xmin(g2) - terra::xmin(g)) %% 20, 0)
  expect_equal((terra::ymax(g2) - terra::ymax(g)) %% 20, 0)
})
