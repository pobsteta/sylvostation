# Mission 039b : la branche « temperature corrigee / RU apprise » de _targets.R tourne dans
# tar_make, en mode reel hors ligne, sur deux extraits REELS du depot (inst/extdata/SOURCES.md) :
# BD ALTI 250 m (Licence Ouverte) et textures SoilGrids 2.0 (CC BY 4.0, ISRIC). Aucun
# telechargement, aucun jeu synthetique (le mode reel les refuse : assert_not_synthetic()).

test_that("mode reel hors ligne : T corrigee et RU apprise calculees, ecrites, T decroit avec l'altitude", {
  skip_on_cran()
  skip_if_not_installed("targets")
  for (p in c("ranger", "CAST", "rpart", "indicspecies", "mgcv", "euptf2", "soiltexture"))
    skip_if_not_installed(p)
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")) && file.exists(file.path(racine, "config.yml")),
              "_targets.R et config.yml absents (paquet installe)")
  mnt <- system.file("extdata", "bdalti_250m_extrait.tif", package = "sylvostation")
  sg <- system.file("extdata", "soilgrids_texture_extrait.tif", package = "sylvostation")
  expect_true(nzchar(mnt) && nzchar(sg))
  expect_lt(file.size(mnt), 200 * 1024)
  expect_lt(file.size(sg), 200 * 1024)
  racine <- normalizePath(racine)
  d <- tempfile("reel039_")
  dir.create(d)
  file.copy(file.path(racine, c("_targets.R", "config.yml")), d)
  txt <- readLines(file.path(d, "config.yml"), encoding = "UTF-8")
  txt <- txt[!grepl("^(gnss_path|reference_path|max_tiles|offline|demo|mnt_large_path|soilgrids_texture_path|climat_temperature|ru_carte):", txt)]
  writeLines(c(txt, "demo: false", "offline: true", "max_tiles: 1", "climat_temperature: corrigee",
               "ru_carte: apprise", paste0("mnt_large_path: \"", mnt, "\""),
               paste0("soilgrids_texture_path: \"", sg, "\"")),
             file.path(d, "config.yml"), useBytes = TRUE)
  old <- setwd(d)
  on.exit(setwd(old), add = TRUE)
  err <- tryCatch({ suppressWarnings(targets::tar_make(callr_function = NULL, reporter = "silent")); NULL },
                  error = function(e) conditionMessage(e))
  expect_null(err, info = "tar_make a echoue (branche 039 hors ligne)")
  skip_if(!is.null(err))
  # cibles de la branche : gradient, T a la cellule, RU apprise, BILJOU sur la RU completee
  lr <- targets::tar_read(t_lapse)
  expect_true(is.list(lr) && is.finite(lr$gradient))
  expect_true("coarse_t_corr_700m" %in% attr(targets::tar_read(ifn_gradients), "bioclim_axis")$vars)
  expect_false(is.null(targets::tar_read(ru_map)))
  h <- targets::tar_read(hydric_grid)
  expect_true(any(is.finite(terra::values(h$r[["is_topo"]]))))
  b <- targets::tar_read(gradient_map)[["bioclim"]]
  expect_true(any(is.finite(terra::values(b))))
  # sorties ecrites, sans prefixe synth_
  cfg <- read_config("config.yml")
  od <- file.path(d, cfg$out_dir, cfg$ser_code)
  ft <- file.path(od, "temperature_corrigee.tif")
  fr <- file.path(od, "ru_apprise.tif")
  expect_true(file.exists(ft))
  expect_true(file.exists(fr))
  expect_false(any(grepl("^synth_", basename(list.files(od)))))
  # la temperature de la cellule decroit avec l'altitude (meme grille, Lambert-93)
  tc <- terra::rast(ft)
  z <- targets::tar_read(terrain)[["altitude"]]
  expect_true(terra::compareGeom(tc, z, stopOnError = FALSE))
  v <- cbind(terra::values(tc, mat = FALSE), terra::values(z, mat = FALSE))
  v <- v[stats::complete.cases(v), , drop = FALSE]
  expect_gt(nrow(v), 10)
  expect_lt(stats::cor(v[, 1], v[, 2]), -0.9)
  ru <- terra::values(terra::rast(fr), mat = FALSE)
  expect_true(all(ru[is.finite(ru)] > 0))
})
