dir_ifn <- function() system.file("extdata", package = "sylvostation")

# --- mark_ifn : précision venue de la config ---------------------------------
test_that("mark_ifn accepte une précision issue de la config et la valide", {
  p <- mark_ifn(data.frame(x = 1, y = 2), precision_m = 500)
  expect_equal(p$loc_precision_m, 500)
  expect_equal(mark_ifn(data.frame(x = 1))$loc_precision_m, 700)
  expect_error(mark_ifn(data.frame(x = 1), precision_m = -1), "positif")
  expect_error(mark_ifn(data.frame(x = 1), precision_m = NA), "positif")
  f <- tempfile(fileext = ".yml")
  writeLines(c(
    'ser_code: "D11"',
    "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
    "buffer_m: 5000", "resolution_m: 25", "crs: 2154",
    "data_dir: data", "laz_dir: data/laz", "out_dir: data/sorties",
    "ifn_precision_m: 650"), f)
  cfg <- read_config(f)
  expect_equal(mark_ifn(data.frame(x = 1), cfg$ifn_precision_m)$loc_precision_m, 650)
})

# --- load_ifn (extraits réels) -----------------------------------------------
test_that("load_ifn lit les extraits réels : 100 placettes, sf Lambert-93, marquées IFN", {
  ifn <- load_ifn(dir_ifn())
  expect_s3_class(ifn$placettes, "sf")
  expect_equal(nrow(ifn$placettes), 100)
  expect_equal(sf::st_crs(ifn$placettes)$epsg, 2154)
  expect_true(all(ifn$placettes$source == "ifn"))
  expect_true(all(ifn$placettes$loc_precision_m == 700))
  expect_identical(attr(ifn$placettes, "source"), "ifn")
  expect_true(all(ifn$flore$loc_precision_m == 700))
  expect_false(anyDuplicated(ifn$placettes$id_placette) > 0)
  # jointure ECOLOGIE : colonnes présentes, sans doublon de clé
  expect_true(all(c("TEXT2", "PROF2", "DATEECO", "HUMUS") %in% names(ifn$placettes)))
  expect_s3_class(ifn$placettes$DATEECO, "Date")
  expect_false(anyNA(ifn$placettes$DATEECO))
  # FLORE et ARBRE : clés numériques, pas de colonne vide issue du ';' final
  expect_type(ifn$flore$CD_REF, "double")
  expect_false("" %in% names(ifn$arbre))
  expect_equal(nrow(ifn$arbre), 1550)
  expect_true(all(ifn$flore$id_placette %in% ifn$placettes$id_placette))
})

test_that("load_ifn : un point connu tombe dans la bonne cellule (x = est, y = nord)", {
  ifn <- load_ifn(dir_ifn())
  p <- ifn$placettes[ifn$placettes$id_placette == "2025_2012026", ]
  xy <- sf::st_coordinates(p)
  expect_equal(unname(xy[1, ]), c(1007726, 6795945))   # XL = est, YL = nord
  grille <- terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
                        resolution = 25, crs = "EPSG:2154")
  cell <- terra::cellFromXY(grille, xy)
  # colonne = floor(726 / 25) + 1 = 30 ; ligne = floor((6805000 - 6795945) / 25) + 1 = 363
  expect_equal(terra::rowColFromCell(grille, cell), cbind(row = 363, col = 30),
               ignore_attr = TRUE)
  # toutes les placettes de l'extrait sont dans l'emprise du massif test
  b <- sf::st_bbox(ifn$placettes)
  expect_gte(b[["xmin"]], 1007000); expect_lte(b[["xmax"]], 1022000)
  expect_gte(b[["ymin"]], 6790000); expect_lte(b[["ymax"]], 6805000)
})

