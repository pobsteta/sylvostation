#' Lire et valider la configuration
#'
#' Lit un fichier `config.yml` (paquet `yaml`) et vérifie les types, le système de
#' coordonnées (EPSG:2154 uniquement) et la cohérence de l'emprise.
#'
#' @param path Chemin du fichier YAML. Par défaut `"config.yml"`.
#' @return Une liste nommée : `ser_code`, `emprise_test` (xmin, ymin, xmax, ymax,
#'   crs), `buffer_m`, `resolution_m`, `crs`, `data_dir`, `laz_dir`, `out_dir`,
#'   `ifn_precision_m`, `demo` (booléen, `FALSE` si la clé est absente : en mode démo,
#'   le pipeline tourne sans réseau sur les jeux d'essai synthétiques de `inst/extdata`),
#'   et les clés du mode réel (mission 016, valeurs par défaut si absentes) : `offline`
#'   (`FALSE` ; `TRUE` = mode réel sans réseau sur les extraits réels de `inst/extdata`),
#'   `max_tiles` (`NULL` = toutes les dalles), `emprise` (`"test"` ou `"ser"`),
#'   `lidar_block_size` (3), `lidar_buffer_m` (20), `lidar_ncores` (3),
#'   `taxref_version` (`"18"`, figée), `indicator_source` (`"tichy"`), `ru_source`
#'   (`"euptf2"`), `safran_annees` (1996-2025), `saison_vegetation` (mois 4 à 9),
#'   `bdcharm_departements`, `gbif_method` (`"search"`), `forest_mask` (`TRUE`),
#'   `forest_height_m` (5), `cache_dir`, la carte hydrique de 25 m (mission 021,
#'   provisoires) : `solar_linke` (3), `solar_albedo` (0,2), `solar_step_h` (0,5),
#'   `hydric_pas_k` (0,02), `hydric_n_controle` (30), `ifn_archive_url` et `taxref_url` (sans valeur
#'   par défaut : seule source, config.yml ; exigées en ligne), et les
#'   entrées optionnelles `gnss_path`, `reference_path`, `soil_paths`, `tichy_path`
#'   (`NULL` si absentes : jamais remplacées).
#' @examples
#' f <- tempfile(fileext = ".yml")
#' writeLines(c(
#'   'ser_code: "D11"',
#'   "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
#'   "buffer_m: 5000", "resolution_m: 25", "crs: 2154",
#'   "data_dir: data", "laz_dir: data/laz", "out_dir: data/sorties",
#'   "ifn_precision_m: 700"), f)
#' read_config(f)$ser_code
#' @export
read_config <- function(path = "config.yml") {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Fichier de configuration introuvable : ", paste(path, collapse = ", "),
         call. = FALSE)
  }
  cfg <- yaml::read_yaml(path)
  if (!is.list(cfg)) {
    stop("Configuration illisible : une liste YAML est attendue.", call. = FALSE)
  }

  requis <- c("ser_code", "emprise_test", "buffer_m", "resolution_m", "crs",
              "data_dir", "laz_dir", "out_dir", "ifn_precision_m")
  manque <- setdiff(requis, names(cfg))
  if (length(manque)) {
    stop("Cl\u00e9s manquantes dans la configuration : ", paste(manque, collapse = ", "),
         call. = FALSE)
  }

  est_chaine <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  est_nombre <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)

  if (!est_chaine(cfg$ser_code)) {
    stop("`ser_code` doit \u00eatre une cha\u00eene non vide.", call. = FALSE)
  }
  for (k in c("data_dir", "laz_dir", "out_dir")) {
    if (!est_chaine(cfg[[k]])) stop("`", k, "` doit \u00eatre une cha\u00eene non vide.", call. = FALSE)
  }
  for (k in c("buffer_m", "resolution_m", "ifn_precision_m")) {
    if (!est_nombre(cfg[[k]]) || cfg[[k]] <= 0) {
      stop("`", k, "` doit \u00eatre un nombre strictement positif.", call. = FALSE)
    }
  }
  if (is.null(cfg$demo)) cfg$demo <- FALSE
  if (!is.logical(cfg$demo) || length(cfg$demo) != 1L || is.na(cfg$demo)) {
    stop("`demo` doit \u00eatre true ou false.", call. = FALSE)
  }
  if (!est_nombre(cfg$crs) || cfg$crs != 2154) {
    stop("`crs` doit valoir 2154 (Lambert-93) ; re\u00e7u : ",
         paste(format(cfg$crs), collapse = ", "), call. = FALSE)
  }

  e <- cfg$emprise_test
  cles <- c("xmin", "ymin", "xmax", "ymax", "crs")
  if (!is.list(e) || length(setdiff(cles, names(e)))) {
    stop("`emprise_test` doit contenir : ", paste(cles, collapse = ", "), call. = FALSE)
  }
  for (k in cles) {
    if (!est_nombre(e[[k]])) stop("`emprise_test$", k, "` doit \u00eatre un nombre.", call. = FALSE)
  }
  if (e$crs != 2154) {
    stop("`emprise_test$crs` doit valoir 2154 (Lambert-93).", call. = FALSE)
  }
  if (e$xmin >= e$xmax || e$ymin >= e$ymax) {
    stop("Emprise incoh\u00e9rente : il faut xmin < xmax et ymin < ymax ",
         "(x = est, y = nord).", call. = FALSE)
  }
  .config_reel(cfg)
}

