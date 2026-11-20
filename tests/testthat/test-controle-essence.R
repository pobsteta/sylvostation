# Controle par essence et sensibilite (mission 037, ADR 0008). Jeux d'essai fabriques
# (synthetic = TRUE) ; aucun telechargement.

synth_arbre_essence <- function() {
  a <- data.frame(
    id_placette = c("A", "A", "A", "A", "B", "B", "C"),
    ESPAR = c("09", "61", "09", "62", "61", "61", "52"),
    C13 = c(1.0, 0.5, 0.8, 0.9, 0.6, 0.6, 0.7),
    W = c(14.1, 88.4, 14.1, 14.1, 39.3, 39.3, 14.1),
    VEGET = c("0", "0", "5", "0", "0", "1", "0"),   # arbre 3 de A : mort sur pied
    stringsAsFactors = FALSE)
  a$synthetic <- TRUE
  a
}

test_that("read_espar_codes lit le dictionnaire de l'IFN (code, nom, latin)", {
  d <- read_espar_codes()
  expect_equal(names(d), c("code", "nom", "latin"))
  expect_equal(nrow(d), 195L)
  expect_equal(d$latin[d$code == "09"], "Fagus sylvatica")
  expect_equal(d$nom[d$code == "52"], "Pin sylvestre")
  expect_error(read_espar_codes(tempfile()), "introuvable")
})

test_that("espar_group_tfv regroupe comme la BD Foret (hypothese) et garde les NA", {
  g <- espar_group_tfv(c("09", "03", "61", "62", "52", "64", "63", "56", "13G", NA))
  expect_equal(g[1:2], c("Hêtre", "Chênes décidus"))
  expect_equal(g[3], g[4])                      # sapin et epicea sont groupes (G61)
  expect_equal(g[8], "Autres conifères")
  expect_equal(g[9], "Autres feuillus")
  expect_true(is.na(g[10]))
})

test_that("dominant_species : surface terriere ponderee par W, vivants seuls, part et ordre", {
  a <- synth_arbre_essence()
  d <- dominant_species(a, ids = c("C", "A", "B", "Z"))
  expect_equal(d$id_placette, c("C", "A", "B", "Z"))
  # A : 09 -> 14,1 * 1,0^2 / 4pi = 1,1221 ; 61 -> 88,4 * 0,25 / 4pi = 1,7588 ; 62 -> 14,1 * 0,81 / 4pi = 0,9088
  # (l'arbre mort de A est ignore) : le sapin domine avec W, alors que sans W le hetre dominerait
  g09 <- 14.1 * 1 / (4 * pi); g61 <- 88.4 * 0.25 / (4 * pi); g62 <- 14.1 * 0.81 / (4 * pi)
  expect_equal(d$espar[d$id_placette == "A"], "61")
  expect_equal(d$share[d$id_placette == "A"], g61 / (g09 + g61 + g62), tolerance = 1e-9)
  expect_equal(d$g_ha[d$id_placette == "A"], g09 + g61 + g62, tolerance = 1e-9)
  expect_false(d$pure[d$id_placette == "A"])             # 0,46 < 0,75
  expect_true(d$pure[d$id_placette == "B"])              # une seule essence
  expect_equal(d$share[d$id_placette == "B"], 1)
  expect_true(all(is.na(d[d$id_placette == "Z", c("espar", "share", "g_ha", "pure")])))
  sans_w <- a; sans_w$W <- 1
  expect_equal(dominant_species(sans_w)$espar[1], "09")   # sans W : mauvais resultat
  expect_equal(dominant_species(a, min_share = 0.4)$pure[1], TRUE)
  expect_error(dominant_species(data.frame(a = 1)), "colonnes")
  expect_error(dominant_species(a, min_share = 1.5), "]0, 1]", fixed = TRUE)
})