test_that("load_ifn applique la précision passée et refuse les entrées invalides", {
  expect_true(all(load_ifn(dir_ifn(), precision_m = 600)$placettes$loc_precision_m == 600))
  sans <- load_ifn(dir_ifn(), files = c("PLACETTE", "ECOLOGIE"))
  expect_null(sans$flore)
  expect_error(load_ifn(file.path(tempdir(), "absent")), "introuvable")
  expect_error(load_ifn(dir_ifn(), files = "ECOLOGIE"), "PLACETTE")
  expect_error(load_ifn(dir_ifn(), files = c("PLACETTE", "BOIS_MORT")), "non pr")
  vide <- file.path(tempdir(), "synth_vide_ifn")
  dir.create(vide, showWarnings = FALSE)
  expect_error(load_ifn(vide, files = "PLACETTE"), "introuvable")
})

test_that("load_ifn lit aussi les noms et le BOM de l'archive DataIFN", {
  d <- file.path(tempdir(), "synth_archive_ifn")
  dir.create(d, showWarnings = FALSE)
  for (n in c("placette", "ecologie")) {
    x <- readBin(file.path(dir_ifn(), paste0("ifn_", n, ".csv")), "raw", 1e7)
    writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), x), file.path(d, paste0(toupper(n), ".csv")))
  }
  ifn <- load_ifn(d, files = c("PLACETTE", "ECOLOGIE"))
  expect_equal(nrow(ifn$placettes), 100)
  expect_true("CAMPAGNE" %in% names(ifn$placettes))
})

# --- filter_releves ----------------------------------------------------------
test_that("filter_releves : saison, perturbation, incohérence et seuil min_occ (jeu synthétique)", {
  f <- filter_releves(make_synth_ifn())
  expect_equal(f$placettes$en_saison, c(TRUE, FALSE, TRUE, TRUE, TRUE))
  expect_equal(f$placettes$perturbe, c(FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_equal(f$placettes$retenu, c(TRUE, FALSE, FALSE, TRUE, TRUE))
  # espèce 10 : 3 relevés retenus ; 20 : 2 seulement ; 30 : hors saison ; 40 : incohérente
  expect_equal(sort(unique(f$flore$CD_REF)), 10)
  expect_equal(nrow(f$flore), 3)
  expect_equal(nrow(f$placettes), 5)  # les placettes ne sont pas supprimées
  expect_equal(attr(f, "filtre")$n_retenues, 3)
})

test_that("filter_releves : paramètres min_occ, months et exclude_incidents", {
  ifn <- make_synth_ifn()
  expect_equal(sort(unique(filter_releves(ifn, min_occ = 2)$flore$CD_REF)), c(10, 20))
  expect_equal(sort(unique(filter_releves(ifn, exclude_incidents = FALSE)$flore$CD_REF)),
               c(10, 20))
  tout <- filter_releves(ifn, months = 1:12, min_occ = 1)
  expect_true(all(tout$placettes$en_saison))
  expect_true(30 %in% tout$flore$CD_REF)
  expect_false(40 %in% tout$flore$CD_REF)
  expect_error(filter_releves(ifn, months = 13), "mois")
  expect_error(filter_releves(ifn, min_occ = 0), "min_occ")
  expect_error(filter_releves(list()), "load_ifn")
})

test_that("filter_releves sur les extraits réels : relevés en saison, non perturbés, espèces >= 3", {
  f <- filter_releves(load_ifn(dir_ifn()))
  ret <- f$placettes[f$placettes$retenu, ]
  expect_gt(nrow(ret), 10)
  expect_true(all(ret$mois_releve %in% 4:9))
  expect_false(any(ret$perturbe))
  expect_true(all(f$flore$id_placette %in% ret$id_placette))
  n <- tapply(f$flore$id_placette, f$flore$CD_REF, function(i) length(unique(i)))
  expect_true(all(n >= 3))
  expect_true(all(is.na(f$flore$INCO_FLOR)))
})

# --- compute_gradients -------------------------------------------------------
test_that("gradient trophique = moyenne des valeurs indicatrices (jeu synthétique, calcul à la main)", {
  g <- compute_gradients(make_synth_ifn(), make_synth_indic())
  # placette 1 : espèces 10, 20, 40 -> pH (4+6+5)/3 = 5 ; azote (2+4+5)/3 = 11/3
  expect_equal(g$grad_ph[1], 5)
  expect_equal(g$grad_azote[1], 11 / 3)
  expect_equal(g$grad_trophique[1], (5 + 11 / 3) / 2)
  # placette 2 : espèces 20 et 30 -> pH 7, azote 5
  expect_equal(g$grad_trophique[2], 6)
  expect_equal(g$n_taxa_indic[2], 2L)
  # placette 5 : espèce 10 seule
  expect_equal(g$grad_trophique[5], 3)
  expect_equal(attr(g, "methode_trophique"), "indicateurs")
})

test_that("une placette sans flore retenue a un gradient trophique NA, pas 0", {
  g <- compute_gradients(filter_releves(make_synth_ifn()), make_synth_indic())
  expect_true(is.na(g$grad_trophique[2]))
  expect_equal(g$n_taxa_indic[2], 0L)
  expect_equal(g$grad_trophique[1], 3)  # seule l'espèce 10 reste
})

test_that("réserve utile et engorgement : calcul à la main (jeu synthétique)", {
  g <- compute_gradients(make_synth_ifn(), make_synth_indic())
  # P1 : (20 cm x 1,7 + 40 cm x 1,0) x (1 - 0,2) = 59,2 ; P2 : 50 x 1,4 ("X" = 0 caillou) = 70
  # P3 : 70 ; P4 : 40 x 0,7 x 0 (10/10 de cailloux) = 0 ; P5 : pas de fosse -> NA
  expect_equal(g$ru_mm, c(59.2, 70, 70, 0, NA))
  # P1 : gley 30 cm, pseudogley 50 cm -> 30 ; P2 : tout "X" -> aucun ; P4 : oxydation 50 cm
  expect_equal(g$engorg_prof_cm, c(30, NA, NA, 50, NA))
  expect_equal(g$engorgement, c(TRUE, FALSE, FALSE, TRUE, NA))
})

test_that("ru_table personnalisée prise en compte et validée", {
  tab <- ru_coefficients()
  tab[] <- 1
  g <- compute_gradients(make_synth_ifn(), make_synth_indic(), ru_table = tab)
  expect_equal(g$ru_mm[2], 50)
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), ru_table = 1), "nomm")
  expect_false(isTRUE(attr(ru_coefficients(), "verifie")))  # valeurs à vérifier
})

