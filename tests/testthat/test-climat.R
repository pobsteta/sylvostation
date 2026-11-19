# Mission 033 : climat SAFRAN interpole bilineairement entre les centres des mailles.
# Extrait reel de 12 mailles (2003-2004, Licence Ouverte 2.0) ; aucun telechargement.

safran12c <- function() {
  read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv", package = "sylvostation"))
}

# centre d'une maille SAFRAN en Lambert-93 (x = est, y = nord)
centre_l93 <- function(lambx, lamby) {
  p <- sf::st_as_sf(data.frame(x = lambx * 100, y = lamby * 100), coords = c("x", "y"),
                    crs = 27572)
  unname(sf::st_coordinates(sf::st_transform(p, 2154))[1, ])
}

test_that("safran_weights : un point connu en Lambert-93 a les bons poids", {
  s <- safran12c()
  a <- centre_l93(9640, 23690)
  # centre de la maille 9640_23690 : x = est ~ 1 014 550, y = nord ~ 6 799 283
  expect_lt(max(abs(a - c(1014550, 6799283))), 2)
  w <- safran_weights(a[1], a[2], s)
  expect_equal(unname(w[1, "9640_23690"]), 1)
  expect_equal(sum(w), 1)
  # milieu des quatre centres 9640/9720 x 23690/23770 : un quart chacun
  q <- rbind(centre_l93(9640, 23690), centre_l93(9720, 23690), centre_l93(9640, 23770),
             centre_l93(9720, 23770))
  x <- sf::st_as_sf(data.frame(x = 9680 * 100, y = 23730 * 100), coords = c("x", "y"), crs = 27572)
  m <- unname(sf::st_coordinates(sf::st_transform(x, 2154))[1, ])
  w <- safran_weights(m[1], m[2], s)
  expect_equal(unname(w[1, c("9640_23690", "9720_23690", "9640_23770", "9720_23770")]),
               rep(0.25, 4), tolerance = 1e-9)
  expect_equal(sum(w[1, ] > 0), 4L)
  # entre deux centres, sur la ligne : poids lineaires (3/4, 1/4)
  x <- sf::st_as_sf(data.frame(x = 9660 * 100, y = 23690 * 100), coords = c("x", "y"), crs = 27572)
  m <- unname(sf::st_coordinates(sf::st_transform(x, 2154))[1, ])
  w <- safran_weights(m[1], m[2], s)
  expect_equal(unname(w[1, c("9640_23690", "9720_23690")]), c(0.75, 0.25), tolerance = 1e-9)
  # bord de l'extrait (ouest de la colonne 9560) : extrapolation constante, poids renormalises
  b <- centre_l93(9530, 23690)                     # 3 km a l'ouest du centre de 9560_23690
  w <- safran_weights(b[1], b[2], s)
  expect_equal(unname(w[1, "9560_23690"]), 1)
  b <- centre_l93(9560, 23690)
  # loin de toute maille : NA
  w <- safran_weights(b[1] - 9000, b[2], s)
  expect_true(all(is.na(w)))
  expect_error(safran_weights(1, 1:2, s), "longueur")
  expect_error(safran_weights(1, 1, data.frame(a = 1)), "LAMBX")
})

test_that(".safran_interp : moyenne ponderee des series, NA d'une maille de poids nul ignore", {
  s <- sylvostation:::.safran_norm(safran12c())
  mailles <- sylvostation:::.mailles_safran(s)
  L <- sylvostation:::.safran_large(s, c("PRELIQ", "T"), mailles)
  w <- matrix(0, 1, nrow(mailles), dimnames = list(NULL, mailles$maille))
  w[1, c("9640_23690", "9720_23690")] <- c(0.75, 0.25)
  v <- sylvostation:::.safran_interp(L$v$T, w)
  att <- 0.75 * L$v$T[, "9640_23690"] + 0.25 * L$v$T[, "9720_23690"]
  expect_equal(as.numeric(v), unname(att), tolerance = 1e-9)
  m <- L$v$T
  m[, "9560_23530"] <- NA                                  # poids nul : sans effet
  expect_equal(as.numeric(sylvostation:::.safran_interp(m, w)), as.numeric(v))
  m[1, "9720_23690"] <- NA                                 # poids positif : NA ce jour-la
  expect_true(is.na(sylvostation:::.safran_interp(m, w)[1, 1]))
})

