# Typologie : discrétisation des gradients, fusion des types rares, contrôle
# par classification non supervisée (mission 009, brief technique § 4 étape 6).
# Aucun réseau, aucun effet de bord : tout est renvoyé en valeur.
# Aucune extraction de variable fine n'a lieu ici (les gradients sont déjà
# prédits) : la règle bloquante n'est donc pas appelée dans ce fichier.

#' Seuils provisoires de discrétisation des gradients
#'
#' Calcule, pour chaque gradient, des seuils par **quantiles** (classes de même
#' effectif). Ces seuils sont **provisoires** : ils ne sont pas écologiquement
#' lisibles et doivent être remplacés par des seuils fixés avec Pascal avant le
#' gel de la phase 1 (SER vosgiennes). L'objet renvoyé porte l'attribut
#' `provisoire = TRUE`.
#'
#' @param gradients Tableau de gradients (colonnes numériques).
#' @param n_classes Vecteur nommé : nombre de classes par gradient. Les noms sont
#'   ceux des colonnes de `gradients`. Défaut provisoire : 4 trophiques, 3 hydriques,
#'   2 bioclimats (le nombre de bioclimats dépend de l'amplitude altitudinale de la
#'   SER, 1 à 5 selon le brief).
#' @return Une liste nommée de vecteurs de seuils croissants (une classe de plus que
#'   de seuils), avec l'attribut `provisoire = TRUE`.
#' @examples
#' set.seed(1)
#' g <- data.frame(trophic = rnorm(100), hydric = rnorm(100), bioclim = rnorm(100))
#' default_thresholds(g)
#' @export
default_thresholds <- function(gradients,
                               n_classes = c(trophic = 4L, hydric = 3L, bioclim = 2L)) {
  g <- .drop_geom(gradients)
  if (is.null(names(n_classes)) || anyNA(n_classes) || any(n_classes < 1)) {
    stop("`n_classes` doit \u00eatre un vecteur nomm\u00e9 d'entiers >= 1.", call. = FALSE)
  }
  absents <- setdiff(names(n_classes), names(g))
  if (length(absents)) {
    stop("Gradients absents de `gradients` : ", paste(absents, collapse = ", "), ".",
         call. = FALSE)
  }
  th <- lapply(names(n_classes), function(nm) {
    x <- g[[nm]]
    if (!is.numeric(x)) stop("Le gradient `", nm, "` doit \u00eatre num\u00e9rique.", call. = FALSE)
    k <- as.integer(n_classes[[nm]])
    if (k == 1L) return(numeric(0))
    unique(unname(stats::quantile(x, probs = seq_len(k - 1L) / k, na.rm = TRUE,
                                  names = FALSE)))
  })
  names(th) <- names(n_classes)
  attr(th, "provisoire") <- TRUE
  th
}

.prefixes_gradients <- function(noms) {
  p <- toupper(substr(noms, 1, 1))
  if (anyDuplicated(p)) p <- paste0("G", seq_along(noms))
  p
}

