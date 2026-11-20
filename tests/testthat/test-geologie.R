# Mission 004 : géologie et recodage lithologique.
# Grille et jeux synthétiques construits localement (aucune fonction de grille du paquet).

geol_reelle <- function() {
  sf::st_read(system.file("extdata", "bdcharm50_emprise_test.gpkg", package = "sylvostation"),
              quiet = TRUE)
}

# Deux carrés côte à côte en Lambert-93 : A (x 1000000-1000500) et B (1000500-1001000),
# y 6800000-6800500 ; synthetic = TRUE.
synth_geol <- function(dep = c("67", "68"), nota = c("a", "b"), code = c(1, 2),
                       classe = c("granite", "gres")) {
  box <- function(x0) sf::st_polygon(list(rbind(c(x0, 6800000), c(x0 + 500, 6800000),
    c(x0 + 500, 6800500), c(x0, 6800500), c(x0, 6800000))))
  sf::st_sf(dep = dep, NOTATION = nota, CODE = code, DESCR = c("Granite A", "Grès B"),
            classe = classe, synthetic = TRUE,
            geometry = sf::st_sfc(box(1000000), box(1000500), crs = 2154))
}

synth_grille <- function(res = 100) {
  terra::rast(xmin = 1000000, xmax = 1001000, ymin = 6800000, ymax = 6800500,
              resolution = res, crs = "EPSG:2154")
}

test_that("list_formations regroupe par NOTATION et somme les surfaces (extrait réel)", {
  f <- list_formations(geol_reelle())
  expect_equal(nrow(f), 94)  # 94 NOTATION distinctes (docs/referentiels.md, 5)
  expect_named(f, c("notation", "code", "description", "n_poly", "area_km2"))
  expect_equal(sum(f$n_poly), 661)
  expect_equal(sum(f$area_km2), 225, tolerance = 0.01)
  expect_false(is.unsorted(rev(f$area_km2)))
  # Grès vosgien : CODE 131 (68) et 155 (67), jamais jointure par CODE
  codes <- strsplit(f$code[f$notation == "t1-2V"], "/")[[1]]
  expect_setequal(codes, c("131", "155"))
})

test_that("list_formations refuse un CRS faux ou un champ absent", {
  g <- synth_geol()
  expect_error(list_formations(sf::st_transform(g, 4326)), "2154|Syst")
  expect_error(list_formations(g[, c("dep", "NOTATION")]), "absent")
  expect_error(list_formations(data.frame(a = 1)), "sf")
})

test_that("recode_lithology : première règle gagnante, non_classe jamais par défaut", {
  rules <- data.frame(priorite = c(2, 1), motif = c("calcaire", "granit"),
                      classe = c("calcaire", "granite"))
  f <- data.frame(notation = c("n1", "n2", "n3", "n4"),
                  description = c("Granite à deux micas", "Calcaire à entroques",
                                  "Granite et calcaire", "Remblais"))
  expect_warning(r <- recode_lithology(f, rules), "n4")
  expect_equal(r$classe, c("granite", "calcaire", "granite", "non_classe"))
  expect_equal(r$statut, c("regle", "regle", "regle", "non_classe"))
  expect_false(any(r$validated))
  # Sans formation orpheline : pas d'avertissement
  expect_no_warning(recode_lithology(f[1:2, ], rules))
  # Accents et casse : insensible
  g <- data.frame(notation = "z", description = "GRÈS")
  expect_equal(suppressWarnings(recode_lithology(g, read_lithology_rules()))$classe, "gres")
  expect_error(recode_lithology(f, data.frame(priorite = 1, motif = "x", classe = "non_classe")),
               "réserv")
})

