# Emprise, grille et tableau d'assemblage LiDAR HD (mission 003).
# Sources : docs/referentiels.md, § 1 (SER) et § 2 (LiDAR HD).

.SER_URL <- "https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip"
.SER_ALLUVIAL_URL <- "https://inventaire-forestier.ign.fr/IMG/zip/ser_ar_l93.zip"
.LIDAR_WFS_URL <- "https://data.geopf.fr/wfs/ows"
.LIDAR_WFS_LAYER <- "IGNF_LIDAR-HD_METADONNEE:metadata"

# Télécharge `url` dans `dir` une seule fois (le fichier existant est conservé).
.download_once <- function(url, dir) {
  dest <- file.path(dir, basename(url))
  if (file.exists(dest) && file.size(dest) > 0) return(dest)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  old <- options(timeout = max(3600, getOption("timeout")))
  on.exit(options(old), add = TRUE)
  tmp <- paste0(dest, ".part")
  status <- utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  if (!identical(as.integer(status), 0L)) {
    unlink(tmp)
    stop("T\u00e9l\u00e9chargement impossible : ", url, call. = FALSE)
  }
  file.rename(tmp, dest)
  dest
}

# Lit une couche SER (zip ou shapefile en WINDOWS-1252, ou GeoPackage) en EPSG:2154.
.read_ser_layer <- function(path) {
  if (!file.exists(path)) stop("Fichier SER introuvable : ", path, call. = FALSE)
  ext <- tolower(tools::file_ext(path))
  if (ext == "zip") {
    contenu <- utils::unzip(path, list = TRUE)$Name
    shp <- contenu[grepl("\\.shp$", contenu, ignore.case = TRUE)]
    if (!length(shp)) stop("Aucun .shp dans l'archive : ", path, call. = FALSE)
    dsn <- paste0("/vsizip/", normalizePath(path), "/", shp[1])
    x <- sf::st_read(dsn, options = "ENCODING=WINDOWS-1252", quiet = TRUE)
  } else if (ext == "shp") {
    x <- sf::st_read(path, options = "ENCODING=WINDOWS-1252", quiet = TRUE)
  } else {
    x <- sf::st_read(path, quiet = TRUE)
  }
  if (is.na(sf::st_crs(x))) {
    stop("Couche SER sans syst\u00e8me de coordonn\u00e9es ; EPSG:2154 attendu.", call. = FALSE)
  }
  if (sf::st_crs(x) != sf::st_crs(2154)) x <- sf::st_transform(x, 2154)
  if (!all(c("codeser", "NomSER") %in% names(x))) {
    stop("Champs `codeser` et `NomSER` attendus dans la couche SER.", call. = FALSE)
  }
  x
}

