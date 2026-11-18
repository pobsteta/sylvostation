pts_precis <- function(n = 2) {
  data.frame(x = 1010000 + seq_len(n), y = 6795000, loc_precision_m = 10)
}

test_that("la règle bloquante bloque les variables fines sur des placettes IFN", {
  p <- mark_ifn(data.frame(x = 1010000, y = 6795000))
  for (v in c("pente", "TWI", "mrvbf", "lidar_p95", "mnt", "mhc", "courbure_plan")) {
    expect_error(assert_no_fine_extract_on_ifn(p, v), "interdite")
  }
  expect_error(assert_no_fine_extract_on_ifn(p, c("coarse_climat", "pente")), "pente")
})

test_that("mark_ifn pose source et loc_precision_m = 700", {
  p <- mark_ifn(data.frame(x = 1, y = 2))
  expect_equal(p$source, "ifn")
  expect_equal(p$loc_precision_m, 700)
  expect_equal(attr(p, "source"), "ifn")
})

test_that("IFN + variables coarse_ passe", {
  p <- mark_ifn(data.frame(x = 1, y = 2))
  expect_true(assert_no_fine_extract_on_ifn(p, c("coarse_climat", "pedopaysage")))
})

test_that("variable inconnue refusée par prudence sur IFN", {
  p <- mark_ifn(data.frame(x = 1, y = 2))
  expect_error(assert_no_fine_extract_on_ifn(p, "inconnue"), "non reconnues")
})

test_that("des points précis (10 m) peuvent recevoir des variables fines", {
  expect_true(assert_no_fine_extract_on_ifn(pts_precis(), c("pente", "twi")))
})

test_that("marquage perdu après jointure mais précision 700 conservée : bloqué", {
  ifn <- data.frame(id = 1:2, x = 1, y = 2, loc_precision_m = 700)  # pas de source
  expect_error(assert_no_fine_extract_on_ifn(ifn, "pente"), "interdite")
  # via merge : colonne source et attribut perdus
  m <- merge(data.frame(id = 1:2, a = 3:4), mark_ifn(data.frame(id = 1:2, x = 1, y = 2)),
             by = "id")
  attr(m, "source") <- NULL
  m$source <- NULL
  expect_error(assert_no_fine_extract_on_ifn(m, "pente"), "interdite")
})

test_that("mélange IFN + points à 10 m : bloqué", {
  melange <- rbind(pts_precis(2)[, c("x", "y", "loc_precision_m")],
                   data.frame(x = 5, y = 6, loc_precision_m = 700))
  expect_error(assert_no_fine_extract_on_ifn(melange, "pente"), "interdite")
})

test_that("précision absente ou NA : bloqué", {
  expect_error(assert_no_fine_extract_on_ifn(data.frame(x = 1, y = 2), "pente"),
               "interdite")
  p <- pts_precis(2)
  p$loc_precision_m[2] <- NA
  expect_error(assert_no_fine_extract_on_ifn(p, "pente"), "interdite")
  expect_error(assert_no_fine_extract_on_ifn(matrix(1:4, 2), "pente"), "interdite")
})

test_that("max_precision_m est paramétrable et validé", {
  p <- pts_precis()
  expect_error(assert_no_fine_extract_on_ifn(p, "pente", max_precision_m = 5), "interdite")
  expect_true(assert_no_fine_extract_on_ifn(p, "pente", max_precision_m = 10))
  expect_error(assert_no_fine_extract_on_ifn(p, "pente", max_precision_m = -1), "positif")
})

test_that("le marquage IFN fonctionne par attribut, par colonne ou sur sf", {
  p_attr <- pts_precis()
  attr(p_attr, "source") <- "ifn"
  expect_error(assert_no_fine_extract_on_ifn(p_attr, "pente"))
  p_col <- cbind(pts_precis(), source = c("autre", "ifn"))
  expect_error(assert_no_fine_extract_on_ifn(p_col, "pente"))
  p_sf <- mark_ifn(sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(1, 2)), crs = 2154)))
  expect_error(assert_no_fine_extract_on_ifn(p_sf, "pente"))
  expect_error(assert_no_fine_extract_on_ifn(p_sf[1, ], "pente"))
})

