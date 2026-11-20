# Controle par essence et modele de sensibilite (mission 037, ADR 0008).
# L'essence n'entre JAMAIS dans la carte, les types ni les modeles du pipeline : ces fonctions
# produisent un controle (trophique predit hors pli contre essence en place) et une
# sensibilite (gain de R2 si l'on connaissait l'essence), publies a part.
# Sources : docs/referentiels.md § 7 (IFN), § 33.5 bis, § 36 (cette mission).

# Mention portee par les sorties de sensibilite
.AVERT_SENSIBILITE <- paste("sensibilite : essence en place ; ne pas lire comme la carte",
                            "(ADR 0008)")

# Groupes de la nomenclature BD Forêt v2 (TFV) pour les essences pures. Les regroupements `G01`
# (chenes decidus) et `G61` (sapin ou epicea) ne sont pas decrits dans ce qui a ete lu : la
# correspondance ESPAR est une hypothese, a verifier (docs/referentiels.md, § 36).
.BDFORET_PUR <- c("FF1-09-09" = "H\u00eatre", "FF1G01-01" = "Ch\u00eanes d\u00e9cidus",
                  "FF1-10-10" = "Ch\u00e2taignier", "FF1-49-49" = "Autres feuillus",
                  "FF2G61-61" = "Sapin ou \u00e9pic\u00e9a", "FF2-52-52" = "Pin sylvestre",
                  "FF2-64-64" = "Douglas", "FF2-63-63" = "M\u00e9l\u00e8ze",
                  "FF2-90-90" = "Autres conif\u00e8res", "FF2G53-53" = "Autres conif\u00e8res")

#' Dictionnaire des codes ESPAR de l'IFN
#'
#' Lit l'extrait `inst/extdata/ifn_espar_codes.csv` (lignes `ESPAR1` de `metadonnees.csv`,
#' campagnes 2009 et suivantes, Licence Ouverte 2.0) : code ESPAR, nom français, nom latin.
#' Le code `332G`, présent dans la table ARBRE, n'y figure pas (traité comme « autre »).
#'
#' @param path Chemin du fichier (défaut : celui du paquet).
#' @return Un `data.frame` : `code`, `nom`, `latin`.
#' @examples
#' head(read_espar_codes(), 3)
#' @export
read_espar_codes <- function(path = system.file("extdata", "ifn_espar_codes.csv",
                                                package = "sylvostation")) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    stop("Dictionnaire ESPAR introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  d <- utils::read.delim(path, sep = ";", colClasses = "character", encoding = "UTF-8")
  if (!all(c("code", "nom", "latin") %in% names(d))) {
    stop("Le dictionnaire ESPAR doit avoir les colonnes code, nom, latin.", call. = FALSE)
  }
  d[, c("code", "nom", "latin"), drop = FALSE]
}

#' Groupe de la nomenclature BD Forêt d'une essence IFN
#'
#' Regroupe les codes ESPAR comme la nomenclature TFV de la BD Forêt v2 (hêtre, chênes
#' décidus, châtaignier, sapin ou épicéa, pin sylvestre, douglas, mélèze, autres conifères,
#' autres feuillus). **Correspondance partielle, hypothèse à vérifier** (regroupements `G01` et
#' `G61` non lus ; chênes décidus = ESPAR 02, 03, 04, 05, 07, 34).
#'
#' @param espar Codes ESPAR (caractères).
#' @return Un vecteur de caractères (`NA` si `espar` est `NA`).
#' @examples
#' espar_group_tfv(c("09", "62", "13G", NA))
#' @export
espar_group_tfv <- function(espar) {
  e <- as.character(espar)
  out <- ifelse(e %in% c("02", "03", "04", "05", "07", "34"), "Ch\u00eanes d\u00e9cidus",
         ifelse(e == "09", "H\u00eatre",
         ifelse(e == "10", "Ch\u00e2taignier",
         ifelse(e %in% c("61", "62"), "Sapin ou \u00e9pic\u00e9a",
         ifelse(e == "52", "Pin sylvestre",
         ifelse(e == "64", "Douglas",
         ifelse(e == "63", "M\u00e9l\u00e8ze",
         ifelse(grepl("^5[0-9]|^6[0-9]|^7[0-9]", e), "Autres conif\u00e8res",
                "Autres feuillus"))))))))
  out[is.na(e)] <- NA_character_
  out
}

