# Points d'ancrage : GBIF (mission 007) et relevés GNSS.
# Sources : docs/brief-technique.md (§ 4 étape 4, § 5), docs/referentiels.md (§ 4, § 8, § 10).

#' Jeu GBIF des relevés de l'inventaire forestier national
#'
#' `datasetKey` du jeu « Relevés floristiques du protocole de l'Inventaire National
#' Forestier de l'IGN » dans GBIF (`docs/referentiels.md`, § 8). Ses occurrences
#' déclarent souvent une incertitude de 1 m alors que l'IGN publie les placettes à
#' 700 m près : `clean_occ()` l'exclut quelle que soit l'incertitude déclarée.
#' @format Un vecteur de caractères.
#' @export
IFN_GBIF_DATASET_KEYS <- "e5f16d86-e225-4822-97be-a64ce17079c7"

# Clés vérifiées au § 8 de docs/referentiels.md.
.GBIF_TRACHEOPHYTA_KEY <- 7707728L
.GBIF_BACKBONE_KEY <- "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"

# Emprise (sf/sfc en EPSG:2154, ou vecteur xmin, ymin, xmax, ymax en EPSG:2154)
# -> rectangle WKT en WGS84, sens anti-horaire (x = longitude, y = latitude).
.emprise_wkt_wgs84 <- function(emprise) {
  if (is.numeric(emprise)) {
    if (length(emprise) != 4L || anyNA(emprise)) {
      stop("`emprise` num\u00e9rique doit valoir c(xmin, ymin, xmax, ymax) en EPSG:2154.",
           call. = FALSE)
    }
    emprise <- sf::st_as_sfc(sf::st_bbox(
      c(xmin = emprise[[1]], ymin = emprise[[2]], xmax = emprise[[3]], ymax = emprise[[4]]),
      crs = sf::st_crs(2154)))
  }
  assert_crs_2154(emprise)
  b <- as.numeric(sf::st_bbox(emprise))  # xmin, ymin, xmax, ymax
  coins <- matrix(c(b[1], b[2], b[3], b[2], b[3], b[4], b[1], b[4], b[1], b[2]),
                  ncol = 2, byrow = TRUE)
  poly <- sf::st_sfc(sf::st_polygon(list(coins)), crs = sf::st_crs(2154))
  sf::st_as_text(sf::st_transform(poly, 4326), digits = 7)
}

# Prédicats de téléchargement (brief technique, § 5), construits sans réseau.
.gbif_predicates <- function(wkt, year_min, max_uncertainty, keep_unknown) {
  p <- list(
    rgbif::pred_within(wkt),
    rgbif::pred("taxonKey", .GBIF_TRACHEOPHYTA_KEY),
    rgbif::pred("hasCoordinate", TRUE),
    rgbif::pred("hasGeospatialIssue", FALSE),
    rgbif::pred_gte("year", year_min)
  )
  if (!is.null(max_uncertainty)) {
    lte <- rgbif::pred_lte("coordinateUncertaintyInMeters", max_uncertainty)
    p <- c(p, list(if (keep_unknown) {
      rgbif::pred_or(lte, rgbif::pred_isnull("coordinateUncertaintyInMeters"))
    } else lte))
  }
  p
}

# Arguments de rgbif::occ_search (aperçu).
.gbif_search_args <- function(wkt, year_min, max_uncertainty, limit) {
  a <- list(taxonKey = .GBIF_TRACHEOPHYTA_KEY, checklistKey = .GBIF_BACKBONE_KEY,
            geometry = wkt, hasCoordinate = TRUE, hasGeospatialIssue = FALSE,
            year = paste0(year_min, ",", format(Sys.Date(), "%Y")), limit = limit)
  if (!is.null(max_uncertainty)) {
    a$coordinateUncertaintyInMeters <- paste0("0,", max_uncertainty)
  }
  a
}

