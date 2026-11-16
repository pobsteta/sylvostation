# Tests de la mission 007 : GBIF, nettoyage, mailles, GNSS. Aucun reseau.
# Jeux d'essai synthetiques (synthetic = TRUE) : inst/extdata/synth_occ.csv,
# synth_gnss.csv. Les points ont ete fabriques en Lambert-93 (x = est, y = nord) puis
# convertis en WGS84 ; la maille A est [1010000 ; 1010050[ x [6795000 ; 6795050[.

synth_occ <- function() {
  f <- system.file("extdata", "synth_occ.csv", package = "sylvostation")
  if (!nzchar(f)) f <- testthat::test_path("..", "..", "inst", "extdata", "synth_occ.csv")
  utils::read.csv(f, stringsAsFactors = FALSE, na.strings = "")
}

synth_ind <- function() {
  data.frame(species = paste("Synthia", c("alpha", "beta", "gamma", "delta", "epsilon",
                                          "zeta", "eta", "theta")),
             trophique = c(1, 2, 3, 4, 5, 6, 7, 8),
             humidite = c(2, 2, 2, 4, 4, 4, 6, 6), synthetic = TRUE)
}

test_that("le jeu synthetique est marque synthetic = TRUE", {
  expect_true(all(synth_occ()$synthetic))
})

test_that("get_gbif sans identifiants echoue clairement, sans reseau", {
  skip_if_not_installed("rgbif")
  if (requireNamespace("withr", quietly = TRUE)) {
    withr::local_envvar(c(GBIF_USER = NA, GBIF_PWD = NA, GBIF_EMAIL = NA))
  } else {
    old <- Sys.getenv(c("GBIF_USER", "GBIF_PWD", "GBIF_EMAIL"), unset = NA)
    Sys.unsetenv(c("GBIF_USER", "GBIF_PWD", "GBIF_EMAIL"))
    on.exit(for (n in names(old)) {
      if (!is.na(old[[n]])) do.call(Sys.setenv, stats::setNames(list(old[[n]]), n))
    })
  }
  expect_error(get_gbif(c(1007000, 6790000, 1022000, 6805000)), "Identifiants GBIF manquants")
  expect_error(get_gbif(c(1007000, 6790000, 1022000, 6805000), user = "u", pwd = "p"),
               "Identifiants GBIF manquants")
})

test_that("l'emprise est reprojetee en WGS84 (referentiels.md, par. 8)", {
  wkt <- sylvostation:::.emprise_wkt_wgs84(c(1007000, 6790000, 1022000, 6805000))
  g <- sf::st_as_sfc(wkt, crs = 4326)
  xy <- sf::st_coordinates(g)[, 1:2]
  # coin sud-ouest : longitude 7.1290454, latitude 48.13811 (valeurs du referentiel)
  expect_equal(unname(xy[1, ]), c(7.1290454, 48.13811), tolerance = 1e-5)
  # sens anti-horaire : aire signee positive en coordonnees planes
  x <- xy[, 1]; y <- xy[, 2]; n <- length(x)
  expect_gt(sum(x[-n] * y[-1] - x[-1] * y[-n]), 0)
  expect_error(sylvostation:::.emprise_wkt_wgs84(c(1, 2, 3)), "xmin, ymin")
  # degres etiquetes 2154 : refuses par assert_crs_2154
  bad <- sf::st_sfc(sf::st_polygon(list(matrix(c(7, 48, 8, 48, 8, 49, 7, 49, 7, 48),
                                               ncol = 2, byrow = TRUE))), crs = 2154)
  expect_error(sylvostation:::.emprise_wkt_wgs84(bad), "implausibles")
})

