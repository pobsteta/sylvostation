# Mission 029 : plan d'echantillonnage des releves GNSS. Jeux synthetiques fabriques ici
# (synthetic = TRUE), aucun telechargement.

# Grille synthetique de 40 x 40 cellules de 20 m, origine (x = est 1010000, y = nord 6795000)
# en Lambert-93. Couches lisses, geologie en trois bandes verticales, foret partout sauf un
# bloc au sud-est, une route est-ouest a y = 6795110 et un sentier au nord.
synth_sampling <- function() {
  g <- terra::rast(nrows = 40, ncols = 40, xmin = 1010000, xmax = 1010800,
                   ymin = 6795000, ymax = 6795800, crs = "EPSG:2154")
  xy <- terra::xyFromCell(g, seq_len(terra::ncell(g)))  # x = est, y = nord
  u <- (xy[, 1] - 1010000) / 800
  v <- (xy[, 2] - 6795000) / 800
  mk <- function(val, nm) { r <- terra::rast(g); terra::values(r) <- val; names(r) <- nm; r }
  geo <- mk(1 + (u >= 1 / 3) + (u >= 2 / 3), "geologie")
  levels(geo) <- data.frame(id = 1:3, classe = c("synth_calcaire", "synth_gres", "synth_granite"))
  names(geo) <- "geologie"
  layers <- c(mk(500 + 200 * v, "altitude"), mk(10 + 20 * u * v, "pente"),
              mk(0.8 + 0.4 * u, "k_sv"), mk(100 + 50 * sin(3 * v), "is_topo"),
              mk(2 * (1 - v), "mrvbf"), mk(30 * v + 5 * u, "hauteur_reseau"), geo)
  forest <- mk(ifelse(u > 0.8 & v < 0.2, NA, 1), "foret")
  ligne <- function(y) sf::st_linestring(rbind(c(1009900, y), c(1010900, y)))
  brut <- sf::st_sf(nature = c("Route empierr\u00e9e", "Sentier"), prive = c(FALSE, FALSE),
                      geometry = sf::st_sfc(ligne(6795110), ligne(6795700), crs = 2154))
  list(layers = layers, forest = forest, access = filter_access(brut), brut = brut)
}

test_that("ACCESS_NATURES, BRAUN_BLANQUET, HUMUS_FORMS : listes fixees", {
  expect_true(all(c("Chemin", "Route empierr\u00e9e") %in% ACCESS_NATURES))
  expect_false(any(c("Sentier", "Escalier") %in% ACCESS_NATURES))
  expect_identical(BRAUN_BLANQUET, c("r", "+", "1", "2", "3", "4", "5"))
  expect_identical(HUMUS_FORMS, c("Mull", "Moder", "Mor", "Amphi", "Tangel"))
})

test_that("filter_access : natures, fictif, etat, acces physiquement impossible, restreint signale", {
  l <- function(i) sf::st_linestring(rbind(c(1010000, 6795000 + i), c(1010100, 6795000 + i)))
  x <- sf::st_sf(
    nature = c("Chemin", "Sentier", "Route \u00e0 1 chauss\u00e9e", "Route empierr\u00e9e",
               "Chemin", "Chemin", "Escalier"),
    fictif = c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
    etat_de_l_objet = c("En service", "En service", "En service", "En projet",
                        "En service", "En service", "En service"),
    acces_vehicule_leger = c("Libre", "Physiquement impossible", "Libre", "Libre",
                             "Restreint aux ayants droit", "Physiquement impossible", NA),
    prive = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
    geometry = sf::st_sfc(lapply(1:7, l), crs = 2154))
  f <- filter_access(x)
  expect_equal(nrow(f), 2L)
  expect_equal(f$acces_restreint, c(TRUE, TRUE))   # prive, puis ayants droit
  expect_true(is.data.frame(attr(f, "decompte")))
  expect_error(filter_access(data.frame(a = 1)), "nature")
})

