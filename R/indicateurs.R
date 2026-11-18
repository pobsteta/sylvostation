# Valeurs indicatrices reelles (mission 015). Source : Tichy et al. (2023), Zenodo
# 10.5281/zenodo.7427088, CC BY 4.0 (docs/referentiels.md, par. 14). Noms standardises
# Euro+Med, pas TAXREF : jointure par nom latin vers TAXREF v18 (par. 15).

#' Lire la table TAXREF (colonnes utiles)
#'
#' Lit `TAXREFv18.txt` (tabulations, guillemets, UTF-8 ; colonnes vérifiées sur le fichier
#' `TAXREF_v18_2025.zip`, voir `docs/referentiels.md` § 15), l'archive zip qui le
#' contient, ou un extrait CSV de mêmes colonnes (séparateur `;` ou tabulation).
#' Ne garde que `CD_NOM`, `CD_REF`, `LB_NOM`, `RANG` (en texte).
#'
#' @param path Chemin du `.txt`, du `.csv` ou du `.zip`. Aucun téléchargement n'est fait ici.
#' @return Un `data.frame` (`CD_NOM`, `CD_REF`, `LB_NOM`, `RANG`).
#' @examples
#' f <- system.file("extdata", "taxref_v18_extrait.csv", package = "sylvostation")
#' head(read_taxref(f))
#' @export
read_taxref <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Fichier TAXREF introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  if (grepl("\\.zip$", path, ignore.case = TRUE)) {
    noms <- utils::unzip(path, list = TRUE)$Name
    cible <- noms[grepl("^TAXREFv[0-9]+\\.txt$", basename(noms))]
    if (length(cible) != 1L) stop("Pas de fichier TAXREFv*.txt unique dans l'archive.", call. = FALSE)
    tmp <- tempfile("taxref_")
    dir.create(tmp)
    on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
    utils::unzip(path, files = cible, exdir = tmp)
    path <- file.path(tmp, cible)
  }
  premiere <- readLines(path, n = 1L, encoding = "UTF-8", warn = FALSE)
  sep <- if (grepl("\t", premiere)) "\t" else ";"
  entete <- gsub("\"", "", strsplit(premiere, sep, fixed = TRUE)[[1]])
  utiles <- c("CD_NOM", "CD_REF", "LB_NOM", "RANG")
  manque <- setdiff(utiles, entete)
  if (length(manque)) {
    stop("Colonnes TAXREF absentes : ", paste(manque, collapse = ", "), call. = FALSE)
  }
  cc <- ifelse(entete %in% utiles, "character", "NULL")
  d <- utils::read.delim(path, sep = sep, quote = "\"", colClasses = cc, na.strings = "",
                         encoding = "UTF-8", comment.char = "")
  d[, utiles, drop = FALSE]
}

#' Lire la table de valeurs indicatrices de Tichý et al. (2023)
#'
#' Lit la feuille finale `Tab-IVs-Tichy-et-al2023` du classeur Zenodo
#' `Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx` (colonnes lues sur le fichier :
#' `SeqID`, `Taxon`, `LIGHT`, `TEMPERATURE`, `MOISTURE`, `REACTION`, `NUTRIENTS`,
#' `SALINITY`, une ligne d'en-tête puis une ligne `Average`), ou un extrait CSV (`;`)
#' de mêmes colonnes. Le symbole `x` (indifférent) et les cases vides deviennent `NA`.
#'
#' @param path Chemin du `.xlsx` (paquet `readxl`) ou du `.csv`.
#' @return Un `data.frame` (`taxon`, `ph` = `REACTION`, `azote` = `NUTRIENTS`,
#'   `humidite` = `MOISTURE`), valeurs numériques de type Ellenberg.
#' @examples
#' f <- system.file("extdata", "tichy_2023_extrait.csv", package = "sylvostation")
#' read_tichy(f)
#' @export
read_tichy <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Fichier Tichy introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  if (grepl("\\.xlsx$", path, ignore.case = TRUE)) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Le paquet `readxl` est requis pour lire le classeur Zenodo.", call. = FALSE)
    }
    raw <- as.data.frame(readxl::read_excel(path, sheet = "Tab-IVs-Tichy-et-al2023",
                                            col_names = FALSE, col_types = "text",
                                            .name_repair = "minimal"),
                         stringsAsFactors = FALSE)
    # ligne 1 : noms des axes (colonnes 3 a 8) ; ligne 2 : SeqID, Taxon puis "Average"
    l1 <- as.character(unlist(raw[1, ]))
    l2 <- as.character(unlist(raw[2, ]))
    entete <- ifelse(is.na(l1), l2, l1)
    d <- raw[-(1:2), , drop = FALSE]
    names(d) <- entete
  } else {
    d <- utils::read.delim(path, sep = ";", quote = "\"", colClasses = "character",
                           na.strings = "", encoding = "UTF-8")
  }
  need <- c("Taxon", "MOISTURE", "REACTION", "NUTRIENTS")
  if (!all(need %in% names(d))) {
    stop("Colonnes attendues (", paste(need, collapse = ", "), ") absentes : ",
         paste(names(d), collapse = ", "), call. = FALSE)
  }
  num <- function(x) suppressWarnings(as.numeric(x))   # "x" -> NA
  out <- data.frame(taxon = trimws(d$Taxon), ph = num(d$REACTION), azote = num(d$NUTRIENTS),
                    humidite = num(d$MOISTURE), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out[!is.na(out$taxon) & nzchar(out$taxon), , drop = FALSE]
}

