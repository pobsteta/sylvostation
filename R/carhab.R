# Mission 031 : comparaison de nos gradients a CarHab 68 (docs/referentiels.md, par. 26).
# CarHab est une carte PREDICTIVE (pas une verite terrain) et n'est pas independante de la
# notre (RGE ALTI, TOPAGE, geologie BRGM entrent dans les deux modeles). La comparaison est de
# grille a grille, en EPSG:2154 (x = est, y = nord) ; la regle des 700 m n'est pas concernee.
# Seules carhab_fetch() (cache) ecrit sur disque.

#' Modalites ordinales CarHab (provisoires)
#'
#' Ordre proposé au § 26.4 de `docs/referentiels.md`, **provisoire** (décisions du
#' 2026-11-18) : `neutre` est une classe propre, jamais fusionnée avec `basique` ; l'ordre de
#' l'humidité mêle réserve en eau et engorgement. Les modalités sont celles du service
#' (lues sur l'emprise test) ; une modalité inconnue donne `NA`, comptée par [carhab_recode()].
#'
#' @param champ `"acidite_edaphique"` ou `"humidite_edaphique"`.
#' @return Un vecteur nommé d'entiers (nom = modalité CarHab, valeur = rang, 1 = bas).
#' @examples
#' carhab_levels("acidite_edaphique")
#' @export
carhab_levels <- function(champ = c("acidite_edaphique", "humidite_edaphique")) {
  champ <- match.arg(champ)
  if (champ == "acidite_edaphique") {
    m <- c("tr\u00e8s acide", "l\u00e9g\u00e8rement acide", "neutre", "basique", "hyperbasique")
  } else {
    m <- c("assez sec", "m\u00e9sique", "l\u00e9g\u00e8rement humide",
           "humide \u00e0 nappe circulante", "d\u00e9tremp\u00e9 \u00e0 nappe stagnante")
  }
  stats::setNames(seq_along(m), m)
}

#' Recoder une modalité CarHab en rang ordinal
#'
#' @param x Vecteur de modalités (texte).
#' @param champ Voir [carhab_levels()].
#' @return Un vecteur d'entiers (`NA` pour une modalité absente de l'ordre, avec un attribut
#'   `inconnues` : table des modalités non reconnues, jamais supprimées en silence).
#' @examples
#' carhab_recode(c("neutre", "basique", NA), "acidite_edaphique")
#' @export
carhab_recode <- function(x, champ = c("acidite_edaphique", "humidite_edaphique")) {
  champ <- match.arg(champ)
  lv <- carhab_levels(champ)
  x <- as.character(x)
  out <- unname(lv[x])
  inc <- table(x[!is.na(x) & is.na(out)])
  attr(out, "inconnues") <- inc
  out
}

#' URL d'une page de la requête WFS CarHab (Géoplateforme)
#'
#' Requête vérifiée au § 26.2 de `docs/referentiels.md` : type `Carhab_habitat:habitats_carhab`,
#' filtre CQL `INTERSECTS` en EPSG:2154, pagination `COUNT` / `STARTINDEX` (tri stable sur
#' `id_polygone_carhab`).
#'
#' @param bbox Emprise `c(xmin, ymin, xmax, ymax)` en Lambert-93 (x = est, y = nord).
#' @param occupation Valeur du champ `occupation` (défaut `"foret"`), ou `NULL`.
#' @param start,count Index de départ et taille de page.
#' @return Une chaîne (URL).
#' @examples
#' carhab_wfs_url(c(1007000, 6790000, 1022000, 6805000))
#' @export
carhab_wfs_url <- function(bbox, occupation = "foret", start = 0L, count = 500L) {
  bbox <- unname(as.numeric(bbox))
  if (length(bbox) != 4L || bbox[1] >= bbox[3] || bbox[2] >= bbox[4]) {
    stop("bbox doit etre c(xmin, ymin, xmax, ymax) en Lambert-93.", call. = FALSE)
  }
  if (bbox[1] < 0 || bbox[3] > 1.3e6 || bbox[2] < 6.0e6 || bbox[4] > 7.2e6) {
    stop("bbox hors de la France metropolitaine en Lambert-93 (x et y inverses ?).",
         call. = FALSE)
  }
  poly <- sprintf("POLYGON((%s))", paste(c(
    sprintf("%.0f %.0f", bbox[1], bbox[2]), sprintf("%.0f %.0f", bbox[3], bbox[2]),
    sprintf("%.0f %.0f", bbox[3], bbox[4]), sprintf("%.0f %.0f", bbox[1], bbox[4]),
    sprintf("%.0f %.0f", bbox[1], bbox[2])), collapse = ","))
  cql <- sprintf("INTERSECTS(geom,SRID=2154;%s)", poly)
  if (!is.null(occupation)) cql <- sprintf("%s AND occupation='%s'", cql, occupation)
  paste0("https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature",
         "&TYPENAMES=Carhab_habitat:habitats_carhab&SRSNAME=EPSG:2154",
         "&SORTBY=id_polygone_carhab&COUNT=", as.integer(count),
         "&STARTINDEX=", as.integer(start),
         "&CQL_FILTER=", utils::URLencode(cql, reserved = TRUE))
}

