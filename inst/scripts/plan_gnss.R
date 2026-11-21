# Plan d'echantillonnage des releves floristiques GNSS (mission 029), a lancer sur les
# sorties du run reel (225 dalles), apres la mission 027 (MRVBF).
# Usage (racine du depot, store `_targets` du run reel a jour) :
#   LC_ALL=C.UTF-8 Rscript inst/scripts/plan_gnss.R [n] [seed] [cost_max_m]
# Sorties : <out_dir>/<ser_code>/plan_gnss/ (GeoPackage EPSG:2154, GPX WGS84, couverture,
# carte, durees). Methode et limites : docs/echantillonnage.md.
suppressMessages({
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE) else library(sylvostation)
})
terra::terraOptions(threads = 2)
args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args) >= 1) as.integer(args[1]) else 50L
seed <- if (length(args) >= 2) as.integer(args[2]) else 29L
cost_max_m <- if (length(args) >= 3) as.numeric(args[3]) else 300

cfg <- read_config("config.yml")
if (isTRUE(cfg$demo)) stop("config.yml est en mode demo : le plan se tire sur le run reel.")
out <- file.path(cfg$out_dir, cfg$ser_code, "plan_gnss")

# --- couches fines de la grille, lues dans le store du run reel ----------------------
terrain <- targets::tar_read(terrain)
hydric <- targets::tar_read(hydric_grid)$r
geol <- targets::tar_read(geol_rast)
forest <- targets::tar_read(forest)
if (is.null(forest)) stop("Masque forestier absent (forest_mask: false) : plan impossible.")
names(geol) <- "geologie"
layers <- c(terrain[[c("pente", "altitude", "mrvbf", "hauteur_reseau")]],
            hydric[[c("k_sv", "is_topo")]], geol)

# --- troncons accessibles BD TOPO (WFS Geoplateforme, cache hors depot) ---------------
# le cache porte l'emprise dans son nom : une autre emprise donne un autre fichier
b <- sf::st_bbox(terra::ext(layers) + 1000, crs = sf::st_crs(2154))
cache <- file.path(cfg$cache_dir, "bdtopo", sprintf("troncon_de_route_%d_%d_%d_%d.gpkg",
                   round(b[["xmin"]]), round(b[["ymin"]]), round(b[["xmax"]]), round(b[["ymax"]])))
if (!file.exists(cache)) {
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  brut <- get_access_network(b, source = "wfs", filter = FALSE)
  sf::st_write(brut, cache, quiet = TRUE)
}
access <- get_access_network(b, source = "file", path = cache)
cat("Troncons accessibles :", nrow(access), "dont acces restreint :", sum(access$acces_restreint), "\n")

# --- tirage, diagnostic, durees ------------------------------------------------------
plan <- sampling_plan(layers, forest, access, n = n, cost_max_m = cost_max_m, seed = seed)
fr <- attr(plan, "frame")
part <- 100 * mean(fr$candidat)
cat(sprintf("Cellules forestieres : %d ; candidates : %d (%.1f %%) ; couches ecartees : %s\n",
            nrow(fr), sum(fr$candidat), part, paste(attr(fr, "ecartees"), collapse = ", ")))
if (sum(fr$candidat) < 20 * n || part < 5) {
  cat("ATTENTION : peu de candidates (seuil d'homogeneite 0,5 sur", length(attr(fr, "vars")),
      "couches, acces, bord des routes) ; lire docs/echantillonnage.md avant de continuer.\n")
}
cv <- sampling_coverage(plan)
ft <- field_time(plan)
f <- write_sampling_plan(plan, cv, out, access = access, forest = forest)
utils::write.csv(ft$par_point, file.path(out, "durees.csv"), row.names = FALSE)
print(cv[cv$indicateur == "ks_p", c("variable", "echantillon")])
cat(sprintf("Duree estimee (parametres provisoires) : %.1f h, %d jours\n", ft$total_h, ft$jours))
cat("Fichiers :", c(f, file.path(out, "durees.csv")), sep = "\n")