test_that("get_access_network (fichier) : recoupe a l'emprise, filtre, EPSG:2154", {
  s <- synth_sampling()
  f <- tempfile(fileext = ".gpkg")
  sf::st_write(sf::st_transform(s$brut, 4326), f, quiet = TRUE)
  r <- get_access_network(c(1010000, 6795000, 1010800, 6795800), source = "file", path = f)
  expect_equal(nrow(r), 1L)  # le sentier est ecarte
  expect_true(sf::st_crs(r) == sf::st_crs(2154))
  r2 <- get_access_network(c(1010000, 6795000, 1010800, 6795200), "file", f, filter = FALSE)
  expect_equal(nrow(r2), 1L)  # le sentier (y = 6795700) est hors emprise
  expect_error(get_access_network(c(1010000, 6795000, 1010800, 6795800), "file", "absent.gpkg"),
               "existant")
})

test_that("access_cost : distance au troncon en metres, erreur sans troncon", {
  s <- synth_sampling()
  cst <- access_cost(s$layers, s$access)
  expect_equal(names(cst), "cout_m")
  # cellule de centre (x = est 1010010, y = nord 6795110) : la route y passe
  expect_equal(terra::extract(cst, cbind(1010010, 6795110))[1, 1], 0)
  # 300 m plus au nord : 15 cellules de 20 m
  expect_equal(terra::extract(cst, cbind(1010010, 6795410))[1, 1], 300)
  loin <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(
    rbind(c(1020000, 6800000), c(1020100, 6800000))), crs = 2154))
  expect_error(access_cost(s$layers, loin), "Aucun")
  expect_error(access_cost(s$layers, sf::st_transform(s$access, 4326)), "EPSG:2154")
})

test_that("homogeneous_cells : damier exclu, lisiere exclue, frontiere geologique exclue", {
  s <- synth_sampling()
  h <- homogeneous_cells(s$layers, s$forest)
  expect_equal(names(h), "homogene")
  # centre de la grille, loin des frontieres : homogene
  expect_equal(terra::extract(h, cbind(1010110, 6795410))[1, 1], 1)
  # frontiere geologique a x = 1010266,7 : cellule de centre 1010270 non homogene
  expect_equal(terra::extract(h, cbind(1010270, 6795410))[1, 1], 0)
  # bordure de la grille (voisinage incomplet) : non homogene
  expect_equal(terra::extract(h, cbind(1010010, 6795410))[1, 1], 0)
  # hors foret : NA
  expect_true(is.na(terra::extract(h, cbind(1010790, 6795010))[1, 1]))
  # damier sur la pente : toutes les cellules du damier exclues
  l2 <- s$layers
  xy <- terra::xyFromCell(l2, seq_len(terra::ncell(l2)))
  pen <- l2[["pente"]]
  terra::values(pen) <- ifelse(xy[, 2] > 6795500, ((xy[, 1] %/% 20 + xy[, 2] %/% 20) %% 2) * 40,
                               terra::values(pen))
  l2[["pente"]] <- pen
  h2 <- homogeneous_cells(l2, s$forest)
  expect_equal(terra::extract(h2, cbind(1010110, 6795610))[1, 1], 0)
  expect_error(homogeneous_cells(s$layers, s$forest, sd_ratio = 0), "positif")
})

test_that("sampling_frame : foret, couches vides ecartees avec avertissement, candidats", {
  s <- synth_sampling()
  l <- s$layers
  vide <- l[["mrvbf"]] * NA
  names(vide) <- "mrvbf"
  l[["mrvbf"]] <- vide
  expect_warning(fr <- sampling_frame(l, s$forest, s$access), class = "sylvostation_non_calcule")
  expect_false("mrvbf" %in% attr(fr, "vars"))
  expect_true(is.factor(fr$geologie))
  # toutes les cellules sont forestieres, les candidates a <= 300 m de la route
  f <- terra::extract(s$forest, fr$cell)[, 1]
  expect_true(all(f == 1))
  expect_true(all(fr$cout_m[fr$candidat] <= 300))
  expect_true(any(fr$cout_m > 300) && any(fr$candidat))
  expect_error(sampling_frame(s$layers, s$forest, s$access, cost_max_m = -1), "positif")
})