#' Lire les polygones CarHab de l'emprise (WFS paginé, avec cache)
#'
#' Si le fichier de cache existe, il est relu sans réseau ; sinon les pages sont lues par GDAL
#' (`sf::read_sf`), dédoublonnées sur `id_polygone_carhab`, puis écrites dans `cache_dir`
#' (jamais dans le dépôt). Les polygones qui recoupent l'emprise sont rendus entiers (non
#' découpés) : [carhab_rasterize()] découpe par la grille.
#'
#' @param bbox Emprise `c(xmin, ymin, xmax, ymax)` en Lambert-93.
#' @param cache_dir Dossier de cache (par défaut `data/cache/carhab`).
#' @param occupation Voir [carhab_wfs_url()].
#' @param taille_page Taille de page WFS.
#' @param reader Fonction `url -> sf` (injectable pour les tests ; défaut `sf::read_sf`).
#' @param essais Nombre d'essais par page.
#' @return Un `sf` en EPSG:2154.
#' @export
carhab_fetch <- function(bbox, cache_dir = file.path("data", "cache", "carhab"),
                         occupation = "foret", taille_page = 500L,
                         reader = sf::read_sf, essais = 4L) {
  bbox <- unname(as.numeric(bbox))
  nom <- sprintf("carhab_%s_%.0f_%.0f_%.0f_%.0f.gpkg",
                 if (is.null(occupation)) "tout" else occupation,
                 bbox[1], bbox[2], bbox[3], bbox[4])
  chemin <- file.path(cache_dir, nom)
  if (file.exists(chemin)) {
    out <- sf::read_sf(chemin)
    assert_crs_2154(out)
    return(out)
  }
  pages <- list()
  start <- 0L
  repeat {
    url <- carhab_wfs_url(bbox, occupation, start, taille_page)
    p <- NULL
    for (k in seq_len(essais)) {
      p <- tryCatch(reader(url), error = function(e) NULL)
      if (!is.null(p) && !"id_polygone_carhab" %in% names(p)) p <- NULL
      if (!is.null(p)) break
      Sys.sleep(2 * k)
    }
    if (is.null(p)) stop("Page WFS CarHab illisible (STARTINDEX ", start, ").", call. = FALSE)
    # GDAL ne rend pas toujours le CRS du GML : le service est interroge en EPSG:2154
    # (SRSNAME, DefaultCRS 2154, par. 26.1) ; la plausibilite des x et y est verifiee plus bas.
    if (is.na(sf::st_crs(p))) p <- sf::st_set_crs(p, 2154) else p <- sf::st_transform(p, 2154)
    pages[[length(pages) + 1L]] <- p
    if (nrow(p) < taille_page) break
    start <- start + as.integer(taille_page)
  }
  out <- do.call(rbind, pages)
  out <- out[!duplicated(out$id_polygone_carhab), ]
  assert_crs_2154(out)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  # le GML rend des MULTISURFACE (WKB 12), que GEOS ne lit pas : conversion en MULTIPOLYGON
  # par GDAL a l'ecriture du cache (sf::st_cast echoue sur ce type).
  tmp <- tempfile(fileext = ".gpkg")
  on.exit(unlink(tmp), add = TRUE)
  sf::write_sf(out, tmp)
  sf::gdal_utils("vectortranslate", tmp, chemin,
                 options = c("-nlt", "MULTIPOLYGON", "-nln", "carhab"), quiet = TRUE)
  sf::read_sf(chemin)
}

