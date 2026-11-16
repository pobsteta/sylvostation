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