#' Obtenir les occurrences GBIF de plantes vasculaires d'une emprise
#'
#' Mode `"download"` (par défaut, brief technique § 4 étape 4 et § 5) : demande un
#' téléchargement `rgbif::occ_download()` (plantes vasculaires, clé 7707728, coordonnées
#' présentes, sans anomalie géographique, depuis `year_min`, incertitude au plus
#' `max_uncertainty`), l'attend, l'importe et **conserve le DOI** (attributs `doi` et
#' `download_key`). Il exige un compte GBIF : `user`, `pwd`, `email`, ou les variables
#' d'environnement `GBIF_USER`, `GBIF_PWD`, `GBIF_EMAIL`. Sans identifiants, la fonction
#' échoue avec un message clair, avant tout accès au réseau.
#'
#' Mode `"search"` : **aperçu non exhaustif** par `rgbif::occ_search()`, au plus `limit`
#' occurrences (jamais plus de 100 000, plafond de l'API), sans compte et sans DOI. À
#' réserver aux essais et aux comptages.
#'
#' La clé taxonomique 7707728 relève du référentiel « GBIF Backbone Taxonomy »
#' (`docs/referentiels.md`, § 8) ; `occ_search()` l'emploie avec ce référentiel. Le
#' comportement d'`occ_download()` avec cette clé et ce `checklistKey` n'a **pas pu être
#' vérifié** (compte requis) : à vérifier au premier téléchargement réel (nombre attendu
#' dans l'emprise test : 18 538 sans filtre d'incertitude).
#'
#' @param emprise Objet `sf`/`sfc` en EPSG:2154, ou `c(xmin, ymin, xmax, ymax)` en
#'   EPSG:2154 (x = est, y = nord). Seule sa boîte englobante est utilisée, reprojetée
#'   en WGS84 (rectangle dont les côtés sont des droites en degrés).
#' @param user,pwd,email Identifiants GBIF (mode `"download"`).
#' @param method `"download"` ou `"search"`.
#' @param year_min Première année retenue (2000).
#' @param max_uncertainty Incertitude maximale en mètres (25). `NULL` : aucun filtre
#'   d'incertitude (utile pour dénombrer les occurrences sans incertitude, que
#'   [clean_occ()] traite ensuite).
#' @param keep_unknown En mode `"download"`, garder aussi les occurrences sans
#'   incertitude (`FALSE` par défaut, conforme au brief).
#' @param limit Mode `"search"` : nombre maximal d'occurrences (≤ 100 000).
#' @param path Dossier du fichier téléchargé (mode `"download"`).
#' @param wait Mode `"download"` : attendre et importer (`TRUE`) ou rendre seulement
#'   la clé de téléchargement.
#' @return Un `data.frame` d'occurrences (colonnes Darwin Core de GBIF, coordonnées en
#'   WGS84 : `decimalLongitude`, `decimalLatitude`), avec les attributs `method`, et pour
#'   `"download"` `doi` et `download_key`. Passer ensuite par [clean_occ()].
#' @examples
#' \dontrun{
#' occ <- get_gbif(c(1007000, 6790000, 1022000, 6805000), method = "search",
#'                 limit = 1000)
#' }
#' @export
get_gbif <- function(emprise, user = Sys.getenv("GBIF_USER"),
                     pwd = Sys.getenv("GBIF_PWD"), email = Sys.getenv("GBIF_EMAIL"),
                     method = c("download", "search"), year_min = 2000,
                     max_uncertainty = 25, keep_unknown = FALSE, limit = 100000,
                     path = tempdir(), wait = TRUE) {
  method <- match.arg(method)
  if (!requireNamespace("rgbif", quietly = TRUE)) {
    stop("Le paquet `rgbif` est requis (Suggests).", call. = FALSE)
  }
  if (!is.numeric(year_min) || length(year_min) != 1L || is.na(year_min)) {
    stop("`year_min` doit \u00eatre une ann\u00e9e.", call. = FALSE)
  }
  if (!is.null(max_uncertainty) &&
      (!is.numeric(max_uncertainty) || length(max_uncertainty) != 1L ||
       is.na(max_uncertainty) || max_uncertainty <= 0)) {
    stop("`max_uncertainty` doit \u00eatre un nombre positif ou NULL.", call. = FALSE)
  }
  wkt <- .emprise_wkt_wgs84(emprise)

  if (method == "search") {
    if (!is.numeric(limit) || length(limit) != 1L || is.na(limit) || limit < 1) {
      stop("`limit` doit \u00eatre un entier positif.", call. = FALSE)
    }
    limit <- min(as.integer(limit), 100000L)
    res <- do.call(rgbif::occ_search, .gbif_search_args(wkt, year_min, max_uncertainty, limit))
    out <- as.data.frame(res$data)
    attr(out, "method") <- "search"
    message("Aper\u00e7u GBIF (occ_search) : ", nrow(out), " occurrences, non exhaustif ",
            "(plafond 100 000), sans DOI.")
    return(out)
  }

  vide <- function(v) is.null(v) || length(v) != 1L || is.na(v) || !nzchar(v)
  if (vide(user) || vide(pwd) || vide(email)) {
    stop("Identifiants GBIF manquants : fournir `user`, `pwd` et `email` ou d\u00e9finir ",
         "GBIF_USER, GBIF_PWD et GBIF_EMAIL (compte gratuit sur gbif.org). ",
         "Sans compte, utiliser `method = \"search\"` (aper\u00e7u non exhaustif).",
         call. = FALSE)
  }
  preds <- .gbif_predicates(wkt, year_min, max_uncertainty, keep_unknown)
  # checklistKey : cle 7707728 = GBIF Backbone ; comportement d'occ_download avec ce
  # referentiel a verifier au premier telechargement reel (compte requis).
  dl <- do.call(rgbif::occ_download,
                c(preds, list(checklistKey = .GBIF_BACKBONE_KEY, user = user, pwd = pwd,
                              email = email)))
  if (!wait) return(dl)
  rgbif::occ_download_wait(dl)
  got <- rgbif::occ_download_get(dl, path = path, overwrite = TRUE)
  out <- as.data.frame(rgbif::occ_download_import(got))
  meta <- rgbif::occ_download_meta(as.character(dl))
  attr(out, "method") <- "download"
  attr(out, "download_key") <- meta$key
  attr(out, "doi") <- meta$doi
  out
}

