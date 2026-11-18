# Gradient hydrique (mission 019, ADR 0006) : dictionnaire IFN des codes de texture,
# granulometrie representative (soiltexture), reserve utile par euptf2, indice de
# contrainte hydrique BILJOU (biljouR) sur climat SAFRAN.

#' Lire le dictionnaire IFN des codes de texture
#'
#' Lit l'extrait du fichier `metadonnees.csv` des données brutes de l'IFN (archive
#' `export_dataifn_2005_2025.zip`, Licence Ouverte 2.0) qui définit les modalités des
#' unités `TEXT` (campagnes 2005-2016) et `TEXT1` (campagnes 2017 et suivantes),
#' utilisées par les colonnes `TEXT1` et `TEXT2` d'`ECOLOGIE` (`docs/referentiels.md`,
#' § 22). Chaque code 1 à 9 y est défini par une liste d'abréviations de classes de
#' texture (par exemple `4` : « Ls, Lsa, Lms, Lls : limon dominant + sable »). Les
#' abréviations sont lues dans la définition (texte avant « : »), jamais recopiées à
#' la main.
#'
#' Les abréviations sont celles du **triangle de l'Aisne** (Jamagne, 1967 ; classes de
#' `soiltexture::TT.get("FR.AISNE.TT")`) : les 15 classes de ce triangle y figurent
#' chacune une fois, et les codes 1 à 9 en forment une partition. L'IFN ne nomme pas
#' le triangle : l'identification est faite par les abréviations. Une abréviation
#' n'appartient pas au triangle de l'Aisne : `Als` (code 8, « argile limono-sableuse »
#' du triangle du GEPPA) ; elle est rendue dans `hors_triangle`.
#'
#' @param path Chemin de l'extrait (par défaut `inst/extdata/ifn_texture_dictionnaire.csv`).
#' @param unite `"TEXT1"` (2017 et suivantes, avec le code `H`) ou `"TEXT"` (2005-2016).
#' @return Un `data.frame` : `unite`, `campagnes`, `code`, `libelle`, `definition`,
#'   `classes` (abréviations en majuscules, séparées par des virgules), `classes_aisne`
#'   (celles du triangle de l'Aisne), `hors_triangle`. Codes `0` (absence de terre fine)
#'   et `H` (texture organique) : classes vides.
#' @examples
#' read_texture_dictionary()[, c("code", "libelle", "classes_aisne")]
#' @export
read_texture_dictionary <- function(path = system.file("extdata", "ifn_texture_dictionnaire.csv",
                                                       package = "sylvostation"),
                                    unite = c("TEXT1", "TEXT")) {
  unite <- match.arg(unite)
  if (!nzchar(path) || !file.exists(path)) {
    stop("Dictionnaire IFN des textures introuvable : ", path, call. = FALSE)
  }
  d <- utils::read.delim(path, sep = ";", colClasses = "character", encoding = "UTF-8")
  requis <- c("unite", "campagnes", "code", "libelle", "definition")
  if (!all(requis %in% names(d))) {
    stop("Dictionnaire : colonnes manquantes : ",
         paste(setdiff(requis, names(d)), collapse = ", "), call. = FALSE)
  }
  d <- d[d$unite == unite, requis, drop = FALSE]
  aisne <- .AISNE_CLASSES
  cls <- lapply(d$definition, function(def) {
    if (!grepl(":", def, fixed = TRUE)) return(character(0))
    # espaces insecables (U+00A0) avant le deux-points dans metadonnees.csv
    toupper(trimws(strsplit(sub(":.*$", "", def), ",", fixed = TRUE)[[1]],
                   whitespace = "[\\h\\v]"))
  })
  d$classes <- vapply(cls, paste, character(1), collapse = ",")
  d$classes_aisne <- vapply(cls, function(x) paste(x[x %in% aisne], collapse = ","), character(1))
  d$hors_triangle <- vapply(cls, function(x) paste(x[!x %in% aisne], collapse = ","), character(1))
  attr(d, "source") <- paste("IGN, Inventaire forestier national, donnees brutes,",
                             "metadonnees.csv (export du 2026-10-07), Licence Ouverte 2.0")
  rownames(d) <- NULL
  d
}

# Classes du triangle de l'Aisne, abreviations de soiltexture::TT.get("FR.AISNE.TT").
.AISNE_CLASSES <- c("ALO", "A", "AL", "AS", "LA", "LAS", "LSA", "SA", "LM", "LMS", "LS",
                    "SL", "S", "LL", "LLS")

# Aire signee et centre de gravite d'un polygone (coordonnees cartesiennes x, y).
.aire_centre <- function(x, y) {
  x2 <- c(x[-1], x[1])
  y2 <- c(y[-1], y[1])
  cr <- x * y2 - x2 * y
  a <- sum(cr) / 2
  c(aire = abs(a), cx = sum((x + x2) * cr) / (6 * a), cy = sum((y + y2) * cr) / (6 * a))
}

#' Granulométrie représentative d'un code de texture IFN
#'
#' Pour chaque code de texture IFN, rend les pourcentages d'argile (< 2 µm), de limon
#' (2-50 µm) et de sable (50-2000 µm) du **centre de gravité** de la réunion des
#' polygones de ses classes dans le triangle de l'Aisne (`soiltexture`,
#' `FR.AISNE.TT`, mêmes limites granulométriques que les fonctions de pédotransfert
#' `euptf2`). Le centre de la réunion est la moyenne des centres des classes pondérée
#' par leur aire ; il est calculé dans le plan (argile, limon), image affine du
#' triangle, qui conserve centres et rapports d'aires. Les classes hors du triangle
#' (`Als`, code 8) ne sont pas comptées (colonne `hors_triangle`).
#'
#' C'est une valeur **représentative**, pas une mesure : la texture IFN est estimée au
#' toucher et la classe couvre une plage (voir `aire`, part du triangle couverte).
#'
#' @param code Vecteur de codes de texture IFN (`"0"` à `"9"`, `"H"`).
#' @param dictionnaire Résultat de [read_texture_dictionary()].
#' @return Un `data.frame`, une ligne par élément de `code` : `code`, `argile`, `limon`,
#'   `sable` (%), `classes` (classes de l'Aisne retenues), `hors_triangle`, `aire`
#'   (part de l'aire du triangle). `NA` pour `0`, `H`, un code vide ou inconnu.
#' @examples
#' texture_to_psd(c("1", "4", "6", "9", "H"))
#' @export
texture_to_psd <- function(code, dictionnaire = read_texture_dictionary()) {
  if (!requireNamespace("soiltexture", quietly = TRUE)) {
    stop("Le paquet `soiltexture` est requis (install.packages(\"soiltexture\")).",
         call. = FALSE)
  }
  tt <- soiltexture::TT.get("FR.AISNE.TT")
  pts <- tt$tt.points
  poly <- lapply(tt$tt.polygons, function(p) .aire_centre(pts$CLAY[p$points], pts$SILT[p$points]))
  code <- toupper(trimws(as.character(code)))
  ligne <- function(k) {
    vide <- data.frame(code = k, argile = NA_real_, limon = NA_real_, sable = NA_real_,
                       classes = NA_character_, hors_triangle = NA_character_,
                       aire = NA_real_, stringsAsFactors = FALSE)
    i <- match(k, dictionnaire$code)
    if (is.na(k) || is.na(i) || !nzchar(dictionnaire$classes_aisne[i])) return(vide)
    cl <- strsplit(dictionnaire$classes_aisne[i], ",", fixed = TRUE)[[1]]
    m <- do.call(rbind, poly[cl])
    a <- m[, "aire"]
    cx <- sum(a * m[, "cx"]) / sum(a)
    cy <- sum(a * m[, "cy"]) / sum(a)
    data.frame(code = k, argile = 100 * cx, limon = 100 * cy, sable = 100 * (1 - cx - cy),
               classes = dictionnaire$classes_aisne[i],
               hors_triangle = dictionnaire$hors_triangle[i],
               aire = sum(a) / 0.5, stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, lapply(code, ligne))
  rownames(out) <- NULL
  out
}

# Charge en elements grossiers (CAILLOUX) : fraction du volume au centre de la classe
# IFN (unites 1/10PCT et 1/10PCT_X de metadonnees.csv) : 0 = moins de 5 % -> 0,025 ;
# k = 1..9 -> k/10 ; 10 = plus de 95 % -> 0,975 ; X = absence -> 0 ; vide -> 0.
.cailloux_frac <- function(x) {
  x <- toupper(trimws(as.character(x)))
  k <- suppressWarnings(as.numeric(x))
  f <- ifelse(is.na(k), 0, ifelse(k <= 0, 0.025, ifelse(k >= 10, 0.975, k / 10)))
  f[x %in% "X"] <- 0
  f
}

# Couches d'une placette : epaisseurs (cm), codes et profondeurs moyennes (cm).
# PROF1 = profondeur de l'horizon superieur, PROF2 = profondeur de sondage (dm).
# Sol homogene : TEXT1 = 0 ou vide, PROF1 vide (IGN_DB_doc_ecologie.pdf, p. 6).
.couches_sol <- function(pl) {
  col <- function(v) {
    if (v %in% names(pl)) toupper(trimws(as.character(pl[[v]])))
    else rep(NA_character_, nrow(pl))
  }
  p1 <- suppressWarnings(as.numeric(col("PROF1"))) * 10
  p2 <- suppressWarnings(as.numeric(col("PROF2"))) * 10
  t1 <- col("TEXT1")
  t2 <- col("TEXT2")
  t1[t1 %in% ""] <- NA_character_
  t2[t2 %in% ""] <- NA_character_
  deux <- !is.na(p1) & !is.na(t1)
  obs <- col("OBSPEDO")
  data.frame(
    ep_haut = ifelse(deux, p1, 0),
    ep_bas = p2 - ifelse(deux, p1, 0),
    z_haut = ifelse(deux, p1 / 2, NA_real_),
    z_bas = ifelse(deux, (p1 + p2) / 2, p2 / 2),
    code_haut = ifelse(deux, t1, NA_character_),
    code_bas = t2,
    cail = .cailloux_frac(col("CAILLOUX")),
    sans_fosse = obs %in% c("5", "X") | is.na(p2) | is.na(t2),
    organique = t1 %in% "H" | t2 %in% "H",
    caillouteux = obs %in% "R",
    stringsAsFactors = FALSE)
}

# Paquet disponible ? (enveloppe de requireNamespace, remplacable dans les tests)
.has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)