#' Discrétiser les gradients en classes et former les types
#'
#' Pour chaque gradient, attribue une classe (1 = valeurs les plus basses) selon des
#' seuils, puis croise les classes : la combinaison est le **type** (par exemple
#' `T2-H1-B1`, préfixe = initiale du gradient). Une valeur égale à un seuil tombe
#' dans la classe supérieure. Une valeur manquante donne une classe et un type `NA`.
#'
#' @param gradients Tableau de gradients (colonnes numériques) ; un `sf` est accepté
#'   (la géométrie est ignorée).
#' @param thresholds Liste nommée de seuils par gradient (voir [default_thresholds()]).
#'   Défaut : seuils **provisoires** par quantiles.
#' @return Un `data.frame` de même nombre de lignes que `gradients` : une colonne
#'   entière `<gradient>_cl` par gradient seuillé et une colonne `type` (caractère).
#'   Attributs : `thresholds`, `provisoire` (`TRUE` si les seuils le sont) et
#'   `synthetic` (hérité de `gradients`).
#' @examples
#' set.seed(1)
#' g <- data.frame(trophic = rnorm(200), hydric = rnorm(200), bioclim = rnorm(200))
#' head(discretise(g))
#' @export
discretise <- function(gradients, thresholds = default_thresholds(gradients)) {
  g <- .drop_geom(gradients)
  if (!is.list(thresholds) || is.null(names(thresholds)) || !length(thresholds)) {
    stop("`thresholds` doit \u00eatre une liste nomm\u00e9e de seuils par gradient.", call. = FALSE)
  }
  absents <- setdiff(names(thresholds), names(g))
  if (length(absents)) {
    stop("Gradients absents de `gradients` : ", paste(absents, collapse = ", "), ".",
         call. = FALSE)
  }
  for (nm in names(thresholds)) {
    s <- thresholds[[nm]]
    if (!is.numeric(g[[nm]])) stop("Le gradient `", nm, "` doit \u00eatre num\u00e9rique.", call. = FALSE)
    if (!is.numeric(s) || anyNA(s) || is.unsorted(s, strictly = TRUE)) {
      stop("Les seuils de `", nm, "` doivent \u00eatre num\u00e9riques, sans NA, strictement croissants.",
           call. = FALSE)
    }
  }
  cls <- lapply(names(thresholds), function(nm) {
    x <- g[[nm]]
    r <- findInterval(x, as.numeric(thresholds[[nm]])) + 1L
    r[is.na(x)] <- NA_integer_
    r
  })
  names(cls) <- paste0(names(thresholds), "_cl")
  out <- as.data.frame(cls, stringsAsFactors = FALSE)
  pref <- .prefixes_gradients(names(thresholds))
  parts <- Map(function(p, v) paste0(p, v), pref, cls)
  out$type <- do.call(paste, c(unname(parts), sep = "-"))
  na_ligne <- Reduce(`|`, lapply(cls, is.na))
  out$type[na_ligne] <- NA_character_
  attr(out, "thresholds") <- thresholds
  attr(out, "provisoire") <- isTRUE(attr(thresholds, "provisoire"))
  attr(out, "synthetic") <- isTRUE(attr(gradients, "synthetic")) ||
    ("synthetic" %in% names(g) && all(g$synthetic %in% TRUE))
  out
}