# Codes BD Forêt retenus : forêt fermée (FF*) ou ouverte (FO*), hors FF0 (sans couvert
# arboré). Peupleraie (FP), landes (LA*) et formations herbacées exclues.
# Décision provisoire (referentiels.md § 4 : "décision à prendre pour FP et FF0").
.forest_code_ok <- function(code) {
  grepl("^F[FO]", code) & code != "FF0"
}

.log_step <- function(log, etape, n) {
  rbind(log, data.frame(etape = etape, n = as.integer(n), stringsAsFactors = FALSE))
}

#' Nettoyer des occurrences GBIF et les reprojeter en Lambert-93
#'
#' Étapes (nombre d'occurrences conservé à chacune dans `attr(, "clean_log")`) :
#' 1. coordonnées présentes, espèce renseignée ; reprojection de WGS84 vers EPSG:2154
#'    **dès l'import** (`assert_crs_2154()`) ;
#' 2. exclusion des jeux de `exclude_datasets` (par défaut le jeu IFN,
#'    [IFN_GBIF_DATASET_KEYS]) : leur incertitude déclarée (1 m) est fausse. Si on les
#'    garde (`exclude_datasets = character(0)`), ils sont marqués `source = "ifn"` et
#'    `loc_precision_m = 700` (comme [mark_ifn()]) ;
#' 3. précision : `loc_precision_m` = `coordinateUncertaintyInMeters` ; elle vaut `NA`
#'    si l'incertitude est absente **ou** si `dataGeneralizations` / `informationWithheld`
#'    est renseigné (donnée généralisée). Sont gardés les points de précision
#'    ≤ `max_uncertainty` ; les `NA` sont écartés sauf `keep_unknown = TRUE` (ils sont
#'    alors refusés par [assert_no_fine_extract_on_ifn()] pour toute extraction fine) ;
#' 4. forêt si `forest` est fourni : polygones BD Forêt avec une colonne `code_tfv` ;
#'    codes `FF*` et `FO*` hors `FF0` (provisoire : décision à prendre pour `FP` et
#'    `FF0`, `docs/referentiels.md` § 4) ;
#' 5. canopée si `canopy` est fourni : hauteur de canopée (MHC) strictement supérieure à
#'    `min_canopy` m. C'est une **extraction fine** : la règle bloquante s'applique
#'    (donc erreur si des points de précision `NA` ou > 25 m subsistent).
#'
#' La licence de chaque jeu (`license`) est conservée.
#'
#' @param occ `data.frame` d'occurrences GBIF (WGS84) : `decimalLongitude`,
#'   `decimalLatitude`, `species` ; facultatives : `gbifID` (ou `key` en mode `"search"`), `speciesKey`, `datasetKey`,
#'   `license`, `year`, `coordinateUncertaintyInMeters`, `dataGeneralizations`,
#'   `informationWithheld`.
#' @param max_uncertainty Précision maximale gardée, en mètres (25).
#' @param exclude_datasets `datasetKey` à écarter.
#' @param keep_unknown Garder les points de précision inconnue (`FALSE`).
#' @param forest Polygones BD Forêt (`sf`, EPSG:2154, colonne `code_tfv`) ou `NULL`.
#' @param canopy `SpatRaster` de hauteur de canopée (EPSG:2154) ou `NULL`.
#' @param min_canopy Hauteur minimale de canopée, en mètres (5).
#' @return Un objet `sf` (points, EPSG:2154) avec `gbif_id`, `species`, `species_key`,
#'   `dataset_key`, `license`, `year`, `loc_precision_m`, `source`, et l'attribut
#'   `clean_log`.
#' @examples
#' f <- system.file("extdata", "synth_occ.csv", package = "sylvostation")
#' if (nzchar(f)) {
#'   p <- clean_occ(utils::read.csv(f))
#'   attr(p, "clean_log")
#' }
#' @export
clean_occ <- function(occ, max_uncertainty = 25, exclude_datasets = IFN_GBIF_DATASET_KEYS,
                      keep_unknown = FALSE, forest = NULL, canopy = NULL, min_canopy = 5) {
  if (!is.data.frame(occ)) stop("`occ` doit \u00eatre un data.frame.", call. = FALSE)
  manque <- setdiff(c("decimalLongitude", "decimalLatitude", "species"), names(occ))
  if (length(manque)) {
    stop("Colonnes manquantes dans `occ` : ", paste(manque, collapse = ", "), ".",
         call. = FALSE)
  }
  if (!is.numeric(max_uncertainty) || length(max_uncertainty) != 1L ||
      is.na(max_uncertainty) || max_uncertainty <= 0) {
    stop("`max_uncertainty` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  col <- function(nm, default) if (nm %in% names(occ)) occ[[nm]] else rep(default, nrow(occ))
  renseigne <- function(v) !is.na(v) & nzchar(trimws(as.character(v)))
  d <- data.frame(
    gbif_id = as.character(if ("gbifID" %in% names(occ)) occ$gbifID else col("key", NA_character_)),  # occ_search donne `key`
    species = as.character(occ$species),
    species_key = as.character(col("speciesKey", NA_character_)),
    dataset_key = as.character(col("datasetKey", NA_character_)),
    license = as.character(col("license", NA_character_)),
    year = suppressWarnings(as.integer(col("year", NA_integer_))),
    lon = suppressWarnings(as.numeric(occ$decimalLongitude)),
    lat = suppressWarnings(as.numeric(occ$decimalLatitude)),
    incert = suppressWarnings(as.numeric(col("coordinateUncertaintyInMeters", NA_real_))),
    generalise = renseigne(col("dataGeneralizations", NA_character_)) |
      renseigne(col("informationWithheld", NA_character_)),
    stringsAsFactors = FALSE
  )
  log <- .log_step(NULL, "entree", nrow(d))

  # 1. coordonnees et espece ; reprojection immediate en 2154
  d <- d[!is.na(d$lon) & !is.na(d$lat) & abs(d$lon) <= 180 & abs(d$lat) <= 90, , drop = FALSE]
  log <- .log_step(log, "coordonnees_presentes", nrow(d))
  d <- d[renseigne(d$species), , drop = FALSE]
  log <- .log_step(log, "espece_renseignee", nrow(d))
  pts <- sf::st_as_sf(d, coords = c("lon", "lat"), crs = 4326)  # x = longitude, y = latitude
  pts <- sf::st_transform(pts, 2154)
  assert_crs_2154(pts)

  # 2. jeux exclus (IFN)
  if (length(exclude_datasets)) {
    pts <- pts[is.na(pts$dataset_key) | !pts$dataset_key %in% exclude_datasets, ]
  }
  log <- .log_step(log, "hors_jeux_exclus", nrow(pts))

  # 3. precision de localisation
  pts$source <- "gbif"
  pts$loc_precision_m <- ifelse(pts$generalise, NA_real_, pts$incert)
  est_ifn <- !is.na(pts$dataset_key) & pts$dataset_key %in% IFN_GBIF_DATASET_KEYS
  pts$source[est_ifn] <- "ifn"
  pts$loc_precision_m[est_ifn] <- 700
  precis <- !is.na(pts$loc_precision_m) & pts$loc_precision_m <= max_uncertainty
  inconnu <- is.na(pts$loc_precision_m)
  pts <- pts[precis | (keep_unknown & inconnu), ]
  log <- .log_step(log, "precision_retenue", nrow(pts))
  pts$incert <- NULL
  pts$generalise <- NULL

  # 4. foret
  if (!is.null(forest)) {
    if (!inherits(forest, "sf") || !"code_tfv" %in% names(forest)) {
      stop("`forest` doit \u00eatre un objet sf avec une colonne `code_tfv`.", call. = FALSE)
    }
    assert_crs_2154(forest)
    f <- forest[.forest_code_ok(as.character(forest$code_tfv)), ]
    dans <- lengths(sf::st_intersects(pts, sf::st_union(sf::st_geometry(f)))) > 0
    pts <- pts[dans, ]
    log <- .log_step(log, "en_foret_bdforet", nrow(pts))
  }

  # 5. canopee (extraction fine : regle bloquante)
  if (!is.null(canopy)) {
    assert_crs_2154(canopy)
    assert_no_fine_extract_on_ifn(pts, "mhc")
    h <- terra::extract(canopy, terra::vect(pts))[, 2]
    pts <- pts[!is.na(h) & h > min_canopy, ]
    log <- .log_step(log, "canopee_sup_seuil", nrow(pts))
  }
  rownames(pts) <- NULL
  attr(pts, "clean_log") <- log
  pts
}

#' Regrouper des occurrences en mailles et calculer les valeurs bioindiquées
#'
#' Pose une grille de `cell` mètres calée sur l'origine (0, 0) de Lambert-93 (donc sur un
#' multiple de 50 m, ADR 0004). Dans chaque maille, les espèces sont dédoublonnées ; seules
#' celles présentes dans `indicateurs` comptent comme **espèces indicatrices**. Une maille
#' est exploitable si elle en compte au moins `min_species` (brief technique, § 4 étape 4) ;
#' ce nombre est conservé comme poids (`poids`). La valeur bioindiquée de chaque gradient
#' est la moyenne, sur les espèces indicatrices de la maille, de la valeur indicatrice.
#'
#' Les noms d'espèces sont comparés tels quels (espaces rognés, casse ignorée) : GBIF
#' emploie le référentiel GBIF, Baseflor TAXREF. Une table de correspondance de
#' synonymes reste **à faire** (à vérifier) ; sans elle, des espèces indicatrices se
#' perdent.
#'
#' @param occ Points `sf` en EPSG:2154 issus de [clean_occ()] (colonnes `species` et
#'   `loc_precision_m`). Refusés si la précision est absente, `NA` ou supérieure à
#'   `cell / 2` (le point pourrait tomber dans une autre maille).
#' @param indicateurs `data.frame` : colonne `species` et une ou plusieurs colonnes
#'   numériques (une par gradient, ex. `trophique`, `humidite`). Format provisoire du
#'   jeu synthétique `synth_indicateurs.csv`, à aligner sur la mission 006 (à vérifier).
#' @param cell Côté de la maille, en mètres (50).
#' @param min_species Nombre minimal d'espèces indicatrices par maille (5).
#' @return Un `sf` de polygones (mailles exploitables, EPSG:2154) : `cell_id`, `x_min`,
#'   `y_min` (coin sud-ouest), `n_occ`, `poids`, une colonne par gradient, et les
#'   attributs `n_mailles_occupees` (mailles comptant au moins une occurrence),
#'   `n_mailles_exploitables` et `cell`.
#' @examples
#' p <- sf::st_as_sf(data.frame(x = c(1010010, 1010020), y = c(6795010, 6795020),
#'                              species = c("A a", "B b"), loc_precision_m = 10),
#'                   coords = c("x", "y"), crs = 2154)
#' ind <- data.frame(species = c("A a", "B b"), trophique = c(2, 4))
#' nrow(grid_bioindication(p, ind, min_species = 2))
#' @export
grid_bioindication <- function(occ, indicateurs, cell = 50, min_species = 5) {
  if (!inherits(occ, "sf")) stop("`occ` doit \u00eatre un objet sf.", call. = FALSE)
  assert_crs_2154(occ)
  if (!is.numeric(cell) || length(cell) != 1L || is.na(cell) || cell <= 0) {
    stop("`cell` doit \u00eatre un nombre positif (m).", call. = FALSE)
  }
  if (!is.numeric(min_species) || length(min_species) != 1L || is.na(min_species) ||
      min_species < 1) {
    stop("`min_species` doit \u00eatre un entier positif.", call. = FALSE)
  }
  if (!"species" %in% names(occ)) stop("Colonne `species` manquante dans `occ`.", call. = FALSE)
  if (.precision_insuffisante(occ, cell / 2)) {
    stop("Pr\u00e9cision de localisation (`loc_precision_m`) absente, NA ou sup\u00e9rieure \u00e0 ",
         cell / 2, " m (demi-maille) : regroupement en mailles de ", cell, " m refus\u00e9.",
         call. = FALSE)
  }
  if (!is.data.frame(indicateurs) || !"species" %in% names(indicateurs)) {
    stop("`indicateurs` doit \u00eatre un data.frame avec une colonne `species`.", call. = FALSE)
  }
  grad <- setdiff(names(indicateurs)[vapply(indicateurs, is.numeric, logical(1))], "synthetic")
  if (!length(grad)) {
    stop("`indicateurs` n'a aucune colonne num\u00e9rique de gradient.", call. = FALSE)
  }

  norm <- function(s) tolower(trimws(as.character(s)))
  xy <- sf::st_coordinates(occ)  # colonnes X (est), Y (nord)
  d <- data.frame(ix = floor(xy[, 1] / cell), iy = floor(xy[, 2] / cell),
                  sp = norm(occ$species), stringsAsFactors = FALSE)
  d$cell_id <- paste(d$ix, d$iy, sep = "_")
  n_occ <- table(d$cell_id)
  occupees <- length(n_occ)

  ind <- indicateurs[!duplicated(norm(indicateurs$species)), c("species", grad), drop = FALSE]
  ind$sp <- norm(ind$species)
  d <- unique(d[, c("cell_id", "ix", "iy", "sp")])
  d <- merge(d, ind[, c("sp", grad)], by = "sp")   # garde les seules especes indicatrices
  if (nrow(d)) {
    n_sp <- table(d$cell_id)
    d <- d[d$cell_id %in% names(n_sp)[n_sp >= min_species], ]
  }
  if (!nrow(d)) {
    out <- sf::st_sf(cell_id = character(0), x_min = numeric(0), y_min = numeric(0),
                     n_occ = integer(0), poids = integer(0),
                     geometry = sf::st_sfc(crs = 2154))
    for (g in grad) out[[g]] <- numeric(0)
  } else {
    agg <- lapply(sort(unique(d$cell_id)), function(id) {
      s <- d[d$cell_id == id, ]
      r <- data.frame(cell_id = id, x_min = s$ix[1] * cell, y_min = s$iy[1] * cell,
                      n_occ = as.integer(n_occ[[id]]), poids = nrow(s),
                      stringsAsFactors = FALSE)
      for (g in grad) r[[g]] <- if (all(is.na(s[[g]]))) NA_real_ else mean(s[[g]], na.rm = TRUE)
      r
    })
    out <- do.call(rbind, agg)
    geom <- lapply(seq_len(nrow(out)), function(i) {
      x0 <- out$x_min[i]
      y0 <- out$y_min[i]
      sf::st_polygon(list(matrix(c(x0, y0, x0 + cell, y0, x0 + cell, y0 + cell,
                                   x0, y0 + cell, x0, y0), ncol = 2, byrow = TRUE)))
    })
    out <- sf::st_sf(out, geometry = sf::st_sfc(geom, crs = 2154))
  }
  attr(out, "n_mailles_occupees") <- occupees
  attr(out, "n_mailles_exploitables") <- nrow(out)
  attr(out, "cell") <- cell
  out
}

#' Lire des relevés GNSS propres
#'
#' Lit un CSV de relevés GNSS (30 à 50 points par massif test, brief technique, § 4
#' étape 4) : un point par ligne, ou une ligne par couple point-espèce. Colonnes :
#' `id` (identifiant du point), `x`, `y` (est, nord ; ou longitude, latitude si
#' `epsg = 4326`), **`loc_precision_m`** (précision horizontale en mètres, obligatoire,
#' numérique, positive, sans `NA`) ; facultatives : `species` et toute autre colonne
#' (conservée). Les relevés sont convertis en EPSG:2154 dès la lecture.
#'
#' @param path Chemin du CSV (séparateur virgule, UTF-8).
#' @param epsg Système des colonnes `x`/`y` : 2154 (défaut) ou 4326.
#' @return Un `sf` de points en EPSG:2154, avec `source = "gnss"` et `loc_precision_m`.
#' @examples
#' f <- system.file("extdata", "synth_gnss.csv", package = "sylvostation")
#' if (nzchar(f)) nrow(load_gnss(f))
#' @export
load_gnss <- function(path, epsg = 2154) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Fichier GNSS introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  if (!epsg %in% c(2154, 4326)) stop("`epsg` doit valoir 2154 ou 4326.", call. = FALSE)
  d <- utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  manque <- setdiff(c("id", "x", "y", "loc_precision_m"), names(d))
  if (length(manque)) {
    stop("Colonnes manquantes dans le fichier GNSS : ", paste(manque, collapse = ", "),
         ". La pr\u00e9cision horizontale `loc_precision_m` est obligatoire.", call. = FALSE)
  }
  if (!is.numeric(d$x) || !is.numeric(d$y) || anyNA(d$x) || anyNA(d$y)) {
    stop("Coordonn\u00e9es `x`/`y` non num\u00e9riques ou manquantes.", call. = FALSE)
  }
  if (!is.numeric(d$loc_precision_m) || anyNA(d$loc_precision_m) ||
      any(d$loc_precision_m <= 0)) {
    stop("`loc_precision_m` doit \u00eatre num\u00e9rique, positive et sans NA.", call. = FALSE)
  }
  pts <- sf::st_as_sf(d, coords = c("x", "y"), crs = epsg)  # x = est/longitude, y = nord/latitude
  if (epsg != 2154) pts <- sf::st_transform(pts, 2154)
  assert_crs_2154(pts)
  pts$source <- "gnss"
  pts
}