#' Essence dominante des placettes (surface terrière pondérée par W)
#'
#' Surface terrière à l'hectare de chaque essence = somme de `W * C13^2 / (4 pi)` sur les arbres
#' **vivants** (`VEGET` 0 ou 1) de chaque placette (`C13` : circonférence en m ; `W` :
#' coefficient d'extrapolation, 1 / surface du cercle de mesure en ha). Sans `W`, les petits
#' arbres, mesurés sur un cercle plus petit, seraient surpondérés. L'essence dominante est
#' celle de plus forte surface terrière ; la placette est **pure** si sa part atteint
#' `min_share` (75 % par défaut). L'essence est observée sur la placette (table ARBRE), non
#' extraite d'un raster : elle ne tombe pas sous la règle des 700 m.
#'
#' @param arbre `data.frame` de la table ARBRE : `id_placette`, `ESPAR`, `C13`, `W`, `VEGET`.
#' @param ids Identifiants de placettes à rendre, dans cet ordre (défaut : ceux de `arbre`).
#' @param min_share Part minimale de la surface terrière pour une placette pure.
#' @return Un `data.frame` : `id_placette`, `espar`, `share`, `g_ha` (m2/ha, tous arbres
#'   vivants), `pure` ; `NA` pour une placette sans arbre vivant mesuré.
#' @examples
#' a <- data.frame(id_placette = c("p", "p", "p"), ESPAR = c("09", "09", "61"),
#'                 C13 = c(1, 0.5, 0.4), W = c(14.1, 39.3, 88.4), VEGET = "0")
#' dominant_species(a)
#' @export
dominant_species <- function(arbre, ids = NULL, min_share = 0.75) {
  if (!is.data.frame(arbre) || !all(c("id_placette", "ESPAR", "C13", "W", "VEGET") %in% names(arbre))) {
    stop("`arbre` doit avoir les colonnes id_placette, ESPAR, C13, W, VEGET.", call. = FALSE)
  }
  if (!is.numeric(min_share) || length(min_share) != 1L || !is.finite(min_share) ||
      min_share <= 0 || min_share > 1) {
    stop("`min_share` doit \u00eatre un nombre dans ]0, 1].", call. = FALSE)
  }
  c13 <- suppressWarnings(as.numeric(arbre$C13))
  w <- suppressWarnings(as.numeric(arbre$W))
  ok <- as.character(arbre$VEGET) %in% c("0", "1") & !is.na(c13) & !is.na(w) &
    !is.na(arbre$ESPAR) & !is.na(arbre$id_placette)
  v <- data.frame(id = as.character(arbre$id_placette[ok]), esp = as.character(arbre$ESPAR[ok]),
                  g = w[ok] * c13[ok]^2 / (4 * pi), stringsAsFactors = FALSE)
  if (is.null(ids)) ids <- unique(as.character(arbre$id_placette))
  ids <- as.character(ids)
  vide <- data.frame(id_placette = ids, espar = NA_character_, share = NA_real_, g_ha = NA_real_,
                     pure = NA, stringsAsFactors = FALSE)
  if (!nrow(v)) return(vide)
  a <- tapply(v$g, list(v$id, v$esp), sum)
  a[is.na(a)] <- 0
  tot <- rowSums(a)
  i <- match(ids, rownames(a))
  out <- vide
  out$espar <- colnames(a)[max.col(a, ties.method = "first")][i]
  out$share <- (apply(a, 1, max) / tot)[i]
  out$g_ha <- tot[i]
  out$pure <- out$share >= min_share
  out
}

#' Table essence ESPAR -> CD_REF de l'IFN
#'
#' Lit `espar-cdref13.csv` (archive DataIFN) ou son extrait `ifn_espar_cdref.csv` : code d'essence
#' `espar`, libellé, `cd_ref` (TAXREF v13.0, comme la flore) et nom du taxon. Même lecture que
#' [read_tree_cd_ref()], qui n'en rend que les `CD_REF`.
#'
#' @param dir Dossier contenant `espar-cdref13.csv` ou `ifn_espar_cdref.csv`.
#' @return Un `data.frame` : `espar`, `lib_espar`, `cd_ref` (numérique), `lib_cdref`.
#' @examples
#' head(read_espar_cdref(system.file("extdata", package = "sylvostation")), 3)
#' @export
read_espar_cdref <- function(dir) {
  if (!is.character(dir) || length(dir) != 1L || !dir.exists(dir)) {
    stop("Dossier introuvable : ", paste(dir, collapse = ", "), call. = FALSE)
  }
  f <- .trouver_fichier_ifn(dir, "espar-cdref13")
  if (is.na(f)) f <- file.path(dir, "ifn_espar_cdref.csv")
  if (!file.exists(f)) stop("espar-cdref13.csv (ou ifn_espar_cdref.csv) introuvable dans ", dir, call. = FALSE)
  l <- readLines(f, encoding = "UTF-8", warn = FALSE)
  l[1] <- sub("^\ufeff?(// ?)?", "", l[1])
  d <- utils::read.delim(text = l, sep = ";", quote = "", colClasses = "character")
  if (!all(c("espar", "lib_espar", "cd_ref", "lib_cdref") %in% names(d))) {
    stop("Colonnes attendues : espar, lib_espar, cd_ref, lib_cdref.", call. = FALSE)
  }
  d <- d[, c("espar", "lib_espar", "cd_ref", "lib_cdref")]
  d$cd_ref <- suppressWarnings(as.numeric(d$cd_ref))
  d
}

