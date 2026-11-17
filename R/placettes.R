# Placettes de l'Inventaire forestier national (IFN) : lecture, filtrage, gradients.
# Colonnes et codes : docs/referentiels.md § 7 et metadonnees.csv de l'archive DataIFN
# (export_dataifn_2005_2025). Rappel : XL, YL sont le centre de la maille kilometrique
# (700 m au plus de la placette) ; aucune variable fine ne leur est croisee.

# Lit un CSV IFN : separateur ";", UTF-8 avec ou sans BOM, "" -> NA, tout en
# caracteres (les codes d'une meme colonne changent de nomenclature selon la campagne :
# on ne convertit que les cles). Le ";" final de ARBRE cree une colonne sans nom, retiree.
.lire_csv_ifn <- function(path) {
  d <- utils::read.delim(path, sep = ";", quote = "\"", colClasses = "character",
                         na.strings = "", fileEncoding = "UTF-8-BOM",
                         check.names = FALSE, comment.char = "", strip.white = TRUE)
  d[, nzchar(names(d)), drop = FALSE]
}

# Cherche NAME.csv (archive DataIFN) ou ifn_name.csv (extraits du depot), sans casse.
.trouver_fichier_ifn <- function(dir, name) {
  cand <- c(paste0(name, ".csv"), paste0("ifn_", tolower(name), ".csv"))
  tous <- list.files(dir)
  i <- match(tolower(cand), tolower(tous))
  i <- i[!is.na(i)]
  if (!length(i)) return(NA_character_)
  file.path(dir, tous[i[1]])
}

.num <- function(x) suppressWarnings(as.numeric(x))

.date_ifn <- function(x) {
  d <- as.Date(x, format = "%Y-%m-%d")
  autre <- is.na(d) & !is.na(x)
  d[autre] <- as.Date(x[autre], format = "%d/%m/%Y")
  d
}

