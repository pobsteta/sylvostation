# Comparaison a la carte de reference (mission 010, brief technique § 9).
# Les rasters de la carte de Gegout et al. (2008) (AgroParisTech) n'ont pas ete obtenus :
# leur format reel (noms de couches, codage des 59 types) est A VERIFIER. Les fonctions
# suivent une convention de ce paquet ; le jeu d'essai est synthetique
# (inst/extdata/synth_reference.tif).

#' Lire une carte de référence
#'
#' Lit un GeoTIFF de référence (EPSG:2154 exigé) dont les couches portent les noms de
#' la convention de ce paquet : `trophic`, `hydric`, `bioclim` (gradients) et,
#' facultativement, `type3` (code à trois chiffres). Le format réel des rasters
#' d'AgroParisTech n'étant pas connu, cette convention est **à vérifier** à leur
#' réception. Un fichier dont le nom commence par `synth_` ou balisé `synthetic` donne
#' un raster balisé synthétique.
#'
#' @param path Chemin du GeoTIFF.
#' @param layers Noms de couches exigés (défaut : au moins une parmi `trophic`,
#'   `hydric`, `bioclim`, `type3` doit exister).
#' @return Un `SpatRaster` en EPSG:2154.
#' @examples
#' f <- system.file("extdata", "synth_reference.tif", package = "sylvostation")
#' if (nzchar(f)) names(load_reference(f))
#' @export
load_reference <- function(path, layers = NULL) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("Carte de r\u00e9f\u00e9rence introuvable : ", paste(path, collapse = ", "), call. = FALSE)
  }
  r <- terra::rast(path)
  assert_crs_2154(r)
  connus <- c("trophic", "hydric", "bioclim", "type3")
  if (is.null(layers)) {
    if (!any(names(r) %in% connus)) {
      stop("Aucune couche reconnue (", paste(connus, collapse = ", "), ") ; couches lues : ",
           paste(names(r), collapse = ", "), ".", call. = FALSE)
    }
  } else if (!all(layers %in% names(r))) {
    stop("Couches absentes : ", paste(setdiff(layers, names(r)), collapse = ", "), ".",
         call. = FALSE)
  }
  if (startsWith(basename(path), "synth_") || identical(unname(terra::metags(r)["synthetic"]), "TRUE")) {
    terra::metags(r) <- c(synthetic = "TRUE")
  }
  r
}

#' Recoder des gradients en code à trois chiffres de la référence
#'
#' Applique les seuils de la référence (et non les nôtres) aux gradients, puis forme le
#' code à trois chiffres de la carte de Gégout et al. : un chiffre par axe (6 classes
#' trophiques, 5 bioclimatiques, 4 classes d'eau, soit 120 combinaisons ; 59 types
#' retenus par la carte). **L'ordre des chiffres** (`order`) et les **seuils** de la
#' référence ne sont pas vérifiés (article de la Revue forestière française à
#' obtenir) : à vérifier. Une valeur égale à un seuil tombe dans la classe supérieure ;
#' une valeur manquante donne `NA`.
#'
#' Écart à la fiche : le premier argument s'appelle `gradients` (valeurs des gradients)
#' et non `types`, car recoder avec d'autres seuils exige les valeurs, pas des classes.
#'
#' @param gradients `data.frame` (ou `sf`) avec une colonne numérique par gradient.
#' @param thresholds_ref Liste nommée de seuils croissants par gradient (voir
#'   [default_thresholds()] pour la forme). Au plus 9 classes par axe.
#' @param order Ordre des gradients dans le code (défaut : trophique, bioclimat, eau).
#' @return Un `data.frame` : colonnes `<gradient>_ref` (classe entière) et `code3`
#'   (chaîne de trois chiffres, `NA` si un axe manque).
#' @examples
#' g <- data.frame(trophic = c(-1, 0, 2), hydric = c(0, 1, 1), bioclim = c(0, 0, 1))
#' th <- list(trophic = c(-0.5, 0.5), bioclim = 0.5, hydric = 0.5)
#' recode_3digits(g, th)$code3
#' @export
recode_3digits <- function(gradients, thresholds_ref,
                           order = c("trophic", "bioclim", "hydric")) {
  g <- .drop_geom(gradients)
  if (!is.list(thresholds_ref) || !all(order %in% names(thresholds_ref))) {
    stop("`thresholds_ref` doit \u00eatre une liste nomm\u00e9e contenant : ",
         paste(order, collapse = ", "), ".", call. = FALSE)
  }
  if (!all(order %in% names(g))) {
    stop("Gradients absents : ", paste(setdiff(order, names(g)), collapse = ", "), ".",
         call. = FALSE)
  }
  cls <- lapply(order, function(nm) {
    s <- thresholds_ref[[nm]]
    if (!is.numeric(s) || anyNA(s) || is.unsorted(s, strictly = TRUE)) {
      stop("Seuils de `", nm, "` : nombres strictement croissants, sans NA.", call. = FALSE)
    }
    if (length(s) + 1L > 9L) stop("Au plus 9 classes par axe (", nm, ").", call. = FALSE)
    if (!is.numeric(g[[nm]])) stop("Le gradient `", nm, "` doit \u00eatre num\u00e9rique.", call. = FALSE)
    r <- findInterval(g[[nm]], as.numeric(s)) + 1L
    r[is.na(g[[nm]])] <- NA_integer_
    r
  })
  names(cls) <- paste0(order, "_ref")
  out <- as.data.frame(cls)
  out$code3 <- do.call(paste0, unname(lapply(cls, as.character)))
  out$code3[Reduce(`|`, lapply(cls, is.na))] <- NA_character_
  out
}

