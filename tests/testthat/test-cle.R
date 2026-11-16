test_that("build_key classe bien une typologie liée aux observables", {
  skip_if_not_installed("rpart")
  set.seed(2)
  d <- data.frame(pente = c(rep(5, 40), rep(25, 40), rep(25, 40)) + rnorm(120),
                  humus = factor(c(rep("mull", 80), rep("moder", 40))))
  d$type <- rep(c("A", "B", "C"), each = 40)
  k <- build_key(d, c("pente", "humus"), maxdepth = 3)
  expect_s3_class(k, "sylvo_key")
  expect_gte(k$accuracy, 0.99)
  expect_gte(k$accuracy_cv, 0.9)
  expect_true(k$meets_target)
  expect_equal(nrow(k$merge_suggestions), 0)
  expect_lte(k$depth, 3)
  expect_true(k$provisoire)
  out <- capture.output(print(k))
  expect_true(any(grepl("pente", out)))
  expect_true(any(grepl("-> B", out, fixed = TRUE)))
})

test_that("build_key respecte maxdepth", {
  skip_if_not_installed("rpart")
  s <- synth_typologie()
  d <- cbind(s$observables, type = s$grp)
  for (p in 1:3) expect_lte(build_key(d, c("pente", "humus"), maxdepth = p)$depth, p)
})

test_that("build_key sous 70 % : suggère de fusionner les types confondus", {
  skip_if_not_installed("rpart")
  set.seed(3)
  n <- 300
  d <- data.frame(x = rnorm(n), z = rnorm(n))
  # A et B indiscernables (même loi), C discernable par x
  d$type <- ifelse(d$x > 1, "C", sample(c("A", "B"), n, TRUE))
  k <- build_key(d, c("x", "z"))
  expect_false(k$meets_target)
  expect_lt(k$accuracy_cv, 0.7)
  sg <- k$merge_suggestions
  expect_gte(nrow(sg), 1)
  expect_setequal(c(sg$type_a[1], sg$type_b[1]), c("A", "B"))
  expect_gte(utils::tail(sg$taux_apres, 1), 0.7)
  expect_match(paste(capture.output(print(k)), collapse = "\n"), "NON atteinte")
})

test_that("build_key valide ses entrées", {
  skip_if_not_installed("rpart")
  d <- data.frame(x = 1:10, type = rep(c("A", "B"), 5))
  expect_error(build_key(d, "zzz"), "observables")
  expect_error(build_key(d, "x", type = "nope"), "introuvable")
  expect_error(build_key(d, c("x", "type")), "observables")
  expect_error(build_key(d, "x", maxdepth = 0), "maxdepth")
  expect_error(build_key(data.frame(x = 1:4, type = "A"), "x"), "deux types")
})

test_that("chaîne complète sur données synthétiques : discretise, merge_rare, clé", {
  skip_if_not_installed("rpart")
  s <- synth_typologie()
  t <- merge_rare(discretise(s$gradients), area_min = 0.05, n_min = 15)
  expect_true(attr(t, "provisoire"))
  d <- cbind(s$observables, type = t$type)
  k <- build_key(d, c("pente", "humus"))
  expect_gt(k$accuracy, 0.5)
})