test_that("sampling_plan : point connu dans la bonne cellule en Lambert-93", {
  s <- synth_sampling()
  # x = est 1010030, y = nord 6795010 : colonne 2, ligne 40 (la derniere, au sud)
  cel <- terra::cellFromXY(s$layers, cbind(1010030, 6795010))
  expect_equal(unname(terra::rowColFromCell(s$layers, cel)), unname(cbind(40, 2)))
  fr <- sampling_frame(s$layers, s$forest, s$access)
  expect_equal(fr$x[fr$cell == cel], 1010030)
  expect_equal(fr$y[fr$cell == cel], 6795010)
})

test_that("sampling_plan : centres de cellules candidates, remplacants de meme classe, distance", {
  skip_if_not_installed("clhs")
  s <- synth_sampling()
  p <- sampling_plan(s$layers, s$forest, s$access, n = 12, seed = 29, iter = 300)
  expect_true(sf::st_crs(p) == sf::st_crs(2154))
  expect_equal(sum(p$rang == 0L), 12L)
  expect_equal(sum(p$rang > 0L), 24L)
  # chaque point est le centre de sa cellule (x = est, y = nord)
  xy <- sf::st_coordinates(p)
  expect_equal(unname(xy), unname(terra::xyFromCell(s$layers, p$cell)))
  expect_equal(terra::cellFromXY(s$layers, xy), p$cell)
  fr <- attr(p, "frame")
  expect_true(all(p$cell %in% fr$cell[fr$candidat]))
  expect_true(all(p$cout_m <= 300))
  # remplacants : meme geologie que leur point
  par <- p[p$rang == 0L, ]
  r <- p[p$rang > 0L, ]
  expect_equal(as.character(r$geologie), as.character(par$geologie[match(r$id_parent, par$id)]))
  # remplacants a au moins 60 m de tout autre point du plan (les points tires par clhs ne
  # sont pas contraints entre eux)
  d <- as.matrix(stats::dist(xy))
  diag(d) <- Inf
  expect_gte(min(d[p$rang > 0L, ]), 60)
  expect_equal(p$loc_precision_m, rep(0, nrow(p)))
  expect_false(any(p$acces_restreint))
})

test_that("sampling_plan : reproductible par seed, sans effet sur le generateur global", {
  skip_if_not_installed("clhs")
  s <- synth_sampling()
  set.seed(1)
  avant <- .Random.seed
  a <- sampling_plan(s$layers, s$forest, s$access, n = 10, seed = 7, iter = 300)
  expect_identical(.Random.seed, avant)
  b <- sampling_plan(s$layers, s$forest, s$access, n = 10, seed = 7, iter = 300)
  c <- sampling_plan(s$layers, s$forest, s$access, n = 10, seed = 8, iter = 300)
  expect_identical(a$cell, b$cell)
  expect_false(identical(a$cell, c$cell))
})

test_that("sampling_plan : erreurs (seed, trop de points, crs)", {
  skip_if_not_installed("clhs")
  s <- synth_sampling()
  expect_error(sampling_plan(s$layers, s$forest, s$access, n = 5), "seed")
  expect_error(sampling_plan(s$layers, s$forest, s$access, n = 5000, seed = 1), "candidates")
  expect_error(sampling_plan(s$layers, s$forest, sf::st_transform(s$access, 4326), seed = 1),
               "EPSG:2154")
})

test_that("sampling_coverage : KS et quantiles par couche, proportions des classes", {
  skip_if_not_installed("clhs")
  s <- synth_sampling()
  p <- sampling_plan(s$layers, s$forest, s$access, n = 15, seed = 3, iter = 300)
  cv <- sampling_coverage(p)
  expect_setequal(unique(cv$variable), names(s$layers))
  ks <- cv[cv$variable == "k_sv" & cv$indicateur == "ks_p", "echantillon"]
  expect_true(ks >= 0 && ks <= 1)
  cl <- cv[cv$variable == "geologie", ]
  expect_equal(sum(cl$echantillon), 1)
  expect_equal(sum(cl$foret), 1)
  expect_error(sampling_coverage(data.frame()), "sampling_plan")
})

