# Clé de détermination terrain (mission 009, brief technique § 4 étape 8).
# Aucun réseau, aucun effet de bord.

.depth_nodes <- function(nodes) floor(log2(as.integer(nodes)))

# Précision en validation croisée (k blocs tirés au hasard, graine fixe).
.key_cv_predictions <- function(data, formula, control, folds, seed) {
  n <- nrow(data)
  if (exists(".Random.seed", envir = globalenv())) {
    old <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)
  f <- sample(rep_len(seq_len(folds), n))
  pred <- rep(NA_character_, n)
  for (i in seq_len(folds)) {
    fit <- rpart::rpart(formula, data = data[f != i, , drop = FALSE], method = "class",
                        control = control)
    pred[f == i] <- as.character(stats::predict(fit, data[f == i, , drop = FALSE],
                                                type = "class"))
  }
  pred
}

# Fusions successives des types les plus confondus jusqu'à atteindre `cible`.
.merge_suggestions <- function(obs, pred, cible) {
  grp <- stats::setNames(unique(c(obs, pred)), unique(c(obs, pred)))
  res <- list()
  repeat {
    o <- unname(grp[obs]); p <- unname(grp[pred])
    acc <- mean(o == p)
    if (acc >= cible || length(unique(grp)) < 2L) break
    niv <- sort(unique(c(o, p)))
    conf <- unclass(table(factor(o, niv), factor(p, niv)))
    conf <- conf + t(conf)
    diag(conf) <- -1
    ij <- which(conf == max(conf), arr.ind = TRUE)[1, ]
    if (conf[ij[1], ij[2]] <= 0) break
    de <- rownames(conf)[ij[1]]; vers <- rownames(conf)[ij[2]]
    grp[grp == de] <- vers
    o <- unname(grp[obs]); p <- unname(grp[pred])
    res[[length(res) + 1L]] <- data.frame(
      etape = length(res) + 1L, type_a = de, type_b = vers,
      n_confondus = as.integer(conf[ij[1], ij[2]]),
      taux_apres = mean(o == p), stringsAsFactors = FALSE)
  }
  if (length(res)) do.call(rbind, res) else
    data.frame(etape = integer(), type_a = character(), type_b = character(),
               n_confondus = integer(), taux_apres = numeric(), stringsAsFactors = FALSE)
}