test_that("variables invalides refusées", {
  expect_error(assert_no_fine_extract_on_ifn(data.frame(), 1), "caract")
})

test_that("assert_crs_2154 accepte le Lambert-93 et refuse le reste", {
  pt <- sf::st_sfc(sf::st_point(c(1010000, 6795000)), crs = 2154)
  expect_invisible(assert_crs_2154(pt))
  expect_invisible(assert_crs_2154(sf::st_sf(id = 1, geometry = pt)))
  expect_error(assert_crs_2154(sf::st_transform(pt, 4326)), "2154")
  expect_error(assert_crs_2154(sf::st_sfc(sf::st_point(c(1, 2)))), "absent")
  expect_error(assert_crs_2154(1:3), "doit")
})

test_that("assert_crs_2154 refuse x/y inversés", {
  inv <- sf::st_sfc(sf::st_point(c(6795000, 1010000)), crs = 2154)
  expect_error(assert_crs_2154(inv), "implausibles")
})

test_that("assert_crs_2154 refuse des degrés étiquetés 2154", {
  deg <- sf::st_sfc(sf::st_point(c(5.7, 45.2)), crs = 2154)
  expect_error(assert_crs_2154(deg), "implausibles")
  r <- terra::rast(xmin = 5, xmax = 6, ymin = 45, ymax = 46, resolution = 0.5,
                   crs = "EPSG:2154")
  expect_error(assert_crs_2154(r), "implausibles")
})

test_that("assert_crs_2154 gère les rasters terra", {
  r <- terra::rast(xmin = 1007000, xmax = 1007100, ymin = 6790000, ymax = 6790100,
                   resolution = 25, crs = "EPSG:2154")
  expect_invisible(assert_crs_2154(r))
  r4326 <- terra::rast(xmin = 0, xmax = 1, ymin = 40, ymax = 41, resolution = 0.5,
                       crs = "EPSG:4326")
  expect_error(assert_crs_2154(r4326), "2154")
})

test_that("un point connu tombe dans la bonne cellule de la grille Lambert-93", {
  # x = est, y = nord ; grille de 25 m dont le coin sud-ouest est (1007000, 6790000)
  r <- terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
                   resolution = 25, crs = "EPSG:2154")
  cell <- terra::cellFromXY(r, cbind(1007030, 6804990))
  expect_equal(terra::rowFromCell(r, cell), 1)   # ligne 1 = bord nord
  expect_equal(terra::colFromCell(r, cell), 2)
  expect_equal(unname(terra::xyFromCell(r, cell)[1, ]), c(1007037.5, 6804987.5))
})

test_that("les constantes de variables sont cohérentes", {
  expect_length(intersect(tolower(FINE_VARIABLES), tolower(COARSE_VARIABLES)), 0)
})

test_that("couches de la carte hydrique de 25 m : fines (mission 021)", {
  noms <- c(sprintf("k_%02d", 1:12), "k_sv", "is_topo", "nj_topo", "is_plat", "grad_hydrique_25m")
  expect_true(all(noms %in% FINE_VARIABLES))
  expect_true(sylvostation:::.is_fine("k_autre"))   # prefixe k_
  # l'indice des placettes (maille SAFRAN, sans k) reste a maille large : pas fin
  expect_false(any(c("is_biljou", "nj_stress", "grad_hydrique") %in% FINE_VARIABLES))
  p <- mark_ifn(data.frame(x = 1015500, y = 6793500))
  for (v in noms) expect_error(assert_no_fine_extract_on_ifn(p, v), "IFN")
  ok <- data.frame(x = 1015500, y = 6793500, loc_precision_m = 5)
  for (v in noms) expect_true(assert_no_fine_extract_on_ifn(ok, v))
})
