# Mission 031 : comparaison de nos gradients (run 018, 225 dalles) a CarHab 68.
# Lit data/sorties/D11/{gradients,incertitude}.tif (lecture seule), lit les polygones CarHab
# (WFS, cache data/cache/carhab/), ecrit tables et figures sous
# data/sorties/D11/comparaison_carhab/. Methode et limites : docs/comparaison-carhab.md.
# Usage (depuis la racine du depot) : Rscript inst/scripts/comparaison_carhab.R [dossier_sorties [dossier_cache]]
# Coordonnees : EPSG:2154 (Lambert-93), x = est, y = nord.

suppressMessages({
  if (file.exists("DESCRIPTION")) devtools::load_all(quiet = TRUE) else library(sylvostation)
})

args <- commandArgs(trailingOnly = TRUE)
dir_in <- if (length(args) >= 1L) args[1] else file.path("data", "sorties", "D11")
dir_out <- file.path(dir_in, "comparaison_carhab")
cache <- if (length(args) >= 2L) args[2] else file.path("data", "cache", "carhab")
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
bbox <- c(1007000, 6790000, 1022000, 6805000)   # emprise test (config.yml, par. 26)
NBOOT <- as.integer(Sys.getenv("CARHAB_NBOOT", "500")); BLOC_M <- 1000; PAS_M <- 500

grad <- terra::rast(file.path(dir_in, "gradients.tif"))
inc <- terra::rast(file.path(dir_in, "incertitude.tif"))
stopifnot(all(c("trophic", "hydric") %in% names(grad)), "aoa_trophic" %in% names(inc))
polys <- carhab_fetch(bbox, cache)
cat("Polygones CarHab 'foret' lus :", nrow(polys), "\n")

defs <- list(
  trophic = list(champ = "acidite_edaphique", titre = "Trophique / acidité édaphique",
                 aoa = inc[["aoa_trophic"]]),
  hydric = list(champ = "humidite_edaphique", titre = "Hydrique / humidité édaphique",
                aoa = NULL))

res <- list(); rasters <- list()
for (g in names(defs)) {
  d <- defs[[g]]
  ref <- carhab_rasterize(polys, grad[[g]], d$champ)
  inconnues <- attr(carhab_recode(polys[[d$champ]], d$champ), "inconnues")
  cat("\n==", g, "==\nModalites inconnues :", length(inconnues), "\n")
  r <- carhab_compare(grad[[g]], ref, d$aoa, bloc_m = BLOC_M, pas_m = PAS_M, nboot = NBOOT)
  res[[g]] <- r
  if (!is.null(d$aoa)) {
    res[[paste0(g, "_sans_aoa")]] <- carhab_compare(grad[[g]], ref, NULL, bloc_m = BLOC_M,
                                                    pas_m = PAS_M, nboot = NBOOT)
  }
  # rasters de classes : notre classe (quantiles aux proportions CarHab) et rang CarHab reindexe
  dom <- r$domaine
  cel <- terra::cellFromXY(grad[[g]], cbind(dom$cx, dom$cy))
  k <- length(r$classes$rangs)
  nous <- terra::rast(grad[[g]]); terra::values(nous) <- NA
  car <- nous; dif <- nous
  nous[cel] <- dom$classe
  car[cel] <- match(dom$ref, r$classes$rangs)
  dif[cel] <- dom$classe - match(dom$ref, r$classes$rangs)
  rasters[[g]] <- list(nous = nous, carhab = car, diff = dif, k = k, ref = ref)
  terra::writeRaster(dif, file.path(dir_out, paste0("ecart_classes_", g, ".tif")),
                     overwrite = TRUE, datatype = "INT1S")
}

