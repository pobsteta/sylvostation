# Mission 016 : mode réel du pipeline. Un test par fonction de R/pipeline_reel.R, plus un
# run complet hors ligne (`demo: false, offline: true`) qui compte les appels réseau
# (attendu : 0), vérifie la reprise après interruption et la position d'un point connu
# dans la grille (Lambert-93, x = est, y = nord). Aucun téléchargement : les fonctions de
# téléchargement sont remplacées par des fonctions locales.

ex <- function(f) {
  p <- system.file("extdata", f, package = "sylvostation")
  if (!nzchar(p)) p <- testthat::test_path("..", "..", "inst", "extdata", f)
  p
}
laz <- function() ex("LHD_FXX_1015_6794_extrait.laz")

cfg_reel <- function(...) {
  f <- tempfile(fileext = ".yml")
  base <- list(ser_code = "D11",
               emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                                   ymax = 6805000, crs = 2154),
               buffer_m = 5000, resolution_m = 20, crs = 2154, data_dir = "data",
               laz_dir = "data/laz", out_dir = "data/sorties", ifn_precision_m = 700,
               demo = FALSE, offline = TRUE)
  yaml::write_yaml(utils::modifyList(base, list(...)), f)
  read_config(f)
}

# Faux tableau de dalles : n x n dalles de 1 km à partir du coin nord-ouest (x0, y0) en km.
fausses_dalles <- function(n = 5, x0 = 1007, y0 = 6805) {
  ids <- as.vector(outer(x0 + 0:(n - 1), y0 - 0:(n - 1), function(x, y) paste0(x, "-", y)))
  g <- lapply(ids, function(id) {
    e <- as.vector(sylvostation:::.tile_extent(id))
    sf::st_polygon(list(matrix(c(e[1], e[3], e[2], e[3], e[2], e[4], e[1], e[4], e[1], e[3]),
                               ncol = 2, byrow = TRUE)))
  })
  sf::st_sf(tile_id = ids, url = paste0("https://exemple.invalid/", ids, ".laz"),
            geometry = sf::st_sfc(g, crs = 2154))
}

# --- configuration -------------------------------------------------------------------
test_that("read_config : clés du mode réel, valeurs par défaut et contrôles", {
  cfg <- cfg_reel()
  expect_true(cfg$offline)
  expect_null(cfg$max_tiles)
  expect_identical(cfg$taxref_version, "18")
  expect_identical(cfg$emprise, "test")
  expect_equal(cfg$lidar_block_size, 3)
  expect_equal(cfg$saison_vegetation, c(4, 9))
  expect_identical(cfg$bdcharm_departements, c("067", "068", "088"))
  expect_true(cfg$forest_mask)
  expect_null(cfg$gnss_path)
  expect_null(cfg$reference_path)
  expect_error(cfg_reel(offline = "oui"), "offline")
  expect_error(cfg_reel(max_tiles = 0), "max_tiles")
  expect_error(cfg_reel(emprise = "france"), "emprise")
  expect_error(cfg_reel(indicator_source = "baseflor"), "tichy")
  expect_error(cfg_reel(saison_vegetation = c(9, 4)), "saison")
  expect_error(cfg_reel(taxref_version = "dix-huit"), "taxref_version")
})

test_that("le config.yml du dépôt garde demo: true et déclare les clés du mode réel", {
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installé")
  cfg <- read_config(f)
  expect_true(cfg$demo)
  expect_false(cfg$offline)
  expect_identical(cfg$taxref_version, "18")
  expect_true(all(c("gnss_path", "reference_path", "max_tiles", "offline", "taxref_version") %in%
                    names(yaml::read_yaml(f))))
})

# --- sources ---------------------------------------------------------------------------
test_that("fetch_cached : cache sans réseau, refus hors ligne, téléchargement simulé", {
  d <- tempfile("cache")
  dir.create(d)
  appels <- 0L
  faux <- function(url, destfile, ...) {
    appels <<- appels + 1L
    writeLines("x", destfile)
    0L
  }
  expect_error(fetch_cached("https://exemple.invalid/a.csv", d, offline = TRUE), "hors ligne")
  p <- fetch_cached("https://exemple.invalid/a.csv", d, downloader = faux)
  expect_true(file.exists(p))
  expect_equal(appels, 1L)
  fetch_cached("https://exemple.invalid/a.csv", d, offline = TRUE, downloader = faux)
  expect_equal(appels, 1L)  # en cache : aucun nouvel appel
  echec <- function(url, destfile, ...) 1L
  expect_error(fetch_cached("https://exemple.invalid/b.csv", d, downloader = echec,
                            sleeper = function(s) NULL), "impossible")
})

test_that("fetch_cached : reprise après deux échecs, puis réussite (mission 026)", {
  d <- tempfile("cache")
  dir.create(d)
  appels <- 0L
  attentes <- numeric()
  partiel_vu <- logical()
  capricieux <- function(url, destfile, ...) {
    partiel_vu <<- c(partiel_vu, file.exists(destfile))
    appels <<- appels + 1L
    if (appels < 3L) {
      writeLines("partiel", destfile)  # fichier partiel laissé par l'échec
      stop("Stream error in the HTTP/2 framing layer")
    }
    writeLines("x", destfile)
    0L
  }
  expect_message(
    p <- fetch_cached("https://exemple.invalid/c.csv", d, downloader = capricieux,
                      sleeper = function(s) attentes <<- c(attentes, s)),
    "tentative 1/3")
  expect_equal(appels, 3L)
  expect_equal(attentes, c(5, 20))                 # attente croissante
  expect_false(any(partiel_vu))                    # partiel supprimé avant chaque reprise
  expect_identical(readLines(p), "x")
  expect_false(file.exists(paste0(p, ".part")))
})

test_that("fetch_cached : échec définitif après N tentatives, N réglable", {
  d <- tempfile("cache")
  dir.create(d)
  appels <- 0L
  toujours <- function(url, destfile, ...) {
    appels <<- appels + 1L
    stop("Stream error in the HTTP/2 framing layer")
  }
  rien <- function(s) NULL
  suppressMessages(expect_error(
    fetch_cached("https://exemple.invalid/e.csv", d, downloader = toujours, sleeper = rien),
    "impossible apr.s 3 tentative.*HTTP/2"))
  expect_equal(appels, 3L)
  appels <- 0L
  suppressMessages(expect_error(
    fetch_cached("https://exemple.invalid/f.csv", d, downloader = toujours, retries = 5,
                 sleeper = rien), "5 tentative"))
  expect_equal(appels, 5L)
  old <- options(sylvostation.download_retries = 2L)
  on.exit(options(old), add = TRUE)
  appels <- 0L
  suppressMessages(try(fetch_cached("https://exemple.invalid/g.csv", d,
                                    downloader = toujours, sleeper = rien), silent = TRUE))
  expect_equal(appels, 2L)
  expect_error(fetch_cached("https://exemple.invalid/h.csv", d, retries = 0), "retries")
  expect_false(file.exists(file.path(d, "e.csv.part")))
})

test_that("real_sources : extraits réels hors ligne, jamais synth_, version TAXREF figée", {
  s <- real_sources(cfg_reel())
  expect_true(s$offline)
  chemins <- unlist(s[c("laz", "taxref", "tichy", "safran")])
  expect_true(all(file.exists(chemins)))
  expect_false(any(startsWith(basename(chemins), "synth_")))
  expect_null(s$gnss)
  expect_null(s$reference)
  expect_null(s$soils)
  expect_error(real_sources(cfg_reel(taxref_version = "17")), "TAXREF")
  expect_error(real_sources(cfg_reel(gnss_path = tempfile())), "introuvable")
  g <- tempfile(fileext = ".csv")
  writeLines("id,x,y,loc_precision_m", g)
  expect_identical(real_sources(cfg_reel(gnss_path = g))$gnss, g)
  expect_error(real_sources(cfg_reel(offline = FALSE, ifn_archive_url = "https://exemple.invalid/a.zip",
                                     taxref_url = "https://exemple.invalid/TAXREF_v18.zip")),
               "tichy_path")
  # URL IFN et TAXREF : une seule source, config.yml ; exigées en ligne
  expect_null(cfg_reel()$taxref_url)
  expect_error(real_sources(cfg_reel(offline = FALSE)), "ifn_archive_url")
})

