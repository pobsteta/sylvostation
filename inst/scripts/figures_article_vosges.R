# Figures et petites tables de l'article « Résultats sur le massif test vosgien (D11) »
# (mission 023). À lancer à la main, depuis la racine du dépôt, APRÈS un run réel du pipeline
# (mission 018) :
#
#   Rscript inst/scripts/figures_article_vosges.R AAAA-MM-JJ [dossier_sorties] [dossier_figures]
#
# Le premier argument est la DATE DU RUN, obligatoire : les sorties ne consignent aucune date
# (le mtime des fichiers n'est pas une date consignée) ; on la recopie du journal du run.
# Défauts : data/sorties/D11 (lecture seule) et vignettes/articles/figures. Le script ne
# lance aucun calcul de pipeline, aucun téléchargement : il met en image des sorties
# existantes (rasters, tables CSV). L'article, lui, ne lit que le résultat de ce script.
# Coordonnées en Lambert-93 (EPSG:2154), x = est, y = nord. Aucune donnée fabriquée : si le
# dossier contient un fichier à préfixe `synth_`, le script s'arrête.
suppressPackageStartupMessages({ library(terra); library(sf) })

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1 || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", args[[1]])) {
  stop("Premier argument obligatoire : date du run au format AAAA-MM-JJ.")
}
date_run <- args[[1]]
dossier <- if (length(args) >= 2) args[[2]] else file.path("data", "sorties", "D11")
sortie  <- if (length(args) >= 3) args[[3]] else file.path("vignettes", "articles", "figures")
dir.create(sortie, showWarnings = FALSE, recursive = TRUE)

if (any(grepl("^synth_", list.files(dossier)))) {
  stop("Sorties synthétiques (préfixe synth_) : l'article ne montre que le run réel.")
}
chemin <- function(f) file.path(dossier, f)
stopifnot(file.exists(chemin("types.tif")), file.exists(chemin("hydrique.tif")),
          file.exists(chemin("incertitude.tif")), file.exists(chemin("etat_de_preuve.csv")))

types <- rast(chemin("types.tif"))
hydro <- rast(chemin("hydrique.tif"))
incer <- rast(chemin("incertitude.tif"))
for (r in list(types, hydro, incer)) {
  if (!identical(crs(r, describe = TRUE)$code, "2154")) stop("Raster hors EPSG:2154.")
}
e <- as.vector(ext(types))   # xmin, xmax, ymin, ymax
res_m <- res(types)[[1]]
legende <- read.csv2(chemin("legende_types.csv"), stringsAsFactors = FALSE)
cols_types <- c("#1b9e77", "#d95f02", "#7570b3", "#e6ab02")[seq_len(nrow(legende))]
masque <- !is.na(types)

pied <- function(...) {
  mtext(paste0(..., "sylvostation, run réel D11 du ", date_run, " | emprise x ", e[1], "-", e[2],
               ", y ", e[3], "-", e[4], " | EPSG:2154 | grille ", res_m, " m"),
        side = 1, line = 4.2, cex = 0.55, adj = 0, col = "grey30")
}
nord <- function(r) {  # flèche du nord et barre d'échelle de 5 km, en coordonnées de la carte
  x0 <- xmax(r) - 1500; y0 <- ymin(r) + 800
  arrows(x0, y0, x0, y0 + 1500, length = 0.08, lwd = 2)
  text(x0, y0 + 2000, "N", cex = 0.8, font = 2)
  segments(xmin(r) + 500, ymin(r) + 600, xmin(r) + 5500, ymin(r) + 600, lwd = 3)
  text(xmin(r) + 3000, ymin(r) + 1100, "5 km", cex = 0.7)
}
png_fig <- function(nom, l = 1100, h = 1000, expr) {
  png(file.path(sortie, nom), width = l, height = h, res = 130)
  on.exit(dev.off())
  par(mar = c(5.6, 4, 3, 1))
  force(expr)
}

# --- 1. situation : emprise test dans la SER D11 -------------------------------------------
ser <- st_read(file.path("inst", "extdata", "ser_extrait.gpkg"), quiet = TRUE)
stopifnot(st_crs(ser)$epsg == 2154)
emp <- st_as_sfc(st_bbox(c(xmin = e[[1]], xmax = e[[2]], ymin = e[[3]], ymax = e[[4]]),
                         crs = st_crs(2154)))
png_fig("situation.png", 1100, 1000, {
  plot(st_geometry(ser), col = c("#cfe3d4", "#e8e0c8"), border = "grey40", axes = TRUE,
       xlab = "x, est (m, Lambert-93)", ylab = "y, nord (m, Lambert-93)",
       main = "Situation : emprise test dans la SER D11")
  plot(emp, add = TRUE, border = "red", lwd = 2)
  cent <- suppressWarnings(st_centroid(st_geometry(ser)))
  text(st_coordinates(cent), labels = ser$codeser, cex = 1.1, font = 2, col = "grey20")
  text(e[[2]] + 3000, mean(e[3:4]), "emprise\ntest\n15 x 15 km", col = "red", cex = 0.8, adj = 0)
  pied("Fond : IGN, sylvoécorégions (Licence Ouverte) | ")
})