test_that("recode_lithology sur l'extrait réel : classes attendues et reste non classé", {
  f <- list_formations(geol_reelle())
  expect_warning(r <- recode_lithology(f, read_lithology_rules()), "sans règle")
  cl <- setNames(r$classe, r$notation)
  expect_equal(cl[["t1-2V"]], "gres")           # Grès vosgien
  expect_equal(cl[["h3M2Ka"]], "gneiss_migmatite")
  expect_equal(cl[["t1-2P"]], "conglomerat")    # Poudingue de Ste Odile
  expect_equal(cl[["X"]], "non_classe")         # Remblais
  expect_equal(cl[["h2ã3sc"]], "granite")  # granite du Bilstein
  n_classes <- length(setdiff(unique(r$classe), "non_classe"))
  expect_gte(n_classes, 8)
  expect_lte(n_classes, 15)
})

test_that("la table livrée est cohérente avec les règles et reste non validée", {
  csv <- system.file("extdata", "lithologie_massif_test.csv", package = "sylvostation")
  tab <- utils::read.csv(csv, encoding = "UTF-8", stringsAsFactors = FALSE)
  expect_true(all(c("notation", "classe", "statut", "validated") %in% names(tab)))
  expect_false(any(tab$validated))
  expect_setequal(tab$statut, c("regle", "non_classe"))
  expect_equal(tab$classe == "non_classe", tab$statut == "non_classe")
  f <- list_formations(geol_reelle())
  expect_setequal(tab$notation, f$notation)
  r <- suppressWarnings(recode_lithology(f, read_lithology_rules()))
  expect_equal(tab$classe[match(r$notation, tab$notation)], r$classe)
})

test_that("rasterize_geol : un point connu tombe dans la bonne cellule et la bonne classe", {
  r <- rasterize_geol(synth_geol(), synth_grille(), "classe")
  expect_s4_class(r, "SpatRaster")
  expect_true(terra::is.factor(r))
  # x = est, y = nord. Point (1000250 ; 6800350) : dans A (granite). Cellule de 100 m :
  # colonne 3, ligne 2 (lignes comptées depuis le nord, 6800500).
  cel <- terra::cellFromXY(r, cbind(1000250, 6800350))
  expect_equal(terra::rowColFromCell(r, cel), cbind(2, 3))
  expect_equal(as.character(terra::extract(r, cbind(1000250, 6800350))[1, 1]), "granite")
  expect_equal(as.character(terra::extract(r, cbind(1000750, 6800050))[1, 1]), "gres")
  # Hors polygones : NA
  expect_true(is.na(terra::extract(r, cbind(1000250, 6800700))[1, 1]))
  expect_true(sf::st_crs(terra::crs(r)) == sf::st_crs(2154))
})

test_that("rasterize_geol joint par NOTATION via une table, non_classe pour l'absente", {
  g <- synth_geol()
  g$classe <- NULL
  tab <- data.frame(notation = "a", classe = "granite")
  r <- rasterize_geol(g, synth_grille(), "litho", table = tab)
  expect_equal(as.character(terra::extract(r, cbind(1000750, 6800250))[1, 1]), "non_classe")
  expect_equal(as.character(terra::extract(r, cbind(1000250, 6800250))[1, 1]), "granite")
  expect_error(rasterize_geol(g, synth_grille(), "absent"), "absent")
  expect_error(rasterize_geol(sf::st_transform(g, 4326), synth_grille()), "2154|Syst")
})

test_that("rasterize_geol sur l'extrait réel couvre la grille de l'emprise", {
  g <- geol_reelle()
  grille <- terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
                        resolution = 100, crs = "EPSG:2154")
  tab <- suppressWarnings(recode_lithology(list_formations(g), read_lithology_rules()))
  r <- rasterize_geol(g, grille, "classe", table = tab)
  frac_na <- terra::global(is.na(r), "mean")[[1]]
  expect_lt(frac_na, 0.01)
  expect_gte(nrow(terra::levels(r)[[1]]), 8)
})

lit_rast <- function(m, res = 100) {
  r <- terra::rast(nrows = nrow(m), ncols = ncol(m), xmin = 1000000,
                   xmax = 1000000 + ncol(m) * res, ymin = 6800000,
                   ymax = 6800000 + nrow(m) * res, crs = "EPSG:2154")
  terra::values(r) <- as.vector(t(m))
  levels(r) <- data.frame(id = 1:3, classe = c("a", "b", "c"))
  r
}