# R1 : aucune entrée optionnelle ne peut être un jeu synthétique (un test par entrée)
synth_csv <- function(nom = "gnss.csv", prefixe = FALSE, colonne = TRUE) {
  f <- file.path(tempfile("e"), if (prefixe) paste0("synth_", nom) else nom)
  dir.create(dirname(f))
  d <- data.frame(id = "G1", x = 1015500, y = 6793500, loc_precision_m = 3)
  if (colonne) d$synthetic <- TRUE
  utils::write.csv(d, f, row.names = FALSE)
  f
}

test_that("R1 gnss_path : préfixe synth_ et colonne synthetic = TRUE refusés", {
  expect_error(real_sources(cfg_reel(gnss_path = ex("synth_gnss.csv"))), "gnss_path.*synth")
  expect_error(real_sources(cfg_reel(gnss_path = synth_csv())), "synthetic = TRUE")
  ok <- synth_csv(colonne = FALSE)
  expect_identical(real_sources(cfg_reel(gnss_path = ok))$gnss, ok)
})

test_that("R1 reference_path : préfixe synth_ et balise synthetic = TRUE refusés", {
  expect_error(real_sources(cfg_reel(reference_path = ex("synth_reference.tif"))),
               "reference_path.*synth")
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 1015500, xmax = 1015550, ymin = 6793500,
                   ymax = 6793550, crs = "EPSG:2154", vals = 1:4)
  names(r) <- "trophic"
  terra::metags(r) <- c(synthetic = "TRUE")
  f <- tempfile("ref", fileext = ".tif")
  terra::writeRaster(r, f, filetype = "GTiff")
  expect_error(real_sources(cfg_reel(reference_path = f)), "balise synthetic")
})

test_that("R1 soil_paths : un raster synth_ parmi les couches est refusé", {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 1015500, xmax = 1015550, ymin = 6793500,
                   ymax = 6793550, crs = "EPSG:2154", vals = 1:4)
  d <- tempfile("sols")
  dir.create(d)
  f1 <- file.path(d, "ph.tif")
  f2 <- file.path(d, "synth_ru.tif")
  terra::writeRaster(r, f1)
  terra::writeRaster(r, f2)
  expect_identical(real_sources(cfg_reel(soil_paths = list(f1)))$soils, f1)
  expect_error(real_sources(cfg_reel(soil_paths = list(f1, f2))), "soil_paths.*synth")
})

test_that("R1 tichy_path : classeur synthétique refusé en ligne", {
  en_ligne <- function(p) cfg_reel(offline = FALSE, tichy_path = p,
                                   ifn_archive_url = "https://exemple.invalid/a.zip",
                                   taxref_url = "https://exemple.invalid/TAXREF_v18.zip")
  expect_error(real_sources(en_ligne(synth_csv("tichy.csv", prefixe = TRUE))), "tichy_path.*synth")
  expect_error(real_sources(en_ligne(synth_csv("tichy.csv"))), "synthetic = TRUE")
  ok <- ex("tichy_2023_extrait.csv")
  expect_identical(real_sources(en_ligne(ok))$tichy, ok)
})

test_that("assert_not_synthetic : nom, colonne (CSV, GeoPackage), sinon rien", {
  expect_error(assert_not_synthetic(ex("synth_occ.csv"), "x"), "pr\u00e9fixe synth_")
  expect_silent(assert_not_synthetic(ex("tichy_2023_extrait.csv"), "x"))
  g <- tempfile(fileext = ".gpkg")
  sf::st_write(sf::st_sf(synthetic = TRUE, geometry = sf::st_sfc(sf::st_point(c(1015500, 6793500)),
                                                                 crs = 2154)), g, quiet = TRUE)
  expect_error(assert_not_synthetic(g, "x"), "colonne synthetic")
  expect_identical(assert_not_synthetic(ex("ser_extrait.gpkg"), "x"), ex("ser_extrait.gpkg"))
})

test_that("real_extent : emprise test recoupée avec la SER, ou SER entière", {
  ser <- get_ser("D11", buffer_m = 5000, source = "file", path = ex("ser_extrait.gpkg"))
  cfg <- cfg_reel()
  e <- real_extent(ser, cfg)
  b <- sf::st_bbox(e)
  expect_gte(b[["xmin"]], 1007000)
  expect_lte(b[["xmax"]], 1022000)
  cfg$emprise <- "ser"
  expect_gt(as.numeric(sf::st_area(real_extent(ser, cfg))), as.numeric(sf::st_area(e)))
  cfg$emprise <- "test"
  cfg$emprise_test <- list(xmin = 100000, ymin = 6100000, xmax = 110000, ymax = 6110000)
  expect_error(real_extent(ser, cfg), "n'intersecte pas")
})

# --- dalles et blocs ---------------------------------------------------------------------
test_that("local_tiles : identifiant et emprise de la dalle lus dans le nom", {
  t <- local_tiles(laz())
  expect_identical(t$tile_id, "1015-6794")
  b <- sf::st_bbox(t)
  expect_equal(unname(b[c("xmin", "ymin", "xmax", "ymax")]), c(1015000, 6793000, 1016000, 6794000))
  f <- tempfile(fileext = ".laz")
  file.create(f)
  expect_error(local_tiles(f), "illisible")
  expect_error(local_tiles("absent.laz"), "existants")
})

test_that("select_tiles : max_tiles garde les dalles centrales, toutes sinon", {
  t <- fausses_dalles(5)
  expect_equal(nrow(select_tiles(t)), 25)
  s <- select_tiles(t, 1)
  expect_identical(s$tile_id, "1009-6803")  # centre du carré 5 x 5
  expect_equal(nrow(select_tiles(t, 4)), 4)
  expect_identical(select_tiles(t, 4)$tile_id, sort(select_tiles(t, 4)$tile_id))
  expect_error(select_tiles(t, 0), "max_tiles")
})

test_that("tile_blocks : blocs contigus de 3 x 3 dalles (225 dalles -> 25 blocs)", {
  b <- tile_blocks(fausses_dalles(15), 3)
  expect_length(b, 25)
  expect_true(all(vapply(b, nrow, 1L) == 9L))
  k <- do.call(rbind, lapply(strsplit(b[[1]]$tile_id, "-"), as.numeric))
  expect_equal(diff(range(k[, 1])), 2)
  expect_equal(diff(range(k[, 2])), 2)
  b5 <- tile_blocks(fausses_dalles(5), 3)
  expect_length(b5, 4)
  expect_equal(sum(vapply(b5, nrow, 1L)), 25)
  expect_error(tile_blocks(fausses_dalles(2), 0), "size")
})

# faux moteur LiDAR : écrit de vrais petits rasters (EPSG:2154, maille `res`) et compte les appels
faux_runner_lidar <- function(journal, crs = "EPSG:2154") {
  function(laz_files, out_dir, res = 1, ...) {
    journal$appels[[length(journal$appels) + 1L]] <- laz_files
    ids <- sub("^.*/", "", sub("\\.laz$", "", laz_files))
    for (id in ids) for (k in c("mnt", "mhc")) {
      r <- terra::rast(xmin = 1015000, xmax = 1015000 + 10 * res, ymin = 6794000,
                       ymax = 6794000 + 10 * res, resolution = res, crs = crs)
      terra::values(r) <- 1
      terra::writeRaster(r, file.path(out_dir, paste0(k, "_", id, ".tif")), overwrite = TRUE)
    }
    invisible(NULL)
  }
}

test_that("run_tile_block : cache par dalle, une dalle déjà calculée n'est pas refaite (032)", {
  d <- tempfile("lidar")
  j <- new.env()
  j$appels <- list()
  faux_runner <- faux_runner_lidar(j)
  blk <- tile_blocks(fausses_dalles(3), 3)[[1]]
  out <- run_tile_block(blk, d, runner = faux_runner)
  expect_length(out, 18)
  expect_length(j$appels[[1]], 9)
  # rien à refaire : aucun appel
  run_tile_block(blk, d, runner = faux_runner)
  expect_length(j$appels, 1)
  # interruption simulée : un fichier absent (mnt, mhc), seules ces dalles sont recalculées
  unlink(file.path(d, c("mnt_1007-6805.tif", "mhc_1008-6804.tif")))
  run_tile_block(blk, d, runner = faux_runner)
  expect_length(j$appels, 2)
  expect_setequal(basename(j$appels[[2]]), c("1007-6805.laz", "1008-6804.laz"))
  # fichier illisible : recalculé
  writeLines("pas un raster", file.path(d, "mnt_1009-6803.tif"))
  run_tile_block(blk, d, runner = faux_runner)
  expect_length(j$appels, 3)
  expect_identical(basename(j$appels[[3]]), "1009-6803.laz")
  # option de recalcul forcé : tout est refait
  run_tile_block(blk, d, runner = faux_runner, force = TRUE)
  expect_length(j$appels, 4)
  expect_length(j$appels[[4]], 9)
  expect_error(run_tile_block(blk, d, runner = faux_runner, force = NA), "force")
  rien <- function(...) NULL
  unlink(file.path(d, "mnt_1007-6805.tif"))
  expect_error(run_tile_block(blk, d, runner = rien), "absents")
})