# binome (deux premiers mots) d'un nom latin
.binome <- function(x) sub("^([^ ]+ [^ ]+).*$", "\\1", x)

#' Valeurs indicatrices (pH, azote, humidité) jointes à TAXREF
#'
#' Charge les valeurs indicatrices de type Ellenberg de Tichý et al. (2023) (Zenodo,
#' CC BY 4.0) et les joint à TAXREF **par le nom latin** (`LB_NOM`), car la source suit
#' Euro+Med et non TAXREF. Sortie au format de `synth_indicateurs.csv` : `cd_ref`,
#' `nom`, `ph` (colonne `REACTION`), `azote` (`NUTRIENTS`), `humidite` (`MOISTURE`),
#' `synthetic = FALSE`. Les valeurs ne sont **pas** des mesures de pH : ce sont des
#' indices ordinaux (réaction, 1 à 9 ; nutriments, 1 à 9 ; humidité, 1 à 12).
#'
#' Deux modes :
#' - `taxa = NULL` : une ligne par taxon de la source apparié, `cd_ref` = `CD_REF`
#'   TAXREF v18 du nom (en cas de synonymes de la source sur un même `cd_ref`, moyenne) ;
#' - `taxa` = codes à résoudre (par exemple `CD_REF` de la flore IFN, TAXREF v13) : un
#'   `CD_NOM` ne change pas d'une version à l'autre pour un nom donné (méthode TAXREF,
#'   `docs/referentiels.md` § 15) ; chaque code est cherché comme `CD_NOM` dans TAXREF v18,
#'   son nom (celui du `CD_REF` v18) est apparié à la source ; **repli** pour un taxon
#'   infra-spécifique (sous-espèce, variété) sur son binôme. Une ligne par code résolu,
#'   `cd_ref` = le code **tel que donné** (jointure directe avec `flore$CD_REF`),
#'   colonnes `cd_ref_taxref` (v18) et `appariement` (`"nom"`, `"binome"`, `"synonyme"` ou `"agregat"`).
#'
#' Les non-appariés ne sont jamais supprimés en silence : attribut `non_apparies`
#' (`data.frame` ; en mode `taxa`, colonnes `cd_ref`, `nom`, `rang`, `motif`).
#'
#' @param source `"tichy"` (Tichý et al. 2023, seule source joignable). `"baseflor"`
#'   (non joignable, `docs/referentiels.md` § 14) et `"ecoplant"` (sur demande,
#'   AgroParisTech, jamais dans le dépôt) lèvent une erreur explicite.
#' @param path Chemin du classeur Zenodo `.xlsx` (téléchargé à l'exécution, cache hors
#'   dépôt) ou de l'extrait CSV, voir [read_tichy()].
#' @param taxref `data.frame` de [read_taxref()] ou chemin du fichier TAXREF.
#' @param taxa Codes à résoudre (facultatif), voir plus haut.
#' @param agregats En mode `taxa` seulement, `TRUE` par défaut : à défaut d'autre
#'   appariement, une espèce ou un taxon infra-spécifique s'apparie à l'agrégat
#'   « binôme aggr. » de la source (`appariement = "agregat"`, `nom` = libellé de
#'   l'agrégat). **Approximation signalée** : l'agrégat englobe plusieurs espèces
#'   proches (par exemple *Dryopteris carthusiana* aggr. englobe *D. dilatata*, dont
#'   l'écologie diffère) ; la valeur est celle de l'agrégat, pas de l'espèce.
#' @param synonymes En mode `taxa` seulement. `FALSE` (défaut, prudent) : le nom retenu
#'   est celui du `CD_REF` v18. `TRUE` : à défaut, les **synonymes** TAXREF de rang espèce
#'   (autres `LB_NOM` de même `CD_REF`) sont essayés ; `appariement` vaut alors
#'   `"synonyme"`. Risque : un synonyme TAXREF peut être un nom mal appliqué (même
#'   libellé, autre taxon dans la source) ; à n'utiliser qu'en le disant.
#' @return Un `data.frame`, attributs `source`, `licence`, `non_apparies`.
#' @examples
#' tx <- read_taxref(system.file("extdata", "taxref_v18_extrait.csv", package = "sylvostation"))
#' ti <- system.file("extdata", "tichy_2023_extrait.csv", package = "sylvostation")
#' ind <- load_indicator_values("tichy", ti, tx)
#' head(ind)
#' @export
load_indicator_values <- function(source = c("tichy", "ecoplant", "baseflor"), path, taxref,
                                  taxa = NULL, synonymes = FALSE, agregats = TRUE) {
  source <- match.arg(source)
  if (source == "baseflor") {
    stop("Baseflor n'est pas joignable (HTTP 403, colonnes non lues) : voir ",
         "docs/referentiels.md, par. 14. Utiliser source = \"tichy\".", call. = FALSE)
  }
  if (source == "ecoplant") {
    stop("EcoPlant est une donn\u00e9e AgroParisTech sur demande, jamais dans le d\u00e9p\u00f4t ",
         "(docs/referentiels.md, par. 14). Utiliser source = \"tichy\".", call. = FALSE)
  }
  if (is.character(taxref)) taxref <- read_taxref(taxref)
  if (!is.data.frame(taxref) || !all(c("CD_NOM", "CD_REF", "LB_NOM", "RANG") %in% names(taxref))) {
    stop("`taxref` doit avoir les colonnes CD_NOM, CD_REF, LB_NOM, RANG.", call. = FALSE)
  }
  ti <- read_tichy(path)
  ti <- ti[!duplicated(ti$taxon), , drop = FALSE]
  val <- c("ph", "azote", "humidite")

  if (is.null(taxa)) {
    t <- taxref[taxref$LB_NOM %in% ti$taxon, , drop = FALSE]
    t <- t[order(t$CD_NOM != t$CD_REF), , drop = FALSE]   # nom valide d'abord
    ti$cd_ref_taxref <- t$CD_REF[match(ti$taxon, t$LB_NOM)]
    app <- ti[!is.na(ti$cd_ref_taxref), , drop = FALSE]
    moy <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
    out <- stats::aggregate(app[val], by = list(cd_ref = app$cd_ref_taxref), FUN = moy)
    out$cd_ref <- as.numeric(out$cd_ref)
    out$nom <- taxref$LB_NOM[match(as.character(out$cd_ref), taxref$CD_NOM)]
    out <- out[order(out$cd_ref), c("cd_ref", "nom", val), drop = FALSE]
    out$synthetic <- FALSE
    rownames(out) <- NULL
    nonapp <- data.frame(taxon = ti$taxon[is.na(ti$cd_ref_taxref)], stringsAsFactors = FALSE)
  } else {
    taxa <- unique(as.character(taxa[!is.na(taxa)]))
    r <- taxref[match(taxa, taxref$CD_NOM), , drop = FALSE]      # le code est un CD_NOM
    ref18 <- taxref[match(r$CD_REF, taxref$CD_NOM), , drop = FALSE]
    nom <- ref18$LB_NOM
    rang <- ref18$RANG
    pos <- match(nom, ti$taxon)
    mode <- rep(NA_character_, length(taxa))
    mode[!is.na(pos)] <- "nom"
    infra <- c("SSES", "VAR", "SVAR", "SSER", "SER", "SSTR", "TR", "RACE", "FO", "SSFO", "CAR")
    repli <- is.na(pos) & !is.na(nom) & rang %in% infra
    pos[repli] <- match(.binome(nom[repli]), ti$taxon)
    mode[repli & !is.na(pos)] <- "binome"
    if (isTRUE(synonymes)) {
      for (i in which(is.na(pos) & !is.na(r$CD_REF))) {
        syn <- taxref[taxref$CD_REF == r$CD_REF[i] & taxref$RANG == "ES", , drop = FALSE]
        j <- match(syn$LB_NOM, ti$taxon)
        j <- j[!is.na(j)]
        if (length(j)) {
          pos[i] <- j[1]
          mode[i] <- "synonyme"
          nom[i] <- ti$taxon[j[1]]
        }
      }
    }
    if (isTRUE(agregats)) {
      # repli "binome aggr." (agregats de Tichy) pour une espece ou un taxon infra-specifique
      cand <- is.na(pos) & !is.na(nom) & rang %in% c("ES", infra)
      j <- match(paste0(.binome(nom[cand]), " aggr."), ti$taxon)
      pos[which(cand)[!is.na(j)]] <- j[!is.na(j)]
      mode[which(cand)[!is.na(j)]] <- "agregat"
    }
    ok <- !is.na(pos)
    nom[!is.na(mode) & mode == "agregat"] <- ti$taxon[pos[!is.na(mode) & mode == "agregat"]]
    out <- data.frame(cd_ref = suppressWarnings(as.numeric(taxa[ok])), nom = nom[ok],
                      ti[pos[ok], val, drop = FALSE], synthetic = FALSE,
                      cd_ref_taxref = suppressWarnings(as.numeric(ref18$CD_REF[ok])),
                      appariement = mode[ok], stringsAsFactors = FALSE)
    rownames(out) <- NULL
    motif <- ifelse(is.na(r$CD_NOM), "CD_NOM absent de TAXREF",
                    ifelse(rang %in% c("GN", "FM", "OR", "CLAD", "SC", "SPTR"),
                           "rang sup\u00e9rieur \u00e0 l'esp\u00e8ce", "nom absent de la source"))
    nonapp <- data.frame(cd_ref = suppressWarnings(as.numeric(taxa[!ok])), nom = nom[!ok],
                         rang = rang[!ok], motif = motif[!ok], stringsAsFactors = FALSE)
  }
  rownames(nonapp) <- NULL
  attr(out, "source") <- paste("Tichy et al. (2023), J. Veg. Sci. 34, e13168 ;",
                               "Zenodo 10.5281/zenodo.7427088 v2.0")
  attr(out, "licence") <- "CC BY 4.0"
  attr(out, "non_apparies") <- nonapp
  out
}

