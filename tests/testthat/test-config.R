ecrire_config <- function(modif = list()) {
  cfg <- list(
    ser_code = "D11",
    emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                        ymax = 6805000, crs = 2154),
    buffer_m = 5000, resolution_m = 25, crs = 2154,
    data_dir = "data", laz_dir = "data/laz", out_dir = "data/sorties",
    ifn_precision_m = 700
  )
  cfg <- utils::modifyList(cfg, modif)
  f <- tempfile(fileext = ".yml")
  yaml::write_yaml(cfg, f)
  f
}

test_that("une configuration valide est lue", {
  cfg <- read_config(ecrire_config())
  expect_equal(cfg$ser_code, "D11")
  expect_equal(cfg$emprise_test$xmax, 1022000)
  expect_equal(cfg$ifn_precision_m, 700)
})

test_that("le config.yml du dépôt est valide quand il est présent", {
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installé")
  expect_equal(read_config(f)$crs, 2154)
})

test_that("les configurations invalides sont refusées", {
  expect_error(read_config(tempfile()), "introuvable")
  expect_error(read_config(ecrire_config(list(crs = 4326))), "2154")
  expect_error(read_config(ecrire_config(list(emprise_test = list(crs = 4326)))), "2154")
  expect_error(read_config(ecrire_config(list(emprise_test = list(xmin = 1030000)))),
               "incoh")
  expect_error(read_config(ecrire_config(list(emprise_test = list(ymax = 6780000)))),
               "incoh")
  expect_error(read_config(ecrire_config(list(buffer_m = -1))), "positif")
  expect_error(read_config(ecrire_config(list(resolution_m = "25"))), "positif")
  expect_error(read_config(ecrire_config(list(ser_code = ""))), "ser_code")
  expect_error(read_config(ecrire_config(list(out_dir = 3))), "out_dir")
})

test_that("une clé manquante est refusée", {
  f <- tempfile(fileext = ".yml")
  writeLines("ser_code: D11", f)
  expect_error(read_config(f), "manquantes")
})
