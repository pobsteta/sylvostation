#' Lire et valider la configuration
#'
#' Lit un fichier `config.yml` (paquet `yaml`) et vérifie les types, le système de
#' coordonnées (EPSG:2154 uniquement) et la cohérence de l'emprise.
#'
#' @param path Chemin du fichier YAML. Par défaut `"config.yml"`.
#' @return Une liste nommée : `ser_code`, `emprise_test` (xmin, ymin, xmax, ymax,
#'   crs), `buffer_m`, `resolution_m`, `crs`, `data_dir`, `laz_dir`, `out_dir`,
#'   `ifn_precision_m`, `demo` (booléen, `FALSE` si la clé est absente : en mode démo,
#'   le pipeline tourne sans réseau sur les jeux d'essai synthétiques de `inst/extdata`).
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
  cfg
}