#' Lire les placettes IFN
#'
#' Lit les fichiers bruts DataIFN (séparateur `;`, UTF-8 avec ou sans BOM) d'un
#' dossier : `PLACETTE.csv`, `ECOLOGIE.csv`, `FLORE.csv`, `ARBRE.csv`, ou les extraits
#' du dépôt `ifn_placette.csv`, etc. (`docs/referentiels.md`, § 7). `PLACETTE` et
#' `ECOLOGIE` sont joints par (`CAMPAGNE`, `IDP`) ; le résultat est un objet `sf` en
#' Lambert-93 (EPSG:2154, `XL` = est, `YL` = nord). Les tables sont marquées par
#' [mark_ifn()] : `source = "ifn"` et `loc_precision_m` (700 m), donc **toute
#' extraction de variable fine y est interdite** ([assert_no_fine_extract_on_ifn()]).
#'
#' Seules les clés sont converties (`CAMPAGNE`, `IDP`, `XL`, `YL`, `VISITE`, `CD_REF`,
#' `ABOND`, dates `DATEPOINT` et `DATEECO`) ; les autres colonnes restent en
#' caractères, car les codes d'une même colonne changent de nomenclature selon la
#' campagne (`metadonnees.csv`). La flore n'est relevée qu'en première visite.
#'
#' @param dir Dossier contenant les fichiers.
#' @param files Fichiers à lire. `PLACETTE` est obligatoire ; `ECOLOGIE` est
#'   nécessaire à [compute_gradients()].
#' @param precision_m Précision de localisation en mètres, à passer depuis
#'   `read_config()$ifn_precision_m` (700 par défaut).
#' @return Une liste de classe `sylvo_ifn` : `placettes` (`sf`, une ligne par
#'   placette et campagne, avec `id_placette` = `CAMPAGNE_IDP` et les colonnes
#'   d'`ECOLOGIE`), `flore` et `arbre` (`data.frame`, `NULL` si non lus), tous marqués
#'   IFN.
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' nrow(ifn$placettes)
#' @export
load_ifn <- function(dir, files = c("PLACETTE", "ECOLOGIE", "FLORE", "ARBRE"),
                     precision_m = 700) {
  if (!is.character(dir) || length(dir) != 1L || !dir.exists(dir)) {
    stop("Dossier IFN introuvable : ", paste(dir, collapse = ", "), call. = FALSE)
  }
  files <- toupper(files)
  inconnus <- setdiff(files, c("PLACETTE", "ECOLOGIE", "FLORE", "ARBRE"))
  if (length(inconnus)) {
    stop("Fichiers IFN non pr\u00e9vus : ", paste(inconnus, collapse = ", "), call. = FALSE)
  }
  if (!"PLACETTE" %in% files) stop("`files` doit contenir \"PLACETTE\".", call. = FALSE)
  chemins <- vapply(files, function(f) .trouver_fichier_ifn(dir, f), character(1))
  if (anyNA(chemins)) {
    stop("Fichier(s) IFN introuvable(s) dans ", dir, " : ",
         paste(files[is.na(chemins)], collapse = ", "), call. = FALSE)
  }
  lire <- function(f) if (f %in% files) .lire_csv_ifn(chemins[[f]]) else NULL

  pl <- lire("PLACETTE")
  cles <- c("CAMPAGNE", "IDP", "XL", "YL")
  if (!all(cles %in% names(pl))) {
    stop("PLACETTE : colonnes manquantes : ", paste(setdiff(cles, names(pl)), collapse = ", "),
         call. = FALSE)
  }
  for (v in intersect(c(cles, "VISITE"), names(pl))) pl[[v]] <- .num(pl[[v]])
  if (anyNA(pl[cles])) {
    stop("PLACETTE : CAMPAGNE, IDP, XL ou YL manquant ou non num\u00e9rique.", call. = FALSE)
  }
  if ("DATEPOINT" %in% names(pl)) pl$DATEPOINT <- .date_ifn(pl$DATEPOINT)
  pl$id_placette <- paste(pl$CAMPAGNE, pl$IDP, sep = "_")

  eco <- lire("ECOLOGIE")
  if (!is.null(eco)) {
    for (v in c("CAMPAGNE", "IDP")) eco[[v]] <- .num(eco[[v]])
    if ("DATEECO" %in% names(eco)) eco$DATEECO <- .date_ifn(eco$DATEECO)
    eco$id_placette <- paste(eco$CAMPAGNE, eco$IDP, sep = "_")
    if (anyDuplicated(eco$id_placette)) {
      stop("ECOLOGIE : plusieurs lignes pour un m\u00eame (CAMPAGNE, IDP).", call. = FALSE)
    }
    ajout <- setdiff(names(eco), c(names(pl), "CAMPAGNE", "IDP"))
    pl <- cbind(pl, eco[match(pl$id_placette, eco$id_placette), ajout, drop = FALSE])
  }
  if (anyDuplicated(pl$id_placette)) {
    stop("PLACETTE : plusieurs lignes pour un m\u00eame (CAMPAGNE, IDP).", call. = FALSE)
  }

  # x = est (XL), y = nord (YL), Lambert-93
  sf_pl <- sf::st_as_sf(pl, coords = c("XL", "YL"), crs = 2154, remove = FALSE)
  assert_crs_2154(sf_pl)
  sf_pl <- mark_ifn(sf_pl, precision_m)

  tab <- function(f, num) {
    d <- lire(f)
    if (is.null(d)) return(NULL)
    for (v in intersect(c("CAMPAGNE", "IDP", num), names(d))) d[[v]] <- .num(d[[v]])
    d$id_placette <- paste(d$CAMPAGNE, d$IDP, sep = "_")
    mark_ifn(d, precision_m)
  }
  structure(list(placettes = sf_pl,
                 flore = tab("FLORE", c("CD_REF", "ABOND")),
                 arbre = tab("ARBRE", c("C13", "HTOT", "V", "W"))),
            class = "sylvo_ifn")
}

# Verifie la forme d'un objet charge par load_ifn().
.check_ifn <- function(ifn, avec_flore = TRUE) {
  if (!is.list(ifn) || !inherits(ifn$placettes, "sf")) {
    stop("`ifn` doit \u00eatre le r\u00e9sultat de load_ifn().", call. = FALSE)
  }
  assert_crs_2154(ifn$placettes)
  if (avec_flore && !is.data.frame(ifn$flore)) {
    stop("`ifn` ne contient pas de table `flore` (FLORE non lu).", call. = FALSE)
  }
  invisible(ifn)
}