test_that("run_tile_block : mauvais système de coordonnées, mauvaise maille ou paramètres changés -> recalcul (032)", {
  blk <- tile_blocks(fausses_dalles(1), 3)[[1]]
  # CRS différent (WGS84) : refait
  d <- tempfile("lidar")
  j <- new.env(); j$appels <- list()
  run_tile_block(blk, d, runner = faux_runner_lidar(j, crs = "EPSG:4326"))
  run_tile_block(blk, d, runner = faux_runner_lidar(j))
  expect_length(j$appels, 2)
  # maille différente : refait
  d <- tempfile("lidar")
  j <- new.env(); j$appels <- list()
  run_tile_block(blk, d, res = 2, runner = faux_runner_lidar(j))
  run_tile_block(blk, d, res = 1, runner = faux_runner_lidar(j))
  expect_length(j$appels, 2)
  # tampon ou moteur changé : refait ; identique : réutilisé
  d <- tempfile("lidar")
  j <- new.env(); j$appels <- list()
  fr <- faux_runner_lidar(j)
  run_tile_block(blk, d, buffer = 20, runner = fr)
  run_tile_block(blk, d, buffer = 20, ncores = 8, runner = fr)  # ncores : sans effet
  expect_length(j$appels, 1)
  run_tile_block(blk, d, buffer = 50, runner = fr)
  expect_length(j$appels, 2)
  run_tile_block(blk, d, buffer = 50, engine = "lidr", runner = fr)
  expect_length(j$appels, 3)
  # dalle calculée avant 032 (sans params_*.txt) : acceptée si le raster est bon
  unlink(list.files(d, "^params_", full.names = TRUE))
  run_tile_block(blk, d, buffer = 50, engine = "lidr", runner = fr)
  expect_length(j$appels, 3)
})

test_that("run_tile_block et mosaic_tiles sur la dalle LiDAR réelle", {
  skip_if_not_installed("lasR")
  d <- tempfile("lidar")
  f <- run_tile_block(tile_blocks(local_tiles(laz()))[[1]], d, buffer = 0)
  expect_true(all(file.exists(f)))
  m <- mosaic_tiles(f, "mnt", fact = 5, tile_ids = "1015-6794")
  expect_equal(terra::res(m), c(5, 5))
  expect_error(assert_crs_2154(m), NA)
  e <- terra::ext(m)
  expect_equal(unname(c(e$xmin, e$ymin) %% 5), c(0, 0))  # origine alignée sur 5 m
  expect_true(e$xmin <= 1015500 && e$xmax >= 1015580)
  expect_error(mosaic_tiles(f, "mnt", tile_ids = c("1015-6794", "1016-6794")), "manquantes")
  expect_error(mosaic_tiles(character(0), "mnt"), "Aucun")
  fm <- forest_mask(f, real_grid(sf::st_bbox(e, crs = sf::st_crs(2154)), m, 20))
  expect_identical(names(fm), c("foret", "part_couvert"))
  expect_gt(sum(!is.na(terra::values(fm[["foret"]]))), 0)
})

test_that("forest_mask : seuil de 5 m sur la moitié de la cellule", {
  chm <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                     resolution = 1, crs = "EPSG:2154")
  xy <- terra::xyFromCell(chm, seq_len(terra::ncell(chm)))  # x = est, y = nord
  terra::values(chm) <- ifelse(xy[, 1] < 1015525, 10, 1)   # ouest boisé, est ouvert
  g <- build_grid(c(1015500, 6793500, 1015550, 6793550), 25)
  m <- forest_mask(chm, g)
  v <- terra::extract(m, cbind(c(1015510, 1015540), c(6793510, 6793510)))
  expect_equal(v$foret, c(1, NA))
  expect_equal(v$part_couvert, c(1, 0))
})

test_that("real_grid : grille alignée sur l'intersection emprise et MNT", {
  d <- terra::rast(xmin = 1015503, xmax = 1015581, ymin = 6793500, ymax = 6793580,
                   resolution = 1, crs = "EPSG:2154", vals = 1)
  e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
                                   ymax = 6805000), crs = sf::st_crs(2154)))
  g <- real_grid(e, d, 25)
  expect_equal(as.vector(terra::ext(g)), c(xmin = 1015500, xmax = 1015600, ymin = 6793500, ymax = 6793600))
  loin <- sf::st_as_sfc(sf::st_bbox(c(xmin = 900000, ymin = 6700000, xmax = 901000,
                                      ymax = 6701000), crs = sf::st_crs(2154)))
  expect_error(real_grid(loin, d, 25), "recoupe")
})

test_that("real_terrain transmet mrvbf_res et mrvbf a derive_terrain (mission 027)", {
  dtm <- make_synth_dtm(nc = 40, res = 5, xmin = 1015000, ymin = 6793000)
  g <- build_grid(c(1015000, 6793000, 1015200, 6793200), 25)
  vu <- new.env()
  testthat::local_mocked_bindings(derive_terrain = function(dtm, tpi_radii, streams, mrvbf,
                                                            mrvbf_res) {
    vu$mrvbf <- mrvbf; vu$res <- mrvbf_res
    out <- dtm * 0; names(out) <- "pente"; out
  })
  real_terrain(dtm, g, mrvbf = TRUE, mrvbf_res = 20)
  expect_true(vu$mrvbf)
  expect_equal(vu$res, 20)
  real_terrain(dtm, g, mrvbf = FALSE)
  expect_null(vu$res)                       # defaut : maille du MNT
})

test_that("real_terrain et empty_layers : dérivés agrégés à la grille, couches vides nommées", {
  dtm <- make_synth_dtm(nc = 40, res = 5, xmin = 1015000, ymin = 6793000)
  g <- build_grid(c(1015000, 6793000, 1015200, 6793200), 25)
  t <- suppressWarnings(real_terrain(dtm, g, mrvbf = FALSE))
  expect_true(all(c("pente", "twi", "tpi_100", "mrvbf", "altitude") %in% names(t)))
  expect_equal(terra::res(t), c(25, 25))
  expect_true(terra::compareGeom(t, g))
  v <- empty_layers(t)
  expect_true(all(c("mrvbf", "hauteur_reseau") %in% v))
  expect_false("pente" %in% v)
  # pente du plan de 10 % : environ 5,7 degrés
  expect_equal(stats::median(terra::values(t[["pente"]]), na.rm = TRUE), atan(0.1) * 180 / pi,
               tolerance = 0.01)
  expect_error(empty_layers(1), "SpatRaster")
})

# --- climat ------------------------------------------------------------------------------
test_that("read_safran : 12 mailles, température lue", {
  s <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  expect_equal(length(unique(paste(s$LAMBX, s$LAMBY))), 12)
  expect_true("T" %in% names(s))
  expect_true(is.numeric(s$PRELIQ))
  s1 <- read_safran(ex("safran_sim2_extrait.csv"))
  expect_false("T" %in% names(s1))
  expect_error(read_safran("absent.csv"), "existants")
})

test_that("fetch_safran : téléchargement simulé, filtrage aux mailles de l'emprise, refus hors ligne", {
  d <- tempfile("safran")
  dir.create(d)
  src <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  faux <- function(url, destfile, ...) {
    expect_match(url, "QUOT_SIM2_2003\\.csv\\.gz$")
    con <- gzfile(destfile, "w")
    utils::write.table(src[substr(src$DATE, 1, 4) == "2003", ], con, sep = ";", quote = FALSE,
                       row.names = FALSE)
    close(con)
    0L
  }
  expect_error(fetch_safran(2003, c(1014000, 6798000, 1015000, 6799000), d, offline = TRUE),
               "hors ligne")
  # lecture par petits blocs : même résultat qu'en un seul bloc
  f <- fetch_safran(2003, c(1014000, 6798000, 1015000, 6799000), d, downloader = faux,
                    lignes_par_bloc = 500L)
  r <- read_safran(f)
  expect_identical(unique(paste(r$LAMBX, r$LAMBY)), "9640 23690")
  expect_equal(nrow(r), 365)
  unlink(f)
  f2 <- fetch_safran(2003, c(1007000, 6790000, 1022000, 6805000), d, offline = TRUE)
  expect_equal(length(unique(paste(read_safran(f2)$LAMBX, read_safran(f2)$LAMBY))), 9)
})