test_that("compute_gradients : sf Lambert-93 marqué IFN, sans variable fine", {
  g <- compute_gradients(make_synth_ifn(), make_synth_indic())
  expect_s3_class(g, "sf")
  expect_equal(sf::st_crs(g)$epsg, 2154)
  expect_true(all(g$source == "ifn"))
  expect_false(any(vapply(names(g), .is_fine, logical(1))))
  expect_error(compute_gradients(make_synth_ifn(), data.frame(a = 1)), "cd_ref")
  expect_error(compute_gradients(make_synth_ifn(),
                                 data.frame(cd_ref = 10, ph = "5")), "num")
  expect_error(compute_gradients(list(), make_synth_indic()), "load_ifn")
})

test_that("taxons sans valeur indicatrice listés, jamais supprimés en silence", {
  ind <- make_synth_indic()[-2, ]   # retire l'espèce 20
  g <- compute_gradients(make_synth_ifn(), ind)
  nm <- attr(g, "taxa_non_apparies")
  expect_equal(nm$cd_ref, 20)
  expect_equal(nm$n_releves, 4L)
  expect_equal(nrow(unmatched_taxa(make_synth_ifn(), make_synth_indic())), 0)
  expect_error(unmatched_taxa(data.frame(a = 1), ind), "CD_REF")
})