#' Rasteriser un champ CarHab sur notre grille (centre de cellule)
#'
#' Le polygone est rasterisé par le centre de la cellule (`touches = FALSE`) ; un polygone à
#' cheval sur la grille est donc découpé par elle. Le champ texte est recodé en rang ordinal
#' ([carhab_recode()]).
#'
#' @param polys `sf` de polygones CarHab, EPSG:2154.
#' @param grid `SpatRaster` de la grille (EPSG:2154).
#' @param champ `"acidite_edaphique"` ou `"humidite_edaphique"`.
#' @return Un `SpatRaster` à une couche (rang ordinal, `NA` hors polygone) sur `grid`.
#' @export
carhab_rasterize <- function(polys, grid, champ = c("acidite_edaphique", "humidite_edaphique")) {
  champ <- match.arg(champ)
  assert_crs_2154(polys)
  if (!isTRUE(terra::crs(grid, describe = TRUE)$code == "2154")) {
    stop("La grille doit etre en EPSG:2154.", call. = FALSE)
  }
  polys$rang <- carhab_recode(polys[[champ]], champ)
  v <- terra::vect(polys[, "rang"])
  r <- terra::rasterize(v, terra::rast(grid, nlyrs = 1), field = "rang", touches = FALSE)
  names(r) <- champ
  r
}

#' Classes de notre gradient aux mêmes proportions que CarHab
#'
#' Découpe `x` en autant de classes que `ref` (rang ordinal CarHab) a de modalités présentes,
#' aux **mêmes parts de surface** (quantiles de `x`), pour ne pas dépendre de nos seuils.
#'
#' @param x Gradient continu (nombres).
#' @param ref Rang ordinal CarHab (même longueur, sans `NA`).
#' @return Une liste : `classe` (entiers 1..k, k modalités présentes de `ref`), `rangs`
#'   (rangs CarHab présents, dans l'ordre), `parts`, `coupes` (quantiles).
#' @examples
#' carhab_quantile_classes(c(1, 2, 3, 4, 5, 6), c(1, 1, 2, 2, 3, 3))$classe
#' @export
carhab_quantile_classes <- function(x, ref) {
  if (length(x) != length(ref)) stop("x et ref doivent avoir la meme longueur.", call. = FALSE)
  if (anyNA(x) || anyNA(ref)) stop("x et ref ne doivent pas contenir de NA.", call. = FALSE)
  rangs <- sort(unique(ref))
  parts <- as.numeric(table(factor(ref, levels = rangs))) / length(ref)
  coupes <- if (length(rangs) > 1L) {
    unname(stats::quantile(x, cumsum(parts)[-length(rangs)], type = 7))
  } else numeric(0)
  classe <- findInterval(x, coupes, left.open = TRUE) + 1L
  list(classe = classe, rangs = rangs, parts = parts, coupes = coupes)
}

