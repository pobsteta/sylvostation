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
#' @return Un `data.frame` : `gradient`, `n`, `r2`, `rmse`, `r2_repere`,
#'   `ecart_r2` (R² moins repère), `atteint` (R² >= repère ; `NA` sans repère),
#'   `block_size`, `synthetic`.
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
validate_stats <- function(cv_results, reperes = .REPERES_R2, synthetic = FALSE) {
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
    data.frame(gradient = nm, n = sum(is.finite(cv$predictions$predit)),
               r2 = r2, rmse = unname(cv$global[["rmse"]]),
               r2_repere = rep, ecart_r2 = r2 - rep, atteint = r2 >= rep,
               block_size = cv$block_size, synthetic = isTRUE(synthetic),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, lignes)
  rownames(out) <- NULL
  attr(out, "synthetic") <- isTRUE(synthetic)
  out
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
#' validate_maps(c("T1-H1", "T2-H1", "T2-H2", "T1-H2"), c("T1-H1", "T2-H2", "T2-H2", "T1-H1"))$accord_exact
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
