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

# ---- carte hydrique de 25 m (mission 021) ------------------------------------------
# Extrait SAFRAN reel de 12 mailles (2003-2004) avec T, FF, HU, SSI (Licence Ouverte 2.0).

safran12 <- function() {
  read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv", package = "sylvostation"))
}

# Grille de facteurs k (12 couches) de 2 x 2 cellules de 50 m centree en (x0, y0),
# Lambert-93 ; une ligne de `prof` par cellule (ordre de terra : nord-ouest d'abord).
grille_k <- function(x0, y0, prof) {
  k <- terra::rast(xmin = x0 - 50, xmax = x0 + 50, ymin = y0 - 50, ymax = y0 + 50,
                   resolution = 50, crs = "EPSG:2154", nlyrs = 12)
  if (ncol(prof) == 1L) prof <- matrix(prof, nrow(prof), 12)
  terra::values(k) <- prof
  names(k) <- sprintf("k_%02d", 1:12)
  k
}

# profils mensuels : versant sud (k > 1 en hiver), plat, versant nord (k < 1)
K_SUD <- c(2.2, 1.8, 1.4, 1.15, 1.05, 1, 1, 1.05, 1.2, 1.5, 2, 2.3)
K_NORD <- c(0.25, 0.4, 0.6, 0.8, 0.85, 0.85, 0.85, 0.8, 0.7, 0.5, 0.3, 0.25)

test_that(".ssi_mj, .ra_mj, .check_ssi : unite J/cm2 et plausibilite", {
  expect_equal(sylvostation:::.ssi_mj(136.3), 1.363)
  # rayonnement extraterrestre a 48 degres N : environ 41,6 MJ/m2 au solstice d'ete
  # (FAO-56, tableau 2.6 : 41,7 a 48 degres N en juin), environ 10 a la mi-janvier
  ra <- sylvostation:::.ra_mj(c(172, 17), 48)
  expect_equal(ra[1], 41.6, tolerance = 0.01)
  expect_true(ra[2] > 8 && ra[2] < 12)
  expect_warning(sylvostation:::.check_ssi(50, 172, 48), "extraterrestre")
  expect_silent(sylvostation:::.check_ssi(30, 172, 48))
  # l'extrait reel ne depasse jamais le rayonnement extraterrestre
  s <- safran12()
  doy <- as.integer(format(as.Date(as.character(s$DATE), "%Y%m%d"), "%j"))
  expect_silent(sylvostation:::.check_ssi(sylvostation:::.ssi_mj(s$SSI), doy, 48.1))
})

test_that("ru_by_safran_cell : mediane par maille, sinon emprise, sinon GRECO ; jamais fin", {
  s <- safran12()
  a <- centre_maille_l93(9640, 23690)
  b <- centre_maille_l93(9560, 23530)
  p <- mark_ifn(points_l93(c(a[1], a[1] + 1000, a[1] - 2000, b[1]), c(a[2], a[2], a[2], b[2]),
                           c(60, 100, 200, 40)))
  r <- ru_by_safran_cell(p, s)
  expect_equal(nrow(r), 12)
  expect_equal(r$ru_mm[r$maille == "9640_23690"], 100)       # mediane de 60, 100, 200
  expect_equal(r$n_placettes[r$maille == "9640_23690"], 3)
  expect_equal(r$ru_mm[r$maille == "9560_23530"], 40)
  vide <- r[r$n_placettes == 0, ]
  expect_true(all(vide$ru_mm == 80))                          # mediane des 4 placettes
  expect_true(all(vide$origine == "médiane des mailles de l'emprise"))
  expect_true(all(grepl("provisoire", r$statut)))
  # emprise autour de la seule maille 9720_23770, sans placette : mediane de la GRECO
  e <- centre_maille_l93(9720, 23770)
  r2 <- ru_by_safran_cell(p, s, emprise = c(e[1] - 100, e[2] - 100, e[1] + 100, e[2] + 100))
  expect_identical(r2$maille, "9720_23770")
  expect_equal(r2$ru_mm, 80)
  expect_identical(r2$origine, "médiane de toutes les placettes (GRECO)")
  expect_error(ru_by_safran_cell(sf::st_transform(p, 4326), s), "2154")
  expect_error(ru_by_safran_cell(p, s, ru_col = "ru"), "absente")
  expect_error(ru_by_safran_cell(points_l93(a[1], a[2], 0), s), "positive")
})