#' Comparer nos gradients à ceux de la référence (protocole § 9, étape 1)
#'
#' Agrège nos gradients à `res` mètres (moyenne), amène la référence sur la même
#' grille (rééchantillonnage bilinéaire si les grilles diffèrent), puis calcule, pour
#' chaque gradient commun, la **corrélation de rang** de Spearman sur les cellules
#' communes, et une carte des écarts. Les deux cartes n'ayant pas forcément la même
#' échelle, les écarts sont calculés sur des valeurs **centrées-réduites** (par couche,
#' sur les cellules communes) : écart = notre z moins le z de la référence. Un bon
#' accord montre que la chaîne reproduit l'existant, pas qu'elle a raison (brief § 9).
#'
#' @param ours `SpatRaster` de nos gradients (couches nommées comme celles de `ref`),
#'   en EPSG:2154.
#' @param ref `SpatRaster` de référence (voir [load_reference()]).
#' @param res Maille de comparaison en mètres (50, comme la référence). Doit être un
#'   multiple entier de notre maille.
#' @param max_cells Nombre maximal de cellules pour la corrélation (échantillon
#'   régulier au-delà).
#' @return Une liste : `correlation` (`data.frame` : `gradient`, `rho`, `n`), `ecarts`
#'   (`SpatRaster`, une couche `ecart_<gradient>`), `ours` et `ref` (les rasters
#'   comparés, sur la même grille à `res` mètres), `res`, `synthetic`.
#' @examples
#' a <- terra::rast(nrows = 20, ncols = 20, xmin = 1007000, xmax = 1007500,
#'                  ymin = 6790000, ymax = 6790500, crs = "EPSG:2154")
#' terra::values(a) <- seq_len(400)
#' names(a) <- "trophic"
#' compare_gradients(a, a, res = 50)$correlation
#' @export
compare_gradients <- function(ours, ref, res = 50, max_cells = 100000L) {
  if (!inherits(ours, "SpatRaster") || !inherits(ref, "SpatRaster")) {
    stop("`ours` et `ref` doivent \u00eatre des SpatRaster.", call. = FALSE)
  }
  assert_crs_2154(ours)
  assert_crs_2154(ref)
  if (!is.numeric(res) || length(res) != 1L || is.na(res) || res <= 0) {
    stop("`res` doit \u00eatre un nombre positif (m\u00e8tres).", call. = FALSE)
  }
  communs <- intersect(names(ours), names(ref))
  if (!length(communs)) stop("Aucune couche commune entre `ours` et `ref`.", call. = FALSE)
  f <- res / terra::res(ours)[1]
  if (f < 1 - 1e-6 || abs(f - round(f)) > 1e-6) {
    stop("`res` (", res, " m) doit \u00eatre un multiple entier de la maille de `ours` (",
         terra::res(ours)[1], " m).", call. = FALSE)
  }
  o <- ours[[communs]]
  if (round(f) > 1) o <- terra::aggregate(o, fact = round(f), fun = "mean", na.rm = TRUE)
  r <- ref[[communs]]
  if (!isTRUE(terra::compareGeom(o, r, stopOnError = FALSE))) {
    r <- terra::resample(terra::crop(r, o), o, method = "bilinear")
  }
  rho <- vapply(communs, function(nm) NA_real_, numeric(1))
  n <- integer(length(communs))
  ec <- vector("list", length(communs))
  for (i in seq_along(communs)) {
    nm <- communs[i]
    vo <- as.numeric(terra::values(o[[nm]], mat = FALSE))
    vr <- as.numeric(terra::values(r[[nm]], mat = FALSE))
    ok <- is.finite(vo) & is.finite(vr)
    n[i] <- sum(ok)
    if (n[i] >= 3L) {
      idx <- which(ok)
      if (length(idx) > max_cells) idx <- idx[round(seq(1, length(idx), length.out = max_cells))]
      rho[i] <- suppressWarnings(stats::cor(vo[idx], vr[idx], method = "spearman"))
      zo <- (o[[nm]] - mean(vo[ok])) / stats::sd(vo[ok])
      zr <- (r[[nm]] - mean(vr[ok])) / stats::sd(vr[ok])
    } else {
      zo <- o[[nm]] * NA
      zr <- r[[nm]] * NA
    }
    e <- zo - zr
    names(e) <- paste0("ecart_", nm)
    ec[[i]] <- e
  }
  syn <- identical(unname(terra::metags(ours)["synthetic"]), "TRUE") ||
    identical(unname(terra::metags(ref)["synthetic"]), "TRUE")
  list(correlation = data.frame(gradient = communs, rho = unname(rho), n = n,
                                stringsAsFactors = FALSE),
       ecarts = do.call(c, ec), ours = o, ref = r, res = res, synthetic = syn)
}
