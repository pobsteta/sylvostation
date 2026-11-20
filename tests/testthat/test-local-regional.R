# Mission 037 : la carte trophique locale (ancrages GBIF) ne remplace la regionale que si elle fait
# mieux en validation croisee. Jeux d'essai fabriques (synthetic = TRUE), aucun telechargement.

fabrique_ancrages <- function(n = 160, signal = "a", seed = 4) {
  set.seed(seed)
  d <- sf::st_as_sf(data.frame(
    x = runif(n, 1000000, 1100000), y = runif(n, 6800000, 6900000), loc_precision_m = 10,
    a = rnorm(n), synthetic = TRUE), coords = c("x", "y"), crs = 2154, remove = FALSE)
  # reponse : portee par le predicteur `a` (le local la voit) ou par une surface lisse de x, y
  lisse <- function(x, y) 2 * sin((x - 1000000) / 30000) + 1.5 * cos((y - 6800000) / 25000)
  d$trophic <- if (signal == "a") 2 * d$a + rnorm(n, sd = 0.3) else
    lisse(d$x, d$y) + rnorm(n, sd = 0.2)
  d$lisse <- lisse(d$x, d$y)
  d
}

local_de <- function(d, predictors = "a", bs = 10000, k = 5L) {
  list(data = d, cv = spatial_cv(d, "trophic", predictors, k = k, block_size = bs, num_trees = 60,
                                 seed = 1))
}

carte <- function(f) {
  r <- terra::rast(xmin = 1000000, xmax = 1100000, ymin = 6800000, ymax = 6900000, resolution = 1000,
                   crs = "EPSG:2154")
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  terra::values(r) <- f(xy[, 1], xy[, 2])
  names(r) <- "pred"
  r
}

test_that("le local gagne : borne basse de l'IC au-dessus de la marge, remplacement decide", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "a")
  r <- carte(function(x, y) rep(mean(d$trophic), length(x)))       # regional : la moyenne seule
  res <- compare_local_regional(local_de(d), r, n_boot = 300)
  expect_true(res$remplace)
  expect_equal(res$publiee, "locale")
  expect_equal(res$resume$decision, "locale")
  expect_gt(res$resume$r2_local, 0.5)
  expect_lt(res$resume$r2_regional, 0.05)
  expect_gt(res$resume$ic_bas, res$resume$seuil_gain)
  expect_lt(res$resume$ic_bas, res$resume$gain)
  expect_gt(res$resume$ic_haut, res$resume$gain - 1e-9)
  expect_equal(res$resume$gain, res$resume$r2_local - res$resume$r2_regional)
  expect_equal(res$resume$n_ancrages, 160L)
  expect_equal(res$resume$niveau_ic, 0.95)
  expect_gte(res$resume$n_blocs, 10L)
  expect_equal(res$resume$k_plis, 5L)
  expect_equal(sum(res$par_pli$n), 160L)
  expect_equal(res$par_pli$gain, res$par_pli$r2_local - res$par_pli$r2_regional)
  expect_match(res$resume$motif, "au-dessus de")
  expect_match(res$resume$statut_seuils, "provisoire, sans source")
})

test_that("le local perd : carte regionale gardee, borne basse sous la marge", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "lisse")                          # reponse = surface lisse
  r <- carte(function(x, y) 2 * sin((x - 1000000) / 30000) + 1.5 * cos((y - 6800000) / 25000))
  res <- compare_local_regional(local_de(d), r, n_boot = 300)       # le local ne voit que `a` (bruit)
  expect_false(res$remplace)
  expect_equal(res$publiee, "regionale")
  expect_equal(res$resume$decision, "régionale")
  expect_lt(res$resume$gain, 0)
  expect_lte(res$resume$ic_bas, res$resume$seuil_gain)
  expect_gt(res$resume$r2_regional, 0.8)
  expect_match(res$resume$motif, "non supérieure")
})