test_that("safran_climate bilineaire : continu, egal a l'interpolation des agregats de maille", {
  s <- safran12c()
  cl <- safran_climate(s)
  pr <- safran_climate(s, interpolation = "proche")
  expect_identical(attr(cl, "interpolation"), "bilineaire")
  expect_true(terra::compareGeom(cl, pr))
  expect_equal(terra::res(cl), c(1000, 1000))
  # plus de valeurs distinctes que de mailles : plus d'aplats de 8 km
  expect_gt(length(unique(stats::na.omit(terra::values(cl[["p_sv"]])[, 1]))), 12)
  expect_identical(length(unique(stats::na.omit(terra::values(pr[["p_sv"]])[, 1]))), 12L)
  # une cellule : moyenne des agregats ponderee par safran_weights() en son centre
  xy <- terra::xyFromCell(cl, 400)
  w <- safran_weights(xy[1], xy[2], s)
  agg <- sylvostation:::.climat_mailles(s, 4:9)
  p <- agg$p[match(colnames(w), agg$cle)]
  expect_equal(unname(terra::values(cl[["p_sv"]])[400, 1]), sum(w * p), tolerance = 1e-6)
  # au centre d'une maille interieure, la cellule vaut a peu pres la maille
  a <- centre_l93(9640, 23690)
  v <- terra::extract(cl, rbind(a))$p_sv
  expect_lt(abs(v - agg$p[agg$cle == "9640_23690"]) / agg$p[agg$cle == "9640_23690"], 0.05)
  expect_error(safran_climate(s, interpolation = "krigeage"), "arg")
})

test_that(".biljou_cols : une serie de pluie par colonne = une passe par serie", {
  skip_if_not_installed("biljouR")
  s <- sylvostation:::.safran_norm(safran12c())
  p <- list(lai_max = 6, forest_type = "broadleaved", budburst = 110, leaf_fall = 300)
  met <- function(m) {
    sm <- s[paste(s$LAMBX, s$LAMBY, sep = "_") == m, ]
    biljouR::safran_to_meteo(sm[order(sm$DATE), ], cols = list(date = "DATE", rain_liq = "PRELIQ",
                                                              rain_sol = "PRENEI", pet = "ETP"))
  }
  a <- met("9560_23610")
  b <- met("9720_23610")
  RAIN <- cbind(a$rain, b$rain)
  PET <- cbind(a$pet, b$pet)
  r <- sylvostation:::.biljou_cols(a, PET, c(1L, 2L, 2L), c(80, 80, 40), p,
                                   RAIN = RAIN, rain_idx = c(1L, 2L, 2L))
  att <- rbind(sylvostation:::.biljou_ru(a, 80, p), sylvostation:::.biljou_ru(b, c(80, 40), p))
  expect_equal(r, att, tolerance = 1e-12)
  expect_gt(r[2, "is"], r[1, "is"])     # l'est (moins de pluie) est plus contraint
})

test_that("hydric_stress bilineaire : centre = maille ; entre deux mailles, entre les deux", {
  skip_if_not_installed("biljouR")
  s <- safran12c()
  a <- centre_l93(9640, 23610)
  b <- centre_l93(9720, 23610)
  mid <- (a + b) / 2
  p <- mark_ifn(sf::st_as_sf(data.frame(ru_mm = 80, x = c(a[1], b[1], mid[1]),
                                        y = c(a[2], b[2], mid[2])),
                             coords = c("x", "y"), crs = 2154))
  h <- hydric_stress(p, s)
  hp <- hydric_stress(p, s, interpolation = "proche")
  expect_identical(attr(h, "interpolation"), "bilineaire")
  expect_equal(h$is_biljou[1:2], hp$is_biljou[1:2], tolerance = 1e-9)
  expect_true(h$is_biljou[3] > min(h$is_biljou[1:2]) && h$is_biljou[3] < max(h$is_biljou[1:2]))
  expect_identical(h$maille_safran, hp$maille_safran)
})