# Prediction ponctuelle euptf2 d'une cible (FC_2, FC, WP) ; les objets ranger sont lus
# par utils::data(package =) : euptfFun() exige le paquet attache et ecrit dans
# l'environnement global.
.euptf_pred <- function(cible, ptf, df) {
  e <- new.env(parent = emptyenv())
  nom <- paste(cible, ptf, sep = "_")
  utils::data(list = nom, package = "euptf2", envir = e)
  suppressWarnings(euptf2::ptfFun.pred(e[[nom]], df))
}

# Eau disponible (cm3/cm3) par euptf2 pour des (code, profondeur moyenne cm), calculee
# comme difference de fonctions ponctuelles (README d'euptf2) : AWC_2 = FC_2 - WP
# (pF 2,0 - 4,2), AWC = FC - WP (pF 2,5 - 4,2).
# PTF01 : predicteurs USSAND, USSILT, USCLAY, DEPTH_M (which_PTF(), verifie le 2026-11-17).
.euptf_awc <- function(code, z, cible, ptf, psd) {
  out <- rep(NA_real_, length(code))
  zero <- code %in% "0"
  out[zero] <- 0
  i <- match(code, psd$code)
  ok <- !is.na(i) & !is.na(psd$argile[i]) & !is.na(z)
  if (!any(ok)) return(out)
  df <- data.frame(USSAND = psd$sable[i[ok]], USSILT = psd$limon[i[ok]],
                   USCLAY = psd$argile[i[ok]], DEPTH_M = z[ok])
  fc <- if (cible == "AWC_2") "FC_2" else "FC"
  out[ok] <- .euptf_pred(fc, ptf, df) - .euptf_pred("WP", ptf, df)
  out
}

#' Réserve utile par la texture IFN : euptf2, contre-vérifiée par Bruand et al. (2004)
#'
#' Chaîne de l'ADR 0006 : code de texture IFN ([read_texture_dictionary()]) →
#' granulométrie représentative ([texture_to_psd()]) → eau disponible par la fonction
#' de pédotransfert européenne `euptf2` (Szabó, Weynants et Weber 2021, *Geoscientific
#' Model Development* 14 : 151-175 ; PTF01 : sable, limon, argile et profondeur) →
#' réserve utile `ru_mm` = somme sur les deux horizons de l'eau disponible × épaisseur,
#' réduite par la charge en éléments grossiers.
#'
#' * **Eau disponible** : `cible = "AWC_2"` (défaut) = θ à -100 cm (pF 2,0) moins θ à
#'   -15 000 cm (pF 4,2), comme la colonne « défaut » de Bruand et al. ; `"AWC"` :
#'   capacité au champ à -330 cm (pF 2,5). Calculée comme **différence des fonctions
#'   ponctuelles** `FC_2` (ou `FC`) et `WP`, comme le recommande le README d'`euptf2`,
#'   et non par la fonction `AWC_2` directe. Profondeur `DEPTH_M` : milieu de l'horizon.
#' * **Horizons** : `PROF1` (horizon supérieur, dm) et `PROF2` (profondeur de sondage,
#'   dm) ; sol homogène (`TEXT1` 0 ou vide, `PROF1` vide) : un seul horizon `TEXT2`.
#' * **Cailloux** : `CAILLOUX` en dixièmes du volume, pris au centre de la classe IFN
#'   (`0` = moins de 5 % → 2,5 % ; `10` = plus de 95 % → 97,5 % ; `X` = absence).
#' * **Cas particuliers** : sans fosse (`OBSPEDO` 5 ou X), sans `PROF2` ou `TEXT2` : `NA` ;
#'   horizon organique (`H`) : `NA` (non modélisé) ; `OBSPEDO` R (horizon entièrement
#'   caillouteux) : 0 ; code `0` (absence de terre fine) : 0 pour l'horizon.
#'
#' **Deux sources** : `ru_euptf2_mm` (chaîne ci-dessus) et `ru_bruand_mm`, calculée avec
#' les mêmes épaisseurs et cailloux et les coefficients de [ru_coefficients()] (Bruand
#' et al. 2004, colonne défaut, horizon A pour `TEXT1`, horizons E, B, C pour `TEXT2`).
#' `ru_mm` reprend celle de `ru_source` (`"euptf2"` par défaut, décision de
#' l'orchestrateur du 2026-11-17) ; `ecart_mm` = `ru_euptf2_mm` - `ru_bruand_mm`. Avec
#' `ru_source = "bruand2004"`, `euptf2` et `soiltexture` ne sont pas requis (colonnes
#' `euptf2` à `NA` s'ils manquent).
#'
#' `ru_verifie` (attribut) vaut `TRUE` seulement si la chaîne est entièrement sourcée :
#' dictionnaire IFN lu, classes identifiées dans le triangle de l'Aisne, `euptf2`
#' appelé. La colonne `texture_partielle` signale les placettes dont un code comporte
#' une classe hors du triangle (`Als`, code 8), non représentée dans la granulométrie.
#'
#' @param pl Tableau des placettes (`ifn$placettes` de [load_ifn()], `sf` accepté) avec
#'   `PROF1`, `PROF2`, `TEXT1`, `TEXT2`, `CAILLOUX`, `OBSPEDO` (en caractères).
#' @param ru_source Source de `ru_mm` : `"euptf2"` (défaut) ou `"bruand2004"`.
#' @param cible `"AWC_2"` (pF 2,0, défaut) ou `"AWC"` (pF 2,5).
#' @param ptf Fonction de pédotransfert `euptf2` (`"PTF01"` : granulométrie et profondeur).
#' @param dictionnaire Résultat de [read_texture_dictionary()].
#' @return Un `data.frame` (une ligne par placette, `id_placette` si présent) :
#'   `ep_haut_cm`, `ep_bas_cm`, `code_haut`, `code_bas`, `cailloux`, `awc_haut`,
#'   `awc_bas` (cm3/cm3), `ru_euptf2_mm`, `ru_bruand_mm`, `ru_mm`, `ecart_mm`,
#'   `texture_partielle`. Attributs `ru_verifie`, `ru_source`, `source`, `cible`, `ptf`.
#' @examples
#' \donttest{
#' if (all(vapply(c("euptf2", "soiltexture", "ranger"), requireNamespace, TRUE,
#'                quietly = TRUE))) {
#'   ifn <- load_ifn(system.file("extdata", package = "sylvostation"),
#'                   files = c("PLACETTE", "ECOLOGIE"))
#'   ru <- ru_from_texture(ifn$placettes)
#'   summary(ru$ru_mm)
#' }
#' }
#' @export
ru_from_texture <- function(pl, ru_source = c("euptf2", "bruand2004"),
                            cible = c("AWC_2", "AWC"), ptf = "PTF01",
                            dictionnaire = read_texture_dictionary()) {
  ru_source <- match.arg(ru_source)
  cible <- match.arg(cible)
  if (!is.data.frame(pl)) stop("`pl` doit \u00eatre un tableau de placettes.", call. = FALSE)
  paquets <- c("euptf2", "ranger", "soiltexture")
  manque <- paquets[!vapply(paquets, .has_pkg, logical(1))]
  if (ru_source == "euptf2" && length(manque)) {
    stop("Paquet(s) requis : ", paste(manque, collapse = ", "),
         " (euptf2 : remotes::install_github(\"tkdweber/euptf2\")).", call. = FALSE)
  }
  avec_euptf <- !length(manque)
  if (!is.character(ptf) || length(ptf) != 1L || !grepl("^PTF[0-9]{2}$", ptf)) {
    stop("`ptf` doit \u00eatre de la forme \"PTF01\".", call. = FALSE)
  }
  if (inherits(pl, "sf")) pl <- sf::st_drop_geometry(pl)
  c0 <- .couches_sol(pl)
  codes <- unique(stats::na.omit(c(c0$code_haut, c0$code_bas)))
  if (avec_euptf) {
    psd <- texture_to_psd(codes, dictionnaire)
    awc_h <- .euptf_awc(c0$code_haut, c0$z_haut, cible, ptf, psd)
    awc_b <- .euptf_awc(c0$code_bas, c0$z_bas, cible, ptf, psd)
  } else {
    awc_h <- awc_b <- rep(NA_real_, nrow(c0))
  }
  awc_h[c0$ep_haut == 0] <- 0
  ru <- (c0$ep_haut * awc_h + c0$ep_bas * awc_b) * 10 * (1 - c0$cail)  # cm x cm3/cm3 x 10 = mm

  b <- ru_coefficients()
  coef <- function(code, tab) unname(tab[code])
  bh <- ifelse(c0$ep_haut == 0, 0, coef(c0$code_haut, b$haut))
  bb <- coef(c0$code_bas, b$bas)
  rub <- (c0$ep_haut * bh + c0$ep_bas * bb) * (1 - c0$cail)

  na <- c0$sans_fosse | c0$organique
  ru[na] <- NA_real_
  rub[na] <- NA_real_
  ru[c0$caillouteux] <- 0
  rub[c0$caillouteux] <- 0

  hors <- dictionnaire$code[nzchar(dictionnaire$hors_triangle)]
  out <- data.frame(
    ep_haut_cm = c0$ep_haut, ep_bas_cm = c0$ep_bas,
    code_haut = c0$code_haut, code_bas = c0$code_bas, cailloux = c0$cail,
    awc_haut = ifelse(c0$ep_haut == 0, NA_real_, awc_h), awc_bas = awc_b,
    ru_euptf2_mm = ru, ru_bruand_mm = rub,
    ru_mm = if (ru_source == "euptf2") ru else rub, ecart_mm = ru - rub,
    texture_partielle = c0$code_haut %in% hors | c0$code_bas %in% hors,
    stringsAsFactors = FALSE)
  if ("id_placette" %in% names(pl)) out <- cbind(id_placette = pl$id_placette, out)
  dico_ok <- !is.null(attr(dictionnaire, "source")) &&
    setequal(unlist(strsplit(dictionnaire$classes_aisne[nzchar(dictionnaire$classes_aisne)], ",")),
             .AISNE_CLASSES)
  attr(out, "ru_verifie") <- isTRUE(dico_ok)
  attr(out, "ru_source") <- ru_source
  attr(out, "cible") <- cible
  attr(out, "ptf") <- ptf
  attr(out, "source") <- paste0(
    "Dictionnaire IFN (metadonnees.csv) ; triangle de l'Aisne (soiltexture, FR.AISNE.TT), ",
    "centre de gravite des classes ; euptf2 ", ptf, " ", cible, " = ",
    if (cible == "AWC_2") "FC_2" else "FC", " - WP (Szabo et al. 2021) ; ",
    "Bruand et al. 2004 ; ru_mm = ", ru_source)
  out
}