#' Taux d'appariement des espèces d'une flore avec les valeurs indicatrices
#'
#' Mesure, pour la flore IFN, la part des espèces (codes `CD_REF` distincts) et des
#' occurrences (lignes de relevé) qui ont une valeur indicatrice, via
#' [load_indicator_values()] en mode `taxa`. Les non-appariés sont listés avec leur
#' nom et leur rang, jamais supprimés.
#'
#' @param flore `data.frame` de flore (colonne `CD_REF`) ou résultat de [load_ifn()].
#' @param indicateurs Résultat de `load_indicator_values(..., taxa = unique(flore$CD_REF))`.
#' @return Une liste : `n_especes`, `n_apparies`, `taux_especes`, `n_occurrences`,
#'   `taux_occurrences`, `par_appariement` (effectifs `nom` / `binome`), `non_apparies`
#'   (avec `n_releves`).
#' @examples
#' fl <- data.frame(CD_REF = c(1, 1, 2), id_placette = c("a", "b", "a"))
#' ind <- data.frame(cd_ref = 1, appariement = "nom")
#' indicator_match_rate(fl, ind)$taux_especes
#' @export
indicator_match_rate <- function(flore, indicateurs) {
  if (is.list(flore) && !is.data.frame(flore)) flore <- flore$flore
  if (!is.data.frame(flore) || !"CD_REF" %in% names(flore)) {
    stop("`flore` doit avoir une colonne CD_REF.", call. = FALSE)
  }
  if (!is.data.frame(indicateurs) || !"cd_ref" %in% names(indicateurs)) {
    stop("`indicateurs` doit avoir une colonne cd_ref.", call. = FALSE)
  }
  cd <- as.numeric(flore$CD_REF)
  cd <- cd[!is.na(cd)]
  esp <- unique(cd)
  ok <- esp %in% indicateurs$cd_ref
  app <- if ("appariement" %in% names(indicateurs)) {
    table(indicateurs$appariement[indicateurs$cd_ref %in% esp])
  } else table(character(0))
  na <- attr(indicateurs, "non_apparies")
  manque <- data.frame(cd_ref = esp[!ok],
                       n_releves = as.integer(table(factor(cd, levels = esp))[!ok]))
  if (is.data.frame(na) && all(c("cd_ref", "nom", "rang", "motif") %in% names(na))) {
    manque <- cbind(manque, na[match(manque$cd_ref, na$cd_ref), c("nom", "rang", "motif")])
  }
  manque <- manque[order(-manque$n_releves, manque$cd_ref), , drop = FALSE]
  rownames(manque) <- NULL
  list(n_especes = length(esp), n_apparies = sum(ok), taux_especes = sum(ok) / length(esp),
       n_occurrences = length(cd), taux_occurrences = sum(cd %in% indicateurs$cd_ref) / length(cd),
       par_appariement = app, non_apparies = manque)
}