test_that("read_espar_cdref lit la table essence -> CD_REF (extrait du depot)", {
  d <- read_espar_cdref(system.file("extdata", package = "sylvostation"))
  expect_equal(names(d), c("espar", "lib_espar", "cd_ref", "lib_cdref"))
  expect_equal(nrow(d), 193L)
  expect_equal(d$cd_ref[d$espar == "61"], 79319)
  expect_equal(d$lib_cdref[d$espar == "9"], "Fagus sylvatica")
  expect_identical(sort(unique(d$cd_ref)),
                   read_tree_cd_ref(system.file("extdata", package = "sylvostation")))
  expect_error(read_espar_cdref(tempfile()), "introuvable")
})

test_that("trophic_without_trees : essences retirees par CD_REF, moyenne ph/azote, minimum de taxons", {
  fl <- data.frame(id_placette = c("p", "p", "p", "p", "q"), CD_REF = c(1, 2, 3, 4, 1))
  ind <- data.frame(cd_ref = 1:4, ph = c(9, 3, 4, 5), azote = c(9, 4, 6, 5))
  t1 <- trophic_without_trees(fl, ind, tree_cd_ref = c(1, 99), ids = c("q", "p"), min_taxa = 2)
  expect_equal(t1[2], mean(c(mean(c(3, 4, 5)), mean(c(4, 6, 5)))))   # 4,5, sans l'essence 1
  expect_true(is.na(t1[1]))                                          # q : aucun taxon restant
  expect_equal(attr(t1, "n_taxons_arbres"), 1)       # le CD_REF 99 n'est pas dans les indicateurs
  expect_equal(attr(trophic_without_trees(fl, ind, tree_cd_ref = c(1, 2), ids = "p"), "n_taxons_arbres"), 2)
  expect_equal(trophic_without_trees(fl, ind, numeric(0), "p")[1], mean(c(mean(c(9, 3, 4, 5)),
                                                                          mean(c(9, 4, 6, 5)))))
  expect_error(trophic_without_trees(data.frame(a = 1), ind, 1, "p"), "id_placette")
  expect_error(trophic_without_trees(fl, ind, "x", "p"), "CD_REF")
})

test_that("species_optima : moyenne ph/azote par CD_REF, NA si absent, nom latin ESPAR1 en plus", {
  ec <- read_espar_cdref(system.file("extdata", package = "sylvostation"))
  ind <- data.frame(cd_ref = c(97947, 79319, 79319, 111111), ph = c(5.7, 5.3, 5.5, NA),
                    azote = c(NA, 5.5, NA, NA))
  o <- species_optima(c("09", "61", "64", "03", NA), ind, ec, read_espar_codes())
  expect_equal(o$espar, c("09", "61", "64", "03"))
  expect_equal(o$optimum_tichy[1], 5.7)                      # ph seul
  expect_equal(o$optimum_tichy[2], mean(c(5.4, 5.5)))        # deux lignes du meme CD_REF
  expect_equal(o$n_lignes[2], 2)
  expect_true(is.na(o$optimum_tichy[3]))                     # douglas absent de la table
  expect_true(is.na(o$optimum_tichy[4]))                     # chene sessile : pas de ligne
  expect_equal(o$nom[1], "H\u00eatre")
  expect_equal(o$latin_espar1[1], "Fagus sylvatica")
  expect_false("latin_espar1" %in% names(species_optima("09", ind, ec)))
  expect_error(species_optima("09", ind, data.frame(a = 1)), "read_espar_cdref")
})

# cv fabrique : 4 plis, 3 essences, prediction = observe + decalage par essence
fabrique_controle <- function(decalage_pin = 0, bruit = 0.1) {
  set.seed(5)
  n <- 240
  esp <- rep(c("09", "61", "52"), each = 80)
  moy <- c("09" = 4.4, "61" = 3.9, "52" = 3.1)[esp]
  tr <- data.frame(id_placette = sprintf("p%03d", seq_len(n)), trophic = moy + rnorm(n, sd = 0.5),
                   synthetic = TRUE)
  pli <- rep(1:4, length.out = n)
  pred <- moy + rnorm(n, sd = bruit) + ifelse(esp == "52", decalage_pin, 0)
  cv <- list(predictions = data.frame(observe = tr$trophic, predit = pred, sd = 0, pli = pli),
             plis = pli, block_size = 5000.4)
  dom <- data.frame(id_placette = tr$id_placette, espar = esp, share = 0.9)
  opt <- data.frame(espar = c("09", "61", "52"), nom = c("Hetre", "Sapin", "Pin"),
                    optimum_tichy = c(5.7, 5.4, 2.9))
  list(tr = tr, cv = cv, dom = dom, opt = opt)
}