test_that("une marge plus haute refuse un gain reel mais trop petit", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "a")
  r <- carte(function(x, y) rep(mean(d$trophic), length(x)))
  l <- local_de(d)
  expect_true(compare_local_regional(l, r, gain_min = 0.02, n_boot = 200)$remplace)
  expect_false(compare_local_regional(l, r, gain_min = 5, n_boot = 200)$remplace)
})

test_that("le regional recalibre est une information, jamais un critere de decision", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "a")
  l <- local_de(d)
  # regional dont le seul defaut est un decalage de +3 : brut il est tres mauvais, recalibre il est
  # parfait (valeurs lues aux ancrages = observe + 3)
  r <- carte(function(x, y) rep(NA_real_, length(x)))
  terra::values(r)[terra::cellFromXY(r, sf::st_coordinates(d))] <- d$trophic + 3
  res <- suppressWarnings(compare_local_regional(l, r, n_boot = 200, min_blocks = 5))
  expect_gt(res$resume$r2_regional_recalibre, res$resume$r2_local)   # information : il gagnerait
  expect_equal(res$resume$decision, "locale")      # mais la decision compare le regional BRUT au local
  expect_true(res$remplace)
  expect_gt(res$resume$biais_regional, 2.5)
})

test_that("comparaison impossible : avertissement avec la raison, carte regionale gardee", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "a")
  r <- carte(function(x, y) rep(0, length(x)))
  # modele local absent (moins d'ancrages que le minimum dans la cible)
  expect_warning(a <- compare_local_regional(NULL, r, n_anchors = 2L), "mod.le local absent \\(2 ancrage")
  expect_false(a$remplace)
  expect_equal(a$publiee, "regionale")
  expect_match(a$resume$decision, "comparaison impossible")
  expect_equal(a$resume$n_ancrages, 2L)
  expect_true(is.na(a$resume$gain))
  expect_equal(nrow(a$par_pli), 0L)
  # trop peu d'ancrages
  l <- local_de(d)
  expect_warning(b <- compare_local_regional(l, r, min_anchors = 500L), "160 ancrage\\(s\\) < 500")
  expect_false(b$remplace)
  # trop peu de blocs : blocs de 50 km sur 100 km = 4 blocs pour 3 plis
  lb <- local_de(d, bs = 50000, k = 3L)
  expect_warning(cc <- compare_local_regional(lb, r, min_blocks = 10L), "bloc\\(s\\) occup.*< 10")
  expect_false(cc$remplace)
  expect_equal(cc$resume$n_blocs, 4L)
  # carte regionale non definie aux ancrages
  rna <- r
  terra::values(rna) <- NA_real_
  expect_warning(e <- compare_local_regional(l, rna), "r.gionale non d.finie")
  expect_false(e$remplace)
  # ancrages non alignes sur leur validation croisee : erreur, pas de decision
  lm <- l
  lm$data$trophic <- lm$data$trophic + 1
  expect_error(compare_local_regional(lm, r), "align")
})

test_that("bootstrap de blocs : reproductible (graine), etat du generateur restaure, entrees controlees", {
  skip_if_not_installed("ranger")
  d <- fabrique_ancrages(signal = "a")
  l <- local_de(d)
  r <- carte(function(x, y) rep(mean(d$trophic), length(x)))
  set.seed(99)
  avant <- .Random.seed
  a <- compare_local_regional(l, r, n_boot = 200, seed = 7)
  expect_identical(.Random.seed, avant)                      # l'etat du generateur n'est pas touche
  b <- compare_local_regional(l, r, n_boot = 200, seed = 7)
  expect_identical(a$resume$ic_bas, b$resume$ic_bas)
  expect_error(compare_local_regional(l, 1), "SpatRaster")
  expect_error(compare_local_regional(l, r, level = 1.2), "level")
  expect_error(compare_local_regional(l, r, gain_min = -1), "gain_min")
  expect_error(compare_local_regional(l, r, n_boot = 2), "n_boot")
})