test_that("dominant_lithology : classe modale du disque, îlot absorbé", {
  m <- matrix(1, 21, 21)
  m[11, 11] <- 2  # une cellule de 100 m dans un fond de classe 1
  d <- dominant_lithology(lit_rast(m), radius = 300)
  expect_equal(names(d), "geologie_700m")
  expect_true(all(terra::values(d) == 1))
  expect_equal(as.character(terra::levels(d)[[1]]$classe), c("a", "b", "c"))
  # Moitié/moitié : loin de la limite, la classe locale est conservée
  m2 <- cbind(matrix(1, 21, 10), matrix(2, 21, 11))
  d2 <- dominant_lithology(lit_rast(m2), radius = 300)
  expect_equal(as.numeric(terra::extract(d2, cbind(1000050, 6800050))[1, 1]), 1)
  expect_equal(as.numeric(terra::extract(d2, cbind(1002050, 6800050))[1, 1]), 2)
})

test_that("dominant_lithology : égalité déterministe, NA propagés, rayon validé", {
  # Disque de rayon 100 m (5 cellules en croix) à la limite 1|2 : centre sur la colonne 1 -> 3 cellules de 1
  m <- cbind(matrix(1, 9, 5), matrix(2, 9, 4))
  d <- dominant_lithology(lit_rast(m), radius = 100)
  # Cellule de la colonne 5 (1re classe), ligne 5 : voisins E de classe 2 -> 4 cellules de 1 vs 1 de 2
  expect_equal(as.numeric(terra::values(d)[5 * 9 - 4 + 0]), 1)
  # Raster déjà déterministe : deux appels identiques
  expect_identical(terra::values(dominant_lithology(lit_rast(m), 100)), terra::values(d))
  # Cellule seule sans voisin : NA hors données
  mna <- matrix(NA_real_, 5, 5); mna[1, 1] <- 3
  dn <- dominant_lithology(lit_rast(mna), radius = 100)
  expect_true(is.na(terra::values(dn)[25]))
  expect_equal(as.numeric(terra::values(dn)[1]), 3)
  # Égalité parfaite (1 contre 1) : la classe de plus petit identifiant l'emporte
  dt <- dominant_lithology(lit_rast(matrix(c(1, 2), 1, 2)), radius = 100)
  expect_equal(as.numeric(terra::values(dt)), c(1, 1))
  expect_error(dominant_lithology(lit_rast(m), radius = -1), "positif")
  expect_error(dominant_lithology(terra::rast(lit_rast(m), vals = 1)), "catégoriel")
})

test_that("règle bloquante : geologie_700m passe sur placettes IFN, une variable fine non", {
  expect_true("geologie_700m" %in% COARSE_VARIABLES)
  p <- mark_ifn(data.frame(x = 1007100, y = 6790100))
  expect_no_error(assert_no_fine_extract_on_ifn(p, "geologie_700m"))
  expect_error(assert_no_fine_extract_on_ifn(p, "pente"), "IFN|700|pr.cision", ignore.case = TRUE)
})

test_that("check_geol_joins signale un changement d'unité à la limite de département", {
  expect_warning(r <- check_geol_joins(synth_geol()), "changement")
  expect_equal(nrow(r), 1)
  expect_equal(r$champ, "dep")
  expect_equal(r$longueur_m, 500, tolerance = 0.05)
  expect_true(r$unite_change)
  # Même NOTATION, CODE différent : pas de changement d'unité, mais CODE signalé
  g <- synth_geol(nota = c("a", "a"))
  expect_no_warning(r2 <- check_geol_joins(g))
  expect_false(r2$unite_change)
  expect_true(r2$code_differe)
  # Même département : rien à signaler
  expect_equal(nrow(check_geol_joins(synth_geol(dep = c("68", "68")))), 0)
  # Sans champ de groupe : message, tableau vide
  g3 <- synth_geol()[, c("NOTATION", "CODE")]
  expect_message(r3 <- check_geol_joins(g3), "Aucun champ")
  expect_equal(nrow(r3), 0)
})