test_that("fetch_safran : un fichier filtre pour une autre emprise n'est jamais resservi (mission 035)", {
  d <- tempfile("safran")
  dir.create(d)
  src <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  faux <- function(url, destfile, ...) {
    con <- gzfile(destfile, "w")
    utils::write.table(src[substr(src$DATE, 1, 4) == "2003", ], con, sep = ";", quote = FALSE,
                       row.names = FALSE)
    close(con)
    0L
  }
  petite <- c(1014000, 6798000, 1015000, 6799000)
  grande <- c(1007000, 6790000, 1022000, 6805000)
  f1 <- fetch_safran(2003, petite, d, downloader = faux)
  f2 <- fetch_safran(2003, grande, d, downloader = faux)
  expect_false(identical(f1, f2))
  expect_true(file.exists(f1))
  n <- function(f) length(unique(paste(read_safran(f)$LAMBX, read_safran(f)$LAMBY)))
  expect_equal(n(f1), 1)
  expect_equal(n(f2), 9)
  # meme emprise : le fichier existant est resservi tel quel (pas de second filtrage)
  mt <- file.mtime(f2)
  expect_identical(fetch_safran(2003, grande, d, offline = TRUE), f2)
  expect_equal(file.mtime(f2), mt)
  # l'ancien nom sans emprise n'est plus lu
  writeLines("LAMBX;LAMBY;DATE;PRENEI;PRELIQ;ETP\n1;1;20030101;0;0;0", file.path(d, "emprise_2003.csv"))
  expect_identical(fetch_safran(2003, grande, d, offline = TRUE), f2)
  # colonnes gardees = celles de read_safran, valeurs inchangees
  expect_true(all(c("LAMBX", "LAMBY", "DATE", "PRENEI", "PRELIQ", "ETP", "T") %in% names(read_safran(f2))))
  r2 <- read_safran(f2)
  k2 <- paste(r2$LAMBX, r2$LAMBY)
  s03 <- src[substr(src$DATE, 1, 4) == "2003" & paste(src$LAMBX, src$LAMBY) %in% k2, ]
  expect_equal(sum(r2$PRELIQ), sum(s03$PRELIQ))      # valeurs inchangees sur les mailles gardees
  expect_equal(nrow(r2), nrow(s03))
})

test_that("safran_climate : couches p_sv, etp_sv, t_moy à maille kilométrique en Lambert-93", {
  s <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  # plus proche voisin : valeurs de la maille (l'interpolation bilineaire, defaut depuis la
  # mission 033, est testee dans test-climat.R)
  cl <- safran_climate(s, interpolation = "proche")
  expect_identical(names(cl), c("p_sv", "etp_sv", "t_moy"))
  expect_equal(terra::res(cl), c(1000, 1000))
  expect_error(assert_crs_2154(cl), NA)
  # maille 9640_23690 (centre ~ x = 1 014 550, y = 6 799 283) : valeurs de la maille
  v <- terra::extract(cl, cbind(1014550, 6799283))
  m <- s[s$LAMBX == 9640 & s$LAMBY == 23690, ]
  m$mois <- as.integer(substr(m$DATE, 5, 6))
  sv <- m[m$mois %in% 4:9, ]
  attendu_p <- mean(tapply(sv$PRELIQ + sv$PRENEI, substr(sv$DATE, 1, 4), sum))
  expect_equal(v$p_sv, attendu_p, tolerance = 1e-6)
  expect_equal(v$t_moy, mean(tapply(m$T, substr(m$DATE, 1, 4), mean)), tolerance = 1e-6)
  sans_t <- safran_climate(read_safran(ex("safran_sim2_extrait.csv")))
  expect_true(all(is.na(terra::values(sans_t[["t_moy"]]))))
  expect_error(safran_climate(s, months = 13), "mois")
  expect_error(safran_climate(data.frame(a = 1)), "read_safran")
})

test_that("coarse_predictors : climat ramené sur la grille, couches coarse_", {
  cl <- safran_climate(read_safran(ex("safran_sim2_12mailles_extrait.csv")))
  g <- build_grid(c(1015500, 6793500, 1015600, 6793600), 25)
  p <- coarse_predictors(cl, g)
  expect_identical(names(p), c("coarse_p_etp_sv", "coarse_t_moy"))
  expect_true(terra::compareGeom(p, g))
  expect_false(anyNA(terra::values(p)))
  loin <- build_grid(c(700000, 6200000, 700100, 6200100), 25)
  expect_error(coarse_predictors(cl, loin), "ne couvre pas")
})

test_that("bioclim_axis et apply_bioclim : axe orienté « plus haut = plus chaud »", {
  d <- data.frame(coarse_p_etp_sv = c(100, 300, 500, 700), coarse_t_moy = c(10, 9, 7, 6))
  a <- bioclim_axis(d)
  b <- apply_bioclim(d, a)
  expect_true(all(diff(b) < 0))  # plus froid et plus humide => plus bas
  expect_gt(a$loadings[["coarse_t_moy"]], 0)
  r <- terra::rast(nrows = 1, ncols = 4, nlyrs = 2, crs = "EPSG:2154",
                   xmin = 1007000, xmax = 1007100, ymin = 6790000, ymax = 6790025)
  terra::values(r) <- as.matrix(d)
  names(r) <- names(d)
  expect_equal(as.vector(terra::values(apply_bioclim(r, a))), b, tolerance = 1e-9)
  a2 <- bioclim_axis(data.frame(coarse_p_etp_sv = c(100, 300, 500), coarse_t_moy = NA))
  expect_match(a2$sens, "sec")
  expect_error(bioclim_axis(data.frame(coarse_t_moy = 1:3)), "coarse_p_etp_sv")
})

test_that("bioclimat (mission 039) : axe appris sur la T moyennee dans 700 m, applique a t_corr", {
  d <- data.frame(coarse_p_etp_sv = c(100, 300, 500, 700), coarse_t_corr_700m = c(10, 9, 7, 6))
  a <- bioclim_axis(d, t_var = "coarse_t_corr_700m")
  expect_identical(a$vars, c("coarse_p_etp_sv", "coarse_t_corr_700m"))
  expect_gt(a$loadings[["coarse_t_corr_700m"]], 0)
  r <- terra::rast(nrows = 1, ncols = 4, nlyrs = 2, crs = "EPSG:2154",
                   xmin = 1007000, xmax = 1007100, ymin = 6790000, ymax = 6790025)
  terra::values(r) <- as.matrix(d)
  names(r) <- c("coarse_p_etp_sv", "t_corr")
  b <- apply_bioclim(r, a, layers = c(coarse_t_corr_700m = "t_corr"))
  expect_equal(as.vector(terra::values(b)), apply_bioclim(d, a), tolerance = 1e-9)
  expect_error(apply_bioclim(r, a), "coarse_t_corr_700m")
})

# --- placettes IFN -----------------------------------------------------------------------
test_that("filter_greco : GRECO = première lettre du code SER", {
  ifn <- load_ifn(ex(""))
  expect_equal(nrow(filter_greco(ifn, "D")$placettes), nrow(ifn$placettes))
  expect_error(filter_greco(ifn, "K"), "GRECO K")
})

test_that("geology_coverage : avertit quand l'emprise déborde des départements lus", {
  g <- read_geology(ex("bdcharm50_emprise_test.gpkg"))
  dedans <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1010000, ymin = 6795000, xmax = 1015000,
                                        ymax = 6800000), crs = sf::st_crs(2154)))
  expect_lt(expect_silent(geology_coverage(g, dedans, "068")), 0.01)
  deborde <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1017000, ymin = 6795000, xmax = 1027000,
                                         ymax = 6800000), crs = sf::st_crs(2154)))
  expect_warning(p <- geology_coverage(g, deborde, c("067", "068", "088")), "bdcharm_departements")
  expect_equal(p, 0.5, tolerance = 0.02)
})