# Mailles SAFRAN (SIM2) : centres en Lambert II etendu (LAMBX, LAMBY en hm, EPSG:27572),
# rendus en Lambert-93 (x = est, y = nord).
.mailles_safran <- function(safran) {
  m <- unique(safran[, c("LAMBX", "LAMBY")])
  m <- m[stats::complete.cases(m), , drop = FALSE]
  p <- sf::st_as_sf(data.frame(m, x = m$LAMBX * 100, y = m$LAMBY * 100),
                    coords = c("x", "y"), crs = 27572)
  xy <- sf::st_coordinates(sf::st_transform(p, 2154))
  data.frame(maille = paste(m$LAMBX, m$LAMBY, sep = "_"), LAMBX = m$LAMBX, LAMBY = m$LAMBY,
             x = xy[, 1], y = xy[, 2], stringsAsFactors = FALSE)
}

# Maille la plus proche de chaque point (x = est, y = nord, Lambert-93) ; NA au-dela de
# la demi-diagonale d'une maille de 8 km (point hors de la grille fournie).
.maille_proche <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  .maille_proche_vec(x, y, mailles, dmax)   # vectorise (mission 028) : meme resultat
}

# Reference lente de `.maille_proche()` (une boucle sur les points), pour le test d'egalite.
.maille_proche_ref <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  vapply(seq_along(x), function(i) {
    d <- sqrt((mailles$x - x[i])^2 + (mailles$y - y[i])^2)
    j <- which.min(d)
    if (!length(j) || d[j] > dmax) NA_character_ else mailles$maille[j]
  }, character(1))
}

# Indices BILJOU moyens (sur les annees) pour une meteo et des reserves utiles.
# Reference lente (mission 028) : une passe `biljouR::biljou_run()` par reserve utile.
# Gardee pour verifier que `.biljou_ru()` (vectorise) rend les memes resultats.
.biljou_ru_ref <- function(meteo, ru, param) {
  t(vapply(ru, function(r) {
    if (is.na(r) || r <= 0) return(c(is = NA_real_, nj = NA_real_, n = NA_real_))
    soil <- biljouR::biljou_soil(ewm = r)
    run <- biljouR::biljou_run(meteo, soil, lai_max = param$lai_max,
                               forest_type = param$forest_type,
                               budburst = param$budburst, leaf_fall = param$leaf_fall)
    idx <- biljouR::biljou_indices(run)
    c(is = mean(idx$Istress), nj = mean(idx$NJstress), n = nrow(idx))
  }, numeric(3)))
}

# Coeur BILJOU vectorise (mission 028). Meme bilan que `biljouR::biljou_run()` pour un sol
# a UNE couche (`biljou_soil(ewm = r)`, sans macroporosite), mais toutes les colonnes
# (couples profil de PET x reserve utile) avancent ensemble, jour par jour, au lieu d'une
# passe de 11 000 jours par colonne. Les fonctions de `biljouR` (interception, transpiration,
# sous-bois, LAI) sont appelees telles quelles, une fois, sur la serie entiere ; seule la
# boucle d'etat (reserve du sol) est ecrite ici, avec les memes operations dans le meme ordre
# (egalite a l'arrondi pres, testee contre `.biljou_ru_ref()`). Les sommes annuelles passent
# par `colSums()` comme `sum()` (accumulateur etendu).
#   meteo    : data.frame de `biljouR::safran_to_meteo()` (date, doy, rain, pet), tri par date ;
#   PET      : matrice (jours x profils) d'ETP, ou NULL (colonne `meteo$pet`) ;
#   prof_idx : profil de PET de chaque colonne ;  ewm : reserve utile (mm > 0) de chaque colonne.
# Rend une matrice (colonnes x is, nj, n) comme `.biljou_ru()`.
.biljou_cols <- function(meteo, PET = NULL, prof_idx = NULL, ewm, param, chunk = 200L) {
  rew_c <- 0.4; k <- 0.5; et_max_ratio <- 1.2; wet <- 0.2   # defauts de biljou_run()
  nd <- nrow(meteo)
  np <- length(ewm)
  out <- matrix(NA_real_, np, 3, dimnames = list(NULL, c("is", "nj", "n")))
  if (!np) return(out)
  if (is.null(PET)) PET <- matrix(meteo$pet, ncol = 1L)
  if (is.null(prof_idx)) prof_idx <- rep(1L, np)
  if (anyNA(meteo$rain) || anyNA(PET) || any(!is.finite(ewm)) || any(ewm <= 0)) {
    stop("BILJOU : pluie, ETP ou réserve utile manquante ou non positive.", call. = FALSE)
  }
  ft <- match.arg(param$forest_type, c("broadleaved", "coniferous"))
  doy <- if ("doy" %in% names(meteo)) meteo$doy else as.integer(format(as.Date(meteo$date), "%j"))
  year <- if (inherits(meteo$date, "Date")) as.integer(format(meteo$date, "%Y")) else rep(1L, nd)
  lai <- biljouR::biljou_lai(doy, param$lai_max, ft, param$budburst, param$leaf_fall)
  inter <- biljouR::rainfall_interception(meteo$rain, lai, ft, k = k)
  tf <- meteo$rain - inter
  ip <- if (ft == "broadleaved" && !is.null(param$budburst)) {
    doy >= param$budburst & doy <= param$leaf_fall
  } else rep(TRUE, nd)
  ipi <- cumsum(ip)                  # rang du jour dans la saison
  yr_ip <- year[ip]
  ans <- sort(unique(yr_ip))
  if (!length(ans)) return(out)
  for (d0 in seq(1L, np, by = chunk)) {
    cols <- d0:min(np, d0 + chunk - 1L)
    nc <- length(cols)
    P <- PET[, prof_idx[cols], drop = FALSE]
    tp0 <- t(matrix(pmax(0, biljouR::potential_transpiration(P, lai) - wet * inter), nd))
    eu0 <- t(biljouR::potential_understorey_evap(P, lai, k = k))
    cap <- t(et_max_ratio * P)
    w <- ewm[cols]
    ew <- w * 1
    SWD <- matrix(0, sum(ip), nc)
    NJ <- matrix(0, sum(ip), nc)
    for (t in seq_len(nd)) {
      rb <- ew / w
      low <- rb < rew_c
      tp <- tp0[, t]
      eu <- eu0[, t]
      if (any(low)) {
        f <- rb[low] / rew_c
        tp[low] <- tp[low] * f
        eu[low] <- eu[low] * f
      }
      eu <- pmax(0, eu)
      dry <- tp + eu
      sc <- (dry + inter[t] > cap[, t]) & dry > 0
      if (any(sc)) {
        s <- pmax(0, cap[sc, t] - inter[t]) / dry[sc]
        tp[sc] <- tp[sc] * s
        eu[sc] <- eu[sc] * s
      }
      ew <- ew + pmin(tf[t], w - ew)        # infiltration (une couche)
      eut <- pmin(eu, ew)
      ew <- ew - eut
      ok <- tp > 1e-12 & ew > 1e-12          # prelevement racinaire (une couche)
      if (any(ok)) ew[ok] <- ew[ok] - pmin(tp[ok], ew[ok])
      if (ip[t]) {
        SWD[ipi[t], ] <- pmax(0, rew_c * w - ew)
        NJ[ipi[t], ] <- (ew / w) < rew_c
      }
    }
    IS <- NJs <- matrix(NA_real_, length(ans), nc)
    for (a in seq_along(ans)) {
      r <- which(yr_ip == ans[a])
      IS[a, ] <- colSums(SWD[r, , drop = FALSE]) / w / rew_c
      NJs[a, ] <- colSums(NJ[r, , drop = FALSE])
    }
    out[cols, "is"] <- apply(IS, 2, mean)
    out[cols, "nj"] <- apply(NJs, 2, mean)
    out[cols, "n"] <- length(ans)
  }
  out
}