#' Filtrer les relevés floristiques IFN
#'
#' Garde les relevés floristiques **en saison** (mois de `DATEECO`, date de validation
#' du levé écologique et floristique, dans `months`), sans **perturbation récente**
#' (incident des 5 dernières années : `NINCID` de 1 à 5, ou `INCID` >= 1 ; codes de
#' `metadonnees.csv`, `NINCID` n'existe qu'à partir de la campagne 2015 et `INCID` de
#' 2009 : en deçà, la perturbation est inconnue et le relevé est conservé), puis les
#' espèces présentes dans au moins `min_occ` relevés retenus. Les lignes de `FLORE`
#' signalées incohérentes (`INCO_FLOR` renseigné : eau, artefact, lisière, roche,
#' autre) sont écartées. Les placettes ne sont pas supprimées : elles gagnent les
#' colonnes `mois_releve`, `en_saison`, `perturbe` et `retenu`.
#'
#' Valeurs provisoires : mois 4 à 9 et seuil de 3 relevés (brief technique), règle
#' de perturbation (à geler avant la phase 1).
#'
#' @param ifn Résultat de [load_ifn()].
#' @param min_occ Nombre minimal de relevés retenus où une espèce doit figurer.
#' @param months Mois (1 à 12) valides.
#' @param exclude_incidents Exclure les relevés perturbés récemment.
#' @return `ifn`, avec `placettes` complétée et `flore` filtrée ; l'attribut
#'   `filtre` résume les effectifs.
#' @examples
#' ifn <- load_ifn(system.file("extdata", package = "sylvostation"))
#' f <- filter_releves(ifn)
#' attr(f, "filtre")
#' @export
filter_releves <- function(ifn, min_occ = 3, months = 4:9, exclude_incidents = TRUE) {
  .check_ifn(ifn)
  if (!is.numeric(min_occ) || length(min_occ) != 1L || is.na(min_occ) || min_occ < 1) {
    stop("`min_occ` doit \u00eatre un entier >= 1.", call. = FALSE)
  }
  if (!is.numeric(months) || !length(months) || anyNA(months) || any(!months %in% 1:12)) {
    stop("`months` doit contenir des mois entre 1 et 12.", call. = FALSE)
  }
  pl <- ifn$placettes
  if (!"DATEECO" %in% names(pl)) {
    stop("Colonne DATEECO absente : ECOLOGIE doit \u00eatre lu par load_ifn().", call. = FALSE)
  }
  pl$mois_releve <- as.integer(format(pl$DATEECO, "%m"))
  pl$en_saison <- !is.na(pl$mois_releve) & pl$mois_releve %in% months
  nincid <- if ("NINCID" %in% names(pl)) .num(pl$NINCID) else rep(NA_real_, nrow(pl))
  incid <- if ("INCID" %in% names(pl)) .num(pl$INCID) else rep(NA_real_, nrow(pl))
  pl$perturbe <- (!is.na(nincid) & nincid >= 1) | (!is.na(incid) & incid >= 1)
  pl$retenu <- pl$en_saison & !(exclude_incidents & pl$perturbe)

  fl <- ifn$flore
  n0 <- nrow(fl)
  fl <- fl[fl$id_placette %in% pl$id_placette[pl$retenu], , drop = FALSE]
  if ("INCO_FLOR" %in% names(fl)) fl <- fl[is.na(fl$INCO_FLOR), , drop = FALSE]
  occ <- tapply(fl$id_placette, fl$CD_REF, function(i) length(unique(i)))
  garde <- as.numeric(names(occ)[occ >= min_occ])
  fl <- fl[fl$CD_REF %in% garde, , drop = FALSE]
  rownames(fl) <- NULL

  ifn$placettes <- pl
  ifn$flore <- fl
  attr(ifn, "filtre") <- list(
    n_placettes = nrow(pl), n_en_saison = sum(pl$en_saison),
    n_perturbees = sum(pl$perturbe), n_retenues = sum(pl$retenu),
    n_lignes_flore_avant = n0, n_lignes_flore_apres = nrow(fl),
    n_especes = length(garde), min_occ = min_occ, months = months)
  ifn
}