test_that("repli AFC (ade4) sans valeurs indicatrices", {
  skip_if_not_installed("ade4")
  f <- filter_releves(load_ifn(dir_ifn()))
  g <- compute_gradients(f)
  expect_equal(attr(g, "methode_trophique"), "afc")
  av <- g$n_taxa_indic > 0
  expect_true(all(is.finite(g$grad_trophique[av])))
  expect_true(all(is.na(g$grad_trophique[!av])))
  expect_error(compute_gradients(filter_releves(make_synth_ifn())), "AFC impossible")
})

test_that("compute_gradients sur les extraits réels et indicateurs synthétiques", {
  f <- filter_releves(load_ifn(dir_ifn()))
  ind <- utils::read.delim(file.path(dir_ifn(), "synth_indicateurs.csv"), sep = ";")
  expect_true(all(ind$synthetic))
  g <- compute_gradients(f, ind)
  expect_equal(nrow(g), 100)
  ret <- f$placettes$retenu
  expect_true(all(!is.na(g$grad_trophique[ret])))
  expect_true(all(g$grad_trophique[!is.na(g$grad_trophique)] >= 1 &
                    g$grad_trophique[!is.na(g$grad_trophique)] <= 9))
  expect_true(all(g$ru_mm[!is.na(g$ru_mm)] >= 0))
  expect_lt(max(g$ru_mm, na.rm = TRUE), 300)
  expect_equal(nrow(attr(g, "taxa_non_apparies")), 0)
})

# --- bioclimat : extraction à maille large et règle bloquante ------------------
test_that("climat kilométrique extrait aux placettes (valeur connue)", {
  g <- compute_gradients(make_synth_ifn(), make_synth_indic(), climat = make_synth_climat())
  # P1 (1 010 500 ; 6 795 500) : centre de cellule -> p_sv = 600 + 10,5 ; etp 450 ; t 8
  expect_equal(g$coarse_p_etp_sv[1], 610.5 - 450)
  expect_equal(g$coarse_p_etp_sv[2], 611.5 - 450)
  expect_equal(g$coarse_t_moy, rep(8, 5))
  expect_true(all(vapply(c("coarse_p_etp_sv", "coarse_t_moy"), .is_coarse, logical(1))))
})

test_that("règle bloquante : climat de maille fine ou couche fine refusés", {
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(),
                                 climat = make_synth_climat(res = 25)), "maille >=")
  c2 <- make_synth_climat()
  names(c2)[1] <- "pente"
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), climat = c2),
               "interdite")
  c3 <- make_synth_climat()[[1:2]]
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), climat = c3), "couches")
  c4 <- make_synth_climat()
  terra::crs(c4) <- "EPSG:4326"
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), climat = c4))
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(), climat = 3),
               "SpatRaster")
})

test_that("climat : maille < 1000 m refusée quel que soit le nom, 1000 m acceptée", {
  ifn <- make_synth_ifn(); ind <- make_synth_indic()
  # noms neutres (p_sv, etp_sv, t_moy) : refusé quand même
  expect_error(compute_gradients(ifn, ind, climat = make_synth_climat(res = 100)), "1000 m")
  expect_error(compute_gradients(ifn, ind, climat = make_synth_climat(res = 500)), "1000 m")
  expect_no_error(compute_gradients(ifn, ind, climat = make_synth_climat(res = 1000)))
  expect_no_error(compute_gradients(ifn, ind, climat = make_synth_climat(res = 500),
                                    min_res_ifn_m = 500))
})

test_that("réserve utile : OBSPEDO R -> 0, texture H -> NA ; ru_verifie = FALSE", {
  ifn <- make_synth_ifn()
  ifn$placettes$OBSPEDO[1] <- "R"
  ifn$placettes$TEXT1[1] <- "0"
  ifn$placettes$TEXT2[2] <- "H"
  g <- compute_gradients(ifn, make_synth_indic())
  expect_equal(g$ru_mm[1], 0)
  expect_true(is.na(g$ru_mm[2]))
  expect_equal(g$ru_mm[3], 70)
  expect_false(attr(g, "ru_verifie"))
})
