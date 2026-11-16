# Incrément 1 (mission 003) : chaîne LiDAR sur des dalles réelles du massif test.
# Liste les dalles (WFS), les télécharge en flux (LAZ supprimés après calcul), calcule MNT et
# MHC à 1 m avec lasR, compare le MNT recalculé au MNT IGN (champ url_mnt), mesure temps et
# volumes, et écrit docs/increment1.md.
#
# Usage (depuis la racine du dépôt) :
#   LC_ALL=C.UTF-8 Rscript inst/scripts/increment1.R [dossier_de_travail] [xmin ymin xmax ymax]
# Par défaut : <data_dir de config.yml>/increment1 et le carré 2 x 2 de dalles 1014-6793 à 1015-6794.
# Hors dépôt : LAZ éphémères dans <travail>/laz, GeoTIFF gardés dans <travail>/sorties.

args <- commandArgs(TRUE)
work <- if (length(args) >= 1) args[1] else file.path(read_config()$data_dir, "increment1")  # data/ est ignoré par git
emprise <- if (length(args) >= 5) as.numeric(args[2:5]) else c(1014000, 6792000, 1016000, 6794000)
names(emprise) <- c("xmin", "ymin", "xmax", "ymax")
ncores <- 3L; buffer <- 20

suppressMessages(devtools::load_all(quiet = TRUE))
sorties <- file.path(work, "sorties"); laz_dir <- file.path(work, "laz"); ign_dir <- file.path(work, "ign_mnt")
for (d in c(sorties, ign_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
disque_libre <- function(p) {
  l <- system2("df", c("-B1", "--output=avail", p), stdout = TRUE)
  as.numeric(l[length(l)])
}
mo <- function(x) sprintf("%.1f", x / 1e6)
tbl <- function(d) {
  d[] <- lapply(d, as.character)
  c(paste0("| ", paste(names(d), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(d)), collapse = "|"), "|"),
    apply(d, 1, function(l) paste0("| ", paste(l, collapse = " | "), " |")))
}

libre0 <- disque_libre(work)
t0 <- Sys.time()

# 1. Tableau d'assemblage (WFS, réseau)
t_list <- system.time(tuiles <- list_tiles(emprise))[["elapsed"]]
message("Dalles : ", paste(tuiles$tile_id, collapse = ", "))

# 2. Téléchargement en flux, calcul lasR, suppression des LAZ
res <- run_lasr(tuiles$url, sorties, res = 1, ncores = ncores, buffer = buffer,
                keep_laz = FALSE, engine = "lasr", laz_dir = laz_dir)
tm <- attr(res, "timing")
laz_restants <- list.files(laz_dir, full.names = TRUE)
message("LAZ restant apres calcul : ", length(laz_restants))
vmhwm <- as.numeric(sub(".*:\\s+(\\d+) kB.*", "\\1",
                        grep("VmHWM", readLines("/proc/self/status"), value = TRUE))) * 1024

# 3. Contrôle : MNT recalculé (1 m) contre MNT IGN (0,5 m, url_mnt), dalle par dalle
comp <- list(); t_ign <- 0
for (i in seq_len(nrow(tuiles))) {
  id <- tuiles$tile_id[i]
  dest <- file.path(ign_dir, paste0("mnt_ign_", id, ".tif"))
  t_ign <- t_ign + system.time({
    if (!file.exists(dest)) utils::download.file(tuiles$url_mnt[i], dest, mode = "wb", quiet = TRUE)
  })[["elapsed"]]
  ign <- terra::rast(dest)
  nous <- terra::rast(res$mnt[res$tile_id == id])
  # Le GeoTIFF IGN annonce EPSG:2154 sans le même texte WKT : on aligne l'étiquette (même CRS).
  terra::crs(ign) <- terra::crs(nous)
  # L'emprise IGN est celle de la dalle (cellules de 0,5 m centrées sur x.25 et x.75) : le centre
  # d'une cellule de 1 m (x.5) est le milieu de 2 x 2 cellules IGN, l'interpolation bilinéaire
  # en est donc la moyenne.
  ign1 <- terra::resample(ign, nous, method = "bilinear")
  d <- nous - ign1
  v <- terra::values(d, na.rm = TRUE)[, 1]
  pente <- terra::terrain(nous, "slope", unit = "degrees", neighbors = 8)
  p <- terra::values(pente)[, 1]; dd <- terra::values(d)[, 1]
  classe <- cut(p, c(-Inf, 10, 25, Inf), labels = c("< 10", "10-25", "> 25"))
  par_pente <- sapply(levels(classe), function(k) {
    z <- dd[classe == k & !is.na(classe) & !is.na(dd)]
    c(n = length(z), moy = mean(z), sd = sd(z), part = mean(abs(z) > 0.5))
  })
  comp[[id]] <- list(
    stat = c(n = length(v), moy = mean(v), sd = sd(v), mediane = median(v),
             part05 = mean(abs(v) > 0.5), p99 = unname(quantile(abs(v), 0.99)),
             na_nous = mean(is.na(terra::values(nous))), na_ign = mean(is.na(terra::values(ign1)))),
    par_pente = par_pente, geoigne = as.vector(terra::ext(ign)), res_ign = terra::res(ign))
}

# 4. Résumés des produits
prod <- do.call(rbind, lapply(seq_len(nrow(res)), function(i) {
  m <- terra::rast(res$mnt[i]); h <- terra::rast(res$mhc[i])
  vm <- terra::values(m)[, 1]; vh <- terra::values(h)[, 1]
  data.frame(
    dalle = res$tile_id[i],
    vol = paste(format(tuiles$date_debut[tuiles$tile_id == res$tile_id[i]]), "->",
                format(tuiles$date_fin[tuiles$tile_id == res$tile_id[i]])),
    cellules = format(terra::ncell(m), big.mark = " ", scientific = FALSE), mnt_na = sprintf("%.2f %%", 100 * mean(is.na(vm))),
    mnt_min_max = sprintf("%.1f ; %.1f", min(vm, na.rm = TRUE), max(vm, na.rm = TRUE)),
    mhc_moy_max = sprintf("%.1f ; %.1f", mean(vh, na.rm = TRUE), max(vh, na.rm = TRUE)),
    mhc_na = sprintf("%.2f %%", 100 * mean(is.na(vh))),
    mhc_min = sprintf("%.2f", min(vh, na.rm = TRUE)),
    mhc_neg = sprintf("%.3f %%", 100 * mean(vh < 0, na.rm = TRUE)),
    mnt_mo = mo(file.size(res$mnt[i])), mhc_mo = mo(file.size(res$mhc[i])))
}))
n <- nrow(res)
sorties_mo <- sum(file.size(c(res$mnt, res$mhc)))
total <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

# 5. Compte rendu
st <- do.call(rbind, lapply(names(comp), function(k) {
  s <- comp[[k]]$stat
  data.frame(dalle = k, n_cellules = format(s[["n"]], big.mark = " ", scientific = FALSE),
             ecart_moyen_m = sprintf("%+.3f", s[["moy"]]), ecart_type_m = sprintf("%.3f", s[["sd"]]),
             mediane_m = sprintf("%+.3f", s[["mediane"]]),
             part_abs_sup_05 = sprintf("%.2f %%", 100 * s[["part05"]]),
             p99_abs_m = sprintf("%.2f", s[["p99"]]))
}))
sl <- do.call(rbind, lapply(names(comp), function(k) {
  m <- comp[[k]]$par_pente
  data.frame(dalle = k, pente_deg = colnames(m), cellules = format(m["n", ], big.mark = " ", scientific = FALSE),
             ecart_moyen_m = sprintf("%+.3f", m["moy", ]), ecart_type_m = sprintf("%.3f", m["sd", ]),
             part_abs_sup_05 = sprintf("%.2f %%", 100 * m["part", ]))
}))
tout <- Reduce(`+`, lapply(comp, function(s) s$stat[["n"]] * c(s$stat[["moy"]], s$stat[["part05"]])))
ntot <- sum(sapply(comp, function(s) s$stat[["n"]]))

doc <- c(
  "# Incrément 1 : chaîne LiDAR HD sur 4 dalles réelles du massif test",
  "",
  paste0("Mission 003. Compte rendu **écrit par `inst/scripts/increment1.R`** le ",
         format(Sys.time(), "%Y-%m-%d"), " ; les chiffres ci-dessous sont mesurés, pas estimés, ",
         "sauf les lignes marquées « extrapolation »."),
  "",
  "## Ce qui a tourné",
  "",
  paste0("- Emprise : `", paste(emprise, collapse = " "), "` (EPSG:2154, xmin ymin xmax ymax), ",
         "carré 2 x 2 de dalles contiguës du massif test (relief : voir les altitudes ci-dessous)."),
  paste0("- `list_tiles()` (WFS `IGNF_LIDAR-HD_METADONNEE:metadata`, `CQL_FILTER=WITHIN`) : ",
         nrow(tuiles), " dalles en ", sprintf("%.1f", t_list), " s."),
  paste0("- `run_lasr()` : téléchargement des URL `url_npl` (COPC LAZ), calcul `lasR` ",
         "(triangulation des classes 2, 9, 66 ; MNT et MHC à 1 m ; ", ncores, " cœurs, `buffer = ", buffer,
         "`), LAZ supprimés après calcul (`keep_laz = FALSE`) : ", length(laz_restants),
         " LAZ restant dans `laz/`."),
  "- Contrôle : MNT IGN 0,5 m (`url_mnt`, WMS) téléchargé pour les 4 dalles, ré-échantillonné",
  "  (bilinéaire) sur la grille 1 m recalculée, écarts = recalculé - IGN.",
  "",
  "## Dalles et dates de vol",
  "",
  tbl(data.frame(dalle = tuiles$tile_id, date_debut = format(tuiles$date_debut),
                 date_fin = format(tuiles$date_fin), points = format(tuiles$nombre_points, big.mark = " "),
                 url_npl = sub("^.*/", "", tuiles$url))),
  "",
  "## Temps et volumes (mesurés)",
  "",
  tbl(data.frame(
    etape = c("Liste des dalles (WFS)", "Téléchargement des 4 LAZ", "Calcul lasR (MNT + MHC)",
              "Téléchargement des 4 MNT IGN de contrôle", "Total du script"),
    duree_s = sprintf("%.0f", c(t_list, tm$download_s, tm$compute_s, t_ign, total)),
    par_dalle_s = c("", sprintf("%.0f", tm$download_s / n), sprintf("%.0f", tm$compute_s / n),
                    sprintf("%.0f", t_ign / n), ""))),
  "",
  paste0("- LAZ téléchargés : ", mo(tm$laz_bytes), " Mo (", mo(tm$laz_bytes / n), " Mo par dalle) ; débit ",
         sprintf("%.1f", tm$laz_bytes / 1e6 / tm$download_s), " Mo/s."),
  paste0("- Pic de disque temporaire : ", mo(tm$laz_bytes), " Mo (les 4 LAZ présents ensemble pour ",
         "que le tampon de 20 m voie les voisines), puis 0 Mo."),
  paste0("- Produits gardés : ", mo(sorties_mo), " Mo pour ", n, " MNT + ", n, " MHC GeoTIFF float32 ",
         "compressés DEFLATE (", mo(sorties_mo / n), " Mo par dalle, MNT + MHC)."),
  paste0("- Mémoire résidente maximale du processus R (VmHWM, lasR compris) : ",
         sprintf("%.1f", vmhwm / 2^30), " Gio."),
  paste0("- Disque libre dans le dossier de travail : ", sprintf("%.1f", libre0 / 1e9), " Go avant, ",
         sprintf("%.1f", disque_libre(work) / 1e9), " Go après."),
  "",
  "### Extrapolation aux 225 dalles de l'emprise (calcul, pas mesure)",
  "",
  paste0("- Calcul lasR : ", sprintf("%.1f", tm$compute_s / n * 225 / 3600), " h à ", ncores, " cœurs (",
         sprintf("%.0f", tm$compute_s / n), " s par dalle mesurées) ; la durée dépend du nombre de points ",
         "par dalle (de 15,7 à 65,8 millions de points, de 62 à 359 Mo, docs/referentiels.md § 13)."),
  paste0("- Téléchargement : ", sprintf("%.1f", 45735823198 / 1e6 / (tm$laz_bytes / 1e6 / tm$download_s) / 60),
         " min pour 45,7 Go au débit mesuré."),
  paste0("- Produits : ", sprintf("%.1f", sorties_mo / n * 225 / 1e9), " Go pour 225 MNT + 225 MHC à 1 m."),
  "",
  "## Produits",
  "",
  tbl(prod),
  "",
  "Colonnes : `mnt_na` = part des cellules sans valeur ; `mnt_min_max` en m (IGN69) ; `mhc_moy_max` en m ; ",
  "`mhc_na` = part des cellules du MHC sans valeur ; `mhc_neg` = part des cellules du MHC < 0 (bruit sous le MNT, non écrêté) ; `mhc_min` = minimum (négatif, de l'ordre de -1 m) : la part « 0.00 % » d'une version antérieure du tableau n'était qu'un effet d'arrondi à deux décimales.",
  "",
  "Calcul de toute l'emprise (décision provisoire, par délégation) : par blocs de 3 x 3 dalles contiguës (environ 1,7 Go de LAZ au pic, le tampon de 20 m voit les voisines du bloc) ; pas de fonction d'enchaînement écrite dans cette mission.",
  "",
  "## Écart MNT recalculé (1 m) moins MNT IGN (0,5 m)",
  "",
  tbl(st),
  "",
  paste0("Ensemble des ", length(comp), " dalles (", format(ntot, big.mark = " ", scientific = FALSE), " cellules) : écart moyen ",
         sprintf("%+.3f", tout[1] / ntot), " m ; part de |écart| > 0,5 m : ",
         sprintf("%.2f %%", 100 * tout[2] / ntot), "."),
  "",
  "Par classe de pente du MNT recalculé (degrés, voisinage 8) :",
  "",
  tbl(sl),
  "",
  "## Limites et points « à vérifier »",
  "",
  "- Le MNT IGN est un produit à 0,5 m dont la méthode d'interpolation et les classes retenues ne sont ",
  "  pas décrites dans `docs/referentiels.md` : à vérifier. Un écart n'est donc pas une erreur de l'un des deux.",
  "- Le MHC exclut les classes 65 et 66 (filtre `Classification %out% 65 66`) : la liste complète des classes ",
  "  LiDAR HD n'est pas dans `docs/referentiels.md` ; à vérifier.",
  "- Aucune dalle du carré n'est volée entièrement en avril : deux sont volées le 2022-01-13, deux entre le 2022-01-13 et le 2022-04-21 (à cheval) ; le choix de dalles « pur avril » n'a pas été fait (le carré 2 x 2 retenu est celui qui contient la frontière janvier / avril du tableau d'assemblage).",
  "- Les dalles de la mission `22LHDVosgesRF` sont volées entre le 2022-01-12 et le 2022-04-21 : ",
  "  la date de vol est à garder comme covariable (brief technique, § 5).",
  "- Le MHC est la hauteur maximale par cellule de 1 m, sans lissage ni remplissage des trous.",
  "- Le repli `lidR` n'est testé que sur l'extrait de 80 m (tests unitaires), pas sur ces 4 dalles.",
  "",
  "## Fichiers gardés (hors dépôt)",
  "",
  paste0("- `", normalizePath(sorties), "/mnt_<dalle>.tif` et `mhc_<dalle>.tif` (EPSG:2154, 1 m, rognés à l'emprise de 1 km de la dalle).")
)
writeLines(doc, "docs/increment1.md")
saveRDS(list(res = res, tuiles = tuiles, comp = comp, tm = tm), file.path(work, "increment1.rds"))
message("Termine : docs/increment1.md")