test_that("essence_control : alerte d'ecart au-dessus du seuil, pas en dessous", {
  f <- fabrique_controle(decalage_pin = 0.8)
  r <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic)
  e <- r$par_essence
  expect_equal(e$ecart[e$espar == "52"], 0.8, tolerance = 0.1)
  expect_true(e$alerte_ecart[e$espar == "52"])
  expect_false(any(e$alerte_ecart[e$espar != "52"]))
  expect_equal(r$global$n_alertes_ecart, 1L)
  expect_equal(r$global$n_pures, 240L)
  expect_identical(r$global$bloc_m, 5000)               # arrondi au metre
  expect_identical(unique(e$bloc_m), 5000)
  expect_match(r$global$statut_seuils, "provisoire")
  f2 <- fabrique_controle(decalage_pin = 0.4)       # sous le seuil de 0,5
  r2 <- essence_control(f2$tr, list(f2$cv), f2$dom, f2$opt, f2$tr$trophic)
  expect_equal(r2$global$n_alertes_ecart, 0L)
  r3 <- essence_control(f2$tr, list(f2$cv), f2$dom, f2$opt, f2$tr$trophic, alerte_ecart = 0.3)
  expect_equal(r3$global$n_alertes_ecart, 1L)         # le seuil est un parametre
})

test_that("essence_control : ordre, amplitude ecrasee, ratio, repere de Tichy", {
  f <- fabrique_controle()
  g <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic)$global
  expect_gt(g$accord_predit, 0.4)
  expect_gt(g$ratio, 0.8)
  expect_false(g$alerte_ordre)
  expect_equal(g$pente_amplitude, 1, tolerance = 0.15)
  # prediction ecrasee vers la moyenne : pente 0,25 sous le seuil de 0,3 -> alerte d'amplitude
  m <- mean(f$tr$trophic)
  f$cv$predictions$predit <- m + 0.25 * (f$cv$predictions$predit - m)
  g2 <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic, alerte_pente = 0.3)$global
  expect_equal(g2$pente_amplitude, 0.25, tolerance = 0.1)
  expect_true(g2$alerte_amplitude)
  # Tichy : information (3 essences : pas de Spearman par essence, n < 4), jamais une alerte
  expect_true(is.na(g2$tichy_essence))
  expect_false("alerte_tichy" %in% names(g2))
  # une prediction sans lien avec l'essence : ratio sous le seuil
  set.seed(2)
  f$cv$predictions$predit <- rnorm(nrow(f$tr))
  g3 <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic)$global
  expect_true(g3$alerte_ordre)
  # trop peu de placettes pures pour juger : pas d'alerte d'ordre
  g4 <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic, min_placettes = 500L)$global
  expect_true(is.na(g4$alerte_ordre))
})

test_that("essence_control n'accepte que des predictions hors pli alignees sur train", {
  f <- fabrique_controle()
  expect_error(essence_control(f$tr, list(lm(trophic ~ 1, f$tr)), f$dom, f$opt, f$tr$trophic),
               "spatial_cv")
  autre <- f$cv
  autre$predictions$observe <- autre$predictions$observe + 1
  expect_error(essence_control(f$tr, list(autre), f$dom, f$opt, f$tr$trophic), "align")
  expect_error(essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic[-1]), "longueur")
  # liste par gradient (forme de cv_sensibilite apres 035) : l'element trophic est lu
  expect_equal(essence_control(f$tr, list(list(trophic = f$cv, hydric = NULL)), f$dom, f$opt,
                               f$tr$trophic)$global$n_pures, 240L)
})

