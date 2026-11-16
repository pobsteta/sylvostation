# Caractérisation des types : espèces indicatrices et fertilité (mission 009,
# brief technique § 4 étape 7). Aucun réseau, aucun effet de bord.
# Les noms des colonnes des fichiers bruts de l'IFN (FLORE, ARBRE) ne sont pas
# vérifiés dans docs/referentiels.md : les colonnes sont donc des arguments
# (à vérifier au moment de brancher les données réelles, mission placettes).

#' Espèces indicatrices par type (IndVal)
#'
#' Calcule l'indice de valeur indicatrice de Dufrêne et Legendre, dans sa version
#' **équilibrée entre groupes** (`IndVal.g` de `indicspecies`) : pour une espèce et
#' un type, \eqn{A} = abondance moyenne dans le type rapportée à la somme des
#' abondances moyennes de tous les types (spécificité), \eqn{B} = part des relevés du
#' type où l'espèce est présente (fidélité), `indval` = \eqn{\sqrt{A B}}. Chaque
#' espèce est attribuée au type où son indice est maximal. Le calcul est direct (sans
#' dépendance) ; le test vérifie qu'il coïncide avec `indicspecies::multipatt()`.
#' La p-valeur vient de permutations des types entre relevés (non ajustée pour les
#' tests multiples).
#'
#' @param flore Matrice ou tableau relevés (lignes) x espèces (colonnes), présence
#'   (0/1) ou abondance (>= 0).
#' @param types Type de chaque relevé (vecteur de la longueur du nombre de lignes).
#' @param nperm Nombre de permutations (199 par défaut ; 0 : pas de p-valeur).
#' @param seed Graine des permutations.
#' @return Un `data.frame` trié par type puis indice décroissant : `species`, `type`,
#'   `A`, `B`, `indval`, `p_value`. Les espèces absentes de tous les relevés sont
#'   omises. Les relevés sans type sont écartés.
#' @examples
#' set.seed(1)
#' fl <- matrix(rbinom(60 * 5, 1, 0.4), 60, 5, dimnames = list(NULL, paste0("sp", 1:5)))
#' fl[1:30, 1] <- 1
#' head(indicator_species(fl, rep(c("a", "b"), each = 30), nperm = 49))
#' @export
indicator_species <- function(flore, types, nperm = 199L, seed = 1L) {
  m <- as.matrix(flore)
  if (!is.numeric(m) && !is.logical(m)) stop("`flore` doit \u00eatre num\u00e9rique.", call. = FALSE)
  m <- m + 0
  if (anyNA(m) || any(m < 0)) stop("`flore` : valeurs >= 0 et sans NA attendues.", call. = FALSE)
  if (length(types) != nrow(m)) {
    stop("`types` doit avoir une valeur par relev\u00e9 (ligne de `flore`).", call. = FALSE)
  }
  if (is.null(colnames(m))) colnames(m) <- paste0("sp", seq_len(ncol(m)))
  ok <- !is.na(types)
  m <- m[ok, , drop = FALSE]
  tp <- factor(as.character(types[ok]))
  if (nlevels(tp) < 2L) stop("Au moins deux types sont n\u00e9cessaires.", call. = FALSE)
  if (any(table(tp) < 1L)) stop("Type sans relev\u00e9.", call. = FALSE)

  indval <- function(grp) {
    g <- factor(grp, levels = levels(tp))
    ab <- rowsum(m, g)[levels(tp), , drop = FALSE]
    nj <- as.vector(table(g))
    pres <- rowsum((m > 0) + 0, g)[levels(tp), , drop = FALSE]
    mean_ab <- ab / nj
    tot <- colSums(mean_ab)
    A <- sweep(mean_ab, 2, ifelse(tot > 0, tot, NA_real_), "/")
    B <- pres / nj
    sqrt(A * B)
  }
  iv <- indval(tp)
  best <- apply(iv, 2, function(v) if (all(is.na(v))) NA_integer_ else which.max(v))
  keep <- !is.na(best)
  esp <- colnames(m)[keep]
  best <- best[keep]
  stat <- iv[cbind(best, which(keep))]
  # A et B du type retenu
  tot <- colSums(rowsum(m, tp) / as.vector(table(tp)))
  A <- (rowsum(m, tp) / as.vector(table(tp)))[cbind(best, which(keep))] / tot[keep]
  B <- (rowsum((m > 0) + 0, tp) / as.vector(table(tp)))[cbind(best, which(keep))]

  p <- rep(NA_real_, length(esp))
  if (nperm > 0L) {
    if (exists(".Random.seed", envir = globalenv())) {
      old <- get(".Random.seed", envir = globalenv())
      on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    }
    set.seed(seed)
    sup <- rep(0L, length(esp))
    for (i in seq_len(nperm)) {
      s <- apply(indval(sample(tp))[, keep, drop = FALSE], 2, max)
      sup <- sup + (s >= stat - 1e-12)
    }
    p <- (1 + sup) / (1 + nperm)
  }
  out <- data.frame(species = esp, type = levels(tp)[best], A = A, B = B,
                    indval = stat, p_value = p, stringsAsFactors = FALSE)
  out <- out[order(out$type, -out$indval), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Fertilité observée par essence et par type
#'
#' Hauteur dominante à un âge de référence (indice de fertilité), par essence et par
#' type, sur les placettes dont les hauteurs et âges sont **mesurés** (IFN ; la
#' hauteur LiDAR ne peut pas être rattachée à ces placettes). Méthode simple et
#' **provisoire**, à valider avec un sylviculteur :
#' \enumerate{
#'   \item par placette et essence, hauteur dominante = moyenne des `n_dom` arbres
#'   les plus hauts, âge = moyenne de leurs âges ;
#'   \item par essence, courbe guide `h = a + b ln(âge)` ajustée sur toutes les
#'   placettes (au moins `n_min_guide` placettes et un âge variable, sinon `NA`) ;
#'   \item indice de fertilité de la placette = `h + b (ln(age_ref) - ln(âge))`
#'   (courbe guide translatée par l'observation), puis résumé par type.
#' }
#' Les noms de colonnes de l'IFN n'étant pas vérifiés, ils sont passés en argument
#' (à vérifier). L'âge de référence par défaut (50 ans) est provisoire.
#'
#' @param arbres Tableau d'arbres : placette, essence, hauteur (m), âge (ans).
#' @param types Type de chaque placette : tableau avec les colonnes `plot` (même nom
#'   que dans `arbres`) et `type`, ou vecteur de types nommé par identifiant de
#'   placette.
#' @param cols Noms des colonnes de `arbres`, vecteur nommé `plot`, `species`,
#'   `height`, `age`.
#' @param age_ref Âge de référence en années : un nombre, ou un vecteur nommé par
#'   essence (défaut provisoire : 50).
#' @param n_dom Nombre d'arbres dominants par placette et essence (3, provisoire).
#' @param n_min_guide Nombre minimal de placettes pour ajuster la courbe guide (10).
#' @return Un `data.frame` par essence x type : `species`, `type`, `n_plots`,
#'   `fertilite_moy`, `fertilite_med`, `fertilite_sd`, `age_ref`. Attributs :
#'   `plots` (indice par placette), `guide` (coefficients par essence), `provisoire =
#'   TRUE`.
#' @examples
#' set.seed(1)
#' ar <- data.frame(plot = rep(1:30, each = 4), species = "chene",
#'                  age = rep(runif(30, 30, 120), each = 4), height = NA)
#' ar$height <- 8 * log(ar$age) - 10 + rep(rnorm(30, sd = 2), each = 4) + rnorm(120, sd = 0.5)
#' ty <- data.frame(plot = 1:30, type = rep(c("a", "b"), 15))
#' fertility_by_type(ar, ty)
#' @export
fertility_by_type <- function(arbres, types,
                              cols = c(plot = "plot", species = "species",
                                       height = "height", age = "age"),
                              age_ref = 50, n_dom = 3L, n_min_guide = 10L) {
  if (!is.data.frame(arbres)) stop("`arbres` doit \u00eatre un tableau.", call. = FALSE)
  if (!all(c("plot", "species", "height", "age") %in% names(cols)) ||
      !all(cols %in% names(arbres))) {
    stop("`cols` doit nommer plot, species, height, age, colonnes pr\u00e9sentes dans `arbres`.",
         call. = FALSE)
  }
  if (is.data.frame(types)) {
    if (!all(c(cols[["plot"]], "type") %in% names(types))) {
      stop("`types` doit avoir les colonnes `", cols[["plot"]], "` et `type`.", call. = FALSE)
    }
    tmap <- stats::setNames(as.character(types$type), as.character(types[[cols[["plot"]]]]))
  } else {
    if (is.null(names(types))) stop("`types` doit \u00eatre nomm\u00e9 par placette.", call. = FALSE)
    tmap <- stats::setNames(as.character(types), names(types))
  }
  a <- data.frame(plot = as.character(arbres[[cols[["plot"]]]]),
                  species = as.character(arbres[[cols[["species"]]]]),
                  height = as.numeric(arbres[[cols[["height"]]]]),
                  age = as.numeric(arbres[[cols[["age"]]]]), stringsAsFactors = FALSE)
  a <- a[stats::complete.cases(a) & a$height > 0 & a$age > 0, , drop = FALSE]
  if (!nrow(a)) stop("Aucun arbre avec hauteur et \u00e2ge valides.", call. = FALSE)

  # 1. dominants par placette x essence
  a <- a[order(a$plot, a$species, -a$height), , drop = FALSE]
  cle <- paste(a$plot, a$species, sep = "\r")
  rang <- stats::ave(seq_along(cle), cle, FUN = seq_along)
  dom <- a[rang <= n_dom, , drop = FALSE]
  pl <- stats::aggregate(cbind(hdom = height, age = age) ~ plot + species, data = dom,
                         FUN = mean)
  pl$type <- unname(tmap[pl$plot])

  # 2. courbe guide par essence, 3. indice
  pl$fertilite <- NA_real_
  pl$age_ref <- NA_real_
  guide <- list()
  for (sp in unique(pl$species)) {
    i <- pl$species == sp
    ar <- if (length(age_ref) > 1L || !is.null(names(age_ref))) age_ref[[sp]] else age_ref
    if (is.null(ar) || is.na(ar)) ar <- NA_real_
    d <- pl[i, , drop = FALSE]
    pente <- NA_real_
    if (nrow(d) >= n_min_guide && stats::sd(log(d$age)) > 0) {
      f <- stats::lm(hdom ~ log(age), data = d)
      pente <- unname(stats::coef(f)[2])
      guide[[sp]] <- stats::coef(f)
      if (!is.na(pente) && pente > 0 && !is.na(ar)) {
        pl$fertilite[i] <- d$hdom + pente * (log(ar) - log(d$age))
      }
    }
    pl$age_ref[i] <- ar
  }
  pl <- pl[!is.na(pl$type), , drop = FALSE]
  res <- pl[!is.na(pl$fertilite), , drop = FALSE]
  out <- if (nrow(res)) {
    do.call(rbind, lapply(split(res, list(res$species, res$type), drop = TRUE), function(d) {
      data.frame(species = d$species[1], type = d$type[1], n_plots = nrow(d),
                 fertilite_moy = mean(d$fertilite), fertilite_med = stats::median(d$fertilite),
                 fertilite_sd = if (nrow(d) > 1L) stats::sd(d$fertilite) else NA_real_,
                 age_ref = d$age_ref[1], stringsAsFactors = FALSE)
    }))
  } else {
    data.frame(species = character(), type = character(), n_plots = integer(),
               fertilite_moy = numeric(), fertilite_med = numeric(),
               fertilite_sd = numeric(), age_ref = numeric(), stringsAsFactors = FALSE)
  }
  out <- out[order(out$species, out$type), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "plots") <- pl
  attr(out, "guide") <- guide
  attr(out, "provisoire") <- TRUE
  out
}
