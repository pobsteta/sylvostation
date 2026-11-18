# Plan d'echantillonnage des releves floristiques GNSS (mission 029).
# Sources : docs/referentiels.md, par. 29 (BD TOPO, troncons de route) et par. 30 (paquet clhs) ;
# methode : docs/echantillonnage.md.

.BDTOPO_WFS <- "https://data.geopf.fr/wfs/ows"
.BDTOPO_ROUTES <- "BDTOPO_V3:troncon_de_route"

#' Natures de tronçons BD TOPO retenues comme accès
#'
#' Valeurs du champ `nature` de `BDTOPO_V3:troncon_de_route` lues au WFS sur l'emprise test
#' le 2026-11-18 (docs/referentiels.md, § 29) : routes (à une ou deux chaussées, bretelles,
#' ronds-points), routes empierrées et chemins. Les sentiers et escaliers sont exclus.
#' @format Un vecteur de caractères.
#' @export
ACCESS_NATURES <- c("Route \u00e0 1 chauss\u00e9e", "Route \u00e0 2 chauss\u00e9es",
                    "Bretelle", "Rond-point", "Route empierr\u00e9e", "Chemin")

#' Échelle de recouvrement de Braun-Blanquet
#'
#' Coefficients d'abondance-dominance de Braun-Blanquet : `r` (individu rare), `+` (peu
#' abondant, recouvrement très faible), puis `1` à `5` (recouvrement croissant, 5 : plus de
#' 75 %). Seuls codes admis dans le gabarit de saisie de la flore.
#' @format Un vecteur de caractères.
#' @export
BRAUN_BLANQUET <- c("r", "+", "1", "2", "3", "4", "5")

#' Grandes formes d'humus admises dans le gabarit de station
#'
#' Grandes formes seulement (Mull, Moder, Mor, Amphi, Tangel), **à vérifier** : le
#' Référentiel humus de l'AFES et Jabiol et al. n'ont pas été lus. Aucune sous-forme n'est
#' proposée.
#' @format Un vecteur de caractères.
#' @export
HUMUS_FORMS <- c("Mull", "Moder", "Mor", "Amphi", "Tangel")

# Seuil provisoire d'homogeneite du voisinage 3 x 3 : ecart-type local <= 0,5 fois
# l'ecart-type de la variable sur la foret (mission 029, decision du 2026-11-18).
.SD_RATIO_PROVISOIRE <- 0.5

# Colonnes du gabarit de la flore (une ligne par couple releve-espece).
.FLORE_COLS <- c("id", "x", "y", "loc_precision_m", "species", "cd_nom",
                 "rec_arborescente", "rec_arbustive", "rec_herbacee", "rec_muscinale",
                 "date", "observateur")
.FLORE_REC <- c("rec_arborescente", "rec_arbustive", "rec_herbacee", "rec_muscinale")

# Colonnes du gabarit de station (une ligne par releve).
.STATION_COLS <- c("id", "x", "y", "loc_precision_m", "n_mesures_gnss", "date",
                   "observateur", "id_plan", "rang_utilise", "humus",
                   "tariere_profondeur_cm", "tariere_refus", "photos", "remarque")

# Evalue `expr` avec la graine `seed` puis restaure l'etat du generateur (pas d'effet de bord).
.with_seed <- function(seed, expr) {
  env <- globalenv()
  had <- exists(".Random.seed", envir = env, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = env, inherits = FALSE) else NULL
  on.exit({
    if (had) assign(".Random.seed", old, envir = env)
    else if (exists(".Random.seed", envir = env, inherits = FALSE)) {
      rm(".Random.seed", envir = env)
    }
  }, add = TRUE)
  set.seed(seed)
  force(expr)
}