#' Contour d'une sylvoécorégion (SER), avec tampon
#'
#' Lit la couche des SER de l'IGN (`ser_l93.zip`, 86 SER ; champs `codeser` et
#' `NomSER`, encodage WINDOWS-1252 ; voir `docs/referentiels.md`, § 1), en extrait la
#' SER demandée, réunit ses polygones et applique un tampon en mètres. Il n'existe pas
#' de service WFS pour les SER : le fichier est téléchargé une fois dans `data_dir`
#' (`source = "download"`), ou lu depuis `path` (`source = "file"`, pour les tests).
#' Avec `alluvial = TRUE`, la lecture porte sur la couche superposée des 5 SER
#' d'alluvions récentes (`ser_ar_l93.zip`, codes `L1` à `L5`).
#'
#' @param ser_code Code de la SER (par exemple `"D11"`).
#' @param buffer_m Tampon en mètres (EPSG:2154), 0 par défaut.
#' @param source `"download"` (télécharge ou réutilise le fichier de `data_dir`) ou
#'   `"file"` (lit `path`).
#' @param path Chemin d'un `.zip`, `.shp` ou `.gpkg` de SER (obligatoire si
#'   `source = "file"`).
#' @param data_dir Dossier de cache du téléchargement.
#' @param alluvial Lire la couche des alluvions récentes plutôt que celle des SER.
#' @return Un objet `sf` d'une ligne (`codeser`, `NomSER`, géométrie) en EPSG:2154.
#' @examples
#' f <- system.file("extdata", "ser_extrait.gpkg", package = "sylvostation")
#' if (nzchar(f)) get_ser("D11", buffer_m = 1000, source = "file", path = f)
#' @export
get_ser <- function(ser_code, buffer_m = 0, source = c("download", "file"),
                    path = NULL, data_dir = "data", alluvial = FALSE) {
  source <- match.arg(source)
  if (!is.character(ser_code) || length(ser_code) != 1L || is.na(ser_code)) {
    stop("`ser_code` doit \u00eatre un code de SER (texte, longueur 1).", call. = FALSE)
  }
  if (!is.numeric(buffer_m) || length(buffer_m) != 1L || is.na(buffer_m) || buffer_m < 0) {
    stop("`buffer_m` doit \u00eatre un nombre positif ou nul (m\u00e8tres).", call. = FALSE)
  }
  if (source == "file") {
    if (is.null(path)) stop("`path` est obligatoire avec source = \"file\".", call. = FALSE)
  } else {
    path <- .download_once(if (alluvial) .SER_ALLUVIAL_URL else .SER_URL, data_dir)
  }
  x <- .read_ser_layer(path)
  sel <- x[x$codeser == ser_code, ]
  if (!nrow(sel)) {
    valides <- sort(setdiff(unique(as.character(x$codeser)), "-1"))
    stop("SER \u00ab ", ser_code, " \u00bb absente de la couche. Codes disponibles : ",
         paste(valides, collapse = ", "), ".", call. = FALSE)
  }
  geom <- sf::st_union(sf::st_make_valid(sf::st_geometry(sel)))
  if (buffer_m > 0) geom <- sf::st_buffer(geom, buffer_m)
  out <- sf::st_sf(codeser = ser_code, NomSER = as.character(sel$NomSER[1]),
                   geometry = sf::st_sfc(geom[[1]], crs = 2154))
  assert_crs_2154(out)
  out
}

# Emprise (sf, sfc, bbox ou c(xmin, ymin, xmax, ymax)) -> bbox sf en EPSG:2154.
.as_bbox <- function(emprise) {
  if (inherits(emprise, c("sf", "sfc"))) {
    assert_crs_2154(emprise)
    return(sf::st_bbox(emprise))
  }
  if (inherits(emprise, "bbox")) {
    if (is.na(sf::st_crs(emprise))) {
      stop("Emprise (bbox) sans syst\u00e8me de coordonn\u00e9es ; EPSG:2154 attendu.", call. = FALSE)
    }
    assert_crs_2154(sf::st_as_sfc(emprise))
    return(emprise)
  }
  if (is.numeric(emprise) && length(emprise) == 4L && !anyNA(emprise)) {
    if (!is.null(names(emprise))) {
      if (!all(c("xmin", "ymin", "xmax", "ymax") %in% names(emprise))) {
        stop("Emprise num\u00e9rique : noms attendus xmin, ymin, xmax, ymax.", call. = FALSE)
      }
      emprise <- emprise[c("xmin", "ymin", "xmax", "ymax")]
    }
    b <- sf::st_bbox(c(xmin = emprise[[1]], ymin = emprise[[2]],
                       xmax = emprise[[3]], ymax = emprise[[4]]), crs = sf::st_crs(2154))
    if (b[["xmax"]] <= b[["xmin"]] || b[["ymax"]] <= b[["ymin"]]) {
      stop("Emprise vide ou invers\u00e9e (ordre attendu : xmin, ymin, xmax, ymax ; ",
           "x = est, y = nord).", call. = FALSE)
    }
    assert_crs_2154(sf::st_as_sfc(b))
    return(b)
  }
  stop("`emprise` doit \u00eatre un objet sf/sfc, une bbox ou c(xmin, ymin, xmax, ymax) ",
       "en EPSG:2154.", call. = FALSE)
}

