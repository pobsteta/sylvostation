# Mission 031 : comparaison a CarHab 68. Aucun telechargement : extrait reel de
# inst/extdata (polygones CarHab, Licence Ouverte) ou jeux fabriques dans le test.

extrait_carhab <- function() {
  sf::read_sf(system.file("extdata", "carhab_extrait_emprise_test.gpkg", package = "sylvostation"))
}

test_that("carhab_levels / carhab_recode : ordre provisoire, neutre distinct de basique", {
  a <- carhab_levels("acidite_edaphique")
  expect_equal(unname(a["neutre"]), 3L)
  expect_equal(unname(a["basique"]), 4L)   # jamais fusionnes
  h <- carhab_levels("humidite_edaphique")
  expect_equal(unname(h[c("assez sec", "mésique")]), c(1L, 2L))
  r <- carhab_recode(c("très acide", "neutre", NA, "inconnue", "inconnue"), "acidite_edaphique")
  expect_equal(as.integer(r), c(1L, 3L, NA, NA, NA))
  expect_equal(unname(as.integer(attr(r, "inconnues"))), 2L)
  expect_equal(names(attr(r, "inconnues")), "inconnue")
  expect_error(carhab_levels("autre"))
})

test_that("carhab_wfs_url : requete du par. 26.2, filtre INTERSECTS en 2154, x/y inverses refuses", {
  u <- carhab_wfs_url(c(1007000, 6790000, 1022000, 6805000), "foret", 500, 250)
  expect_match(u, "TYPENAMES=Carhab_habitat:habitats_carhab", fixed = TRUE)
  expect_match(u, "STARTINDEX=500", fixed = TRUE)
  expect_match(u, "COUNT=250", fixed = TRUE)
  dec <- utils::URLdecode(u)
  expect_match(dec, "INTERSECTS(geom,SRID=2154;POLYGON((1007000 6790000,1022000 6790000,1022000 6805000,1007000 6805000,1007000 6790000)))", fixed = TRUE)
  expect_match(dec, "occupation='foret'", fixed = TRUE)
  expect_false(grepl("occupation", utils::URLdecode(carhab_wfs_url(c(1007000, 6790000, 1022000, 6805000), NULL))))
  expect_error(carhab_wfs_url(c(6790000, 1007000, 6805000, 1022000)), "inverses|Lambert")
  expect_error(carhab_wfs_url(c(1022000, 6790000, 1007000, 6805000)), "bbox")
})

test_that("carhab_fetch : cache relu sans reseau ; pagination, doublons et CRS absent", {
  x <- extrait_carhab()
  bb <- c(1007000, 6790000, 1022000, 6805000)
  nom <- "carhab_foret_1007000_6790000_1022000_6805000.gpkg"
  # cache present : le lecteur ne doit pas etre appele
  d <- file.path(tempfile("cache_carhab"))
  dir.create(d)
  sf::write_sf(x, file.path(d, nom))
  out <- carhab_fetch(bb, d, reader = function(u) stop("reseau interdit"))
  expect_equal(nrow(out), nrow(x))
  # pagination : pages de 10 (la derniere plus courte), un doublon, CRS retire
  n <- nrow(x)
  appels <- character()
  lecteur <- function(url) {
    appels <<- c(appels, url)
    s <- as.integer(sub(".*STARTINDEX=([0-9]+).*", "\\1", url))
    i <- seq_len(n)
    i <- i[i > s][seq_len(min(10L, max(0L, n - s)))]
    p <- x[i, ]
    if (s == 10L) p <- rbind(p, x[1, ])   # doublon d'une page a l'autre
    sf::st_crs(p) <- NA
    p
  }
  d2 <- file.path(tempfile("cache_carhab"))
  out2 <- carhab_fetch(bb, d2, taille_page = 10L, reader = lecteur, essais = 1L)
  expect_equal(nrow(out2), n)
  expect_equal(length(appels), ceiling(n / 10))
  expect_true(sf::st_crs(out2) == sf::st_crs(2154))
  expect_true(file.exists(file.path(d2, nom)))
  expect_s3_class(sf::st_geometry(out2), "sfc_MULTIPOLYGON")
  # page illisible : erreur nette
  expect_error(carhab_fetch(bb, file.path(tempfile("cache_carhab")),
                            reader = function(u) stop("panne"), essais = 1L), "illisible")
})

