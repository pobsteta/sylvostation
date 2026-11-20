# Jeux synthétiques : vérités calculées à la main.

cv_factice <- function(obs, pred, r2 = NULL) {
  r <- if (is.null(r2)) 1 - sum((obs - pred)^2) / sum((obs - mean(obs))^2) else r2
  list(global = c(r2 = r, rmse = sqrt(mean((obs - pred)^2))),
       predictions = data.frame(observe = obs, predit = pred, sd = 1, pli = 1),
       block_size = 1000, k = 2)
}

test_that("validate_stats : R2, RMSE et repères du brief (0,36 / 0,52 / 0,43)", {
  obs <- c(1, 2, 3, 4)
  cvs <- list(trophic = cv_factice(obs, c(1, 2, 3, 5)),     # R2 = 1 - 1/5 = 0,8
              bioclim = cv_factice(obs, c(2, 2, 3, 3)),     # SCR = 2, R2 = 0,6
              hydric = cv_factice(obs, rep(2.5, 4)),        # R2 = 0
              autre = cv_factice(obs, obs))
  v <- validate_stats(cvs, synthetic = TRUE)
  expect_equal(v$gradient, c("trophic", "bioclim", "hydric", "autre"))
  expect_equal(v$r2, c(0.8, 0.6, 0, 1))
  expect_equal(v$rmse[1], sqrt(1 / 4))
  expect_equal(v$r2_repere, c(0.36, 0.52, 0.43, NA))
  expect_equal(v$atteint, c(TRUE, TRUE, FALSE, NA))
  expect_equal(v$ecart_r2[1], 0.8 - 0.36)
  expect_true(all(v$synthetic))
  expect_true(attr(v, "synthetic"))
  expect_false(any(validate_stats(cvs)$synthetic))
})

test_that("validate_stats : entrées invalides", {
  expect_error(validate_stats(list(cv_factice(1:3, 1:3))), "nomm")
  expect_error(validate_stats(list(a = 1)), "spatial_cv")
  expect_error(validate_stats(NULL), "nomm")
})

test_that("validate_stats lit un vrai résultat de spatial_cv()", {
  skip_if_not_installed("mgcv")
  s <- synth_modeles(n = 120)
  cv <- spatial_cv(s$points, "gradient", "coarse_climat", method = "gam", block_size = 4000)
  v <- validate_stats(list(trophic = cv), synthetic = TRUE)
  expect_equal(v$r2, cv$global[["r2"]])
  expect_equal(v$n, 120)
})

test_that("validate_maps : confusion, kappa, accords exact et à une classe près", {
  # observé : 1 1 1 1 2 2 2 2 ; prédit : 1 1 1 2 2 2 2 1 -> po = 6/8
  # kappa = (0,75 - 0,5) / (1 - 0,5) = 0,5
  obs <- c(rep("T1", 4), rep("T2", 4))
  prd <- c("T1", "T1", "T1", "T2", "T2", "T2", "T2", "T1")
  v <- validate_maps(prd, obs)
  expect_equal(unname(v$confusion["T1", "T1"]), 3)
  expect_equal(unname(v$confusion["T1", "T2"]), 1)
  expect_equal(unname(v$confusion["T2", "T1"]), 1)
  expect_equal(v$kappa, 0.5)
  expect_equal(v$accord_exact, 0.75)
  expect_equal(v$n, 8)
  expect_equal(v$n_ecartes, 0)
})

test_that("validate_maps : accord à une classe près, par axe, codes à trois chiffres", {
  obs <- c("412", "321", "654", "111")
  prd <- c("412", "422", "644", "333")
  v <- validate_maps(prd, obs)
  expect_equal(v$accord_exact, 0.25)
  # écarts par axe : (0,0,0) (1,0,1) (0,1,0) (2,2,2) -> tous à <= 1 : 3 lignes sur 4
  expect_equal(v$accord_une_classe, 0.75)
  expect_equal(nrow(v$par_axe), 3)
  expect_equal(v$par_axe$accord_exact, c(0.5, 0.5, 0.5))
  expect_equal(v$par_axe$accord_une_classe, c(0.75, 0.75, 0.75))
  # types nommés « T2-H1-B1 » : nombres successifs
  v2 <- validate_maps(c("T2-H1-B1", "T3-H1-B2"), c("T2-H1-B1", "T1-H1-B2"))
  expect_equal(v2$accord_exact, 0.5)
  expect_equal(v2$accord_une_classe, 0.5)
  # types non numériques : pas d'accord à une classe près
  expect_true(is.na(validate_maps(c("a", "b"), c("a", "a"))$accord_une_classe))
})

test_that("validate_maps : NA écartés et erreurs", {
  v <- validate_maps(c("T1", NA, "T2"), c("T1", "T1", "T2"))
  expect_equal(v$n, 2)
  expect_equal(v$n_ecartes, 1)
  expect_error(validate_maps("a", c("a", "b")), "longueur")
  expect_error(validate_maps(NA_character_, "a"), "comparable")
})