test_that("hydric_stress_grid : k = 1 donne le plat ; versant sud > plat > versant nord", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  c0 <- centre_maille_l93(9640, 23690)
  k <- grille_k(c0[1], c0[2], rbind(K_SUD, 1, 1, K_NORD))
  ru <- data.frame(maille = "9640_23690", ru_mm = 100)
  h <- hydric_stress_grid(k, ru, s, n_controle = 4)
  expect_s4_class(h, "SpatRaster")
  expect_identical(names(h), c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille",
                               "grad_hydrique_carte"))
  expect_identical(attr(h, "methode"), "biljou_topo")
  expect_equal(attr(h, "sens"), "plus haut = plus humide")
  v <- terra::values(h)
  expect_equal(v[2:3, "is_topo"], v[2:3, "is_plat"])         # k = 1 : le plat
  expect_equal(v[2:3, "k_sv"], c(1, 1))
  expect_true(v[1, "k_sv"] > 1 && v[4, "k_sv"] < 1)
  expect_gt(v[1, "is_topo"], v[2, "is_topo"])                 # sud plus contraint
  expect_lt(v[4, "is_topo"], v[2, "is_topo"])                 # nord moins contraint
  expect_equal(v[, "grad_hydrique_carte"], -v[, "is_topo"])
  expect_true(all(v[, "ru_maille"] == 100))                   # RU uniforme de la maille
  # le plat = BILJOU sur l'ETP de Penman de biljouR (SSI x 0,01), meme formule
  sm <- s[s$LAMBX == 9640 & s$LAMBY == 23690, ]
  lat <- sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c0), crs = 2154), 4326))[2]
  met <- biljouR::safran_to_meteo(
    data.frame(DATE = sm$DATE, PRELIQ = sm$PRELIQ, PRENEI = sm$PRENEI, T = sm$T, FF = sm$FF,
               HU = sm$HU, RG = sm$SSI * 0.01),
    cols = list(date = "DATE", rain_liq = "PRELIQ", rain_sol = "PRENEI", tmean = "T",
                rg = "RG", wind = "FF", rh = "HU"), compute_pet = TRUE, latitude = lat)
  run <- biljouR::biljou_run(met, biljouR::biljou_soil(100), lai_max = 6,
                             forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
  expect_equal(unname(v[2, "is_plat"]), mean(biljouR::biljou_indices(run)$Istress))
  # ecart table / calcul direct : mesure et rendu
  e <- attr(h, "ecart")
  expect_identical(names(e), c("maille", "n_controle", "is_direct_moyen", "ecart_moyen_abs",
                               "ecart_max_abs", "ecart_relatif"))
  expect_equal(e$n_controle, 4)
  expect_lt(e$ecart_max_abs, 1e-8)        # profils exacts des noeuds : ecart nul
  m <- attr(h, "mailles")
  expect_equal(m$n_cellules, 4)
  expect_equal(m$altitude, 0)             # pas d'altitude fournie
})

test_that("hydric_stress_grid : table sur des profils varies, ecart mesure faible", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  c0 <- centre_maille_l93(9640, 23690)
  # 36 cellules : melange continu entre versant nord et versant sud
  r <- terra::rast(xmin = c0[1] - 150, xmax = c0[1] + 150, ymin = c0[2] - 150,
                   ymax = c0[2] + 150, resolution = 50, crs = "EPSG:2154", nlyrs = 12)
  t <- seq(0, 1, length.out = 36)
  terra::values(r) <- outer(1 - t, K_NORD) + outer(t, K_SUD)
  names(r) <- sprintf("k_%02d", 1:12)
  alt <- r[[1]] * 0 + 600
  h <- hydric_stress_grid(r, data.frame(maille = "9640_23690", ru_mm = 80), s, altitude = alt,
                          pas_k = 0.05, n_controle = 6, seed = 3)
  v <- terra::values(h)
  expect_true(all(diff(v[, "k_sv"]) > 0))
  expect_true(all(diff(v[, "is_topo"]) >= -1e-8))   # Istress croit avec k
  e <- attr(h, "ecart")
  expect_equal(e$n_controle, 6)
  expect_lt(e$ecart_relatif, 0.05)
  expect_equal(attr(h, "mailles")$altitude, 600)
  # la graine ne touche pas au generateur aleatoire de l'appelant
  set.seed(42)
  a <- stats::runif(1)
  set.seed(42)
  invisible(hydric_stress_grid(r, data.frame(maille = "9640_23690", ru_mm = 80), s,
                               pas_k = 0.2, n_controle = 1))
  expect_equal(stats::runif(1), a)
})