test_that("carhab_rasterize : un point connu tombe dans la bonne cellule (Lambert-93, x = est, y = nord)", {
  x <- extrait_carhab()
  grille <- terra::rast(xmin = 1007000, xmax = 1022000, ymin = 6790000, ymax = 6805000,
                        resolution = 20, crs = "EPSG:2154")
  r <- carhab_rasterize(x, grille, "acidite_edaphique")
  h <- carhab_rasterize(x, grille, "humidite_edaphique")
  # Point (x 1013643, y 6798321) dans le polygone 6057 (neutre, mesique, biotope 338802) :
  # colonne floor((1013643 - 1007000) / 20) + 1 = 333, ligne floor((6805000 - 6798321) / 20) + 1 = 334
  cel <- terra::cellFromXY(grille, cbind(1013643, 6798321))
  expect_equal(unname(terra::rowColFromCell(grille, cel)), unname(cbind(334, 333)))
  expect_equal(terra::values(r)[cel], 3)   # neutre
  expect_equal(terra::values(h)[cel], 2)   # mesique
  # le centre de cette cellule est (1013650, 6798330)
  expect_equal(unname(terra::xyFromCell(grille, cel)), unname(cbind(1013650, 6798330)))
  # hors de l'extrait : NA ; aucun rang hors des modalites
  expect_true(is.na(terra::values(r)[terra::cellFromXY(grille, cbind(1021000, 6791000))]))
  expect_true(all(terra::values(r)[!is.na(terra::values(r))] %in% 1:5))
  # surface rasterisee proche de la surface des polygones decoupes (centre de cellule)
  ha_r <- sum(!is.na(terra::values(r))) * 400 / 1e4
  poly <- sf::st_intersection(sf::st_geometry(x), sf::st_as_sfc(sf::st_bbox(
    c(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000), crs = sf::st_crs(2154))))
  expect_lt(abs(ha_r - sum(as.numeric(sf::st_area(poly))) / 1e4) / ha_r, 0.05)
  # CRS autre que 2154 refuse
  expect_error(carhab_rasterize(sf::st_transform(x, 4326), grille), "2154")
  expect_error(carhab_rasterize(x, terra::rast(xmin = 0, xmax = 10, ymin = 0, ymax = 10,
                                               resolution = 1, crs = "EPSG:4326")), "2154")
})

test_that("carhab_quantile_classes : memes parts de surface que CarHab", {
  x <- c(5, 3, 1, 6, 2, 4, 9, 8, 7, 10)
  ref <- c(1, 1, 1, 2, 2, 2, 2, 4, 4, 4)   # parts 0,3 / 0,4 / 0,3 ; rang 3 absent
  q <- carhab_quantile_classes(x, ref)
  expect_equal(q$rangs, c(1, 2, 4))
  expect_equal(q$parts, c(0.3, 0.4, 0.3))
  expect_equal(as.numeric(table(q$classe)), c(3, 4, 3))
  expect_true(all(q$classe[x <= 3] == 1))
  expect_true(all(q$classe[x >= 8] == 3))
  expect_equal(carhab_quantile_classes(1:3, rep(2, 3))$classe, rep(1L, 3))
  expect_error(carhab_quantile_classes(c(1, NA), c(1, 2)), "NA")
  expect_error(carhab_quantile_classes(1:3, 1:2), "longueur")
})

test_that("carhab_kappa : valeurs calculees a la main", {
  expect_equal(carhab_kappa(c(1, 2, 3), c(1, 2, 3))$kappa, 1)
  # deux classes : kappa pondere = kappa simple = 0,5 ; po = 0,75
  k2 <- carhab_kappa(c(1, 1, 2, 2), c(1, 2, 2, 2))
  expect_equal(k2$kappa, 0.5)
  expect_equal(k2$kappa_simple, 0.5)
  expect_equal(k2$accord_exact, 0.75)
  # trois classes : lineaire 5/7, quadratique 0,8, accord exact 0,75, a une classe 1
  a <- c(1, 2, 3, 3); b <- c(1, 2, 3, 2)
  k3 <- carhab_kappa(a, b)
  expect_equal(k3$kappa, 5 / 7)
  expect_equal(carhab_kappa(a, b, poids = "quadratique")$kappa, 0.8)
  expect_equal(k3$accord_exact, 0.75)
  expect_equal(k3$accord_1_classe, 1)
  expect_equal(as.integer(k3$matrice[3, 2]), 1L)   # a = 3 en ligne, b = 2 en colonne
  expect_equal(dim(carhab_kappa(a, b, k = 4)$matrice), c(4L, 4L))
  expect_error(carhab_kappa(c(1, NA), c(1, 2)), "NA")
})

