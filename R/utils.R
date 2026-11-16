#' Variables fines (interdites aux placettes IFN)
#'
#' Variables dont la résolution est bien plus fine que la précision de localisation
#' des placettes de l'IFN (700 m). La correspondance est insensible à la casse. Les
#' noms commençant par `lidar_`, `mnt_` ou `mhc_` sont aussi considérés comme fins.
#' @format Un vecteur de caractères.
#' @export
FINE_VARIABLES <- c(
  "pente", "exposition", "courbure", "courbure_plan", "courbure_profil",
  "tpi", "twi", "mrvbf", "hauteur_reseau", "rayonnement",
  "mnt", "mhc", "metriques_lidar",
  # couches de derive_terrain() (mission 005)
  "exposition_cos", "exposition_sin", "surface_drainee",
  "tpi_100", "tpi_300", "tpi_1000"
)

#' Variables à maille large (autorisées aux placettes IFN)
#'
#' Prédicteurs de maille kilométrique ou plus grossière. Une variable est aussi
#' « large » si son nom porte le préfixe `coarse_`.
#' @format Un vecteur de caractères.
#' @export
COARSE_VARIABLES <- c("climat_km", "pedopaysage", "geologie_700m")

.FINE_PREFIXES <- c("lidar_", "mnt_", "mhc_")

#' Marquer des points comme placettes IFN
#'
#' Pose `attr(x, "source") <- "ifn"` et, pour un tableau, deux colonnes :
#' `source = "ifn"` et `loc_precision_m = 700`. Les colonnes survivent aux
#' sous-ensembles, à `rbind` et aux jointures, l'attribut non toujours.
#'
#' @param x Un objet (`data.frame`, `sf`, ...).
#' @return `x`, marqué.
#' @examples
#' p <- mark_ifn(data.frame(x = 1, y = 2))
#' p$loc_precision_m
#' @export
mark_ifn <- function(x) {
  if (is.data.frame(x)) {
    x[["source"]] <- "ifn"
    x[["loc_precision_m"]] <- 700
  }
  attr(x, "source") <- "ifn"
  x
}

# TRUE si la précision de localisation n'est pas garantie <= max_precision_m
# (colonne absente, NA, ou trop grossière).
.precision_insuffisante <- function(points, max_precision_m) {
  if (!is.data.frame(points) || !"loc_precision_m" %in% names(points)) return(TRUE)
  p <- points[["loc_precision_m"]]
  if (!is.numeric(p) || anyNA(p)) return(TRUE)
  any(p > max_precision_m)
}

.is_ifn <- function(points) {
  a <- attr(points, "source", exact = TRUE)
  if (is.character(a) && length(a) == 1L && identical(tolower(a), "ifn")) return(TRUE)
  if (is.data.frame(points) && "source" %in% names(points)) {
    s <- points[["source"]]
    if (any(tolower(as.character(s)) == "ifn", na.rm = TRUE)) return(TRUE)
  }
  FALSE
}

.is_coarse <- function(v) {
  # Le préfixe `coarse_` est sensible à la casse (décision mission 011) :
  # `COARSE_climat` est traité comme fin ; COARSE_VARIABLES reste insensible à la casse.
  tolower(v) %in% tolower(COARSE_VARIABLES) || startsWith(v, "coarse_")
}

.is_fine <- function(v) {
  l <- tolower(v)
  !.is_coarse(v) &&
    (l %in% tolower(FINE_VARIABLES) || any(startsWith(l, .FINE_PREFIXES)))
}

