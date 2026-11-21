# Validation statistique et thematique (mission 010, brief technique § 4 etape 9, § 9).
# Aucun reseau, aucun effet de bord.

# Reperes publies (brief technique § 4 etape 9 et § 9, Vosges, Gegout et al. 2008) :
# R2 = 0,36 trophique, 0,52 bioclimat, 0,43 reserve utile. La correspondance
# « reserve utile -> gradient hydrique » est une lecture du brief (le gradient hydrique
# etant etabli a partir de la reserve utile) : a confirmer avec Pascal.
.REPERES_R2 <- c(trophic = 0.36, bioclim = 0.52, hydric = 0.43)

#' R² et RMSE par gradient, comparés aux repères publiés
#'
#' Réunit les résultats de [spatial_cv()] de chaque gradient. Les repères sont ceux du
#' brief technique (étape 9 et § 9) : R² de 0,36 (trophique), 0,52 (bioclimat) et 0,43
#' (réserve utile, associée ici au gradient hydrique : lecture à confirmer). Un gradient
#' dont le nom n'est pas `trophic`, `bioclim` ou `hydric` n'a pas de repère (`NA`).
#' Le R² est celui de la validation croisée **spatiale par blocs** (jamais un tirage
#' aléatoire simple). Un R² supérieur au repère sur des données synthétiques ne prouve
#' rien : l'attribut `synthetic` le rappelle.
#'
#' @param cv_results Liste **nommée** (un élément par gradient) de résultats de
#'   [spatial_cv()].
#' @param reperes Vecteur nommé des repères de R² (défaut : ceux du brief).
#' @param synthetic `TRUE` si les données sont synthétiques (balise reprise en attribut
#'   et en colonne).
#' @param min_blocs_par_pli Nombre minimal de blocs occupés **par pli** pour que le R² soit
#'   interprétable (4 par défaut ; **valeur provisoire, à vérifier**, `cv_min_blocs_par_pli`
#'   de config.yml). Un R² calculé avec moins de `min_blocs_par_pli * k` blocs dépend de
#'   quelques blocs seulement.
#' @return Un `data.frame` : `gradient`, `n`, `r2`, `rmse`, `r2_repere`,
#'   `ecart_r2` (R² moins repère), `atteint` (R² >= repère ; `NA` sans repère),
#'   `block_size`, `blocs` (blocs occupés, `NA` si plis fournis), `k`, `blocs_insuffisants`
#'   (`TRUE` si `blocs < min_blocs_par_pli * k`), `alerte` (texte en clair, vide sinon),
#'   `synthetic`.
#' @examples
#' set.seed(1)
#' d <- data.frame(x = runif(100, 1007000, 1012000), y = runif(100, 6790000, 6795000),
#'                 loc_precision_m = 10, coarse_a = rnorm(100))
#' d$g <- d$coarse_a + rnorm(100, sd = 0.3)
#' if (requireNamespace("mgcv", quietly = TRUE)) {
#'   cv <- spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 1000)
#'   validate_stats(list(trophic = cv), synthetic = TRUE)
#' }
#' @export
validate_stats <- function(cv_results, reperes = .REPERES_R2, synthetic = FALSE,
                           min_blocs_par_pli = 4) {
  if (!is.numeric(min_blocs_par_pli) || length(min_blocs_par_pli) != 1L ||
      !is.finite(min_blocs_par_pli) || min_blocs_par_pli < 0) {
    stop("`min_blocs_par_pli` doit \u00eatre un nombre >= 0.", call. = FALSE)
  }
  if (!is.list(cv_results) || !length(cv_results) || is.null(names(cv_results)) ||
      any(!nzchar(names(cv_results)))) {
    stop("`cv_results` doit \u00eatre une liste nomm\u00e9e de r\u00e9sultats de spatial_cv().",
         call. = FALSE)
  }
  lignes <- lapply(names(cv_results), function(nm) {
    cv <- cv_results[[nm]]
    if (!is.list(cv) || is.null(cv$global) || is.null(cv$predictions)) {
      stop("`cv_results$", nm, "` ne vient pas de spatial_cv().", call. = FALSE)
    }
    rep <- if (nm %in% names(reperes)) unname(reperes[[nm]]) else NA_real_
    r2 <- unname(cv$global[["r2"]])
    blocs <- if (is.null(cv$n_blocs)) NA_integer_ else as.integer(cv$n_blocs)
    k <- if (is.null(cv$k)) NA_integer_ else as.integer(cv$k)
    insuf <- if (is.na(blocs) || is.na(k)) NA else blocs < min_blocs_par_pli * k
    alerte <- if (isTRUE(insuf)) {
      paste0("R\u00b2 peu interpr\u00e9table : ", blocs, " blocs pour ", k,
             " plis ; voir la ligne de sensibilit\u00e9")
    } else ""
    data.frame(gradient = nm, n = sum(is.finite(cv$predictions$predit)),
               r2 = r2, rmse = unname(cv$global[["rmse"]]),
               r2_repere = rep, ecart_r2 = r2 - rep, atteint = r2 >= rep,
               block_size = cv$block_size, blocs = blocs, k = k,
               blocs_insuffisants = insuf, alerte = alerte, synthetic = isTRUE(synthetic),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, lignes)
  rownames(out) <- NULL
  attr(out, "synthetic") <- isTRUE(synthetic)
  out
}

#' Table de validation du pipeline : chiffre principal, sensibilité à blocs fixes, local
#'
#' Réunit [validate_stats()] des gradients (blocs de portée estimée, le chiffre publié), une
#' ligne « `<gradient>` (sensibilité : blocs de taille fixe) » pour chaque gradient dont la
#' sensibilité est fournie, et la ligne du modèle local (ancrages GBIF) si elle existe. Un
#' résultat `NULL` est omis. L'alerte `blocs_insuffisants` s'applique à chaque ligne.
#'
#' @param cvs Liste nommée de [spatial_cv()] (un élément par gradient).
#' @param sensibilite Liste nommée de [spatial_cv()] à blocs fixes (éléments `NULL` omis) ou
#'   `NULL`.
#' @param local `NULL` ou résultat de [spatial_cv()] du modèle local (trophique, GBIF).
#' @param min_blocs_par_pli Voir [validate_stats()].
#' @param synthetic Voir [validate_stats()].
#' @return Un `data.frame` (colonnes de [validate_stats()]).
#' @examples
#' set.seed(1)
#' d <- data.frame(x = runif(100, 1007000, 1012000), y = runif(100, 6790000, 6795000),
#'                 loc_precision_m = 10, coarse_a = rnorm(100))
#' d$g <- d$coarse_a + rnorm(100, sd = 0.3)
#' if (requireNamespace("mgcv", quietly = TRUE)) {
#'   cv <- spatial_cv(d, "g", "coarse_a", method = "gam", block_size = 1000)
#'   validation_table(list(trophic = cv), list(trophic = cv), synthetic = TRUE)
#' }
#' @export
validation_table <- function(cvs, sensibilite = NULL, local = NULL, min_blocs_par_pli = 4,
                             synthetic = FALSE) {
  v <- validate_stats(cvs, synthetic = synthetic, min_blocs_par_pli = min_blocs_par_pli)
  for (g in names(sensibilite)) {
    if (is.null(sensibilite[[g]])) next
    s <- validate_stats(stats::setNames(list(sensibilite[[g]]), g), synthetic = synthetic,
                        min_blocs_par_pli = min_blocs_par_pli)
    s$gradient <- paste0(g, " (sensibilit\u00e9 : blocs de taille fixe)")
    v <- rbind(v, s)
  }
  if (!is.null(local)) {
    l <- validate_stats(list(trophic = local), synthetic = synthetic,
                        min_blocs_par_pli = min_blocs_par_pli)
    l$gradient <- "trophic (local, ancrages GBIF)"
    v <- rbind(v, l)
  }
  attr(v, "synthetic") <- isTRUE(synthetic)
  v
}

# Axes (classes) d'un type : chaine de chiffres (« 412 » -> 4, 1, 2) ou suites
# d'entiers separees par un non-chiffre (« T2-H1-B1 » -> 2, 1, 1). Matrice n x axes.
.type_axes <- function(x) {
  x <- as.character(x)
  chiffres <- !is.na(x) & grepl("^[0-9]+$", x)
  if (any(!is.na(x)) && all(chiffres[!is.na(x)])) {
    parts <- strsplit(x, "")
  } else {
    parts <- regmatches(x, gregexpr("[0-9]+", x))
  }
  len <- vapply(parts, length, integer(1))
  len[is.na(x)] <- NA_integer_
  k <- unique(len[!is.na(len)])
  if (length(k) != 1L || k < 1L) return(NULL)
  m <- t(vapply(seq_along(parts), function(i) {
    if (is.na(x[i])) rep(NA_real_, k) else as.numeric(parts[[i]])
  }, numeric(k)))
  if (k == 1L) m <- matrix(m, ncol = 1L)
  m
}

.kappa <- function(obs, pred) {
  niv <- sort(unique(c(obs, pred)))
  tab <- table(factor(obs, niv), factor(pred, niv))
  n <- sum(tab)
  if (n == 0) return(NA_real_)
  po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (isTRUE(all.equal(pe, 1))) return(NA_real_)
  (po - pe) / (1 - pe)
}

#' Accord thématique entre types prédits et types de terrain
#'
#' Compare des types prédits à des types observés (relevés GNSS, cartes de stations
#' levées) : matrice de confusion, kappa de Cohen, accord exact et **accord à une
#' classe près**. Les types sont des codes dont les axes (classes) sont lus dans la
#' chaîne : « 412 » (code à trois chiffres de la référence, un chiffre par axe) ou
#' « T2-H1-B1 » (nombres successifs). L'accord à une classe près suppose des classes
#' **ordonnées** par axe ; il vaut `NA` si les axes ne sont pas lisibles ou ne sont pas
#' en même nombre partout. Les paires avec `NA` sont écartées et comptées.
#'
#' @param pred_types Types prédits (vecteur).
#' @param field_types Types observés (même longueur).
#' @return Une liste : `confusion` (table, lignes = observé, colonnes = prédit),
#'   `kappa`, `accord_exact`, `accord_une_classe` (tous les axes à au plus une
#'   classe), `par_axe` (`axe`, `accord_exact`, `accord_une_classe`, `kappa`), `n`,
#'   `n_ecartes`.
#' @examples
#' pred <- c("T1-H1", "T2-H1", "T2-H2", "T1-H2")
#' field <- c("T1-H1", "T2-H2", "T2-H2", "T1-H1")
#' validate_maps(pred, field)$accord_exact
#' @export
validate_maps <- function(pred_types, field_types) {
  if (length(pred_types) != length(field_types)) {
    stop("`pred_types` et `field_types` doivent avoir la m\u00eame longueur.", call. = FALSE)
  }
  p <- as.character(pred_types)
  o <- as.character(field_types)
  ok <- !is.na(p) & !is.na(o)
  if (!any(ok)) stop("Aucune paire de types comparable.", call. = FALSE)
  p <- p[ok]
  o <- o[ok]
  niv <- sort(unique(c(o, p)))
  conf <- table(observe = factor(o, niv), predit = factor(p, niv))
  ap <- .type_axes(p)
  ao <- .type_axes(o)
  par_axe <- NULL
  une_classe <- NA_real_
  if (!is.null(ap) && !is.null(ao) && ncol(ap) == ncol(ao)) {
    d <- abs(ap - ao)
    une_classe <- mean(rowSums(d > 1) == 0)
    par_axe <- data.frame(axe = seq_len(ncol(ap)),
                          accord_exact = colMeans(d == 0),
                          accord_une_classe = colMeans(d <= 1),
                          kappa = vapply(seq_len(ncol(ap)), function(j) .kappa(ao[, j], ap[, j]),
                                         numeric(1)))
  }
  list(confusion = conf, kappa = .kappa(o, p), accord_exact = mean(o == p),
       accord_une_classe = une_classe, par_axe = par_axe, n = length(p),
       n_ecartes = sum(!ok))
}