test_that("fetch_ifn : archive simulée décompressée dans le cache", {
  d <- tempfile("cache")
  dir.create(d)
  src <- tempfile("ifnsrc")
  dir.create(src)
  for (f in c("PLACETTE", "ECOLOGIE", "FLORE", "ARBRE")) {
    file.copy(ex(paste0("ifn_", tolower(f), ".csv")), file.path(src, paste0(f, ".csv")))
  }
  zip <- file.path(tempdir(), "export_dataifn_test.zip")
  old <- setwd(src)
  utils::zip(zip, list.files(), flags = "-q")
  setwd(old)
  faux <- function(url, destfile, ...) file.copy(zip, destfile, overwrite = TRUE) - 1L
  dir_ifn <- fetch_ifn("https://exemple.invalid/export_dataifn_test.zip", d, downloader = faux)
  expect_equal(nrow(load_ifn(dir_ifn)$placettes), 100)
  expect_error(fetch_ifn("https://exemple.invalid/autre.zip", d, offline = TRUE), "hors ligne")
})

test_that("read_geology : extrait gpkg et archive départementale (S_FGEOL, CRS posé)", {
  g <- read_geology(ex("bdcharm50_emprise_test.gpkg"),
                    emprise = c(1015000, 6793000, 1016000, 6794000))
  expect_true(all(c("NOTATION", "DESCR", "CODE") %in% names(g)))
  expect_error(assert_crs_2154(g), NA)
  expect_lte(sf::st_bbox(g)[["xmax"]], 1016000)
  # archive simulée : shapefile sans CRS EPSG reconnu
  d <- tempfile("bd")
  dir.create(d)
  x <- sf::st_read(ex("bdcharm50_emprise_test.gpkg"), quiet = TRUE)[1:3, c("CODE", "NOTATION", "DESCR")]
  sf::st_write(sf::st_set_crs(x, NA), file.path(d, "GEO050K_HARM_068_S_FGEOL_2154.shp"), quiet = TRUE)
  zip <- file.path(tempdir(), "GEO050K_HARM_068.zip")
  old <- setwd(d)
  utils::zip(zip, list.files(), flags = "-q")
  setwd(old)
  z <- read_geology(zip)
  expect_equal(nrow(z), 3)
  expect_identical(unique(z$dep), "68")
  expect_error(assert_crs_2154(z), NA)
})

test_that("ifn_real_gradients : trois gradients aux placettes, maille large seulement", {
  skip_if_not_installed("euptf2")
  skip_if_not_installed("soiltexture")
  skip_if_not_installed("ranger")
  ifn <- filter_releves(load_ifn(ex("")))
  ind <- load_indicator_values("tichy", ex("tichy_2023_extrait.csv"), ex("taxref_v18_extrait.csv"),
                               taxa = unique(ifn$flore$CD_REF))
  s <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  g <- suppressWarnings(ifn_real_gradients(ifn, ind, safran_climate(s), s))
  expect_true(all(c("trophic", "hydric", "bioclim", "ru_mm", "coarse_p_etp_sv") %in% names(g)))
  expect_true(all(g$source == "ifn"))
  expect_true(all(g$loc_precision_m == 700))
  expect_false(any(names(g) %in% FINE_VARIABLES))
  expect_true(attr(g, "methode_hydrique") %in% c("biljou", "repli_ru"))
  if (requireNamespace("biljouR", quietly = TRUE)) {
    expect_identical(attr(g, "methode_hydrique"), "biljou")
    expect_equal(g$hydric, -g$is_biljou)
  }
  expect_false(is.null(attr(g, "bioclim_axis")))
})

test_that("ifn_real_gradients(t_layer) : T corrigee dans 700 m aux placettes, axe appris sur elle", {
  skip_if_not_installed("euptf2")
  skip_if_not_installed("soiltexture")
  skip_if_not_installed("ranger")
  ifn <- filter_releves(load_ifn(ex("")))
  ind <- load_indicator_values("tichy", ex("tichy_2023_extrait.csv"), ex("taxref_v18_extrait.csv"),
                               taxa = unique(ifn$flore$CD_REF))
  s <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  b <- sf::st_bbox(ifn$placettes)
  # couche large fabriquee en memoire : T croissante vers l'est (x = est, Lambert-93)
  t7 <- terra::rast(xmin = floor(b[["xmin"]] / 250) * 250 - 5000, xmax = ceiling(b[["xmax"]] / 250) * 250 + 5000,
                    ymin = floor(b[["ymin"]] / 250) * 250 - 5000, ymax = ceiling(b[["ymax"]] / 250) * 250 + 5000,
                    resolution = 250, crs = "EPSG:2154")
  xy <- terra::xyFromCell(t7, seq_len(terra::ncell(t7)))
  terra::values(t7) <- 8 + (xy[, 1] - b[["xmin"]]) / 10000
  names(t7) <- "coarse_t_corr_700m"
  g <- suppressWarnings(ifn_real_gradients(ifn, ind, safran_climate(s), s, t_layer = t7))
  expect_true("coarse_t_corr_700m" %in% names(g))
  x <- sf::st_coordinates(g)[, 1]
  expect_equal(g$coarse_t_corr_700m, 8 + (x - b[["xmin"]]) / 10000, tolerance = 1e-6)
  ax <- attr(g, "bioclim_axis")
  expect_identical(ax$vars, c("coarse_p_etp_sv", "coarse_t_corr_700m"))
  expect_gt(ax$loadings[["coarse_t_corr_700m"]], 0)
  expect_equal(g$bioclim, apply_bioclim(g, ax))
  # une couche fine (t_corr) est refusee aux placettes IFN (regle des 700 m)
  fine <- t7
  names(fine) <- "t_corr"
  expect_error(suppressWarnings(ifn_real_gradients(ifn, ind, safran_climate(s), s, t_layer = fine)),
               "IFN|interdite")
})

test_that("ifn_observables, ifn_flora_matrix, ifn_trees : formats pour la clé et les fiches", {
  ifn <- load_ifn(ex(""))
  o <- ifn_observables(ifn$placettes)
  expect_identical(names(o), c("id_placette", "obs_pente", "obs_topo", "obs_humus"))
  expect_false(any(tolower(names(o)) %in% tolower(FINE_VARIABLES)))
  expect_true(is.numeric(o$obs_pente))
  ids <- unique(ifn$flore$id_placette)[1:4]
  m <- ifn_flora_matrix(ifn$flore, ids)
  expect_identical(rownames(m), ids)
  expect_true(all(m %in% c(0L, 1L)))
  expect_error(ifn_flora_matrix(data.frame(a = 1), ids), "CD_REF")
  a <- ifn_trees(ifn$arbre)
  expect_identical(names(a), c("plot", "species", "height", "age"))
  expect_error(ifn_trees(data.frame(a = 1)), "ESPAR")
})

test_that("real_fertility : table vide signalée quand aucun arbre n'a d'âge", {
  f <- real_fertility(data.frame(plot = "a", species = "x", height = 20, age = NA),
                      data.frame(plot = "a", type = "T1"))
  expect_equal(nrow(f), 0)
  expect_match(attr(f, "motif"), "AGE")
  set.seed(1)
  ar <- data.frame(plot = rep(1:30, each = 4), species = "chene",
                   age = rep(stats::runif(30, 30, 120), each = 4))
  ar$height <- 8 * log(ar$age) - 10 + stats::rnorm(120, sd = 0.5)
  expect_gt(nrow(real_fertility(ar, data.frame(plot = 1:30, type = rep(c("a", "b"), 15)))), 0)
})

