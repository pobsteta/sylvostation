# Mission 025 (ADR 0007) : grille de 20 m, comparaison a la reference.

test_that("comparison_res : plus petit multiple commun de resolution_m et de 50 m", {
  expect_equal(comparison_res(20), 100)
  expect_equal(comparison_res(25), 50)
  expect_equal(comparison_res(30), 150)
  expect_equal(comparison_res(50), 50)
  expect_error(comparison_res(0), "entiers")
  expect_error(comparison_res("20"), "entiers")
})

test_that("real_grid a 20 m : MNT non aligne, bordure NA retiree par trim, bords multiples de 20", {
  # MNT a 5 m dont l'origine (1015503, 6793507) n'est pas un multiple de 20, bordure de NA
  d <- terra::rast(xmin = 1015503, xmax = 1015683, ymin = 6793507, ymax = 6793687,
                   resolution = 5, crs = "EPSG:2154", vals = 1)
  d[1:2, ] <- NA   # deux lignes du nord
  d[, 1:3] <- NA   # trois colonnes de l'ouest
  e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                                   ymax = 6805000), crs = sf::st_crs(2154)))
  g <- real_grid(e, d, 20)
  x <- terra::ext(g)
  # trim : xmin = 1015503 + 15 = 1015518, ymax = 6793687 - 10 = 6793677 ; arrondi exterieur a 20
  expect_equal(unname(c(x$xmin, x$xmax, x$ymin, x$ymax)), c(1015500, 1015700, 6793500, 6793680))
  expect_equal(unname(c(x$xmin, x$xmax, x$ymin, x$ymax) %% 20), c(0, 0, 0, 0))
  expect_equal(terra::res(g), c(20, 20))
  # x = est 1015530, y = nord 6793670 : colonne floor(30 / 20) + 1 = 2, ligne floor(10 / 20) + 1 = 1
  cel <- terra::cellFromXY(g, cbind(1015530, 6793670))
  expect_equal(unname(terra::rowColFromCell(g, cel)), unname(cbind(1, 2)))
})