# --- blocs occupes et alerte (mission 035) ------------------------------------------------
cv_blocs <- function(n_blocs, k = 5L, r2 = 0.3, bs = 1000) {
  list(global = c(r2 = r2, rmse = 1), predictions = data.frame(observe = 1:10, predit = 1:10),
       block_size = bs, k = k, n_blocs = n_blocs)
}

test_that("spatial_cv rend le nombre de blocs occupes (jeu synthetique, blocs connus)", {
  skip_if_not_installed("mgcv")
  set.seed(2)
  # 4 x 3 = 12 blocs de 1 000 m (x = est, y = nord), 10 points par bloc
  d <- data.frame(x = rep(1000000 + 1000 * rep(0:3, each = 3) + 500, each = 10),
                  y = rep(6800000 + 1000 * rep(0:2, times = 4) + 500, each = 10),
                  loc_precision_m = 10)
  d$x <- d$x + runif(nrow(d), -400, 400)
  d$y <- d$y + runif(nrow(d), -400, 400)
  d$a <- rnorm(nrow(d))
  d$g <- d$a + rnorm(nrow(d), sd = 0.3)
  cv <- spatial_cv(d, "g", "a", method = "gam", block_size = 1000, k = 3)
  expect_equal(cv$n_blocs, 12L)
  # plis fournis par l'utilisateur : nombre de blocs non defini
  cv2 <- spatial_cv(d, "g", "a", method = "gam", block_size = 1000, folds = rep(1:3, length.out = nrow(d)))
  expect_true(is.na(cv2$n_blocs))
})

test_that("validate_stats : alerte blocs_insuffisants sous 4 blocs par pli, texte en clair", {
  v <- validate_stats(list(hydric = cv_blocs(8L), trophic = cv_blocs(37L), bioclim = cv_blocs(20L)))
  expect_equal(v$blocs, c(8L, 37L, 20L))
  expect_equal(v$k, c(5L, 5L, 5L))
  expect_equal(v$blocs_insuffisants, c(TRUE, FALSE, FALSE))   # seuil 4 x 5 = 20 : 20 suffit
  expect_equal(v$alerte[1], "R² peu interprétable : 8 blocs pour 5 plis ; voir la ligne de sensibilité")
  expect_equal(v$alerte[2:3], c("", ""))
  # seuil reglable
  expect_false(validate_stats(list(hydric = cv_blocs(8L)), min_blocs_par_pli = 1)$blocs_insuffisants)
  expect_true(validate_stats(list(hydric = cv_blocs(37L)), min_blocs_par_pli = 8)$blocs_insuffisants)
  # blocs inconnus (plis fournis) : pas d'alerte inventee
  u <- validate_stats(list(trophic = cv_blocs(NA_integer_)))
  expect_true(is.na(u$blocs_insuffisants))
  expect_equal(u$alerte, "")
  expect_error(validate_stats(list(a = cv_blocs(8L)), min_blocs_par_pli = -1), "min_blocs_par_pli")
  expect_error(validate_stats(list(a = cv_blocs(8L)), min_blocs_par_pli = "a"), "min_blocs_par_pli")
})

test_that("validation_table : sensibilite par gradient, NULL omis, ligne locale, alerte par ligne", {
  cvs <- list(trophic = cv_blocs(37L, r2 = 0.19, bs = 22000), hydric = cv_blocs(8L, r2 = 0.28, bs = 76000))
  sens <- list(trophic = cv_blocs(163L, r2 = 0.27, bs = 8358),
               hydric = cv_blocs(162L, r2 = 0.36, bs = 8358))
  v <- validation_table(cvs, sens, local = cv_blocs(30L, r2 = 0.1))
  expect_equal(v$gradient, c("trophic", "hydric", "trophic (sensibilité : blocs de taille fixe)",
                             "hydric (sensibilité : blocs de taille fixe)",
                             "trophic (local, ancrages GBIF)"))
  expect_equal(v$block_size, c(22000, 76000, 8358, 8358, 1000))
  expect_equal(v$blocs_insuffisants, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_match(v$alerte[2], "8 blocs pour 5 plis")
  # sensibilite manquante pour un gradient : ligne omise ; sans sensibilite ni local : seulement cvs
  v2 <- validation_table(cvs, list(trophic = NULL, hydric = sens$hydric))
  expect_equal(nrow(v2), 3)
  expect_false(any(grepl("trophic \\(sensib", v2$gradient)))
  expect_equal(nrow(validation_table(cvs)), 2)
  # donnees synthetiques : balise reprise
  expect_true(all(validation_table(cvs, sens, synthetic = TRUE)$synthetic))
})