#' Tronçons de route de la BD TOPO sur une emprise
#'
#' Lit la couche `BDTOPO_V3:troncon_de_route` de la Géoplateforme (WFS 2.0.0, GeoJSON,
#' EPSG:2154 ; docs/referentiels.md, § 29), filtrée par l'emprise en Lambert-93
#' (`BBOX=...,urn:ogc:def:crs:EPSG::2154`, x = est puis y = nord), par pages. Avec
#' `source = "file"`, lit un extrait local (aucun réseau : mode des tests). Le résultat
#' est ensuite filtré par [filter_access()] si `filter = TRUE`.
#'
#' @param emprise Objet `sf`/`sfc` en EPSG:2154, `bbox`, ou `c(xmin, ymin, xmax, ymax)`.
#' @param source `"wfs"` (réseau) ou `"file"` (lit `path`).
#' @param path Fichier vectoriel local si `source = "file"`.
#' @param filter Appliquer [filter_access()] (`TRUE` par défaut).
#' @param taille_page Nombre de tronçons par requête.
#' @return Un `sf` de lignes en EPSG:2154.
#' @examples
#' l <- sf::st_sf(nature = "Chemin", geometry = sf::st_sfc(sf::st_linestring(
#'   rbind(c(1010000, 6795000), c(1010500, 6795000))), crs = 2154))
#' f <- tempfile(fileext = ".gpkg"); sf::st_write(l, f, quiet = TRUE)
#' nrow(get_access_network(c(1009000, 6794000, 1011000, 6796000), "file", f))
#' @export
get_access_network <- function(emprise, source = c("wfs", "file"), path = NULL,
                               filter = TRUE, taille_page = 5000L) {
  source <- match.arg(source)
  b <- .as_bbox(emprise)
  if (source == "file") {
    if (is.null(path) || !file.exists(path)) {
      stop("`path` doit d\u00e9signer un fichier existant avec source = \"file\".", call. = FALSE)
    }
    x <- sf::st_read(path, quiet = TRUE)
    if (is.na(sf::st_crs(x))) stop("Extrait sans syst\u00e8me de coordonn\u00e9es.", call. = FALSE)
    x <- sf::st_transform(x, 2154)
  } else {
    fmt <- function(v) format(v, scientific = FALSE, trim = TRUE)
    bbox <- paste0(fmt(b[["xmin"]]), ",", fmt(b[["ymin"]]), ",", fmt(b[["xmax"]]), ",",
                   fmt(b[["ymax"]]), ",urn:ogc:def:crs:EPSG::2154")
    pages <- list()
    debut <- 0L
    repeat {
      q <- c(SERVICE = "WFS", VERSION = "2.0.0", REQUEST = "GetFeature",
             TYPENAMES = .BDTOPO_ROUTES, SRSNAME = "EPSG:2154", BBOX = bbox,
             OUTPUTFORMAT = "application/json", COUNT = taille_page, STARTINDEX = debut)
      tmp <- tempfile(fileext = ".json")
      .download_retry(.wfs_url(.BDTOPO_WFS, q), tmp)
      p <- sf::st_read(tmp, quiet = TRUE)
      unlink(tmp)
      if (!nrow(p)) break
      pages[[length(pages) + 1L]] <- p
      if (nrow(p) < taille_page) break
      debut <- debut + as.integer(taille_page)
    }
    if (!length(pages)) {
      x <- sf::st_sf(nature = character(), geometry = sf::st_sfc(crs = 2154))
    } else {
      x <- do.call(rbind, pages)
      if ("cleabs" %in% names(x)) x <- x[!duplicated(x$cleabs), ]
    }
    x <- sf::st_set_crs(sf::st_zm(x), 2154)
  }
  # le BBOX du WFS deborde (referentiels, par. 2) : recoupe locale
  if (nrow(x)) x <- x[lengths(sf::st_intersects(x, sf::st_as_sfc(b))) > 0, , drop = FALSE]
  assert_crs_2154(x)
  if (isTRUE(filter)) x <- filter_access(x)
  x
}

#' Tronçons accessibles et accès restreint
#'
#' Garde les tronçons dont `nature` est dans `natures` ([ACCESS_NATURES]), en écartant
#' les tronçons fictifs (`fictif`), ceux qui ne sont pas « En service »
#' (`etat_de_l_objet`) et ceux dont `acces_vehicule_leger` vaut « Physiquement
#' impossible ». Ajoute la colonne logique `acces_restreint` : tronçon privé (`prive`),
#' « Restreint aux ayants droit » ou « A péage ». L'accès restreint est **signalé, pas
#' exclu** : l'autorisation se demande avant la sortie.
#'
#' @param x `sf` de tronçons BD TOPO (au moins la colonne `nature`).
#' @param natures Natures retenues.
#' @return `x` filtré, avec `acces_restreint` ; attribut `decompte` (tronçons lus et gardés
#'   par nature).
#' @examples
#' l <- sf::st_sf(nature = c("Chemin", "Sentier"), prive = c(TRUE, FALSE),
#'   geometry = sf::st_sfc(sf::st_linestring(rbind(c(1010000, 6795000), c(1010100, 6795000))),
#'                         sf::st_linestring(rbind(c(1010000, 6795100), c(1010100, 6795100))),
#'                         crs = 2154))
#' filter_access(l)
#' @export
filter_access <- function(x, natures = ACCESS_NATURES) {
  if (!inherits(x, "sf") || !"nature" %in% names(x)) {
    stop("`x` doit \u00eatre un sf avec la colonne `nature`.", call. = FALSE)
  }
  vrai <- function(v) !is.na(v) & tolower(as.character(v)) %in% c("true", "t", "1")
  col <- function(nm) if (nm %in% names(x)) x[[nm]] else rep(NA, nrow(x))
  avl <- as.character(col("acces_vehicule_leger"))
  etat <- as.character(col("etat_de_l_objet"))
  garde <- as.character(x$nature) %in% natures &
    !vrai(col("fictif")) &
    (is.na(etat) | etat == "En service") &
    (is.na(avl) | avl != "Physiquement impossible")
  dec <- as.data.frame(table(nature = as.character(x$nature), garde = garde),
                       stringsAsFactors = FALSE)
  out <- x[garde, , drop = FALSE]
  out$acces_restreint <- vrai(col("prive"))[garde] |
    (!is.na(avl[garde]) & avl[garde] %in% c("Restreint aux ayants droit", "A p\u00e9age"))
  attr(out, "decompte") <- dec[dec$Freq > 0, ]
  out
}