test_that("hydric_stress_grid : RU en raster, table sur une suite de RU", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  c0 <- centre_maille_l93(9640, 23690)
  k <- grille_k(c0[1], c0[2], rbind(1, 1, 1, 1))
  ru <- k[[1]]
  terra::values(ru) <- c(60, 80, 65, 0)
  h <- hydric_stress_grid(k, ru, s, n_controle = 0)
  v <- terra::values(h)
  p <- hydric_stress_grid(k, data.frame(maille = "9640_23690", ru_mm = 60), s, n_controle = 0)
  expect_equal(v[1, "is_topo"], terra::values(p)[1, "is_topo"])   # noeud exact (pas de 10)
  expect_true(v[3, "is_topo"] <= v[1, "is_topo"] && v[3, "is_topo"] >= v[2, "is_topo"])
  expect_true(is.na(v[4, "is_topo"]))                              # RU nulle
  expect_equal(nrow(attr(h, "ecart")), 0)
})

test_that("hydric_stress_grid : points precis en calcul direct ; placettes IFN refusees", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  c0 <- centre_maille_l93(9640, 23690)
  k <- grille_k(c0[1], c0[2], rbind(K_SUD, 1, 1, K_NORD))
  ru <- data.frame(maille = "9640_23690", ru_mm = 100)
  # point connu (x = est, y = nord) dans la cellule nord-ouest (versant sud)
  xy <- c(c0[1] - 25, c0[2] + 25)
  expect_equal(terra::cellFromXY(k, rbind(xy)), 1)
  ifn <- mark_ifn(points_l93(xy[1], xy[2], 100))
  expect_error(hydric_stress_grid(k, ru, s, points = ifn), "IFN")   # regle des 700 m
  flou <- points_l93(xy[1], xy[2], 100)                             # precision absente
  expect_error(hydric_stress_grid(k, ru, s, points = flou), "loc_precision_m")
  gnss <- points_l93(xy[1], xy[2], 100)
  gnss$loc_precision_m <- 5
  p <- hydric_stress_grid(k, ru, s, points = gnss)
  g <- terra::values(hydric_stress_grid(k, ru, s, n_controle = 0))
  expect_identical(p$maille_safran, "9640_23690")
  expect_equal(p$is_topo, unname(g[1, "is_topo"]))
  expect_equal(p$is_plat, unname(g[1, "is_plat"]))
  expect_equal(p$grad_hydrique_carte, -p$is_topo)
})

test_that("hydric_stress_grid : replis signales (k = 1, SAFRAN sans SSI, SAFRAN absent)", {
  skip_if_not_installed("biljouR")
  c0 <- centre_maille_l93(9640, 23690)
  k <- grille_k(c0[1], c0[2], rbind(1, 1, 1, 1))
  ru <- data.frame(maille = "9640_23690", ru_mm = c(100))
  h <- hydric_stress_grid(k, ru, safran12(), n_controle = 0, k_methode = "climatique")
  expect_identical(attr(h, "methode"), "biljou_climatique")
  expect_match(attr(h, "repli"), "GRASS")
  # SAFRAN sans T, FF, HU, SSI : BILJOU sur l'ETP SAFRAN, sans k (= hydric_stress)
  s1 <- safran_extrait()
  c1 <- centre_maille_l93(9640, 23690)
  k1 <- grille_k(c1[1], c1[2], rbind(K_SUD, 1, 1, K_NORD))
  expect_warning(h1 <- hydric_stress_grid(k1, ru, s1), "sans modulation")
  expect_identical(attr(h1, "methode"), "climatique_etp_safran")
  v1 <- terra::values(h1)
  ref <- hydric_stress(points_l93(c1[1], c1[2], 100), s1)
  expect_equal(v1[, "is_topo"], rep(ref$is_biljou, 4))
  expect_equal(v1[, "is_plat"], v1[, "is_topo"])
  # SAFRAN absent : la reserve utile
  expect_warning(h0 <- hydric_stress_grid(k, ru, NULL), "repli")
  expect_identical(attr(h0, "methode"), "repli_ru")
  expect_true(all(is.na(terra::values(h0)[, "is_topo"])))
})