#' Règle bloquante : pas d'extraction fine sans précision de localisation suffisante
#'
#' Les placettes de l'IFN sont localisées à 700 m près : y extraire une variable fine
#' (pente, TWI, LiDAR...) produirait un bruit pris pour un signal. La fonction
#' échoue si une variable fine est demandée et que `points` est marqué IFN (voir
#' [mark_ifn()]) **ou** que sa précision de localisation n'est pas garantie : colonne
#' `loc_precision_m` absente, `NA`, ou supérieure à `max_precision_m`. Ainsi le
#' blocage survit à un `rbind` ou à une jointure qui perdrait le marquage, et un
#' mélange de placettes IFN et de points précis est refusé en entier. Par prudence,
#' une variable ni connue comme large ni préfixée `coarse_` est traitée comme fine ; le
#' préfixe est **sensible à la casse** (`COARSE_climat` est traité comme fin). Une colonne
#' `source = "ifn"` seule suffit à bloquer. `variables = character(0)` ou `NULL` passe (rien
#' n'est extrait).
#' Toute fonction d'extraction doit l'appeler en premier.
#'
#' @param points Points à échantillonner (tableau avec colonne `loc_precision_m`).
#' @param variables Vecteur de noms de variables à extraire.
#' @param max_precision_m Précision maximale admise, en mètres (25 par défaut).
#' @return `TRUE` de façon invisible si l'extraction est permise.
#' @examples
#' p <- mark_ifn(data.frame(x = 1, y = 2))
#' assert_no_fine_extract_on_ifn(p, "coarse_climat")
#' try(assert_no_fine_extract_on_ifn(p, "pente"))
#' @export
assert_no_fine_extract_on_ifn <- function(points, variables, max_precision_m = 25) {
  if (is.null(variables)) variables <- character(0)
  if (!is.character(variables) || anyNA(variables)) {
    stop("`variables` doit \u00eatre un vecteur de caract\u00e8res sans NA.", call. = FALSE)
  }
  if (!is.numeric(max_precision_m) || length(max_precision_m) != 1L ||
      is.na(max_precision_m) || max_precision_m <= 0) {
    stop("`max_precision_m` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  est_fine <- vapply(variables, .is_fine, logical(1))
  est_large <- vapply(variables, .is_coarse, logical(1))
  fines <- variables[est_fine]
  inconnues <- variables[!est_fine & !est_large]
  if (!length(fines) && !length(inconnues)) return(invisible(TRUE))

  ifn <- .is_ifn(points)
  imprecis <- .precision_insuffisante(points, max_precision_m)
  if (ifn || imprecis) {
    msg <- if (ifn) {
      "Extraction interdite sur les placettes IFN (localis\u00e9es \u00e0 700 m pr\u00e8s)."
    } else {
      paste0("Extraction interdite : pr\u00e9cision de localisation (`loc_precision_m`) ",
             "absente, NA ou sup\u00e9rieure \u00e0 ", max_precision_m, " m.")
    }
    if (length(fines)) {
      msg <- paste0(msg, " Variables fines : ", paste(fines, collapse = ", "), ".")
    }
    if (length(inconnues)) {
      msg <- paste0(msg, " Variables non reconnues comme larges : ",
                    paste(inconnues, collapse = ", "), ".")
    }
    msg <- paste0(msg, " Seules les variables \u00e0 maille large (pr\u00e9fixe `coarse_` ",
                  "ou COARSE_VARIABLES) sont permises.")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Vérifier qu'un objet spatial est en Lambert-93
#'
#' Vérifie le code EPSG:2154, puis la plausibilité des coordonnées : l'emprise doit
#' tenir dans des bornes **approximatives** de la France métropolitaine en Lambert-93,
#' x (est) entre 0 et 1 300 000 et y (nord) entre 6 000 000 et 7 200 000 mètres. Cela
#' détecte les x/y inversés et les degrés étiquetés à tort en 2154.
#'
#' @param x Un objet `sf`, `sfc`, `SpatRaster` ou `SpatVector`.
#' @return `x` de façon invisible ; erreur si le CRS est absent, n'est pas EPSG:2154
#'   ou si les coordonnées sont implausibles.
#' @examples
#' p <- sf::st_sfc(sf::st_point(c(1010000, 6795000)), crs = 2154)
#' assert_crs_2154(p)
#' @export
assert_crs_2154 <- function(x) {
  if (inherits(x, c("sf", "sfc"))) {
    crs <- sf::st_crs(x)
  } else if (inherits(x, c("SpatRaster", "SpatVector"))) {
    wkt <- terra::crs(x)
    crs <- if (nzchar(wkt)) sf::st_crs(wkt) else sf::NA_crs_
  } else {
    stop("`x` doit \u00eatre un objet sf, sfc, SpatRaster ou SpatVector.", call. = FALSE)
  }
  if (is.na(crs)) stop("Syst\u00e8me de coordonn\u00e9es absent ; EPSG:2154 attendu.", call. = FALSE)
  if (!isTRUE(crs == sf::st_crs(2154))) {
    stop("Syst\u00e8me de coordonn\u00e9es incorrect (", crs$input,
         ") ; EPSG:2154 (Lambert-93) attendu.", call. = FALSE)
  }
  b <- if (inherits(x, c("sf", "sfc"))) {
    unname(as.numeric(sf::st_bbox(x))[c(1, 3, 2, 4)])
  } else {
    as.vector(terra::ext(x))
  }
  if (!anyNA(b) && (b[1] < 0 || b[2] > 1300000 || b[3] < 6000000 || b[4] > 7200000)) {
    stop("Coordonn\u00e9es implausibles pour du Lambert-93 m\u00e9tropolitain ",
         "(x = est dans [0 ; 1 300 000], y = nord dans [6 000 000 ; 7 200 000], ",
         "bornes approximatives) : x/y invers\u00e9s ou degr\u00e9s non reproject\u00e9s ? ",
         "Emprise : x [", format(b[1]), " ; ", format(b[2]), "], y [",
         format(b[3]), " ; ", format(b[4]), "].", call. = FALSE)
  }
  invisible(x)
}
