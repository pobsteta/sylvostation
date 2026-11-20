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
#'   `mrvbf_res_m` (maille en m du MNT sur lequel le MRVBF est calculé, multiple de 5 ;
#'   défaut `resolution_m` ; provisoire, à vérifier, mission 027), `lidar_block_size` (3), `lidar_buffer_m` (20), `lidar_ncores` (3),
#'   `taxref_version` (`"18"`, figée), `indicator_source` (`"tichy"`), `ru_source`
#'   (`"euptf2"`), `safran_annees` (1996-2025), `saison_vegetation` (mois 4 à 9),
#'   `bdcharm_departements`, `gbif_method` (`"search"`), `forest_mask` (`TRUE`),
#'   `forest_height_m` (5), `cache_dir`, la carte hydrique (mission 021,
#'   provisoires) : `solar_linke` (3), `solar_albedo` (0,2), `solar_step_h` (0,5),
#'   `hydric_pas_k` (0,02), `hydric_n_controle` (30), la descente d'échelle du climat
#'   (mission 033, provisoires) : `safran_interpolation` (`"bilineaire"` ou `"proche"`),
#'   `hydric_node_res_m` (1000), `ru_min_placettes` (5), la calibration sur la GRECO
#'   (mission 035, provisoires) : `litho_min_cover` (0,5), `litho_encoding_k` (10), `soilgrids_ph` (`TRUE`), `cv_block_m` (`NULL` : portée
#'   estimée de la réponse) `cv_block_sensibilite_m` (8 358 m) et `cv_min_blocs_par_pli` (4),
#'   les choix de la mission 039 : `climat_temperature` (`"corrigee"` ou `"bilineaire"`),
#'   `trophique_climat` (`"sans"` par défaut, décision de Pascal du 2026-11-20 ;
#'   options `"actuel"` et `"corrige"`), `ru_carte` (`"apprise"` ou `"maille"`), `mnt_large_res_m` (250),
#'   `bilan_lateral` (`FALSE`), `bilan_lateral_ru_mm` (−30, 0, 60) et `bilan_lateral_coef`
#'   (`NULL` : tableau 20 de Piedallu et al. 2006, à vérifier), l'entrée optionnelle
#'   `mnt_large_path` (MNT de 250 m local, mode hors ligne),
#'   `ifn_archive_url` et `taxref_url` (sans valeur
#'   par défaut : seule source, config.yml ; exigées en ligne), et les
#'   entrées optionnelles `gnss_path`, `reference_path`, `soil_paths`, `tichy_path`
#'   (`NULL` si absentes : jamais remplacées).
#' @examples
#' f <- tempfile(fileext = ".yml")
#' writeLines(c(
#'   'ser_code: "D11"',
#'   "emprise_test: {xmin: 1007000, ymin: 6790000, xmax: 1022000, ymax: 6805000, crs: 2154}",
#'   "buffer_m: 5000", "resolution_m: 20", "crs: 2154",
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
  # carte hydrique (mission 021), valeurs provisoires (referentiels § 25.5)
  solar_linke = 3, solar_albedo = 0.2, solar_step_h = 0.5, hydric_pas_k = 0.02,
  hydric_n_controle = 30L,
  # descente d'echelle du climat SAFRAN (mission 033), valeurs provisoires
  safran_interpolation = "bilineaire", hydric_node_res_m = 1000, ru_min_placettes = 5L,
  # calibration sur la GRECO (mission 035), valeurs provisoires : part minimale du disque de
  # 700 m couverte par la geologie, poids (en placettes) de la moyenne generale dans
  # l'encodage de la lithologie
  litho_min_cover = 0.5, litho_encoding_k = 10, soilgrids_ph = TRUE,
  # blocs de la validation croisee du pipeline : cv_block_m absent ou null = portee estimee
  # (le chiffre publie, le plus prudent) ; cv_block_sensibilite_m = taille de la sensibilite
  cv_block_sensibilite_m = 8358, cv_min_blocs_par_pli = 4,
  # controle par essence et sensibilite (mission 037) : valeurs provisoires, sans source, a
  # verifier (docs/referentiels.md, section 36)
  essence_part_pure = 0.75, essence_min_placettes = 15L, essence_alerte_ecart = 0.5,
  essence_alerte_ratio = 0.5, essence_alerte_pente = 0.2,
  bdforet_controle = FALSE, bdforet_tampon_m = 50, bdforet_min_polygones = 5L,
  # reprise sur incident reseau des telechargements (mission 026), provisoire
  download_retries = 3L,
  # bioclimat et RU plus fins (mission 039, arbitrages du 2026-11-20) : temperature corrigee du
  # relief par le gradient lu dans SAFRAN, MNT BD ALTI de 250 m, RU de carte apprise ; climat
  # retire du trophique (decision de Pascal du 2026-11-20) ; bilan lateral desactive
  climat_temperature = "corrigee", trophique_climat = "sans", ru_carte = "apprise",
  mnt_large_res_m = 250, bilan_lateral = FALSE, bilan_lateral_ru_mm = c(-30, 0, 60)
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
  # maille de calcul du MRVBF (mission 027) : par defaut celle de la grille
  if (is.null(cfg$mrvbf_res_m)) cfg$mrvbf_res_m <- cfg$resolution_m
  if (!is.numeric(cfg$mrvbf_res_m) || length(cfg$mrvbf_res_m) != 1L ||
      !is.finite(cfg$mrvbf_res_m) || cfg$mrvbf_res_m <= 0) {
    stop("`mrvbf_res_m` doit \u00eatre un nombre strictement positif (m).", call. = FALSE)
  }
  logique("offline")
  logique("forest_mask")
  logique("soilgrids_ph")
  logique("bdforet_controle")
  est_chaine_cfg <- function(x) is.character(x) && length(x) == 1L && !is.na(x)
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
  if (!est_chaine_cfg(cfg$safran_interpolation) ||
      !cfg$safran_interpolation %in% c("bilineaire", "proche")) {
    stop("`safran_interpolation` doit valoir bilineaire ou proche.", call. = FALSE)
  }
  x <- cfg$hydric_node_res_m
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
    stop("`hydric_node_res_m` doit \u00eatre un nombre > 0 (m).", call. = FALSE)
  }
  entier_pos("ru_min_placettes")
  x <- cfg$litho_min_cover
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0 || x > 1) {
    stop("`litho_min_cover` doit \u00eatre un nombre dans [0, 1].", call. = FALSE)
  }
  for (k in c("cv_block_m", "cv_block_sensibilite_m")) {
    x <- cfg[[k]]
    if (!is.null(x) && (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0)) {
      stop("`", k, "` doit \u00eatre un nombre > 0 (m) ou null.", call. = FALSE)
    }
  }
  x <- cfg$cv_min_blocs_par_pli
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop("`cv_min_blocs_par_pli` doit \u00eatre un nombre >= 0.", call. = FALSE)
  }
  x <- cfg$litho_encoding_k
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop("`litho_encoding_k` doit \u00eatre un nombre >= 0.", call. = FALSE)
  }
  cfg$ru_min_placettes <- as.integer(cfg$ru_min_placettes)
  x <- cfg$essence_part_pure
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0.5 || x > 1) {
    stop("`essence_part_pure` doit \u00eatre un nombre dans ]0,5 ; 1].", call. = FALSE)
  }
  for (k in c("essence_alerte_ecart", "essence_alerte_ratio", "essence_alerte_pente",
              "bdforet_tampon_m")) {
    x <- cfg[[k]]
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
      stop("`", k, "` doit \u00eatre un nombre >= 0.", call. = FALSE)
    }
  }
  for (k in c("essence_min_placettes", "bdforet_min_polygones")) {
    entier_pos(k)
    cfg[[k]] <- as.integer(cfg[[k]])
  }
  x <- cfg$download_retries
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 1 || x != round(x)) {
    stop("`download_retries` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  cfg$download_retries <- as.integer(x)
  logique("bilan_lateral")
  choix <- list(climat_temperature = c("corrigee", "bilineaire"),
                trophique_climat = c("actuel", "corrige", "sans"),
                ru_carte = c("apprise", "maille"))
  for (k in names(choix)) {
    if (!est_chaine_cfg(cfg[[k]]) || !cfg[[k]] %in% choix[[k]]) {
      stop("`", k, "` doit valoir ", paste(choix[[k]], collapse = ", "), ".", call. = FALSE)
    }
  }
  x <- cfg$mnt_large_res_m
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 250) {
    stop("`mnt_large_res_m` doit \u00eatre un nombre >= 250 (m, maille large).", call. = FALSE)
  }
  x <- unlist(cfg$bilan_lateral_ru_mm)
  if (!is.numeric(x) || length(x) != 3L || anyNA(x)) {
    stop("`bilan_lateral_ru_mm` doit donner trois valeurs (mm) : d\u00e9part, \u00e9quilibre, apports.",
         call. = FALSE)
  }
  cfg$bilan_lateral_ru_mm <- as.numeric(x)
  if (!is.null(cfg$bilan_lateral_coef)) {
    cf <- cfg$bilan_lateral_coef
    nm <- c("constante", "curv150", "idr_1500", "moore")
    ok <- is.list(cf) && all(c("depart", "equilibre") %in% names(cf)) &&
      all(vapply(cf[c("depart", "equilibre")], function(z) all(nm %in% names(z)) &&
                   all(vapply(z[nm], is.numeric, logical(1))), logical(1)))
    if (!ok) {
      stop("`bilan_lateral_coef` doit donner depart et equilibre : ", paste(nm, collapse = ", "),
           ".", call. = FALSE)
    }
    cfg$bilan_lateral_coef <- lapply(cf[c("depart", "equilibre")], function(z) unlist(z[nm]))
  }
  v <- cfg$mnt_large_path
  if (!is.null(v) && (!is.character(v) || length(v) != 1L)) {
    stop("`mnt_large_path` doit \u00eatre un chemin ou absent.", call. = FALSE)
  }
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
