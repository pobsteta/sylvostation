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

#' Jeux GBIF Pl@ntNet (identification par algorithme)
#'
#' `datasetKey` des deux jeux Pl@ntNet vus dans l'emprise (`docs/referentiels.md`, § 8 et
#' § 33.1) : « Pl@ntNet automatically identified occurrences » et « Pl@ntNet
#' observations ». Une photo = une espèce, identification non validée : `clean_occ()` les
#' écarte par défaut. Liste **non exhaustive** : d'autres jeux Pl@ntNet peuvent exister
#' ailleurs (à vérifier hors emprise).
#' @format Un vecteur de caractères.
#' @export
PLANTNET_GBIF_DATASET_KEYS <- c("14d5676a-2c54-4f94-9023-1e8dcd822aa0",
                                "7a3679ef-5582-4aaa-81f0-8c2545cafc81")

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
#' @param format Mode `"download"` : format du téléchargement, `"SIMPLE_CSV"` (défaut, celui
#'   du brief technique, léger : une table à plat) ou `"DWCA"`. **`DWCA` apporte les
#'   colonnes `dataGeneralizations` et `informationWithheld`**, qui permettent à
#'   [clean_occ()] de reconnaître les données généralisées (`loc_precision_m = NA`) ; avec
#'   `SIMPLE_CSV`, ces colonnes sont absentes (présence **à vérifier** au premier
#'   téléchargement réel) et seule l'incertitude déclarée décide. Choisir `"DWCA"` si l'on
#'   garde les points sans incertitude (`keep_unknown = TRUE`).
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
                     path = tempdir(), wait = TRUE, format = c("SIMPLE_CSV", "DWCA")) {
  method <- match.arg(method)
  format <- match.arg(format)
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
                c(preds, list(format = format, checklistKey = .GBIF_BACKBONE_KEY,
                              user = user, pwd = pwd, email = email)))
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