# ---- tables ------------------------------------------------------------------------
lab <- function(g) sub("_sans_aoa", " (sans exclusion hors zone d'applicabilite)", g)
t_sp <- do.call(rbind, lapply(names(res), function(g) {
  r <- res[[g]]
  data.frame(gradient = g, n_cellules = nrow(r$domaine), spearman = r$spearman$rho,
             ic_blocs_bas = r$spearman$bloc$ic_bas, ic_blocs_haut = r$spearman$bloc$ic_haut,
             n_blocs = r$spearman$bloc$n_blocs, bloc_m = BLOC_M, nboot = NBOOT,
             spearman_espace = r$spearman$espace$rho, ic_espace_bas = r$spearman$espace$ic_bas,
             ic_espace_haut = r$spearman$espace$ic_haut, n_espace = r$spearman$espace$n,
             pas_m = PAS_M, kappa_lineaire = r$kappa$kappa, kappa_quadratique = r$kappa_quad$kappa,
             accord_exact = r$kappa$accord_exact, accord_1_classe = r$kappa$accord_1_classe)
}))
utils::write.csv(t_sp, file.path(dir_out, "spearman_kappa.csv"), row.names = FALSE)
t_cp <- do.call(rbind, lapply(names(res), function(g) {
  data.frame(gradient = g, etape = names(res[[g]]$comptes), cellules = as.integer(res[[g]]$comptes),
             hectares = as.integer(res[[g]]$comptes) * 0.04)
}))
utils::write.csv(t_cp, file.path(dir_out, "comptes.csv"), row.names = FALSE)
for (g in names(res)) {
  r <- res[[g]]
  champ <- defs[[sub("_sans_aoa", "", g)]]$champ
  modal <- names(carhab_levels(champ))[r$classes$rangs]
  m <- as.matrix(r$kappa$matrice)
  dimnames(m) <- list(nous = paste0("classe_", seq_len(nrow(m))), carhab = modal)
  utils::write.csv(cbind(classe_nous = rownames(m), as.data.frame.matrix(m)),
                   file.path(dir_out, paste0("matrice_confusion_", g, ".csv")), row.names = FALSE)
  pm <- r$par_modalite; pm$modalite <- modal; pm$coupe_haute <- c(r$classes$coupes, NA)
  utils::write.csv(pm, file.path(dir_out, paste0("par_modalite_", g, ".csv")), row.names = FALSE)
}
print(t_sp, digits = 3)
print(t_cp)
for (g in names(res)) { cat("\n--", g, "--\n"); print(res[[g]]$kappa$matrice) }

# ---- figures -----------------------------------------------------------------------
cols_acc <- c("#2c7bb6", "#fdae61", "#d7191c")   # exact, a une classe, 2 classes ou plus
for (g in names(defs)) {
  rs <- rasters[[g]]; d <- defs[[g]]; k <- rs$k
  champ <- d$champ
  ac <- abs(rs$diff)
  ac <- terra::ifel(ac == 0, 1, terra::ifel(ac == 1, 2, 3))
  levels(ac) <- data.frame(id = 1:3, accord = c("accord exact", "\u00e0 une classe",
                                                "deux classes ou plus"))
  png(file.path(dir_out, paste0("carte_accord_", g, ".png")), width = 1700, height = 1250, res = 130)
  terra::plot(ac, col = cols_acc, type = "classes", levels = c("accord exact", "à une classe",
              "deux classes ou plus"), main = paste0("Accord : ", d$titre, " (grille de 20 m)"),
              mar = c(2, 2, 3, 11))
  dev.off()
  png(file.path(dir_out, paste0("carte_desaccord_", g, ".png")), width = 1700, height = 1250, res = 130)
  terra::plot(rs$diff, col = hcl.colors(2 * (k - 1) + 1, "RdBu", rev = TRUE), range = c(-(k - 1), k - 1),
              main = paste0("Ecart (notre classe - classe CarHab) : ", d$titre),
              mar = c(2, 2, 3, 11))
  dev.off()
  # zoom sur le secteur de contrôle (polygone 6057, 1013000-1015000 x 6797000-6799000)
  z <- terra::ext(1013000, 1015000, 6797000, 6799000)
  png(file.path(dir_out, paste0("zoom_secteur_", g, ".png")), width = 1800, height = 900, res = 130)
  par(mfrow = c(1, 2))
  terra::plot(terra::crop(rs$carhab, z), main = paste0("CarHab (classe, 1 = bas) - ", g),
              col = hcl.colors(k, "YlGnBu", rev = TRUE), type = "continuous", range = c(1, k))
  terra::plot(terra::crop(rs$nous, z), main = paste0("Nos classes (1 = bas) - ", g),
              col = hcl.colors(k, "YlGnBu", rev = TRUE), type = "continuous", range = c(1, k))
  dev.off()
}
# distribution de notre gradient par modalite CarHab
png(file.path(dir_out, "distribution_gradient_par_modalite.png"), width = 1800, height = 800, res = 130)
par(mfrow = c(1, 2), mar = c(13, 4, 3, 1))
for (g in names(defs)) {
  r <- res[[g]]; dom <- r$domaine; champ <- defs[[g]]$champ
  modal <- names(carhab_levels(champ))
  dom$mod <- factor(modal[dom$ref], levels = modal[r$classes$rangs])
  boxplot(x ~ mod, data = dom, las = 2, col = "grey85", outline = FALSE, xlab = "", ylab = paste("Notre gradient", g),
          main = sprintf("%s (Spearman %.2f)", defs[[g]]$titre, r$spearman$rho), cex.axis = 0.8)
}
dev.off()