test_that("field_time : somme des temps, jours arrondis au-dessus", {
  pts <- sf::st_sf(id = c("P1", "P2"), rang = 0L, cout_m = c(100, 200),
                   geometry = sf::st_sfc(sf::st_point(c(1010000, 6795000)),
                                         sf::st_point(c(1013000, 6799000)), crs = 2154))
  ft <- field_time(pts, detour = 1)
  expect_equal(ft$par_point$id, c("P1", "P2"))
  # marche : 2 * 100 m a 2 km/h = 6 min ; route : 5 000 m a 30 km/h = 10 min
  expect_equal(ft$par_point$marche_min, c(6, 12))
  expect_equal(ft$par_point$route_min, c(0, 10))
  expect_equal(ft$total_h, (80 * 2 + 6 + 12 + 10) / 60)
  expect_equal(ft$jours, 1)
  expect_error(field_time(data.frame()), "sampling_plan")
})

test_that("write_sampling_plan : GeoPackage en 2154, GPX en WGS84, prefixe synth_", {
  skip_if_not_installed("clhs")
  s <- synth_sampling()
  p <- sampling_plan(s$layers, s$forest, s$access, n = 8, seed = 2, iter = 300)
  d <- tempfile("plan_")
  f <- write_sampling_plan(p, sampling_coverage(p), d, s$access, s$forest, synthetic = TRUE)
  expect_true(all(file.exists(f)))
  expect_true(all(startsWith(basename(f), "synth_")))
  g <- sf::st_read(f[1], quiet = TRUE)
  expect_true(sf::st_crs(g) == sf::st_crs(2154))
  expect_true(all(g$synthetic))
  w <- sf::st_read(f[2], layer = "waypoints", quiet = TRUE)
  expect_true(sf::st_crs(w) == sf::st_crs(4326))
  expect_equal(nrow(w), nrow(p))
  back <- sf::st_coordinates(sf::st_transform(w, 2154))
  expect_equal(unname(back), unname(sf::st_coordinates(p)), tolerance = 0.01)
})

# Releve synthetique conforme au gabarit de la flore.
synth_flore <- function(prec = 4) {
  data.frame(id = c("P01", "P01", "P02"), x = c(1010110, 1010110, 1010330),
             y = c(6795410, 6795410, 6795250), loc_precision_m = prec,
             species = c("Synthia alpha", "Synthia beta", "Synthia alpha"),
             cd_nom = "", rec_arborescente = c("4", "", ""), rec_arbustive = c("", "+", ""),
             rec_herbacee = c("1", "r", "2"), rec_muscinale = "", date = "2027-06-01",
             observateur = "synth", synthetic = TRUE, stringsAsFactors = FALSE)
}

test_that("gabarits : colonnes conformes aux lecteurs", {
  fl <- system.file("terrain", "gabarit_flore.csv", package = "sylvostation")
  st <- system.file("terrain", "gabarit_station.csv", package = "sylvostation")
  expect_true(nzchar(fl) && nzchar(st))
  expect_identical(names(utils::read.csv(fl, check.names = FALSE)), .FLORE_COLS)
  expect_identical(names(utils::read.csv(st, check.names = FALSE)), .STATION_COLS)
})