#' Coût d'accès : distance au tronçon accessible le plus proche
#'
#' Distance euclidienne (m) du centre de chaque cellule de `grid` à la cellule la plus
#' proche touchée par un tronçon de `access` (tronçons rastérisés sur la grille).
#'
#' @param grid `SpatRaster` modèle (EPSG:2154).
#' @param access `sf` de lignes (EPSG:2154), par exemple [get_access_network()].
#' @return `SpatRaster` à une couche `cout_m`.
#' @examples
#' g <- build_grid(c(1010000, 6795000, 1010200, 6795200), 20)
#' l <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(
#'   rbind(c(1010000, 6795010), c(1010200, 6795010))), crs = 2154))
#' access_cost(g, l)
#' @export
access_cost <- function(grid, access) {
  if (!inherits(grid, "SpatRaster")) stop("`grid` doit \u00eatre un SpatRaster.", call. = FALSE)
  if (!inherits(access, c("sf", "sfc"))) stop("`access` doit \u00eatre un sf de lignes.", call. = FALSE)
  assert_crs_2154(grid)
  assert_crs_2154(access)
  tpl <- terra::rast(grid, nlyrs = 1)
  r <- terra::rasterize(terra::vect(sf::st_geometry(access)), tpl, field = 1, touches = TRUE)
  if (all(is.na(terra::values(r)))) {
    stop("Aucun tron\u00e7on d'acc\u00e8s ne touche la grille.", call. = FALSE)
  }
  out <- terra::distance(r)
  names(out) <- "cout_m"
  out
}