#' Fusionner les types rares avec le type voisin le plus proche
#'
#' Un type est **rare** s'il couvre moins de `area_min` de la surface forestière ou
#' compte moins de `n_min` placettes (1 % et 15 d'après le brief, valeurs
#' **provisoires** à confirmer). Les types rares sont fusionnés un à un, le moins
#' étendu d'abord, avec le type le plus proche (distance euclidienne entre
#' combinaisons de classes, dans l'espace des colonnes `gradients`) ; en cas
#' d'égalité de distance, le plus étendu. Les surfaces et effectifs sont recalculés
#' après chaque fusion. Les stations azonales (alluviales, tourbeuses, éboulis) sont
#' à traiter à part, hors de cette fonction.
#'
#' @param types Tableau issu de [discretise()] : lignes = unités de surface (par
#'   exemple cellules du raster), colonne `type` et colonnes de classes.
#' @param area_min Part minimale de surface forestière (0,01 par défaut).
#' @param n_min Nombre minimal de placettes (15 par défaut).
#' @param gradients Noms des colonnes de classes définissant l'espace des distances
#'   (défaut : toutes les colonnes se terminant par `_cl`).
#' @param area Surface de chaque ligne de `types` (défaut : 1 par ligne, cellules de
#'   même taille).
#' @param plots Vecteur des types des **placettes** (un élément par placette, par
#'   exemple le `type` issu de [discretise()] appliqué aux gradients des placettes).
#'   Si `NULL`, les lignes de `types` sont comptées comme placettes.
#' @return `types` avec `type` mis à jour, la colonne `type_initial` et les
#'   attributs `merges` (table de traçabilité : `etape`, `de`, `vers`, `distance`,
#'   `motif`, `part_surface`, `n_placettes`), `plots` (types des placettes après
#'   fusion, si fournis) et `provisoire = TRUE`.
#' @examples
#' set.seed(1)
#' g <- data.frame(trophic = rnorm(500), hydric = rnorm(500), bioclim = rnorm(500))
#' t <- discretise(g)
#' attr(merge_rare(t, n_min = 30), "merges")
#' @export
merge_rare <- function(types, area_min = 0.01, n_min = 15, gradients = NULL,
                       area = NULL, plots = NULL) {
  if (!is.data.frame(types) || !"type" %in% names(types)) {
    stop("`types` doit \u00eatre un tableau avec une colonne `type` (voir discretise()).",
         call. = FALSE)
  }
  if (is.null(gradients)) gradients <- grep("_cl$", names(types), value = TRUE)
  if (!length(gradients) || !all(gradients %in% names(types))) {
    stop("`gradients` : colonnes de classes introuvables dans `types`.", call. = FALSE)
  }
  if (!is.numeric(area_min) || length(area_min) != 1L || area_min < 0 || area_min >= 1) {
    stop("`area_min` doit \u00eatre une part dans [0 ; 1[.", call. = FALSE)
  }
  if (!is.numeric(n_min) || length(n_min) != 1L || n_min < 0) {
    stop("`n_min` doit \u00eatre un nombre >= 0.", call. = FALSE)
  }
  n <- nrow(types)
  if (is.null(area)) area <- rep(1, n)
  if (length(area) != n || !is.numeric(area) || anyNA(area) || any(area < 0)) {
    stop("`area` doit \u00eatre num\u00e9rique, sans NA, de la longueur de `types`.", call. = FALSE)
  }
  lab <- as.character(types$type)
  plt <- if (is.null(plots)) NULL else as.character(plots)
  coord <- unique(types[!is.na(types$type), c("type", gradients), drop = FALSE])
  coord$type <- as.character(coord$type)
  if (anyDuplicated(coord$type)) {
    stop("Un m\u00eame `type` correspond \u00e0 plusieurs combinaisons de classes.", call. = FALSE)
  }
  xy <- as.matrix(coord[, gradients, drop = FALSE])
  rownames(xy) <- coord$type
  if (!is.null(plt) && !all(plt[!is.na(plt)] %in% coord$type)) {
    stop("`plots` contient des types absents de `types`.", call. = FALSE)
  }

  stats_types <- function() {
    ok <- !is.na(lab)
    a <- tapply(area[ok], lab[ok], sum)
    cnt <- if (is.null(plt)) table(lab[ok]) else table(plt[!is.na(plt)])
    cnt <- as.integer(cnt[names(a)])
    cnt[is.na(cnt)] <- 0L
    data.frame(type = names(a), part = as.numeric(a) / sum(a), n = cnt,
               stringsAsFactors = FALSE)
  }
  journal <- list()
  etape <- 0L
  repeat {
    st <- stats_types()
    rare <- st$part < area_min | st$n < n_min
    if (!any(rare) || nrow(st) < 2L) break
    r <- st[rare, , drop = FALSE]
    r <- r[order(r$part, r$n), , drop = FALSE][1L, ]
    autres <- st[st$type != r$type, , drop = FALSE]
    ref <- matrix(xy[r$type, ], nrow(autres), length(gradients), byrow = TRUE)
    d <- sqrt(rowSums((xy[autres$type, , drop = FALSE] - ref)^2))
    j <- order(d, -autres$part)[1L]
    dest <- autres$type[j]
    motif <- paste(c(if (r$part < area_min) "surface", if (r$n < n_min) "placettes"),
                   collapse = "+")
    etape <- etape + 1L
    journal[[etape]] <- data.frame(etape = etape, de = r$type, vers = dest,
                                   distance = unname(d[j]), motif = motif,
                                   part_surface = r$part, n_placettes = r$n,
                                   stringsAsFactors = FALSE)
    lab[!is.na(lab) & lab == r$type] <- dest
    if (!is.null(plt)) plt[!is.na(plt) & plt == r$type] <- dest
  }
  out <- types
  out$type_initial <- as.character(types$type)
  out$type <- lab
  attr(out, "merges") <- if (length(journal)) do.call(rbind, journal) else
    data.frame(etape = integer(), de = character(), vers = character(),
               distance = numeric(), motif = character(),
               part_surface = numeric(), n_placettes = integer(),
               stringsAsFactors = FALSE)
  attr(out, "plots") <- plt
  attr(out, "provisoire") <- TRUE
  out
}

