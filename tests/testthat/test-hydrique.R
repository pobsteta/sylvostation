# Mission 019 : dictionnaire IFN des textures, granulometrie, reserve utile euptf2,
# indice BILJOU sur SAFRAN. Sans reseau : extraits reels de inst/extdata
# (ifn_texture_dictionnaire.csv, safran_sim2_extrait.csv, Licence Ouverte 2.0) et
# jeu IFN synthetique (make_synth_ifn(), synthetic = TRUE).

safran_extrait <- function() {
  utils::read.csv2(system.file("extdata", "safran_sim2_extrait.csv", package = "sylvostation"),
                   dec = ".")
}

# Centre de la maille SAFRAN (LAMBX, LAMBY en hm, Lambert II etendu) en Lambert-93.
centre_maille_l93 <- function(lambx, lamby) {
  p <- sf::st_as_sf(data.frame(x = lambx * 100, y = lamby * 100), coords = c("x", "y"),
                    crs = 27572)
  unname(sf::st_coordinates(sf::st_transform(p, 2154))[1, ])   # x = est, y = nord
}

points_l93 <- function(x, y, ru) {
  sf::st_as_sf(data.frame(id = seq_along(ru), ru_mm = ru, x = x, y = y),
               coords = c("x", "y"), crs = 2154)
}

soiltexture_classes_aisne <- function() {
  skip_if_not_installed("soiltexture")
  names(soiltexture::TT.get("FR.AISNE.TT")$tt.polygons)
}

# ---- read_texture_dictionary ------------------------------------------------

test_that("read_texture_dictionary : codes de metadonnees.csv, partition du triangle de l'Aisne", {
  d <- read_texture_dictionary()
  expect_equal(d$code, c(as.character(0:9), "H"))
  expect_equal(d$classes[d$code == "4"], "LS,LSA,LMS,LLS")
  expect_equal(d$classes[d$code == "5"], "LA,LAS")
  expect_equal(d$classes[d$code == "6"], "LM,LL")
  expect_equal(d$classes[d$code == "9"], "A,ALO")
  # chaque classe de l'Aisne une seule fois : partition
  cl <- unlist(strsplit(d$classes_aisne[nzchar(d$classes_aisne)], ","))
  expect_false(anyDuplicated(cl) > 0)
  expect_setequal(cl, soiltexture_classes_aisne())
  # une abreviation hors du triangle de l'Aisne : Als (code 8)
  expect_equal(d$hors_triangle[d$code == "8"], "ALS")
  expect_true(all(!nzchar(d$hors_triangle[d$code != "8"])))
  expect_equal(d$classes[d$code %in% c("0", "H")], c("", ""))
  # 2005-2016 (TEXT) : memes classes pour 0 a 9, pas de H
  d0 <- read_texture_dictionary(unite = "TEXT")
  expect_equal(d0$code, as.character(0:9))
  expect_equal(d0$classes, d$classes[d$code %in% as.character(0:9)])
  expect_match(attr(d, "source"), "Licence Ouverte 2.0")
  expect_error(read_texture_dictionary(tempfile()), "introuvable")
})

# ---- texture_to_psd ---------------------------------------------------------