test_that("essence_control : une validation absente est ignoree avec un avertissement", {
  f <- fabrique_controle(decalage_pin = 0.8)
  expect_warning(r <- essence_control(f$tr, list(f$cv, NULL), f$dom, f$opt, f$tr$trophic),
                 "1 validation.*absente.*sur 2")
  expect_equal(nrow(r$global), 1L)                 # la taille de blocs presente est calculee seule
  expect_equal(r$global$n_alertes_ecart, 1L)
  # liste par gradient dont l'element trophic est NULL (cv_sensibilite apres 035)
  expect_warning(r2 <- essence_control(f$tr, list(f$cv, list(trophic = NULL, hydric = NULL)),
                                       f$dom, f$opt, f$tr$trophic), "absente")
  expect_equal(nrow(r2$global), 1L)
  expect_error(suppressWarnings(essence_control(f$tr, list(NULL), f$dom, f$opt, f$tr$trophic)),
               "Aucune validation")
  expect_no_warning(essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic))
})

fabrique_sf <- function(n = 240, effet = 1.2, seed = 3) {
  set.seed(seed)
  esp <- rep(c("09", "61", "52", "62"), length.out = n)
  d <- sf::st_as_sf(data.frame(id_placette = sprintf("p%03d", seq_len(n)),
    x = runif(n, 1000000, 1060000), y = runif(n, 6800000, 6860000), loc_precision_m = 700,
    coarse_a = rnorm(n), synthetic = TRUE), coords = c("x", "y"), crs = 2154, remove = FALSE)
  e <- c("09" = 1, "61" = -1, "52" = -2, "62" = 0.5)[esp]
  d$trophic <- 1.5 * d$coarse_a + effet * e + rnorm(n, sd = 0.3)
  list(d = d, dom = data.frame(id_placette = d$id_placette, espar = esp, share = 0.9))
}

test_that("essence_sensitivity : gain de R2 avec une vraie essence, pas avec une essence au hasard", {
  skip_if_not_installed("ranger")
  f <- fabrique_sf()
  s <- essence_sensitivity(f$d, "coarse_a", NULL, f$dom, block_sizes = c(20000, 10000),
                           min_placettes = 10, num_trees = 60, folds = 3L)
  expect_equal(sort(unique(s$resume$variante)), c("base", "fine", "placebo", "tfv"))
  expect_equal(sort(unique(s$resume$bloc_m)), c(10000, 20000))
  base <- s$resume[s$resume$variante == "base", ]
  fin <- s$resume[s$resume$variante == "fine", ]
  expect_true(all(fin$gain_r2 > 0.2))
  pla <- s$resume[s$resume$variante == "placebo", ]
  expect_true(all(pla$gain_r2 < fin$gain_r2 - 0.15))      # le placebo ne gagne pas autant
  expect_equal(fin$gain_r2, fin$r2 - base$r2[match(fin$bloc_m, base$bloc_m)])
  expect_true(all(s$resume$avertissement == "sensibilite : essence en place ; ne pas lire comme la carte (ADR 0008)"))
  expect_true(all(c("pli", "gain_r2") %in% names(s$par_pli)))
  expect_equal(nrow(s$par_pli), 2L * 3L * 3L)             # 2 blocs x 3 variantes x 3 plis
  expect_true(all(c("09", "61", "52", "62") %in% s$niveaux$niveau[s$niveaux$variante == "fine"]))
  # essence sans lien avec la reponse : gain proche de zero
  alea <- f$dom
  set.seed(9)
  alea$espar <- sample(alea$espar)
  s2 <- essence_sensitivity(f$d, "coarse_a", NULL, alea, block_sizes = 20000, min_placettes = 10,
                            num_trees = 60, folds = 3L)
  expect_lt(max(s2$resume$gain_r2), 0.15)
})