test_that("les predicats du brief sont construits", {
  skip_if_not_installed("rgbif")
  p <- sylvostation:::.gbif_predicates("POLYGON ((0 0, 1 0, 1 1, 0 0))", 2000, 25, FALSE)
  types <- vapply(p, function(z) z$type, character(1))
  expect_equal(types, c("within", "equals", "equals", "equals", "greaterThanOrEquals",
                        "lessThanOrEquals"))
  expect_equal(as.character(p[[2]]$key), "TAXON_KEY")
  expect_equal(as.character(p[[2]]$value), "7707728")
  expect_equal(as.character(p[[6]]$key), "COORDINATE_UNCERTAINTY_IN_METERS")
  expect_equal(as.character(p[[6]]$value), "25")
  p2 <- sylvostation:::.gbif_predicates("POLYGON ((0 0, 1 0, 1 1, 0 0))", 2000, 25, TRUE)
  expect_equal(as.character(attr(p2[[6]], "type")), "or")
  expect_equal(as.character(p2[[6]][[2]]$type), "isNull")
  p3 <- sylvostation:::.gbif_predicates("POLYGON ((0 0, 1 0, 1 1, 0 0))", 2000, NULL, FALSE)
  expect_length(p3, 5)
})

test_that("les arguments du mode search suivent le referentiel", {
  a <- sylvostation:::.gbif_search_args("POLYGON ((0 0, 1 0, 1 1, 0 0))", 2000, 25, 500)
  expect_equal(a$taxonKey, 7707728L)
  expect_equal(a$checklistKey, "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c")
  expect_equal(a$coordinateUncertaintyInMeters, "0,25")
  expect_match(a$year, "^2000,[0-9]{4}$")
  expect_null(sylvostation:::.gbif_search_args("W", 2000, NULL, 10)$coordinateUncertaintyInMeters)
})

test_that("clean_occ reprojette en 2154, exclut l'IFN et trie la precision", {
  p <- clean_occ(synth_occ())
  expect_s3_class(p, "sf")
  expect_equal(sf::st_crs(p), sf::st_crs(2154))
  expect_no_error(assert_crs_2154(p))
  log <- attr(p, "clean_log")
  n <- stats::setNames(log$n, log$etape)
  expect_equal(unname(n["entree"]), 21L)
  expect_equal(unname(n["coordonnees_presentes"]), 20L)
  expect_equal(unname(n["hors_jeux_exclus"]), 18L)   # 2 releves IFN ecartes
  expect_equal(unname(n["precision_retenue"]), 15L)  # > 25 m, NA, generalise ecartes
  expect_equal(nrow(p), 15L)
  expect_false(any(p$dataset_key %in% IFN_GBIF_DATASET_KEYS))
  expect_true(all(p$loc_precision_m <= 25 & !is.na(p$loc_precision_m)))
  expect_true("license" %in% names(p))
  expect_true("CC_BY_NC_4_0" %in% p$license)  # licence conservee
  # un point connu : G (S001) = (1010011, 6795011) en Lambert-93 a moins de 0,5 m
  xy <- sf::st_coordinates(p[p$gbif_id == "S001", ])
  expect_lt(max(abs(unname(xy[1, ]) - c(1010011, 6795011))), 0.1)  # x = est, y = nord
})

test_that("clean_occ : points a precision inconnue gardes sur demande, puis refuses en extraction fine", {
  p <- clean_occ(synth_occ(), keep_unknown = TRUE)
  expect_equal(nrow(p), 17L)  # 15 + incertitude absente + generalise
  expect_equal(sum(is.na(p$loc_precision_m)), 2L)
  expect_error(assert_no_fine_extract_on_ifn(p, "pente"), "précision")
  expect_error(assert_no_fine_extract_on_ifn(p, "mhc"), "précision")
})

test_that("clean_occ : IFN gardee = marquee 700 m et refusee par le filtre de precision", {
  p <- clean_occ(synth_occ(), exclude_datasets = character(0))
  expect_equal(nrow(p), 15L)  # IFN a 700 m > 25 m : ecartee quand meme
  p2 <- clean_occ(synth_occ(), exclude_datasets = character(0), max_uncertainty = 1000)
  ifn <- p2[p2$source == "ifn", ]
  expect_equal(nrow(ifn), 2L)
  expect_true(all(ifn$loc_precision_m == 700))
  expect_error(assert_no_fine_extract_on_ifn(ifn, "pente"), "IFN")
})