test_that("texture_to_psd : centre de gravite des classes, dans la bonne classe", {
  skip_if_not_installed("soiltexture")
  p <- texture_to_psd(c("1", "4", "6", "9", "0", "H", NA, "Z"))
  expect_equal(nrow(p), 8)
  ok <- !is.na(p$argile)
  expect_equal(ok, c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_equal(p$argile[ok] + p$limon[ok] + p$sable[ok], rep(100, 4))
  # S : triangle (argile, limon) de sommets (0,0), (0,15), (10,0)... centre calcule a la main
  tt <- soiltexture::TT.get("FR.AISNE.TT")
  s <- tt$tt.points[tt$tt.polygons$S$points, ]
  ref <- .aire_centre(s$CLAY, s$SILT)
  expect_equal(p$argile[1], 100 * unname(ref["cx"]))
  expect_equal(p$limon[1], 100 * unname(ref["cy"]))
  expect_equal(round(p$sable[1], 2), 87.78)
  # code a classe unique : le centre tombe dans sa classe (soiltexture)
  cl <- soiltexture::TT.points.in.classes(
    data.frame(CLAY = p$argile[1], SILT = p$limon[1], SAND = p$sable[1]),
    class.sys = "FR.AISNE.TT", PiC.type = "t")
  expect_equal(as.character(cl), "S")
  # code 9 (A, ALO) : moyenne des centres ponderee par l'aire, calculee a la main
  a <- tt$tt.points[tt$tt.polygons$A$points, ]
  alo <- tt$tt.points[tt$tt.polygons$ALO$points, ]
  ca <- .aire_centre(a$CLAY, a$SILT)
  cal <- .aire_centre(alo$CLAY, alo$SILT)
  attendu <- 100 * (ca["aire"] * ca["cx"] + cal["aire"] * cal["cx"]) / (ca["aire"] + cal["aire"])
  expect_equal(p$argile[4], unname(attendu))
  expect_equal(p$classes[4], "A,ALO")
  # code 6 (LM, LL) : le centre de la reunion est dans LM ou LL
  cl6 <- soiltexture::TT.points.in.classes(
    data.frame(CLAY = p$argile[3], SILT = p$limon[3], SAND = p$sable[3]),
    class.sys = "FR.AISNE.TT", PiC.type = "t")
  expect_true(any(strsplit(as.character(cl6), ", ")[[1]] %in% c("LM", "LL")))
  # aires : la somme des codes 1 a 9 couvre tout le triangle
  expect_equal(sum(texture_to_psd(as.character(1:9))$aire), 1)
  # code 8 : Als hors triangle, signale
  expect_equal(texture_to_psd("8")$hors_triangle, "ALS")
})

# ---- ru_from_texture --------------------------------------------------------

# AWC_2 = FC_2 - WP, fonctions ponctuelles d'euptf2 (README d'euptf2), calcul independant
awc_euptf <- function(code, z) {
  p <- texture_to_psd(code)
  df <- data.frame(USSAND = p$sable, USSILT = p$limon, USCLAY = p$argile, DEPTH_M = z)
  e <- new.env()
  utils::data(list = c("FC_2_PTF01", "WP_PTF01"), package = "euptf2", envir = e)
  suppressWarnings(euptf2::ptfFun.pred(e$FC_2_PTF01, df) - euptf2::ptfFun.pred(e$WP_PTF01, df))
}

test_that("ru_from_texture : euptf2 par couche, cailloux au centre de classe, Bruand en regard", {
  skip_if_not_installed("soiltexture")
  skip_if_not_installed("euptf2")
  skip_if_not_installed("ranger")
  ifn <- make_synth_ifn()   # synthetique
  ru <- ru_from_texture(ifn$placettes)
  expect_equal(ru$id_placette, ifn$placettes$id_placette)
  expect_true(attr(ru, "ru_verifie"))
  expect_equal(attr(ru, "cible"), "AWC_2")
  # P1 : 20 cm de limon (6, milieu 10 cm) sur 40 cm de sable limoneux (2, milieu 40 cm),
  # CAILLOUX 2 -> 20 %
  attendu <- (20 * awc_euptf("6", 10) + 40 * awc_euptf("2", 40)) * 10 * 0.8
  expect_equal(ru$ru_mm[1], attendu)
  expect_equal(ru$ru_bruand_mm[1], (20 * 2.13 + 40 * 1.16) * 0.8)
  expect_equal(ru$ecart_mm[1], ru$ru_mm[1] - ru$ru_bruand_mm[1])
  # P2 : 50 cm de limon sableux (4, milieu 25 cm), CAILLOUX X (absence)
  expect_equal(ru$ru_mm[2], 50 * awc_euptf("4", 25) * 10)
  expect_equal(ru$cailloux[2], 0)
  # P3 : CAILLOUX 0 = moins de 5 % -> 2,5 %
  expect_equal(ru$cailloux[3], 0.025)
  # P4 : CAILLOUX 10 = plus de 95 % -> 97,5 %
  expect_equal(ru$ru_mm[4], 40 * awc_euptf("1", 20) * 10 * 0.025)
  # P5 : sans fosse (OBSPEDO 5) -> NA
  expect_true(is.na(ru$ru_mm[5]) && is.na(ru$ru_bruand_mm[5]))
  # ordre physique : le sable retient moins que le limon
  expect_lt(awc_euptf("1", 20), awc_euptf("6", 20))
  expect_true(all(!ru$texture_partielle))
})

test_that("ru_from_texture : cas particuliers H, R, 0, code 8, erreurs", {
  skip_if_not_installed("soiltexture")
  skip_if_not_installed("euptf2")
  skip_if_not_installed("ranger")
  pl <- data.frame(PROF1 = c(NA, NA, NA, NA, "3"), PROF2 = c("5", "5", "5", "5", "6"),
                   TEXT1 = c(NA, "H", NA, NA, "0"), TEXT2 = c("8", "4", "0", "4", "6"),
                   CAILLOUX = "X", OBSPEDO = c(NA, NA, NA, "R", NA),
                   synthetic = TRUE, stringsAsFactors = FALSE)
  ru <- ru_from_texture(pl)
  expect_false("id_placette" %in% names(ru))
  expect_true(ru$texture_partielle[1])            # As, Als : Als hors triangle
  expect_gt(ru$ru_mm[1], 0)
  expect_true(is.na(ru$ru_mm[2]))                 # horizon organique : non modelise
  expect_equal(ru$ru_mm[3], 0)                    # absence de terre fine
  expect_equal(ru$ru_mm[4], 0)                    # horizon entierement caillouteux
  # TEXT1 = 0 avec PROF1 : horizon superieur sans terre fine, compte 0
  expect_equal(ru$ru_mm[5], 30 * awc_euptf("6", 45) * 10)
  expect_equal(ru_from_texture(pl, cible = "AWC")$ru_mm[3], 0)
  expect_error(ru_from_texture(pl, ptf = "1"), "PTF01")
  expect_error(ru_from_texture(1), "tableau")
})

test_that("ru_from_texture : ru_source euptf2 (defaut) ou bruand2004", {
  skip_if_not_installed("soiltexture")
  skip_if_not_installed("euptf2")
  skip_if_not_installed("ranger")
  ifn <- make_synth_ifn()   # synthetique
  e <- ru_from_texture(ifn$placettes)
  b <- ru_from_texture(ifn$placettes, ru_source = "bruand2004")
  expect_equal(attr(e, "ru_source"), "euptf2")
  expect_equal(attr(b, "ru_source"), "bruand2004")
  expect_equal(e$ru_mm, e$ru_euptf2_mm)
  expect_equal(b$ru_mm, b$ru_bruand_mm)
  expect_equal(b$ru_euptf2_mm, e$ru_euptf2_mm)    # les deux colonnes restent rendues
  expect_equal(e$ecart_mm, e$ru_euptf2_mm - e$ru_bruand_mm)
  expect_match(attr(e, "source"), "FC_2 - WP")
  expect_error(ru_from_texture(ifn$placettes, ru_source = "autre"))
})

test_that("ru_from_texture : sans euptf2, Bruand seul possible, euptf2 refuse", {
  local_mocked_bindings(.has_pkg = function(pkg) FALSE)
  ifn <- make_synth_ifn()   # synthetique
  expect_error(ru_from_texture(ifn$placettes), "euptf2")
  b <- ru_from_texture(ifn$placettes, ru_source = "bruand2004")
  expect_true(all(is.na(b$ru_euptf2_mm)))
  expect_equal(b$ru_mm[1], (20 * 2.13 + 40 * 1.16) * 0.8)
})

test_that("ru_coefficients : chaque code 1 a 9 a une valeur par type d'horizon (sans repli)", {
  ru <- ru_coefficients()
  expect_false(anyNA(ru$haut[as.character(1:9)]))
  expect_false(anyNA(ru$bas[as.character(1:9)]))
})

# ---- hydric_stress ----------------------------------------------------------

test_that("hydric_stress : un point connu tombe dans la bonne maille SAFRAN (Lambert-93)", {
  skip_if_not_installed("biljouR")
  s <- safran_extrait()
  m <- .mailles_safran(s)
  expect_equal(m$maille, "9640_23690")
  c0 <- centre_maille_l93(9640, 23690)
  # centre de la maille, x = est, y = nord : environ (1 014 550 ; 6 799 283)
  expect_lt(max(abs(c0 - c(1014550, 6799283))), 2)
  expect_equal(.maille_proche(c0[1] + 3000, c0[2] - 3000, m), "9640_23690")
  expect_true(is.na(.maille_proche(c0[1] + 9000, c0[2], m)))   # hors de la grille fournie
})

test_that("hydric_stress : Is et jours de stress BILJOU par placette, decroissants avec la RU", {
  skip_if_not_installed("biljouR")
  s <- safran_extrait()
  c0 <- centre_maille_l93(9640, 23690)
  p <- mark_ifn(points_l93(c0[1] + c(0, 500, 1000, 9000), c0[2], c(60, 150, 0, 60)))
  h <- hydric_stress(p, s)          # placettes IFN : SAFRAN 8 km est une maille large
  expect_equal(attr(h, "methode"), "biljou")
  expect_equal(h$maille_safran, c("9640_23690", "9640_23690", "9640_23690", NA))
  expect_equal(h$n_annees[1:2], c(2, 2))
  expect_gt(h$is_biljou[1], h$is_biljou[2])
  expect_gte(h$nj_stress[1], h$nj_stress[2])
  expect_true(is.na(h$is_biljou[3]))              # RU nulle : BILJOU ne tourne pas
  expect_true(is.na(h$is_biljou[4]))              # hors grille
  expect_equal(h$grad_hydrique, -h$is_biljou)    # plus haut = plus humide
  expect_equal(attr(h, "sens"), "plus haut = plus humide")
  # meme chiffre qu'un appel direct a biljouR
  met <- biljouR::safran_to_meteo(s, cols = list(date = "DATE", rain_liq = "PRELIQ",
                                                 rain_sol = "PRENEI", pet = "ETP"))
  run <- biljouR::biljou_run(met, biljouR::biljou_soil(60), lai_max = 6,
                             forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
  idx <- biljouR::biljou_indices(run)
  expect_equal(h$is_biljou[1], mean(idx$Istress))
  expect_equal(h$nj_stress[1], mean(idx$NJstress))
  # annees : 2003 seule
  h3 <- hydric_stress(p[1, ], s, annees = 2003)
  expect_equal(h3$n_annees, 1)
  expect_error(hydric_stress(p[1, ], s, annees = 1900), "Aucune")
})

test_that("hydric_stress : repli sur la RU, signale, si SAFRAN absent", {
  c0 <- centre_maille_l93(9640, 23690)
  p <- points_l93(c0[1], c0[2], 80)
  expect_warning(h <- hydric_stress(p, NULL), "repli")
  expect_equal(attr(h, "methode"), "repli_ru")
  expect_equal(attr(h, "repli"), "climat SAFRAN absent")
  expect_equal(h$grad_hydrique, 80)
  expect_true(is.na(h$is_biljou))
  expect_equal(attr(h, "sens"), "plus haut = plus humide")
})

test_that("hydric_stress : repli sur la RU, signale, si biljouR absent", {
  local_mocked_bindings(.has_pkg = function(pkg) pkg != "biljouR")
  c0 <- centre_maille_l93(9640, 23690)
  p <- points_l93(c0[1], c0[2], c(80, 30))
  expect_warning(h <- hydric_stress(p, safran_extrait()), "biljouR absent")
  expect_equal(attr(h, "methode"), "repli_ru")
  expect_equal(attr(h, "repli"), "paquet biljouR absent")
  expect_equal(h$grad_hydrique, c(80, 30))
  expect_true(all(is.na(h$is_biljou)))
})

test_that("hydric_stress : grad_hydrique va dans le meme sens en mode nominal et en repli", {
  skip_if_not_installed("biljouR")
  c0 <- centre_maille_l93(9640, 23690)
  p <- points_l93(c0[1] + c(0, 200, 400), c0[2], c(40, 90, 160))   # RU croissante
  nominal <- hydric_stress(p, safran_extrait())
  expect_warning(repli <- hydric_stress(p, NULL), "repli")
  expect_equal(attr(nominal, "sens"), attr(repli, "sens"))
  # plus de reserve utile = plus humide, dans les deux modes
  expect_true(all(diff(nominal$grad_hydrique) > 0))
  expect_true(all(diff(repli$grad_hydrique) > 0))
  expect_equal(rank(nominal$grad_hydrique), rank(repli$grad_hydrique))
})

test_that("hydric_stress : controles (Lambert-93, colonnes, regle 700 m)", {
  c0 <- centre_maille_l93(9640, 23690)
  p <- points_l93(c0[1], c0[2], 80)
  expect_error(hydric_stress(sf::st_transform(p, 4326), NULL), "2154")
  expect_error(hydric_stress(p, NULL, ru_col = "ru"), "absente")
  expect_error(hydric_stress(data.frame(ru_mm = 1)), "sf")
  skip_if_not_installed("biljouR")
  expect_error(hydric_stress(p, data.frame(LAMBX = 1)), "colonnes")
  # la regle bloquante reste active : une variable fine sur ces placettes echoue
  expect_error(assert_no_fine_extract_on_ifn(mark_ifn(p), "twi"), "IFN")
})

test_that("hydric_stress : grille de RU, interpolation par maille SAFRAN", {
  skip_if_not_installed("biljouR")
  s <- safran_extrait()
  c0 <- centre_maille_l93(9640, 23690)
  r <- terra::rast(xmin = c0[1] - 50, xmax = c0[1] + 50, ymin = c0[2] - 50, ymax = c0[2] + 50,
                   resolution = 50, crs = "EPSG:2154")
  terra::values(r) <- c(60, 150, 0, 65)
  g <- hydric_stress(r, s)
  expect_s4_class(g, "SpatRaster")
  expect_equal(names(g), c("is_biljou", "nj_stress", "grad_hydrique"))
  expect_equal(attr(g, "sens"), "plus haut = plus humide")
  v <- terra::values(g)
  p <- points_l93(c0[1], c0[2], c(60, 150, 70))
  h <- hydric_stress(p, s)
  expect_equal(v[1:2, "is_biljou"], h$is_biljou[1:2])      # RU multiples du pas : exact
  expect_true(is.na(v[3, "is_biljou"]))
  expect_true(v[4, "is_biljou"] <= h$is_biljou[1] && v[4, "is_biljou"] >= h$is_biljou[3])
  expect_equal(v[, "grad_hydrique"], -v[, "is_biljou"])
  expect_warning(g0 <- hydric_stress(r, NULL), "repli")
  v0 <- terra::values(g0)
  expect_true(all(is.na(v0[, c("is_biljou", "nj_stress")])))
  expect_equal(v0[, "grad_hydrique"], c(60, 150, 0, 65))   # repli : la RU
})
