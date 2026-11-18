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
  vapply(seq_along(x), function(i) {
    d <- sqrt((mailles$x - x[i])^2 + (mailles$y - y[i])^2)
    j <- which.min(d)
    if (!length(j) || d[j] > dmax) NA_character_ else mailles$maille[j]
  }, character(1))
}

# Indices BILJOU moyens (sur les annees) pour une meteo et des reserves utiles.
.biljou_ru <- function(meteo, ru, param) {
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