#' Trophique observé sans les arbres
#'
#' Recalcule l'indice trophique des placettes (moyenne de la moyenne de `ph` et de la moyenne
#' d'`azote` des espèces de la flore, comme [compute_gradients()]) **sans les essences de
#' l'IFN** : les `CD_REF` de [read_tree_cd_ref()] (table `espar-cdref13.csv`, TAXREF v13, même
#' référentiel que la flore) sont retirés par jointure sur `CD_REF`. Sert de référence au contrôle
#' par essence : l'indice complet contient l'essence elle-même. La table des essences liste
#' les arbres et quelques arbustes de l'inventaire.
#'
#' @param flore `data.frame` de la flore IFN : `id_placette`, `CD_REF`.
#' @param indicateurs Valeurs indicatrices (`cd_ref`, `ph`, `azote`).
#' @param tree_cd_ref Vecteur de `CD_REF` des essences ([read_tree_cd_ref()]).
#' @param ids Identifiants de placettes à rendre, dans cet ordre.
#' @param min_taxa Nombre minimal d'espèces indicatrices restantes (3).
#' @return Un vecteur numérique aligné sur `ids` (`NA` sous `min_taxa`), attribut
#'   `n_taxons_arbres` (taxons de `indicateurs` retirés, comptés et jamais retirés en silence).
#' @examples
#' fl <- data.frame(id_placette = "p", CD_REF = 1:4)
#' ind <- data.frame(cd_ref = 1:4, ph = c(5.7, 3, 4, 5), azote = c(5, 4, 6, 5))
#' trophic_without_trees(fl, ind, tree_cd_ref = 1, ids = "p", min_taxa = 2)
#' @export
trophic_without_trees <- function(flore, indicateurs, tree_cd_ref, ids, min_taxa = 3) {
  if (!is.data.frame(flore) || !all(c("id_placette", "CD_REF") %in% names(flore))) {
    stop("`flore` doit avoir les colonnes id_placette et CD_REF.", call. = FALSE)
  }
  ind <- as.data.frame(indicateurs)
  if (!all(c("cd_ref", "ph", "azote") %in% names(ind))) {
    stop("`indicateurs` doit avoir les colonnes cd_ref, ph, azote.", call. = FALSE)
  }
  if (!is.numeric(tree_cd_ref)) stop("`tree_cd_ref` doit \u00eatre un vecteur de CD_REF.", call. = FALSE)
  arbre <- ind$cd_ref %in% tree_cd_ref
  j <- match(flore$CD_REF, ind$cd_ref)
  ok <- !is.na(j) & !arbre[j]
  ids <- as.character(ids)
  id <- factor(as.character(flore$id_placette[ok]), ids)
  moy <- function(v) as.numeric(tapply(v, id, mean, na.rm = TRUE))
  n <- as.integer(tapply(rep(1L, sum(ok)), id, sum))
  out <- rowMeans(cbind(moy(ind$ph[j[ok]]), moy(ind$azote[j[ok]])), na.rm = TRUE)
  out[is.nan(out)] <- NA_real_
  out[is.na(n) | n < min_taxa] <- NA_real_
  attr(out, "n_taxons_arbres") <- sum(arbre)
  out
}

#' Optimum trophique de Tichý des essences (repère indicatif)
#'
#' Pour chaque essence ESPAR, moyenne de `ph` et `azote` de l'espèce dans la table des valeurs
#' indicatrices (Tichý et al., celle qui sert au trophique), appariée par **`CD_REF`** grâce à
#' la table essence -> `CD_REF` de l'IFN ([read_espar_cdref()]). **Repère indicatif, jamais la
#' base d'une alerte** : la table décrit l'espèce, non la station forestière, et contredit les
#' placettes (hêtre 5,7 contre 4,2 observé sans les arbres). Les optimums forestiers publiés
#' (Rameau et al., *Flore forestière française* ; EcoPlant) sont **à vérifier, non lus**.
#'
#' @param espar Codes ESPAR.
#' @param indicateurs Valeurs indicatrices (`cd_ref`, `ph`, `azote`).
#' @param espar_cdref Résultat de [read_espar_cdref()].
#' @param codes Facultatif : résultat de [read_espar_codes()] (ajoute `latin_espar1`, nom latin
#'   de l'unité ESPAR1 des métadonnées, qui complète le nom du taxon de `espar_cdref`).
#' @return Un `data.frame` : `espar`, `nom` (libellé de l'essence), `latin` (nom du taxon),
#'   `cd_ref`, `optimum_tichy` (`NA` si l'espèce n'a ni `ph` ni `azote`, ou n'est pas dans la
#'   table), `n_lignes`, et `latin_espar1` si `codes` est fourni.
#' @examples
#' ind <- data.frame(cd_ref = 97947, ph = 5.7, azote = NA_real_)
#' species_optima(c("09", "64"), ind, read_espar_cdref(system.file("extdata",
#'                package = "sylvostation")))
#' @export
species_optima <- function(espar, indicateurs, espar_cdref, codes = NULL) {
  ind <- as.data.frame(indicateurs)
  if (!all(c("cd_ref", "ph", "azote") %in% names(ind))) {
    stop("`indicateurs` doit avoir les colonnes cd_ref, ph, azote.", call. = FALSE)
  }
  if (!all(c("espar", "lib_espar", "cd_ref", "lib_cdref") %in% names(espar_cdref))) {
    stop("`espar_cdref` doit venir de read_espar_cdref().", call. = FALSE)
  }
  esp <- unique(as.character(espar[!is.na(espar)]))
  # ARBRE note les essences sur deux caracteres (09) ; espar-cdref13.csv sans zero de tete (9)
  nz <- function(x) sub("^0+(?=.)", "", as.character(x), perl = TRUE)
  i <- match(nz(esp), nz(espar_cdref$espar))
  cd <- espar_cdref$cd_ref[i]
  v <- rowMeans(cbind(ind$ph, ind$azote), na.rm = TRUE)
  v[is.nan(v)] <- NA_real_
  res <- lapply(seq_along(esp), function(k) {
    r <- if (is.na(cd[k])) integer(0) else which(ind$cd_ref == cd[k])
    c(opt = if (length(r) && any(!is.na(v[r]))) mean(v[r], na.rm = TRUE) else NA_real_,
      n = length(r))
  })
  out <- data.frame(espar = esp, nom = espar_cdref$lib_espar[i], latin = espar_cdref$lib_cdref[i],
                    cd_ref = cd, optimum_tichy = vapply(res, `[`, 0, "opt"),
                    n_lignes = vapply(res, `[`, 0, "n"), stringsAsFactors = FALSE)
  if (!is.null(codes)) out$latin_espar1 <- codes$latin[match(esp, codes$code)]
  out
}

