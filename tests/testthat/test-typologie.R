test_that("default_thresholds renvoie des seuils provisoires par quantiles", {
  s <- synth_typologie()
  th <- default_thresholds(s$gradients)
  expect_true(isTRUE(attr(th, "provisoire")))
  expect_equal(lengths(th), c(trophic = 3L, hydric = 2L, bioclim = 1L))
  expect_equal(unname(th$bioclim), unname(stats::median(s$gradients$bioclim)))
  expect_error(default_thresholds(s$gradients, c(zzz = 3)), "absents")
})

test_that("discretise : classes aux seuils, seuil = classe supérieure, NA propagé", {
  g <- data.frame(trophic = c(0, 1, 1.0001, 5, NA), hydric = c(0, 0, 0, 0, 0))
  d <- discretise(g, list(trophic = c(1, 2), hydric = 5))
  expect_equal(d$trophic_cl, c(1L, 2L, 2L, 3L, NA))
  expect_equal(d$hydric_cl, rep(1L, 5))
  expect_equal(d$type, c("T1-H1", "T2-H1", "T2-H1", "T3-H1", NA))
  expect_false(attr(d, "provisoire"))
  expect_error(discretise(g, list(trophic = c(2, 1))), "croissants")
  expect_error(discretise(g, list(zzz = 1)), "absents")
})

test_that("discretise avec seuils par défaut est marquée provisoire et synthétique", {
  s <- synth_typologie()
  d <- discretise(s$gradients)
  expect_true(attr(d, "provisoire"))
  expect_true(attr(d, "synthetic"))
  expect_equal(nrow(d), nrow(s$gradients))
  expect_lte(length(unique(d$type)), 4 * 3 * 2)
})

test_that("merge_rare fusionne avec le voisin le plus proche et trace", {
  # T1-H1 (45), T2-H1 (45), T3-H1 (9), T1-H3 (1 cellule, rare)
  cl <- data.frame(trophic_cl = c(rep(1L, 45), rep(2L, 45), rep(3L, 9), 1L),
                   hydric_cl = c(rep(1L, 99), 3L))
  cl$type <- paste0("T", cl$trophic_cl, "-H", cl$hydric_cl)
  m <- merge_rare(cl, area_min = 0.05, n_min = 0)
  mg <- attr(m, "merges")
  expect_equal(nrow(mg), 1)
  expect_equal(mg$de, "T1-H3")
  expect_equal(mg$vers, "T1-H1")          # distance 2 contre sqrt(5), sqrt(8)
  expect_equal(mg$distance, 2)
  expect_equal(mg$motif, "surface")
  expect_equal(sum(m$type == "T1-H1"), 46)
  expect_equal(m$type_initial, cl$type)
  expect_true(attr(m, "provisoire"))
})

test_that("merge_rare : l'effectif des placettes déclenche la fusion", {
  cl <- data.frame(trophic_cl = rep(1:3, each = 50), hydric_cl = 1L)
  cl$type <- paste0("T", cl$trophic_cl, "-H1")
  plots <- c(rep("T1-H1", 20), rep("T2-H1", 20), rep("T3-H1", 3))
  m <- merge_rare(cl, area_min = 0.01, n_min = 15, plots = plots)
  mg <- attr(m, "merges")
  expect_equal(mg$de, "T3-H1")
  expect_equal(mg$vers, "T2-H1")
  expect_equal(mg$motif, "placettes")
  expect_true(all(attr(m, "plots")[41:43] == "T2-H1"))
  # rien ne tient : un seul type restant, pas de boucle infinie
  m2 <- merge_rare(cl, area_min = 0, n_min = 1000)
  expect_equal(length(unique(m2$type)), 1)
  expect_error(merge_rare(data.frame(a = 1)), "type")
})

test_that("merge_rare sans type rare ne change rien", {
  s <- synth_typologie()
  d <- discretise(s$gradients)
  m <- merge_rare(d, area_min = 0, n_min = 0)
  expect_equal(nrow(attr(m, "merges")), 0)
  expect_equal(m$type, d$type)
})

test_that("cluster_check retrouve 3 groupes nets et compare à la typologie", {
  s <- synth_typologie(n = 240)
  r <- cluster_check(s$gradients[, c("trophic", "hydric", "bioclim")], k = 2:6,
                     types = s$grp)
  expect_equal(r$k_best, 3L)
  expect_gt(r$ari, 0.9)
  expect_equal(nrow(r$silhouette), 5)
  expect_equal(length(r$clusters), 240)
  r2 <- cluster_check(s$gradients[, 1:3], k = 3, max_n = 100)
  expect_equal(length(r2$rows), 100)
})

test_that("indice de Rand ajusté : valeurs connues", {
  expect_equal(sylvostation:::.adjusted_rand(c(1, 1, 2, 2), c("a", "a", "b", "b")), 1)
  expect_equal(sylvostation:::.adjusted_rand(c(1, 1, 2, 2), c(1, 2, 1, 2)), -0.5)
})