# Indices BILJOU moyens (sur les annees) pour une meteo et des reserves utiles.
.biljou_ru <- function(meteo, ru, param) {
  out <- matrix(NA_real_, length(ru), 3, dimnames = list(NULL, c("is", "nj", "n")))
  ok <- !is.na(ru) & ru > 0
  if (any(ok)) out[ok, ] <- .biljou_cols(meteo, NULL, NULL, ru[ok], param)
  out
}

.SENS_HYDRIQUE <- "plus haut = plus humide"

#' Gradient hydrique : indice de contrainte hydrique BILJOU sur climat SAFRAN
#'
#' Calcule, avec le modèle de bilan hydrique journalier BILJOU (paquet `biljouR`,
#' Granier et al. 1999), l'indice de contrainte hydrique `Istress` (définition de
#' l'outil en ligne de l'INRAE : somme sur les jours de stress de (0,4 - REW) / 0,4) et
#' le nombre de jours de stress `NJstress` (REW < 0,4), en moyenne annuelle, à partir de
#' la réserve utile et du climat journalier SAFRAN (SIM2, Météo-France, maille 8 km).
#' Le gradient hydrique devient cet indice ; la réserve utile en est une entrée
#' (ADR 0006).
#'
#' * **Placettes** (`x` = `sf` de points en EPSG:2154 avec la colonne `ru_col`) : chaque
#'   point prend la maille SAFRAN la plus proche (maille large, croisable avec l'IFN :
#'   [assert_no_fine_extract_on_ifn()] est appelée avec `coarse_safran`) ; un calcul
#'   BILJOU par couple (maille, réserve utile).
#' * **Grille** (`x` = `SpatRaster` de réserve utile en mm, EPSG:2154) : pour chaque
#'   maille SAFRAN, l'indice est calculé sur une suite de réserves utiles (pas `pas_ru`)
#'   puis interpolé linéairement pour chaque pixel (descente d'échelle par la réserve
#'   utile).
#' * **Sens** : `grad_hydrique` est orienté « plus haut = plus humide » dans les deux
#'   modes (attribut `sens`) : `-is_biljou` en mode nominal, la réserve utile en repli.
#' * **Repli** : sans `safran` ou sans le paquet `biljouR`, l'indice vaut `NA` et
#'   `grad_hydrique` reprend la réserve utile ; l'attribut `methode` vaut `"repli_ru"`
#'   et la raison est dans l'attribut `repli` (avertissement émis).
#' * Une réserve utile nulle ou absente donne un indice `NA` (BILJOU exige un réservoir
#'   positif).
#'
#' Paramètres de végétation **provisoires** (mission 019) : `lai_max = 6`, feuillus,
#' débourrement au jour 110 et chute des feuilles au jour 300 (valeurs de l'exemple de
#' `biljouR`) ; ils sont à mesurer par comparaison à l'humidité bioindiquée, et à geler
#' avant la phase 1.
#'
#' @param x `sf` de points (EPSG:2154) ou `SpatRaster` de réserve utile (EPSG:2154).
#' @param safran `data.frame` SIM2 quotidien (colonnes `LAMBX`, `LAMBY`, `DATE`
#'   AAAAMMJJ, `PRELIQ`, `PRENEI`, `ETP` en mm, noms des fichiers `QUOT_SIM2_AAAA.csv.gz`
#'   de meteo.data.gouv.fr ; suffixe `_Q` accepté) ou `NULL`.
#' @param ru_col Colonne de réserve utile (mm) de `x` (points).
#' @param annees Années à garder (`NULL` : toutes).
#' @param lai_max,forest_type,budburst,leaf_fall Paramètres de [biljouR::biljou_run()].
#' @param pas_ru Pas (mm) de la suite de réserves utiles pour une grille.
#' @return Points : `x` avec `maille_safran`, `is_biljou`, `nj_stress`, `n_annees`,
#'   `grad_hydrique` (= `-is_biljou`, ou la réserve utile en repli). Grille :
#'   `SpatRaster` à trois couches `is_biljou`, `nj_stress`, `grad_hydrique`. Attributs
#'   `methode` (`"biljou"` ou `"repli_ru"`), `sens`, `parametres`.
#' @examples
#' \donttest{
#' s <- utils::read.csv2(system.file("extdata", "safran_sim2_extrait.csv",
#'                                   package = "sylvostation"))
#' m <- s[1, c("LAMBX", "LAMBY")]
#' xy <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(x = m$LAMBX * 100,
#'   y = m$LAMBY * 100), coords = c("x", "y"), crs = 27572), 2154))
#' p <- sf::st_as_sf(data.frame(id = 1:2, ru_mm = c(60, 150), x = xy[1], y = xy[2]),
#'                   coords = c("x", "y"), crs = 2154)
#' hydric_stress(p, s)
#' }
#' @export
hydric_stress <- function(x, safran = NULL, ru_col = "ru_mm", annees = NULL,
                          lai_max = 6, forest_type = "broadleaved",
                          budburst = 110, leaf_fall = 300, pas_ru = 10) {
  param <- list(lai_max = lai_max, forest_type = forest_type, budburst = budburst,
                leaf_fall = leaf_fall, statut = "provisoire (mission 019)")
  grille <- inherits(x, "SpatRaster")
  if (!grille && !inherits(x, "sf")) {
    stop("`x` doit \u00eatre un sf de points ou un SpatRaster de r\u00e9serve utile.", call. = FALSE)
  }
  assert_crs_2154(x)
  if (!grille) {
    if (!ru_col %in% names(x)) stop("Colonne `", ru_col, "` absente de `x`.", call. = FALSE)
    assert_no_fine_extract_on_ifn(x, "coarse_safran")
  }

  raison <- NULL
  if (is.null(safran)) raison <- "climat SAFRAN absent"
  else if (!.has_pkg("biljouR")) raison <- "paquet biljouR absent"
  if (!is.null(raison)) {
    warning("Gradient hydrique en repli sur la r\u00e9serve utile : ", raison, ".", call. = FALSE)
    if (grille) {
      out <- c(x * NA, x * NA, x)
      names(out) <- c("is_biljou", "nj_stress", "grad_hydrique")
    } else {
      out <- x
      out$maille_safran <- NA_character_
      out$is_biljou <- NA_real_
      out$nj_stress <- NA_real_
      out$n_annees <- NA_real_
      out$grad_hydrique <- x[[ru_col]]
    }
    attr(out, "methode") <- "repli_ru"
    attr(out, "sens") <- .SENS_HYDRIQUE
    attr(out, "repli") <- raison
    attr(out, "parametres") <- param
    return(out)
  }

  requis <- c("LAMBX", "LAMBY", "DATE", "PRELIQ_Q", "PRENEI_Q", "ETP_Q")
  if (is.data.frame(safran)) {
    # fichiers QUOT_SIM2_AAAA.csv.gz de meteo.data.gouv.fr : PRELIQ, PRENEI, ETP (sans _Q)
    for (v in c("PRELIQ", "PRENEI", "ETP")) {
      if (!paste0(v, "_Q") %in% names(safran) && v %in% names(safran)) {
        names(safran)[names(safran) == v] <- paste0(v, "_Q")
      }
    }
  }
  if (!is.data.frame(safran) || !all(requis %in% names(safran))) {
    stop("`safran` doit avoir les colonnes : ", paste(requis, collapse = ", "), ".",
         call. = FALSE)
  }
  safran <- as.data.frame(safran)
  for (v in setdiff(requis, "DATE")) safran[[v]] <- suppressWarnings(as.numeric(safran[[v]]))
  if (!is.null(annees)) {
    safran <- safran[as.integer(substr(as.character(safran$DATE), 1, 4)) %in% annees, , drop = FALSE]
    if (!nrow(safran)) stop("Aucune journ\u00e9e SAFRAN pour les ann\u00e9es demand\u00e9es.", call. = FALSE)
  }
  mailles <- .mailles_safran(safran)
  cle <- paste(safran$LAMBX, safran$LAMBY, sep = "_")
  meteo_de <- function(m) {
    s <- safran[cle == m, , drop = FALSE]
    biljouR::safran_to_meteo(s, cols = list(date = "DATE", rain_liq = "PRELIQ_Q",
                                            rain_sol = "PRENEI_Q", pet = "ETP_Q"))
  }

  if (!grille) {
    xy <- sf::st_coordinates(x)  # x = est, y = nord
    ma <- .maille_proche(xy[, 1], xy[, 2], mailles)
    ru <- as.numeric(x[[ru_col]])
    res <- matrix(NA_real_, nrow(x), 3, dimnames = list(NULL, c("is", "nj", "n")))
    for (m in unique(stats::na.omit(ma))) {
      met <- meteo_de(m)
      i <- which(ma == m)
      u <- unique(ru[i])
      r <- .biljou_ru(met, u, param)
      res[i, ] <- r[match(ru[i], u), , drop = FALSE]
    }
    out <- x
    out$maille_safran <- ma
    out$is_biljou <- res[, "is"]
    out$nj_stress <- res[, "nj"]
    out$n_annees <- res[, "n"]
    out$grad_hydrique <- -out$is_biljou   # plus haut = plus humide
  } else {
    xy <- terra::xyFromCell(x, seq_len(terra::ncell(x)))
    v <- terra::values(x)[, 1]
    ma <- .maille_proche(xy[, 1], xy[, 2], mailles)
    is <- nj <- rep(NA_real_, length(v))
    for (m in unique(stats::na.omit(ma))) {
      i <- which(ma == m & !is.na(v) & v > 0)
      if (!length(i)) next
      seq_ru <- unique(c(seq(pas_ru, max(v[i]) + pas_ru, by = pas_ru)))
      r <- .biljou_ru(meteo_de(m), seq_ru, param)
      is[i] <- stats::approx(seq_ru, r[, "is"], xout = v[i], rule = 2)$y
      nj[i] <- stats::approx(seq_ru, r[, "nj"], xout = v[i], rule = 2)$y
    }
    out <- c(x, x, x)
    terra::values(out) <- cbind(is, nj, -is)
    names(out) <- c("is_biljou", "nj_stress", "grad_hydrique")
  }
  attr(out, "methode") <- "biljou"
  attr(out, "sens") <- .SENS_HYDRIQUE
  attr(out, "parametres") <- param
  out
}