# Licence GBIF : URL (\"http://creativecommons.org/licenses/by-nc/4.0/legalcode\") ou code
# (\"CC_BY_NC_4_0\") -> code de type CC_BY_NC_4_0 ; CC0 -> CC0_1_0. Autre valeur : inchangee.
.normalise_licence <- function(x) {
  x <- as.character(x)
  m <- regmatches(x, regexec("creativecommons\\.org/licenses/([a-z-]+)/([0-9.]+)", x))
  out <- vapply(seq_along(x), function(i) {
    if (length(m[[i]]) == 3L) {
      paste0("CC_", toupper(gsub("-", "_", m[[i]][2])), "_", gsub("\\.", "_", m[[i]][3]))
    } else if (!is.na(x[i]) && grepl("publicdomain/zero", x[i])) {
      "CC0_1_0"
    } else if (!is.na(x[i]) && grepl("^\\s*CC[ _-]*(BY|0)", x[i], ignore.case = TRUE)) {
      # ecriture en toutes lettres (« CC BY-NC 4.0 ») : meme code que les autres formes
      gsub("^_+|_+$", "", gsub("[^A-Z0-9]+", "_", toupper(x[i])))
    } else x[i]
  }, character(1))
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
#' 2 bis. licence et Pl@ntNet, **dans cet ordre**, chaque occurrence n'étant comptée que
#'    par le premier motif qui l'écarte : (i) licence non commerciale (code `CC_BY_NC*`,
#'    toute variante, URL, code ou écriture en toutes lettres) si `exclude_noncommercial`
#'    (défaut `TRUE`) ; (ii) jeux de `exclude_plantnet` (défaut [PLANTNET_GBIF_DATASET_KEYS]) ;
#'    (iii) licence absente, `UNSPECIFIED`, `UNSUPPORTED` ou autre qu'un code `CC_BY_<n>` (variantes comprises : la variante NC dépend de `exclude_noncommercial`) ou `CC0_1_0`
#'    (motif `licence_inconnue`) si `exclude_unknown_licence` (défaut `TRUE` : la fiche 037
#'    veut du CC BY seulement). Les effectifs par motif sont rendus dans l'attribut
#'    `ecartees` et dans le message émis (jamais de suppression silencieuse) ;
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
#' La licence de chaque jeu (`license`) est conservée et normalisée en code de type
#' `CC_BY_4_0`, `CC_BY_NC_4_0` ou `CC0_1_0` (GBIF la donne tantôt en URL, tantôt en code).
#'
#' @param occ `data.frame` d'occurrences GBIF (WGS84) : `decimalLongitude`,
#'   `decimalLatitude`, `species` ; facultatives : `gbifID` (ou `key` en mode `"search"`), `speciesKey`, `datasetKey`,
#'   `license`, `year`, `coordinateUncertaintyInMeters`, `dataGeneralizations`,
#'   `informationWithheld`.
#' @param max_uncertainty Précision maximale gardée, en mètres (25).
#' @param exclude_datasets `datasetKey` à écarter.
#' @param exclude_noncommercial Écarter les licences `CC_BY_NC*` (`TRUE`).
#' @param exclude_unknown_licence Écarter les licences absentes ou autres que la famille CC BY et CC0
#'   (`TRUE`).
#' @param exclude_plantnet `datasetKey` Pl@ntNet à écarter (défaut
#'   [PLANTNET_GBIF_DATASET_KEYS] ; `character(0)` pour les garder).
#' @param keep_unknown Garder les points de précision inconnue (`FALSE`).
#' @param forest Polygones BD Forêt (`sf`, EPSG:2154, colonne `code_tfv`) ou `NULL`.
#' @param canopy `SpatRaster` de hauteur de canopée (EPSG:2154) ou `NULL`.
#' @param min_canopy Hauteur minimale de canopée, en mètres (5).
#' @return Un objet `sf` (points, EPSG:2154) avec `gbif_id`, `species`, `species_key`,
#'   `dataset_key`, `license`, `year`, `loc_precision_m`, `source`, et les attributs
#'   `clean_log` et `ecartees` (`data.frame` `motif`, `n` : `licence_non_commerciale`,
#'   `plantnet`, `licence_inconnue`).
#' @examples
#' f <- system.file("extdata", "synth_occ.csv", package = "sylvostation")
#' if (nzchar(f)) {
#'   p <- clean_occ(utils::read.csv(f))
#'   attr(p, "clean_log")
#' }
#' @export
clean_occ <- function(occ, max_uncertainty = 25, exclude_datasets = IFN_GBIF_DATASET_KEYS,
                      exclude_noncommercial = TRUE,
                      exclude_plantnet = PLANTNET_GBIF_DATASET_KEYS,
                      exclude_unknown_licence = TRUE,
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
    cd_ref = suppressWarnings(as.numeric(col("cd_ref", NA_real_))),
    dataset_key = as.character(col("datasetKey", NA_character_)),
    license = .normalise_licence(col("license", NA_character_)),
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

  # 2 bis. licence non commerciale, Pl@ntNet, licence inconnue : dans cet ordre, chaque
  # motif compte les occurrences qu'il ecarte lui-meme (jamais en silence)
  lic <- gsub("^_+|_+$", "", gsub("[^A-Z0-9]+", "_", toupper(as.character(pts$license))))
  nc <- if (isTRUE(exclude_noncommercial)) !is.na(pts$license) & grepl("^CC_BY_NC", lic) else
    rep(FALSE, nrow(pts))
  pts <- pts[!nc, ]
  lic <- lic[!nc]
  log <- .log_step(log, "hors_licence_nc", nrow(pts))
  pn <- if (length(exclude_plantnet)) {
    !is.na(pts$dataset_key) & pts$dataset_key %in% exclude_plantnet
  } else rep(FALSE, nrow(pts))
  pts <- pts[!pn, ]
  lic <- lic[!pn]
  log <- .log_step(log, "hors_plantnet", nrow(pts))
  inconnue <- if (isTRUE(exclude_unknown_licence)) {
    is.na(pts$license) | !grepl("^(CC_BY(_[A-Z]+)*_[0-9]|CC0_1_0)", lic)
  } else rep(FALSE, nrow(pts))
  pts <- pts[!inconnue, ]
  log <- .log_step(log, "hors_licence_inconnue", nrow(pts))
  ecartees <- data.frame(motif = c("licence_non_commerciale", "plantnet", "licence_inconnue"),
                         n = c(sum(nc), sum(pn), sum(inconnue)), stringsAsFactors = FALSE)
  message("clean_occ : ", ecartees$n[1], " occurrence(s) ecartee(s) pour licence non ",
          "commerciale, ", ecartees$n[2], " pour Pl@ntNet, ", ecartees$n[3],
          " pour licence absente ou non reconnue.")

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
  attr(pts, "ecartees") <- ecartees
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
#' GBIF emploie le référentiel GBIF, Baseflor TAXREF : sans `cd_ref` dans `occ`, le repli
#' par nom perd des espèces indicatrices. Elles sont listées dans l'attribut
#' `especes_non_appariees`, jamais supprimées en silence.
#'
#' @param occ Points `sf` en EPSG:2154 issus de [clean_occ()] (colonnes `species` et
#'   `loc_precision_m`). Refusés si la précision est absente, `NA` ou supérieure à
#'   `cell / 2` (le point pourrait tomber dans une autre maille).
#' @param indicateurs `data.frame` des valeurs indicatrices, format partagé de la mission
#'   006 (`inst/extdata/synth_indicateurs.csv`, séparateur `;`) : `cd_ref`, `nom`, et une
#'   colonne numérique par gradient (`ph`, `azote`, `humidite`). Les colonnes `cd_ref`,
#'   `cd_nom`, `id` et `synthetic` ne sont jamais des gradients. L'appariement se fait sur
#'   `cd_ref` quand `occ` et `indicateurs` le portent, sinon sur le nom (`nom` ou
#'   `species`, nom vernaculaire entre parenthèses ignoré ; repli **à vérifier** : la
#'   table GBIF vers TAXREF `CD_REF` manque).
#' @param cell Côté de la maille, en mètres (50).
#' @param min_species Nombre minimal d'espèces indicatrices par maille (5).
#' @return Un `sf` de polygones (mailles exploitables, EPSG:2154) : `cell_id`, `x_min`,
#'   `y_min` (coin sud-ouest), `n_occ`, `poids`, une colonne par gradient, et les
#'   attributs `n_mailles_occupees` (mailles comptant au moins une occurrence),
#'   `n_mailles_exploitables`, `cell`, `especes_non_appariees` (espèces
#'   d'`occ` absentes de `indicateurs`, avec leur nombre d'occurrences) et `log_appariement`.
#' @examples
#' p <- sf::st_as_sf(data.frame(x = c(1010010, 1010020), y = c(6795010, 6795020),
#'                              species = c("A a", "B b"), loc_precision_m = 10),
#'                   coords = c("x", "y"), crs = 2154)
#' ind <- data.frame(nom = c("A a", "B b"), trophique = c(2, 4))
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
  nom_col <- intersect(c("nom", "species"), names(indicateurs))[1]
  if (!is.data.frame(indicateurs) || (is.na(nom_col) && !"cd_ref" %in% names(indicateurs))) {
    stop("`indicateurs` doit \u00eatre un data.frame avec une colonne `cd_ref`, `nom` ou `species`.",
         call. = FALSE)
  }
  # gradients = colonnes numeriques hors identifiants et marques
  non_grad <- c("cd_ref", "cd_nom", "id", "synthetic")
  grad <- setdiff(names(indicateurs)[vapply(indicateurs, is.numeric, logical(1))], non_grad)
  if (!length(grad)) {
    stop("`indicateurs` n'a aucune colonne num\u00e9rique de gradient.", call. = FALSE)
  }

  # nom sans nom vernaculaire entre parentheses, casse et espaces ignores
  norm <- function(s) tolower(trimws(sub("\\s*\\(.*\\)\\s*$", "", as.character(s))))
  xy <- sf::st_coordinates(occ)  # colonnes X (est), Y (nord)
  d <- data.frame(ix = floor(xy[, 1] / cell), iy = floor(xy[, 2] / cell),
                  sp = norm(occ$species), stringsAsFactors = FALSE)
  d$cell_id <- paste(d$ix, d$iy, sep = "_")
  n_occ <- table(d$cell_id)
  occupees <- length(n_occ)

  # Appariement : par cd_ref si occ et indicateurs le portent ; a defaut, par nom
  # (a verifier : la table GBIF -> TAXREF CD_REF manque ; un nom GBIF different du nom
  # TAXREF n'apparie pas). Les non apparies sont listes, jamais supprimes en silence.
  i_nom <- if (is.na(nom_col)) rep(NA_integer_, nrow(d)) else
    match(d$sp, norm(indicateurs[[nom_col]]))
  i_ref <- rep(NA_integer_, nrow(d))
  if ("cd_ref" %in% names(occ) && "cd_ref" %in% names(indicateurs)) {
    i_ref <- match(suppressWarnings(as.numeric(occ$cd_ref)),
                   suppressWarnings(as.numeric(indicateurs$cd_ref)))
  }
  d$ind_id <- ifelse(!is.na(i_ref), i_ref, i_nom)
  par_ref <- sum(!is.na(i_ref))
  par_nom <- sum(is.na(i_ref) & !is.na(i_nom))
  non <- is.na(d$ind_id)
  non_app <- if (any(non)) {
    t <- table(as.character(occ$species)[non])
    data.frame(species = names(t), n_occ = as.integer(t), stringsAsFactors = FALSE)
  } else data.frame(species = character(0), n_occ = integer(0))
  non_app <- non_app[order(-non_app$n_occ, non_app$species), , drop = FALSE]
  rownames(non_app) <- NULL
  log_app <- data.frame(
    etape = c("apparie_cd_ref", "apparie_nom_a_verifier", "non_apparie"),
    n = c(par_ref, par_nom, sum(non)), stringsAsFactors = FALSE)

  d <- unique(d[!non, c("cell_id", "ix", "iy", "ind_id")])
  d <- cbind(d, indicateurs[d$ind_id, grad, drop = FALSE])  # une ligne par espece indicatrice
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
  attr(out, "especes_non_appariees") <- non_app
  attr(out, "log_appariement") <- log_app
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