test_that("essence_sensitivity : une taille de blocs impossible est omise avec avertissement", {
  skip_if_not_installed("ranger")
  f <- fabrique_sf(120)
  # des blocs de 500 km : un seul bloc, impossible de faire des plis
  expect_warning(s <- essence_sensitivity(f$d, "coarse_a", NULL, f$dom,
                                          block_sizes = c(500000, 20000.4), min_placettes = 10,
                                          num_trees = 30, folds = 3L),
                 "taille de blocs 500000 m omise")
  expect_identical(unique(s$resume$bloc_m), 20000)       # arrondi au metre, seule taille gardee
  expect_error(suppressWarnings(essence_sensitivity(f$d, "coarse_a", NULL, f$dom,
                                                    block_sizes = 500000, min_placettes = 10,
                                                    num_trees = 30, folds = 3L)),
               "Aucune taille")
})

test_that("essence_sensitivity : regle des 700 m et entrees", {
  f <- fabrique_sf(60)
  f$d$pente <- 1
  # la regle des 700 m s'applique : une variable fine est refusee (pas avalee par l'omission de bloc)
  expect_error(suppressWarnings(essence_sensitivity(f$d, c("coarse_a", "pente"), NULL, f$dom,
                                                    block_sizes = 10000, num_trees = 20, folds = 3L)),
               "Aucune taille|700|IFN|fine|maille")
  expect_error(essence_sensitivity(f$d, "coarse_a", NULL, f$dom, block_sizes = -1), "blocs")
  expect_error(essence_sensitivity(data.frame(a = 1), "coarse_a", NULL, f$dom, block_sizes = 1),
               "sf")
})

test_that("essence_tables : le controle est publie meme sans la sensibilite, et inversement", {
  ctl <- list(global = data.frame(pente_amplitude = 0.3, bloc_m = 1), par_essence = data.frame(a = 1))
  sens <- list(resume = data.frame(bloc_m = 1, variante = "base", r2 = 0.2, rmse = 1, gain_r2 = 0,
                                   gain_rmse = 0, avertissement = "x"),
               par_pli = data.frame(bloc_m = 1, variante = "tfv", pli = 1L, n = 10L, r2 = 0.2,
                                    gain_r2 = 0.05, avertissement = "x"))
  expect_equal(names(essence_tables(ctl, NULL)), c("controle_essence", "controle_essence_par_essence"))
  expect_equal(names(essence_tables(NULL, sens)), "sensibilite_essence")
  expect_equal(length(essence_tables(NULL, NULL)), 0L)
})

test_that("essence_tables : trois tables, defaut d'amplitude en tete, mention de sensibilite", {
  skip_if_not_installed("ranger")
  f <- fabrique_controle()
  ctl <- essence_control(f$tr, list(f$cv), f$dom, f$opt, f$tr$trophic)
  g <- fabrique_sf(120)
  s <- essence_sensitivity(g$d, "coarse_a", NULL, g$dom, block_sizes = 20000, min_placettes = 10,
                           num_trees = 30, folds = 3L)
  t <- essence_tables(ctl, s)
  expect_equal(names(t), c("controle_essence", "controle_essence_par_essence", "sensibilite_essence"))
  expect_equal(names(t$controle_essence)[1:3], c("bloc_m", "pente_amplitude", "alerte_amplitude"))
  expect_true(all(vapply(t, is.data.frame, logical(1))))
  expect_equal(nrow(t$sensibilite_essence), nrow(s$resume) + nrow(s$par_pli))
  expect_true(all(grepl("ne pas lire comme la carte", t$sensibilite_essence$avertissement)))
})