test_that("hydric_stress_grid : controles des entrees", {
  c0 <- centre_maille_l93(9640, 23690)
  k <- grille_k(c0[1], c0[2], rbind(1, 1, 1, 1))
  ru <- data.frame(maille = "9640_23690", ru_mm = 100)
  expect_error(hydric_stress_grid(k[[1:3]], ru), "12 couches")
  expect_error(hydric_stress_grid(terra::project(k, "EPSG:4326"), ru), "2154")
  expect_error(hydric_stress_grid(k, data.frame(a = 1)), "maille")
  expect_error(hydric_stress_grid(k, 100), "data.frame")
  expect_error(hydric_stress_grid(k, ru, pas_k = 0), "pas_k")
})

# ---- cout de calcul (mission 028) : resultats identiques a la reference lente --------------
# `.biljou_ru()` / `.biljou_cols()` (boucle d'etat vectorisee) contre `biljouR::biljou_run()`
# (une passe par reserve utile, `.biljou_ru_ref()`). Tolerance ecrite : 1e-12 en relatif ;
# l'egalite mesuree sur l'extrait est exacte (identical).

meteo_essai <- function(s = safran_extrait()) {
  biljouR::safran_to_meteo(s, cols = list(date = "DATE", rain_liq = "PRELIQ",
                                          rain_sol = "PRENEI", pet = "ETP"))
}