# Indice de Rand ajusté entre deux partitions (Hubert et Arabie, 1985).
.adjusted_rand <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  tab <- table(a[ok], b[ok])
  n <- sum(tab)
  if (n < 2) return(NA_real_)
  c2 <- function(x) x * (x - 1) / 2
  somme <- sum(c2(tab))
  sa <- sum(c2(rowSums(tab)))
  sb <- sum(c2(colSums(tab)))
  attendu <- sa * sb / c2(n)
  maxi <- (sa + sb) / 2
  if (maxi == attendu) return(1)
  (somme - attendu) / (maxi - attendu)
}

#' Contrôle de la typologie par classification non supervisée (PAM)
#'
#' Variante de contrôle du brief : classification PAM sur les gradients centrés
#' réduits pour chaque nombre de groupes `k`, choix de `k` par la largeur moyenne de
#' silhouette, et comparaison avec la typologie par seuils par l'**indice de Rand
#' ajusté** (1 = partitions identiques, ~0 = accord dû au hasard). Au-delà de
#' `max_n` lignes, un sous-échantillon aléatoire (graine `seed`) est utilisé, le
#' PAM étant quadratique. Les lignes incomplètes sont écartées.
#'
#' @param gradients Tableau de gradients numériques.
#' @param k Nombres de groupes à essayer (2 à 20 par défaut).
#' @param types Typologie par seuils (vecteur de la longueur de `gradients`, ou
#'   tableau avec colonne `type`) ; `NULL` : pas de comparaison.
#' @param max_n Taille maximale du sous-échantillon (1500 par défaut).
#' @param seed Graine du sous-échantillonnage.
#' @return Une liste : `silhouette` (tableau `k`, `largeur`), `k_best`, `clusters`
#'   (groupes du meilleur `k`), `rows` (indices des lignes utilisées), `ari` (Rand
#'   ajusté pour `k_best`, ou `NA`), `ari_par_k` (idem pour chaque `k`).
#' @examples
#' set.seed(1)
#' g <- data.frame(a = c(rnorm(40), rnorm(40, 5)), b = c(rnorm(40), rnorm(40, 5)))
#' cluster_check(g, k = 2:4)$k_best
#' @export
cluster_check <- function(gradients, k = 2:20, types = NULL, max_n = 1500L, seed = 1L) {
  if (!requireNamespace("cluster", quietly = TRUE)) {
    stop("Le paquet 'cluster' est requis.", call. = FALSE)
  }
  g <- .drop_geom(gradients)
  g <- g[, vapply(g, is.numeric, logical(1)), drop = FALSE]
  if (!ncol(g)) stop("`gradients` ne contient aucune colonne num\u00e9rique.", call. = FALSE)
  if (!is.null(types)) {
    if (is.data.frame(types)) types <- types$type
    if (length(types) != nrow(g)) {
      stop("`types` doit avoir la longueur de `gradients`.", call. = FALSE)
    }
  }
  rows <- which(stats::complete.cases(g))
  if (length(rows) > max_n) {
    if (exists(".Random.seed", envir = globalenv())) {
      old <- get(".Random.seed", envir = globalenv())
      on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    }
    set.seed(seed)
    rows <- sort(sample(rows, max_n))
  }
  k <- sort(unique(as.integer(k)))
  k <- k[k >= 2L & k < length(rows)]
  if (!length(k)) stop("Pas assez de lignes pour les `k` demand\u00e9s.", call. = FALSE)
  x <- scale(as.matrix(g[rows, , drop = FALSE]))
  x[is.nan(x)] <- 0
  d <- stats::dist(x)
  fits <- lapply(k, function(kk) cluster::pam(d, k = kk, diss = TRUE))
  larg <- vapply(fits, function(f) f$silinfo$avg.width, numeric(1))
  best <- which.max(larg)
  t_rows <- if (is.null(types)) NULL else as.character(types[rows])
  ari_k <- if (is.null(t_rows)) rep(NA_real_, length(k)) else
    vapply(fits, function(f) .adjusted_rand(f$clustering, t_rows), numeric(1))
  list(silhouette = data.frame(k = k, largeur = larg), k_best = k[best],
       clusters = fits[[best]]$clustering, rows = rows,
       ari = ari_k[best], ari_par_k = stats::setNames(ari_k, k))
}