test_that("read_field_sheet : saisie lue par load_gnss puis gnss_field_gradients", {
  f <- tempfile("synth_flore_", fileext = ".csv")
  utils::write.csv(synth_flore(), f, row.names = FALSE)
  g <- read_field_sheet(f)
  expect_true(sf::st_crs(g) == sf::st_crs(2154))
  expect_equal(unique(g$source), "gnss")
  ind <- data.frame(nom = c("Synthia alpha", "Synthia beta"), ph = c(5, 7), azote = 4,
                    humidite = 6)
  r <- terra::rast(xmin = 1009000, xmax = 1012000, ymin = 6794000, ymax = 6797000,
                   resolution = 1000, crs = "EPSG:2154", nlyrs = 2)
  terra::values(r) <- cbind(300, 8)
  names(r) <- c("coarse_p_etp_sv", "coarse_t_moy")
  ax <- list(vars = names(r), center = c(coarse_p_etp_sv = 300, coarse_t_moy = 8),
             scale = c(coarse_p_etp_sv = 1, coarse_t_moy = 1),
             loadings = c(coarse_p_etp_sv = -0.7, coarse_t_moy = 0.7))
  gr <- gnss_field_gradients(g, ind, r, ax)
  expect_equal(gr$id, c("P01", "P02"))
  expect_equal(gr$n_especes, c(2L, 1L))
  # point connu : P01 (x = est 1010110, y = nord 6795410) dans la cellule ligne 20, colonne 6
  s <- synth_sampling()
  cel <- terra::cellFromXY(s$layers, sf::st_coordinates(g[g$id == "P01", ][1, ]))
  expect_equal(unname(terra::rowColFromCell(s$layers, cel)), unname(cbind(20, 6)))
})

test_that("read_field_sheet : refus (precision > 25 m, code hors Braun-Blanquet, doublon, strates vides)", {
  w <- function(d) { f <- tempfile(fileext = ".csv"); utils::write.csv(d, f, row.names = FALSE); f }
  expect_error(read_field_sheet(w(synth_flore(prec = 30))), "25")
  d <- synth_flore(); d$rec_herbacee[1] <- "50%"
  expect_error(read_field_sheet(w(d)), "Braun-Blanquet")
  d <- synth_flore(); d$species[2] <- "Synthia alpha"
  expect_error(read_field_sheet(w(d)), "double")
  d <- synth_flore(); d[3, .FLORE_REC] <- ""
  expect_error(read_field_sheet(w(d)), "strate")
  d <- synth_flore(); d$x[2] <- 1010200
  expect_error(read_field_sheet(w(d)), "emplacements")
  d <- synth_flore(); d$x <- 7.2; d$y <- 48.2
  expect_error(read_field_sheet(w(d)), "Lambert-93")
  expect_error(read_field_sheet(w(synth_flore()[, -5])), "species")
})

test_that("read_station_sheet : humus en grandes formes, rang, tariere", {
  d <- data.frame(id = c("P01", "P02"), x = c(1010110, 1010330), y = c(6795410, 6795250),
                  loc_precision_m = c(3, 4), n_mesures_gnss = 60, date = "2027-06-01",
                  observateur = "synth", id_plan = c("P01", "P02-R1"), rang_utilise = c(0, 1),
                  humus = c("Mull", ""), tariere_profondeur_cm = c(45, NA),
                  tariere_refus = c("oui", ""), photos = "", remarque = "", synthetic = TRUE)
  w <- function(d) { f <- tempfile(fileext = ".csv"); utils::write.csv(d, f, row.names = FALSE); f }
  s <- read_station_sheet(w(d))
  expect_equal(nrow(s), 2L)
  expect_true(sf::st_crs(s) == sf::st_crs(2154))
  e <- d; e$humus[2] <- "Eumull"
  expect_error(read_station_sheet(w(e)), "humus")
  e <- d; e$rang_utilise[1] <- 3
  expect_error(read_station_sheet(w(e)), "rang_utilise")
  e <- d; e$tariere_refus[1] <- "peut-etre"
  expect_error(read_station_sheet(w(e)), "tariere_refus")
  e <- d; e$loc_precision_m[1] <- 26
  expect_error(read_station_sheet(w(e)), "25")
})

test_that("plan_gnss.R : le script d'application se lit sans erreur", {
  f <- system.file("scripts", "plan_gnss.R", package = "sylvostation")
  expect_true(nzchar(f))
  expect_silent(parse(f))
})