test_that(".biljou_ru : memes indices que biljou_run (feuillus et resineux, RU nulle ou NA)", {
  skip_if_not_installed("biljouR")
  met <- meteo_essai()
  ru <- c(5, 20, 50.5, 100, 180, 400, NA, 0, -3)
  for (p in list(list(lai_max = 6, forest_type = "broadleaved", budburst = 110, leaf_fall = 300),
                 list(lai_max = 5, forest_type = "coniferous", budburst = NULL, leaf_fall = NULL))) {
    ref <- sylvostation:::.biljou_ru_ref(met, ru, p)
    nv <- sylvostation:::.biljou_ru(met, ru, p)
    expect_identical(dim(nv), dim(ref))
    expect_identical(colnames(nv), colnames(ref))
    expect_identical(is.na(nv), is.na(ref))
    expect_equal(nv, ref, tolerance = 1e-12)
    expect_gt(nv[1, "is"], nv[4, "is"])      # moins de RU : plus de stress
  }
  expect_identical(nrow(sylvostation:::.biljou_ru(met, numeric(0), p)), 0L)
  # decoupage en blocs (chunk) : sans effet sur le resultat
  p <- list(lai_max = 6, forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
  a <- sylvostation:::.biljou_cols(met, NULL, NULL, c(30, 60, 90, 120, 150), p, chunk = 2L)
  b <- sylvostation:::.biljou_cols(met, NULL, NULL, c(30, 60, 90, 120, 150), p)
  expect_identical(a, b)
  expect_error(sylvostation:::.biljou_cols(met, NULL, NULL, c(60, NA), p), "BILJOU")
})

test_that(".biljou_cols : une colonne par couple (profil d'ETP, RU), comme une passe par couple", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  sm <- s[s$LAMBX == 9640 & s$LAMBY == 23690, ]
  sm <- sm[order(sm$DATE), ]
  p <- list(lai_max = 6, forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
  m1 <- sylvostation:::.meteo_topo(sm, rep(1, 12), 49, 150)
  m2 <- sylvostation:::.meteo_topo(sm, K_SUD, 49, 150)
  expect_false(isTRUE(all.equal(m1$pet, m2$pet)))
  PET <- cbind(m1$pet, m2$pet)
  r <- sylvostation:::.biljou_cols(m1, PET, c(1L, 2L, 2L, 1L), c(60, 60, 120, 120), p)
  att <- rbind(sylvostation:::.biljou_ru_ref(m1, 60, p), sylvostation:::.biljou_ru_ref(m2, 60, p),
               sylvostation:::.biljou_ru_ref(m2, 120, p), sylvostation:::.biljou_ru_ref(m1, 120, p))
  expect_equal(r, att, tolerance = 1e-12)
})

test_that(".maille_proche : memes mailles que la boucle de reference, hors grille en NA", {
  s <- safran12()
  m <- sylvostation:::.mailles_safran(s)
  set.seed(3)
  x <- c(runif(200, min(m$x) - 12000, max(m$x) + 12000), m$x)   # x = est (Lambert-93)
  y <- c(runif(200, min(m$y) - 12000, max(m$y) + 12000), m$y)   # y = nord
  v <- sylvostation:::.maille_proche(x, y, m)
  expect_identical(v, sylvostation:::.maille_proche_ref(x, y, m))
  expect_true(anyNA(v[1:200]))                                   # des points hors grille
  expect_identical(tail(v, 12), m$maille)                        # un centre tombe dans sa maille
  expect_identical(sylvostation:::.maille_proche(numeric(0), numeric(0), m), character(0))
})

test_that("hydric_stress_grid : points directs = biljou_run ; nombre de coeurs sans effet", {
  skip_if_not_installed("biljouR")
  s <- safran12()
  m <- sylvostation:::.mailles_safran(s)
  a <- m[m$maille == "9560_23530", ]
  b <- m[m$maille == "9640_23530", ]
  # grille de 500 m couvrant deux mailles (x = est, y = nord), profils k varies
  k <- terra::rast(xmin = a$x - 1000, xmax = b$x + 1000, ymin = a$y - 1000, ymax = a$y + 1000,
                   resolution = 500, crs = "EPSG:2154", nlyrs = 12)
  set.seed(11)
  base <- runif(terra::ncell(k), 0.5, 1.5)
  terra::values(k) <- vapply(1:12, function(j) base * (1 + 0.1 * cos(j)), numeric(terra::ncell(k)))
  names(k) <- sprintf("k_%02d", 1:12)
  ru <- data.frame(maille = c(a$maille, b$maille), ru_mm = c(70, 130))
  h1 <- hydric_stress_grid(k, ru, s, n_controle = 3, ncores = 1)
  h2 <- hydric_stress_grid(k, ru, s, n_controle = 3, ncores = 2)
  expect_identical(terra::values(h1), terra::values(h2))
  expect_identical(attr(h1, "ecart"), attr(h2, "ecart"))
  expect_identical(attr(h1, "mailles"), attr(h2, "mailles"))
  expect_identical(sort(attr(h1, "ecart")$maille), sort(c(a$maille, b$maille)))
  # points precis : l'indice direct est celui de biljou_run (reference lente), a 1e-12 pres
  xy <- rbind(c(a$x + 300, a$y - 200), c(b$x - 900, b$y + 400))
  g <- sf::st_as_sf(data.frame(id = 1:2, x = xy[, 1], y = xy[, 2]),
                    coords = c("x", "y"), crs = 2154)
  g$loc_precision_m <- 5
  pr <- hydric_stress_grid(k, ru, s, points = g)
  Kp <- terra::extract(k, xy)[, names(k)]
  for (i in 1:2) {
    mm <- list(a, b)[[i]]
    sm <- s[s$LAMBX == mm$LAMBX & s$LAMBY == mm$LAMBY, ]
    sm <- sm[order(sm$DATE), ]
    lat <- sf::st_coordinates(sf::st_transform(
      sf::st_as_sf(mm, coords = c("x", "y"), crs = 2154), 4326))[, 2]
    p <- list(lai_max = 6, forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
    ref <- sylvostation:::.biljou_ru_ref(sylvostation:::.meteo_topo(sm, as.numeric(Kp[i, ]), lat, 0),
                                         ru$ru_mm[i], p)
    expect_equal(pr$is_topo[i], unname(ref[1, "is"]), tolerance = 1e-12)
    expect_equal(pr$nj_topo[i], unname(ref[1, "nj"]), tolerance = 1e-12)
    ref1 <- sylvostation:::.biljou_ru_ref(sylvostation:::.meteo_topo(sm, rep(1, 12), lat, 0),
                                          ru$ru_mm[i], p)
    expect_equal(pr$is_plat[i], unname(ref1[1, "is"]), tolerance = 1e-12)
  }
})