# ---- Descente d'echelle hydrique (mission 021) ------------------------------------------

# SSI SAFRAN en MJ m-2 j-1. Unite verifiee le 2026-11-18 : J/cm2, cumul quotidien
# ]00UTC-00UTC], libelle « Rayonnement visible » (Meteo-France, « Donnees quotidiennes
# SIM », document du 2026-03-31, params.pdf du cache SAFRAN). 1 J/cm2 = 0,01 MJ/m2.
.ssi_mj <- function(ssi) ssi * 0.01

# Rayonnement extraterrestre journalier sur le plat (MJ m-2 j-1), FAO-56 (Allen et al.
# 1998, eq. 21), meme formule que biljouR::penman_pet().
.ra_mj <- function(doy, lat) {
  phi <- lat * pi / 180
  dr <- 1 + 0.033 * cos(2 * pi / 365 * doy)
  decl <- 0.409 * sin(2 * pi / 365 * doy - 1.39)
  ws <- acos(pmax(pmin(-tan(phi) * tan(decl), 1), -1))
  24 * 60 / pi * 0.082 * dr * (ws * sin(phi) * sin(decl) + cos(phi) * cos(decl) * sin(ws))
}

# Controle de plausibilite : un rayonnement au sol ne depasse pas le rayonnement
# extraterrestre du jour (avertissement sinon : unite ou donnee douteuse).
.check_ssi <- function(rg_mj, doy, lat) {
  trop <- which(rg_mj > .ra_mj(doy, lat))
  if (length(trop)) {
    warning(length(trop), " jour(s) SAFRAN avec SSI sup\u00e9rieur au rayonnement ",
            "extraterrestre : unit\u00e9 (J/cm2) ou donn\u00e9e \u00e0 v\u00e9rifier.", call. = FALSE)
  }
  invisible(length(trop))
}

# Noms SAFRAN sans suffixe `_Q` (fichiers de meteo.data.gouv.fr), colonnes numeriques.
.safran_norm <- function(safran) {
  s <- as.data.frame(safran)
  for (v in c("PRELIQ", "PRENEI", "ETP", "T", "FF", "HU", "SSI")) {
    q <- paste0(v, "_Q")
    if (!v %in% names(s) && q %in% names(s)) names(s)[names(s) == q] <- v
  }
  for (v in intersect(c("LAMBX", "LAMBY", "PRELIQ", "PRENEI", "ETP", "T", "FF", "HU", "SSI"),
                      names(s))) {
    s[[v]] <- suppressWarnings(as.numeric(s[[v]]))
  }
  s
}

# Maille SAFRAN la plus proche, vectorisee pour une grille (x = est, y = nord).
.maille_proche_vec <- function(x, y, mailles, dmax = 8000 * sqrt(2) / 2 + 1) {
  best <- rep(Inf, length(x))
  out <- rep(NA_character_, length(x))
  for (j in seq_len(nrow(mailles))) {
    d <- sqrt((mailles$x[j] - x)^2 + (mailles$y[j] - y)^2)
    p <- d < best
    best[p] <- d[p]
    out[p] <- mailles$maille[j]
  }
  out[best > dmax] <- NA_character_
  out
}

#' Réserve utile uniforme par maille SAFRAN (médiane des placettes IFN)
#'
#' Réserve utile **provisoire** de la carte hydrique (mission 021) : aucune
#' source ne donne la réserve utile à cette échelle (`docs/referentiels.md` § 25.3), et aucune
#' modulation topographique publiée n'a été trouvée (§ 25.2) ; la réserve utile est donc
#' **uniforme dans chaque maille SAFRAN de 8 km**, égale à la médiane des réserves utiles
#' (euptf2, [ru_from_texture()]) des placettes IFN de la maille. Une maille sans placette
#' prend la médiane des placettes des mailles de l'emprise, sinon celle de toutes les
#' placettes fournies (GRECO), et la colonne `origine` le dit. Jamais de modulation par la
#' topographie.
#'
#' Le rattachement d'une placette à sa maille de 8 km est une opération à maille large,
#' permise aux placettes IFN ([assert_no_fine_extract_on_ifn()] avec `coarse_safran`).
#'
#' @param points `sf` de points (EPSG:2154), par exemple les placettes IFN, avec la
#'   colonne `ru_col`.
#' @param safran `data.frame` SIM2 (colonnes `LAMBX`, `LAMBY`).
#' @param emprise Emprise de la carte (bbox, `sf` ou `c(xmin, ymin, xmax, ymax)`,
#'   EPSG:2154) : mailles dont le centre est à moins d'une demi-diagonale (5,7 km).
#'   `NULL` : toutes les mailles de `safran`.
#' @param ru_col Colonne de réserve utile (mm).
#' @return `data.frame` : `maille`, `ru_mm`, `n_placettes`, `origine`, `statut`.
#' @examples
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)
#' p <- mark_ifn(sf::st_as_sf(data.frame(ru_mm = c(80, 120), x = m$x[1:2], y = m$y[1:2]),
#'                            coords = c("x", "y"), crs = 2154))
#' ru_by_safran_cell(p, s)
#' @export
ru_by_safran_cell <- function(points, safran, emprise = NULL, ru_col = "ru_mm") {
  if (!inherits(points, "sf")) stop("`points` doit \u00eatre un sf de points.", call. = FALSE)
  assert_crs_2154(points)
  if (!ru_col %in% names(points)) stop("Colonne `", ru_col, "` absente de `points`.", call. = FALSE)
  assert_no_fine_extract_on_ifn(points, "coarse_safran")
  if (!is.data.frame(safran) || !all(c("LAMBX", "LAMBY") %in% names(safran))) {
    stop("`safran` doit avoir les colonnes LAMBX et LAMBY.", call. = FALSE)
  }
  mailles <- .mailles_safran(.safran_norm(safran))
  xy <- sf::st_coordinates(points)   # x = est, y = nord
  ma <- .maille_proche(xy[, 1], xy[, 2], mailles)
  ru <- suppressWarnings(as.numeric(points[[ru_col]]))
  ok <- is.finite(ru) & ru > 0
  if (!any(ok)) stop("Aucune placette avec une r\u00e9serve utile positive.", call. = FALSE)
  if (!is.null(emprise)) {
    b <- .as_bbox(emprise)
    m <- 8000 * sqrt(2) / 2
    mailles <- mailles[mailles$x >= b[["xmin"]] - m & mailles$x <= b[["xmax"]] + m &
                         mailles$y >= b[["ymin"]] - m & mailles$y <= b[["ymax"]] + m, , drop = FALSE]
  }
  if (!nrow(mailles)) stop("Aucune maille SAFRAN sur l'emprise.", call. = FALSE)
  emp <- ok & ma %in% mailles$maille
  med_emp <- if (any(emp)) stats::median(ru[emp]) else NA_real_
  med_tout <- stats::median(ru[ok])
  lignes <- lapply(mailles$maille, function(m) {
    i <- ok & ma %in% m
    if (any(i)) {
      data.frame(maille = m, ru_mm = stats::median(ru[i]), n_placettes = sum(i),
                 origine = "placettes de la maille", stringsAsFactors = FALSE)
    } else if (!is.na(med_emp)) {
      data.frame(maille = m, ru_mm = med_emp, n_placettes = 0L,
                 origine = "m\u00e9diane des mailles de l'emprise", stringsAsFactors = FALSE)
    } else {
      data.frame(maille = m, ru_mm = med_tout, n_placettes = 0L,
                 origine = "m\u00e9diane de toutes les placettes (GRECO)", stringsAsFactors = FALSE)
    }
  })
  out <- do.call(rbind, lignes)
  out$statut <- "provisoire (mission 021) : RU uniforme par maille SAFRAN"
  out
}