# --- ancrages, GNSS, règle des 700 m -------------------------------------------------------
test_that("gbif_anchors : précision = incertitude maximale des occurrences de la maille", {
  carre <- function(x, y) sf::st_polygon(list(rbind(c(x, y), c(x + 50, y), c(x + 50, y + 50),
                                                     c(x, y + 50), c(x, y))))
  cel <- sf::st_sf(cell_id = c("a", "b"), ph = c(5, 6), azote = c(4, NA),
                   geometry = sf::st_sfc(carre(1015500, 6793500), carre(1015550, 6793500), crs = 2154))
  r <- terra::rast(xmin = 1015500, xmax = 1015600, ymin = 6793500, ymax = 6793600,
                   resolution = 25, crs = "EPSG:2154", vals = 7)
  names(r) <- "pente"
  occ <- sf::st_as_sf(data.frame(x = c(1015510, 1015520, 1015560), y = 6793510,
                                 loc_precision_m = c(5, 12, 20)),
                      coords = c("x", "y"), crs = 2154)
  a <- gbif_anchors(cel, occ, r)
  expect_equal(a$trophic, c(4.5, 6))
  expect_equal(a$loc_precision_m, c(12, 20))
  expect_equal(a$n_occ_maille, c(2L, 1L))
  expect_equal(a$pente, c(7, 7))
  # maille sans occurrence : écartée et comptée
  b <- gbif_anchors(cel, occ[1:2, ], r)
  expect_equal(nrow(b), 1)
  expect_equal(attr(b, "n_ecartees"), 1L)
  # occurrence imprécise (> 25 m) : la règle bloquante arrête l'extraction fine
  occ$loc_precision_m[3] <- 30
  expect_error(gbif_anchors(cel, occ, r), "IFN|700|25|pr.cision", ignore.case = TRUE)
  ifn <- mark_ifn(cel)
  expect_error(gbif_anchors(cel, mark_ifn(occ), r), "IFN|700|pr.cision", ignore.case = TRUE)
  expect_error(gbif_anchors(data.frame(a = 1), occ, r), "grid_bioindication")
  expect_error(gbif_anchors(cel, data.frame(a = 1), r), "clean_occ")
})

test_that("gbif_anchors : aucune maille bioindiquée -> sf vide signalé, pas d'erreur (026)", {
  carre <- sf::st_polygon(list(rbind(c(1015500, 6793500), c(1015550, 6793500),
                                     c(1015550, 6793550), c(1015500, 6793550),
                                     c(1015500, 6793500))))
  cel <- sf::st_sf(cell_id = "a", ph = 5, azote = 4, geometry = sf::st_sfc(carre, crs = 2154))
  r <- terra::rast(xmin = 1015500, xmax = 1015600, ymin = 6793500, ymax = 6793600,
                   resolution = 25, crs = "EPSG:2154", vals = 7)
  names(r) <- "pente"
  loin <- sf::st_as_sf(data.frame(x = 1016500, y = 6794500, loc_precision_m = 5),
                       coords = c("x", "y"), crs = 2154)
  expect_warning(a <- gbif_anchors(cel, loin, r), class = "sylvostation_non_calcule")
  expect_s3_class(a, "sf")
  expect_equal(nrow(a), 0L)
  expect_true(all(c("cell_id", "source", "loc_precision_m", "n_occ_maille", "trophic", "pente")
                  %in% names(a)))
  expect_equal(sf::st_crs(a)$epsg, 2154L)
  expect_equal(attr(a, "n_ecartees"), 1L)
  # l'aval accepte ce vide : aucune ligne complète, donc pas de modèle local (< 20 lignes)
  expect_equal(sum(stats::complete.cases(sf::st_drop_geometry(a))), 0L)
  # l'état de preuve le dit
  e <- evidence_table_real(list(offline = FALSE, n_gbif = nrow(a), gnss = TRUE,
                                reference = TRUE, key = TRUE, soils = TRUE))
  expect_identical(e$etat[grepl("GBIF", e$etape)], "non atteint (aucune maille GBIF)")
  expect_match(e$detail[grepl("^10", e$etape)], "non ex.cut.e")
})

test_that("gnss_field_gradients : gradients de terrain des relevés GNSS", {
  g <- load_gnss(ex("synth_gnss.csv"))  # jeu d'essai synthétique (test seulement)
  ind <- data.frame(nom = c("Synthia alpha", "Synthia beta"), ph = c(4, 6), azote = c(5, 5),
                    humidite = c(6, 8))
  r <- terra::rast(xmin = 1005000, xmax = 1025000, ymin = 6788000, ymax = 6808000,
                   resolution = 1000, crs = "EPSG:2154", nlyrs = 2)
  terra::values(r) <- cbind(300, 8)
  names(r) <- c("coarse_p_etp_sv", "coarse_t_moy")
  ax <- list(vars = names(r), center = c(coarse_p_etp_sv = 300, coarse_t_moy = 8),
             scale = c(coarse_p_etp_sv = 1, coarse_t_moy = 1),
             loadings = c(coarse_p_etp_sv = -0.7, coarse_t_moy = 0.7))
  p <- gnss_field_gradients(g, ind, r, ax)
  expect_equal(nrow(p), length(unique(g$id)))
  expect_true(all(c("trophic", "humidite", "bioclim") %in% names(p)))
  expect_equal(p$bioclim, rep(0, nrow(p)))
  expect_error(gnss_field_gradients(data.frame(id = 1), ind, r, ax), "load_gnss")
})

# --- typologie et état de preuve -------------------------------------------------------
test_that("real_type_legend : colonne logique azonal, FALSE partout", {
  l <- real_type_legend(data.frame(id = 1:2, type = c("T1-H1-B1", "T2-H1-B1")))
  expect_identical(l$azonal, c(FALSE, FALSE))
  expect_error(real_type_legend(data.frame(a = 1)), "id et type")
})

test_that("evidence_table_real : libellés exacts des entrées absentes, jamais « synthétique »", {
  e <- evidence_table_real(list(offline = TRUE, ser_code = "D11", n_tiles = 1, n_ifn = 100,
                                gnss = FALSE, reference = FALSE, key = FALSE))
  expect_identical(names(e), c("etape", "etat", "dans_ce_run", "detail"))
  expect_false(any(grepl("synth", e$etat)))
  expect_identical(e$etat[grepl("GNSS", e$etape)], "non atteint (entrée absente)")
  expect_identical(e$etat[grepl("référence", e$etape)], "sautée (entrée absente)")
  expect_identical(e$etat[grepl("GBIF", e$etape)], "non exécuté")
  expect_true(all(e$etat[e$dans_ce_run == "oui"] == "réel réduit"))
  en_ligne <- evidence_table_real(list(offline = FALSE, n_gbif = 40, gnss = TRUE,
                                       reference = TRUE, key = TRUE, soils = TRUE))
  expect_false(any(grepl("entrée absente", en_ligne$etat)))
  expect_identical(en_ligne$etat[grepl("GBIF", en_ligne$etape)], "réel")
})

test_that("evidence_table_real : ligne 6 bis de la carte hydrique de 25 m (mission 021)", {
  e <- evidence_table_real(list(offline = TRUE, ser_code = "D11"))
  l <- e[grepl("6 bis", e$etape), ]
  expect_equal(nrow(l), 1)
  expect_identical(l$etat, "non exécuté")
  expect_identical(l$dans_ce_run, "non")
  f <- list(offline = TRUE, ser_code = "D11", methode_hydrique_carte = "biljou_topo",
            k_methode = "r.sun", ru_origine = "9640_23610 : 68 mm, placettes de la maille",
            n_controle = 4, ecart_moyen_abs = 0.06, ecart_max_abs = 0.16)
  e <- evidence_table_real(f)
  l <- e[grepl("6 bis", e$etape), ]
  expect_identical(l$etat, "réel réduit")
  for (motif in c("RU uniforme par maille SAFRAN, provisoire", "jamais modulée",
                  "0.06", "0.16", "Placettes IFN : Istress sans k", "même échelle",
                  "TWI, MRVBF et hauteur_reseau", "Istress seul", "ciel clair",
                  "hors de l'emprise", "rg/rso", "aucune validation française")) {
    expect_true(grepl(motif, l$detail, fixed = TRUE), info = motif)
  }
  expect_true(any(grepl("Composante régionale seulement", e$detail)))
  expect_true(any(grepl("validation croisée", e$detail[grepl("^10", e$etape)])))
  expect_true(all(e$etat[e$dans_ce_run == "oui"] == "réel réduit"))
  expect_true(grepl("seuils de la carte hydrique", l$detail, fixed = TRUE))
  expect_true(grepl("merge_rare", l$detail, fixed = TRUE))
  # toute autre méthode que biljou_topo : état « repli »
  for (m in c("biljou_climatique", "climatique_etp_safran", "repli_ru")) {
    f$methode_hydrique_carte <- m
    l2 <- evidence_table_real(f)
    l2 <- l2[grepl("6 bis", l2$etape), ]
    expect_identical(l2$etat, "repli", info = m)
    expect_identical(l2$dans_ce_run, "oui")
  }
  f$methode_hydrique_carte <- "biljou_climatique"
  expect_match(evidence_table_real(f)$detail[grepl("6 bis", e$etape)], "GRASS absent")
})