.sp <- function(a, b) {
  ok <- stats::complete.cases(a, b)
  if (sum(ok) < 3L || stats::sd(a[ok]) == 0 || stats::sd(b[ok]) == 0) return(NA_real_)
  stats::cor(a[ok], b[ok], method = "spearman")
}

# Resultat de spatial_cv(), ou element `trophic` d'une liste de resultats (une par gradient)
.cv_trophic <- function(x) {
  if (is.list(x) && !"predictions" %in% names(x) && "trophic" %in% names(x)) x <- x$trophic
  if (!is.list(x) || !all(c("predictions", "plis", "block_size") %in% names(x))) {
    stop("Chaque validation croisee doit venir de spatial_cv() (predictions, plis, block_size).",
         call. = FALSE)
  }
  x
}

#' Contrôle : trophique prédit hors pli contre essences en place
#'
#' Sur les placettes **pures**, compare le trophique prédit **hors pli** (prédictions de
#' [spatial_cv()] ; jamais celles de l'apprentissage) à la moyenne d'essence. Trois mesures :
#'
#' - **accord d'ordre** : Spearman entre le prédit et la moyenne d'essence **apprise hors pli**
#'   (trophique observé sans les arbres, plis d'apprentissage seuls), rapporté au même accord
#'   avec le trophique observé ; alerte si le ratio tombe sous `alerte_ratio` (non évaluée
#'   sous `min_placettes` placettes pures : trop peu pour juger) ;
#' - **écart par essence** (essences à au moins `min_placettes` placettes pures) : moyenne
#'   prédite moins moyenne observée ; alerte si `|écart| > alerte_ecart` ;
#' - **amplitude** : pente de la moyenne prédite sur la moyenne observée, par essence ; alerte
#'   sous `alerte_pente`.
#'
#' Les optimums de Tichý ([species_optima()]) ne servent que de repère (Spearman rendu, jamais
#' d'alerte). **Seuils : valeur provisoire, sans source, à vérifier.** Ce contrôle n'est pas une
#' validation indépendante : les essences sont corrélées au climat et à la roche que le modèle
#' voit ; l'accord d'ordre est un minimum de cohérence.
#'
#' @param train `data.frame` ou `sf` d'apprentissage : `id_placette`, `trophic` (même ordre que
#'   les prédictions).
#' @param cv Liste de résultats de [spatial_cv()] (un par taille de blocs) ou de listes par
#'   gradient (élément `trophic`). Un élément `NULL` est ignoré avec un avertissement.
#' @param dominant Résultat de [dominant_species()] (placettes de `train`).
#' @param optima Résultat de [species_optima()].
#' @param trophic_sans_arbres Résultat de [trophic_without_trees()], aligné sur `train`.
#' @param part_pure,min_placettes,alerte_ecart,alerte_ratio,alerte_pente Seuils (provisoires).
#' @return Une liste : `global` (une ligne par taille de blocs) et `par_essence`.
#' @examples
#' set.seed(1)
#' n <- 120
#' tr <- data.frame(id_placette = as.character(seq_len(n)), trophic = rnorm(n, 4))
#' dom <- data.frame(id_placette = tr$id_placette, espar = rep(c("09", "61", "52"), 40),
#'                   share = 0.9)
#' cv <- list(predictions = data.frame(observe = tr$trophic, predit = tr$trophic + rnorm(n)),
#'            plis = rep(1:4, 30), block_size = 5000)
#' opt <- data.frame(espar = c("09", "61", "52"), nom = c("a", "b", "c"), optimum_tichy = 4)
#' essence_control(tr, list(`5000` = cv), dom, opt, tr$trophic, min_placettes = 10)$global
#' @export
essence_control <- function(train, cv, dominant, optima, trophic_sans_arbres,
                            part_pure = 0.75, min_placettes = 15L, alerte_ecart = 0.5,
                            alerte_ratio = 0.5, alerte_pente = 0.2) {
  d <- if (inherits(train, "sf")) sf::st_drop_geometry(train) else as.data.frame(train)
  if (!all(c("id_placette", "trophic") %in% names(d))) {
    stop("`train` doit avoir les colonnes id_placette et trophic.", call. = FALSE)
  }
  n <- nrow(d)
  if (length(trophic_sans_arbres) != n) {
    stop("`trophic_sans_arbres` doit avoir la longueur de `train`.", call. = FALSE)
  }
  if (!is.list(cv) || !length(cv)) stop("`cv` doit \u00eatre une liste de validations.", call. = FALSE)
  # une validation absente (NULL, ou gradient sans resultat) n'arrete pas le controle : les
  # autres tailles de blocs sont calculees, et l'absence est signalee (jamais muette)
  vide <- vapply(cv, function(x) is.null(x) || (is.list(x) && "trophic" %in% names(x) &&
                                                   is.null(x$trophic) && !"predictions" %in% names(x)),
                 logical(1))
  if (any(vide)) {
    warning(sum(vide), " validation(s) crois\u00e9e(s) absente(s) sur ", length(cv),
            " : le contr\u00f4le est calcul\u00e9 sans elle(s) (taille de blocs omise).", call. = FALSE)
    cv <- cv[!vide]
  }
  if (!length(cv)) stop("Aucune validation crois\u00e9e disponible pour le contr\u00f4le.", call. = FALSE)
  dom <- dominant[match(as.character(d$id_placette), as.character(dominant$id_placette)), ]
  pure <- !is.na(dom$share) & dom$share >= part_pure
  esp <- dom$espar
  nm <- optima$nom[match(esp, optima$espar)]
  opt <- optima$optimum_tichy[match(esp, optima$espar)]
  glob <- list()
  par_e <- list()
  for (b in seq_along(cv)) {
    r <- .cv_trophic(cv[[b]])
    p <- r$predictions
    if (nrow(p) != n || max(abs(p$observe - d$trophic)) > 1e-8) {
      stop("Les pr\u00e9dictions hors pli ne sont pas align\u00e9es sur `train` (observ\u00e9 diff\u00e9rent) : ",
           "le contr\u00f4le n'accepte que les pr\u00e9dictions de spatial_cv().", call. = FALSE)
    }
    pred <- p$predit
    pli <- r$plis
    # moyenne d'essence apprise hors pli (trophique sans arbres, placettes pures des autres plis)
    appris <- rep(NA_real_, n)
    for (f in unique(pli)) {
      a <- which(pure & pli != f & !is.na(trophic_sans_arbres))
      m <- tapply(trophic_sans_arbres[a], esp[a], mean)
      te <- which(pure & pli == f)
      appris[te] <- as.numeric(m[esp[te]])
    }
    acc_p <- .sp(pred[pure], appris[pure])
    acc_o <- .sp(d$trophic[pure], appris[pure])
    ratio <- if (is.na(acc_p) || is.na(acc_o) || acc_o <= 0) NA_real_ else acc_p / acc_o
    tb <- table(esp[pure])
    gardees <- names(tb)[tb >= min_placettes]
    e <- do.call(rbind, lapply(gardees, function(x) {
      i <- which(pure & esp == x)
      data.frame(bloc_m = round(r$block_size), espar = x, nom = nm[i[1]], n = length(i),
                 observe_complet = mean(d$trophic[i]),
                 observe_sans_arbres = mean(trophic_sans_arbres[i], na.rm = TRUE),
                 predit_hors_pli = mean(pred[i]), optimum_tichy = opt[i[1]],
                 stringsAsFactors = FALSE)
    }))
    if (is.null(e)) {
      e <- data.frame(bloc_m = numeric(), espar = character(), nom = character(), n = integer(),
                      observe_complet = numeric(), observe_sans_arbres = numeric(),
                      predit_hors_pli = numeric(), optimum_tichy = numeric())
    }
    e$ecart <- e$predit_hors_pli - e$observe_complet
    e$alerte_ecart <- abs(e$ecart) > alerte_ecart
    pente <- if (nrow(e) >= 3L) unname(stats::coef(stats::lm(predit_hors_pli ~ observe_complet,
                                                             data = e))[2]) else NA_real_
    i_g <- which(pure & esp %in% gardees)
    r2 <- function(y) {
      ok <- !is.na(y[i_g])
      if (sum(ok) < 3L || length(unique(esp[i_g][ok])) < 2L) return(NA_real_)
      summary(stats::lm(y[i_g][ok] ~ esp[i_g][ok]))$r.squared
    }
    glob[[b]] <- data.frame(
      bloc_m = round(r$block_size), n_pures = sum(pure), n_essences = nrow(e),
      accord_predit = acc_p, accord_observe = acc_o, ratio = ratio,
      alerte_ordre = if (is.na(ratio) || sum(pure) < min_placettes) NA else ratio < alerte_ratio,
      pente_amplitude = pente,
      alerte_amplitude = if (is.na(pente)) NA else pente < alerte_pente,
      n_alertes_ecart = sum(e$alerte_ecart),
      tichy_placette = .sp(pred[pure], opt[pure]),
      tichy_essence = if (sum(!is.na(e$optimum_tichy)) >= 4L) .sp(e$predit_hors_pli, e$optimum_tichy) else NA_real_,
      tichy_essence_observe = if (sum(!is.na(e$optimum_tichy)) >= 4L) .sp(e$observe_complet, e$optimum_tichy) else NA_real_,
      r2_predit_essence = r2(pred), r2_sans_arbres_essence = r2(trophic_sans_arbres),
      seuil_ratio = alerte_ratio, seuil_ecart = alerte_ecart, seuil_pente = alerte_pente,
      part_pure = part_pure, min_placettes = min_placettes,
      statut_seuils = "valeur provisoire, sans source, \u00e0 v\u00e9rifier",
      stringsAsFactors = FALSE)
    par_e[[b]] <- e
  }
  list(global = do.call(rbind, glob), par_essence = do.call(rbind, par_e))
}