#' Kappa pondéré de deux classements ordinaux, accord à une classe près, matrice
#'
#' Kappa pondéré de Cohen écrit ici (aucun paquet de kappa n'est installé) :
#' `kappa = (po - pe) / (1 - pe)` avec des poids d'accord `1 - |i - j| / (k - 1)` (linéaire)
#' ou `1 - ((i - j) / (k - 1))^2` (quadratique).
#'
#' @param a,b Classes entières 1..k (mêmes niveaux), sans `NA`.
#' @param k Nombre de classes (défaut : maximum de `a` et `b`).
#' @param poids `"lineaire"` ou `"quadratique"`.
#' @return Une liste : `kappa`, `kappa_simple`, `accord_exact`, `accord_1_classe`, `matrice`
#'   (`a` en lignes, `b` en colonnes, effectifs), `n`.
#' @examples
#' carhab_kappa(c(1, 2, 3, 3), c(1, 2, 3, 2))$kappa
#' @export
carhab_kappa <- function(a, b, k = max(a, b), poids = c("lineaire", "quadratique")) {
  poids <- match.arg(poids)
  if (length(a) != length(b)) stop("a et b doivent avoir la meme longueur.", call. = FALSE)
  if (anyNA(a) || anyNA(b)) stop("a et b ne doivent pas contenir de NA.", call. = FALSE)
  m <- table(factor(a, levels = seq_len(k)), factor(b, levels = seq_len(k)))
  n <- sum(m)
  p <- m / n
  i <- row(p); j <- col(p)
  d <- if (k > 1L) abs(i - j) / (k - 1L) else 0 * i
  w <- if (poids == "lineaire") 1 - d else 1 - d^2
  pe_m <- outer(rowSums(p), colSums(p))
  po_w <- sum(w * p); pe_w <- sum(w * pe_m)
  po <- sum(diag(p)); pe <- sum(diag(pe_m))
  list(kappa = (po_w - pe_w) / (1 - pe_w),
       kappa_simple = (po - pe) / (1 - pe),
       accord_exact = po,
       accord_1_classe = sum(p[abs(i - j) <= 1]),
       matrice = m, n = n)
}

#' Spearman avec intervalle tenant compte de l'autocorrélation spatiale
#'
#' Deux estimations, méthode écrite :
#' 1. **bootstrap par blocs** : la zone est découpée en blocs carrés de `bloc_m` mètres
#'    (Lambert-93), les blocs sont tirés avec remise, le Spearman est recalculé sur les cellules
#'    des blocs tirés ; intervalle = quantiles 2,5 % et 97,5 % ;
#' 2. **sous-échantillon espacé** : une cellule tous les `pas_m` mètres (en x et en y), Spearman
#'    et intervalle de Bonett-Wright (`se = sqrt((1 + rho^2 / 2) / (n - 3))` sur la
#'    transformée de Fisher), valable si les cellules gardées sont quasi indépendantes
#'    (`pas_m` à comparer à la portée de l'autocorrélation, à justifier à l'appel).
#'
#' @param x,y Valeurs (numériques, mêmes longueurs, sans `NA`).
#' @param cx,cy Coordonnées des cellules (Lambert-93 : `cx` = est, `cy` = nord, en m).
#' @param bloc_m Côté des blocs (m).
#' @param pas_m Pas du sous-échantillon espacé (m).
#' @param nboot Nombre de tirages.
#' @param seed Graine.
#' @return Une liste : `rho`, `bloc` (`ic_bas`, `ic_haut`, `n_blocs`), `espace` (`rho`,
#'   `ic_bas`, `ic_haut`, `n`).
#' @examples
#' set.seed(1); xy <- expand.grid(cx = 1007010 + 20 * 0:49, cy = 6790010 + 20 * 0:49)
#' v <- xy$cx + rnorm(nrow(xy), sd = 300)
#' carhab_spearman(v, xy$cx, xy$cx, xy$cy, bloc_m = 200, pas_m = 100, nboot = 50)$rho
#' @export
carhab_spearman <- function(x, y, cx, cy, bloc_m = 1000, pas_m = 500, nboot = 300L,
                            seed = 1L) {
  n <- length(x)
  if (length(y) != n || length(cx) != n || length(cy) != n) {
    stop("x, y, cx et cy doivent avoir la meme longueur.", call. = FALSE)
  }
  if (anyNA(x) || anyNA(y)) stop("x et y ne doivent pas contenir de NA.", call. = FALSE)
  rho <- stats::cor(x, y, method = "spearman")
  bid <- paste(floor(cx / bloc_m), floor(cy / bloc_m))
  idx <- split(seq_len(n), bid)
  nb <- length(idx)
  set.seed(seed)
  bs <- vapply(seq_len(nboot), function(b) {
    i <- unlist(idx[sample.int(nb, nb, replace = TRUE)], use.names = FALSE)
    stats::cor(x[i], y[i], method = "spearman")
  }, numeric(1))
  q <- unname(stats::quantile(bs, c(0.025, 0.975), na.rm = TRUE))
  # sous-echantillon espace : cellules dont l'indice de bloc de pas_m est le premier de la
  # tranche (une cellule tous les pas_m en x et en y, decalage fixe sur le minimum)
  gx <- floor((cx - min(cx)) / pas_m); gy <- floor((cy - min(cy)) / pas_m)
  cle <- paste(gx, gy)
  keep <- !duplicated(cle)
  ns <- sum(keep)
  rs <- if (ns > 3L) stats::cor(x[keep], y[keep], method = "spearman") else NA_real_
  se <- sqrt((1 + rs^2 / 2) / (ns - 3))
  z <- atanh(rs)
  list(rho = rho,
       bloc = list(ic_bas = q[1], ic_haut = q[2], n_blocs = nb, bloc_m = bloc_m,
                   nboot = nboot),
       espace = list(rho = rs, ic_bas = tanh(z - 1.96 * se), ic_haut = tanh(z + 1.96 * se),
                     n = ns, pas_m = pas_m))
}