test_that("check_geol_joins sur l'extrait réel repère les contacts 67/68", {
  r <- suppressWarnings(check_geol_joins(geol_reelle()))
  expect_s3_class(r, "data.frame")
  expect_gt(nrow(r), 0)
  expect_true("dep" %in% r$champ)
  expect_true(all(r$longueur_m >= 50))
  d <- r[r$champ == "dep", ]
  expect_true(all(c("067", "068") %in% c(d$groupe_a, d$groupe_b)))
})

# --- lithology_at_points (mission 035) -----------------------------------------------
pt_sf <- function(x, y, id = "p", ifn = FALSE) {
  p <- sf::st_sf(id_placette = id, geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154))
  if (ifn) mark_ifn(p) else { p$loc_precision_m <- 10; p }   # point precis (10 m) hors IFN
}
tab_synth <- data.frame(notation = c("a", "b"), classe = c("granite", "gres"))

test_that("lithology_at_points : un point connu tombe dans la bonne classe (Lambert-93, x = est)", {
  g <- synth_geol()
  # carre A : x 1000000-1000500 (granite) ; carre B : x 1000500-1001000 (gres)
  expect_equal(lithology_at_points(pt_sf(1000100, 6800250), g, tab_synth, radius = 100)$coarse_litho_700m,
               "granite")
  expect_equal(lithology_at_points(pt_sf(1000900, 6800250), g, tab_synth, radius = 100)$coarse_litho_700m,
               "gres")
  # x et y inverses : refus (coordonnees implausibles en Lambert-93), jamais un resultat
  expect_error(lithology_at_points(pt_sf(6800250, 1000100), g, tab_synth, radius = 100))
})

test_that("lithology_at_points : classe modale par surface, couverture et seuil", {
  g <- synth_geol()
  # disque de 300 m centre en x = 1000400 : 2/3 environ cote A (granite)
  r <- lithology_at_points(pt_sf(1000400, 6800250), g, tab_synth, radius = 300)
  expect_equal(r$coarse_litho_700m, "granite")
  expect_gt(r$litho_part_dominante, 0.5)
  expect_lte(r$litho_couverture, 1)
  # point hors de toute geologie : pas de classe, couverture nulle
  h <- lithology_at_points(pt_sf(1005000, 6805000), g, tab_synth, radius = 300)
  expect_true(is.na(h$coarse_litho_700m))
  expect_equal(h$litho_couverture, 0)
  # disque a moins de la moitie couvert : NA ; avec min_cover = 0 : une classe
  c1 <- lithology_at_points(pt_sf(1000250, 6800250), g, tab_synth, radius = 700)
  expect_lt(c1$litho_couverture, 0.5)
  expect_true(is.na(c1$coarse_litho_700m))
  c0 <- lithology_at_points(pt_sf(1000250, 6800250), g, tab_synth, radius = 700, min_cover = 0)
  expect_false(is.na(c0$coarse_litho_700m))
})

test_that("lithology_at_points : notation sans classe -> non_classe, listee ; jamais par defaut", {
  g <- synth_geol()
  r <- lithology_at_points(pt_sf(1000900, 6800250), g, tab_synth[1, ], radius = 100)
  expect_equal(r$coarse_litho_700m, "non_classe")
  f <- attr(r, "formations_non_classees")
  expect_equal(f$notation, "b")
  expect_equal(f$n_points, 1L)
  expect_gt(f$surface_km2, 0)
  expect_equal(nrow(attr(lithology_at_points(pt_sf(1000100, 6800250), g, tab_synth, radius = 100),
                         "formations_non_classees")), 0)
})