#' Modèle de sensibilité : le trophique avec l'essence dominante
#'
#' Refait la validation croisée spatiale du trophique du pipeline, **avec** l'essence dominante
#' en plus, pour chiffrer ce que le pipeline s'interdit (ADR 0008). L'essence est **encodée par
#' le trophique moyen de l'essence, refait dans chaque pli** à partir des seuls plis
#' d'apprentissage (comme la lithologie : [spatial_cv()], argument `encode`) ; la réponse du pli
#' de test n'intervient jamais. Trois variantes : essence fine (essences à au moins
#' `min_placettes` placettes pures, sinon `autre`) et groupes de la BD Forêt ([espar_group_tfv()]) ;
#' dans les deux, `mixte` (part sous `part_pure`) et `sans_arbre` ; et un **placebo** (niveaux de l'essence fine mélangés au hasard, graine fixe) : le gain de l'essence se lit moins celui du placebo. La base (sans essence) est
#' recalculée avec les mêmes plis. **Jamais un prédicteur de la carte, des types ni des
#' modèles** ; toute sortie porte la mention « ne pas lire comme la carte ». La variable
#' `coarse_essence_enc` vient de la table ARBRE de la placette (observée, non extraite d'un
#' raster) : le préfixe `coarse_` ne sert qu'à passer [assert_no_fine_extract_on_ifn()].
#'
#' @param train `sf` d'apprentissage du trophique (`trophic`, prédicteurs, colonnes encodées).
#' @param predictors Prédicteurs du modèle de base (`vars_modele$trophic`).
#' @param encode Encodages du modèle de base (liste de listes `var`, `name`, `k`, `oof`).
#' @param dominant Résultat de [dominant_species()] (placettes de `train`).
#' @param block_sizes Tailles de blocs (m) de la validation croisée.
#' @param part_pure,min_placettes Seuils (provisoires).
#' @param k Poids de la moyenne générale dans l'encodage de l'essence.
#' @param ifn_precision_m Précision des placettes IFN (700).
#' @param num_trees,seed,folds Transmis à [fit_gradient()] ; `folds` : nombre de plis (5).
#' @return Une liste : `resume` (`bloc_m`, `variante`, `r2`, `rmse`, `gain_r2`, `gain_rmse`,
#'   `avertissement`), `par_pli` (`bloc_m`, `variante`, `pli`, `n`, `r2`, `gain_r2`), `niveaux`
#'   (effectifs par niveau d'essence).
#' @examples
#' \donttest{
#' set.seed(1)
#' n <- 150
#' d <- sf::st_as_sf(data.frame(id_placette = as.character(seq_len(n)),
#'   x = runif(n, 1e6, 1.04e6), y = runif(n, 6.8e6, 6.84e6), loc_precision_m = 700,
#'   coarse_a = rnorm(n)), coords = c("x", "y"), crs = 2154, remove = FALSE)
#' dom <- data.frame(id_placette = d$id_placette, espar = rep(c("09", "61"), length.out = n),
#'                   share = 0.9)
#' d$trophic <- d$coarse_a + ifelse(dom$espar == "09", 1, -1) + rnorm(n, sd = 0.3)
#' essence_sensitivity(d, "coarse_a", NULL, dom, block_sizes = 10000, min_placettes = 10,
#'                     num_trees = 50)$resume
#' }
#' @export
essence_sensitivity <- function(train, predictors, encode = NULL, dominant, block_sizes,
                                part_pure = 0.75, min_placettes = 15L, k = 10,
                                ifn_precision_m = 700, num_trees = 500L, seed = 1, folds = 5L) {
  if (!inherits(train, "sf") || !"trophic" %in% names(train)) {
    stop("`train` doit \u00eatre un sf avec la colonne trophic.", call. = FALSE)
  }
  if (!is.numeric(block_sizes) || !length(block_sizes) || any(!is.finite(block_sizes)) ||
      any(block_sizes <= 0)) {
    stop("`block_sizes` doit contenir des tailles de blocs (m) > 0.", call. = FALSE)
  }
  dom <- dominant[match(as.character(train$id_placette), as.character(dominant$id_placette)), ]
  pure <- !is.na(dom$share) & dom$share >= part_pure
  tb <- table(dom$espar[pure])
  grands <- names(tb)[tb >= min_placettes]
  niveau <- function(x) ifelse(is.na(dom$share), "sans_arbre", ifelse(!pure, "mixte", x))
  train$essence_fine <- niveau(ifelse(dom$espar %in% grands, dom$espar, "autre"))
  train$essence_tfv <- niveau(espar_group_tfv(dom$espar))
  # placebo : les memes niveaux que l'essence fine, melanges au hasard (graine fixe) ; mesure ce
  # que le gain doit a la seule presence d'une variable de plus (regularisation), non a l'essence
  graine <- if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (is.null(graine)) rm(".Random.seed", envir = globalenv()) else
    assign(".Random.seed", graine, envir = globalenv()), add = TRUE)
  set.seed(seed)
  train$essence_placebo <- sample(train$essence_fine)
  var <- c(fine = "essence_fine", tfv = "essence_tfv", placebo = "essence_placebo")
  niveaux <- do.call(rbind, lapply(names(var), function(v) {
    t <- table(train[[var[[v]]]])
    data.frame(variante = v, niveau = names(t), n = as.integer(t), stringsAsFactors = FALSE)
  }))
  cv <- function(bs, extra = NULL) {
    spatial_cv(train, "trophic", c(predictors, if (!is.null(extra)) "coarse_essence_enc"),
               k = folds, points_source = "ifn", block_size = bs,
               ifn_precision_m = ifn_precision_m, num_trees = num_trees, seed = seed,
               encode = c(encode, if (!is.null(extra)) list(list(var = extra,
                 name = "coarse_essence_enc", k = k, oof = FALSE))))
  }
  resume <- list()
  par_pli <- list()
  for (bs in block_sizes) {
    # une taille de blocs impossible (trop peu de blocs pour les plis) est omise avec un
    # avertissement qui donne la raison ; les autres tailles sont calculees
    r <- tryCatch({
      base <- cv(bs)
      v <- lapply(names(var), function(nm) cv(bs, var[[nm]]))
      list(base = base, v = stats::setNames(v, names(var)))
    }, error = function(e) {
      warning("essence_sensitivity : taille de blocs ", format(round(bs), scientific = FALSE),
              " m omise : ",
              conditionMessage(e), call. = FALSE)
      NULL
    })
    if (is.null(r)) next
    base <- r$base
    resume[[length(resume) + 1L]] <- data.frame(bloc_m = round(bs), variante = "base",
      r2 = base$global[["r2"]], rmse = base$global[["rmse"]], gain_r2 = 0, gain_rmse = 0,
      stringsAsFactors = FALSE)
    for (nm in names(var)) {
      m <- r$v[[nm]]
      resume[[length(resume) + 1L]] <- data.frame(bloc_m = round(bs), variante = nm,
        r2 = m$global[["r2"]], rmse = m$global[["rmse"]],
        gain_r2 = m$global[["r2"]] - base$global[["r2"]],
        gain_rmse = m$global[["rmse"]] - base$global[["rmse"]], stringsAsFactors = FALSE)
      par_pli[[length(par_pli) + 1L]] <- data.frame(bloc_m = round(bs), variante = nm,
        pli = m$par_pli$pli, n = m$par_pli$n, r2 = m$par_pli$r2,
        gain_r2 = m$par_pli$r2 - base$par_pli$r2, stringsAsFactors = FALSE)
    }
  }
  if (!length(resume)) {
    stop("Aucune taille de blocs n'a pu \u00eatre calcul\u00e9e (voir les avertissements).", call. = FALSE)
  }
  resume <- do.call(rbind, resume)
  resume$avertissement <- .AVERT_SENSIBILITE
  par_pli <- do.call(rbind, par_pli)
  par_pli$avertissement <- .AVERT_SENSIBILITE
  list(resume = resume, par_pli = par_pli, niveaux = niveaux)
}