# Meteo BILJOU d'une maille avec l'ETP de Penman (biljouR) sur un rayonnement
# rg = SSI x 0,01 x k(mois) ; kprof : 12 facteurs mensuels.
.meteo_topo <- function(sm, kprof, lat, alt) {
  mois <- as.integer(substr(as.character(sm$DATE), 5, 6))
  d <- data.frame(DATE = sm$DATE, PRELIQ = sm$PRELIQ, PRENEI = sm$PRENEI, T = sm$T,
                  FF = sm$FF, HU = sm$HU, RG = .ssi_mj(sm$SSI) * kprof[mois])
  biljouR::safran_to_meteo(d, cols = list(date = "DATE", rain_liq = "PRELIQ",
                                          rain_sol = "PRENEI", tmean = "T", rg = "RG",
                                          wind = "FF", rh = "HU"),
                           compute_pet = TRUE, latitude = lat, altitude = alt)
}

# Interpolation lineaire a une dimension, constante hors des noeuds.
.interp1 <- function(x, y, xout) {
  ok <- is.finite(x) & is.finite(y)
  if (!any(ok)) return(rep(NA_real_, length(xout)))
  if (sum(ok) == 1L || length(unique(x[ok])) == 1L) return(rep(mean(y[ok]), length(xout)))
  stats::approx(x[ok], y[ok], xout = xout, rule = 2, ties = mean)$y
}

# Table (RU x k) : lineaire en k pour chaque RU, puis lineaire en RU.
.interp_table <- function(knodes, U, tab, kc, uc) {
  V <- matrix(NA_real_, length(kc), length(U))
  for (j in seq_along(U)) V[, j] <- .interp1(knodes, tab[j, ], kc)
  if (length(U) == 1L) return(V[, 1])
  j <- findInterval(uc, U, all.inside = TRUE)
  t <- pmin(pmax((uc - U[j]) / (U[j + 1] - U[j]), 0), 1)
  n <- seq_along(kc)
  V[cbind(n, j)] * (1 - t) + V[cbind(n, j + 1)] * t
}

