test_that("indicator_species retrouve les espèces indicatrices connues", {
  s <- synth_typologie()
  r <- indicator_species(s$flore, s$grp, nperm = 49)
  top <- r[r$indval > 0.6, ]
  expect_equal(sort(top$species[top$type == "a"]), paste0("sp", 1:3))
  expect_equal(sort(top$species[top$type == "b"]), paste0("sp", 4:6))
  expect_equal(sort(top$species[top$type == "c"]), paste0("sp", 7:9))
  expect_true(all(r$p_value[r$indval > 0.6] <= 0.05))
  expect_true(all(r$A <= 1 & r$B <= 1 & r$indval >= 0))
})

test_that("indicator_species coïncide avec indicspecies::multipatt (IndVal.g)", {
  skip_if_not_installed("indicspecies")
  skip_if_not_installed("permute")
  s <- synth_typologie(n = 150)
  r <- indicator_species(s$flore, s$grp, nperm = 0)
  mp <- suppressMessages(indicspecies::multipatt(
    as.data.frame(s$flore), s$grp, func = "IndVal.g", duleg = TRUE,
    control = permute::how(nperm = 0)))
  ref <- mp$sign
  r <- r[match(rownames(ref), r$species), ]
  expect_equal(r$indval, ref$stat, tolerance = 1e-8)
  expect_equal(r$type, c("a", "b", "c")[ref$index])
})

test_that("indicator_species valide ses entrées", {
  expect_error(indicator_species(matrix(1, 3, 2), c("a", "b")), "relev")
  expect_error(indicator_species(matrix(1, 3, 2), c("a", "a", "a")), "deux types")
  expect_error(indicator_species(matrix(-1, 3, 2), c("a", "a", "b")), "sans NA")
})

test_that("fertility_by_type retrouve les écarts entre types", {
  s <- synth_typologie()
  f <- fertility_by_type(s$arbres, s$plot_types)
  expect_true(attr(f, "provisoire"))
  expect_equal(f$type, c("a", "b", "c"))
  expect_equal(f$n_plots, c(20, 20, 20))
  expect_true(all(f$age_ref == 50))
  m <- stats::setNames(f$fertilite_moy, f$type)
  expect_gt(m[["a"]], m[["b"]])
  expect_gt(m[["b"]], m[["c"]])
  expect_equal(m[["a"]] - m[["c"]], 6, tolerance = 0.15)
  # niveau absolu du type b (effet 0) : 8 ln(50) - 10
  expect_equal(m[["b"]], 8 * log(50) - 10, tolerance = 0.1)
})

test_that("fertility_by_type : âge de référence par essence, peu de placettes, colonnes", {
  s <- synth_typologie()
  f <- fertility_by_type(s$arbres, s$plot_types, age_ref = c(chene = 80))
  expect_true(all(f$age_ref == 80))
  v <- fertility_by_type(s$arbres[s$arbres$plot <= 5, ], s$plot_types)
  expect_equal(nrow(v), 0)
  a2 <- s$arbres
  names(a2)[1:2] <- c("id", "ess")
  tv <- stats::setNames(s$plot_types$type, s$plot_types$plot)
  f2 <- fertility_by_type(a2, tv, cols = c(plot = "id", species = "ess",
                                           height = "height", age = "age"))
  f1 <- fertility_by_type(s$arbres, s$plot_types)
  expect_equal(f2$fertilite_moy, f1$fertilite_moy)
  expect_error(fertility_by_type(s$arbres, s$plot_types, cols = c(plot = "zz")), "cols")
})

test_that("fertility_by_type : essence absente de age_ref -> NA et avertissement", {
  s <- synth_typologie()
  a2 <- rbind(s$arbres, transform(s$arbres, species = "hetre"))
  expect_warning(
    f <- fertility_by_type(a2, s$plot_types, age_ref = c(chene = 50)),
    "hetre")
  expect_true(all(f$species == "chene"))
  expect_equal(nrow(f), 3)
  pl <- attr(f, "plots")
  expect_true(all(is.na(pl$fertilite[pl$species == "hetre"])))
  expect_true(all(is.na(pl$age_ref[pl$species == "hetre"])))
})