#' Tables publiables du contrôle par essence et de la sensibilité
#'
#' Met en forme les résultats pour `write_outputs()` : trois tables, dont la première
#' (`controle_essence`) place **en tête le défaut d'amplitude** (pente prévu contre observé par
#' essence : les prédictions hors pli sont écrasées vers la moyenne).
#'
#' @param controle Résultat de [essence_control()], ou `NULL` (table omise).
#' @param sensibilite Résultat de [essence_sensitivity()], ou `NULL` (table omise) : le contrôle
#'   est publié même sans la sensibilité.
#' @return Une liste nommée de `data.frame` : `controle_essence`, `controle_essence_par_essence`,
#'   `sensibilite_essence`.
#' @examples
#' sens <- list(resume = data.frame(bloc_m = 1, variante = "base", r2 = 0.2, rmse = 1,
#'                                  gain_r2 = 0, gain_rmse = 0, avertissement = "x"),
#'               par_pli = data.frame(bloc_m = 1, variante = "tfv", pli = 1L, n = 10L, r2 = 0.2,
#'                                    gain_r2 = 0.05, avertissement = "x"))
#' ctl <- list(global = data.frame(pente_amplitude = 0.3, bloc_m = 1), par_essence = data.frame(a = 1))
#' names(essence_tables(ctl, sens))
#' @export
essence_tables <- function(controle = NULL, sensibilite = NULL) {
  out <- list()
  if (!is.null(controle)) {
    g <- controle$global
    tete <- c("bloc_m", "pente_amplitude", "alerte_amplitude")
    g <- g[, c(intersect(tete, names(g)), setdiff(names(g), tete)), drop = FALSE]
    out$controle_essence <- g
    out$controle_essence_par_essence <- controle$par_essence
  }
  if (!is.null(sensibilite)) {
    s <- sensibilite$resume
    p <- sensibilite$par_pli
    s$pli <- NA_integer_
    s$n <- NA_integer_
    p$rmse <- NA_real_
    p$gain_rmse <- NA_real_
    cols <- c("bloc_m", "variante", "pli", "n", "r2", "rmse", "gain_r2", "gain_rmse",
              "avertissement")
    out$sensibilite_essence <- rbind(s[, cols], p[, cols])
  }
  out
}