#' Carte de l'indice de contrainte hydrique à la maille de sortie : BILJOU modulé par le rayonnement
#'
#' Descente d'échelle de l'indice `Istress` de BILJOU (ADR 0006) par la méthode A de
#' `docs/referentiels.md` § 25.4 (adaptation **non validée** de Dyer 2009) : l'ETP est
#' modulée par le rayonnement reçu par la pente ; ni la réserve utile, ni TWI, ni MRVBF,
#' ni HAND n'entrent dans BILJOU (ils restent des prédicteurs à part).
#'
#' Pour chaque cellule `x` de la grille, dans sa maille SAFRAN (8 km) :
#' 1. rayonnement du jour `d` : rg(x, d) = SSI(maille, d) × 0,01 × k(x, mois de d)
#'    (SSI en J/cm², unité vérifiée dans le document « Données quotidiennes SIM » de
#'    Météo-France du 2026-03-31 ; k de [solar_factor()]). Ce document nomme `SSI`
#'    « Rayonnement visible » : il est lu ici comme le rayonnement global de courte
#'    longueur d'onde, **à vérifier** ; la hauteur du vent `FF` (10 m supposés par
#'    `biljouR`) est aussi **à vérifier** ;
#' 2. ETP de Penman de `biljouR` ([biljouR::safran_to_meteo()] avec `compute_pet = TRUE` :
#'    `penman_pet(T, rg, wind_to_2m(FF, 10), HU, doy, latitude, altitude)`) ; latitude du
#'    centre de la maille, altitude = moyenne de `altitude` dans la maille (**provisoire**) ;
#' 3. `Istress(x)` = BILJOU(ETP(x), P(maille), RU(maille)) ;
#' 4. **plat de référence** (`is_plat`) par la même formule avec k = 1 : l'écart
#'    `is_topo - is_plat` est purement topographique (l'ETP SAFRAN, Penman-Monteith,
#'    n'est pas la référence).
#'
#' **Table par maille.** BILJOU ne tourne pas cellule par cellule (environ 2 s par
#' passe sur 30 ans). Chaque cellule reçoit un facteur scalaire `k_sv`, moyenne de ses 12
#' facteurs mensuels pondérée par le rayonnement SAFRAN moyen des jours de la saison de
#' BILJOU (`budburst` à `leaf_fall`) ; les cellules sont classées par pas de `pas_k`, et
#' BILJOU tourne une fois par classe avec le profil mensuel moyen de la classe, et par
#' réserve utile (une seule valeur si la RU est uniforme par maille, sinon une suite de
#' pas `pas_ru`). Chaque cellule est interpolée linéairement en `k_sv` puis en RU.
#' **Écart mesuré** : sur `n_controle` cellules tirées dans chaque maille, BILJOU tourne
#' avec le vrai profil de 12 facteurs ; l'écart à la table est rendu (attribut `ecart`),
#' sans seuil bloquant.
#'
#' **Points** (`points`, `sf` en EPSG:2154) : calcul direct, sans table, pour des points
#' précis (relevés GNSS, points au sol). [assert_no_fine_extract_on_ifn()] est appelée
#' d'abord : **k n'est jamais appliqué aux placettes IFN** (localisées à 700 m), dont
#' l'indice reste celui de [hydric_stress()], sans k.
#'
#' **Replis** (attribut `methode`, avertissement) : `"biljou_topo"` (k de `r.sun`) ;
#' `"biljou_climatique"` (k = 1, GRASS absent) ; `"climatique_etp_safran"` (colonnes
#' `T`, `FF`, `HU` ou `SSI` absentes : BILJOU sur l'ETP SAFRAN, sans k) ; `"repli_ru"`
#' (SAFRAN ou `biljouR` absent : la réserve utile).
#'
#' Valeurs **provisoires** (§ 25.5) : ciel clair pour k, passage de Turc au Penman de
#' `biljouR`, Linke 3,0, albédo 0,2, jours de Klein, RU uniforme par maille, pas des
#' suites, altitude moyenne de la maille ; paramètres de végétation de [hydric_stress()].
#'
#' @param k `SpatRaster` à 12 couches (EPSG:2154), de [solar_factor()].
#' @param ru Réserve utile : `data.frame` (`maille`, `ru_mm`) de [ru_by_safran_cell()],
#'   ou `SpatRaster` (mm) sur la grille de `k`.
#' @param safran `data.frame` SIM2 quotidien avec `LAMBX`, `LAMBY`, `DATE`, `PRELIQ`,
#'   `PRENEI`, `T`, `FF`, `HU`, `SSI` (suffixe `_Q` accepté), ou `NULL`.
#' @param points `NULL` (grille) ou `sf` de points précis (EPSG:2154).
#' @param altitude `SpatRaster` d'altitude (m) sur la grille, ou `NULL` (0 m).
#' @param annees Années à garder (`NULL` : toutes).
#' @param lai_max,forest_type,budburst,leaf_fall Paramètres de [biljouR::biljou_run()].
#' @param pas_k Pas des classes de `k_sv` (provisoire).
#' @param pas_ru Pas de la suite de RU si `ru` est un raster.
#' @param n_controle Cellules de contrôle par maille (calcul direct).
#' @param seed Graine du tirage des cellules de contrôle.
#' @param k_methode Méthode de `k` (`attr(k, "methode")` par défaut).
#' @param ncores Nombre de coeurs (une maille SAFRAN par processus, `parallel::mclapply()`,
#'   Unix seulement) ; 1 par défaut. Le résultat ne dépend pas de ce nombre.
#' @return Grille : `SpatRaster` `is_topo`, `nj_topo`, `is_plat`, `k_sv`, `ru_maille`,
#'   `grad_hydrique_carte` (= `-is_topo`, plus haut = plus humide). Points : `points` avec ces
#'   colonnes et `maille_safran`. Attributs `methode`, `k_methode`, `ecart`, `mailles`,
#'   `parametres`, `sens`, `repli`.
#' @examples
#' \donttest{
#' s <- read_safran(system.file("extdata", "safran_sim2_12mailles_extrait.csv",
#'                               package = "sylvostation"))
#' m <- sylvostation:::.mailles_safran(s)[1, ]
#' k <- terra::rast(xmin = m$x - 50, xmax = m$x + 50, ymin = m$y - 50, ymax = m$y + 50,
#'                  resolution = 50, crs = "EPSG:2154", nlyrs = 12)
#' terra::values(k) <- matrix(c(1.3, 1, 1, 0.7), 4, 12)
#' names(k) <- sprintf("k_%02d", 1:12)
#' h <- hydric_stress_grid(k, data.frame(maille = m$maille, ru_mm = 100), s, n_controle = 2)
#' terra::values(h)
#' }
#' @export
hydric_stress_grid <- function(k, ru, safran = NULL, points = NULL, altitude = NULL,
                               annees = NULL, lai_max = 6, forest_type = "broadleaved",
                               budburst = 110, leaf_fall = 300, pas_k = 0.02, pas_ru = 10,
                               n_controle = 30, seed = 1, k_methode = attr(k, "methode"),
                               ncores = 1L) {
  if (!inherits(k, "SpatRaster") || terra::nlyr(k) != 12L) {
    stop("`k` doit \u00eatre un SpatRaster \u00e0 12 couches (solar_factor()).", call. = FALSE)
  }
  assert_crs_2154(k)
  if (is.null(k_methode)) k_methode <- "inconnue"
  pts <- !is.null(points)
  if (pts) {
    if (!inherits(points, "sf")) stop("`points` doit \u00eatre un sf de points.", call. = FALSE)
    assert_crs_2154(points)
    # regle bloquante : k est une variable fine, jamais aux placettes IFN
    assert_no_fine_extract_on_ifn(points, names(k))
  }
  if (is.data.frame(ru)) {
    if (!all(c("maille", "ru_mm") %in% names(ru))) {
      stop("`ru` doit avoir les colonnes maille et ru_mm (ru_by_safran_cell()).", call. = FALSE)
    }
  } else if (inherits(ru, "SpatRaster")) {
    assert_crs_2154(ru)
    if (!terra::compareGeom(ru, k, stopOnError = FALSE)) {
      stop("`ru` (raster) doit \u00eatre sur la grille de `k`.", call. = FALSE)
    }
  } else {
    stop("`ru` doit \u00eatre un data.frame (maille, ru_mm) ou un SpatRaster.", call. = FALSE)
  }
  if (!is.null(altitude)) assert_crs_2154(altitude)
  if (!is.numeric(pas_k) || length(pas_k) != 1L || !(pas_k > 0)) {
    stop("`pas_k` doit \u00eatre un nombre positif.", call. = FALSE)
  }
  param <- list(lai_max = lai_max, forest_type = forest_type, budburst = budburst,
                leaf_fall = leaf_fall, pas_k = pas_k, pas_ru = pas_ru, n_controle = n_controle,
                rg = "SSI x 0,01 x k (SSI en J/cm2, v\u00e9rifi\u00e9 2026-11-18)",
                etp = "Penman biljouR (penman_pet, vent ramen\u00e9 \u00e0 2 m depuis 10 m)",
                statut = "provisoire (r\u00e9f\u00e9rentiels \u00a7 25.5, mission 021)")

  # cellules ou points : coordonnees (x = est, y = nord), facteurs, RU
  if (pts) {
    xy <- sf::st_coordinates(points)
    K <- as.matrix(terra::extract(k, xy[, 1:2, drop = FALSE])[, names(k), drop = FALSE])
  } else {
    xy <- terra::xyFromCell(k, seq_len(terra::ncell(k)))
    K <- terra::values(k, mat = TRUE)
  }
  colnames(K) <- NULL
  valid <- stats::complete.cases(K)

  noms <- c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille", "grad_hydrique_carte")
  rendre <- function(res, methode, ecart = NULL, mailles = NULL, repli = NULL) {
    if (pts) {
      out <- points
      for (v in noms) out[[v]] <- res[, v]
      out$maille_safran <- ma
    } else {
      out <- terra::rast(k, nlyrs = length(noms))
      terra::values(out) <- res[, noms]
      names(out) <- noms
    }
    attr(out, "methode") <- methode
    attr(out, "k_methode") <- k_methode
    attr(out, "ecart") <- ecart
    attr(out, "mailles") <- mailles
    attr(out, "parametres") <- param
    attr(out, "sens") <- .SENS_HYDRIQUE
    attr(out, "repli") <- repli
    out
  }
  res <- matrix(NA_real_, nrow(K), length(noms), dimnames = list(NULL, noms))

  raison <- NULL
  if (is.null(safran)) raison <- "climat SAFRAN absent"
  else if (!.has_pkg("biljouR")) raison <- "paquet biljouR absent"
  s <- if (is.null(safran)) NULL else .safran_norm(safran)
  mailles <- if (is.null(s)) NULL else .mailles_safran(s)
  ma <- if (is.null(mailles)) rep(NA_character_, nrow(K)) else
    .maille_proche_vec(xy[, 1], xy[, 2], mailles)
  ru_c <- if (is.data.frame(ru)) ru$ru_mm[match(ma, ru$maille)] else {
    if (pts) terra::extract(ru, xy[, 1:2, drop = FALSE])[, 1] else terra::values(ru, mat = FALSE)
  }
  if (is.data.frame(ru) && is.null(mailles)) ru_c <- rep(NA_real_, nrow(K))
  res[, "ru_maille"] <- ru_c
  if (!is.null(raison)) {
    warning("Carte hydrique en repli sur la r\u00e9serve utile : ", raison, ".", call. = FALSE)
    res[, "grad_hydrique_carte"] <- ru_c
    return(rendre(res, "repli_ru", repli = raison))
  }

  requis <- c("LAMBX", "LAMBY", "DATE", "PRELIQ", "PRENEI")
  if (!all(requis %in% names(s))) {
    stop("`safran` doit avoir les colonnes : ", paste(requis, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.null(annees)) {
    s <- s[as.integer(substr(as.character(s$DATE), 1, 4)) %in% annees, , drop = FALSE]
    if (!nrow(s)) stop("Aucune journ\u00e9e SAFRAN pour les ann\u00e9es demand\u00e9es.", call. = FALSE)
  }
  cle <- paste(s$LAMBX, s$LAMBY, sep = "_")
  bio <- list(lai_max = lai_max, forest_type = forest_type, budburst = budburst,
              leaf_fall = leaf_fall)

  # repli : sans T, FF, HU ou SSI, pas de Penman ; BILJOU sur l'ETP SAFRAN, sans k
  clim <- c("T", "FF", "HU", "SSI")
  absent <- clim[vapply(clim, function(v) !v %in% names(s) || all(is.na(s[[v]])), logical(1))]
  if (length(absent)) {
    if (!"ETP" %in% names(s)) {
      stop("`safran` n'a ni T, FF, HU, SSI ni ETP.", call. = FALSE)
    }
    msg <- paste0("colonnes SAFRAN absentes ou vides (", paste(absent, collapse = ", "),
                  ") : BILJOU sur l'ETP SAFRAN, sans k")
    warning("Carte hydrique sans modulation topographique : ", msg, ".", call. = FALSE)
    for (m in unique(stats::na.omit(ma))) {
      i <- which(ma == m & valid & is.finite(ru_c) & ru_c > 0)
      if (!length(i)) next
      sm <- s[cle == m, , drop = FALSE]
      met <- biljouR::safran_to_meteo(sm, cols = list(date = "DATE", rain_liq = "PRELIQ",
                                                     rain_sol = "PRENEI", pet = "ETP"))
      U <- sort(unique(ru_c[i]))
      r <- .biljou_ru(met, U, bio)
      res[i, "is_topo"] <- .interp1(U, r[, "is"], ru_c[i])
      res[i, "nj_topo"] <- .interp1(U, r[, "nj"], ru_c[i])
    }
    res[, "is_plat"] <- res[, "is_topo"]
    res[, "grad_hydrique_carte"] <- -res[, "is_topo"]
    return(rendre(res, "climatique_etp_safran", repli = msg))
  }

  # altitude de chaque maille : moyenne des cellules du raster `altitude` dans la maille
  alt_m <- stats::setNames(rep(0, nrow(mailles)), mailles$maille)
  if (!is.null(altitude)) {
    axy <- terra::xyFromCell(altitude, seq_len(terra::ncell(altitude)))
    av <- terra::values(altitude, mat = FALSE)
    am <- .maille_proche_vec(axy[, 1], axy[, 2], mailles)
    moy <- tapply(av, am, mean, na.rm = TRUE)
    moy <- moy[is.finite(moy)]
    alt_m[names(moy)] <- moy
  }
  lat_m <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(mailles, coords = c("x", "y"),
                                                            crs = 2154), 4326))[, 2]
  ecarts <- list()
  infos <- list()
  if (exists(".Random.seed", envir = globalenv())) {
    old <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)
  mm <- Filter(function(m) length(which(ma == m & valid & is.finite(ru_c) & ru_c > 0)) > 0,
               unique(stats::na.omit(ma)))
  # pre-passe sequentielle : controle de plausibilite du SSI (avertissements dans l'ordre)
  # et tirage des cellules de controle (meme suite de nombres aleatoires qu'en une seule
  # boucle, quel que soit le nombre de coeurs)
  ctls <- list()
  for (m in mm) {
    i <- which(ma == m & valid & is.finite(ru_c) & ru_c > 0)
    sm <- s[cle == m, , drop = FALSE]
    sm <- sm[order(sm$DATE), , drop = FALSE]
    doy <- as.integer(format(as.Date(as.character(sm$DATE), "%Y%m%d"), "%j"))
    .check_ssi(.ssi_mj(sm$SSI), doy, lat_m[mailles$maille == m])
    if (!pts) {
      ctls[[m]] <- if (n_controle > 0) i[sample.int(length(i), min(n_controle, length(i)))] else
        integer(0)
    }
  }

  # une maille : toutes les passes BILJOU (plat, classes de k, cellules de controle ou points)
  # avancent ensemble dans `.biljou_cols()` (mission 028)
  calcul_maille <- function(m) {
    i <- which(ma == m & valid & is.finite(ru_c) & ru_c > 0)
    sm <- s[cle == m, , drop = FALSE]
    sm <- sm[order(sm$DATE), , drop = FALSE]
    lat <- lat_m[mailles$maille == m]
    alt <- unname(alt_m[m])
    doy <- as.integer(format(as.Date(as.character(sm$DATE), "%Y%m%d"), "%j"))
    # poids mensuels : rayonnement SAFRAN des jours de la saison BILJOU
    mois <- as.integer(substr(as.character(sm$DATE), 5, 6))
    sv <- doy >= budburst & doy <= leaf_fall
    w <- vapply(1:12, function(j) sum(sm$SSI[sv & mois == j], na.rm = TRUE), numeric(1))
    if (sum(w) <= 0) w <- rep(1, 12)
    w <- w / sum(w)
    kc <- as.numeric(K[i, , drop = FALSE] %*% w)
    U <- sort(unique(ru_c[i]))
    if (!is.data.frame(ru) && length(U) > 1L) {
      U <- seq(pas_ru * floor(min(U) / pas_ru), pas_ru * ceiling(max(U) / pas_ru), by = pas_ru)
      U <- U[U > 0]
    }
    o <- list(i = i, k_sv = kc)
    # profils mensuels de k a passer dans Penman : plat, puis classes, puis controles/points
    if (pts) {
      ctl <- i
    } else {
      cl <- floor(kc / pas_k)
      grp <- sort(unique(cl))
      prof <- t(vapply(grp, function(g) colMeans(K[i[cl == g], , drop = FALSE]), numeric(12)))
      knodes <- as.numeric(prof %*% w)
      ctl <- ctls[[m]]
    }
    profs <- c(list(rep(1, 12)),
               if (!pts) lapply(seq_along(grp), function(g) prof[g, ]),
               lapply(ctl, function(c) K[c, ]))
    # meteo (dates, pluie) lue une fois via le plat ; les autres profils ne changent que
    # le rayonnement, donc l'ETP : Penman direct, sans relire les dates (mission 028)
    met0 <- .meteo_topo(sm, profs[[1]], lat, alt)
    vent2 <- biljouR::wind_to_2m(sm$FF, 10)
    PET <- do.call(cbind, c(list(met0$pet), lapply(profs[-1], function(p) {
      as.numeric(biljouR::penman_pet(tmean = sm$T, rg = .ssi_mj(sm$SSI) * p[mois], wind = vent2,
                                     rh = sm$HU, doy = doy, latitude = lat, altitude = alt))
    })))
    ng <- if (pts) 0L else length(grp)
    # colonnes : plat x U ; classes x U ; un calcul direct par controle (RU de la cellule)
    pidx <- c(rep(1L, length(U)), rep(seq_len(ng) + 1L, each = length(U)),
            seq_along(ctl) + 1L + ng)
    ew <- c(U, rep(U, ng), ru_c[ctl])
    r <- .biljou_cols(met0, PET, pidx, ew, bio)
    plat <- r[seq_along(U), , drop = FALSE]
    o$is_plat <- .interp1(U, plat[, "is"], ru_c[i])
    dir <- r[length(U) * (1L + ng) + seq_along(ctl), , drop = FALSE]
    if (pts) {
      o$is_topo <- dir[, "is"]
      o$nj_topo <- dir[, "nj"]
      o$info <- data.frame(maille = m, latitude = lat, altitude = alt, n_cellules = length(i),
                           n_noeuds_k = NA_integer_, n_noeuds_ru = length(U))
      return(o)
    }
    tab_is <- tab_nj <- matrix(NA_real_, length(U), ng)
    for (g in seq_len(ng)) {
      rg <- r[length(U) * g + seq_along(U), , drop = FALSE]
      tab_is[, g] <- rg[, "is"]
      tab_nj[, g] <- rg[, "nj"]
    }
    # noeud du plat (k = 1) : deja calcule
    knodes <- c(knodes, 1)
    tab_is <- cbind(tab_is, plat[, "is"])
    tab_nj <- cbind(tab_nj, plat[, "nj"])
    o$is_topo <- .interp_table(knodes, U, tab_is, kc, ru_c[i])
    o$nj_topo <- .interp_table(knodes, U, tab_nj, kc, ru_c[i])
    # ecart a un calcul direct sur un echantillon de cellules
    if (length(ctl)) {
      direct <- dir[, "is"]
      e <- o$is_topo[match(ctl, i)] - direct
      o$ecart <- data.frame(maille = m, n_controle = length(ctl),
                            is_direct_moyen = mean(direct),
                            ecart_moyen_abs = mean(abs(e)), ecart_max_abs = max(abs(e)),
                            ecart_relatif = if (mean(abs(direct)) > 0)
                              mean(abs(e)) / mean(abs(direct)) else NA_real_)
    }
    o$info <- data.frame(maille = m, latitude = lat, altitude = alt, n_cellules = length(i),
                         n_noeuds_k = length(knodes), n_noeuds_ru = length(U))
    o
  }
  ncores <- max(1L, as.integer(ncores))
  sorties <- if (ncores > 1L && length(mm) > 1L && .Platform$OS.type == "unix") {
    parallel::mclapply(mm, calcul_maille, mc.cores = min(ncores, length(mm)), mc.preschedule = FALSE)
  } else lapply(mm, calcul_maille)
  names(sorties) <- mm
  for (m in mm) {
    o <- sorties[[m]]
    if (inherits(o, "try-error") || is.null(o)) {
      stop("Carte hydrique : échec du calcul de la maille ", m, ".", call. = FALSE)
    }
    res[o$i, "k_sv"] <- o$k_sv
    res[o$i, "is_plat"] <- o$is_plat
    res[o$i, "is_topo"] <- o$is_topo
    res[o$i, "nj_topo"] <- o$nj_topo
    if (!is.null(o$ecart)) ecarts[[m]] <- o$ecart
    infos[[m]] <- o$info
  }
  res[, "grad_hydrique_carte"] <- -res[, "is_topo"]
  methode <- if (identical(k_methode, "climatique")) "biljou_climatique" else "biljou_topo"
  ecart <- if (length(ecarts)) do.call(rbind, ecarts) else
    data.frame(maille = character(), n_controle = integer(), is_direct_moyen = numeric(),
               ecart_moyen_abs = numeric(), ecart_max_abs = numeric(), ecart_relatif = numeric())
  rownames(ecart) <- NULL
  inf <- if (length(infos)) do.call(rbind, infos) else NULL
  if (!is.null(inf)) rownames(inf) <- NULL
  rendre(res, methode, ecart = ecart, mailles = inf,
         repli = if (methode == "biljou_climatique") "k = 1 (GRASS absent)" else NULL)
}