#' Grille vide alignée sur des multiples de la résolution
#'
#' Crée un `SpatRaster` vide (sans valeurs) en Lambert-93 couvrant l'emprise, dont les
#' bords sont arrondis vers l'extérieur à des multiples de `res`. Ainsi deux grilles de
#' même résolution se superposent cellule à cellule, quelle que soit l'emprise.
#'
#' @param emprise Un objet `sf`/`sfc` en EPSG:2154, une `bbox` de [sf::st_bbox()], ou
#'   un vecteur `c(xmin, ymin, xmax, ymax)` (x = est, y = nord, mètres, EPSG:2154).
#' @param res Résolution en mètres (cellules carrées).
#' @return Un `SpatRaster` d'une couche, vide, en EPSG:2154.
#' @examples
#' g <- build_grid(c(xmin = 1007003, ymin = 6790010, xmax = 1007180, ymax = 6790099), res = 25)
#' terra::ext(g)
#' @export
build_grid <- function(emprise, res) {
  if (!is.numeric(res) || length(res) != 1L || is.na(res) || res <= 0) {
    stop("`res` doit \u00eatre un nombre strictement positif (m\u00e8tres).", call. = FALSE)
  }
  b <- .as_bbox(emprise)
  xmin <- floor(b[["xmin"]] / res) * res
  xmax <- ceiling(b[["xmax"]] / res) * res
  ymin <- floor(b[["ymin"]] / res) * res
  ymax <- ceiling(b[["ymax"]] / res) * res
  r <- terra::rast(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                   resolution = res, crs = "EPSG:2154")
  assert_crs_2154(r)
  r
}

# Construit le tableau des dalles à partir de la métadonnée brute (sf) et de l'emprise.
.tiles_from_meta <- function(meta, emprise) {
  requis <- c("coordonnees_nw", "url_npl", "url_mnt", "date_debut_acquisition",
              "date_fin_acquisition", "nombre_points")
  manque <- setdiff(requis, names(meta))
  if (length(manque)) {
    stop("Champs manquants dans la m\u00e9tadonn\u00e9e LiDAR HD : ",
         paste(manque, collapse = ", "), ".", call. = FALSE)
  }
  meta <- sf::st_transform(meta, 2154)
  zone <- if (inherits(emprise, c("sf", "sfc"))) {
    sf::st_union(sf::st_geometry(emprise))
  } else {
    sf::st_as_sfc(.as_bbox(emprise))
  }
  # Le BBOX/WITHIN ramène des voisines : on ne garde que les dalles qui recoupent l'emprise
  # rétrécie de 1 m (les dalles qui ne font que toucher le bord, au décalage de géométrie
  # près de quelques millimètres, sont exclues).
  zone_int <- sf::st_buffer(zone, -1)
  garde <- if (all(sf::st_is_empty(zone_int))) {
    sf::st_intersects(sf::st_geometry(meta), zone, sparse = FALSE)[, 1]
  } else {
    sf::st_intersects(sf::st_geometry(meta), zone_int, sparse = FALSE)[, 1]
  }
  meta <- meta[garde, ]
  out <- sf::st_sf(
    tile_id = as.character(meta$coordonnees_nw),
    url = as.character(meta$url_npl),
    url_mnt = as.character(meta$url_mnt),
    date_debut = as.Date(meta$date_debut_acquisition),
    date_fin = as.Date(meta$date_fin_acquisition),
    nombre_points = as.numeric(meta$nombre_points),
    geometry = sf::st_geometry(meta)
  )
  out <- out[order(out$tile_id), ]
  rownames(out) <- NULL
  out
}