#' Télécharger la BD Forêt v2 (formation végétale) sur une emprise
#'
#' Lit la couche WFS `LANDCOVER.FORESTINVENTORY.V2:formation_vegetale` de la Géoplateforme
#' (`docs/referentiels.md`, § 4), par pages de 5 000 entités, en EPSG:2154, et la met en cache.
#' **Licence contradictoire** (Licence Ouverte pour data.gouv.fr, « conditions générales
#' d'utilisation IGN » dans les métadonnées livrées : § 33.5 bis et § 36) : le cache reste dans
#' `data/` (hors dépôt) et rien n'en est publié, hors moyennes par classe.
#'
#' @param bbox Emprise : `bbox` de `sf` en EPSG:2154.
#' @param cache_dir Dossier du cache.
#' @return Un `sf` (EPSG:2154) avec `code_tfv`, `tfv`, `essence`.
#' @examples
#' \dontrun{
#' fetch_bdforet(sf::st_bbox(c(xmin = 1007000, ymin = 6790000, xmax = 1022000, ymax = 6805000),
#'                           crs = 2154), tempdir())
#' }
#' @export
fetch_bdforet <- function(bbox, cache_dir = file.path("data", "cache", "bdforet")) {
  assert_crs_2154(sf::st_as_sfc(sf::st_bbox(bbox)))
  b <- as.numeric(sf::st_bbox(bbox)[c("xmin", "ymin", "xmax", "ymax")])
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  base <- paste0("https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature",
                 "&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale&SRSNAME=EPSG:2154",
                 "&BBOX=", paste(format(b, scientific = FALSE, trim = TRUE), collapse = ","), ",EPSG:2154",
                 "&OUTPUTFORMAT=application/json&COUNT=5000")
  pages <- list()
  debut <- 0L
  repeat {
    f <- file.path(cache_dir, sprintf("bdforet_%s_%d.json", paste(format(round(b), scientific = FALSE, trim = TRUE),
                                                           collapse = "_"), debut))
    if (!file.exists(f) || file.size(f) == 0) {
      tmp <- paste0(f, ".part")
      .download_retry(paste0(base, "&STARTINDEX=", debut), tmp)
      file.rename(tmp, f)
    }
    x <- sf::st_read(f, quiet = TRUE)
    if (!nrow(x)) break
    pages[[length(pages) + 1L]] <- x[, c("code_tfv", "tfv", "essence")]
    if (nrow(x) < 5000L) break
    debut <- debut + 5000L
  }
  out <- do.call(rbind, pages)
  sf::st_crs(out) <- 2154
  out
}