#' Écrire les couches de la carte hydrique
#'
#' Écrit `hydrique.tif` dans `out_dir/<ser_code>/` (couches `is_topo`, `nj_topo`,
#' `is_plat`, `k_sv`, `ru_maille` de [hydric_stress_grid()]), en **COG** si le pilote
#' GDAL `COG` est disponible, sinon en GeoTIFF tuilé compressé, comme [write_outputs()].
#' Si `synthetic = TRUE`, le fichier est préfixé `synth_` (CLAUDE.md). Les cellules hors
#' de `forest` (couche `foret` de [forest_mask()]) sont mises à `NA`.
#'
#' @param r `SpatRaster` de [hydric_stress_grid()] (EPSG:2154).
#' @param out_dir Dossier racine des sorties.
#' @param ser_code Code SER (sous-dossier).
#' @param forest `NULL` ou `SpatRaster` du masque forestier (couche `foret`).
#' @param synthetic `TRUE` pour préfixer le fichier par `synth_`.
#' @param cog Demander un COG.
#' @return Un `data.frame` (`fichier`, `format`), de façon invisible.
#' @examples
#' r <- terra::rast(xmin = 1015500, xmax = 1015550, ymin = 6793500, ymax = 6793550,
#'                  resolution = 20, crs = "EPSG:2154", nlyrs = 5)
#' terra::values(r) <- matrix(1, 4, 5)
#' names(r) <- c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille")
#' w <- write_hydric_grid(r, tempdir(), "D11", synthetic = TRUE)
#' basename(w$fichier)
#' @export
write_hydric_grid <- function(r, out_dir, ser_code, forest = NULL, synthetic = FALSE,
                              cog = TRUE) {
  couches <- c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille")
  if (!inherits(r, "SpatRaster") || !all(couches %in% names(r))) {
    stop("`r` doit \u00eatre un SpatRaster de hydric_stress_grid() (couches ",
         paste(couches, collapse = ", "), ").", call. = FALSE)
  }
  assert_crs_2154(r)
  if (!is.character(out_dir) || length(out_dir) != 1L || !nzchar(out_dir)) {
    stop("`out_dir` doit \u00eatre un chemin.", call. = FALSE)
  }
  if (!is.character(ser_code) || length(ser_code) != 1L || !nzchar(ser_code)) {
    stop("`ser_code` doit \u00eatre un code SER.", call. = FALSE)
  }
  h <- r[[couches]]
  if (!is.null(forest)) {
    assert_crs_2154(forest)
    h <- terra::mask(h, forest[["foret"]])
  }
  dir <- file.path(out_dir, ser_code)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  f <- file.path(dir, paste0(if (isTRUE(synthetic)) "synth_" else "", "hydrique.tif"))
  fmt <- .write_raster_cog(h, f, cog)
  invisible(data.frame(fichier = f, format = fmt, stringsAsFactors = FALSE))
}