# --- 2. carte des types ---------------------------------------------------------------------
png_fig("types.png", 1100, 1000, {
  f <- as.factor(types)
  levels(f) <- data.frame(id = legende$id, type = legende$type)
  plot(f, col = cols_types, main = "Types de stations (4 types, cellules forestières)",
       plg = list(x = "topright", cex = 0.8), mar = c(5.6, 4, 3, 1),
       xlab = "x, est (m)", ylab = "y, nord (m)")
  nord(types)
  pied("Composante régionale, non validée sur le terrain | ")
})

# --- 3. carte hydrique (Istress de 20 m) ---------------------------------------------------
png_fig("hydrique.png", 1100, 1000, {
  h <- mask(hydro[["is_topo"]], types)
  plot(h, col = hcl.colors(50, "YlOrRd", rev = TRUE), mar = c(5.6, 4, 3, 1),
       main = "Contrainte hydrique Istress (plus haut = plus sec)",
       xlab = "x, est (m)", ylab = "y, nord (m)")
  nord(h)
  pied("BILJOU sur SAFRAN, rayonnement de la pente | provisoire | ")
})

# --- 4. incertitude : écart-type et zone d'applicabilité (trophique) -----------------------
png_fig("incertitude.png", 1900, 900, {
  par(mfrow = c(1, 2), mar = c(5.6, 4, 3, 1))
  sd1 <- mask(incer[["sd_cv_trophic"]], types)
  plot(sd1, col = hcl.colors(50, "Purples 3", rev = TRUE), mar = c(5.6, 4, 3, 1),
       main = "Écart-type (trophique, niveau global)", xlab = "x, est (m)", ylab = "y, nord (m)")
  nord(sd1)
  pied("Incertitude | ")
  a <- mask(incer[["aoa_trophic"]], types)
  f <- as.factor(a); niv <- levels(f)[[1]]
  lib <- c(`0` = "hors zone", `1` = "dans la zone")
  levels(f) <- data.frame(id = niv[[1]], zone = lib[as.character(niv[[1]])])
  plot(f, col = c(`0` = "#d95f02", `1` = "#1b9e77")[as.character(niv[[1]])],
       main = "Zone d'applicabilité (trophique)", mar = c(5.6, 4, 3, 1),
       plg = list(x = "topright", cex = 0.8), xlab = "x, est (m)", ylab = "y, nord (m)")
  nord(a)
  pied("Applicabilité | ")
})
aoa_hors <- as.numeric(global(mask(incer[["aoa_trophic"]] == 0, types), "sum", na.rm = TRUE)) /
  as.numeric(global(masque, "sum"))

# --- 5. schéma de la chaîne ------------------------------------------------------------------
png_fig("schema.png", 1500, 700, {
  par(mar = c(1.2, 0.2, 2, 0.2))
  etapes <- c("1  LiDAR HD\nMNT 1 m, MHC", paste0("2  Terrain ", res_m, " m\nmasque forestier"),
              "3  Gradients des\nplacettes IFN", "4  Modèles régionaux,\nvalidation croisée",
              paste0("5  Carte hydrique\n", res_m, " m (BILJOU)"), "6  Typologie\n(seuils, fusions)",
              "7  Caractérisation\ndes types", "8  Clé de\ndétermination", "9  Validation")
  plot(NA, xlim = c(0, 3), ylim = c(0, 3), axes = FALSE, xlab = "", ylab = "",
       main = "Chaîne de calcul (de la dalle LiDAR au catalogue)")
  mtext(paste0("Source : sylvostation, run réel D11 du ", date_run, " | schéma, pas une donnée"),
        side = 1, line = -0.3, cex = 0.6, adj = 0, col = "grey30")
  bw <- 0.40; bh <- 0.30
  xs <- rep(c(0.5, 1.5, 2.5), 3); ys <- rep(c(2.5, 1.5, 0.5), each = 3)
  cols <- c("#cfe3f1", "#cfe3f1", "#dfeccf", "#dfeccf", "#dfeccf", "#f5e6c4", "#f5e6c4",
            "#f5e6c4", "#e7d3e8")
  for (i in seq_along(etapes)) {
    rect(xs[i] - bw, ys[i] - bh, xs[i] + bw, ys[i] + bh, col = cols[i], border = "grey30")
    text(xs[i], ys[i], etapes[i], cex = 0.95)
  }
  fl <- function(x0, y0, x1, y1) arrows(x0, y0, x1, y1, length = 0.08, col = "grey20")
  for (i in c(1, 2, 4, 5, 7, 8)) fl(xs[i] + bw, ys[i], xs[i + 1] - bw, ys[i + 1])
  for (r in 1:2) {
    yb <- ys[3 * r] - bh; yn <- ys[3 * r + 1] + bh; ym <- (yb + yn) / 2
    segments(xs[3 * r], yb, xs[3 * r], ym, col = "grey20")
    segments(xs[3 * r], ym, xs[3 * r + 1], ym, col = "grey20")
    fl(xs[3 * r + 1], ym, xs[3 * r + 1], yn)
  }
})