test_that("carhab_spearman : monotone = 1, bruit = 0, blocs et sous-echantillon espace", {
  xy <- expand.grid(cx = 1007010 + 20 * 0:99, cy = 6790010 + 20 * 0:99)   # 2 km x 2 km
  s <- carhab_spearman(xy$cx, xy$cx, xy$cx, xy$cy, bloc_m = 500, pas_m = 200, nboot = 50)
  expect_equal(s$rho, 1)
  expect_equal(s$bloc$n_blocs, 16)       # 4 x 4 blocs de 500 m
  expect_equal(s$espace$n, 100)          # 10 x 10 cellules espacees de 200 m
  expect_equal(s$bloc$ic_haut, 1)
  # gradient en x + bruit : rho positif, intervalle autour de rho, graine reproductible
  set.seed(42)
  v <- xy$cx + rnorm(nrow(xy), sd = 600)
  s1 <- carhab_spearman(v, xy$cx, xy$cx, xy$cy, bloc_m = 500, pas_m = 200, nboot = 100, seed = 7)
  s2 <- carhab_spearman(v, xy$cx, xy$cx, xy$cy, bloc_m = 500, pas_m = 200, nboot = 100, seed = 7)
  expect_equal(s1, s2)
  expect_gt(s1$rho, 0.3); expect_lt(s1$rho, 0.9)
  expect_lt(s1$bloc$ic_bas, s1$bloc$ic_haut)
  expect_lt(s1$espace$ic_bas, s1$espace$rho); expect_gt(s1$espace$ic_haut, s1$espace$rho)
  # sans lien : rho proche de 0
  z <- carhab_spearman(rnorm(nrow(xy)), xy$cx, xy$cx, xy$cy, nboot = 20)
  expect_lt(abs(z$rho), 0.05)
  expect_error(carhab_spearman(c(1, NA), 1:2, 1:2, 1:2), "NA")
  expect_error(carhab_spearman(1:3, 1:2, 1:3, 1:3), "longueur")
})

test_that("carhab_compare : comptes, domaine commun, zone d'applicabilite, kappa (jeu synthetique)", {
  g <- terra::rast(xmin = 1007000, xmax = 1008000, ymin = 6790000, ymax = 6791000,
                   resolution = 20, crs = "EPSG:2154")   # 50 x 50
  col <- terra::colFromCell(g, seq_len(terra::ncell(g)))
  grad <- g; terra::values(grad) <- col + (seq_along(col) %% 3) * 0.1
  ref <- g; terra::values(ref) <- ifelse(col <= 20, 1, ifelse(col <= 35, 2, 3))
  grad[1:5, ] <- NA                 # 5 lignes hors foret chez nous : 250 cellules
  ref[, 1:10] <- NA                 # 10 colonnes hors foret CarHab : 500 cellules
  aoa <- g; terra::values(aoa) <- 1
  aoa[10:12, 30:32] <- 0            # 9 cellules hors zone d'applicabilite (dans le commun)
  res <- carhab_compare(grad, ref, aoa, bloc_m = 200, pas_m = 100, nboot = 30)
  expect_equal(unname(res$comptes["foret_nous"]), 2500 - 250)
  expect_equal(unname(res$comptes["foret_carhab"]), 2500 - 500)
  expect_equal(unname(res$comptes["commun"]), 2500 - 250 - 500 + 50)   # 5 x 10 recouvrement
  expect_equal(unname(res$comptes["hors_aoa"]), 9)
  expect_equal(nrow(res$domaine), unname(res$comptes["retenues"]))
  expect_gt(res$spearman$rho, 0.9)
  expect_gt(res$kappa$kappa, 0.9)
  expect_gt(res$kappa_quad$kappa, res$kappa$kappa - 1e-9)
  expect_equal(sum(res$kappa$matrice), nrow(res$domaine))
  expect_equal(sum(res$par_modalite$n), nrow(res$domaine))
  # sans aoa : on retrouve tout le domaine commun
  r0 <- carhab_compare(grad, ref, NULL, nboot = 5)
  expect_equal(unname(r0$comptes["retenues"]), unname(r0$comptes["commun"]))
  # grilles differentes : refus
  expect_error(carhab_compare(grad, terra::rast(xmin = 1007000, xmax = 1007500, ymin = 6790000,
                                                ymax = 6790500, resolution = 20, crs = "EPSG:2154")),
               "meme grille")
})