test_that("write_hydric_grid : COG ou GeoTIFF, prefixe synth_, masque forestier", {
  r <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
                   resolution = 25, crs = "EPSG:2154", nlyrs = 6)
  terra::values(r) <- matrix(c(10, 20, 30, 40), 4, 6)
  names(r) <- c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille", "grad_hydrique_carte")
  d <- tempfile("hyd")
  w <- write_hydric_grid(r, d, "D11")
  expect_identical(basename(w$fichier), "hydrique.tif")
  expect_true(w$format %in% c("COG", "GTiff"))
  h <- terra::rast(w$fichier)
  expect_identical(names(h), c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille"))
  expect_error(assert_crs_2154(h), NA)
  # point connu (x = est, y = nord) : cellule nord-ouest
  expect_equal(terra::extract(h, cbind(1015510, 6793540))[1, "is_topo"], 10)
  foret <- r[[1]]
  terra::values(foret) <- c(1, NA, 1, NA)
  names(foret) <- "foret"
  ws <- write_hydric_grid(r, d, "D11", forest = foret, synthetic = TRUE)
  expect_identical(basename(ws$fichier), "synth_hydrique.tif")
  expect_equal(terra::values(terra::rast(ws$fichier))[, "is_topo"], c(10, NA, 30, NA))
  expect_error(write_hydric_grid(r[[1:2]], d, "D11"), "hydric_stress_grid")
  expect_error(write_hydric_grid(terra::project(r, "EPSG:4326"), d, "D11"), "2154")
})

test_that("read_safran : garde T, FF, HU et SSI quand ils existent (mission 021)", {
  s <- read_safran(ex("safran_sim2_12mailles_extrait.csv"))
  expect_true(all(c("T", "FF", "HU", "SSI") %in% names(s)))
  expect_true(is.numeric(s$SSI))
  expect_equal(s$SSI[s$LAMBX == 9560 & s$LAMBY == 23530 & s$DATE == "20030101"], 136.3)
  expect_equal(nrow(s), 8772)
  s1 <- read_safran(ex("safran_sim2_extrait.csv"))
  expect_false(any(c("FF", "HU", "SSI") %in% names(s1)))
})

test_that("write_types_gpkg_real : table jointe aux polygones, aucune couche sans CRS", {
  f <- tempfile(fileext = ".gpkg")
  p <- sf::st_sf(type_id = 1:2, type = c("T1", "T2"),
                 geometry = sf::st_sfc(sf::st_point(c(1015500, 6793500)),
                                       sf::st_point(c(1015550, 6793500)), crs = 2154))
  sf::st_write(p, f, layer = "types", quiet = TRUE)
  sf::st_write(data.frame(type = c("T1", "T2"), n = 3:4), f, layer = "table_types",
               append = TRUE, quiet = TRUE)
  write_types_gpkg_real(f, data.frame(type = c("T2", "T1"), n = 4:3, azonal = FALSE))
  expect_identical(sf::st_layers(f)$name, "types")
  x <- sf::st_read(f, quiet = TRUE)
  expect_equal(x$n, 3:4)
  expect_identical(sf::st_crs(x)$epsg, 2154L)
  expect_error(write_types_gpkg_real(tempfile(), data.frame(type = 1)), "introuvable")
})

# --- run complet hors ligne : réseau, reprise, point connu --------------------------------
test_that("mode réel hors ligne : 0 appel réseau, reprise après interruption, point dans la bonne cellule", {
  skip_on_cran()
  skip_if_not_installed("targets")
  skip_if_not_installed("withr")
  skip_if_not_installed("lasR")
  for (p in c("ranger", "CAST", "rpart", "indicspecies", "mgcv", "euptf2", "soiltexture"))
    skip_if_not_installed(p)
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")) &&
                file.exists(file.path(racine, "config.yml")),
              "_targets.R et config.yml absents (paquet installé)")
  racine <- normalizePath(racine)
  d <- withr::local_tempdir("reel016_")
  file.copy(file.path(racine, c("_targets.R", "config.yml")), d)
  txt <- readLines(file.path(d, "config.yml"), encoding = "UTF-8")
  txt <- txt[!grepl("^(demo|offline|max_tiles):", txt)]
  writeLines(c(txt, "demo: false", "offline: true", "max_tiles: 1"), file.path(d, "config.yml"),
             useBytes = TRUE)
  withr::local_dir(d)
  # tout appel HTTP échouerait (mandataire mort) et chaque appel R au réseau est compté
  withr::local_envvar(http_proxy = "http://127.0.0.1:9", https_proxy = "http://127.0.0.1:9",
                      HTTP_PROXY = "http://127.0.0.1:9", HTTPS_PROXY = "http://127.0.0.1:9",
                      no_proxy = "", GDAL_HTTP_PROXY = "127.0.0.1:9")
  compteur <- new.env()
  compteur$n <- 0L
  traces <- list(c("download.file", "utils"), c("url", "base"))
  if (nzchar(system.file(package = "curl"))) {  # curl : paquet facultatif, non déclaré
    traces <- c(traces, list(c("curl_download", "curl"), c("curl_fetch_memory", "curl"),
                             c("curl_fetch_disk", "curl")))
  }
  if (nzchar(system.file(package = "rgbif"))) {
    traces <- c(traces, list(c("occ_search", "rgbif"), c("occ_download", "rgbif")))
  }
  for (t in traces) {
    suppressMessages(trace(t[1], where = asNamespace(t[2]), print = FALSE,
                           tracer = bquote(.(compteur)$n <- .(compteur)$n + 1L)))
  }
  on.exit(for (t in traces) suppressMessages(untrace(t[1], where = asNamespace(t[2]))), add = TRUE)

  debut <- Sys.time()
  targets::tar_make(callr_function = NULL, reporter = "silent")
  duree <- as.numeric(difftime(Sys.time(), debut, units = "secs"))
  message("Run hors ligne : ", round(duree), " s ; appels réseau : ", compteur$n)
  expect_identical(compteur$n, 0L)
  prog <- targets::tar_progress()
  expect_true(all(prog$progress %in% c("completed", "skipped")))
  cfg <- read_config("config.yml")
  out <- file.path(cfg$out_dir, cfg$ser_code)

  # point connu : x = 1 015 540 (est), y = 6 793 540 (nord), Lambert-93
  ty <- terra::rast(file.path(out, "types.tif"))
  expect_error(assert_crs_2154(ty), NA)
  e <- terra::ext(ty)
  expect_equal(c(e$xmin, e$ymax) %% cfg$resolution_m, c(xmin = 0, ymax = 0))
  cel <- terra::cellFromXY(ty, cbind(1015540, 6793540))
  col <- floor((1015540 - e$xmin) / cfg$resolution_m) + 1
  lig <- floor((e$ymax - 6793540) / cfg$resolution_m) + 1
  expect_equal(unname(terra::rowColFromCell(ty, cel)[1, ]), unname(c(lig, col)))
  expect_false(is.na(terra::values(ty)[cel, 1]))

  # reprise : rien n'est refait ; une dalle perdue est recalculée seule
  targets::tar_make(callr_function = NULL, reporter = "silent")
  expect_true(all(targets::tar_progress()$progress == "skipped"))
  f <- targets::tar_read(lidar_files)
  unlink(f[startsWith(basename(f), "mnt_")])
  targets::tar_make(callr_function = NULL, reporter = "silent")
  p <- targets::tar_progress()
  expect_true(any(startsWith(p$name[p$progress == "completed"], "lidar_files")))
  expect_true(all(file.exists(f)))
  expect_identical(compteur$n, 0L)

  # sorties : pas de préfixe synth_, légende avec azonal, état de preuve hors ligne
  fichiers <- list.files(out)
  expect_false(any(startsWith(fichiers, "synth_")))
  leg <- utils::read.delim(file.path(out, "legende_types.csv"), sep = ";")
  expect_true("azonal" %in% names(leg))
  ep <- utils::read.delim(file.path(out, "etat_de_preuve.csv"), sep = ";", encoding = "UTF-8")
  expect_true(any(grepl("Composante régionale seulement", ep$detail)))
  expect_true(any(grepl("non atteint (entrée absente)", ep$etat, fixed = TRUE)))
})