#' Cellules à voisinage 3 × 3 homogène
#'
#' Une cellule est retenue si ses 9 cellules (elle et ses 8 voisines) sont forestières et
#' renseignées, si chaque couche continue a dans ce voisinage un écart-type au plus égal à
#' `sd_ratio` fois son écart-type sur la forêt, et si chaque couche catégorielle (géologie)
#' y prend une seule classe. But : qu'un relevé localisé à quelques mètres près (GNSS) lise
#' les mêmes valeurs que la cellule tirée, et qu'il ne tombe pas en lisière.
#'
#' @param layers `SpatRaster` des couches fines (EPSG:2154).
#' @param forest `SpatRaster` : forêt si valeur non `NA` et positive (couche `foret` de
#'   [forest_mask()], ou première couche).
#' @param sd_ratio Seuil **provisoire** (0,5).
#' @return `SpatRaster` `homogene` (1 retenue, 0 non retenue, `NA` hors forêt).
#' @examples
#' r <- terra::rast(nrows = 5, ncols = 5, xmin = 1010000, xmax = 1010100, ymin = 6795000,
#'                  ymax = 6795100, crs = "EPSG:2154", vals = 1:25)
#' names(r) <- "pente"
#' f <- r * 0 + 1
#' homogeneous_cells(r, f)
#' @export
homogeneous_cells <- function(layers, forest, sd_ratio = .SD_RATIO_PROVISOIRE) {
  if (!inherits(layers, "SpatRaster") || !inherits(forest, "SpatRaster")) {
    stop("`layers` et `forest` doivent \u00eatre des SpatRaster.", call. = FALSE)
  }
  if (!is.numeric(sd_ratio) || length(sd_ratio) != 1L || is.na(sd_ratio) || sd_ratio <= 0) {
    stop("`sd_ratio` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  assert_crs_2154(layers)
  assert_crs_2154(forest)
  terra::compareGeom(layers, forest)
  f <- .forest_layer(forest)
  ok <- terra::focal(f, w = 3, fun = "sum", na.rm = FALSE) == 9
  fct <- terra::is.factor(layers)
  for (i in seq_len(terra::nlyr(layers))) {
    r <- terra::mask(layers[[i]], f)
    if (fct[i]) {
      r <- terra::as.int(r)
      h <- terra::focal(r, w = 3, fun = "max", na.rm = FALSE) ==
        terra::focal(r, w = 3, fun = "min", na.rm = FALSE)
    } else {
      s <- terra::global(r, "sd", na.rm = TRUE)[1, 1]
      loc <- terra::focal(r, w = 3, fun = "sd", na.rm = FALSE)
      h <- if (is.na(s) || s == 0) loc * 0 + 1 else loc <= sd_ratio * s
    }
    ok <- ok & h
  }
  ok[is.na(ok)] <- 0
  out <- terra::mask(terra::as.int(ok), f)
  names(out) <- "homogene"
  out
}

# Couche forestiere 1 / NA a partir d'un raster de foret.
.forest_layer <- function(forest) {
  f <- if ("foret" %in% names(forest)) forest[["foret"]] else forest[[1]]
  terra::ifel(!is.na(f) & f > 0, 1, NA)
}

#' Base de sondage du plan d'échantillonnage
#'
#' Tableau des cellules forestières de la grille dont toutes les couches sont renseignées
#' (la distribution de référence de l'hypercube), avec leur coût d'accès ([access_cost()])
#' et la colonne `candidat` : cellule tirable, c'est-à-dire à au plus `cost_max_m` d'un
#' tronçon accessible et à voisinage 3 × 3 homogène ([homogeneous_cells()]). Les couches
#' entièrement vides (MRVBF non calculé, par exemple ; voir [empty_layers()]) sont
#' **écartées avec un avertissement** de classe `sylvostation_non_calcule`, jamais
#' remplacées. Les couches catégorielles (géologie) deviennent des facteurs.
#'
#' @param layers `SpatRaster` des couches fines sur la grille (EPSG:2154) : par exemple
#'   `k_sv`, `is_topo`, `mrvbf`, `hauteur_reseau`, `pente`, `altitude`, `geologie`.
#' @param forest `SpatRaster` forestier, même géométrie (voir [homogeneous_cells()]).
#' @param access `sf` des tronçons accessibles.
#' @param cost_max_m Distance maximale à un tronçon, en mètres (300).
#' @param sd_ratio Seuil provisoire d'homogénéité (0,5).
#' @return `data.frame` : `cell`, `x` (est), `y` (nord), les couches, `cout_m`, `candidat`.
#'   Attributs `vars`, `ecartees`, `cost_max_m`, `sd_ratio`.
#' @examples
#' r <- terra::rast(nrows = 10, ncols = 10, xmin = 1010000, xmax = 1010200,
#'                  ymin = 6795000, ymax = 6795200, crs = "EPSG:2154", vals = 1:100)
#' names(r) <- "altitude"
#' l <- sf::st_sf(geometry = sf::st_sfc(sf::st_linestring(
#'   rbind(c(1010000, 6795010), c(1010200, 6795010))), crs = 2154))
#' table(sampling_frame(r, r * 0 + 1, l)$candidat)
#' @export
sampling_frame <- function(layers, forest, access, cost_max_m = 300,
                           sd_ratio = .SD_RATIO_PROVISOIRE) {
  if (!inherits(layers, "SpatRaster")) stop("`layers` doit \u00eatre un SpatRaster.", call. = FALSE)
  if (!is.numeric(cost_max_m) || length(cost_max_m) != 1L || is.na(cost_max_m) ||
      cost_max_m <= 0) {
    stop("`cost_max_m` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  assert_crs_2154(layers)
  vides <- empty_layers(layers)
  if (length(vides)) {
    .warn_non_calcule(paste0("Couches vides \u00e9cart\u00e9es du plan : ",
                             paste(vides, collapse = ", "), "."))
    layers <- layers[[setdiff(names(layers), vides)]]
  }
  if (!terra::nlyr(layers)) stop("Aucune couche renseign\u00e9e.", call. = FALSE)
  vars <- names(layers)
  if (anyDuplicated(vars) || any(vars %in% c("cell", "x", "y", "cout_m", "candidat", "homogene"))) {
    stop("Noms de couches dupliqu\u00e9s ou r\u00e9serv\u00e9s.", call. = FALSE)
  }
  f <- .forest_layer(forest)
  cout <- access_cost(layers, access)
  homog <- homogeneous_cells(layers, forest, sd_ratio)
  st <- c(layers, f, cout, homog)
  names(st) <- c(vars, ".foret", "cout_m", "homogene")
  d <- terra::as.data.frame(st, cells = TRUE, xy = TRUE, na.rm = FALSE)
  # un raster categoriel peut nommer sa colonne d'apres sa categorie active : on renomme
  names(d) <- c("cell", "x", "y", vars, ".foret", "cout_m", "homogene")
  d <- d[!is.na(d$.foret) & stats::complete.cases(d[, vars, drop = FALSE]), , drop = FALSE]
  if (!nrow(d)) stop("Aucune cellule foresti\u00e8re renseign\u00e9e.", call. = FALSE)
  out <- data.frame(cell = d$cell, x = d$x, y = d$y, stringsAsFactors = FALSE)  # x = est, y = nord
  for (v in vars) out[[v]] <- if (is.factor(d[[v]])) droplevels(d[[v]]) else as.numeric(d[[v]])
  out$cout_m <- d$cout_m
  out$candidat <- !is.na(d$homogene) & d$homogene == 1 & d$cout_m <= cost_max_m
  rownames(out) <- NULL
  attr(out, "vars") <- vars
  attr(out, "ecartees") <- vides
  attr(out, "cost_max_m") <- cost_max_m
  attr(out, "sd_ratio") <- sd_ratio
  out
}

#' Plan d'échantillonnage des relevés floristiques GNSS
#'
#' Tire `n` cellules par hypercube latin conditionné à coût (cLHS, Minasny et McBratney
#' 2006 ; variante à coût de Roudier et al. 2012 ; paquet `clhs`, docs/referentiels.md,
#' § 30). La distribution de référence est l'ensemble des cellules forestières renseignées
#' ([sampling_frame()]) ; seules les cellules `candidat` peuvent être tirées
#' (`can.include`) ; le coût est la distance au tronçon accessible (`cout_m`). Chaque point
#' est le **centre** de sa cellule. Pour chaque point, `n_replace` remplaçants : cellules
#' candidates de même(s) classe(s) catégorielle(s) (géologie), les plus proches dans
#' l'espace des couches continues centrées-réduites, à au moins `min_dist_m` de tout autre
#' point du plan. Les variables fines sont lues sur la grille, jamais aux placettes IFN
#' (`assert_no_fine_extract_on_ifn()` est appelé sur les points du plan).
#'
#' @param grid_layers `SpatRaster` des couches fines (voir [sampling_frame()]).
#' @param forest `SpatRaster` forestier.
#' @param access `sf` des tronçons accessibles ([get_access_network()]).
#' @param n Nombre de points (50).
#' @param cost_max_m Distance maximale à un tronçon, en mètres (300).
#' @param seed Graine (obligatoire) : même graine, même plan. L'état du générateur est
#'   restauré.
#' @param n_replace Remplaçants par point (2).
#' @param min_dist_m Distance minimale entre deux points du plan, remplaçants compris (60 m,
#'   provisoire).
#' @param iter Itérations du recuit de `clhs` (10 000).
#' @param sd_ratio Seuil provisoire d'homogénéité (0,5).
#' @return `sf` de points en EPSG:2154 : `id` (`P01`, `P01-R1`...), `rang` (0 point, 1 et 2
#'   remplaçants), `id_parent`, `cell`, `x`, `y`, les couches, `cout_m`, `acces_restreint`,
#'   `loc_precision_m` (0 : centre exact de cellule), `source` (`"plan_grille"`). Attributs
#'   `seed`, `frame` (base de sondage), `n_candidats`.
#' @examples
#' \dontrun{
#' p <- sampling_plan(couches, foret, troncons, n = 50, seed = 29)
#' }
#' @export
sampling_plan <- function(grid_layers, forest, access, n = 50, cost_max_m = 300, seed,
                          n_replace = 2, min_dist_m = 60, iter = 10000,
                          sd_ratio = .SD_RATIO_PROVISOIRE) {
  if (!requireNamespace("clhs", quietly = TRUE)) {
    stop("Le paquet `clhs` est requis (install.packages(\"clhs\")).", call. = FALSE)
  }
  if (missing(seed) || !is.numeric(seed) || length(seed) != 1L || is.na(seed)) {
    stop("`seed` (nombre) est obligatoire.", call. = FALSE)
  }
  ent <- function(v, min) is.numeric(v) && length(v) == 1L && !is.na(v) && v >= min && v == round(v)
  if (!ent(n, 1) || !ent(n_replace, 0) || !ent(iter, 1)) {
    stop("`n`, `n_replace` et `iter` doivent \u00eatre des entiers (n >= 1).", call. = FALSE)
  }
  if (!is.numeric(min_dist_m) || length(min_dist_m) != 1L || is.na(min_dist_m) || min_dist_m <= 0) {
    stop("`min_dist_m` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  fr <- sampling_frame(grid_layers, forest, access, cost_max_m, sd_ratio)
  vars <- attr(fr, "vars")
  cand <- which(fr$candidat)
  if (length(cand) < n * (1 + n_replace)) {
    stop("Trop peu de cellules candidates (", length(cand), ") pour ", n, " points et ",
         n_replace, " rempla\u00e7ants chacun.", call. = FALSE)
  }
  x <- fr[, c(vars, "cout_m"), drop = FALSE]
  idx <- .with_seed(seed, clhs::clhs(x, size = n, can.include = cand, cost = "cout_m",
                                     iter = iter, progress = FALSE, simple = TRUE))
  idx <- sort(as.integer(idx))
  if (!all(idx %in% cand)) stop("clhs a tir\u00e9 une cellule non candidate.", call. = FALSE)

  # remplacants : meme(s) classe(s), plus proches en variables centrees-reduites
  num <- vars[!vapply(fr[vars], is.factor, logical(1))]
  fac <- setdiff(vars, num)
  z <- if (length(num)) scale(as.matrix(fr[, num, drop = FALSE])) else matrix(0, nrow(fr), 0)
  z[is.na(z)] <- 0
  # dmin : carre de la distance de chaque candidate au point du plan le plus proche
  cx <- fr$x[cand]
  cy <- fr$y[cand]
  dmin <- rep(Inf, length(cand))
  ajoute <- function(r) pmin(dmin, (cx - fr$x[r])^2 + (cy - fr$y[r])^2)
  for (r in idx) dmin <- ajoute(r)
  rempl <- matrix(NA_integer_, length(idx), n_replace)
  for (k in seq_along(idx)) {
    if (!n_replace) break
    i <- idx[k]
    meme <- rep(TRUE, length(cand))
    for (v in fac) meme <- meme & fr[[v]][cand] == fr[[v]][i]
    for (j in seq_len(n_replace)) {
      p <- cand[meme & dmin >= min_dist_m^2]
      if (!length(p)) break
      dz <- if (ncol(z)) rowSums((z[p, , drop = FALSE] -
                                   matrix(z[i, ], length(p), ncol(z), byrow = TRUE))^2) else 0
      o <- order(dz, fr$cout_m[p], fr$cell[p])
      rempl[k, j] <- p[o[1]]
      dmin <- ajoute(p[o[1]])
    }
  }
  if (anyNA(rempl)) {
    warning("Rempla\u00e7ants incomplets pour ", sum(rowSums(is.na(rempl)) > 0),
            " point(s) : pas assez de cellules candidates de m\u00eame classe.", call. = FALSE)
  }
  ids <- sprintf(paste0("P%0", max(2, nchar(n)), "d"), seq_along(idx))
  rows <- data.frame(row = idx, id = ids, rang = 0L, id_parent = ids, stringsAsFactors = FALSE)
  for (j in seq_len(n_replace)) {
    ok <- !is.na(rempl[, j])
    rows <- rbind(rows, data.frame(row = rempl[ok, j], id = paste0(ids[ok], "-R", j), rang = j,
                                   id_parent = ids[ok], stringsAsFactors = FALSE))
  }
  rows <- rows[order(rows$id_parent, rows$rang), ]
  d <- cbind(rows[, c("id", "rang", "id_parent")], fr[rows$row, c("cell", "x", "y", vars, "cout_m")])
  d$rang <- as.integer(d$rang)
  rownames(d) <- NULL
  pts <- sf::st_as_sf(d, coords = c("x", "y"), crs = 2154, remove = FALSE)  # x = est, y = nord
  assert_crs_2154(pts)
  near <- sf::st_nearest_feature(pts, access)
  pts$acces_restreint <- if ("acces_restreint" %in% names(access)) {
    as.logical(access$acces_restreint[near])
  } else NA
  pts$loc_precision_m <- 0
  pts$source <- "plan_grille"
  assert_no_fine_extract_on_ifn(pts, vars)
  attr(pts, "seed") <- seed
  attr(pts, "n_candidats") <- length(cand)
  attr(pts, "frame") <- fr
  pts
}

#' Diagnostic de couverture du plan
#'
#' Compare la distribution de chaque couche dans l'échantillon (points de rang 0) à celle
#' de la forêt (toutes les cellules renseignées) et des cellules candidates : test de
#' Kolmogorov-Smirnov à deux échantillons (`stats::ks.test`, échantillon contre forêt) et
#' quantiles 5, 25, 50, 75 et 95 % pour les couches continues ; proportions par classe pour
#' les couches catégorielles.
#'
#' @param plan Résultat de [sampling_plan()].
#' @param frame Base de sondage ([sampling_frame()]) ; par défaut `attr(plan, "frame")`.
#' @return `data.frame` : `variable`, `indicateur` (`ks_D`, `ks_p`, `q05`... ou
#'   `classe:<nom>`), `echantillon`, `candidats`, `foret`.
#' @examples
#' \dontrun{
#' sampling_coverage(p)
#' }
#' @export
sampling_coverage <- function(plan, frame = attr(plan, "frame")) {
  if (!inherits(plan, "sf") || !"rang" %in% names(plan)) {
    stop("`plan` doit venir de sampling_plan().", call. = FALSE)
  }
  if (!is.data.frame(frame) || is.null(attr(frame, "vars"))) {
    stop("`frame` doit venir de sampling_frame().", call. = FALSE)
  }
  ech <- sf::st_drop_geometry(plan)[plan$rang == 0L, , drop = FALSE]
  can <- frame[frame$candidat, , drop = FALSE]
  probs <- c(0.05, 0.25, 0.5, 0.75, 0.95)
  out <- list()
  for (v in attr(frame, "vars")) {
    if (is.factor(frame[[v]])) {
      lv <- levels(frame[[v]])
      pr <- function(a) as.numeric(table(factor(as.character(a), lv))) / length(a)
      out[[v]] <- data.frame(variable = v, indicateur = paste0("classe:", lv),
                             echantillon = pr(ech[[v]]), candidats = pr(can[[v]]),
                             foret = pr(frame[[v]]), stringsAsFactors = FALSE)
    } else {
      ks <- suppressWarnings(stats::ks.test(ech[[v]], frame[[v]]))
      q <- function(a) unname(stats::quantile(a, probs, na.rm = TRUE))
      out[[v]] <- data.frame(variable = v,
                             indicateur = c("ks_D", "ks_p", sprintf("q%02d", probs * 100)),
                             echantillon = c(unname(ks$statistic), ks$p.value, q(ech[[v]])),
                             candidats = c(NA, NA, q(can[[v]])),
                             foret = c(NA, NA, q(frame[[v]])), stringsAsFactors = FALSE)
    }
  }
  res <- do.call(rbind, out)
  rownames(res) <- NULL
  res
}

#' Durée de terrain estimée
#'
#' Pour les points de rang 0 : relevé (`t_releve_min`) et tarière (`t_tariere_min`),
#' marche aller-retour depuis le tronçon (`2 * cout_m * detour` à `v_marche_kmh`), route
#' entre points visités dans l'ordre du plus proche voisin depuis le point le plus à
#' l'ouest (distance à vol d'oiseau `* detour` à `v_route_kmh`). Le trajet depuis la base
#' n'est pas compté. **Tous les paramètres sont provisoires**, à confirmer par Pascal.
#'
#' @param plan Résultat de [sampling_plan()].
#' @param t_releve_min,t_tariere_min Durées par point, en minutes (60 et 20).
#' @param v_marche_kmh Vitesse de marche hors piste (2 km/h).
#' @param v_route_kmh Vitesse sur route et chemin (30 km/h).
#' @param detour Facteur de détour appliqué aux distances à vol d'oiseau (1,3).
#' @param h_jour Heures de terrain utiles par jour (7).
#' @return Liste : `par_point` (`ordre`, `id`, `releve_min`, `marche_min`, `route_min`),
#'   `total_h`, `jours`, `parametres`.
#' @examples
#' \dontrun{
#' field_time(p)$jours
#' }
#' @export
field_time <- function(plan, t_releve_min = 60, t_tariere_min = 20, v_marche_kmh = 2,
                       v_route_kmh = 30, detour = 1.3, h_jour = 7) {
  if (!inherits(plan, "sf") || !all(c("rang", "id", "cout_m") %in% names(plan))) {
    stop("`plan` doit venir de sampling_plan().", call. = FALSE)
  }
  p <- plan[plan$rang == 0L, ]
  if (!nrow(p)) stop("Aucun point de rang 0.", call. = FALSE)
  xy <- sf::st_coordinates(p)  # x = est, y = nord
  reste <- seq_len(nrow(p))
  cur <- reste[which.min(xy[, 1])]
  ordre <- cur
  route <- 0
  reste <- setdiff(reste, cur)
  while (length(reste)) {
    d <- sqrt((xy[reste, 1] - xy[cur, 1])^2 + (xy[reste, 2] - xy[cur, 2])^2)
    nx <- reste[which.min(d)]
    route <- c(route, min(d))
    ordre <- c(ordre, nx)
    reste <- setdiff(reste, nx)
    cur <- nx
  }
  pp <- data.frame(ordre = seq_along(ordre), id = p$id[ordre],
                   releve_min = t_releve_min + t_tariere_min,
                   marche_min = 2 * p$cout_m[ordre] * detour / (v_marche_kmh * 1000) * 60,
                   route_min = route * detour / (v_route_kmh * 1000) * 60,
                   stringsAsFactors = FALSE)
  total <- sum(pp$releve_min + pp$marche_min + pp$route_min) / 60
  list(par_point = pp, total_h = total, jours = ceiling(total / h_jour),
       parametres = c(t_releve_min = t_releve_min, t_tariere_min = t_tariere_min,
                      v_marche_kmh = v_marche_kmh, v_route_kmh = v_route_kmh,
                      detour = detour, h_jour = h_jour))
}

#' Écrire le plan d'échantillonnage
#'
#' Écrit dans `out_dir` : `plan_gnss.gpkg` (couche `plan`, EPSG:2154), `plan_gnss.gpx`
#' (points de passage en WGS84, EPSG:4326 : `name` = identifiant, `desc` = rang et parent),
#' `couverture.csv` et la carte `plan_gnss.png` (forêt, tronçons, points et remplaçants).
#' Préfixe `synth_` et colonne `synthetic` si `synthetic = TRUE`.
#'
#' @param plan Résultat de [sampling_plan()].
#' @param coverage Résultat de [sampling_coverage()] (ou `NULL`).
#' @param out_dir Dossier de sortie (créé si besoin).
#' @param access,forest Tronçons et forêt pour la carte (facultatifs).
#' @param synthetic Données synthétiques ?
#' @return Chemins écrits, de façon invisible.
#' @examples
#' \dontrun{
#' write_sampling_plan(p, sampling_coverage(p), tempdir())
#' }
#' @export
write_sampling_plan <- function(plan, coverage, out_dir, access = NULL, forest = NULL,
                                synthetic = FALSE) {
  if (!inherits(plan, "sf")) stop("`plan` doit venir de sampling_plan().", call. = FALSE)
  assert_crs_2154(plan)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  pre <- if (isTRUE(synthetic)) "synth_" else ""
  f <- file.path(out_dir, paste0(pre, c("plan_gnss.gpkg", "plan_gnss.gpx",
                                        "couverture.csv", "plan_gnss.png")))
  attr(plan, "frame") <- NULL
  plan$synthetic <- isTRUE(synthetic)
  for (v in names(plan)) if (is.factor(plan[[v]])) plan[[v]] <- as.character(plan[[v]])
  sf::st_write(plan, f[1], layer = "plan", delete_dsn = TRUE, quiet = TRUE)
  g <- sf::st_transform(plan, 4326)
  g <- sf::st_sf(name = g$id,
                 desc = ifelse(g$rang == 0L, "point",
                               paste0("remplacant ", g$rang, " de ", g$id_parent)),
                 geometry = sf::st_geometry(g))
  sf::st_write(g, f[2], layer = "waypoints", driver = "GPX", delete_dsn = TRUE, quiet = TRUE)
  if (!is.null(coverage)) {
    utils::write.csv(coverage, f[3], row.names = FALSE, fileEncoding = "UTF-8")
  } else f[3] <- NA_character_
  grDevices::png(f[4], width = 1600, height = 1600, res = 150)
  tryCatch({
    if (!is.null(forest)) {
      terra::plot(.forest_layer(forest), col = "darkseagreen2", legend = FALSE,
                  main = paste0(pre, "plan d'\u00e9chantillonnage GNSS"))
    } else {
      plot(sf::st_geometry(plan), main = paste0(pre, "plan d'\u00e9chantillonnage GNSS"), col = NA)
    }
    if (!is.null(access)) plot(sf::st_geometry(access), add = TRUE, col = "grey40", lwd = 0.6)
    plot(sf::st_geometry(plan[plan$rang > 0L, ]), add = TRUE, pch = 1, col = "orange", cex = 0.7)
    p0 <- plan[plan$rang == 0L, ]
    plot(sf::st_geometry(p0), add = TRUE, pch = 19, col = "red3", cex = 0.9)
    graphics::text(sf::st_coordinates(p0), labels = p0$id, pos = 3, cex = 0.5)
  }, finally = grDevices::dev.off())
  invisible(f[!is.na(f)])
}

#' Lire et valider la saisie de la flore
#'
#' Contrôle le gabarit `inst/terrain/gabarit_flore.csv` rempli (une ligne par couple
#' relevé-espèce) : colonnes attendues, coordonnées en Lambert-93 (x = est, y = nord), un
#' seul emplacement par relevé, précision `loc_precision_m` au plus `max_precision_m`
#' (25 m), recouvrements au code de Braun-Blanquet ([BRAUN_BLANQUET]) avec au moins une
#' strate renseignée, pas d'espèce en double dans un relevé. Lit ensuite le fichier par
#' [load_gnss()], le lecteur du pipeline (`gnss_path`).
#'
#' @param path Chemin du CSV (virgule, UTF-8).
#' @param max_precision_m Précision maximale admise (25 m).
#' @return Le `sf` de [load_gnss()].
#' @examples
#' \dontrun{
#' read_field_sheet("releves_flore.csv")
#' }
#' @export
read_field_sheet <- function(path, max_precision_m = 25) {
  d <- .read_sheet(path, .FLORE_COLS)
  .check_location(d, max_precision_m)
  for (v in .FLORE_REC) {
    a <- trimws(d[[v]])
    a[is.na(a)] <- ""
    bad <- a != "" & !a %in% BRAUN_BLANQUET
    if (any(bad)) {
      stop("Code de recouvrement hors Braun-Blanquet (", v, ") : ",
           paste(unique(a[bad]), collapse = ", "), ".", call. = FALSE)
    }
    d[[v]] <- a
  }
  vide <- rowSums(d[, .FLORE_REC] != "") == 0
  if (any(vide)) {
    stop("Aucune strate renseign\u00e9e pour : ",
         paste(unique(paste(d$id[vide], d$species[vide])), collapse = "; "), ".", call. = FALSE)
  }
  if (any(is.na(d$species) | trimws(d$species) == "")) {
    stop("Nom d'esp\u00e8ce vide.", call. = FALSE)
  }
  dup <- duplicated(paste(d$id, tolower(trimws(d$species))))
  if (any(dup)) {
    stop("Esp\u00e8ce en double dans un relev\u00e9 (une ligne par esp\u00e8ce, strates en ",
         "colonnes) : ", paste(unique(paste(d$id[dup], d$species[dup])), collapse = "; "),
         ".", call. = FALSE)
  }
  load_gnss(path)
}

#' Lire et valider la saisie des stations
#'
#' Contrôle le gabarit `inst/terrain/gabarit_station.csv` rempli (une ligne par relevé) :
#' colonnes attendues, Lambert-93, précision au plus 25 m, `rang_utilise` dans 0, 1, 2,
#' forme d'humus vide ou dans [HUMUS_FORMS], `tariere_refus` vide, `oui` ou `non`.
#'
#' @param path Chemin du CSV (virgule, UTF-8).
#' @param max_precision_m Précision maximale admise (25 m).
#' @return `sf` de points en EPSG:2154, `source = "gnss"`.
#' @examples
#' \dontrun{
#' read_station_sheet("releves_station.csv")
#' }
#' @export
read_station_sheet <- function(path, max_precision_m = 25) {
  d <- .read_sheet(path, .STATION_COLS)
  .check_location(d, max_precision_m)
  if (anyDuplicated(d$id)) stop("Identifiant de relev\u00e9 en double.", call. = FALSE)
  if (!all(d$rang_utilise %in% 0:2)) stop("`rang_utilise` doit valoir 0, 1 ou 2.", call. = FALSE)
  h <- trimws(as.character(d$humus))
  h[is.na(h)] <- ""
  if (any(h != "" & !h %in% HUMUS_FORMS)) {
    stop("Forme d'humus non admise : ", paste(unique(h[h != "" & !h %in% HUMUS_FORMS]),
                                              collapse = ", "),
         " (grandes formes seulement : ", paste(HUMUS_FORMS, collapse = ", "), ").", call. = FALSE)
  }
  t <- trimws(as.character(d$tariere_refus))
  t[is.na(t)] <- ""
  if (!all(t %in% c("", "oui", "non"))) stop("`tariere_refus` : oui, non ou vide.", call. = FALSE)
  pts <- sf::st_as_sf(d, coords = c("x", "y"), crs = 2154, remove = FALSE)  # x = est, y = nord
  assert_crs_2154(pts)
  pts$source <- "gnss"
  pts
}

.read_sheet <- function(path, cols) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Fichier de saisie introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8",
                       colClasses = "character", na.strings = c("", "NA"))
  manque <- setdiff(cols, names(d))
  if (length(manque)) {
    stop("Colonnes manquantes : ", paste(manque, collapse = ", "), ".", call. = FALSE)
  }
  if (!nrow(d)) stop("Fichier de saisie vide.", call. = FALSE)
  for (v in c("x", "y", "loc_precision_m")) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
  if ("rang_utilise" %in% names(d)) d$rang_utilise <- suppressWarnings(as.integer(d$rang_utilise))
  d
}

.check_location <- function(d, max_precision_m) {
  if (anyNA(d$x) || anyNA(d$y)) stop("Coordonn\u00e9es x/y manquantes ou non num\u00e9riques.", call. = FALSE)
  p <- d$loc_precision_m
  if (anyNA(p) || any(p <= 0)) {
    stop("`loc_precision_m` doit \u00eatre positive et renseign\u00e9e.", call. = FALSE)
  }
  if (any(p > max_precision_m)) {
    stop("Pr\u00e9cision GNSS sup\u00e9rieure \u00e0 ", max_precision_m, " m pour : ",
         paste(unique(d$id[p > max_precision_m]), collapse = ", "),
         " (relev\u00e9 inutilisable pour les variables fines).", call. = FALSE)
  }
  pts <- sf::st_as_sf(d[, c("x", "y")], coords = c("x", "y"), crs = 2154)
  assert_crs_2154(pts)  # x = est, y = nord en Lambert-93
  u <- unique(d[, c("id", "x", "y")])
  if (anyDuplicated(u$id)) {
    stop("Plusieurs emplacements pour un m\u00eame relev\u00e9 : ",
         paste(unique(u$id[duplicated(u$id)]), collapse = ", "), ".", call. = FALSE)
  }
  invisible(TRUE)
}