test_that("clean_occ : filtre foret BD Foret (code_tfv)", {
  # Foret = maille A seulement (code FF2G61-61) ; maille C en lande LA4 ; B en FF0
  mk <- function(x0, code) sf::st_sf(code_tfv = code, geometry = sf::st_sfc(
    sf::st_polygon(list(matrix(c(x0, 6795000, x0 + 50, 6795000, x0 + 50, 6795050,
                                 x0, 6795050, x0, 6795000), ncol = 2, byrow = TRUE))),
    crs = 2154))
  forest <- rbind(mk(1010000, "FF2G61-61"), mk(1010050, "FF0"), mk(1010100, "LA4"))
  p <- clean_occ(synth_occ(), forest = forest)
  expect_equal(nrow(p), 7L)  # maille A seulement
  expect_equal(tail(attr(p, "clean_log")$etape, 1), "en_foret_bdforet")
  expect_true(all(sf::st_coordinates(p)[, 1] < 1010050))
  expect_error(clean_occ(synth_occ(), forest = data.frame(a = 1)), "code_tfv")
  forest_bad <- sf::st_transform(forest, 4326)
  expect_error(clean_occ(synth_occ(), forest = forest_bad), "EPSG:2154")
})

test_that("clean_occ : filtre canopee MHC > 5 m et regle bloquante", {
  r <- terra::rast(xmin = 1010000, xmax = 1010200, ymin = 6795000, ymax = 6795100,
                   resolution = 50, crs = "EPSG:2154")
  terra::values(r) <- c(10, 2, 8, 10, 2, 8, 10, 2)[seq_len(terra::ncell(r))]
  # lignes du haut (y > 6795050) : colonnes 1..4 = 10, 2, 8, 10 ; bas : 2, 8, 10, 2
  p <- clean_occ(synth_occ(), canopy = r)
  expect_equal(tail(attr(p, "clean_log")$etape, 1), "canopee_sup_seuil")
  expect_true(nrow(p) < 15L && nrow(p) > 0L)
  # la maille A (colonne 1, ligne du bas) vaut 2 m : ecartee ; maille C (colonne 3, bas) 10 m
  expect_false(any(sf::st_coordinates(p)[, 1] < 1010050))
  # precision inconnue + extraction fine : bloque
  expect_error(clean_occ(synth_occ(), keep_unknown = TRUE, canopy = r), "précision")
})

test_that("clean_occ valide ses entrees", {
  expect_error(clean_occ(1), "data.frame")
  expect_error(clean_occ(data.frame(a = 1)), "Colonnes manquantes")
  expect_error(clean_occ(synth_occ(), max_uncertainty = -1), "positif")
})

test_that("grid_bioindication : points connus dans la bonne maille de 50 m", {
  p <- clean_occ(synth_occ())
  g <- grid_bioindication(p, synth_ind(), cell = 50, min_species = 5)
  expect_s3_class(g, "sf")
  expect_equal(sf::st_crs(g), sf::st_crs(2154))
  expect_equal(attr(g, "n_mailles_occupees"), 3L)
  expect_equal(nrow(g), 2L)  # A (6 especes) et C (5) ; B (3) ecartee
  expect_equal(g$cell_id, c("20200_135900", "20202_135900"))
  a <- g[g$x_min == 1010000, ]
  expect_equal(a$y_min, 6795000)
  expect_equal(a$poids, 6L)
  expect_equal(a$n_occ, 7L)  # 7 occurrences, 6 especes
  expect_equal(a$trophique, mean(1:6))
  expect_equal(a$humidite, mean(c(2, 2, 2, 4, 4, 4)))
  # le point au bord nord-est (1010149.9 ; 6795049.9) est dans la maille C
  cc <- g[g$x_min == 1010100, ]
  expect_equal(cc$poids, 5L)
  expect_equal(cc$trophique, mean(c(1, 2, 3, 4, 5)))
  expect_equal(as.numeric(sf::st_area(g$geometry[1])), 2500)
  # mailles de 100 m : [1010000 ; 1010100[ regroupe A (6 especes) et B (3 especes, deja
  # presentes dans A) -> 6 especes ; [1010100 ; 1010200[ est la maille C (5 especes)
  g100 <- grid_bioindication(p, synth_ind(), cell = 100, min_species = 5)
  expect_equal(nrow(g100), 2L)
  expect_equal(g100$x_min, c(1010000, 1010100))
})

test_that("grid_bioindication : seules les especes indicatrices comptent", {
  p <- clean_occ(synth_occ())
  ind <- synth_ind()[1:4, ]  # 4 especes indicatrices seulement
  g <- grid_bioindication(p, ind, cell = 50, min_species = 5)
  expect_equal(nrow(g), 0L)
  expect_equal(attr(g, "n_mailles_occupees"), 3L)
  g4 <- grid_bioindication(p, ind, cell = 50, min_species = 4)
  expect_equal(sort(g4$poids), c(4L, 4L))
})