test_that("lithology_at_points : la regle des 700 m bloque un rayon inferieur a la precision IFN", {
  g <- synth_geol()
  p <- pt_sf(1000250, 6800250, ifn = TRUE)
  expect_error(lithology_at_points(p, g, tab_synth, radius = 100), "précision|fine")
  expect_error(lithology_at_points(p, g, tab_synth, radius = 699), "précision")
  expect_error(lithology_at_points(p, g, tab_synth, radius = 700, min_cover = 0), NA)
  # placette IFN dont loc_precision_m a ete retire ou vaut NA : au moins 700 m s'applique,
  # un rayon de 50 m est refuse (jamais un contournement par colonne absente)
  q <- p
  q$loc_precision_m <- NULL
  expect_error(lithology_at_points(q, g, tab_synth, radius = 50, min_cover = 0), "pr\u00e9cision")
  expect_error(suppressWarnings(lithology_at_points(q, g, tab_synth, radius = 700, min_cover = 0)), NA)
  q2 <- p
  q2$loc_precision_m <- NA_real_
  expect_error(lithology_at_points(q2, g, tab_synth, radius = 50, min_cover = 0), "pr\u00e9cision")
  # hors IFN : precision absente ou NA refusee
  n1 <- pt_sf(1000250, 6800250)
  n1$loc_precision_m <- NULL
  expect_error(lithology_at_points(n1, g, tab_synth, radius = 700), "loc_precision_m")
  n2 <- pt_sf(1000250, 6800250)
  n2$loc_precision_m <- NA_real_
  expect_error(lithology_at_points(n2, g, tab_synth, radius = 700), "loc_precision_m")
  # validations
  expect_error(lithology_at_points(p, g, tab_synth, radius = -1), "radius")
  expect_error(lithology_at_points(p, g, tab_synth, min_cover = 2), "min_cover")
  expect_error(lithology_at_points(p, g, data.frame(a = 1)), "table")
  expect_error(lithology_at_points(sf::st_transform(p, 4326), g, tab_synth), "2154|Syst")
  expect_error(lithology_at_points(data.frame(a = 1), g, tab_synth), "sf")
})

test_that("lithology_encoded_layer : chaque classe prend sa valeur encodee, NA reste NA", {
  r <- terra::rast(nrows = 2, ncols = 3, xmin = 1000000, xmax = 1000300, ymin = 6800000,
                   ymax = 6800200, crs = "EPSG:2154")
  terra::values(r) <- c(1, 2, 1, 2, 3, NA)
  levels(r) <- data.frame(id = 1:3, classe = c("granite", "gres", "loess"))
  e <- target_encoding(c("granite", "granite", "gres"), c(5, 5, 3), k = 0)
  o <- lithology_encoded_layer(r, e)
  expect_identical(names(o), "coarse_litho_enc")
  expect_equal(terra::values(o, mat = FALSE), c(5, 3, 5, 3, attr(e, "generale"), NA))
  expect_error(lithology_encoded_layer(1, e), "SpatRaster")
  expect_error(lithology_encoded_layer(terra::rast(r, vals = 1), e), "cat")
})

test_that("formation_encoded_layer : valeur de la formation dominante, a la maille de 100 m puis sur la grille", {
  g <- synth_geol()   # A : x 1000000-1000500, B : x 1000500-1001000 ; NOTATION a et b
  grid <- terra::rast(xmin = 1000000, xmax = 1001000, ymin = 6800000, ymax = 6800500,
                      resolution = 50, crs = "EPSG:2154")
  e <- target_encoding(c("a", "a", "b", "b"), c(2, 2, 8, 8), k = 0)
  r <- formation_encoded_layer(g, grid, e, radius = 700, res = 100)
  expect_identical(names(r), "coarse_formation_enc")
  expect_equal(terra::res(r), c(50, 50))
  v <- function(x, y) terra::extract(r, cbind(x, y))[[1]]     # x = est, y = nord
  # rayon 700 m : toutes les cellules voient les deux carres ; la modale depend de la position
  expect_equal(v(1000050, 6800250), 2)    # extremite ouest : A domine
  expect_equal(v(1000950, 6800250), 8)    # extremite est : B domine
  expect_error(formation_encoded_layer(g, grid, e, res = 75), "multiple")
  expect_error(formation_encoded_layer(g[, "dep"], grid, e), "NOTATION")
})