# --- 5 bis. la carte reproduit-elle les mailles climatiques ? -------------------------------
# La couche ru_maille de hydrique.tif prend une valeur par maille SAFRAN (9 mailles) : elle
# sert d'identifiant de maille.
grad <- rast(chemin("gradients.tif"))
mk <- round(values(hydro[["ru_maille"]])[, 1], 3)
tv <- values(types)[, 1]
ok <- !is.na(tv) & !is.na(mk)
r2_maille <- function(y) {
  y <- y[ok]; f <- factor(mk[ok]); 1 - sum(resid(lm(y ~ f))^2) / sum((y - mean(y))^2)
}
r2_is <- r2_maille(values(hydro[["is_topo"]])[, 1])
r2_tr <- r2_maille(values(grad[["trophic"]])[, 1])
tb <- table(mk[ok], tv[ok])
part_modal <- sum(apply(tb, 1, max)) / sum(tb)
M <- matrix(mk, nrow = nrow(types), byrow = TRUE); Tm <- matrix(tv, nrow = nrow(types), byrow = TRUE)
chg <- function(a, b, ma, mb) {
  v <- !is.na(a) & !is.na(b); same <- ma == mb
  c(dans = sum((a != b)[v & same]), n_dans = sum(v & same),
    limite = sum((a != b)[v & !same]), n_limite = sum(v & !same))
}
cc <- chg(Tm[, -ncol(Tm)], Tm[, -1], M[, -ncol(M)], M[, -1]) +
  chg(Tm[-nrow(Tm), ], Tm[-1, ], M[-nrow(M), ], M[-1, ])
chg_dans <- cc[["dans"]] / cc[["n_dans"]]; chg_limite <- cc[["limite"]] / cc[["n_limite"]]
# chaque sens séparément (le relecteur donne une plage) : 12 à 18 % à une limite
ch_h <- chg(Tm[, -ncol(Tm)], Tm[, -1], M[, -ncol(M)], M[, -1])
ch_v <- chg(Tm[-nrow(Tm), ], Tm[-1, ], M[-nrow(M), ], M[-1, ])
lim_h <- ch_h[["limite"]] / ch_h[["n_limite"]]; lim_v <- ch_v[["limite"]] / ch_v[["n_limite"]]
# part de la grille et de la forêt typée hors de la SER D11 (centres de cellules, Lambert-93)
d11 <- st_union(ser[ser$codeser == "D11", ])
xy <- xyFromCell(types, seq_len(ncell(types)))
dedans <- lengths(st_intersects(st_as_sf(as.data.frame(xy), coords = c("x", "y"), crs = 2154), d11)) > 0
hors_grille <- mean(!dedans); hors_foret <- mean(!dedans[!is.na(tv)])

# --- 6. petites tables précalculées ---------------------------------------------------------
for (f in c("etat_de_preuve.csv", "validation_stats.csv", "cle_resume.csv", "types.csv")) {
  file.copy(chemin(f), file.path(sortie, f), overwrite = TRUE)
}
n_forest <- as.numeric(global(masque, "sum"))
chiffres <- data.frame(
  cle = c("date_run", "resolution_m", "cellules_forestieres", "surface_foret_ha",
          "part_hors_zone_aoa_trophique", "n_mailles", "r2_maille_istress", "r2_maille_trophique",
          "part_type_modal_maille", "changement_type_voisins_dans_maille",
          "changement_type_voisins_limite_h", "changement_type_voisins_limite_v",
          "part_emprise_hors_d11", "part_foret_hors_d11"),
  valeur = c(date_run, res_m, n_forest, round(n_forest * res_m^2 / 1e4, 1), round(aoa_hors, 4),
             length(unique(mk[ok])), round(r2_is, 4), round(r2_tr, 4), round(part_modal, 4),
             round(chg_dans, 4), round(lim_h, 4), round(lim_v, 4),
             round(hors_grille, 4), round(hors_foret, 4)))
write.csv(chiffres, file.path(sortie, "chiffres.csv"), row.names = FALSE)
message("Figures écrites dans ", sortie, " (",
        round(sum(file.size(list.files(sortie, full.names = TRUE))) / 1e6, 2), " Mo)")