test_that("grid_bioindication refuse les precisions absentes ou trop grossieres", {
  p <- clean_occ(synth_occ(), keep_unknown = TRUE)
  expect_error(grid_bioindication(p, synth_ind()), "précision|Précision")
  p0 <- clean_occ(synth_occ())
  p0$loc_precision_m <- NULL
  expect_error(grid_bioindication(p0, synth_ind()), "Précision")
  p1 <- clean_occ(synth_occ())
  p1$loc_precision_m <- 30
  expect_error(grid_bioindication(p1, synth_ind(), cell = 50), "demi-maille")
  expect_no_error(grid_bioindication(p1, synth_ind(), cell = 100))
  expect_error(grid_bioindication(sf::st_transform(p0, 4326), synth_ind()), "EPSG:2154")
  expect_error(grid_bioindication(data.frame(a = 1), synth_ind()), "sf")
  expect_error(grid_bioindication(clean_occ(synth_occ()), data.frame(species = "a")),
               "gradient")
})

test_that("load_gnss lit du Lambert-93 et exige la precision", {
  f <- system.file("extdata", "synth_gnss.csv", package = "sylvostation")
  if (!nzchar(f)) f <- testthat::test_path("..", "..", "inst", "extdata", "synth_gnss.csv")
  g <- load_gnss(f)
  expect_s3_class(g, "sf")
  expect_equal(sf::st_crs(g), sf::st_crs(2154))
  expect_equal(nrow(g), 6L)
  expect_true(all(g$source == "gnss"))
  expect_true(all(g$synthetic))
  expect_equal(unname(sf::st_coordinates(g)[1, ]), c(1010012, 6795012))  # x = est, y = nord
  expect_no_error(assert_no_fine_extract_on_ifn(g, "pente"))  # precision 3 a 8 m
  # sans precision : refuse
  d <- utils::read.csv(f)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  utils::write.csv(d[, setdiff(names(d), "loc_precision_m")], tmp, row.names = FALSE)
  expect_error(load_gnss(tmp), "loc_precision_m")
  d$loc_precision_m[1] <- NA
  utils::write.csv(d, tmp, row.names = FALSE)
  expect_error(load_gnss(tmp), "sans NA")
  expect_error(load_gnss("absent.csv"), "introuvable")
})

test_that("load_gnss convertit le WGS84 en Lambert-93 (lon, lat)", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  pt <- sf::st_transform(sf::st_sfc(sf::st_point(c(1010000, 6795000)), crs = 2154), 4326)
  ll <- sf::st_coordinates(pt)
  utils::write.csv(data.frame(id = "G", x = ll[1, 1], y = ll[1, 2], loc_precision_m = 4),
                   tmp, row.names = FALSE)
  g <- load_gnss(tmp, epsg = 4326)
  expect_equal(sf::st_crs(g), sf::st_crs(2154))
  expect_equal(unname(sf::st_coordinates(g)[1, ]), c(1010000, 6795000), tolerance = 1e-6)
  expect_error(load_gnss(tmp, epsg = 3857), "2154 ou 4326")
})

test_that("clean_occ accepte la colonne `key` de occ_search a la place de gbifID", {
  o <- synth_occ()
  names(o)[names(o) == "gbifID"] <- "key"
  p <- clean_occ(o)
  expect_equal(nrow(p), 15L)
  expect_true("S001" %in% p$gbif_id)
})

test_that("la licence GBIF est normalisee en code de type", {
  l <- sylvostation:::.normalise_licence(c(
    "http://creativecommons.org/licenses/by-nc/4.0/legalcode",
    "http://creativecommons.org/licenses/by/4.0/legalcode",
    "http://creativecommons.org/publicdomain/zero/1.0/legalcode",
    "CC_BY_4_0", NA))
  expect_equal(l, c("CC_BY_NC_4_0", "CC_BY_4_0", "CC0_1_0", "CC_BY_4_0", NA))
  o <- synth_occ()
  o$license[1:2] <- c("http://creativecommons.org/licenses/by-nc/4.0/legalcode", "x")
  p <- clean_occ(o)
  expect_equal(p$license[p$gbif_id == "S001"], "CC_BY_NC_4_0")
})