#' Moyennes du trophique de la carte par classe de peuplement pur (BD Forêt)
#'
#' Pour chaque classe de peuplement **pur** de la BD Forêt v2 (hêtre, chênes décidus, sapin ou
#' épicéa, etc.), moyenne du trophique de la carte à l'**intérieur** des polygones (tampon
#' intérieur de `buffer_m`, provisoire, sans source : marge de lisière et d'écart de position),
#' moyenne des moyennes par polygone, et nombre de polygones. Comparaison de **lecture**, pas une
#' validation : la carte n'a pas vu l'essence, mais le modèle a été entraîné sur des placettes
#' dont l'essence est corrélée au climat et à la roche. Seules des moyennes par classe sont
#' rendues (aucune géométrie).
#'
#' @param forest `sf` BD Forêt (EPSG:2154) avec `code_tfv`.
#' @param trophic `SpatRaster` du trophique (EPSG:2154).
#' @param buffer_m Tampon intérieur (m).
#' @param min_polygones Polygones minimaux pour que la classe soit jugée.
#' @return Un `data.frame` : `classe`, `n_polygones`, `n_cellules`, `moyenne_carte`,
#'   `ecart_type_polygones`, `suffisant`.
#' @examples
#' p <- sf::st_sf(code_tfv = "FF1-09-09", geometry = sf::st_sfc(sf::st_polygon(list(
#'   rbind(c(1e6, 6.8e6), c(1e6 + 400, 6.8e6), c(1e6 + 400, 6.8e6 + 400), c(1e6, 6.8e6 + 400),
#'         c(1e6, 6.8e6)))), crs = 2154))
#' r <- terra::rast(xmin = 1e6, xmax = 1e6 + 400, ymin = 6.8e6, ymax = 6.8e6 + 400,
#'                  resolution = 20, crs = "EPSG:2154", vals = 4.5)
#' bdforet_class_means(p, r, buffer_m = 50, min_polygones = 1)
#' @export
bdforet_class_means <- function(forest, trophic, buffer_m = 50, min_polygones = 5L) {
  if (!inherits(forest, "sf") || !"code_tfv" %in% names(forest)) {
    stop("`forest` doit \u00eatre un sf avec la colonne code_tfv.", call. = FALSE)
  }
  assert_crs_2154(forest)
  assert_crs_2154(trophic)
  p <- forest[forest$code_tfv %in% names(.BDFORET_PUR), ]
  vide <- data.frame(classe = character(), n_polygones = integer(), n_cellules = integer(),
                     moyenne_carte = numeric(), ecart_type_polygones = numeric(),
                     suffisant = logical(), stringsAsFactors = FALSE)
  if (!nrow(p)) return(vide)
  p$classe <- unname(.BDFORET_PUR[p$code_tfv])
  p <- suppressWarnings(sf::st_buffer(p, -buffer_m))
  p <- p[!sf::st_is_empty(p), ]
  if (!nrow(p)) return(vide)
  v <- terra::extract(trophic[[1]], terra::vect(p), ID = TRUE)
  names(v)[2] <- "tro"
  v <- v[!is.na(v$tro), ]
  if (!nrow(v)) return(vide)
  v$classe <- p$classe[v$ID]
  pm <- stats::aggregate(tro ~ ID + classe, v, mean)
  nc <- table(v$classe)
  out <- do.call(rbind, lapply(split(pm, pm$classe), function(z) {
    data.frame(classe = z$classe[1], n_polygones = nrow(z), n_cellules = as.integer(nc[[z$classe[1]]]),
               moyenne_carte = mean(z$tro),
               ecart_type_polygones = if (nrow(z) > 1L) stats::sd(z$tro) else NA_real_,
               suffisant = nrow(z) >= min_polygones, stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}