#' Comparer un gradient à un paramètre CarHab sur le domaine commun
#'
#' Domaine = cellules où notre gradient et le rang CarHab existent (et, si `aoa` est donné,
#' où la zone d'applicabilité vaut 1). Les cellules écartées sont comptées. Calcule Spearman
#' ([carhab_spearman()]), classes de notre gradient aux proportions CarHab
#' ([carhab_quantile_classes()]), kappa pondéré, matrice de confusion et résumé par modalité.
#'
#' @param gradient `SpatRaster` à une couche (notre gradient), EPSG:2154.
#' @param carhab `SpatRaster` du rang ordinal CarHab sur la même grille ([carhab_rasterize()]).
#' @param aoa `SpatRaster` (1 = dans la zone d'applicabilité) ou `NULL`.
#' @param ... Arguments passés à [carhab_spearman()].
#' @return Une liste : `comptes` (cellules), `spearman`, `kappa` (linéaire), `kappa_quad`,
#'   `classes` (`rangs`, `parts`, `coupes`), `par_modalite` (`data.frame`), `domaine`
#'   (`data.frame` `cx`, `cy`, `x`, `ref`, `classe`).
#' @export
carhab_compare <- function(gradient, carhab, aoa = NULL, ...) {
  if (!terra::compareGeom(gradient, carhab, stopOnError = FALSE)) {
    stop("gradient et carhab doivent etre sur la meme grille.", call. = FALSE)
  }
  x <- terra::values(gradient, mat = FALSE)
  r <- terra::values(carhab, mat = FALSE)
  a <- if (is.null(aoa)) rep(1, length(x)) else terra::values(aoa, mat = FALSE)
  xy <- terra::xyFromCell(gradient, seq_along(x))
  ok_g <- !is.na(x); ok_c <- !is.na(r)
  commun <- ok_g & ok_c
  dans <- commun & (is.na(a) | a == 1)
  comptes <- c(foret_nous = sum(ok_g), foret_carhab = sum(ok_c), commun = sum(commun),
               hors_aoa = sum(commun & !dans), retenues = sum(dans))
  d <- data.frame(cx = xy[dans, 1], cy = xy[dans, 2], x = x[dans], ref = as.integer(r[dans]))
  if (nrow(d) < 10L) stop("Domaine commun trop petit (< 10 cellules).", call. = FALSE)
  sp <- carhab_spearman(d$x, d$ref, d$cx, d$cy, ...)
  qc <- carhab_quantile_classes(d$x, d$ref)
  d$classe <- qc$classe
  ref_k <- match(d$ref, qc$rangs)
  k <- length(qc$rangs)
  kap <- carhab_kappa(d$classe, ref_k, k, "lineaire")
  kapq <- carhab_kappa(d$classe, ref_k, k, "quadratique")
  pm <- do.call(rbind, lapply(qc$rangs, function(g) {
    v <- d$x[d$ref == g]
    data.frame(rang = g, n = length(v), part = length(v) / nrow(d),
               mediane = stats::median(v), q25 = unname(stats::quantile(v, 0.25)),
               q75 = unname(stats::quantile(v, 0.75)))
  }))
  list(comptes = comptes, spearman = sp, kappa = kap, kappa_quad = kapq,
       classes = qc[c("rangs", "parts", "coupes")], par_modalite = pm, domaine = d)
}