test_that("bdforet_class_means : moyenne par classe pure a l'interieur des polygones", {
  carre <- function(x0, y0, l) sf::st_polygon(list(rbind(c(x0, y0), c(x0 + l, y0), c(x0 + l, y0 + l),
                                                         c(x0, y0 + l), c(x0, y0))))
  p <- sf::st_sf(code_tfv = c("FF1-09-09", "FF31", "FF2G61-61"),
                 geometry = sf::st_sfc(carre(1000000, 6800000, 400), carre(1000500, 6800000, 400),
                                       carre(1001000, 6800000, 400), crs = 2154))
  r <- terra::rast(xmin = 1000000, xmax = 1001400, ymin = 6800000, ymax = 6800400, resolution = 20,
                   crs = "EPSG:2154")
  r <- (terra::init(r, "x") - 1000000) / 100   # valeur = abscisse du centre de cellule, en hm
  m <- bdforet_class_means(p, r, buffer_m = 45, min_polygones = 1)
  expect_equal(m$classe, c("Hêtre", "Sapin ou épicéa"))   # FF31 (mixte) ignore
  # tampon de 45 m (pas de centre de cellule sur le bord) : centres de 50 a 350 -> moyenne 200 -> 2,0 ;
  # sapin : 1050 a 1350 -> 12,0
  expect_equal(m$moyenne_carte, c(2, 12), tolerance = 1e-9)
  expect_equal(m$n_polygones, c(1L, 1L))
  expect_equal(m$n_cellules, c(256L, 256L))     # 16 x 16 cellules de 20 m
  expect_true(all(m$suffisant))
  expect_false(any(bdforet_class_means(p, r, 45, min_polygones = 2)$suffisant))
  expect_equal(nrow(bdforet_class_means(p, r, buffer_m = 250, min_polygones = 1)), 0L)  # tout disparait
  expect_false(any(c("geometry", "geom") %in% names(m)))                                 # aucune geometrie
  p4326 <- sf::st_transform(p, 4326)
  expect_error(bdforet_class_means(p4326, r), "2154")
  expect_error(bdforet_class_means(data.frame(a = 1), r), "code_tfv")
})

cfg_essence <- function(modif = list()) {
  cfg <- list(ser_code = "D11",
              emprise_test = list(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000,
                                  crs = 2154),
              buffer_m = 5000, resolution_m = 20, crs = 2154, data_dir = "data",
              laz_dir = "data/laz", out_dir = "data/sorties", ifn_precision_m = 700)
  f <- tempfile(fileext = ".yml")
  yaml::write_yaml(utils::modifyList(cfg, modif), f)
  f
}

test_that("config : seuils du controle par essence (provisoires), option BD Foret desactivee", {
  cfg <- read_config(cfg_essence())
  expect_equal(cfg$essence_part_pure, 0.75)
  expect_equal(cfg$essence_min_placettes, 15L)
  expect_equal(cfg$essence_alerte_ecart, 0.5)
  expect_equal(cfg$essence_alerte_ratio, 0.5)
  expect_equal(cfg$essence_alerte_pente, 0.2)
  expect_false(cfg$bdforet_controle)
  expect_equal(cfg$bdforet_tampon_m, 50)
  expect_equal(read_config(cfg_essence(list(essence_alerte_ecart = 0.8)))$essence_alerte_ecart, 0.8)
  expect_error(read_config(cfg_essence(list(essence_part_pure = 0.4))), "essence_part_pure")
  expect_error(read_config(cfg_essence(list(essence_alerte_ecart = -1))), "essence_alerte_ecart")
  expect_error(read_config(cfg_essence(list(bdforet_controle = "oui"))), "bdforet_controle")
  expect_error(read_config(cfg_essence(list(essence_min_placettes = 0))), "essence_min_placettes")
  f <- testthat::test_path("..", "..", "config.yml")
  skip_if_not(file.exists(f), "config.yml absent du paquet installe")
  y <- read_config(f)
  expect_false(y$bdforet_controle)          # desactivee par defaut dans le depot
  expect_match(paste(readLines(f, encoding = "UTF-8"), collapse = "\n"),
               "valeur provisoire, sans source", fixed = TRUE)
})