# Valeurs par defaut et controle des cles du mode reel (mission 016). Une cle absente ou
# `null` prend la valeur par defaut ; les entrees optionnelles restent NULL.
.CONFIG_REEL_DEFAUTS <- list(
  offline = FALSE, emprise = "test", lidar_block_size = 3, lidar_buffer_m = 20,
  lidar_ncores = 3, taxref_version = "18", indicator_source = "tichy",
  ru_source = "euptf2", safran_annees = c(1996L, 2025L), saison_vegetation = c(4L, 9L),
  bdcharm_departements = c("067", "068", "088"), gbif_method = "search",
  forest_mask = TRUE, forest_height_m = 5, cache_dir = "data/cache",
  # carte hydrique de 25 m (mission 021), valeurs provisoires (referentiels § 25.5)
  solar_linke = 3, solar_albedo = 0.2, solar_step_h = 0.5, hydric_pas_k = 0.02,
  hydric_n_controle = 30L,
  # reprise sur incident reseau des telechargements (mission 026), provisoire
  download_retries = 3L
)

.config_reel <- function(cfg) {
  for (k in names(.CONFIG_REEL_DEFAUTS)) {
    if (is.null(cfg[[k]])) cfg[[k]] <- .CONFIG_REEL_DEFAUTS[[k]]
  }
  logique <- function(k) {
    if (!is.logical(cfg[[k]]) || length(cfg[[k]]) != 1L || is.na(cfg[[k]])) {
      stop("`", k, "` doit \u00eatre true ou false.", call. = FALSE)
    }
  }
  logique("offline")
  logique("forest_mask")
  entier_pos <- function(k, x = cfg[[k]]) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 1 || x != round(x)) {
      stop("`", k, "` doit \u00eatre un entier >= 1.", call. = FALSE)
    }
  }
  if (!is.null(cfg$max_tiles)) entier_pos("max_tiles")
  for (k in c("lidar_block_size", "lidar_ncores")) entier_pos(k)
  if (!is.numeric(cfg$lidar_buffer_m) || length(cfg$lidar_buffer_m) != 1L || cfg$lidar_buffer_m < 0) {
    stop("`lidar_buffer_m` doit \u00eatre un nombre >= 0.", call. = FALSE)
  }
  if (!is.numeric(cfg$forest_height_m) || length(cfg$forest_height_m) != 1L ||
      cfg$forest_height_m <= 0) {
    stop("`forest_height_m` doit \u00eatre un nombre > 0.", call. = FALSE)
  }
  for (k in c("solar_linke", "solar_albedo", "solar_step_h", "hydric_pas_k")) {
    x <- cfg[[k]]
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
      stop("`", k, "` doit \u00eatre un nombre > 0.", call. = FALSE)
    }
  }
  if (cfg$solar_albedo >= 1) stop("`solar_albedo` doit \u00eatre < 1.", call. = FALSE)
  x <- cfg$hydric_n_controle
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0 || x != round(x)) {
    stop("`hydric_n_controle` doit \u00eatre un entier >= 0.", call. = FALSE)
  }
  x <- cfg$download_retries
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 1 || x != round(x)) {
    stop("`download_retries` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  cfg$download_retries <- as.integer(x)
  if (!cfg$emprise %in% c("test", "ser")) {
    stop("`emprise` doit valoir test ou ser.", call. = FALSE)
  }
  cfg$taxref_version <- as.character(cfg$taxref_version)
  if (length(cfg$taxref_version) != 1L || !grepl("^[0-9]+(\\.[0-9]+)?$", cfg$taxref_version)) {
    stop("`taxref_version` doit \u00eatre un num\u00e9ro de version (par exemple \"18\").", call. = FALSE)
  }
  if (!identical(cfg$indicator_source, "tichy")) {
    stop("`indicator_source` : seule la source tichy est joignable (r\u00e9f\u00e9rentiels \u00a7 14).",
         call. = FALSE)
  }
  if (!cfg$ru_source %in% c("euptf2", "bruand2004")) {
    stop("`ru_source` doit valoir euptf2 ou bruand2004.", call. = FALSE)
  }
  if (!cfg$gbif_method %in% c("search", "download")) {
    stop("`gbif_method` doit valoir search ou download.", call. = FALSE)
  }
  a <- cfg$safran_annees
  if (!is.numeric(a) || length(a) != 2L || anyNA(a) || a[1] > a[2]) {
    stop("`safran_annees` doit \u00eatre [premi\u00e8re, derni\u00e8re] ann\u00e9e.", call. = FALSE)
  }
  m <- cfg$saison_vegetation
  if (!is.numeric(m) || length(m) != 2L || anyNA(m) || m[1] > m[2] || m[1] < 1 || m[2] > 12) {
    stop("`saison_vegetation` doit \u00eatre [premier, dernier] mois (1 \u00e0 12).", call. = FALSE)
  }
  cfg$bdcharm_departements <- sprintf("%03d", as.integer(unlist(cfg$bdcharm_departements)))
  for (k in c("gnss_path", "reference_path")) {
    v <- cfg[[k]]
    if (!is.null(v) && (!is.character(v) || length(v) != 1L)) {
      stop("`", k, "` doit \u00eatre un chemin ou absent.", call. = FALSE)
    }
  }
  if (!is.null(cfg$soil_paths) && !is.character(unlist(cfg$soil_paths))) {
    stop("`soil_paths` doit \u00eatre une liste de chemins ou absent.", call. = FALSE)
  }
  cfg
}
