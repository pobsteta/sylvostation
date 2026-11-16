# Géologie et recodage lithologique (mission 004).
# Source des champs : docs/referentiels.md, § 5 (BD Charm-50 : CARTE, CODE, CODE_LEG,
# NOTATION, DESCR). La jointure se fait par NOTATION, jamais par CODE.
# Le régolithe BRGM (§ 6) n'est pas vérifié : les fonctions acceptent toute couche
# polygonale portant les champs demandés.

#' Lister les formations géologiques d'une couche
#'
#' Regroupe les polygones d'une couche BD Charm-50 par `NOTATION` (jamais par `CODE`,
#' qui n'est pas comparable d'un département à l'autre ; `docs/referentiels.md`, § 5).
#'
#' @param geol Objet `sf` polygonal en Lambert-93 (EPSG:2154) portant les champs
#'   `NOTATION`, `DESCR` et `CODE` (nom des champs réglable ci-dessous).
#' @param notation,description,code Noms des champs.
#' @return Un `data.frame` trié par surface décroissante : `notation`, `code` (les
#'   `CODE` distincts, séparés par `/`), `description` (celle du plus grand polygone
#'   de la notation), `n_poly`, `area_km2` (surface des polygones **dans
#'   l'emprise de la couche**, calculée sur la géométrie fournie).
#' @examples
#' g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
#'                              package = "sylvostation"), quiet = TRUE)
#' head(list_formations(g), 3)
#' @export
list_formations <- function(geol, notation = "NOTATION", description = "DESCR",
                            code = "CODE") {
  if (!inherits(geol, "sf")) stop("`geol` doit \u00eatre un objet sf.", call. = FALSE)
  assert_crs_2154(geol)
  manq <- setdiff(c(notation, description, code), names(geol))
  if (length(manq)) {
    stop("Champ(s) absent(s) de `geol` : ", paste(manq, collapse = ", "), ".", call. = FALSE)
  }
  d <- sf::st_drop_geometry(geol)
  d$.area <- as.numeric(sf::st_area(geol)) / 1e6
  d$.nota <- as.character(d[[notation]])
  out <- lapply(split(d, d$.nota), function(s) {
    s <- s[order(-s$.area), , drop = FALSE]
    data.frame(
      notation = s$.nota[1],
      code = paste(unique(as.character(s[[code]])), collapse = "/"),
      description = as.character(s[[description]][1]),
      n_poly = nrow(s),
      area_km2 = sum(s$.area),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, unname(out))
  out <- out[order(-out$area_km2), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# Normalise un texte pour la recherche de mots-clés : minuscules, sans accents.
.norm_texte <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("\u0153", "oe", x, fixed = TRUE)
  chartr("\u00e0\u00e2\u00e4\u00e9\u00e8\u00ea\u00eb\u00ee\u00ef\u00f4\u00f6\u00fb\u00f9\u00fc\u00e7",
         "aaaeeeeiioouuuc", x)
}

#' Lire les règles de recodage lithologique
#'
#' @param path Chemin d'un CSV de règles (colonnes `priorite`, `motif`, `classe`,
#'   `commentaire`). Par défaut, `inst/extdata/lithologie_regles.csv`.
#' @return Un `data.frame` de règles, trié par priorité.
#' @examples
#' read_lithology_rules()$classe
#' @export
read_lithology_rules <- function(path = system.file("extdata", "lithologie_regles.csv",
                                                    package = "sylvostation")) {
  if (!nzchar(path) || !file.exists(path)) stop("Fichier de r\u00e8gles introuvable.", call. = FALSE)
  r <- utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8")
  .check_rules(r)
  r[order(r$priorite), , drop = FALSE]
}

.check_rules <- function(rules) {
  if (!is.data.frame(rules) || !all(c("priorite", "motif", "classe") %in% names(rules))) {
    stop("`rules` doit \u00eatre un data.frame avec les colonnes priorite, motif, classe.",
         call. = FALSE)
  }
  if ("non_classe" %in% rules$classe) {
    stop("`non_classe` est r\u00e9serv\u00e9 aux formations sans r\u00e8gle.", call. = FALSE)
  }
  invisible(rules)
}

#' Recoder les formations en classes lithologiques
#'
#' Applique des règles de mots-clés (expressions régulières sur la description,
#' en minuscules et sans accents) dans l'ordre de `priorite` : la **première** règle
#' qui correspond donne la classe. Une formation sans règle reçoit `non_classe` :
#' elle n'est **jamais** affectée par défaut, et un avertissement la liste.
#' Les règles fournies sont **provisoires** (`validated = FALSE` jusqu'à relecture).
#'
#' @param formations `data.frame` de [list_formations()] (colonne `description`).
#' @param rules `data.frame` de règles, voir [read_lithology_rules()].
#' @return `formations` avec les colonnes `classe`, `statut` (`regle` ou `non_classe`)
#'   et `validated` (`FALSE`).
#' @examples
#' f <- data.frame(notation = c("a", "b"), description = c("Granite de X", "Remblais"))
#' suppressWarnings(recode_lithology(f, read_lithology_rules()))
#' @export
recode_lithology <- function(formations, rules = read_lithology_rules()) {
  if (!is.data.frame(formations) || !"description" %in% names(formations)) {
    stop("`formations` doit avoir une colonne `description`.", call. = FALSE)
  }
  .check_rules(rules)
  rules <- rules[order(rules$priorite), , drop = FALSE]
  txt <- .norm_texte(formations$description)
  classe <- rep(NA_character_, length(txt))
  for (i in seq_len(nrow(rules))) {
    hit <- is.na(classe) & grepl(rules$motif[i], txt, perl = TRUE)
    classe[hit] <- rules$classe[i]
  }
  nc <- is.na(classe)
  classe[nc] <- "non_classe"
  formations$classe <- classe
  formations$statut <- ifelse(nc, "non_classe", "regle")
  formations$validated <- FALSE
  if (any(nc)) {
    id <- if ("notation" %in% names(formations)) formations$notation else formations$description
    warning(sum(nc), " formation(s) sans r\u00e8gle, laiss\u00e9e(s) en `non_classe` : ",
            paste(id[nc], collapse = ", "), ".", call. = FALSE)
  }
  formations
}

#' Rasteriser une couche géologique sur la grille commune
#'
#' Rasterise un champ de classes d'une couche polygonale (BD Charm-50, ou toute autre
#' couche polygonale, par exemple le régolithe) sur une grille. Le résultat est un
#' raster **catégoriel** (niveaux = classes), `NA` hors polygones. La cellule prend la
#' valeur du polygone qui contient son centre.
#'
#' @param geol Objet `sf` polygonal en Lambert-93 (EPSG:2154).
#' @param grid `SpatRaster` en Lambert-93 : la grille commune.
#' @param field Nom du champ de classes (texte) de `geol`.
#' @param table Optionnel : tableau de recodage (par exemple le résultat de
#'   [recode_lithology()] ou `lithologie_massif_test.csv`) avec colonnes `notation`
#'   et `classe` ; `geol` est alors joint par `NOTATION` (jamais par `CODE`) pour
#'   créer le champ `field` ; une notation absente du tableau devient `non_classe`.
#' @return `SpatRaster` catégoriel à une couche nommée `field`.
#' @examples
#' g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
#'                              package = "sylvostation"), quiet = TRUE)
#' grid <- terra::rast(xmin = 1007000, xmax = 1010000, ymin = 6790000, ymax = 6793000,
#'                     resolution = 100, crs = "EPSG:2154")
#' tab <- suppressWarnings(recode_lithology(list_formations(g)))
#' rasterize_geol(g, grid, "classe", table = tab)
#' @export
rasterize_geol <- function(geol, grid, field = "classe", table = NULL) {
  if (!inherits(geol, "sf")) stop("`geol` doit \u00eatre un objet sf.", call. = FALSE)
  if (!inherits(grid, "SpatRaster")) stop("`grid` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(geol)
  assert_crs_2154(grid)
  if (!is.null(table)) {
    if (!all(c("notation", "classe") %in% names(table))) {
      stop("`table` doit avoir les colonnes notation et classe.", call. = FALSE)
    }
    if (!"NOTATION" %in% names(geol)) stop("`geol` n'a pas de champ NOTATION.", call. = FALSE)
    cl <- table$classe[match(as.character(geol$NOTATION), table$notation)]
    cl[is.na(cl)] <- "non_classe"
    geol[[field]] <- cl
  }
  if (!field %in% names(geol)) stop("Champ `", field, "` absent de `geol`.", call. = FALSE)
  v <- as.character(geol[[field]])
  niveaux <- sort(unique(v[!is.na(v)]))
  geol$.id <- match(v, niveaux)
  geol <- geol[!is.na(geol$.id), ]
  r <- terra::rasterize(terra::vect(geol), terra::rast(grid, nlyrs = 1), field = ".id")
  levels(r) <- data.frame(id = seq_along(niveaux), classe = niveaux)
  names(r) <- field
  r
}

#' Lithologie dominante dans un disque
#'
#' Classe **modale** dans un disque de rayon `radius` autour de chaque cellule : le
#' prédicteur géologique à maille large autorisé pour les placettes de l'IFN
#' (localisées à 700 m près ; brief technique, règle des 700 m). En cas d'égalité, la
#' classe de plus petit identifiant l'emporte (résultat déterministe). Les cellules
#' sans aucune donnée dans le disque restent `NA` ; hors du raster, les cellules sont
#' ignorées.
#'
#' @param litho_rast `SpatRaster` catégoriel de [rasterize_geol()], à maille carrée.
#' @param radius Rayon du disque, en mètres (700 par défaut).
#' @return `SpatRaster` catégoriel nommé `geologie_700m` (nom de la variable à maille
#'   large de [COARSE_VARIABLES]), mêmes niveaux que `litho_rast`.
#' @examples
#' r <- terra::rast(nrows = 20, ncols = 20, xmin = 1e6, xmax = 1000500,
#'                  ymin = 6.8e6, ymax = 6800500, crs = "EPSG:2154")
#' terra::values(r) <- rep(c(1, 2), each = 200)
#' levels(r) <- data.frame(id = 1:2, classe = c("a", "b"))
#' dominant_lithology(r, radius = 50)
#' @export
dominant_lithology <- function(litho_rast, radius = 700) {
  if (!inherits(litho_rast, "SpatRaster")) {
    stop("`litho_rast` doit \u00eatre un SpatRaster.", call. = FALSE)
  }
  assert_crs_2154(litho_rast)
  if (!is.numeric(radius) || length(radius) != 1L || is.na(radius) || radius <= 0) {
    stop("`radius` doit \u00eatre un nombre positif (m).", call. = FALSE)
  }
  rs <- terra::res(litho_rast)
  if (abs(rs[1] - rs[2]) > 1e-6) stop("Maille carr\u00e9e requise.", call. = FALSE)
  cats <- terra::cats(litho_rast)[[1]]
  if (is.null(cats)) stop("`litho_rast` doit \u00eatre cat\u00e9goriel.", call. = FALSE)
  ids <- cats[[1]]
  n <- floor(radius / rs[1])
  off <- -n:n
  w <- outer(off, off, function(i, j) sqrt(i^2 + j^2) * rs[1] <= radius) * 1
  v <- terra::rast(litho_rast, nlyrs = 1)
  terra::values(v) <- as.numeric(terra::values(litho_rast, mat = FALSE))
  # Marge de n cellules (NA) : terra::focal refuse un disque plus grand que le raster
  e0 <- terra::ext(v)
  m <- n * rs[1]
  vx <- terra::extend(v, terra::ext(e0[1] - m, e0[2] + m, e0[3] - m, e0[4] + m))
  counts <- lapply(ids, function(k) {
    terra::crop(terra::focal(vx == k, w = w, fun = "sum", na.rm = TRUE), e0)
  })
  counts <- terra::rast(counts)
  tot <- sum(counts)
  best <- terra::which.max(counts)
  out <- terra::ifel(tot > 0, best, NA)
  out <- terra::subst(out, seq_along(ids), ids)
  levels(out) <- cats
  names(out) <- "geologie_700m"
  out
}

#' Contrôler les raccords entre feuilles et départements
#'
#' Repère les polygones voisins (à moins de `tol` m l'un de l'autre) qui appartiennent
#' à deux groupes différents (champ `dep` ou `CARTE`, s'ils existent) : à chaque
#' limite, on liste la paire de notations et la longueur de contact. Une notation
#' différente de part et d'autre est un **changement d'unité à la limite**, à
#' examiner (raccord de feuille ou de département mal harmonisé) ; une même notation
#' avec des `CODE` différents est signalée aussi (`code_differe`). Si aucun champ de
#' groupe n'existe, renvoie un tableau vide avec un message.
#'
#' @param geol Objet `sf` polygonal en Lambert-93 avec `NOTATION` (et `CODE`).
#' @param fields Champs de groupe à examiner.
#' @param tol Distance de voisinage, en mètres (les géométries de l'extrait sont
#'   simplifiées à 5 m).
#' @param min_length Longueur de contact minimale retenue, en mètres.
#' @return Un `data.frame` : `champ`, `groupe_a`, `groupe_b`, `notation_a`,
#'   `notation_b`, `longueur_m`, `unite_change` (notations différentes),
#'   `code_differe`. Un avertissement est émis s'il y a des changements d'unité.
#' @examples
#' g <- sf::st_read(system.file("extdata/bdcharm50_emprise_test.gpkg",
#'                              package = "sylvostation"), quiet = TRUE)
#' nrow(suppressWarnings(check_geol_joins(g)))
#' @export
check_geol_joins <- function(geol, fields = c("dep", "CARTE"), tol = 10,
                             min_length = 50) {
  if (!inherits(geol, "sf")) stop("`geol` doit \u00eatre un objet sf.", call. = FALSE)
  assert_crs_2154(geol)
  if (!"NOTATION" %in% names(geol)) stop("`geol` n'a pas de champ NOTATION.", call. = FALSE)
  vide <- data.frame(champ = character(), groupe_a = character(), groupe_b = character(),
                     notation_a = character(), notation_b = character(),
                     longueur_m = numeric(), unite_change = logical(),
                     code_differe = logical(), stringsAsFactors = FALSE)
  champs <- intersect(fields, names(geol))
  if (!length(champs)) {
    message("Aucun champ de groupe (", paste(fields, collapse = ", "),
            ") dans `geol` : raccords non contr\u00f4l\u00e9s.")
    return(vide)
  }
  nb <- as.character(geol$NOTATION)
  cd <- if ("CODE" %in% names(geol)) as.character(geol$CODE) else rep(NA_character_, nrow(geol))
  geom <- sf::st_geometry(geol)
  voisins <- sf::st_is_within_distance(geom, geom, dist = tol)
  res <- list()
  for (ch in champs) {
    g <- as.character(geol[[ch]])
    for (i in seq_along(voisins)) {
      for (j in voisins[[i]][voisins[[i]] > i]) {
        if (is.na(g[i]) || is.na(g[j]) || g[i] == g[j]) next
        bi <- sf::st_boundary(geom[i])
        zj <- sf::st_buffer(geom[j], tol)
        len <- sum(as.numeric(sf::st_length(suppressWarnings(sf::st_intersection(bi, zj)))))
        if (len < min_length) next
        res[[length(res) + 1L]] <- data.frame(
          champ = ch, groupe_a = g[i], groupe_b = g[j], notation_a = nb[i],
          notation_b = nb[j], longueur_m = len, unite_change = nb[i] != nb[j],
          code_differe = nb[i] == nb[j] && !identical(cd[i], cd[j]),
          stringsAsFactors = FALSE)
      }
    }
  }
  out <- if (length(res)) do.call(rbind, res) else vide
  if (any(out$unite_change)) {
    warning(sum(out$unite_change), " contact(s) entre groupes avec changement d'unit\u00e9 ",
            "\u00e0 la limite (", round(sum(out$longueur_m[out$unite_change])),
            " m) : voir le tableau renvoy\u00e9.", call. = FALSE)
  }
  out
}