test_that("ADR 0008 : l'essence n'entre dans aucune cible de la carte, des types ni des modeles", {
  f <- testthat::test_path("..", "..", "_targets.R")
  skip_if_not(file.exists(f), "_targets.R absent du paquet installe")
  l <- readLines(f, encoding = "UTF-8")
  debuts <- grep("^\\s*tar_target\\(", l)
  nom <- sub("^\\s*tar_target\\(([A-Za-z_0-9.]+).*$", "\\1", l[debuts])
  fin <- c(debuts[-1] - 1L, length(l))
  bloc <- function(n) paste(unlist(Map(function(a, b) l[a:b], debuts[nom == n], fin[nom == n])),
                            collapse = "\n")
  cibles <- c("train_climat", "trophic_enc", "train", "vars_modele", "models", "cvs", "maps",
              "gradient_map", "uncertainty", "type_map", "cell_types", "merged", "thresholds",
              "maps_regional", "local_map", "local_trophic", "comparaison_locale", "vars_fines")
  present <- intersect(cibles, nom)
  skip_if(length(present) < 5L, "cibles reelles absentes de _targets.R")
  motif <- paste0("essence_dominante|coarse_essence|cv_essence|controle_essence|essence_sensitivity|",
                  "dominant_species|espar_cdref|arbres_cd_ref|espar_codes|(?<![$.A-Za-z_])ifn_dir")
  for (n in present) expect_false(grepl(motif, bloc(n), perl = TRUE), info = n)
  expect_false("essence" %in% unlist(strsplit(bloc("vars_modele"), "[^A-Za-z_]")))
})

test_that("fetch_bdforet : lit le cache (JSON synthetique) sans reseau, pages et colonnes", {
  d <- file.path(tempdir(), "bdforet_cache_synth")
  dir.create(d, showWarnings = FALSE)
  carre <- function(x0) sf::st_polygon(list(rbind(c(x0, 6800000), c(x0 + 400, 6800000),
                         c(x0 + 400, 6800400), c(x0, 6800400), c(x0, 6800000))))
  x <- sf::st_sf(code_tfv = c("FF1-09-09", "FF2G61-61"), tfv = c("Foret de hetre", "Foret de sapin"),
                 essence = c("H\u00eatre", "Sapin, \u00e9pic\u00e9a"), synthetic = TRUE,
                 geometry = sf::st_sfc(carre(1000000), carre(1000500), crs = 2154))
  bb <- sf::st_bbox(c(xmin = 1000000, ymin = 6800000, xmax = 1001000, ymax = 6800400), crs = 2154)
  f <- file.path(d, sprintf("bdforet_%s_%d.json", paste(format(round(as.numeric(bb)), scientific = FALSE, trim = TRUE), collapse = "_"), 0L))
  sf::st_write(x, f, driver = "GeoJSON", quiet = TRUE)
  old <- options(sylvostation.downloader = function(...) stop("reseau interdit dans ce test"),
                 sylvostation.download_retries = 1L, sylvostation.sleeper = function(...) NULL)
  on.exit(options(old), add = TRUE)
  r <- fetch_bdforet(bb, d)                      # tout vient du cache : aucun telechargement
  expect_s3_class(r, "sf")
  expect_equal(sf::st_crs(r)$epsg, 2154L)
  expect_equal(names(r)[1:3], c("code_tfv", "tfv", "essence"))
  expect_false("synthetic" %in% names(r))
  expect_equal(nrow(r), 2L)
  expect_equal(r$code_tfv, c("FF1-09-09", "FF2G61-61"))
  # un point connu : le centre du premier polygone tombe dans la classe hetre
  pt <- sf::st_sfc(sf::st_point(c(1000200, 6800200)), crs = 2154)
  expect_equal(r$code_tfv[sf::st_intersects(pt, r)[[1]]], "FF1-09-09")
  # sans cache, le telechargement est tente (et ici refuse) : l'erreur vient du telechargeur
  expect_error(fetch_bdforet(bb, file.path(d, "vide")), "reseau interdit|T\u00e9l\u00e9chargement|echec|\u00e9chec")
  expect_error(fetch_bdforet(sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 1, ymax = 1), crs = 2154), d))
})