test_that("regle des 700 m : climat interpole aux placettes IFN, variables larges seulement", {
  skip_if_not_installed("biljouR")
  s <- safran12c()
  a <- centre_l93(9640, 23610)
  p <- mark_ifn(sf::st_as_sf(data.frame(ru_mm = c(60, 90), x = a[1] + c(0, 2500),
                                        y = a[2] + c(0, 1500)), coords = c("x", "y"), crs = 2154))
  vues <- character(0)
  vraie <- assert_no_fine_extract_on_ifn
  local_mocked_bindings(assert_no_fine_extract_on_ifn = function(points, variables, ...) {
    vues <<- c(vues, variables)
    vraie(points, variables, ...)
  })
  h <- hydric_stress(p, s)
  cl <- safran_climate(s)
  g <- sylvostation:::.extraire_climat(p, cl)
  expect_true(length(vues) > 0)
  expect_true(all(vapply(vues, sylvostation:::.is_coarse, logical(1))))
  expect_false(any(vapply(vues, sylvostation:::.is_fine, logical(1))))
  # une variable fine sur ces placettes reste refusee
  expect_error(assert_no_fine_extract_on_ifn(p, "k_sv"), "IFN")
  # un climat a maille fine (20 m) reste refuse aux placettes
  fin <- terra::disagg(cl, 50)
  expect_error(sylvostation:::.extraire_climat(p, fin), "maille")
})

test_that("hydric_stress_grid bilineaire : pas de saut a la limite de deux mailles", {
  skip_if_not_installed("biljouR")
  s <- safran12c()
  a <- centre_l93(9640, 23610)
  b <- centre_l93(9720, 23610)
  # bande est-ouest de 500 m de haut, cellules de 500 m, du centre de a au centre de b
  y0 <- round((a[2] + b[2]) / 2)
  k <- terra::rast(xmin = round(a[1]) - 250, xmax = round(a[1]) + 7750, ymin = y0 - 250,
                   ymax = y0 + 250, resolution = 500, crs = "EPSG:2154", nlyrs = 12)
  terra::values(k) <- 1
  names(k) <- sprintf("k_%02d", 1:12)
  ru <- data.frame(maille = c("9640_23610", "9720_23610"), ru_mm = 80)
  hb <- hydric_stress_grid(k, ru, s, n_controle = 0)
  hp <- hydric_stress_grid(k, ru, s, n_controle = 0, interpolation = "proche")
  vb <- terra::values(hb)[, "is_plat"]
  vp <- terra::values(hp)[, "is_plat"]
  expect_false(anyNA(vb))
  sb <- abs(diff(vb))
  sp <- abs(diff(vp))
  # proche : un seul saut (la limite) porte tout l'ecart ; bilineaire : ecart reparti
  expect_gt(max(sp), 0.9 * abs(vp[16] - vp[1]))
  expect_lt(max(sb), 0.25 * abs(vb[16] - vb[1]))
  # bords : les noeuds des centres retrouvent la maille
  expect_equal(vb[1], vp[1], tolerance = 0.02 * vp[1])
  expect_identical(attr(hb, "parametres")$interpolation, "bilineaire")
  expect_true(all(attr(hb, "mailles")$n_unites >= 1))
  expect_error(hydric_stress_grid(k, ru, s, node_res = 0), "node_res")
})

test_that("ru_by_safran_cell : moins de min_placettes placettes -> mediane de l'emprise", {
  s <- safran12c()
  a <- centre_l93(9640, 23690)
  b <- centre_l93(9560, 23530)
  p <- mark_ifn(sf::st_as_sf(data.frame(ru_mm = c(60, 100, 200, 40, 50),
                                        x = c(a[1], a[1] + 1000, a[1] - 2000, b[1], b[1] + 100),
                                        y = c(a[2], a[2], a[2], b[2], b[2])),
                             coords = c("x", "y"), crs = 2154))
  r1 <- ru_by_safran_cell(p, s)
  expect_equal(r1$ru_mm[r1$maille == "9560_23530"], 45)
  r3 <- ru_by_safran_cell(p, s, min_placettes = 3)
  expect_equal(r3$ru_mm[r3$maille == "9640_23690"], 100)          # 3 placettes : gardee
  expect_equal(r3$ru_mm[r3$maille == "9560_23530"], 60)           # 2 : mediane des 5
  expect_equal(r3$n_placettes[r3$maille == "9560_23530"], 2)
  expect_match(r3$origine[r3$maille == "9560_23530"], "moins de 3 placettes")
  expect_error(ru_by_safran_cell(p, s, min_placettes = 0), "min_placettes")
})
