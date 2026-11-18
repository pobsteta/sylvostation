# References lentes de la mission 028, utilisees seulement par les tests de test-hydrique.R.

# Reference lente de `.maille_proche()` (une boucle sur les points), pour le test d'egalite.
.maille_proche_ref <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  vapply(seq_along(x), function(i) {
    d <- sqrt((mailles$x - x[i])^2 + (mailles$y - y[i])^2)
    j <- which.min(d)
    if (!length(j) || d[j] > dmax) NA_character_ else mailles$maille[j]
  }, character(1))
}

# Indices BILJOU moyens (sur les annees) pour une meteo et des reserves utiles.
# Reference lente (mission 028) : une passe `biljouR::biljou_run()` par reserve utile.
# Gardee pour verifier que `.biljou_ru()` (vectorise) rend les memes resultats.
.biljou_ru_ref <- function(meteo, ru, param) {
  t(vapply(ru, function(r) {
    if (is.na(r) || r <= 0) return(c(is = NA_real_, nj = NA_real_, n = NA_real_))
    soil <- biljouR::biljou_soil(ewm = r)
    run <- biljouR::biljou_run(meteo, soil, lai_max = param$lai_max,
                               forest_type = param$forest_type,
                               budburst = param$budburst, leaf_fall = param$leaf_fall)
    idx <- biljouR::biljou_indices(run)
    c(is = mean(idx$Istress), nj = mean(idx$NJstress), n = nrow(idx))
  }, numeric(3)))
}