#' Taxons de la flore IFN sans valeur indicatrice
#'
#' Liste les `CD_REF` (TAXREF v13.0 pour l'IFN) présents dans `flore` mais absents de
#' la table des valeurs indicatrices, avec le nombre de relevés concernés. Ces
#' taxons ne sont jamais supprimés en silence : à publier dans le rapport. La
#' jointure se fait directement sur `CD_REF` ; la correspondance `CD_NOM` vers
#' `CD_REF` d'autres sources exige une table TAXREF, non disponible à ce jour (à
#' vérifier, mission 007).
#'
#' @param flore `data.frame` de flore (colonnes `CD_REF`, `id_placette`) ou résultat
#'   de [load_ifn()] / [filter_releves()].
#' @param indicateurs Table des valeurs indicatrices (colonne `cd_ref`).
#' @return Un `data.frame` (`cd_ref`, `n_releves`), vide s'il n'y a rien à signaler.
#' @examples
#' fl <- data.frame(CD_REF = c(1, 1, 2), id_placette = c("a", "b", "a"))
#' unmatched_taxa(fl, data.frame(cd_ref = 1))
#' @export
unmatched_taxa <- function(flore, indicateurs) {
  if (is.list(flore) && !is.data.frame(flore)) flore <- flore$flore
  if (!is.data.frame(flore) || !all(c("CD_REF", "id_placette") %in% names(flore))) {
    stop("`flore` doit avoir les colonnes CD_REF et id_placette.", call. = FALSE)
  }
  if (!is.data.frame(indicateurs) || !"cd_ref" %in% names(indicateurs)) {
    stop("`indicateurs` doit avoir une colonne cd_ref.", call. = FALSE)
  }
  manque <- flore[!flore$CD_REF %in% indicateurs$cd_ref, , drop = FALSE]
  if (!nrow(manque)) return(data.frame(cd_ref = numeric(0), n_releves = integer(0)))
  n <- tapply(manque$id_placette, manque$CD_REF, function(i) length(unique(i)))
  out <- data.frame(cd_ref = as.numeric(names(n)), n_releves = as.integer(n))
  out[order(-out$n_releves, out$cd_ref), , drop = FALSE]
}

