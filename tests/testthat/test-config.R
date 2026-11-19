ecrire_config <- function(modif = list()) {
  cfg <- list(
    ser_code = "D11",
    emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                        ymax = 6805000, crs = 2154),
    buffer_m = 5000, resolution_m = 20, crs = 2154,
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

test_that("`demo` est facultatif (FALSE par défaut) et doit être booléen", {
  expect_false(read_config(ecrire_config())$demo)
  expect_true(read_config(ecrire_config(list(demo = TRUE)))$demo)
  expect_error(read_config(ecrire_config(list(demo = "oui"))), "demo")
})

test_that("mrvbf_res_m : defaut = resolution_m, valeur lue, controle (mission 027)", {
  expect_equal(read_config(ecrire_config())$mrvbf_res_m, 20)
  expect_equal(read_config(ecrire_config(list(resolution_m = 25)))$mrvbf_res_m, 25)
  expect_equal(read_config(ecrire_config(list(mrvbf_res_m = 5)))$mrvbf_res_m, 5)
  expect_error(read_config(ecrire_config(list(mrvbf_res_m = -5))), "mrvbf_res_m")
  expect_error(read_config(ecrire_config(list(mrvbf_res_m = "20"))), "mrvbf_res_m")
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installé")
  expect_equal(read_config(f)$mrvbf_res_m, 20)
})

test_that("cles de la carte hydrique de 25 m : defauts provisoires et controles", {
  cfg <- read_config(ecrire_config())
  expect_equal(cfg$solar_linke, 3)
  expect_equal(cfg$solar_albedo, 0.2)
  expect_equal(cfg$solar_step_h, 0.5)
  expect_equal(cfg$hydric_pas_k, 0.02)
  expect_equal(cfg$hydric_n_controle, 30)
  expect_error(read_config(ecrire_config(list(solar_linke = -1))), "solar_linke")
  expect_error(read_config(ecrire_config(list(solar_albedo = 1.5))), "solar_albedo")
  expect_error(read_config(ecrire_config(list(hydric_pas_k = 0))), "hydric_pas_k")
  expect_error(read_config(ecrire_config(list(hydric_n_controle = 2.5))), "hydric_n_controle")
})

test_that("cles de la descente d'echelle du climat (mission 033) : defauts et controles", {
  cfg <- read_config(ecrire_config())
  expect_identical(cfg$safran_interpolation, "bilineaire")
  expect_equal(cfg$hydric_node_res_m, 1000)
  expect_identical(cfg$ru_min_placettes, 5L)
  expect_identical(read_config(ecrire_config(list(safran_interpolation = "proche")))$safran_interpolation,
                   "proche")
  expect_error(read_config(ecrire_config(list(safran_interpolation = "krigeage"))),
               "safran_interpolation")
  expect_error(read_config(ecrire_config(list(hydric_node_res_m = 0))), "hydric_node_res_m")
  expect_error(read_config(ecrire_config(list(ru_min_placettes = 0))), "ru_min_placettes")
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installe")
  cf <- read_config(f)
  expect_identical(cf$safran_interpolation, "bilineaire")
  expect_identical(cf$ru_min_placettes, 5L)
})

test_that("config.yml du depot : grille de 20 m (mission 025, ADR 0007)", {
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f))
  cfg <- read_config(f)
  expect_equal(cfg$resolution_m, 20)
})
