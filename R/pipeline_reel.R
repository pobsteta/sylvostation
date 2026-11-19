# Mode réel du pipeline (mission 016) : assistants appelés par `_targets.R` quand
# `demo: false`. Avec `offline: true`, aucune fonction de ce fichier ne touche au réseau :
# toutes les sources sont les extraits réels de `inst/extdata` (docs/pipeline.md).
# Sources des URL : docs/referentiels.md (§ 1, 2, 5, 7, 15, 23). Une URL non vérifiée
# n'est jamais codée : le chemin local est alors demandé dans config.yml.

# URL vérifiées (docs/referentiels.md) des sources dont seule l'année ou le département
# varie. Les URL de l'archive IFN et de TAXREF ont une seule source : config.yml
# (`ifn_archive_url`, `taxref_url`), lue par read_config().
.URL_SAFRAN <- "https://meteofrance.s3.sbg.io.cloud.ovh.net/data/REF_CC/SIM/QUOT_SIM2_%d.csv.gz"
.URL_BDCHARM <- "https://infoterre.brgm.fr/telechargements/BDCharm50/GEO050K_HARM_%s.zip"

# Gradients du catalogue, dans l'ordre des types (T-H-B).
.GRADIENTS <- c("trophic", "hydric", "bioclim")

#' Télécharger un fichier une seule fois (cache local), ou refuser hors ligne
#'
#' Renvoie le chemin local de `url` dans `dir` : si le fichier y est déjà, aucun accès
#' réseau n'a lieu. Sinon, avec `offline = TRUE`, la fonction **s'arrête** (le mode
#' hors ligne ne télécharge jamais) ; sinon elle télécharge par `downloader`.
#'
#' **Reprise sur incident réseau** (mission 026) : un échec du téléchargement (erreur ou
#' état non nul, par exemple « Stream error in the HTTP/2 framing layer ») est repris,
#' jusqu'à `retries` tentatives au total, avec une attente croissante (`wait`). Le fichier
#' partiel est supprimé avant chaque reprise et un message est émis à chaque tentative.
#' Après la dernière, la fonction s'arrête avec une erreur claire (adresse, nombre de
#' tentatives, dernière cause).
#'
#' @param url Adresse du fichier.
#' @param dir Dossier de cache (créé si besoin, hors dépôt : sous `data/`).
#' @param offline `TRUE` pour interdire tout téléchargement.
#' @param downloader Fonction de téléchargement, de signature de
#'   [utils::download.file()] (remplaçable dans les tests).
#' @param retries Nombre total de tentatives (au moins 1). Par défaut l'option
#'   `sylvostation.download_retries`, sinon 3 (valeur provisoire ; en mode réel, `_targets.R`
#'   pose l'option depuis la clé `download_retries` de `config.yml`).
#' @param wait Attentes (secondes) avant la 2e, la 3e... tentative ; la dernière valeur
#'   est répétée si besoin. Défaut : 5, 20, 60 (provisoire).
#' @param sleeper Fonction d'attente (remplaçable dans les tests).
#' @return Le chemin du fichier local.
#' @examples
#' d <- tempfile("cache")
#' dir.create(d)
#' writeLines("x", file.path(d, "a.csv"))
#' fetch_cached("https://exemple.invalid/a.csv", d, offline = TRUE)
#' @export
fetch_cached <- function(url, dir, offline = FALSE, downloader = utils::download.file,
                         retries = getOption("sylvostation.download_retries", 3L),
                         wait = c(5, 20, 60), sleeper = Sys.sleep) {
  if (!is.character(url) || length(url) != 1L || !nzchar(url)) {
    stop("`url` doit \u00eatre une adresse.", call. = FALSE)
  }
  if (!is.numeric(retries) || length(retries) != 1L || !is.finite(retries) || retries < 1 ||
      retries != round(retries)) {
    stop("`retries` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  if (!is.numeric(wait) || length(wait) < 1L || anyNA(wait) || any(wait < 0)) {
    stop("`wait` doit contenir au moins une dur\u00e9e (s) >= 0.", call. = FALSE)
  }
  dest <- file.path(dir, basename(sub("[?#].*$", "", url)))
  if (file.exists(dest) && file.size(dest) > 0) return(dest)
  if (isTRUE(offline)) {
    stop("Mode hors ligne : t\u00e9l\u00e9chargement interdit (", url, ").", call. = FALSE)
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(dest, ".part")
  .retry_download(url, tmp, downloader, as.integer(retries), wait, sleeper)
  file.rename(tmp, dest)
  dest
}

# Telechargement avec reprise pour les appels hors `fetch_cached()` (SER, dalles LiDAR,
# tableau d'assemblage WFS, TOPAGE ; mission 026). `tmp` : fichier partiel, supprime avant
# chaque reprise. Le telechargeur et l'attente se remplacent dans les tests par les options
# `sylvostation.downloader` et `sylvostation.sleeper` ; le nombre de tentatives vient de
# l'option `sylvostation.download_retries` (3 par defaut, config.yml: download_retries).
.download_retry <- function(url, tmp) {
  .retry_download(url, tmp,
                  getOption("sylvostation.downloader", utils::download.file),
                  as.integer(getOption("sylvostation.download_retries", 3L)),
                  c(5, 20, 60), getOption("sylvostation.sleeper", Sys.sleep))
}

# Tente `downloader(url, tmp)` jusqu'a `retries` fois ; supprime `tmp` avant chaque reprise.
.retry_download <- function(url, tmp, downloader, retries, wait, sleeper) {
  cause <- ""
  for (k in seq_len(retries)) {
    unlink(tmp)
    cause <- tryCatch({
      status <- downloader(url, tmp, mode = "wb", quiet = TRUE)
      if (identical(as.integer(status), 0L) && file.exists(tmp)) "" else
        paste0("\u00e9tat ", paste(status, collapse = ","))
    }, error = function(e) conditionMessage(e))
    if (!nzchar(cause)) return(invisible(tmp))
    unlink(tmp)
    if (k < retries) {
      w <- wait[min(k, length(wait))]
      message("T\u00e9l\u00e9chargement en \u00e9chec (tentative ", k, "/", retries, ") : ", url,
              " \u2014 ", cause, ". Nouvelle tentative dans ", w, " s.")
      sleeper(w)
    }
  }
  stop("T\u00e9l\u00e9chargement impossible apr\u00e8s ", retries, " tentative(s) : ", url,
       " (derni\u00e8re cause : ", cause, ").", call. = FALSE)
}

#' Sources du mode réel (fichiers locaux ou téléchargement)
#'
#' Résout, pour chaque entrée du mode réel, où la lire. Avec `offline: true`, ce sont
#' les **extraits réels** de `inst/extdata` (jamais un jeu `synth_`) ; sinon les sources
#' publiques de `docs/referentiels.md`, mises en cache sous `cfg$data_dir/cache`. Les
#' entrées optionnelles (`gnss_path`, `reference_path`, `soil_paths`) valent `NULL`
#' quand elles sont absentes : elles ne sont jamais remplacées.
#'
#' La version de TAXREF de `cfg$taxref_version` doit figurer dans le nom du fichier
#' TAXREF utilisé (`v18`...) : sinon la fonction s'arrête.
#'
#' @param cfg Configuration de [read_config()] (mode réel).
#' @param extdata Dossier des extraits (`inst/extdata` du paquet).
#' @return Une liste nommée de sources : `offline`, `ser`, `laz`, `hydro`, `geol`,
#'   `ifn_dir`, `taxref`, `tichy`, `safran`, `gnss`, `reference`, `soils`.
#' @examples
#' f <- tempfile(fileext = ".yml")
#' writeLines(c('ser_code: "D11"',
#'   "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
#'   "buffer_m: 5000", "resolution_m: 20", "crs: 2154", "data_dir: data",
#'   "laz_dir: data/laz", "out_dir: data/sorties", "ifn_precision_m: 700",
#'   "demo: false", "offline: true"), f)
#' names(real_sources(read_config(f)))
#' @export
real_sources <- function(cfg, extdata = system.file("extdata", package = "sylvostation")) {
  off <- isTRUE(cfg$offline)
  x <- function(f) {
    p <- file.path(extdata, f)
    if (!file.exists(p)) stop("Extrait absent de inst/extdata : ", f, call. = FALSE)
    assert_not_synthetic(p, f)
  }
  opt <- function(p, cle) {
    if (is.null(p) || !length(p) || all(!nzchar(p))) return(NULL)
    manque <- p[!file.exists(p)]
    if (length(manque)) {
      stop("Entr\u00e9e optionnelle introuvable : ", paste(manque, collapse = ", "),
           " (retirer la cl\u00e9 de config.yml si l'entr\u00e9e est absente).", call. = FALSE)
    }
    assert_not_synthetic(p, cle)
  }
  if (off) {
    s <- list(
      ser = list(source = "file", path = x("ser_extrait.gpkg")),
      laz = x("LHD_FXX_1015_6794_extrait.laz"),
      hydro = list(source = "file", path = x("topage_troncons_extrait.gpkg")),
      geol = list(paths = x("bdcharm50_emprise_test.gpkg")),
      ifn_dir = extdata,
      taxref = x("taxref_v18_extrait.csv"),
      tichy = x("tichy_2023_extrait.csv"),
      safran = x("safran_sim2_12mailles_extrait.csv"))
  } else {
    for (k in c("ifn_archive_url", "taxref_url")) {
      if (is.null(cfg[[k]]) || !nzchar(cfg[[k]])) {
        stop("Mode r\u00e9el en ligne : la cl\u00e9 `", k, "` de config.yml est requise ",
             "(docs/referentiels.md \u00a7 7 et \u00a7 15).", call. = FALSE)
      }
    }
    if (is.null(cfg$tichy_path) || !file.exists(cfg$tichy_path)) {
      stop("Mode r\u00e9el en ligne : `tichy_path` doit d\u00e9signer le classeur Zenodo ",
           "Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx (DOI 10.5281/zenodo.7427088 ; ",
           "adresse de t\u00e9l\u00e9chargement directe \u00e0 v\u00e9rifier, docs/referentiels.md \u00a7 14).",
           call. = FALSE)
    }
    s <- list(
      ser = list(source = "download", path = NULL),
      laz = NULL,
      hydro = list(source = "wfs", path = NULL),
      geol = list(urls = sprintf(.URL_BDCHARM, cfg$bdcharm_departements)),
      ifn_dir = NULL,
      ifn_url = cfg$ifn_archive_url,
      taxref = cfg$taxref_url,
      tichy = assert_not_synthetic(cfg$tichy_path, "tichy_path"),
      safran = NULL)
  }
  tx <- basename(s$taxref)
  if (!grepl(paste0("v", cfg$taxref_version, "([^0-9]|$)"), tx, ignore.case = TRUE)) {
    stop("Version TAXREF incoh\u00e9rente : config.yml fige la v", cfg$taxref_version,
         ", le fichier est ", tx, ".", call. = FALSE)
  }
  s$offline <- off
  s$gnss <- opt(cfg$gnss_path, "gnss_path")
  s$reference <- opt(cfg$reference_path, "reference_path")
  s$soils <- opt(unlist(cfg$soil_paths), "soil_paths")
  s
}

#' Refuser un fichier synthétique en mode réel
#'
#' Le mode réel ne remplace jamais une entrée par un jeu fabriqué (CLAUDE.md). Arrêt si
#' le nom du fichier commence par `synth_`, si une colonne `synthetic` vaut `TRUE`
#' (CSV, TXT, GeoPackage, classeur `.xlsx` si `readxl` est installé) ou si un raster
#' porte la balise `synthetic = TRUE` (`terra::metags`).
#'
#' @param paths Chemins des fichiers.
#' @param entree Nom de l'entrée (clé de config.yml), pour le message.
#' @return `paths`, de façon invisible, si aucun n'est synthétique.
#' @examples
#' f <- tempfile("synth_gnss_", fileext = ".csv")
#' writeLines("id,x,y", f)
#' try(assert_not_synthetic(f, "gnss_path"))
#' @export
assert_not_synthetic <- function(paths, entree = "entr\u00e9e") {
  arret <- function(p, pourquoi) {
    stop("Mode r\u00e9el : `", entree, "` d\u00e9signe un jeu synth\u00e9tique (", pourquoi, ") : ",
         p, ". Une entr\u00e9e absente se d\u00e9clare (retirer la cl\u00e9), elle ne se remplace pas.",
         call. = FALSE)
  }
  vrai <- function(v) any(toupper(trimws(as.character(v))) %in% c("TRUE", "T", "1"), na.rm = TRUE)
  for (p in paths) {
    if (startsWith(tolower(basename(p)), "synth_")) arret(p, "pr\u00e9fixe synth_")
    ext <- tolower(sub("^.*\\.([^.]+)$", "\\1", sub("\\.gz$", "", basename(p), ignore.case = TRUE)))
    if (ext %in% c("csv", "txt")) {
      l1 <- readLines(p, n = 1L, warn = FALSE, encoding = "UTF-8")
      if (length(l1)) {
        sep <- c(";", ",", "\t")[which.max(vapply(c(";", ",", "\t"), function(s)
          lengths(regmatches(l1, gregexpr(s, l1, fixed = TRUE))), 1L))]
        noms <- gsub('^"|"$', "", strsplit(l1, sep, fixed = TRUE)[[1]])
        if ("synthetic" %in% noms) {
          d <- utils::read.table(p, sep = sep, header = TRUE, quote = "\"", comment.char = "",
                                 colClasses = "character", check.names = FALSE, fill = TRUE)
          if (vrai(d[["synthetic"]])) arret(p, "colonne synthetic = TRUE")
        }
      }
    } else if (ext %in% c("tif", "tiff")) {
      m <- terra::metags(terra::rast(p))
      # selon la version de terra : data.frame (name, value) ou matrice nommee par ligne
      v <- if (is.data.frame(m) && all(c("name", "value") %in% names(m))) {
        m$value[m$name == "synthetic"]
      } else if (length(m) && "synthetic" %in% rownames(m)) m["synthetic", 1] else character(0)
      if (vrai(v)) arret(p, "balise synthetic = TRUE")
    } else if (ext == "gpkg") {
      for (ly in sf::st_layers(p)$name) {
        d <- sf::st_read(p, layer = ly, quiet = TRUE)
        if ("synthetic" %in% names(d) && vrai(d[["synthetic"]])) arret(p, "colonne synthetic = TRUE")
      }
    } else if (ext == "xlsx" && requireNamespace("readxl", quietly = TRUE)) {
      for (fe in readxl::excel_sheets(p)) {
        if ("synthetic" %in% names(readxl::read_excel(p, sheet = fe, n_max = 0,
                                                              .name_repair = "minimal"))) {
          d <- readxl::read_excel(p, sheet = fe, .name_repair = "minimal")
          if (vrai(d[["synthetic"]])) arret(p, "colonne synthetic = TRUE")
        }
      }
    }
  }
  invisible(paths)
}

#' Emprise de travail du mode réel
#'
#' `cfg$emprise = "test"` (défaut, phase 0) : le carré `emprise_test` recoupé avec la
#' SER tamponnée ; `"ser"` : la SER tamponnée entière.
#'
#' @param ser `sf` de [get_ser()] (déjà tamponné).
#' @param cfg Configuration de [read_config()].
#' @return Un `sfc` (polygone) en EPSG:2154.
#' @examples
#' ser <- get_ser("D11", source = "file",
#'                path = system.file("extdata", "ser_extrait.gpkg", package = "sylvostation"))
#' cfg <- list(emprise = "test", emprise_test = list(xmin = 1007000, ymin = 6790000,
#'             xmax = 1022000, ymax = 6805000))
#' sf::st_bbox(real_extent(ser, cfg))
#' @export
real_extent <- function(ser, cfg) {
  assert_crs_2154(ser)
  g <- sf::st_union(sf::st_geometry(ser))
  mode <- if (is.null(cfg[["emprise"]])) "test" else cfg[["emprise"]]
  if (identical(mode, "ser")) return(g)
  e <- cfg$emprise_test
  box <- sf::st_as_sfc(sf::st_bbox(c(xmin = e$xmin, ymin = e$ymin, xmax = e$xmax,
                                     ymax = e$ymax), crs = sf::st_crs(2154)))
  out <- suppressWarnings(sf::st_intersection(box, g))
  if (!length(out) || all(sf::st_is_empty(out))) {
    stop("L'emprise test n'intersecte pas la SER ", cfg$ser_code, ".", call. = FALSE)
  }
  sf::st_union(out)
}

#' Tableau des dalles à partir de fichiers LAZ locaux (sans réseau)
#'
#' Pour le mode hors ligne : l'identifiant `XXXX-YYYY` est lu dans le nom
#' `LHD_FXX_XXXX_YYYY_*` (convention de l'IGN, docs/referentiels.md § 2) et la dalle
#' couvre x de `XXXX` à `XXXX + 1` km, y de `YYYY - 1` à `YYYY` km (Lambert-93).
#'
#' @param laz_files Chemins de fichiers LAZ.
#' @return Un `sf` (EPSG:2154) : `tile_id`, `url` (le chemin local), géométrie de la dalle.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' local_tiles(f)$tile_id
#' @export
local_tiles <- function(laz_files) {
  if (!is.character(laz_files) || !length(laz_files) || !all(file.exists(laz_files))) {
    stop("`laz_files` doit d\u00e9signer des fichiers LAZ existants.", call. = FALSE)
  }
  ids <- vapply(laz_files, .tile_id_from_name, "", USE.NAMES = FALSE)
  if (anyNA(ids)) {
    stop("Nom de dalle illisible (LHD_FXX_XXXX_YYYY attendu) : ",
         paste(basename(laz_files[is.na(ids)]), collapse = ", "), call. = FALSE)
  }
  geoms <- lapply(ids, function(id) {
    e <- as.vector(.tile_extent(id))  # xmin, xmax, ymin, ymax
    sf::st_polygon(list(matrix(c(e[1], e[3], e[2], e[3], e[2], e[4], e[1], e[4], e[1], e[3]),
                               ncol = 2, byrow = TRUE)))
  })
  out <- sf::st_sf(tile_id = ids, url = laz_files,
                   geometry = sf::st_sfc(geoms, crs = 2154))
  out[order(out$tile_id), ]
}

#' Garder au plus `max_tiles` dalles, les plus proches du centre de l'ensemble
#'
#' Pour un essai court (par exemple 4 dalles avant la SER entière). Les dalles gardées
#' sont les plus proches du centre de l'ensemble (contiguës), triées par `tile_id` ;
#' en cas d'égalité de distance, l'ordre de `tile_id` décide.
#'
#' @param tiles `sf` de [list_tiles()] ou [local_tiles()].
#' @param max_tiles Nombre maximal de dalles (`NULL` : toutes).
#' @return `tiles`, éventuellement réduit.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' nrow(select_tiles(local_tiles(f), 1))
#' @export
select_tiles <- function(tiles, max_tiles = NULL) {
  if (!inherits(tiles, "sf") || !"tile_id" %in% names(tiles)) {
    stop("`tiles` doit \u00eatre un sf avec une colonne tile_id.", call. = FALSE)
  }
  if (is.null(max_tiles) || max_tiles >= nrow(tiles)) return(tiles)
  if (!is.numeric(max_tiles) || length(max_tiles) != 1L || max_tiles < 1) {
    stop("`max_tiles` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  xy <- sf::st_coordinates(sf::st_centroid(sf::st_geometry(tiles)))  # x = est, y = nord
  cx <- mean(range(xy[, 1]))
  cy <- mean(range(xy[, 2]))
  d <- round((xy[, 1] - cx)^2 + (xy[, 2] - cy)^2)
  o <- order(d, tiles$tile_id)[seq_len(max_tiles)]
  out <- tiles[sort(o), ]
  out[order(out$tile_id), ]
}

#' Grouper les dalles en blocs contigus de `size` x `size`
#'
#' Bloc d'une dalle = (`floor((x_km - x0) / size)`, `floor((y0 - y_km) / size)`), avec
#' `x0` le plus petit `x_km` et `y0` le plus grand `y_km` (coin nord-ouest) des dalles.
#' Valeur provisoire de 3 x 3 (journal, mission 003 : environ 1,7 Go de LAZ au pic).
#'
#' @param tiles `sf` de dalles (`tile_id` = « x_km-y_km », coin nord-ouest).
#' @param size Côté du bloc, en dalles (3).
#' @return Une liste de `data.frame` (`tile_id`, `url`, `block`), un par bloc, dans
#'   l'ordre des blocs : l'unité du branchement dynamique de `targets`.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' length(tile_blocks(local_tiles(f)))
#' @export
tile_blocks <- function(tiles, size = 3) {
  if (!is.numeric(size) || length(size) != 1L || size < 1) {
    stop("`size` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  d <- if (inherits(tiles, "sf")) sf::st_drop_geometry(tiles) else as.data.frame(tiles)
  if (!all(c("tile_id", "url") %in% names(d)) || !nrow(d)) {
    stop("`tiles` doit avoir des lignes et les colonnes tile_id et url.", call. = FALSE)
  }
  k <- do.call(rbind, lapply(strsplit(d$tile_id, "-", fixed = TRUE), as.numeric))
  bx <- floor((k[, 1] - min(k[, 1])) / size)
  by <- floor((max(k[, 2]) - k[, 2]) / size)
  d$block <- sprintf("b%03d_%03d", by, bx)
  d <- d[order(d$block, d$tile_id), c("tile_id", "url", "block")]
  rownames(d) <- NULL
  unname(split(d, d$block))
}

#' Traiter un bloc de dalles LiDAR (cache par dalle, reprise après interruption)
#'
#' Appelle `runner` ([run_lasr()] par défaut) sur les dalles du bloc qui ne sont pas
#' déjà calculées. Une dalle est **réutilisée** (ni retéléchargée ni recalculée) seulement
#' si ses deux sorties `mnt_<dalle>.tif` et `mhc_<dalle>.tif` existent, se lisent avec
#' `terra`, sont en EPSG:2154 et ont la résolution `res` demandée, et si les paramètres
#' consignés à leur calcul (fichier `params_<dalle>.txt`) sont ceux demandés (`res`,
#' `buffer`, `engine`). Une dalle sans fichier de paramètres (calculée avant la mission
#' 032) est acceptée sur les seuls contrôles du raster. Sinon elle est recalculée.
#' Avant tout recalcul, les sorties et le fichier de paramètres de la dalle sont effacés
#' (pas de dalle mixte après une interruption). Une dalle reprise sans `params_*.txt` est
#' signalée par un message. `force = TRUE` recalcule toutes les dalles du bloc. Les LAZ téléchargés sont effacés
#' après le bloc (`keep_laz = FALSE`). Le nombre de coeurs (`ncores`) ne change pas le
#' résultat et n'est pas consigné.
#'
#' @param block Un élément de [tile_blocks()].
#' @param out_dir Dossier des rasters LiDAR (hors dépôt).
#' @param res,buffer,ncores,engine Transmis à `runner`.
#' @param force Si `TRUE`, recalcule toutes les dalles du bloc (défaut `FALSE`).
#' @param runner Fonction de traitement (signature de [run_lasr()]).
#' @return Les chemins des rasters du bloc (`mnt_*` puis `mhc_*`), pour une cible
#'   `format = "file"`.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
#'   run_tile_block(tile_blocks(local_tiles(f))[[1]], tempfile("lidar"), buffer = 0)
#' }
#' @export
run_tile_block <- function(block, out_dir, res = 1, buffer = 20, ncores = 3,
                           engine = "auto", force = FALSE, runner = run_lasr) {
  if (!is.data.frame(block) || !all(c("tile_id", "url") %in% names(block))) {
    stop("`block` doit venir de tile_blocks().", call. = FALSE)
  }
  if (!is.logical(force) || length(force) != 1L || is.na(force)) {
    stop("`force` doit \u00eatre TRUE ou FALSE.", call. = FALSE)
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  mnt <- file.path(out_dir, paste0("mnt_", block$tile_id, ".tif"))
  mhc <- file.path(out_dir, paste0("mhc_", block$tile_id, ".tif"))
  par <- file.path(out_dir, paste0("params_", block$tile_id, ".txt"))
  params <- .tile_params(res, buffer, engine)
  a_faire <- if (force) rep(TRUE, nrow(block)) else
    !vapply(seq_len(nrow(block)), function(i) {
      .tile_cached(mnt[i], mhc[i], par[i], res, params)
    }, logical(1))
  sans_params <- !a_faire & !file.exists(par)
  if (any(sans_params)) {
    message("run_tile_block : ", sum(sans_params), " dalle(s) reprise(s) sans params_*.txt ",
            "(calcul ant\u00e9rieur \u00e0 la mission 032, param\u00e8tres non v\u00e9rifi\u00e9s) ; ",
            "param\u00e8tres demand\u00e9s : ", params)
  }
  if (any(a_faire)) {
    # efface sorties et params des dalles a refaire : un calcul interrompu ne laisse jamais
    # une dalle mixte (mnt d'un calcul, mhc d'un autre) qui serait reprise ensuite
    unlink(c(mnt[a_faire], mhc[a_faire], par[a_faire]))
    runner(block$url[a_faire], out_dir, res = res, ncores = ncores, buffer = buffer,
           keep_laz = FALSE, engine = engine)
    for (i in which(a_faire)) {
      if (file.exists(mnt[i]) && file.exists(mhc[i])) writeLines(params, par[i])
    }
  }
  manque <- c(mnt, mhc)[!file.exists(c(mnt, mhc))]
  if (length(manque)) {
    stop("Rasters LiDAR absents apr\u00e8s traitement : ", paste(basename(manque), collapse = ", "),
         call. = FALSE)
  }
  c(mnt, mhc)
}

# Parametres qui changent le calcul d'une dalle, en une ligne de texte stable.
.tile_params <- function(res, buffer, engine) {
  sprintf("res=%s;buffer=%s;engine=%s", format(res), format(buffer), engine)
}

# Une dalle est-elle reutilisable ? (existence, lecture terra, EPSG:2154, resolution,
# parametres consignes). Toute anomalie rend FALSE : la dalle est recalculee.
.tile_cached <- function(mnt, mhc, par, res, params) {
  if (!(file.exists(mnt) && file.exists(mhc))) return(FALSE)
  if (file.exists(par) && !identical(readLines(par, warn = FALSE), params)) return(FALSE)
  all(vapply(c(mnt, mhc), function(f) {
    tryCatch({
      r <- terra::rast(f)
      identical(terra::crs(r, describe = TRUE)$code, "2154") &&
        isTRUE(all.equal(unname(terra::res(r)), c(res, res)))
    }, error = function(e) FALSE)
  }, logical(1)))
}

#' Mosaïque des rasters LiDAR, agrégée
#'
#' Assemble (`terra::vrt`) les rasters `mnt_*` ou `mhc_*` de toutes les dalles,
#' vérifie qu'aucune dalle attendue ne manque, agrège d'un facteur `fact` (moyenne,
#' 1 m vers 5 m par défaut, ADR 0004) et rogne les bords vides.
#'
#' @param files Chemins renvoyés par [run_tile_block()] (tous blocs).
#' @param kind `"mnt"` ou `"mhc"`.
#' @param fact Facteur d'agrégation (5 : de 1 m à 5 m).
#' @param tile_ids Dalles attendues (`NULL` : pas de contrôle).
#' @return Un `SpatRaster` en EPSG:2154, en mémoire.
#' @examples
#' f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
#' if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
#'   r <- run_tile_block(tile_blocks(local_tiles(f))[[1]], tempfile("lidar"), buffer = 0)
#'   mosaic_tiles(r, "mnt")
#' }
#' @export
mosaic_tiles <- function(files, kind = c("mnt", "mhc"), fact = 5, tile_ids = NULL) {
  kind <- match.arg(kind)
  f <- files[startsWith(basename(files), paste0(kind, "_"))]
  if (!length(f)) stop("Aucun raster ", kind, "_ parmi `files`.", call. = FALSE)
  if (!is.null(tile_ids)) {
    attendus <- paste0(kind, "_", tile_ids, ".tif")
    manque <- setdiff(attendus, basename(f))
    if (length(manque)) {
      stop("Dalles manquantes dans la mosa\u00efque : ", paste(manque, collapse = ", "), call. = FALSE)
    }
  }
  r <- if (length(f) == 1L) terra::rast(f) else terra::vrt(f)
  assert_crs_2154(r)
  if (fact > 1) {
    # origine multiple de la maille agregee (ADR 0004) avant l'agregation
    pas <- fact * terra::res(r)[1]
    e <- as.vector(terra::ext(r))  # xmin, xmax, ymin, ymax
    r <- terra::extend(r, terra::ext(floor(e[1] / pas) * pas, ceiling(e[2] / pas) * pas,
                                     floor(e[3] / pas) * pas, ceiling(e[4] / pas) * pas))
    r <- terra::aggregate(r, fact = fact, fun = "mean", na.rm = TRUE)
  }
  r <- terra::trim(r)
  names(r) <- kind
  terra::toMemory(r)
}

#' Part de couvert forestier (MHC > `height` m) par cellule de la grille
#'
#' Masque forestier du mode réel (brief technique, étape 4 : hauteur de canopée LiDAR
#' supérieure à 5 m) : pour chaque cellule de `grid`, part des pixels du MHC
#' (1 m) au-dessus de `height`, parmi les pixels renseignés. Une cellule est forestière
#' si cette part atteint `min_share` (0,5, provisoire) et si au moins la moitié de ses
#' pixels sont renseignés ; sinon `NA`.
#'
#' @param files Chemins des rasters `mhc_*` (ou un `SpatRaster` de MHC).
#' @param grid `SpatRaster` modèle (EPSG:2154).
#' @param height Seuil de hauteur, en mètres (5).
#' @param min_share Part minimale de pixels au-dessus du seuil (0,5).
#' @return Un `SpatRaster` sur `grid` : `foret` (1 ou `NA`) et `part_couvert` (0 à 1).
#' @examples
#' chm <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
#'                    resolution = 1, crs = "EPSG:2154", vals = 10)
#' g <- build_grid(c(1015500, 6793500, 1015550, 6793550), 20)
#' forest_mask(chm, g)
#' @export
forest_mask <- function(files, grid, height = 5, min_share = 0.5) {
  assert_crs_2154(grid)
  chm <- if (inherits(files, "SpatRaster")) files else {
    f <- files[startsWith(basename(files), "mhc_")]
    if (!length(f)) stop("Aucun raster mhc_ parmi `files`.", call. = FALSE)
    if (length(f) == 1L) terra::rast(f) else terra::vrt(f)
  }
  assert_crs_2154(chm)
  fact <- round(terra::res(grid)[1] / terra::res(chm)[1])
  if (fact < 1) stop("Le MHC doit \u00eatre plus fin que la grille.", call. = FALSE)
  haut <- chm > height
  part <- terra::aggregate(haut, fact = fact, fun = "mean", na.rm = TRUE)
  rens <- terra::aggregate(!is.na(chm), fact = fact, fun = "mean")
  part <- terra::resample(part, grid, method = "near")
  rens <- terra::resample(rens, grid, method = "near")
  foret <- terra::ifel(!is.na(part) & part >= min_share & rens >= 0.5, 1, NA)
  out <- c(foret, part)
  names(out) <- c("foret", "part_couvert")
  out
}

#' Grille de travail du mode réel
#'
#' Grille de `res` m (origine multiple de `res`, ADR 0007) sur l'intersection de
#' l'emprise et de la partie renseignée du MNT (les dalles traitées).
#'
#' @param emprise `sfc` de [real_extent()].
#' @param dtm `SpatRaster` du MNT (mosaïque).
#' @param res Résolution (m).
#' @return Un `SpatRaster` vide en EPSG:2154.
#' @examples
#' d <- terra::rast(xmin = 1015500, xmax = 1015580, ymin = 6793500, ymax = 6793580,
#'                  resolution = 5, crs = "EPSG:2154", vals = 1)
#' e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
#'                    ymax = 6805000), crs = sf::st_crs(2154)))
#' terra::ext(real_grid(e, d, 20))
#' @export
real_grid <- function(emprise, dtm, res) {
  assert_crs_2154(dtm)
  b <- .as_bbox(emprise)
  e <- terra::ext(terra::trim(dtm))
  xmin <- max(b[["xmin"]], e$xmin)
  xmax <- min(b[["xmax"]], e$xmax)
  ymin <- max(b[["ymin"]], e$ymin)
  ymax <- min(b[["ymax"]], e$ymax)
  if (xmin >= xmax || ymin >= ymax) stop("Le MNT ne recoupe pas l'emprise.", call. = FALSE)
  build_grid(c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax), res)
}

#' Maille de comparaison à la référence
#'
#' Plus petit multiple commun de `resolution_m` et de la maille de la référence (50 m) :
#' [compare_gradients()] exige un multiple entier de notre maille. 20 donne 100, 25 donne 50,
#' 30 donne 150 (ADR 0007).
#'
#' @param resolution_m Résolution de la grille (m), nombre entier positif.
#' @param ref_m Maille de la référence (m), 50 par défaut.
#' @return Un nombre (m).
#' @examples
#' comparison_res(20)
#' @export
comparison_res <- function(resolution_m, ref_m = 50) {
  ok <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x) && x > 0 && x == round(x)
  if (!ok(resolution_m) || !ok(ref_m)) {
    stop("`resolution_m` et `ref_m` doivent \u00eatre des entiers positifs (m).", call. = FALSE)
  }
  pgcd <- function(a, b) if (b == 0) a else pgcd(b, a %% b)
  resolution_m / pgcd(resolution_m, ref_m) * ref_m
}

#' Dérivés du terrain ramenés à la grille
#'
#' Calcule les dérivés de [derive_terrain()] sur le MNT à 5 m (avec MRVBF et réseau
#' hydrographique en mode réel), puis les agrège (moyenne) à la grille (ADR 0004). Le MNT
#' est d'abord bordé de `NA` sur le plus grand rayon du TPI (la fenêtre doit tenir dans
#' le raster, même sur une petite emprise), puis le résultat est rogné.
#'
#' @param dtm `SpatRaster` du MNT (5 m).
#' @param grid `SpatRaster` modèle.
#' @param streams Réseau (`sf` de lignes) ou `NULL`.
#' @param mrvbf Calculer le MRVBF (`TRUE` en mode réel).
#' @param tpi_radii Rayons du TPI (m).
#' @param mrvbf_res Maille (m) du calcul du MRVBF, passée à [derive_terrain()] (`mrvbf_res`,
#'   `mrvbf_res_m` de `config.yml`) ; `NULL` = maille du MNT.
#' @return Un `SpatRaster` sur `grid` : couches de [derive_terrain()] et `altitude`
#'   (couches éventuellement vides : voir [empty_layers()]).
#' @examples
#' \donttest{
#' f <- system.file("extdata", "synth_dtm.tif", package = "sylvostation")
#' d <- terra::rast(f)
#' g <- build_grid(terra::ext(d)[c(1, 3, 2, 4)], 20)
#' suppressWarnings(names(real_terrain(d, g, mrvbf = FALSE)))
#' }
#' @export
real_terrain <- function(dtm, grid, streams = NULL, mrvbf = TRUE, tpi_radii = c(100, 300),
                         mrvbf_res = NULL) {
  assert_crs_2154(grid)
  # marge de NA pour que la fenetre du plus grand TPI tienne dans le raster (petite emprise)
  n <- ceiling(max(tpi_radii) / terra::res(dtm)[1])
  d <- terra::extend(dtm, n)
  t5 <- derive_terrain(d, tpi_radii = tpi_radii, streams = streams, mrvbf = mrvbf,
                        mrvbf_res = mrvbf_res)
  t5 <- terra::crop(t5, dtm)
  alt <- dtm
  names(alt) <- "altitude"
  terra::resample(c(t5, alt), grid, method = "average")
}

#' Couches entièrement vides d'un raster
#'
#' Noms des couches sans aucune cellule renseignée (par exemple le MRVBF sans GRASS, un
#' TPI dont la fenêtre dépasse l'emprise, la hauteur au réseau sans cours d'eau). Elles
#' sont retirées des prédicteurs et déclarées dans l'état de preuve.
#'
#' @param r `SpatRaster`.
#' @return Un vecteur de noms (éventuellement vide).
#' @examples
#' r <- terra::rast(nrows = 2, ncols = 2, nlyrs = 2, crs = "EPSG:2154",
#'                  xmin = 1007000, xmax = 1007050, ymin = 6790000, ymax = 6790050)
#' terra::values(r) <- cbind(1:4, NA)
#' names(r) <- c("a", "b")
#' empty_layers(r)
#' @export
empty_layers <- function(r) {
  if (!inherits(r, "SpatRaster")) stop("`r` doit \u00eatre un SpatRaster.", call. = FALSE)
  n <- terra::global(!is.na(r), "sum")[, 1]
  names(r)[is.na(n) | n == 0]
}

#' Lire des fichiers SAFRAN (SIM2 quotidien)
#'
#' Lit un ou plusieurs CSV (`;`, décimale point, `.csv` ou `.csv.gz`) au format de
#' meteo.data.gouv.fr (docs/referentiels.md, § 23) et garde `LAMBX`, `LAMBY`, `DATE`,
#' `PRENEI`, `PRELIQ`, `ETP` et, s'ils existent, `T` (°C), `FF` (vent, m/s), `HU`
#' (humidité relative, %) et `SSI` (rayonnement, J/cm², cumul quotidien ; unités du
#' document « Données quotidiennes SIM » de Météo-France du 2026-03-31, mission 021).
#'
#' @param paths Chemins des fichiers.
#' @return Un `data.frame`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' length(unique(paste(s$LAMBX, s$LAMBY)))
#' @export
read_safran <- function(paths) {
  if (!is.character(paths) || !length(paths) || !all(file.exists(paths))) {
    stop("`paths` doit d\u00e9signer des fichiers SAFRAN existants.", call. = FALSE)
  }
  lire <- function(p) {
    d <- utils::read.csv2(p, dec = ".", stringsAsFactors = FALSE, check.names = FALSE,
                          colClasses = "character")
    req <- c("LAMBX", "LAMBY", "DATE", "PRENEI", "PRELIQ", "ETP")
    if (!all(req %in% names(d))) {
      stop("Colonnes SAFRAN absentes de ", basename(p), " : ",
           paste(setdiff(req, names(d)), collapse = ", "), call. = FALSE)
    }
    d <- d[, intersect(c(req, "T", "FF", "HU", "SSI"), names(d)), drop = FALSE]
    for (v in setdiff(names(d), "DATE")) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
    d
  }
  l <- lapply(paths, lire)
  cols <- Reduce(intersect, lapply(l, names))
  do.call(rbind, lapply(l, function(d) d[, cols, drop = FALSE]))
}

#' Télécharger SAFRAN (SIM2 quotidien) et garder les mailles d'une emprise
#'
#' Pour chaque année, télécharge (une fois, cache `cache_dir`) le fichier
#' `QUOT_SIM2_<année>.csv.gz` de meteo.data.gouv.fr (docs/referentiels.md, § 23,
#' Licence Ouverte 2.0, « Source : Météo-France »), garde les mailles dont le centre est
#' à moins d'une demi-diagonale de maille (5,7 km) de l'emprise, et écrit
#' `emprise_<année>.csv` dans le cache.
#'
#' @param years Années (vecteur d'entiers).
#' @param emprise Emprise (bbox, sf ou `c(xmin, ymin, xmax, ymax)`, EPSG:2154).
#' @param cache_dir Dossier de cache.
#' @param offline `TRUE` : aucun téléchargement (seul le cache sert).
#' @param downloader Voir [fetch_cached()].
#' @param lignes_par_bloc Lignes lues à la fois : le fichier (environ 137 Mo compressé,
#'   toute la France) est filtré à la lecture, jamais chargé en entier.
#' @return Les chemins des fichiers `emprise_<année>.csv`.
#' @examples
#' \dontrun{
#' fetch_safran(1996:2025, c(1007000, 6790000, 1022000, 6805000), "data/cache/safran")
#' }
#' @export
fetch_safran <- function(years, emprise, cache_dir, offline = FALSE,
                         downloader = utils::download.file, lignes_par_bloc = 200000L) {
  b <- .as_bbox(emprise)
  m <- 8000 * sqrt(2) / 2
  vapply(as.integer(years), function(y) {
    out <- file.path(cache_dir, sprintf("emprise_%d.csv", y))
    if (file.exists(out)) return(out)
    gz <- fetch_cached(sprintf(.URL_SAFRAN, y), cache_dir, offline, downloader)
    .filtrer_safran(gz, out, b, m, lignes_par_bloc)
  }, character(1))
}

# Lit un fichier SIM2 par blocs de lignes et n'ecrit que les mailles proches de la bbox
# `b` (a moins de `m` metres) : la France entiere n'est jamais chargee en memoire.
.filtrer_safran <- function(gz, out, b, m, lignes_par_bloc = 200000L) {
  con <- gzfile(gz, "r")
  on.exit(close(con), add = TRUE)
  entete <- readLines(con, n = 1L)
  tmp <- paste0(out, ".part")
  sortie <- file(tmp, "w")
  writeLines(entete, sortie)
  decision <- logical(0)  # maille -> garder ?
  repeat {
    l <- readLines(con, n = lignes_par_bloc)
    if (!length(l)) break
    cle <- sub("^([^;]*;[^;]*);.*$", "\\1", l)
    nouv <- setdiff(unique(cle), names(decision))
    if (length(nouv)) {
      k <- do.call(rbind, strsplit(nouv, ";", fixed = TRUE))
      ma <- .mailles_safran(data.frame(LAMBX = as.numeric(k[, 1]), LAMBY = as.numeric(k[, 2])))
      ok <- ma$x >= b[["xmin"]] - m & ma$x <= b[["xmax"]] + m &
        ma$y >= b[["ymin"]] - m & ma$y <= b[["ymax"]] + m
      decision <- c(decision, stats::setNames(ok, nouv))
    }
    garde <- unname(decision[cle])
    if (any(garde)) writeLines(l[garde], sortie)
  }
  close(sortie)
  file.rename(tmp, out)
  out
}

#' Climat kilométrique à partir de SAFRAN
#'
#' Pour chaque maille SAFRAN (8 km), moyenne sur les années des cumuls de la saison de
#' végétation (`months`, avril à septembre par défaut, **provisoire**) des
#' précipitations (`PRELIQ + PRENEI`, couche `p_sv`) et de l'ETP (`etp_sv`), et
#' température moyenne annuelle (`t_moy`, `NA` si la colonne `T` manque). Le raster
#' est construit en Lambert II étendu (EPSG:27572, grille SAFRAN) puis projeté en
#' Lambert-93 à `res` m.
#'
#' * `interpolation = "bilineaire"` (défaut, mission 033) : chaque cellule de `res` m
#'   reçoit l'interpolation bilinéaire des valeurs des mailles entre leurs centres
#'   ([safran_weights()]) : le champ est continu, sans saut aux limites des mailles.
#'   Lissé à l'échelle de 8 km, il reste un climat kilométrique (variable large),
#'   croisable avec les placettes IFN. Aucune correction d'altitude.
#' * `interpolation = "proche"` : plus proche voisin (comportement d'avant 033), la
#'   valeur de la maille est uniforme sur ses 8 km.
#'
#' @param safran `data.frame` de [read_safran()].
#' @param months Mois de la saison de végétation (4:9).
#' @param res Résolution du raster en Lambert-93 (1000 m, minimum pour l'IFN).
#' @param interpolation `"bilineaire"` (défaut) ou `"proche"`.
#' @return Un `SpatRaster` (EPSG:2154) : `p_sv`, `etp_sv`, `t_moy` ; attributs `months`
#'   et `interpolation`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' safran_climate(s)
#' @export
safran_climate <- function(safran, months = 4:9, res = 1000,
                           interpolation = c("bilineaire", "proche")) {
  interpolation <- match.arg(interpolation)
  if (!is.data.frame(safran) || !all(c("LAMBX", "LAMBY", "DATE") %in% names(safran))) {
    stop("`safran` doit venir de read_safran().", call. = FALSE)
  }
  if (!is.numeric(months) || !length(months) || any(!months %in% 1:12)) {
    stop("`months` doit contenir des mois de 1 \u00e0 12.", call. = FALSE)
  }
  m <- .climat_mailles(safran, months)   # R/climat.R
  x <- m$LAMBX * 100
  y <- m$LAMBY * 100
  r <- terra::rast(xmin = min(x) - 4000, xmax = max(x) + 4000, ymin = min(y) - 4000,
                   ymax = max(y) + 4000, resolution = 8000, crs = "EPSG:27572", nlyrs = 3)
  cel <- terra::cellFromXY(r, cbind(x, y))
  v <- matrix(NA_real_, terra::ncell(r), 3)
  v[cel, ] <- cbind(m$p, m$etp, m$T)
  terra::values(r) <- v
  names(r) <- c("p_sv", "etp_sv", "t_moy")
  out <- terra::project(r, "EPSG:2154", method = "near", res = res)
  if (interpolation == "bilineaire") out <- .climat_bilineaire(out, m)
  assert_crs_2154(out)
  attr(out, "months") <- months
  attr(out, "interpolation") <- interpolation
  out
}

#' Prédicteurs à maille large sur la grille
#'
#' Ramène le climat kilométrique sur la grille (bilinéaire) : `coarse_p_etp_sv`
#' (P - ETP de la saison de végétation) et `coarse_t_moy`. Les couches entièrement
#' `NA` sont retirées.
#'
#' @param climat `SpatRaster` de [safran_climate()].
#' @param grid `SpatRaster` modèle.
#' @return Un `SpatRaster` sur `grid`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' g <- build_grid(c(1015500, 6793500, 1015600, 6793600), 20)
#' names(coarse_predictors(safran_climate(s), g))
#' @export
coarse_predictors <- function(climat, grid) {
  assert_crs_2154(climat)
  assert_crs_2154(grid)
  if (is.null(terra::intersect(terra::ext(climat), terra::ext(grid)))) {
    stop("Le climat ne couvre pas la grille.", call. = FALSE)
  }
  cl <- c(climat[["p_sv"]] - climat[["etp_sv"]], climat[["t_moy"]])
  names(cl) <- c("coarse_p_etp_sv", "coarse_t_moy")
  cl <- terra::resample(terra::crop(cl, terra::ext(grid) + 2000, snap = "out"), grid,
                        method = "bilinear")
  vide <- is.na(terra::global(cl, "max", na.rm = TRUE)[, 1])
  if (all(vide)) stop("Le climat ne couvre pas la grille.", call. = FALSE)
  cl[[which(!vide)]]
}

#' Garder les placettes IFN d'une GRECO
#'
#' Le modèle régional est calibré sur les placettes de la GRECO (première lettre du
#' code SER, docs/referentiels.md § 1 ; colonne `GRECO` de `PLACETTE`).
#'
#' @param ifn Résultat de [load_ifn()].
#' @param greco Lettre de la GRECO.
#' @return `ifn` réduit (placettes, flore, arbres).
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' nrow(filter_greco(ifn, "D")$placettes)
#' @export
filter_greco <- function(ifn, greco) {
  .check_ifn(ifn, avec_flore = FALSE)
  if (!"GRECO" %in% names(ifn$placettes)) stop("Colonne GRECO absente.", call. = FALSE)
  pl <- ifn$placettes[ifn$placettes$GRECO %in% greco, ]
  if (!nrow(pl)) stop("Aucune placette IFN dans la GRECO ", greco, ".", call. = FALSE)
  ids <- pl$id_placette
  ifn$placettes <- pl
  if (is.data.frame(ifn$flore)) ifn$flore <- ifn$flore[ifn$flore$id_placette %in% ids, , drop = FALSE]
  if (is.data.frame(ifn$arbre)) ifn$arbre <- ifn$arbre[ifn$arbre$id_placette %in% ids, , drop = FALSE]
  ifn
}

#' Télécharger et décompresser l'archive des données brutes IFN
#'
#' Archive `export_dataifn_*.zip` (docs/referentiels.md § 7, Licence Ouverte 2.0),
#' mise en cache, puis extraction de `PLACETTE.csv`, `ECOLOGIE.csv`, `FLORE.csv` et
#' `ARBRE.csv` dans `cache_dir/ifn`.
#'
#' @param url Adresse de l'archive (`cfg$ifn_archive_url`).
#' @param cache_dir Dossier de cache.
#' @param offline,downloader Voir [fetch_cached()].
#' @return Le dossier des CSV, à passer à [load_ifn()].
#' @examples
#' \dontrun{
#' load_ifn(fetch_ifn(read_config()$ifn_archive_url, "data/cache"))
#' }
#' @export
fetch_ifn <- function(url, cache_dir, offline = FALSE, downloader = utils::download.file) {
  zip <- fetch_cached(url, cache_dir, offline, downloader)
  dir <- file.path(cache_dir, "ifn")
  fichiers <- c("PLACETTE.csv", "ECOLOGIE.csv", "FLORE.csv", "ARBRE.csv")
  if (!all(file.exists(file.path(dir, fichiers)))) {
    utils::unzip(zip, files = fichiers, exdir = dir)
  }
  dir
}

#' Lire la BD Charm-50 (formations géologiques) de plusieurs sources
#'
#' Lit des GeoPackage (extrait du dépôt) ou des archives départementales
#' `GEO050K_HARM_0DD.zip` (couche `S_FGEOL`, encodage WINDOWS-1252, CRS posé à 2154 :
#' docs/referentiels.md § 5), les réunit et les recoupe à l'emprise. Les départements
#' se joignent par `NOTATION`, jamais par `CODE`.
#'
#' @param paths Chemins des `.gpkg` ou des `.zip`.
#' @param emprise Emprise (EPSG:2154) ou `NULL`.
#' @return Un `sf` (EPSG:2154) avec `dep`, `CARTE`, `CODE`, `CODE_LEG`, `NOTATION`, `DESCR`.
#' @examples
#' g <- read_geology(system.file("extdata", "bdcharm50_emprise_test.gpkg",
#'                               package = "sylvostation"))
#' nrow(g)
#' @export
read_geology <- function(paths, emprise = NULL) {
  lire <- function(p) {
    if (grepl("\\.zip$", p, ignore.case = TRUE)) {
      d <- file.path(tempdir(), tools::file_path_sans_ext(basename(p)))
      utils::unzip(p, exdir = d)
      shp <- list.files(d, pattern = "S_FGEOL.*\\.shp$", recursive = TRUE, full.names = TRUE,
                        ignore.case = TRUE)
      if (length(shp) != 1L) stop("Couche S_FGEOL introuvable dans ", basename(p), call. = FALSE)
      x <- sf::st_read(shp, options = "ENCODING=WINDOWS-1252", quiet = TRUE)
      # le .prj ESRI n'est pas reconnu comme EPSG:2154 (referentiels, par. 5) : on le pose
      x <- suppressWarnings(sf::st_set_crs(x, 2154))
      x$dep <- sub("^.*_0?([0-9]{2,3})\\.zip$", "\\1", basename(p), ignore.case = TRUE)
    } else {
      x <- sf::st_read(p, quiet = TRUE)
    }
    x <- sf::st_make_valid(x)
    x[, intersect(c("dep", "CARTE", "CODE", "CODE_LEG", "NOTATION", "DESCR"), names(x))]
  }
  g <- do.call(rbind, lapply(paths, lire))
  assert_crs_2154(g)
  if (!is.null(emprise)) {
    box <- sf::st_as_sfc(.as_bbox(emprise))
    g <- suppressWarnings(sf::st_intersection(g, box))
  }
  g
}

#' Axe bioclimatique des placettes
#'
#' Le bioclimat combine le bilan hydrique climatique de la saison de végétation
#' (P - ETP) et la température moyenne (brief technique, étape 5). Ces deux variables
#' sont centrées-réduites sur les placettes, puis résumées par leur **premier axe
#' principal** (choix provisoire, mission 016), orienté pour que la valeur croisse avec
#' la température (« plus haut = plus chaud ») ; sans température, l'axe est
#' `-(P - ETP)` réduit (« plus haut = plus sec »).
#'
#' @param data Tableau avec `coarse_p_etp_sv` et, si possible, `coarse_t_moy`.
#' @return Une liste : `vars`, `center`, `scale`, `loadings`, `sens`, `variance_expliquee`.
#' @examples
#' d <- data.frame(coarse_p_etp_sv = c(100, 300, 500), coarse_t_moy = c(10, 8, 6))
#' bioclim_axis(d)$sens
#' @export
bioclim_axis <- function(data) {
  d <- .drop_geom(data)
  vars <- intersect(c("coarse_p_etp_sv", "coarse_t_moy"), names(d))
  vars <- vars[vapply(vars, function(v) any(!is.na(d[[v]])), logical(1))]
  if (!"coarse_p_etp_sv" %in% vars) stop("`coarse_p_etp_sv` absent ou vide.", call. = FALSE)
  m <- as.matrix(d[stats::complete.cases(d[, vars, drop = FALSE]), vars, drop = FALSE])
  if (nrow(m) < 3L) stop("Moins de 3 placettes avec climat.", call. = FALSE)
  ctr <- colMeans(m)
  sc <- apply(m, 2, stats::sd)
  sc[!is.finite(sc) | sc == 0] <- 1
  z <- sweep(sweep(m, 2, ctr), 2, sc, "/")
  if (length(vars) == 2L) {
    e <- eigen(stats::cov(z), symmetric = TRUE)
    l <- e$vectors[, 1]
    names(l) <- vars
    if (l[["coarse_t_moy"]] < 0) l <- -l
    if (l[["coarse_t_moy"]] == 0 && l[["coarse_p_etp_sv"]] > 0) l <- -l
    ve <- if (sum(e$values) > 0) e$values[1] / sum(e$values) else NA_real_
    sens <- "plus haut = plus chaud (axe 1 de P - ETP et T, centr\u00e9s-r\u00e9duits)"
  } else {
    l <- c(coarse_p_etp_sv = -1)
    ve <- 1
    sens <- "plus haut = plus sec (-(P - ETP) r\u00e9duit ; temp\u00e9rature absente)"
  }
  list(vars = vars, center = ctr, scale = sc, loadings = l, sens = sens,
       variance_expliquee = ve, statut = "provisoire (mission 016)")
}

#' Appliquer l'axe bioclimatique à un tableau ou à un raster
#'
#' @param x Tableau ou `SpatRaster` portant les couches de `axis$vars`.
#' @param axis Résultat de [bioclim_axis()].
#' @return Un vecteur numérique (tableau) ou un `SpatRaster` `bioclim`.
#' @examples
#' d <- data.frame(coarse_p_etp_sv = c(100, 300, 500), coarse_t_moy = c(10, 8, 6))
#' apply_bioclim(d, bioclim_axis(d))
#' @export
apply_bioclim <- function(x, axis) {
  v <- axis$vars
  if (inherits(x, "SpatRaster")) {
    if (!all(v %in% names(x))) stop("Couches absentes : ", paste(setdiff(v, names(x)), collapse = ", "), call. = FALSE)
    out <- Reduce(`+`, lapply(v, function(k) (x[[k]] - axis$center[[k]]) / axis$scale[[k]] *
                                axis$loadings[[k]]))
    names(out) <- "bioclim"
    return(out)
  }
  d <- .drop_geom(x)
  if (!all(v %in% names(d))) stop("Colonnes absentes : ", paste(setdiff(v, names(d)), collapse = ", "), call. = FALSE)
  Reduce(`+`, lapply(v, function(k) (d[[k]] - axis$center[[k]]) / axis$scale[[k]] *
                       axis$loadings[[k]]))
}

#' Gradients réels des placettes IFN (trophique, hydrique, bioclimatique)
#'
#' Enchaîne, sans aucune variable fine (règle des 700 m) : [compute_gradients()]
#' (niveau trophique par les valeurs indicatrices, climat kilométrique), la réserve utile
#' par la texture ([ru_from_texture()]) et la contrainte hydrique BILJOU
#' ([hydric_stress()], ADR 0006, « plus haut = plus humide »), puis l'axe bioclimatique
#' ([bioclim_axis()]).
#'
#' @param ifn Résultat de [filter_releves()].
#' @param indicateurs Résultat de [load_indicator_values()].
#' @param climat `SpatRaster` de [safran_climate()].
#' @param safran `data.frame` de [read_safran()].
#' @param ru_source Source de la réserve utile (`"euptf2"`, défaut ADR 0006).
#' @param annees Années SAFRAN gardées (`NULL` : toutes).
#' @param interpolation Séries SAFRAN aux placettes : `"bilineaire"` (défaut, mission 033)
#'   ou `"proche"` ([hydric_stress()]).
#' @return Un `sf` (une ligne par placette retenue avec flore) : `id_placette`,
#'   `source`, `loc_precision_m`, `grad_trophique`, `ru_mm`, `grad_hydrique`,
#'   `is_biljou`, `coarse_p_etp_sv`, `coarse_t_moy`, `bioclim`, `trophic`, `hydric`.
#'   Attributs `methode_hydrique`, `bioclim_axis`, `taxa_non_apparies`, `ru_source`.
#' @examples
#' \donttest{
#' if (all(vapply(c("euptf2", "soiltexture", "ranger"), requireNamespace, TRUE,
#'                quietly = TRUE))) {
#' ex <- system.file("extdata", package = "sylvostation")
#' ifn <- filter_releves(load_ifn(ex))
#' ind <- load_indicator_values("tichy", file.path(ex, "tichy_2023_extrait.csv"),
#'                              file.path(ex, "taxref_v18_extrait.csv"),
#'                              taxa = unique(ifn$flore$CD_REF))
#' s <- read_safran(file.path(ex, "safran_sim2_12mailles_extrait.csv"))
#' g <- suppressWarnings(ifn_real_gradients(ifn, ind, safran_climate(s), s))
#' summary(g$hydric)
#' }
#' }
#' @export
ifn_real_gradients <- function(ifn, indicateurs, climat, safran, ru_source = "euptf2",
                               annees = NULL, interpolation = "bilineaire") {
  ind <- as.data.frame(indicateurs)
  g <- compute_gradients(ifn, ind, climat)
  ru <- ru_from_texture(ifn$placettes, ru_source = ru_source)
  g$ru_mm <- ru$ru_mm[match(g$id_placette, ru$id_placette)]
  g <- g[!is.na(g$grad_trophique), ]
  h <- hydric_stress(g, safran, ru_col = "ru_mm", annees = annees, interpolation = interpolation)
  axis <- bioclim_axis(h)
  h$bioclim <- apply_bioclim(h, axis)
  h$trophic <- h$grad_trophique
  h$hydric <- h$grad_hydrique
  attr(h, "methode_hydrique") <- attr(h, "methode")
  attr(h, "bioclim_axis") <- axis
  attr(h, "taxa_non_apparies") <- attr(g, "taxa_non_apparies")
  attr(h, "ru_source") <- ru_source
  h
}

#' Observables de terrain des placettes IFN, pour la clé
#'
#' Variables **notées sur le terrain** par l'IFN (`ECOLOGIE`, docs/referentiels.md § 7),
#' renommées `obs_*` pour ne jamais être confondues avec des variables fines extraites
#' d'un raster : `obs_pente` (`PENT2`, %), `obs_topo` (`TOPO`, code), `obs_humus`
#' (`HUMUS`, code). Les codes restent ceux de l'IFN (nomenclature selon la campagne).
#'
#' @param placettes `ifn$placettes`.
#' @return Un `data.frame` : `id_placette`, `obs_pente`, `obs_topo`, `obs_humus`.
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' head(ifn_observables(ifn$placettes))
#' @export
ifn_observables <- function(placettes) {
  d <- .drop_geom(placettes)
  col <- function(v) if (v %in% names(d)) d[[v]] else rep(NA_character_, nrow(d))
  data.frame(id_placette = d$id_placette,
             obs_pente = suppressWarnings(as.numeric(col("PENT2"))),
             obs_topo = as.character(col("TOPO")),
             obs_humus = as.character(col("HUMUS")), stringsAsFactors = FALSE)
}

#' Matrice de présence de la flore IFN (placettes x espèces)
#'
#' @param flore `ifn$flore` (colonnes `id_placette`, `CD_REF`).
#' @param ids Placettes à garder, dans cet ordre.
#' @return Une matrice 0/1 (lignes = `ids`, colonnes = `CD_REF`).
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' dim(ifn_flora_matrix(ifn$flore, unique(ifn$flore$id_placette)[1:5]))
#' @export
ifn_flora_matrix <- function(flore, ids) {
  if (!is.data.frame(flore) || !all(c("id_placette", "CD_REF") %in% names(flore))) {
    stop("`flore` doit avoir les colonnes id_placette et CD_REF.", call. = FALSE)
  }
  f <- flore[flore$id_placette %in% ids, , drop = FALSE]
  m <- unclass(table(factor(f$id_placette, ids), f$CD_REF)) > 0
  storage.mode(m) <- "integer"
  m
}

#' Arbres IFN au format de [fertility_by_type()]
#'
#' @param arbre `ifn$arbre` (colonnes `id_placette`, `ESPAR`, `HTOT`, `AGE`,
#'   docs/referentiels.md § 7).
#' @return Un `data.frame` : `plot`, `species`, `height` (m), `age` (ans).
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' nrow(ifn_trees(ifn$arbre))
#' @export
ifn_trees <- function(arbre) {
  if (!is.data.frame(arbre) || !all(c("id_placette", "ESPAR", "HTOT", "AGE") %in% names(arbre))) {
    stop("`arbre` doit avoir les colonnes id_placette, ESPAR, HTOT, AGE.", call. = FALSE)
  }
  data.frame(plot = arbre$id_placette, species = as.character(arbre$ESPAR),
             height = suppressWarnings(as.numeric(arbre$HTOT)),
             age = suppressWarnings(as.numeric(arbre$AGE)), stringsAsFactors = FALSE)
}

#' Types de terrain des relevés GNSS
#'
#' Pour chaque relevé GNSS ([load_gnss()], une ligne par couple point-espèce) :
#' moyenne des valeurs indicatrices des espèces (niveau trophique = moyenne de `ph` et
#' `azote`, comme aux placettes ; humidité = `humidite`), bioclimat par [apply_bioclim()]
#' sur le climat kilométrique du point, puis type par les seuils et fusions du
#' catalogue. Le gradient hydrique de terrain est l'humidité bioindiquée, sur une autre
#' échelle que la carte (-Is) : seuls les axes trophique et bioclimatique sont donc
#' comparables tant que les deux échelles ne sont pas raccordées (à faire par Pascal).
#'
#' @param gnss `sf` de [load_gnss()] (colonnes `id`, `species`).
#' @param indicateurs Valeurs indicatrices (`nom`, `ph`, `azote`, `humidite`).
#' @param predictors `SpatRaster` des prédicteurs à maille large.
#' @param axis Résultat de [bioclim_axis()].
#' @return Un `sf` (un point par relevé) : `id`, `n_especes`, `trophic`, `humidite`,
#'   `bioclim`.
#' @examples
#' g <- load_gnss(system.file("extdata", "synth_gnss.csv", package = "sylvostation"))
#' ind <- data.frame(nom = c("Synthia alpha", "Synthia beta"), ph = 5, azote = 4, humidite = 6)
#' r <- terra::rast(xmin = 1009000, xmax = 1012000, ymin = 6794000, ymax = 6797000,
#'                  resolution = 1000, crs = "EPSG:2154", nlyrs = 2)
#' terra::values(r) <- cbind(300, 8); names(r) <- c("coarse_p_etp_sv", "coarse_t_moy")
#' ax <- list(vars = names(r), center = c(coarse_p_etp_sv = 300, coarse_t_moy = 8),
#'            scale = c(coarse_p_etp_sv = 1, coarse_t_moy = 1),
#'            loadings = c(coarse_p_etp_sv = -0.7, coarse_t_moy = 0.7))
#' gnss_field_gradients(g, ind, r, ax)
#' @export
gnss_field_gradients <- function(gnss, indicateurs, predictors, axis) {
  if (!inherits(gnss, "sf") || !all(c("id", "species") %in% names(gnss))) {
    stop("`gnss` doit venir de load_gnss() avec les colonnes id et species.", call. = FALSE)
  }
  assert_crs_2154(gnss)
  assert_no_fine_extract_on_ifn(gnss, axis$vars)
  ind <- as.data.frame(indicateurs)
  nom <- if ("nom" %in% names(ind)) ind$nom else ind$taxon
  j <- match(tolower(trimws(gnss$species)), tolower(trimws(nom)))
  d <- sf::st_drop_geometry(gnss)
  d$ph <- ind$ph[j]
  d$azote <- ind$azote[j]
  d$humidite <- if ("humidite" %in% names(ind)) ind$humidite[j] else NA_real_
  moy <- function(v) as.numeric(tapply(v, factor(d$id, unique(d$id)), mean, na.rm = TRUE))
  ids <- unique(d$id)
  pts <- gnss[match(ids, gnss$id), c("id", "loc_precision_m", "source")]
  pts$n_especes <- as.integer(tapply(!is.na(j), factor(d$id, ids), sum))
  pts$trophic <- rowMeans(cbind(moy(d$ph), moy(d$azote)), na.rm = TRUE)
  pts$humidite <- moy(d$humidite)
  for (v in c("trophic", "humidite")) pts[[v]][is.nan(pts[[v]])] <- NA_real_
  xy <- sf::st_coordinates(pts)  # x = est, y = nord
  cl <- terra::extract(predictors[[axis$vars]], xy)
  pts$bioclim <- apply_bioclim(cl, axis)
  pts
}

#' Légende des types du mode réel
#'
#' Ajoute à la légende de [type_raster()] la colonne logique `azonal`. Aucune station
#' azonale n'est reconnue par le pipeline à ce jour : `azonal = FALSE` partout (déclaré
#' dans les limites du rapport) ; tout type de moins de 1 % est donc fusionné par
#' [merge_rare()].
#'
#' @param legend `data.frame` (`id`, `type`).
#' @return `legend` avec `azonal`.
#' @examples
#' real_type_legend(data.frame(id = 1:2, type = c("T1-H1-B1", "T2-H1-B1")))
#' @export
real_type_legend <- function(legend) {
  if (!is.data.frame(legend) || !all(c("id", "type") %in% names(legend))) {
    stop("`legend` doit avoir les colonnes id et type.", call. = FALSE)
  }
  legend$azonal <- FALSE
  legend
}

#' Tableau « état de preuve » du mode réel
#'
#' Une ligne par étape : `etat` vaut `réel`, `réel réduit` (extrait réel de
#' `inst/extdata`, mode `offline: true`), `non exécuté`, `non atteint (entrée absente)`
#' (critère dont l'entrée manque : relevés GNSS) ou `sautée (entrée absente)` (étape
#' sautée : comparaison à la référence). Jamais `synthétique` : le mode réel n'utilise
#' aucun jeu fabriqué.
#'
#' @param f Liste de faits du run : `offline`, `ser_code`, `n_tiles`, `n_ifn`,
#'   `greco`, `mrvbf` (couche calculée ?), `empty_layers`, `hydro_n`, `methode_hydrique`, `n_gbif`
#'   (`NA` hors ligne), `soils` (logique), `forest_mask` (logique), `n_cells`,
#'   `n_types`, `key` (logique), `gnss` (logique), `reference` (logique),
#'   `taxref_version`, `safran_annees`, et pour la carte hydrique (mission 021) et `resolution_m` (m, `config.yml`)
#'   `methode_hydrique_carte`, `k_methode`, `ru_origine` (texte), `ecart_moyen_abs`,
#'   `ecart_max_abs`, `n_controle`. Sans `methode_hydrique_carte`, la ligne « 6 bis » dit
#'   que la carte n'a pas été calculée.
#' @return Un `data.frame` : `etape`, `etat`, `dans_ce_run`, `detail`.
#' @examples
#' evidence_table_real(list(offline = TRUE, ser_code = "D11", n_tiles = 1, n_ifn = 100,
#'                          gnss = FALSE, reference = FALSE))[, 1:2]
#' @export
evidence_table_real <- function(f) {
  g <- function(k, def = NA) if (is.null(f[[k]])) def else f[[k]]
  off <- isTRUE(g("offline"))
  reel <- if (off) "r\u00e9el r\u00e9duit" else "r\u00e9el"
  src <- if (off) " (extrait de inst/extdata, hors ligne)" else ""
  e <- function(etape, etat, detail, dans = "oui") {
    data.frame(etape = etape, etat = etat, dans_ce_run = dans, detail = detail,
               stringsAsFactors = FALSE)
  }
  n_gbif <- g("n_gbif")
  maille <- .res_txt(g("resolution_m"))
  rbind(
    e("1. Emprise et grille", reel,
      paste0("SER ", g("ser_code"), src, " ; grille ", maille, " sur les dalles trait\u00e9es.")),
    e("2. LiDAR HD et MNT", reel, paste0(g("n_tiles"), " dalle(s) LiDAR HD trait\u00e9e(s)", src,
                                         " ; MNT et MHC \u00e0 1 m, mosa\u00efque \u00e0 5 m.")),
    e("3. D\u00e9riv\u00e9s du terrain", reel,
      paste0("MRVBF ", if (isTRUE(g("mrvbf"))) "calcul\u00e9" else "non calcul\u00e9 (GRASS ou r.valley.bottom absent)",
             " ; r\u00e9seau BD TOPAGE : ", g("hydro_n"), " tron\u00e7on(s)",
             src, if (length(g("empty_layers", character(0))))
               paste0(" ; couches vides (retir\u00e9es) : ", paste(g("empty_layers"), collapse = ", ")) else "",
             ". Non utilis\u00e9s par les mod\u00e8les r\u00e9gionaux (r\u00e8gle des 700 m).")),
    e("4. G\u00e9ologie (BD Charm-50)", reel,
      paste0("Formations", src, " ; recodage lithologique provisoire, non valid\u00e9.")),
    e("5. Placettes IFN (lecture, filtres)", reel,
      paste0(g("n_ifn"), " placettes de la GRECO ", g("greco"), src, ", localis\u00e9es \u00e0 700 m.")),
    e("6. Gradients des placettes", reel,
      paste0("Trophique : valeurs indicatrices de Tich\u00fd et al. 2023 (TAXREF v", g("taxref_version"),
             ") ; hydrique : BILJOU sur SAFRAN (m\u00e9thode ", g("methode_hydrique"),
             ", ann\u00e9es ", g("safran_annees"), ") ; bioclimat : axe 1 de P - ETP (avril-septembre) et T.")),
    .evidence_hydric_grid(f, reel, e),
    if (off || is.na(n_gbif)) {
      e("7. Points d'ancrage (GBIF)", "non ex\u00e9cut\u00e9",
        "Hors ligne : pas d'extrait GBIF r\u00e9el (un DOI exige un t\u00e9l\u00e9chargement occ_download avec compte).",
        dans = "non")
    } else if (n_gbif == 0) {
      e("7. Points d'ancrage (GBIF)", "non atteint (aucune maille GBIF)",
        "Aucune maille de bioindication avec occurrence lisible sur l'emprise : ancrages vides, rien n'est substitu\u00e9.",
        dans = "non")
    } else {
      e("7. Points d'ancrage (GBIF)", "r\u00e9el", paste0(n_gbif, " maille(s) de bioindication."))
    },
    e("8. Sols", if (isTRUE(g("soils"))) "r\u00e9el" else "non ex\u00e9cut\u00e9",
      if (isTRUE(g("soils"))) "Couches de soil_paths empil\u00e9es sur la grille." else
        "Aucune couche de sols fournie (cl\u00e9 soil_paths absente) ; GlobalSoilMap introuvable (r\u00e9f\u00e9rentiels \u00a7 18).",
      dans = if (isTRUE(g("soils"))) "oui" else "non"),
    e("9. Masque forestier (MHC > 5 m)", if (isTRUE(g("forest_mask"))) reel else "non ex\u00e9cut\u00e9",
      paste0("Cellule ", maille, " foresti\u00e8re si au moins la moiti\u00e9 de ses pixels du MHC d\u00e9passe 5 m ",
             "(seuil provisoire) ; BD For\u00eat non branch\u00e9e. ", g("n_cells"), " cellule(s) foresti\u00e8re(s)."),
      dans = if (isTRUE(g("forest_mask"))) "oui" else "non"),
    e("10. Mod\u00e8les, validation crois\u00e9e spatiale, zone d'applicabilit\u00e9", reel,
      paste0("Composante r\u00e9gionale seulement : placettes IFN et pr\u00e9dicteurs \u00e0 maille large (climat SAFRAN). ",
             if (!is.null(f$methode_hydrique_carte)) paste0(
               "Hydrique : la carte est l'indice Istress ", maille, " calcul\u00e9 (ligne 6 bis) ; le mod\u00e8le ",
               "r\u00e9gional hydrique ne sert qu'\u00e0 la validation crois\u00e9e. ") else "",
             if (off || is.na(n_gbif) || n_gbif == 0) "Composante locale (pr\u00e9dicteurs fins, ancrages GBIF) non ex\u00e9cut\u00e9e." else
               "Composante locale trophique sur les ancrages GBIF.")),
    e("11. Typologie (seuils, fusion des types rares)", reel,
      paste0(g("n_types"), " type(s) ; seuils provisoires par quantiles ; aucun type azonal reconnu (azonal = FALSE).")),
    e("12. Caract\u00e9risation des types", reel, "Flore et arbres des placettes IFN de la GRECO."),
    e("13. Cl\u00e9 de d\u00e9termination terrain", if (isTRUE(g("key"))) reel else "non ex\u00e9cut\u00e9",
      if (isTRUE(g("key"))) "Observables not\u00e9s par l'IFN (pente, position, humus)." else
        "Moins de deux types parmi les placettes : cl\u00e9 non construite.",
      dans = if (isTRUE(g("key"))) "oui" else "non"),
    e("14. Validation statistique (validation crois\u00e9e spatiale)", reel,
      "R\u00b2 et RMSE par blocs des mod\u00e8les r\u00e9gionaux (trophique, hydrique) ; bioclimat calcul\u00e9, non mod\u00e9lis\u00e9."),
    if (isTRUE(g("gnss"))) {
      e("15. Validation th\u00e9matique par relev\u00e9s GNSS ind\u00e9pendants", "r\u00e9el",
        "Types de terrain des relev\u00e9s GNSS contre types pr\u00e9dits.")
    } else {
      e("15. Validation th\u00e9matique par relev\u00e9s GNSS ind\u00e9pendants", "non atteint (entr\u00e9e absente)",
        "Aucun relev\u00e9 GNSS fourni (cl\u00e9 gnss_path absente) : crit\u00e8re non atteint, rien n'est substitu\u00e9.",
        dans = "non")
    },
    if (isTRUE(g("reference"))) {
      e("16. Comparaison \u00e0 la r\u00e9f\u00e9rence AgroParisTech (\u00a7 9)", "r\u00e9el",
        "Corr\u00e9lation de rang et accord des codes \u00e0 trois chiffres.")
    } else {
      e("16. Comparaison \u00e0 la r\u00e9f\u00e9rence AgroParisTech (\u00a7 9)", "saut\u00e9e (entr\u00e9e absente)",
        "Rasters de la r\u00e9f\u00e9rence non fournis (cl\u00e9 reference_path absente) : \u00e9tape saut\u00e9e.",
        dans = "non")
    },
    e("17. Sorties et rapport", reel, "Fichiers sans pr\u00e9fixe synth_ (aucun jeu fabriqu\u00e9).")
  )
}

# Ligne « 6 bis » de l'etat de preuve : carte hydrique (mission 021).
.evidence_hydric_grid <- function(f, reel, e) {
  maille <- .res_txt(f$resolution_m)
  m <- f$methode_hydrique_carte
  etape <- "6 bis. Carte hydrique (BILJOU, rayonnement de la pente)"
  if (is.null(m)) {
    return(e(etape, "non ex\u00e9cut\u00e9", "Carte hydrique non calcul\u00e9e.", dans = "non"))
  }
  chiffre <- function(x) if (is.null(x) || !length(x) || is.na(x)) "NA" else format(signif(x, 3))
  quoi <- switch(m,
    biljou_topo = paste0("ETP de Penman (biljouR) sur le rayonnement SAFRAN (SSI, J/cm2) ",
                         "multipli\u00e9 par k (r.sun, ciel clair)"),
    biljou_climatique = paste0("repli : k = 1 (GRASS absent), ETP de Penman (biljouR) sur le ",
                               "rayonnement SAFRAN, sans modulation topographique"),
    climatique_etp_safran = paste0("repli : colonnes SAFRAN T, FF, HU ou SSI absentes, BILJOU ",
                                   "sur l'ETP SAFRAN, sans k"),
    repli_ru = "repli : SAFRAN ou biljouR absent, la r\u00e9serve utile tient lieu d'indice",
    m)
  # etat \u00ab repli \u00bb des que la carte n'est pas modulee par le rayonnement r.sun
  etat <- if (identical(m, "biljou_topo")) reel else "repli"
  e(etape, etat, paste0(
    "Istress ", maille, " = BILJOU(ETP, P et RU de la maille SAFRAN) ; m\u00e9thode ", m, " (", quoi,
    ") ; k : ", if (is.null(f$k_methode)) "NA" else f$k_methode,
    ". Plat de r\u00e9f\u00e9rence par la m\u00eame formule (k = 1). ",
    "RU uniforme par maille SAFRAN, provisoire : m\u00e9diane euptf2 des placettes IFN de la maille (",
    if (is.null(f$ru_origine)) "NA" else f$ru_origine,
    "), jamais modul\u00e9e par la topographie. \u00c9cart de la table au calcul direct (",
    chiffre(f$n_controle), " cellule(s) de contr\u00f4le) : moyen ", chiffre(f$ecart_moyen_abs),
    ", maximal ", chiffre(f$ecart_max_abs), " (unit\u00e9s d'Istress). ",
    "La couche hydric de la carte est -Istress ", maille, ". Placettes IFN : Istress sans k, sur la ",
    "RU de la placette (r\u00e8gle des 700 m) ; carte et placettes ne sont pas \u00e0 la m\u00eame ",
    "\u00e9chelle (RU de la placette contre m\u00e9diane de la maille, plat contre pente). ",
    "Les placettes IFN sont discr\u00e9tis\u00e9es avec les seuils de la carte hydrique alors que leur ",
    "Istress est calcul\u00e9 sans k : cet \u00e9cart d'\u00e9chelle peut d\u00e9placer des placettes d'un type ",
    "hydrique \u00e0 l'autre et changer les fusions de types rares (merge_rare) ; le calcul n'est ",
    "pas corrig\u00e9. TWI, MRVBF et ",
    "hauteur_reseau sont des pr\u00e9dicteurs du seul mod\u00e8le local trophique (ancrages GBIF) ; la ",
    "composante hydrique locale passe par Istress seul. Limites : (a) k en ciel clair appliqu\u00e9 au ",
    "rayonnement nuageux, contraste d'exposition surestim\u00e9 ; (b) ombres du relief hors de ",
    "l'emprise non vues au bord ; (c) le Penman de biljouR plafonne rg/rso \u00e0 1 : au-del\u00e0, le ",
    "terme de grandes ondes ne suit plus k ; (d) RU uniforme par maille, provisoire ; (e) aucune ",
    "validation fran\u00e7aise \u00e0 cette r\u00e9solution (adaptation non valid\u00e9e de Dyer 2009) ; apports lat\u00e9raux et ",
    "engorgement non capt\u00e9s. Valeurs provisoires : r\u00e9f\u00e9rentiels \u00a7 25.5."))
}

#' Points d'ancrage GBIF : mailles de bioindication et prédicteurs
#'
#' Centres des mailles de [grid_bioindication()] (`source = "gbif"`), niveau trophique
#' bioindiqué (moyenne de `ph` et `azote`, comme aux placettes) et extraction des
#' prédicteurs. La précision de localisation d'une maille (`loc_precision_m`) est
#' l'**incertitude maximale** des occurrences qu'elle contient (colonne `loc_precision_m`
#' de [clean_occ()]) ; une maille sans occurrence lisible est écartée (et comptée).
#' **La règle bloquante est appelée avant l'extraction**
#' ([assert_no_fine_extract_on_ifn()]) : une précision supérieure à 25 m l'arrête.
#'
#' @param cells `sf` de [grid_bioindication()] (colonnes `cell_id`, `ph`, `azote`).
#' @param occ `sf` de points de [clean_occ()] (colonne `loc_precision_m`), ceux qui ont
#'   servi à `cells`.
#' @param predictors `SpatRaster` des prédicteurs (fins et à maille large).
#' @return Un `sf` de points : `cell_id`, `source`, `loc_precision_m`, `n_occ_maille`,
#'   `trophic`, une colonne par couche de `predictors`. Attribut `n_ecartees`. Si aucune
#'   maille n'est bioindiquée : `sf` de 0 ligne aux mêmes colonnes et avertissement de
#'   classe `sylvostation_non_calcule` (l'aval, modèle trophique local, reste sauté).
#' @examples
#' cel <- sf::st_sf(cell_id = "a", ph = 5, azote = 4,
#'   geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(1015500, 6793500), c(1015550, 6793500),
#'   c(1015550, 6793550), c(1015500, 6793550), c(1015500, 6793500)))), crs = 2154))
#' occ <- sf::st_as_sf(data.frame(x = c(1015510, 1015520), y = 6793510,
#'                                loc_precision_m = c(5, 12)),
#'                     coords = c("x", "y"), crs = 2154)
#' r <- terra::rast(xmin = 1015500, xmax = 1015600, ymin = 6793500, ymax = 6793600,
#'                  resolution = 20, crs = "EPSG:2154", vals = 1)
#' names(r) <- "pente"
#' gbif_anchors(cel, occ, r)$loc_precision_m
#' @export
gbif_anchors <- function(cells, occ, predictors) {
  if (!inherits(cells, "sf") || !all(c("ph", "azote") %in% names(cells))) {
    stop("`cells` doit venir de grid_bioindication() (colonnes ph et azote).", call. = FALSE)
  }
  if (!inherits(occ, "sf") || !"loc_precision_m" %in% names(occ)) {
    stop("`occ` doit venir de clean_occ() (colonne loc_precision_m).", call. = FALSE)
  }
  assert_crs_2154(cells)
  assert_crs_2154(occ)
  j <- sf::st_intersects(cells, occ)
  prec <- vapply(j, function(i) {
    v <- suppressWarnings(as.numeric(occ$loc_precision_m[i]))
    if (!length(v) || anyNA(v)) NA_real_ else max(v)
  }, numeric(1))
  garde <- !is.na(prec)
  if (!any(garde)) {
    # aucune maille bioindiquee : resultat vide signale, pas d'erreur (mission 026)
    .warn_non_calcule(paste0("Aucune maille GBIF bioindiqu\u00e9e (", nrow(cells),
                             " maille(s), aucune avec occurrence lisible) : ancrages vides."))
    out <- sf::st_sf(
      cell_id = character(), source = character(), loc_precision_m = numeric(),
      n_occ_maille = integer(), trophic = numeric(),
      stats::setNames(rep(list(numeric()), length(names(predictors))), names(predictors)),
      geometry = sf::st_sfc(crs = sf::st_crs(cells)))
    attr(out, "n_ecartees") <- length(garde)
    return(out)
  }
  pts <- suppressWarnings(sf::st_centroid(cells[garde, ]))
  pts$source <- "gbif"
  pts$loc_precision_m <- prec[garde]
  pts$n_occ_maille <- lengths(j)[garde]
  assert_no_fine_extract_on_ifn(pts, names(predictors))
  pts$trophic <- rowMeans(cbind(pts$ph, pts$azote), na.rm = TRUE)
  pts$trophic[is.nan(pts$trophic)] <- NA_real_
  xy <- sf::st_coordinates(pts)  # x = est, y = nord
  v <- terra::extract(predictors, xy)
  out <- sf::st_as_sf(cbind(pts[, c("cell_id", "source", "loc_precision_m", "n_occ_maille",
                                    "trophic")], v))
  attr(out, "n_ecartees") <- sum(!garde)
  out
}

#' Fertilité par type, ou table vide si aucun arbre n'a d'âge
#'
#' Appelle [fertility_by_type()] ; si aucun arbre n'a à la fois une hauteur et un âge
#' (cas de l'extrait IFN du dépôt), renvoie une table vide avec l'attribut `motif`, au
#' lieu d'arrêter le pipeline.
#'
#' @param trees Résultat de [ifn_trees()].
#' @param types `data.frame` (`plot`, `type`).
#' @return Le résultat de [fertility_by_type()] ou un `data.frame` vide.
#' @examples
#' real_fertility(data.frame(plot = "a", species = "x", height = 20, age = NA),
#'                data.frame(plot = "a", type = "T1"))
#' @export
real_fertility <- function(trees, types) {
  ok <- !is.na(trees$height) & !is.na(trees$age) & trees$height > 0 & trees$age > 0
  if (!any(ok)) {
    out <- data.frame(species = character(), type = character(), n_plots = integer(),
                      fertilite_moy = numeric(), stringsAsFactors = FALSE)
    attr(out, "motif") <- "aucun arbre avec hauteur et \u00e2ge (AGE) renseign\u00e9s"
    return(out)
  }
  fertility_by_type(trees, types)
}

#' Réunir la table des types à la couche des polygones du GeoPackage
#'
#' [write_outputs()] écrit dans `types.gpkg` une couche de polygones `types` et une
#' table attributaire sans géométrie `table_types`. Une table sans géométrie n'a pas de
#' système de coordonnées : en mode réel, ses colonnes sont jointes (par `type`) aux
#' polygones, qui restent en EPSG:2154, puis la table est retirée du GeoPackage (elle
#' reste dans `types.csv`). Fonction d'écriture : modifie le fichier en place.
#'
#' @param path Chemin de `types.gpkg`.
#' @param type_table Table des types (colonne `type`).
#' @return `path`, de façon invisible.
#' @examples
#' f <- tempfile(fileext = ".gpkg")
#' p <- sf::st_sf(type_id = 1L, type = "T1",
#'   geometry = sf::st_sfc(sf::st_point(c(1015500, 6793500)), crs = 2154))
#' sf::st_write(p, f, layer = "types", quiet = TRUE)
#' sf::st_write(data.frame(type = "T1", n = 3), f, layer = "table_types", append = TRUE, quiet = TRUE)
#' write_types_gpkg_real(f, data.frame(type = "T1", n = 3))
#' sf::st_layers(f)$name
#' @export
write_types_gpkg_real <- function(path, type_table) {
  if (!file.exists(path)) stop("GeoPackage introuvable : ", path, call. = FALSE)
  if (!is.data.frame(type_table) || !"type" %in% names(type_table)) {
    stop("`type_table` doit avoir une colonne type.", call. = FALSE)
  }
  poly <- sf::st_read(path, layer = "types", quiet = TRUE)
  assert_crs_2154(poly)
  ajout <- setdiff(names(type_table), names(poly))
  if (length(ajout)) {
    poly <- cbind(poly, type_table[match(poly$type, type_table$type), ajout, drop = FALSE])
  }
  sf::st_write(poly, path, layer = "types", delete_layer = TRUE, quiet = TRUE)
  if ("table_types" %in% sf::st_layers(path)$name) {
    sf::st_delete(path, layer = "table_types", quiet = TRUE)
  }
  invisible(path)
}

#' Part de l'emprise non couverte par la géologie (départements BD Charm-50)
#'
#' La BD Charm-50 est téléchargée par département (`bdcharm_departements` de
#' config.yml, liste explicite faute de couche des départements vérifiée). Avec
#' `emprise: ser`, la SER peut déborder de ces départements : la fonction mesure la part
#' de l'emprise qu'aucune formation ne couvre et **avertit** au-delà de `tol`.
#'
#' @param geol `sf` de [read_geology()].
#' @param emprise `sf`/`sfc` (EPSG:2154), par exemple [real_extent()].
#' @param departements Départements lus (pour le message).
#' @param tol Part tolérée (0,01).
#' @return La part non couverte (0 à 1), de façon invisible.
#' @examples
#' g <- read_geology(system.file("extdata", "bdcharm50_emprise_test.gpkg",
#'                               package = "sylvostation"))
#' e <- sf::st_as_sfc(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000,
#'                                  ymax = 6805000), crs = sf::st_crs(2154)))
#' geology_coverage(g, e, c("067", "068", "088"))
#' @export
geology_coverage <- function(geol, emprise, departements = character(0), tol = 0.01) {
  assert_crs_2154(geol)
  e <- sf::st_union(sf::st_geometry(emprise))
  assert_crs_2154(e)
  couvert <- suppressWarnings(sf::st_intersection(sf::st_union(sf::st_make_valid(
    sf::st_geometry(geol))), e))
  a <- as.numeric(sf::st_area(e))
  ac <- if (length(couvert)) sum(as.numeric(sf::st_area(couvert))) else 0
  part <- max(0, 1 - ac / a)
  if (part > tol) {
    warning(sprintf("G\u00e9ologie : %.1f %% de l'emprise hors des d\u00e9partements BD Charm-50 lus (%s) ; compl\u00e9ter `bdcharm_departements` dans config.yml.",
                    100 * part, paste(departements, collapse = ", ")), call. = FALSE)
  }
  invisible(part)
}