#' Coefficients de réserve en eau par classe de texture IFN
#'
#' Table par défaut de [compute_gradients()] : millimètres d'eau utilisable par
#' centimètre de terre fine, par code de texture IFN (`TEXT1`, `TEXT2`, modalités de
#' `metadonnees.csv` : 0 absence de terre fine, 1 sable, 2 sable limoneux, 3 sable
#' argileux, 4 limon sableux, 5 limon argileux, 6 limon, 7 argile limoneuse,
#' 8 argile sablo-limoneuse, 9 argile, H texture organique).
#'
#' **`source = "bruand2004"` (défaut)** : table publiée. Bruand A., Duval O., Cousin I.
#' (2004), « Estimation des propriétés de rétention en eau des sols à partir de la base
#' de données SOLHYDRO : une première proposition combinant le type d'horizon, sa
#' texture et sa densité apparente », *Étude et Gestion des Sols* 11(3) : 323-332,
#' **tableau 2, p. 328**, colonnes « sans prise en compte de la densité apparente »
#' (valeurs relues par le relecteur de la mission 013, `docs/referentiels.md` § 18).
#' On retient la réserve en eau utile **« défaut »** (θ à pF 2,0 moins θ à pF 4,2),
#' la plus basse des deux, par prudence. La table distingue l'horizon **A**
#' (`TEXT1`, horizon supérieur) et les horizons **E, B, C** (`TEXT2`) : le résultat
#' est une liste `list(haut = , bas = )` de deux vecteurs nommés, acceptée par
#' l'argument `ru_table` de [compute_gradients()]. Attribut `verifie = TRUE` (le
#' tableau lui-même est relu).
#'
#' **Correspondance codes IFN → classes de l'Aisne** (mission 019) : lue dans le
#' dictionnaire des données brutes de l'IFN ([read_texture_dictionary()], extrait de
#' `metadonnees.csv`), qui définit chaque code par les abréviations des classes du
#' triangle de l'Aisne : 1 = S, 2 = SL, 3 = SA, 4 = LS, LSA, LMS, LLS, 5 = LA, LAS,
#' 6 = LM, LL, 7 = AL, 8 = AS (et `Als`, hors du triangle de l'Aisne, sans valeur
#' chez Bruand), 9 = A, ALO. Attribut `correspondance_verifiee = TRUE`. Un code qui
#' couvre plusieurs classes prend la **moyenne simple** des classes qui ont une valeur
#' (choix du code, non publié) ; avec cette correspondance, chaque code 1 à 9 a au moins
#' une classe renseignée pour chaque type d'horizon (l'ancien repli d'un type d'horizon
#' sur l'autre est retiré ; un code sans valeur rendrait `NA`). Une hypothèse reste du
#' code : `TEXT1` est pris pour un horizon A, `TEXT2` pour un horizon E, B ou C. Les écarts types de l'article
#' (0,14 à 0,53 mm/cm) ne sont pas propagés. `H` vaut `NA` (la couche organique n'est
#' pas comptée), `0` vaut 0. La réserve utile de référence est désormais celle de
#' [ru_from_texture()] (euptf2) ; cette table sert de contre-vérification.
#'
#' **`source = "provisoire"`** : ordres de grandeur **non publiés** de la mission
#' 005 (vecteur unique pour les deux horizons), attribut `verifie = FALSE` ; conservés
#' pour la comparaison.
#'
#' @param source `"bruand2004"` ou `"provisoire"`.
#' @return `"bruand2004"` : liste `haut`, `bas` ; `"provisoire"` : vecteur nommé par
#'   code de texture. Dans les deux cas, attributs `verifie`, `source`, `unite`
#'   (`"mm/cm"`).
#' @examples
#' ru_coefficients()
#' ru_coefficients("provisoire")
#' @export
ru_coefficients <- function(source = c("bruand2004", "provisoire")) {
  source <- match.arg(source)
  if (source == "provisoire") {
    return(structure(
      c("0" = 0, "1" = 0.7, "2" = 1.0, "3" = 1.1, "4" = 1.4, "5" = 1.6,
        "6" = 1.7, "7" = 1.5, "8" = 1.3, "9" = 1.4, "H" = NA_real_),
      verifie = FALSE, source = "provisoire (non publi\u00e9)", unite = "mm/cm"))
  }
  # Bruand et al. 2004, tableau 2, p. 328 : reserve utile "defaut" (mm/cm),
  # sans prise en compte de Da, 15 classes du triangle de l'Aisne.
  # NA = "-" dans l'article (pas de valeur).
  b <- data.frame(
    aisne = c("ALO", "AL", "AS", "A", "LA", "LAS", "LSA", "LM", "LMS", "LS", "LLS", "LL",
              "SA", "SL", "S"),
    haut  = c(1.24, 1.36, 1.73, NA, 1.73, 1.67, 1.43, 2.13, 1.83, 1.62, NA, NA,
              1.28, 1.31, 0.60),   # horizon A
    bas   = c(1.12, 1.13, 0.95, 0.93, 1.49, 1.48, 1.27, 2.07, 1.96, NA, NA, NA,
              1.03, 1.16, 0.73),   # horizons E, B, C
    stringsAsFactors = FALSE)
  # Correspondance code IFN -> classes : dictionnaire IFN (metadonnees.csv, mission 019).
  # Un code a plusieurs classes prend la moyenne des classes qui ont une valeur.
  dico <- read_texture_dictionary()
  dico <- dico[dico$code %in% as.character(1:9), , drop = FALSE]
  corr <- stats::setNames(strsplit(dico$classes, ",", fixed = TRUE), dico$code)
  moy <- function(classes, col) {
    v <- b[[col]][match(classes, b$aisne)]
    if (all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE)
  }
  haut <- vapply(corr, moy, numeric(1), col = "haut")
  bas  <- vapply(corr, moy, numeric(1), col = "bas")
  haut <- stats::setNames(c(0, haut, NA_real_), c("0", names(corr), "H"))
  bas  <- stats::setNames(c(0, bas,  NA_real_), c("0", names(corr), "H"))
  structure(list(haut = haut, bas = bas), verifie = TRUE, correspondance_verifiee = TRUE,
            source = paste("Bruand, Duval et Cousin (2004), Etude et Gestion des Sols 11(3),",
                           "323-332, tableau 2 p. 328, colonne defaut, sans Da"),
            unite = "mm/cm", correspondance = corr)
}