test_that("select_trophic_map ne remplace jamais sans decision positive explicite", {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 1e6, xmax = 1000040, ymin = 6.8e6, ymax = 6800040,
                   crs = "EPSG:2154", vals = 1)
  h <- r * 2
  maps <- list(trophic = r, hydric = h)
  poison <- "carte locale : ne doit jamais etre lue"
  s0 <- select_trophic_map(maps, poison, NULL)
  expect_identical(s0$maps, maps)
  expect_equal(s0$publiee, "regionale")
  non <- list(remplace = FALSE, resume = data.frame(motif = "non"))
  s1 <- select_trophic_map(maps, poison, non)
  expect_identical(s1$maps, maps)
  expect_equal(s1$motif, "non")
  loc <- r * 10
  oui <- list(remplace = TRUE, resume = data.frame(motif = "oui"))
  s2 <- select_trophic_map(maps, loc, oui)
  expect_equal(s2$publiee, "locale")
  expect_equal(terra::values(s2$maps$trophic)[1], 10)
  expect_identical(s2$maps$hydric, h)                       # les autres gradients restent regionaux
  expect_error(select_trophic_map(maps, NULL, oui), "sans carte locale")
  expect_error(select_trophic_map(list(a = 1), NULL, NULL), "trophic")
})

cfg_local <- function(modif = list()) {
  cfg <- list(ser_code = "D11",
              emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000,
                                  crs = 2154),
              buffer_m = 5000, resolution_m = 20, crs = 2154, data_dir = "data",
              laz_dir = "data/laz", out_dir = "data/sorties", ifn_precision_m = 700)
  f <- tempfile(fileext = ".yml")
  yaml::write_yaml(utils::modifyList(cfg, modif), f)
  f
}

test_that("config : seuils de la comparaison local / regional (provisoires), controles", {
  cfg <- read_config(cfg_local())
  expect_equal(cfg$local_gain_min, 0.02)
  expect_equal(cfg$local_min_ancrages, 20L)
  expect_equal(cfg$local_min_blocs, 10L)
  expect_equal(cfg$local_ic_niveau, 0.95)
  expect_equal(cfg$local_bootstrap, 1000L)
  expect_equal(read_config(cfg_local(list(local_gain_min = 0.05)))$local_gain_min, 0.05)
  expect_error(read_config(cfg_local(list(local_gain_min = -0.1))), "local_gain_min")
  expect_error(read_config(cfg_local(list(local_ic_niveau = 1))), "local_ic_niveau")
  expect_error(read_config(cfg_local(list(local_min_blocs = 0))), "local_min_blocs")
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installe")
  expect_match(paste(readLines(f, encoding = "UTF-8"), collapse = "\n"),
               "provisoire, sans source, à vérifier", fixed = TRUE)
})

test_that("_targets.R : le local n'entre dans maps que par select_trophic_map", {
  f <- testthat::test_path("..", "..", "_targets.R")
  skip_if_not(file.exists(f), "_targets.R absent du paquet installe")
  l <- readLines(f, encoding = "UTF-8")
  debuts <- grep("^\\s*tar_target\\(", l)
  nom <- sub("^\\s*tar_target\\(([A-Za-z_0-9.]+).*$", "\\1", l[debuts])
  fin <- c(debuts[-1] - 1L, length(l))
  bloc <- function(n) paste(unlist(Map(function(a, b) l[a:b], debuts[nom == n], fin[nom == n])),
                            collapse = "\n")
  skip_if(!"maps_regional" %in% nom, "cibles reelles absentes de _targets.R")
  reel <- function(n) {            # derniere definition (le mode reel suit le mode demo)
    i <- which(nom == n)
    i <- i[length(i)]
    paste(l[debuts[i]:fin[i]], collapse = "\n")
  }
  expect_match(reel("maps"), "select_trophic_map", fixed = TRUE)
  expect_false(grepl("local_trophic\\$model|predict_raster", reel("maps")))
  expect_false(grepl("local", bloc("maps_regional")))
  expect_match(bloc("comparaison_locale"), "compare_local_regional", fixed = TRUE)
  expect_match(bloc("comparaison_locale"), "maps_regional", fixed = TRUE)   # le regional, jamais maps
})
