# Chaîne LiDAR HD : MNT et MHC à 1 m (lasR, repli lidR) et métriques ponctuelles lidR.
# Sources : docs/referentiels.md, § 2 (dalles), § 10 (signatures lasR 0.21.4, lidR 4.3.3).
# Classes LiDAR HD : 2 sol, 9 eau, 66 points virtuels (CLAUDE.md, « Référentiels »).

.CLASSES_SOL <- c(2L, 9L, 66L)

# Identifiant de dalle « XXXX-YYYY » lu dans un nom de fichier LHD_FXX_XXXX_YYYY_*, sinon NA.
.tile_id_from_name <- function(f) {
  m <- regmatches(basename(f), regexec("LHD_FXX_(\\d{4})_(\\d{4})", basename(f)))[[1]]
  if (length(m) == 3L) paste0(m[2], "-", m[3]) else NA_character_
}

# Emprise (xmin, xmax, ymin, ymax) d'une dalle de 1 km à partir de son identifiant « XXXX-YYYY ».
.tile_extent <- function(tile_id) {
  xy <- as.numeric(strsplit(tile_id, "-", fixed = TRUE)[[1]]) * 1000
  terra::ext(xy[1], xy[1] + 1000, xy[2] - 1000, xy[2])
}

# Écrit un raster rogné à l'emprise de la dalle (lasR déborde d'une cellule sur le bord).
.write_tile_raster <- function(r, tile_id, dest) {
  if (!is.na(tile_id)) r <- terra::crop(r, .tile_extent(tile_id))
  terra::writeRaster(r, dest, overwrite = TRUE, datatype = "FLT4S",
                     gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
  dest
}

# Pipeline lasR : triangulation du sol (2, 9, 66), MNT, normalisation, MHC (maximum des hauteurs).
.run_lasr_engine <- function(files, raw_dir, res, ncores, buffer) {
  filtre_sol <- paste0("Classification %in% ", paste(.CLASSES_SOL, collapse = " "))
  tri <- lasR::triangulate(filter = filtre_sol)
  mnt <- lasR::rasterize(res, tri, ofile = file.path(raw_dir, "*_mnt.tif"))
  nrm <- lasR::transform_with(tri, "-")
  # Classes 65 (artefacts) et 66 (points virtuels) exclues du MHC : à vérifier (nomenclature
  # complète des classes LiDAR HD non reprise dans docs/referentiels.md).
  mhc <- lasR::rasterize(res, "max", filter = "Classification %out% 65 66",
                         ofile = file.path(raw_dir, "*_mhc.tif"))
  pipeline <- lasR::reader() + tri + mnt + nrm + mhc
  lasR::exec(pipeline, on = files,
             with = list(ncores = lasR::concurrent_points(ncores), buffer = buffer))
  invisible(NULL)
}

# Repli lidR : MNT (TIN sur les classes 2, 9, 66), MHC = MNS (point le plus haut) - MNT.
.run_lidr_engine <- function(files, res, ncores, buffer) {
  ctg <- lidR::readLAScatalog(files, progress = FALSE)
  lidR::opt_chunk_buffer(ctg) <- max(buffer, 1) # lidR exige un tampon > 0
  lidR::opt_chunk_size(ctg) <- 0
  lidR::opt_progress(ctg) <- FALSE
  lidR::set_lidr_threads(ncores)
  # Repli : classes 2 et 9 seulement ; le filtre LASlib de lidR refuse la classe 66 (hors 0-31).
  mnt <- lidR::rasterize_terrain(ctg, res, lidR::tin(), use_class = c(2L, 9L))
  mns <- lidR::rasterize_canopy(ctg, res, lidR::p2r())
  mhc <- terra::resample(mns, mnt, method = "near") - mnt
  list(mnt = mnt, mhc = mhc)
}

#' MNT et MHC à 1 m depuis des dalles LiDAR HD
#'
#' Calcule, dalle par dalle, le modèle numérique de terrain (MNT : triangulation des
#' points de classes 2 sol, 9 eau et 66 points virtuels) et le modèle de hauteur de
#' canopée (MHC : maximum par cellule de la hauteur au-dessus du MNT) en un seul passage
#' `lasR`. Si `lasR` n'est pas installé, repli sur `lidR` (MHC alors = MNS - MNT ;
#' tampon d'au moins 1 m, exigé par lidR ; classes 2 et 9 seulement, le filtre de lidR
#' refusant la classe 66).
#'
#' `laz_files` peut mêler des chemins locaux et des URL (`http`/`https`, champ `url` de
#' [list_tiles()]). Les URL sont téléchargées dans `laz_dir`, **toutes avant le calcul**
#' (les voisines servent au tampon `buffer`), puis supprimées après le calcul si
#' `keep_laz = FALSE`. Les fichiers locaux fournis par l'appelant ne sont **jamais**
#' supprimés. Pour un massif entier, appeler la fonction par blocs de dalles contiguës.
#' Chaque raster est rogné à l'emprise de 1 km de sa dalle quand le nom du fichier suit
#' `LHD_FXX_XXXX_YYYY_*`.
#'
#' @param laz_files Chemins ou URL de fichiers LAZ/LAS/COPC.
#' @param out_dir Dossier de sortie (créé si besoin) : `mnt_<dalle>.tif`, `mhc_<dalle>.tif`.
#' @param res Résolution en mètres (1 par défaut).
#' @param ncores Nombre de cœurs (3 par défaut, valeur provisoire).
#' @param buffer Tampon en mètres lu autour de chaque dalle (20 par défaut, valeur
#'   provisoire de l'esquisse du brief).
#' @param keep_laz Garder les LAZ téléchargés (`FALSE` par défaut).
#' @param engine `"auto"` (lasR si installé, sinon lidR), `"lasr"` ou `"lidr"`.
#' @param laz_dir Dossier des LAZ téléchargés.
#' @return Un `data.frame` : `tile_id`, `mnt`, `mhc` (chemins des GeoTIFF). Attribut
#'   `timing` : liste `download_s`, `compute_s`, `laz_bytes`, `engine`.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
#'   run_lasr(f, tempfile("lidar"), buffer = 0)
#' }
#' @export
run_lasr <- function(laz_files, out_dir, res = 1, ncores = 3, buffer = 20,
                     keep_laz = FALSE, engine = c("auto", "lasr", "lidr"),
                     laz_dir = file.path(out_dir, "laz")) {
  engine <- match.arg(engine)
  if (!is.character(laz_files) || !length(laz_files) || anyNA(laz_files)) {
    stop("`laz_files` doit \u00eatre un vecteur de chemins ou d'URL.", call. = FALSE)
  }
  if (!is.numeric(res) || length(res) != 1L || is.na(res) || res <= 0) {
    stop("`res` doit \u00eatre un nombre strictement positif.", call. = FALSE)
  }
  if (!is.numeric(buffer) || length(buffer) != 1L || is.na(buffer) || buffer < 0) {
    stop("`buffer` doit \u00eatre un nombre positif ou nul (m\u00e8tres).", call. = FALSE)
  }
  if (engine == "auto") {
    engine <- if (requireNamespace("lasR", quietly = TRUE)) "lasr" else "lidr"
  }
  if (!requireNamespace(if (engine == "lasr") "lasR" else "lidR", quietly = TRUE)) {
    stop("Paquet `", if (engine == "lasr") "lasR" else "lidR", "` non install\u00e9.", call. = FALSE)
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  distant <- grepl("^https?://", laz_files)
  locaux <- laz_files[!distant]
  if (length(locaux) && !all(file.exists(locaux))) {
    stop("Fichier(s) LAZ introuvable(s) : ",
         paste(locaux[!file.exists(locaux)], collapse = ", "), call. = FALSE)
  }
  files <- laz_files
  telecharges <- character(0)
  t_dl <- system.time({
    for (i in which(distant)) {
      files[i] <- .download_once(laz_files[i], laz_dir)
      telecharges <- c(telecharges, files[i])
    }
  })[["elapsed"]]
  if (!keep_laz) on.exit(unlink(telecharges), add = TRUE)
  laz_bytes <- sum(file.size(files))

  raw_dir <- file.path(out_dir, "_raw")
  dir.create(raw_dir, showWarnings = FALSE)
  on.exit(unlink(raw_dir, recursive = TRUE), add = TRUE)

  ids <- vapply(files, .tile_id_from_name, "", USE.NAMES = FALSE)
  noms <- ifelse(is.na(ids), tools::file_path_sans_ext(basename(files)), ids)
  mnt_out <- file.path(out_dir, paste0("mnt_", noms, ".tif"))
  mhc_out <- file.path(out_dir, paste0("mhc_", noms, ".tif"))

  t_calc <- system.time({
    if (engine == "lasr") {
      .run_lasr_engine(files, raw_dir, res, ncores, buffer)
      for (i in seq_along(files)) {
        base <- sub("\\.(la[sz])$", "", basename(files[i]), ignore.case = TRUE)
        for (k in c("mnt", "mhc")) {
          brut <- file.path(raw_dir, paste0(base, "_", k, ".tif"))
          if (!file.exists(brut)) {
            stop("Sortie lasR absente : ", brut, call. = FALSE)
          }
          .write_tile_raster(terra::rast(brut), ids[i],
                             if (k == "mnt") mnt_out[i] else mhc_out[i])
        }
      }
    } else {
      r <- .run_lidr_engine(files, res, ncores, buffer)
      for (i in seq_along(files)) {
        .write_tile_raster(r$mnt, ids[i], mnt_out[i])
        .write_tile_raster(r$mhc, ids[i], mhc_out[i])
      }
    }
  })[["elapsed"]]

  out <- data.frame(tile_id = ifelse(is.na(ids), NA_character_, ids),
                    mnt = mnt_out, mhc = mhc_out, stringsAsFactors = FALSE)
  attr(out, "timing") <- list(download_s = t_dl, compute_s = t_calc,
                              laz_bytes = laz_bytes, engine = engine)
  out
}

#' Métriques LiDAR ponctuelles autour de points précis
#'
#' Calcule des métriques de hauteur (nombre de points, moyenne, écart-type, 95e
#' percentile, maximum, part des points au-dessus de 2 m) dans un disque de rayon
#' `radius` autour de chaque point. Les points doivent être normalisés (hauteur au-dessus
#' du sol) ou un `dtm` doit être fourni. **Extraction fine : la règle bloquante
#' s'applique** ; la fonction appelle [assert_no_fine_extract_on_ifn()] en premier et
#' refuse les placettes IFN et tout point dont `loc_precision_m` est absent, `NA` ou
#' supérieur à 25 m.
#'
#' @param ctg_or_files Un objet `lidR::LAS`, un `lidR::LAScatalog` ou des chemins de
#'   fichiers LAZ/LAS.
#' @param points Un `sf` de points en EPSG:2154, avec la colonne `loc_precision_m`.
#' @param radius Rayon du disque, en mètres (15 par défaut).
#' @param dtm Un `SpatRaster` de MNT pour normaliser les hauteurs (facultatif).
#' @return `points` complété des colonnes `lidar_n_pts`, `lidar_zmean`, `lidar_zsd`,
#'   `lidar_zq95`, `lidar_zmax`, `lidar_cover2` (`NA` si aucun point dans le disque).
#' @examples
#' p <- mark_ifn(sf::st_as_sf(data.frame(x = 1015040, y = 6793960),
#'                            coords = c("x", "y"), crs = 2154))
#' try(point_lidar_metrics("absent.laz", p))
#' @export
point_lidar_metrics <- function(ctg_or_files, points, radius = 15, dtm = NULL) {
  assert_no_fine_extract_on_ifn(points, "metriques_lidar")
  if (!inherits(points, "sf") || !all(sf::st_geometry_type(points) == "POINT")) {
    stop("`points` doit \u00eatre un objet sf de points.", call. = FALSE)
  }
  assert_crs_2154(points)
  if (!is.numeric(radius) || length(radius) != 1L || is.na(radius) || radius <= 0) {
    stop("`radius` doit \u00eatre un nombre strictement positif (m\u00e8tres).", call. = FALSE)
  }
  if (!requireNamespace("lidR", quietly = TRUE)) {
    stop("Paquet `lidR` non install\u00e9.", call. = FALSE)
  }
  src <- ctg_or_files
  if (is.character(src)) src <- lidR::readLAScatalog(src, progress = FALSE)
  if (inherits(src, "LAScatalog")) lidR::opt_progress(src) <- FALSE
  xy <- sf::st_coordinates(points)
  cols <- c("lidar_n_pts", "lidar_zmean", "lidar_zsd", "lidar_zq95", "lidar_zmax", "lidar_cover2")
  res <- matrix(NA_real_, nrow(points), length(cols), dimnames = list(NULL, cols))
  for (i in seq_len(nrow(points))) {
    las <- suppressWarnings(lidR::clip_circle(src, xy[i, 1], xy[i, 2], radius))
    if (is.null(las) || lidR::is.empty(las)) next
    if (!is.null(dtm)) las <- lidR::normalize_height(las, dtm)
    z <- las$Z[las$Z >= 0]
    if (!length(z)) next
    res[i, ] <- c(length(z), mean(z), stats::sd(z), unname(stats::quantile(z, 0.95)),
                  max(z), mean(z > 2))
  }
  cbind(points, as.data.frame(res))
}
