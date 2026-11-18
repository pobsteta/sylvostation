# Réseau hydrographique (BD TOPAGE, Sandre) et hauteur au-dessus du réseau (mission 014).
# Sources : docs/referentiels.md, § 16 (service, colonnes, ordre des axes, licence).

.TOPAGE_URL <- "https://services.sandre.eaufrance.fr/geo/topage2025"
.TOPAGE_LAYER_RE <- "^sa:TronconHydrographique_FXX_Topage[0-9]{4}$"

# Adresse d'une requête WFS 2.0.0 (paramètres encodés).
.wfs_url <- function(base, q) {
  paste0(base, "?", paste0(names(q), "=",
         vapply(q, utils::URLencode, "", reserved = TRUE), collapse = "&"))
}

# Lit dans le GetCapabilities le nom de la couche des tronçons de Métropole : le millésime
# est dans le nom (référentiels § 16), on ne le fige pas. Millésime le plus récent.
.topage_layer <- function(base = .TOPAGE_URL) {
  tmp <- tempfile(fileext = ".xml")
  on.exit(unlink(tmp), add = TRUE)
  url <- .wfs_url(base, c(SERVICE = "WFS", VERSION = "2.0.0", REQUEST = "GetCapabilities"))
  status <- utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  if (!identical(as.integer(status), 0L)) {
    stop("GetCapabilities de la BD TOPAGE impossible.", call. = FALSE)
  }
  txt <- paste(readLines(tmp, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  noms <- regmatches(txt, gregexpr("sa:TronconHydrographique_FXX_Topage[0-9]{4}", txt))[[1]]
  noms <- sort(unique(noms[grepl(.TOPAGE_LAYER_RE, noms)]), decreasing = TRUE)
  if (!length(noms)) {
    stop("Aucune couche de tron\u00e7ons de M\u00e9tropole dans le service TOPAGE.", call. = FALSE)
  }
  noms[1]
}

# Écarte les tronçons fictifs (colonne TronconFictifTH, référentiels § 16).
.filter_network <- function(x) {
  if ("TronconFictifTH" %in% names(x)) {
    x <- x[!(tolower(as.character(x$TronconFictifTH)) %in% "true"), , drop = FALSE]
  }
  x
}

#' Réseau hydrographique BD TOPAGE sur une emprise
#'
#' Lit les tronçons hydrographiques de la BD TOPAGE (Sandre) de Métropole par le
#' service WFS du Sandre (référentiels, § 16), filtrés par l'emprise en Lambert-93
#' (`BBOX=...,urn:ogc:def:crs:EPSG::2154`, x = est puis y = nord). Le nom de la couche,
#' qui porte le millésime, est lu dans le `GetCapabilities` (le plus récent). Le
#' service ne sert pas le JSON : la lecture se fait en GML. Les tronçons fictifs
#' (`TronconFictifTH`) sont écartés. **Pas de filtre sur la persistance** : la liste des
#' modalités de `PersistanceTH` n'a pas été lue (à vérifier), les cours d'eau
#' intermittents sont donc conservés.
#'
#' Avec `source = "file"`, la fonction lit un extrait local (aucun réseau) : c'est le
#' mode des tests (`inst/extdata/topage_troncons_extrait.gpkg`).
#'
#' @param emprise Objet `sf`/`sfc` en EPSG:2154, `bbox`, ou `c(xmin, ymin, xmax, ymax)`
#'   (x = est, y = nord, EPSG:2154), comme [build_grid()].
#' @param source `"wfs"` (réseau) ou `"file"` (lit `path`).
#' @param path Fichier vectoriel local si `source = "file"`.
#' @param taille_page Nombre de tronçons par requête.
#' @return Un `sf` de lignes en EPSG:2154 (colonnes TOPAGE : `CdOH`, `NatureTH`,
#'   `PersistanceTH`, `TronconFictifTH`...). Attribut `couche` : nom de la couche lue.
#' @examples
#' f <- system.file("extdata", "topage_troncons_extrait.gpkg", package = "sylvostation")
#' if (nzchar(f)) {
#'   r <- get_hydro_network(c(1015000, 6793000, 1016000, 6794000), source = "file", path = f)
#'   nrow(r)
#' }
#' @export
get_hydro_network <- function(emprise, source = c("wfs", "file"), path = NULL,
                              taille_page = 500L) {
  source <- match.arg(source)
  b <- .as_bbox(emprise)
  if (source == "file") {
    if (is.null(path) || !file.exists(path)) {
      stop("`path` doit d\u00e9signer un fichier existant avec source = \"file\".", call. = FALSE)
    }
    x <- sf::st_read(path, quiet = TRUE)
    if (is.na(sf::st_crs(x))) stop("Extrait sans syst\u00e8me de coordonn\u00e9es.", call. = FALSE)
    x <- sf::st_transform(x, 2154)
    x <- x[lengths(sf::st_intersects(x, sf::st_as_sfc(b))) > 0, , drop = FALSE]
    couche <- basename(path)
  } else {
    couche <- .topage_layer()
    fmt <- function(v) format(v, scientific = FALSE, trim = TRUE)
    bbox <- paste0(fmt(b[["xmin"]]), ",", fmt(b[["ymin"]]), ",", fmt(b[["xmax"]]), ",",
                   fmt(b[["ymax"]]), ",urn:ogc:def:crs:EPSG::2154")
    pages <- list()
    debut <- 0L
    repeat {
      q <- c(SERVICE = "WFS", VERSION = "2.0.0", REQUEST = "GetFeature",
             TYPENAMES = couche, SRSNAME = "urn:ogc:def:crs:EPSG::2154", BBOX = bbox,
             COUNT = taille_page, STARTINDEX = debut)
      tmp <- tempfile(fileext = ".gml")
      status <- utils::download.file(.wfs_url(.TOPAGE_URL, q), tmp, mode = "wb", quiet = TRUE)
      if (!identical(as.integer(status), 0L)) {
        unlink(tmp)
        stop("Requ\u00eate WFS BD TOPAGE impossible.", call. = FALSE)
      }
      p <- sf::st_read(tmp, quiet = TRUE)
      unlink(tmp)
      if (!nrow(p)) break
      pages[[length(pages) + 1L]] <- p
      if (nrow(p) < taille_page) break
      debut <- debut + taille_page
    }
    if (!length(pages)) {
      x <- sf::st_sf(CdOH = character(), geometry = sf::st_sfc(crs = 2154))
    } else {
      x <- do.call(rbind, pages)
    }
  }
  x <- .filter_network(x)
  assert_crs_2154(x)
  geom <- as.character(sf::st_geometry_type(x))
  if (nrow(x) && !all(geom %in% c("LINESTRING", "MULTILINESTRING"))) {
    stop("Le r\u00e9seau doit \u00eatre compos\u00e9 de lignes.", call. = FALSE)
  }
  attr(x, "couche") <- couche
  x
}

#' Hauteur au-dessus du réseau hydrographique
#'
#' HAND (*height above nearest drainage*) : pour chaque cellule du MNT, altitude moins celle
#' de la **première cellule du réseau** atteinte en suivant les directions d'écoulement D8
#' (les mêmes que `surface_drainee` de [derive_terrain()], **sans remplissage** des
#' cuvettes). Le réseau est rastérisé (cellules touchées). Résultat `NA` là où
#' l'écoulement n'atteint pas le réseau (cuvette, sortie du MNT, cellule en aval du
#' dernier point du réseau) ; **jamais négatif**, car l'écoulement descend. Variable
#' **fine** : jamais aux coordonnées des placettes IFN.
#'
#' @param dtm `SpatRaster` à une couche, EPSG:2154, maille carrée.
#' @param network Réseau de lignes (`sf` ou `SpatVector`, EPSG:2154), p. ex.
#'   [get_hydro_network()].
#' @return Un `SpatRaster` à une couche nommée `hauteur_reseau` (m, >= 0). Tout `NA` avec
#'   avertissement de classe `sylvostation_non_calcule` si aucun tronçon ne touche le MNT.
#' @examples
#' d <- terra::rast(nrows = 20, ncols = 20, xmin = 980000, xmax = 980500,
#'                  ymin = 6800000, ymax = 6800500, crs = "EPSG:2154")
#' terra::values(d) <- 500 + 0.1 * (terra::yFromCell(d, seq_len(terra::ncell(d))) - 6800000)
#' ln <- terra::vect(matrix(c(980000, 6800250, 980500, 6800250), ncol = 2, byrow = TRUE),
#'                   type = "lines", crs = "EPSG:2154")
#' height_above_network(d, ln)
#' @export
height_above_network <- function(dtm, network) {
  .check_dtm(dtm)
  if (inherits(network, "sf")) network <- terra::vect(network)
  if (!inherits(network, "SpatVector") || terra::geomtype(network) != "lines") {
    stop("`network` doit \u00eatre un SpatVector ou sf de lignes.", call. = FALSE)
  }
  assert_crs_2154(network)
  out <- .height_above_streams(dtm, network)
  names(out) <- "hauteur_reseau"
  out
}