#' Clé de détermination terrain (arbre de décision CART)
#'
#' Ajuste un arbre de classification (`rpart`) qui prédit le type à partir des seules
#' variables **observables sur le terrain**, de profondeur limitée (`maxdepth`, 5 par
#' défaut, valeur provisoire) pour rester utilisable. Publie deux taux de bon
#' classement par rapport à la typologie : `accuracy` (sur les données d'ajustement,
#' optimiste) et `accuracy_cv` (validation croisée à `folds` blocs tirés au hasard).
#' Le critère des 70 % du brief est appliqué au taux **en validation croisée**
#' (choix prudent) ; s'il n'est pas atteint, `merge_suggestions` liste, dans l'ordre,
#' les types les plus confondus à fusionner et le taux obtenu après chaque fusion.
#'
#' @param data Tableau portant la colonne des types et les observables (un `sf` est
#'   accepté, géométrie ignorée).
#' @param observables Noms des colonnes observables sur le terrain.
#' @param maxdepth Profondeur maximale de l'arbre (5).
#' @param type Nom de la colonne des types (`"type"`).
#' @param min_accuracy Taux minimal de bon classement (0,70).
#' @param folds Nombre de blocs de la validation croisée (5).
#' @param cp Paramètre de complexité de `rpart` (0,005, provisoire).
#' @param minbucket Effectif minimal d'une feuille (5).
#' @param seed Graine de la validation croisée.
#' @return Un objet de classe `sylvo_key` (liste) : `tree` (`rpart`), `accuracy`,
#'   `accuracy_cv`, `confusion` (validation croisée), `meets_target`,
#'   `merge_suggestions`, `depth`, `observables`, `provisoire = TRUE`. `print()` imprime
#'   la clé en texte.
#' @examples
#' set.seed(1)
#' d <- data.frame(pente = runif(120, 0, 30), humus = sample(c("mull", "moder"), 120, TRUE))
#' d$type <- ifelse(d$pente > 15, "A", ifelse(d$humus == "mull", "B", "C"))
#' build_key(d, c("pente", "humus"))
#' @export
build_key <- function(data, observables, maxdepth = 5L, type = "type",
                      min_accuracy = 0.70, folds = 5L, cp = 0.005, minbucket = 5L,
                      seed = 1L) {
  if (!requireNamespace("rpart", quietly = TRUE)) {
    stop("Le paquet 'rpart' est requis.", call. = FALSE)
  }
  d <- .drop_geom(data)
  if (!type %in% names(d)) stop("Colonne des types `", type, "` introuvable.", call. = FALSE)
  if (!is.character(observables) || !length(observables) || !all(observables %in% names(d))) {
    stop("`observables` doit nommer des colonnes de `data`.", call. = FALSE)
  }
  if (type %in% observables) {
    stop("Le type ne peut pas figurer parmi les observables.", call. = FALSE)
  }
  maxdepth <- as.integer(maxdepth)
  if (is.na(maxdepth) || maxdepth < 1L || maxdepth > 30L) {
    stop("`maxdepth` doit \u00eatre un entier entre 1 et 30.", call. = FALSE)
  }
  d <- d[!is.na(d[[type]]), c(type, observables), drop = FALSE]
  d[[type]] <- factor(as.character(d[[type]]))
  d[] <- lapply(d, function(v) if (is.character(v)) factor(v) else v)
  if (nlevels(d[[type]]) < 2L) stop("Au moins deux types sont n\u00e9cessaires.", call. = FALSE)
  names(d)[1L] <- ".type"
  fml <- stats::as.formula(paste(".type ~", paste(sprintf("`%s`", observables), collapse = " + ")))
  ctl <- rpart::rpart.control(maxdepth = maxdepth, cp = cp, minbucket = minbucket,
                              minsplit = 2L * minbucket, xval = 0)
  fit <- rpart::rpart(fml, data = d, method = "class", control = ctl)
  obs <- as.character(d$.type)
  acc <- mean(as.character(stats::predict(fit, d, type = "class")) == obs)
  folds <- min(as.integer(folds), nrow(d))
  pred_cv <- .key_cv_predictions(d, fml, ctl, folds, seed)
  acc_cv <- mean(pred_cv == obs)
  ok <- acc_cv >= min_accuracy
  sugg <- if (ok) .merge_suggestions(obs, pred_cv, min_accuracy)[0, ] else
    .merge_suggestions(obs, pred_cv, min_accuracy)
  prof <- max(.depth_nodes(rownames(fit$frame)))
  structure(list(tree = fit, accuracy = acc, accuracy_cv = acc_cv,
                 confusion = table(observe = obs, prevu = pred_cv),
                 meets_target = ok, min_accuracy = min_accuracy,
                 merge_suggestions = sugg, depth = prof,
                 observables = observables, provisoire = TRUE),
            class = "sylvo_key")
}

# Lignes de texte de la clé : un test par ligne, indentation = profondeur.
.key_lines <- function(fit) {
  fr <- fit$frame
  nodes <- as.integer(rownames(fr))
  lab <- labels(fit, minlength = 0L)
  lev <- attr(fit, "ylevels")
  lignes <- character()
  rec <- function(node) {
    i <- match(node, nodes)
    prof <- .depth_nodes(node)
    if (node > 1L) {
      lignes <<- c(lignes, paste0(strrep("  ", prof - 1L), "- ", lab[i],
                                  if (fr$var[i] == "<leaf>") {
                                    paste0(" -> ", lev[fr$yval[i]], " (n = ", fr$n[i], ")")
                                  } else ""))
    }
    if (fr$var[i] != "<leaf>") {
      rec(2L * node)
      rec(2L * node + 1L)
    } else if (node == 1L) {
      lignes <<- c(lignes, paste0("-> ", lev[fr$yval[i]], " (n = ", fr$n[i], ")"))
    }
  }
  rec(1L)
  lignes
}

#' @export
print.sylvo_key <- function(x, ...) {
  cat("Cl\u00e9 de d\u00e9termination terrain (CART), profondeur ", x$depth,
      " - valeurs provisoires\n", sep = "")
  cat(sprintf("Bon classement : %.1f %% (ajustement), %.1f %% (validation crois\u00e9e) ; cible %.0f %% : %s\n",
              100 * x$accuracy, 100 * x$accuracy_cv, 100 * x$min_accuracy,
              if (x$meets_target) "atteinte" else "NON atteinte"))
  cat(paste(.key_lines(x$tree), collapse = "\n"), "\n", sep = "")
  if (nrow(x$merge_suggestions)) {
    cat("Types confondus \u00e0 fusionner (dans l'ordre) :\n")
    print(x$merge_suggestions, row.names = FALSE)
  }
  invisible(x)
}