# ---- controles ---------------------------------------------------------------------
# 1. Alignement spatial : notre axe bioclimatique contre l'etage de vegetation CarHab
#    (collineen 1, montagnard 2, subalpin 3). Notre axe croit avec la chaleur : le signe
#    attendu est NEGATIF ; seul le |rho| dit si les deux grilles sont bien superposees.
et <- polys
et$rang <- ifelse(grepl("^montagnard$", et$etage_de_vegetation), 2L,
                  ifelse(grepl("^subalpin$", et$etage_de_vegetation), 3L, 1L))
et$rang[!et$etage_de_vegetation %in% c("collin\u00e9en", "montagnard", "subalpin")] <- NA
re <- terra::rasterize(terra::vect(et[, "rang"]), terra::rast(grad, nlyrs = 1), field = "rang")
db <- stats::na.omit(data.frame(b = terra::values(grad[["bioclim"]], mat = FALSE),
                                e = terra::values(re, mat = FALSE)))
ctl <- data.frame(controle = "bioclim_contre_etage_carhab", n_cellules = nrow(db),
                  spearman = stats::cor(db$b, db$e, method = "spearman"),
                  mediane_collineen = stats::median(db$b[db$e == 1]),
                  mediane_montagnard = stats::median(db$b[db$e == 2]))
utils::write.csv(ctl, file.path(dir_out, "controle_alignement_bioclim.csv"), row.names = FALSE)
print(ctl)
# 2. Egalites de notre gradient (les quantiles ne peuvent pas separer des valeurs egales)
eg <- do.call(rbind, lapply(names(defs), function(g) {
  v <- terra::values(grad[[g]], mat = FALSE); v <- v[!is.na(v)]
  data.frame(gradient = g, valeurs_distinctes = length(unique(v)),
             part_au_maximum = mean(v == max(v)), part_au_minimum = mean(v == min(v)))
}))
utils::write.csv(eg, file.path(dir_out, "egalites_gradient.csv"), row.names = FALSE)
print(eg)

# 3. Sensibilite de l'ordre hydrique (provisoire : il mele reserve en eau et engorgement).
#    (a) sec -> humide seul : modalites 1 a 3 (assez sec, mesique, legerement humide) ;
#    (b) engorgement : modalites 4 et 5 contre les autres. Estimations ponctuelles et
#    intervalle du sous-echantillon espace seulement (pas de bootstrap : nboot = 0).
dh <- res[["hydric"]]$domaine
sens <- list(
  sec_humide_1_a_3 = dh[dh$ref <= 3L, ],
  engorgement_4_5_contre_reste = transform(dh, ref = as.integer(ref >= 4L)))
t_sens <- do.call(rbind, lapply(names(sens), function(n) {
  q <- sens[[n]]
  sp <- carhab_spearman(q$x, q$ref, q$cx, q$cy, bloc_m = BLOC_M, pas_m = PAS_M, nboot = 0L)
  data.frame(sensibilite = n, n_cellules = nrow(q), spearman = sp$rho,
             spearman_espace = sp$espace$rho, ic_espace_bas = sp$espace$ic_bas,
             ic_espace_haut = sp$espace$ic_haut, n_espace = sp$espace$n)
}))
utils::write.csv(t_sens, file.path(dir_out, "sensibilite_ordre_hydrique.csv"), row.names = FALSE)
print(t_sens)
cat("\nTables et figures dans", dir_out, "\n")