test_that("get_gbif : le format de telechargement est un argument (SIMPLE_CSV par defaut)", {
  expect_equal(eval(formals(get_gbif)$format)[1], "SIMPLE_CSV")
  expect_error(get_gbif(c(1007000, 6790000, 1022000, 6805000), format = "XLS"), "arg")
})

# --- format partage de la mission 006 : synth_indicateurs.csv (separateur ;) ---
read_ind006 <- function() {
  f <- system.file("extdata", "synth_indicateurs.csv", package = "sylvostation")
  if (!nzchar(f)) f <- testthat::test_path("..", "..", "inst", "extdata", "synth_indicateurs.csv")
  utils::read.delim(f, sep = ";", stringsAsFactors = FALSE, encoding = "UTF-8")
}

# 6 especes du fichier dans une meme maille de 50 m (x = est, y = nord), plus une espece
# absente du fichier ; `nom_gbif` = nom GBIF sans l'auteur ni le nom vernaculaire
occ_ind006 <- function(ind, avec_cd_ref = TRUE) {
  sp <- ind[1:6, ]
  d <- data.frame(x = 1010005 + 5 * (1:7), y = 6795005 + 5 * (1:7),
                  species = c(sub(" \\(.*$", "", sp$nom), "Inconnua nulla"),
                  cd_ref = c(sp$cd_ref, 999999999), loc_precision_m = 10,
                  stringsAsFactors = FALSE)
  if (!avec_cd_ref) d$cd_ref <- NULL
  sf::st_as_sf(d, coords = c("x", "y"), crs = 2154)
}

test_that("grid_bioindication lit synth_indicateurs.csv (cd_ref, ph, azote, humidite)", {
  ind <- read_ind006()
  expect_true(all(ind$synthetic))
  g <- grid_bioindication(occ_ind006(ind), ind, cell = 50, min_species = 5)
  expect_equal(nrow(g), 1L)
  expect_equal(g$poids, 6L)
  expect_equal(g$n_occ, 7L)
  expect_true(all(c("ph", "azote", "humidite") %in% names(g)))
  expect_false(any(c("cd_ref", "synthetic", "nom") %in% names(g)))
  expect_equal(g$ph, mean(ind$ph[1:6]))
  expect_equal(g$azote, mean(ind$azote[1:6]))
  expect_equal(g$humidite, mean(ind$humidite[1:6]))
  # espece non appariee : listee, pas supprimee en silence
  na <- attr(g, "especes_non_appariees")
  expect_equal(na$species, "Inconnua nulla")
  expect_equal(na$n_occ, 1L)
  lg <- stats::setNames(attr(g, "log_appariement")$n, attr(g, "log_appariement")$etape)
  expect_equal(unname(lg["apparie_cd_ref"]), 6L)
  expect_equal(unname(lg["non_apparie"]), 1L)
})

test_that("grid_bioindication : cd_ref prime sur le nom, repli par nom marque", {
  ind <- read_ind006()
  p <- occ_ind006(ind)
  p$species[1:6] <- paste("Nom GBIF different", 1:6)  # synonymes : le cd_ref apparie quand meme
  g <- grid_bioindication(p, ind, min_species = 5)
  expect_equal(g$poids, 6L)
  # sans cd_ref dans occ : repli par nom (nom vernaculaire entre parentheses ignore)
  g2 <- grid_bioindication(occ_ind006(ind, avec_cd_ref = FALSE), ind, min_species = 5)
  expect_equal(g2$poids, 6L)
  lg <- stats::setNames(attr(g2, "log_appariement")$n, attr(g2, "log_appariement")$etape)
  expect_equal(unname(lg["apparie_nom_a_verifier"]), 6L)
  # noms differents et pas de cd_ref : rien n'apparie, tout est liste
  p3 <- occ_ind006(ind, avec_cd_ref = FALSE)
  p3$species <- paste("Autre", 1:7)
  g3 <- grid_bioindication(p3, ind, min_species = 5)
  expect_equal(nrow(g3), 0L)
  expect_equal(nrow(attr(g3, "especes_non_appariees")), 7L)
})