# Lit le tableau d'assemblage par le WFS de la Géoplateforme (pages de 500 dalles).
.fetch_tiles_wfs <- function(bbox, marge = 1010, taille_page = 500L) {
  b <- c(xmin = bbox[["xmin"]] - marge, ymin = bbox[["ymin"]] - marge,
         xmax = bbox[["xmax"]] + marge, ymax = bbox[["ymax"]] + marge)
  poly <- sprintf("POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))",
                  b[["xmin"]], b[["ymin"]], b[["xmax"]], b[["ymin"]],
                  b[["xmax"]], b[["ymax"]], b[["xmin"]], b[["ymax"]],
                  b[["xmin"]], b[["ymin"]])
  cql <- sprintf("WITHIN(geom,SRID=2154;%s)", poly)
  pages <- list()
  debut <- 0L
  repeat {
    q <- c(SERVICE = "WFS", VERSION = "2.0.0", REQUEST = "GetFeature",
           TYPENAMES = .LIDAR_WFS_LAYER, SRSNAME = "EPSG:2154",
           OUTPUTFORMAT = "application/json", SORTBY = "coordonnees_nw",
           COUNT = taille_page, STARTINDEX = debut, CQL_FILTER = cql)
    url <- paste0(.LIDAR_WFS_URL, "?",
                  paste0(names(q), "=", vapply(q, utils::URLencode, "", reserved = TRUE),
                         collapse = "&"))
    tmp <- tempfile(fileext = ".json")
    status <- utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
    if (!identical(as.integer(status), 0L)) {
      unlink(tmp)
      stop("Requ\u00eate WFS LiDAR HD impossible.", call. = FALSE)
    }
    p <- sf::st_read(tmp, quiet = TRUE)
    unlink(tmp)
    if (!nrow(p)) break
    pages[[length(pages) + 1L]] <- p
    if (nrow(p) < taille_page) break
    debut <- debut + taille_page
  }
  if (!length(pages)) return(NULL)
  do.call(rbind, pages)
}

#' Tableau d'assemblage LiDAR HD sur une emprise
#'
#' Interroge la couche `IGNF_LIDAR-HD_METADONNEE:metadata` de la Géoplateforme
#' (WFS, `CQL_FILTER=WITHIN(...)` : le BBOX déborde sur les voisines ; voir
#' `docs/referentiels.md`, § 2), puis ne garde que les dalles qui recoupent
#' réellement l'emprise. L'identifiant d'une dalle est `coordonnees_nw` (« x_min en
#' km - y_max en km ») ; l'URL du nuage est lue dans `url_npl`, jamais reconstruite.
#'
#' @param emprise Un objet `sf`/`sfc` en EPSG:2154, une `bbox`, ou
#'   `c(xmin, ymin, xmax, ymax)` en EPSG:2154.
#' @param source `"wfs"` (réseau) ou `"file"` (lit `path`, une extraction de la
#'   métadonnée, pour les tests).
#' @param path Fichier de métadonnée (GeoJSON, GeoPackage...) si `source = "file"`.
#' @return Un `sf` (EPSG:2154) : `tile_id`, `url` (nuage COPC LAZ), `url_mnt` (MNT IGN
#'   de contrôle), `date_debut`, `date_fin` (dates de vol), `nombre_points`.
#' @examples
#' \dontrun{
#' list_tiles(c(xmin = 1014000, ymin = 6793000, xmax = 1016000, ymax = 6795000))
#' }
#' @export
list_tiles <- function(emprise, source = c("wfs", "file"), path = NULL) {
  source <- match.arg(source)
  bbox <- .as_bbox(emprise)
  if (source == "file") {
    if (is.null(path)) stop("`path` est obligatoire avec source = \"file\".", call. = FALSE)
    meta <- sf::st_read(path, quiet = TRUE)
  } else {
    meta <- .fetch_tiles_wfs(bbox)
    if (is.null(meta)) {
      stop("Aucune dalle LiDAR HD renvoy\u00e9e par le WFS pour cette emprise.", call. = FALSE)
    }
  }
  out <- .tiles_from_meta(meta, emprise)
  if (!nrow(out)) stop("Aucune dalle LiDAR HD ne recoupe l'emprise.", call. = FALSE)
  out
}