# Valide `ru_table` : vecteur nomme, ou liste(haut, bas) de vecteurs nommes
.check_ru_table <- function(ru_table) {
  ok_vec <- function(x) is.numeric(x) && !is.null(names(x))
  if (is.list(ru_table)) {
    if (!all(c("haut", "bas") %in% names(ru_table)) ||
        !ok_vec(ru_table$haut) || !ok_vec(ru_table$bas)) {
      stop("`ru_table` doit \u00eatre un vecteur num\u00e9rique nomm\u00e9 par code de texture ",
           "ou une liste `haut`, `bas` de tels vecteurs.", call. = FALSE)
    }
  } else if (!ok_vec(ru_table)) {
    stop("`ru_table` doit \u00eatre un vecteur num\u00e9rique nomm\u00e9 par code de texture.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# Reserve utile (mm) : somme sur les deux horizons (epaisseur cm x coefficient mm/cm),
# reduite par la charge en elements grossiers (CAILLOUX, dixiemes ; "X" = absence).
# PROF1 = profondeur de l'horizon superieur, PROF2 = profondeur de sondage (dm) :
# PROF1 < PROF2 sur tous les extraits. Sans fosse (OBSPEDO 5 ou X) : NA.
.reserve_utile <- function(pl, ru_table) {
  col <- function(v) if (v %in% names(pl)) pl[[v]] else rep(NA_character_, nrow(pl))
  tab_haut <- if (is.list(ru_table)) ru_table$haut else ru_table
  tab_bas <- if (is.list(ru_table)) ru_table$bas else ru_table
  coef <- function(code, tab) {
    k <- toupper(as.character(code))
    v <- unname(tab[k])
    v[is.na(k)] <- NA_real_
    v
  }
  p1 <- .num(col("PROF1")) * 10
  p2 <- .num(col("PROF2")) * 10
  deux <- !is.na(p1) & !is.na(col("TEXT1"))
  ep_haut <- ifelse(deux, p1, 0)
  ep_bas <- p2 - ifelse(deux, p1, 0)
  c_haut <- ifelse(deux, coef(col("TEXT1"), tab_haut), 0)
  c_haut[is.na(c_haut)] <- 0   # couche organique ou code inconnu : non comptee
  c_bas <- coef(col("TEXT2"), tab_bas)
  c_bas[!is.na(col("TEXT2")) & is.na(c_bas)] <- 0
  cail <- .num(col("CAILLOUX"))
  cail[toupper(col("CAILLOUX")) %in% "X"] <- 0
  cail[is.na(cail)] <- 0
  ru <- (ep_haut * c_haut + ep_bas * c_bas) * (1 - pmin(cail, 10) / 10)
  sans_fosse <- toupper(col("OBSPEDO")) %in% c("5", "X")
  ru[sans_fosse | is.na(p2) | is.na(c_bas)] <- NA_real_
  # horizon entierement organique (H) : non modelise -> NA ; entierement caillouteux
  # (OBSPEDO R) : aucune terre fine -> 0
  organique <- toupper(col("TEXT1")) %in% "H" | toupper(col("TEXT2")) %in% "H"
  ru[organique] <- NA_real_
  ru[toupper(col("OBSPEDO")) %in% "R"] <- 0
  ru
}

# Profondeur (cm) du premier signe d'hydromorphie parmi gley, taches d'oxydation et
# pseudogley (classes de 10 cm : code k = k x 10 cm). Avant 2017, l'absence n'est pas
# renseignee ; depuis 2017, "X" = absence ; vide + OBSPEDO 5 ou X = fosse non faite.
.engorgement <- function(pl) {
  col <- function(v) if (v %in% names(pl)) pl[[v]] else rep(NA_character_, nrow(pl))
  prof <- cbind(.num(col("PGLEY")), .num(col("POX")), .num(col("PPSEUDO"))) * 10
  d <- suppressWarnings(apply(prof, 1, min, na.rm = TRUE))
  d[!is.finite(d)] <- NA_real_
  sans_fosse <- toupper(col("OBSPEDO")) %in% c("5", "X")
  list(prof_cm = ifelse(sans_fosse, NA_real_, d),
       engorgement = ifelse(sans_fosse, NA, !is.na(d)))
}

#' Calculer les gradients écologiques par placette
#'
#' Trois familles de gradients, sans aucune variable fine :
#'
#' * **trophique** : moyenne, par placette, des valeurs indicatrices (colonnes
#'   `ph` et `azote` de `indicateurs`) des espèces présentes ; `grad_trophique` est
#'   la moyenne des colonnes disponibles. Sans table `indicateurs`, repli sur l'axe 1
#'   d'une AFC (`ade4::dudi.coa`) de la matrice présence/absence : le signe de l'axe
#'   est arbitraire.
#' * **hydrique** : réserve utile `ru_mm` par pédotransfert (texture, profondeur,
#'   éléments grossiers ; coefficients `ru_table`, par défaut [ru_coefficients()]
#'   **à vérifier**) et engorgement (`engorg_prof_cm`, profondeur du premier signe
#'   d'hydromorphie ; `engorgement`). Aucun indice composite n'est inventé : les
#'   deux colonnes sont rendues.
#' * **bioclimatique** : si `climat` est fourni (`SpatRaster` en EPSG:2154 de maille
#'   au moins 90 m, couches nommées `p_sv`, `etp_sv` (cumuls de la saison de végétation,
#'   mm) et `t_moy` (°C) ; convention de ce paquet), extraction aux placettes :
#'   `coarse_p_etp_sv` (P - ETP) et `coarse_t_moy`. La règle bloquante est
#'   appliquée avant toute extraction.
#'
#' @param ifn Résultat de [load_ifn()] (de préférence passé par [filter_releves()]).
#' @param indicateurs `data.frame` des valeurs indicatrices (colonne `cd_ref` en
#'   TAXREF v13.0, colonnes `ph`, `azote`), ou `NULL` pour l'AFC. Voir
#'   `inst/extdata/synth_indicateurs.csv` (synthétique).
#' @param climat `SpatRaster` ou `NULL`. Maille d'au moins `min_res_ifn_m`, quel que
#'   soit le nom des couches ; agréger avant avec [aggregate_to_km()].
#' @param min_res_ifn_m Maille minimale (m) d'une couche croisée avec des placettes
#'   IFN : 1000 (brief technique, étape 5 : climat et pH agrégés à 1 km).
#' @param ru_table Vecteur nommé de coefficients mm/cm par code de texture, ou liste
#'   `haut`, `bas` (horizon supérieur `TEXT1`, horizon inférieur `TEXT2`), voir
#'   [ru_coefficients()]. `ru_verifie` du résultat vaut `TRUE` seulement
#'   si `verifie` est vrai et si `correspondance_verifiee` n'est pas faux ; l'attribut
#'   `correspondance_verifiee` est repris tel quel.
#' @return Un `sf` (Lambert-93) : `id_placette`, `CAMPAGNE`, `IDP`, `source`,
#'   `loc_precision_m`, `n_taxa_indic`, `grad_ph`, `grad_azote`, `grad_trophique`,
#'   `ru_mm`, `engorg_prof_cm`, `engorgement` et, si `climat`, les colonnes
#'   `coarse_`. Attributs : `methode_trophique` (`"indicateurs"` ou `"afc"`) et
#'   `taxa_non_apparies` (voir [unmatched_taxa()]).
#' @examples
#' ifn <- filter_releves(load_ifn(system.file("extdata", package = "sylvostation")))
#' ind <- utils::read.delim(system.file("extdata", "synth_indicateurs.csv",
#'                              package = "sylvostation"), sep = ";")
#' g <- compute_gradients(ifn, ind)
#' head(sf::st_drop_geometry(g)[, c("id_placette", "grad_trophique", "ru_mm")])
#' @export
compute_gradients <- function(ifn, indicateurs = NULL, climat = NULL,
                              ru_table = ru_coefficients(), min_res_ifn_m = 1000) {
  .check_ifn(ifn)
  .check_ru_table(ru_table)
  pl <- ifn$placettes
  fl <- ifn$flore
  out <- pl[, c("id_placette", "CAMPAGNE", "IDP", "source", "loc_precision_m")]

  # --- trophique
  ids <- pl$id_placette
  if (!is.null(indicateurs)) {
    if (!is.data.frame(indicateurs) || !"cd_ref" %in% names(indicateurs)) {
      stop("`indicateurs` doit avoir une colonne cd_ref.", call. = FALSE)
    }
    cols <- intersect(c("ph", "azote"), names(indicateurs))
    if (!length(cols)) stop("`indicateurs` doit avoir une colonne ph ou azote.", call. = FALSE)
    if (!all(vapply(indicateurs[cols], is.numeric, logical(1)))) {
      stop("Colonnes ph/azote non num\u00e9riques (lire avec read.delim(sep = \";\") : ",
           "d\u00e9cimale = point).", call. = FALSE)
    }
    j <- indicateurs[match(fl$CD_REF, indicateurs$cd_ref), cols, drop = FALSE]
    avec <- !is.na(match(fl$CD_REF, indicateurs$cd_ref))
    moy <- function(v) as.numeric(tapply(v, factor(fl$id_placette, ids), mean, na.rm = TRUE))
    out$n_taxa_indic <- as.integer(tapply(avec, factor(fl$id_placette, ids), sum))
    out$n_taxa_indic[is.na(out$n_taxa_indic)] <- 0L
    out$grad_ph <- if ("ph" %in% cols) moy(j$ph) else NA_real_
    out$grad_azote <- if ("azote" %in% cols) moy(j$azote) else NA_real_
    out$grad_trophique <- rowMeans(cbind(out$grad_ph, out$grad_azote), na.rm = TRUE)
    out$grad_trophique[is.nan(out$grad_trophique)] <- NA_real_
    out$grad_ph[is.nan(out$grad_ph)] <- NA_real_
    out$grad_azote[is.nan(out$grad_azote)] <- NA_real_
    methode <- "indicateurs"
    non_app <- unmatched_taxa(fl, indicateurs)
  } else {
    if (!requireNamespace("ade4", quietly = TRUE)) {
      stop("Le paquet `ade4` est requis pour l'AFC (sans `indicateurs`).", call. = FALSE)
    }
    tab <- unclass(table(factor(fl$id_placette, ids), fl$CD_REF)) > 0
    tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
    if (nrow(tab) < 3 || ncol(tab) < 3) {
      stop("AFC impossible : au moins 3 relev\u00e9s et 3 esp\u00e8ces sont n\u00e9cessaires.",
           call. = FALSE)
    }
    afc <- ade4::dudi.coa(as.data.frame(tab * 1), scannf = FALSE, nf = 2)
    out$n_taxa_indic <- as.integer(rowSums(unclass(table(factor(fl$id_placette, ids),
                                                         fl$CD_REF)) > 0))
    out$grad_ph <- NA_real_
    out$grad_azote <- NA_real_
    out$grad_trophique <- afc$li[match(ids, rownames(afc$li)), 1]
    methode <- "afc"
    non_app <- data.frame(cd_ref = numeric(0), n_releves = integer(0))
  }

  # --- hydrique
  out$ru_mm <- .reserve_utile(pl, ru_table)
  eng <- .engorgement(pl)
  out$engorg_prof_cm <- eng$prof_cm
  out$engorgement <- eng$engorgement

  # --- bioclimatique (maille large uniquement)
  if (!is.null(climat)) {
    cl <- .extraire_climat(out, climat, min_res_ifn_m)
    out$coarse_p_etp_sv <- cl$p_etp_sv
    out$coarse_t_moy <- cl$t_moy
  }
  # vrai seulement si la table est publiee ET la correspondance codes IFN -> classes
  # de l'Aisne est sourcee (attribut absent = table sans correspondance a verifier : vrai)
  cv <- attr(ru_table, "correspondance_verifiee")
  attr(out, "ru_verifie") <- isTRUE(attr(ru_table, "verifie")) && (is.null(cv) || isTRUE(cv))
  attr(out, "correspondance_verifiee") <- if (is.null(cv)) NA else isTRUE(cv)
  attr(out, "methode_trophique") <- methode
  attr(out, "taxa_non_apparies") <- non_app
  out
}

# Extraction du climat kilometrique aux placettes. La regle bloquante est appelee en
# premier ; les couches de maille < 90 m ou portant un nom de variable fine sont refusees.
.extraire_climat <- function(pts, climat, min_res_ifn_m = 1000) {
  if (!inherits(climat, "SpatRaster")) {
    stop("`climat` doit \u00eatre un SpatRaster.", call. = FALSE)
  }
  assert_crs_2154(climat)
  noms <- names(climat)
  fines <- noms[vapply(noms, .is_fine, logical(1))]
  if (length(fines)) {
    assert_no_fine_extract_on_ifn(pts, fines)  # leve l'erreur de la regle bloquante
  }
  assert_no_fine_extract_on_ifn(pts, paste0("coarse_", noms))
  if (any(terra::res(climat) < min_res_ifn_m)) {
    stop("`climat` doit \u00eatre de maille >= ", min_res_ifn_m, " m pour \u00eatre crois\u00e9e avec des placettes IFN (agr\u00e9ger : aggregate_to_km()) : ",
         "r\u00e9solution ", paste(terra::res(climat), collapse = " x "), " m.", call. = FALSE)
  }
  requis <- c("p_sv", "etp_sv", "t_moy")
  if (!all(requis %in% noms)) {
    stop("`climat` doit avoir les couches : ", paste(requis, collapse = ", "),
         " (manque : ", paste(setdiff(requis, noms), collapse = ", "), ").", call. = FALSE)
  }
  xy <- sf::st_coordinates(pts)  # x = est, y = nord
  v <- terra::extract(climat[[requis]], xy)
  data.frame(p_etp_sv = v$p_sv - v$etp_sv, t_moy = v$t_moy)
}
