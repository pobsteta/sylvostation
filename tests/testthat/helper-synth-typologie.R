# Jeu synthétique (synthetic = TRUE) pour la mission 009. Aucun résultat sur données
# réelles. Trois gradients (trophic, hydric, bioclim) avec 3 noyaux nets, des observables
# liés aux gradients avec bruit, une flore à espèces indicatrices connues
# (sp1-sp3 -> groupe a, sp4-sp6 -> b, sp7-sp9 -> c) et des arbres à fertilité connue
# (+3 m dans le groupe a, -3 m dans le groupe c).
synth_typologie <- function(n = 450, seed = 7) {
  has_seed <- exists(".Random.seed", envir = globalenv())
  old <- if (has_seed) get(".Random.seed", envir = globalenv())
  on.exit(if (has_seed) assign(".Random.seed", old, envir = globalenv()))
  set.seed(seed)
  grp <- rep(c("a", "b", "c"), length.out = n)
  centre <- list(a = c(2, -1, 0), b = c(0, 1.5, 1), c = c(-2, 0, -1))
  g <- t(vapply(grp, function(k) centre[[k]] + stats::rnorm(3, sd = 0.45), numeric(3)))
  colnames(g) <- c("trophic", "hydric", "bioclim")
  gradients <- as.data.frame(g)
  gradients$synthetic <- TRUE
  obs <- data.frame(
    pente = 10 + 4 * gradients$hydric + stats::rnorm(n, sd = 2),
    humus = factor(ifelse(gradients$trophic + stats::rnorm(n, sd = 0.4) > 0, "mull", "moder")),
    synthetic = TRUE)
  flore <- matrix(0L, n, 9, dimnames = list(NULL, paste0("sp", 1:9)))
  for (j in 1:9) {
    cible <- c("a", "b", "c")[(j - 1) %/% 3 + 1]
    flore[, j] <- stats::rbinom(n, 1, ifelse(grp == cible, 0.8, 0.1))
  }
  np <- 60
  age <- stats::runif(np, 30, 120)
  gp <- rep(c("a", "b", "c"), length.out = np)
  eff <- c(a = 3, b = 0, c = -3)[gp] + stats::rnorm(np, sd = 0.5)
  arbres <- data.frame(plot = rep(seq_len(np), each = 4), species = "chene")
  arbres$age <- rep(age, each = 4) + stats::rnorm(4 * np, sd = 2)
  arbres$height <- 8 * log(rep(age, each = 4)) - 10 + rep(eff, each = 4) +
    stats::rnorm(4 * np, sd = 0.3)
  arbres$synthetic <- TRUE
  list(grp = grp, gradients = gradients, observables = obs, flore = flore,
       arbres = arbres, plot_types = data.frame(plot = seq_len(np), type = gp),
       synthetic = TRUE)
}
