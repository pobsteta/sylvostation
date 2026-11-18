# Reprise sur incident réseau des téléchargements hors fetch_cached() (mission 026).
# Aucun accès réseau : le téléchargeur et l'attente sont remplacés par les options
# `sylvostation.downloader` et `sylvostation.sleeper`.

# Téléchargeur qui échoue (erreur) `n_echecs` fois en laissant un fichier partiel, puis
# écrit `contenu`. Garde la trace des appels et de la présence d'un partiel avant l'appel.
faux_telechargeur <- function(contenu, n_echecs = 2L) {
  etat <- new.env()
  etat$appels <- 0L
  etat$partiel_vu <- logical()
  etat$f <- function(url, destfile, ...) {
    etat$partiel_vu <- c(etat$partiel_vu, file.exists(destfile))
    etat$appels <- etat$appels + 1L
    if (etat$appels <= n_echecs) {
      writeLines("partiel", destfile)
      stop("Stream error in the HTTP/2 framing layer")
    }
    writeLines(contenu, destfile)
    0L
  }
  etat
}

avec_reseau_simule <- function(tel, code) {
  attentes <- numeric()
  old <- options(sylvostation.downloader = tel$f,
                 sylvostation.sleeper = function(s) attentes <<- c(attentes, s),
                 sylvostation.download_retries = 3L)
  on.exit(options(old), add = TRUE)
  suppressMessages(force(code))
  attentes
}

test_that(".download_once (SER, dalles LiDAR) : reprise puis réussite, partiel supprimé", {
  d <- tempfile("dl")
  tel <- faux_telechargeur("contenu")
  att <- avec_reseau_simule(tel, p <- sylvostation:::.download_once("https://exemple.invalid/x.laz", d))
  expect_equal(tel$appels, 3L)
  expect_equal(att, c(5, 20))
  expect_false(any(tel$partiel_vu))
  expect_identical(readLines(p), "contenu")
  expect_false(file.exists(paste0(p, ".part")))
})

test_that(".download_once : échec définitif après N tentatives, sans fichier laissé", {
  d <- tempfile("dl")
  tel <- faux_telechargeur("x", n_echecs = 99L)
  old <- options(sylvostation.downloader = tel$f, sylvostation.sleeper = function(s) NULL,
                 sylvostation.download_retries = 4L)
  on.exit(options(old), add = TRUE)
  suppressMessages(expect_error(
    sylvostation:::.download_once("https://exemple.invalid/y.laz", d),
    "impossible apr.s 4 tentative"))
  expect_equal(tel$appels, 4L)
  expect_length(list.files(d, all.files = TRUE, no.. = TRUE), 0L)
})

test_that(".fetch_tiles_wfs (tableau d'assemblage LiDAR) : reprise puis réussite", {
  geojson <- paste0('{"type":"FeatureCollection","features":[{"type":"Feature",',
                    '"properties":{"coordonnees_nw":"1015_6794"},',
                    '"geometry":{"type":"Point","coordinates":[1015500,6793500]}}]}')
  tel <- faux_telechargeur(geojson)
  p <- NULL
  att <- avec_reseau_simule(tel, p <- sylvostation:::.fetch_tiles_wfs(
    c(xmin = 1015000, ymin = 6793000, xmax = 1016000, ymax = 6794000)))
  expect_equal(tel$appels, 3L)
  expect_equal(att, c(5, 20))
  expect_equal(nrow(p), 1L)
})

test_that(".topage_layer et get_hydro_network (TOPAGE) : reprise des deux appels", {
  xml <- "<x>sa:TronconHydrographique_FXX_Topage2024</x>"
  tel <- faux_telechargeur(xml)
  couche <- NULL
  att <- avec_reseau_simule(tel, couche <- sylvostation:::.topage_layer())
  expect_equal(couche, "sa:TronconHydrographique_FXX_Topage2024")
  expect_equal(tel$appels, 3L)
  expect_equal(att, c(5, 20))
  # pages : GetCapabilities réussit, la page échoue une fois, puis rend une ligne (L93)
  gj <- paste0('{"type":"FeatureCollection","crs":{"type":"name","properties":{"name":',
               '"urn:ogc:def:crs:EPSG::2154"}},"features":[{"type":"Feature","properties":',
               '{"CdOH":"A"},"geometry":{"type":"LineString","coordinates":',
               '[[1015100,6793100],[1015200,6793200]]}}]}')
  etat <- new.env()
  etat$appels <- 0L
  etat$partiel_vu <- FALSE
  f <- function(url, destfile, ...) {
    etat$appels <- etat$appels + 1L
    etat$partiel_vu <- etat$partiel_vu || file.exists(destfile)
    if (etat$appels == 2L) {
      writeLines("partiel", destfile)
      stop("Stream error in the HTTP/2 framing layer")
    }
    writeLines(if (etat$appels == 1L) xml else gj, destfile)
    0L
  }
  old <- options(sylvostation.downloader = f, sylvostation.sleeper = function(s) NULL,
                 sylvostation.download_retries = 3L)
  on.exit(options(old), add = TRUE)
  r <- suppressMessages(get_hydro_network(c(1015000, 6793000, 1016000, 6794000)))
  expect_equal(etat$appels, 3L)
  expect_false(etat$partiel_vu)
  expect_equal(nrow(r), 1L)
})

cfg_dl <- function(...) {
  f <- tempfile(fileext = ".yml")
  base <- list(ser_code = "D11",
               emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                                   ymax = 6805000, crs = 2154),
               buffer_m = 5000, resolution_m = 25, crs = 2154, data_dir = "data",
               laz_dir = "data/laz", out_dir = "data/sorties", ifn_precision_m = 700,
               demo = FALSE, offline = TRUE)
  yaml::write_yaml(utils::modifyList(base, list(...)), f)
  read_config(f)
}

test_that("download_retries : défaut 3, contrôles de config", {
  cfg <- cfg_dl()
  expect_identical(cfg$download_retries, 3L)
  expect_identical(cfg_dl(download_retries = 5)$download_retries, 5L)
  expect_error(cfg_dl(download_retries = 0), "download_retries")
  expect_error(cfg_dl(download_retries = 2.5), "download_retries")
  expect_error(cfg_dl(download_retries = "trois"), "download_retries")
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installé")
  expect_identical(yaml::read_yaml(f)$download_retries, 3L)
})