test_that("run_tile_block : recalcul interrompu, pas de dalle mixte ; message sans params (032)", {
  blk <- tile_blocks(fausses_dalles(1), 3)[[1]]
  d <- tempfile("lidar")
  j <- new.env(); j$appels <- list()
  fr <- faux_runner_lidar(j)
  run_tile_block(blk, d, buffer = 20, runner = fr)
  # recalcul à buffer 30 interrompu après l'écriture du mnt seul
  interrompu <- function(laz_files, out_dir, res = 1, ...) {
    r <- terra::rast(xmin = 1015000, xmax = 1015010, ymin = 6794000, ymax = 6794010,
                     resolution = res, crs = "EPSG:2154")
    terra::values(r) <- 2
    terra::writeRaster(r, file.path(out_dir, "mnt_1007-6805.tif"), overwrite = TRUE)
    stop("coupure")
  }
  expect_error(run_tile_block(blk, d, buffer = 30, runner = interrompu), "coupure")
  # relance à buffer 20 : la dalle mixte ne doit pas être reprise
  j$appels <- list()
  run_tile_block(blk, d, buffer = 20, runner = fr)
  expect_length(j$appels, 1)
  # dalle sans params : reprise avec un message
  unlink(list.files(d, "^params_", full.names = TRUE))
  expect_message(run_tile_block(blk, d, buffer = 20, runner = fr), "sans params")
  expect_length(j$appels, 1)
  run_tile_block(blk, d, buffer = 20, runner = fr, force = TRUE)  # recalcul : params réécrits
  expect_no_message(run_tile_block(blk, d, buffer = 20, runner = fr))
})

test_that("_targets.R : seule la valeur 1 de SYLVOSTATION_LIDAR_FORCE force le recalcul (032)", {
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")), "_targets.R absent")
  txt <- paste(readLines(file.path(racine, "_targets.R"), encoding = "UTF-8"), collapse = "\n")
  expect_match(txt, 'identical(Sys.getenv("SYLVOSTATION_LIDAR_FORCE"), "1")', fixed = TRUE)
  expect_false(grepl('nzchar(Sys.getenv("SYLVOSTATION_LIDAR_FORCE"))', txt, fixed = TRUE))
})

test_that("_targets.R : une clé sans rapport ne périme pas lidar_files, lidar_buffer_m la périme (032)", {
  skip_on_cran()
  skip_if_not_installed("targets")
  skip_if_not_installed("withr")
  skip_if_not_installed("lasR")
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")) &&
                file.exists(file.path(racine, "config.yml")),
              "_targets.R et config.yml absents (paquet installé)")
  racine <- normalizePath(racine)
  d <- withr::local_tempdir("cache032_")
  file.copy(file.path(racine, c("_targets.R", "config.yml")), d)
  ecrire_config <- function(retirer = character(), ajouter = character()) {
    txt <- readLines(file.path(racine, "config.yml"), encoding = "UTF-8")
    txt <- txt[!grepl(paste0("^(demo|offline|max_tiles|", paste(c("zz", retirer), collapse = "|"), "):"), txt)]
    writeLines(c(txt, "demo: false", "offline: true", "max_tiles: 1", ajouter),
               file.path(d, "config.yml"), useBytes = TRUE)
  }
  ecrire_config()
  withr::local_dir(d)
  perimee <- function() {
    "lidar_files" %in% targets::tar_outdated(names = "lidar_files", callr_function = NULL,
                                              reporter = "silent")
  }
  targets::tar_make(names = "lidar_files", callr_function = NULL, reporter = "silent")
  expect_false(perimee())
  # une clé ajoutée sans rapport avec le LiDAR, et une clé d'un autre calcul modifiée
  ecrire_config(ajouter = "cle_sans_rapport_032: 42")
  expect_false(perimee())
  ecrire_config(retirer = "mrvbf_res_m", ajouter = c("cle_sans_rapport_032: 42", "mrvbf_res_m: 10"))
  expect_false(perimee())
  # le tampon LiDAR change le calcul : périmée
  ecrire_config(retirer = "lidar_buffer_m", ajouter = "lidar_buffer_m: 30")
  expect_true(perimee())
})

test_that("fetch_cached : retries entier >= 1 et wait non vide (026)", {
  d <- tempfile("cache")
  dir.create(d)
  u <- "https://exemple.invalid/z.csv"
  expect_error(fetch_cached(u, d, retries = 2.5), "retries")
  expect_error(fetch_cached(u, d, retries = NA_real_), "retries")
  expect_error(fetch_cached(u, d, wait = numeric(0)), "wait")
  expect_error(fetch_cached(u, d, wait = -1), "wait")
})

test_that("forest_mask a 20 m : la moitie de la cellule suit la resolution de la grille (mission 025)", {
  # MHC a 1 m ; cellule de 20 m. Colonnes ouest (x < 1015510) boisees : la cellule de
  # x 1015500-1015520 est boisee a exactement 50 %, celle de 1015520-1015540 a 0 %.
  chm <- terra::rast(xmin = 1015500, xmax = 1015540, ymin = 6793500, ymax = 6793520,
                     resolution = 1, crs = "EPSG:2154")
  xy <- terra::xyFromCell(chm, seq_len(terra::ncell(chm)))  # x = est, y = nord
  terra::values(chm) <- ifelse(xy[, 1] < 1015510, 10, 1)
  g <- build_grid(c(1015500, 6793500, 1015540, 6793520), 20)
  expect_equal(terra::res(g), c(20, 20))
  m <- forest_mask(chm, g)
  v <- terra::extract(m, cbind(c(1015510, 1015530), c(6793510, 6793510)))
  expect_equal(v$part_couvert, c(0.5, 0))
  expect_equal(v$foret, c(1, NA))   # 50 % : seuil atteint (>=), 0 % : hors foret
  # a moins de la moitie : non boisee
  terra::values(chm) <- ifelse(xy[, 1] < 1015509, 10, 1)
  expect_equal(terra::extract(forest_mask(chm, g), cbind(1015510, 6793510))$foret, NA_real_)
})

test_that("evidence_table_real et evidence_table : la maille vient de resolution_m (mission 025)", {
  e20 <- evidence_table_real(list(offline = TRUE, ser_code = "D11", n_tiles = 1, n_ifn = 10,
                                  gnss = FALSE, reference = FALSE, resolution_m = 20,
                                  forest_mask = TRUE, n_cells = 5))
  expect_true(any(grepl("grille de 20 m", e20$detail, fixed = TRUE)))
  expect_true(any(grepl("Cellule de 20 m", e20$detail, fixed = TRUE)))
  expect_false(any(grepl("25 m", e20$detail, fixed = TRUE)))
  e30 <- evidence_table_real(list(offline = TRUE, ser_code = "D11", n_tiles = 1, n_ifn = 10,
                                  gnss = FALSE, reference = FALSE, resolution_m = 30))
  expect_true(any(grepl("grille de 30 m", e30$detail, fixed = TRUE)))
  d <- evidence_table(n_ifn = 3, resolution_m = 20)
  expect_true(grepl("grille de 20 m", d$detail[1], fixed = TRUE))
})

test_that("calibration_counts : entonnoir des effectifs, chute a l'etape climat visible", {
  ifn <- filter_releves(load_ifn(system.file("extdata", package = "sylvostation")))
  g <- data.frame(coarse_t_moy = c(1, NA, NA, NA, 2))
  litho <- data.frame(coarse_litho_700m = c("gres", NA))
  r <- calibration_counts(ifn, g, list(trophic = 2, hydric = data.frame(a = 1)), litho,
                          data.frame(a = 1))
  expect_named(r, c("etape", "n", "perdues", "cause"))
  expect_equal(r$n[1], nrow(ifn$placettes))
  expect_equal(r$n[r$etape == "trophique calculable"], 5L)
  expect_equal(r$n[r$etape == "avec climat SAFRAN"], 2L)
  expect_equal(r$perdues[r$etape == "avec climat SAFRAN"], 3L)
  expect_equal(r$n[r$etape == "avec lithologie (disque couvert)"], 1L)
  expect_equal(r$n[r$etape == "apprentissage trophique"], 1L)
  expect_true(is.na(r$perdues[1]))
  r0 <- calibration_counts(ifn, g, list(trophic = 2, hydric = 1))
  expect_false(any(grepl("lithologie|apprentissage trophique", r0$etape)))
})
