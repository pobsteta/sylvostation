# Sorties du catalogue (mission 010, brief technique § 4 etape 10).
# write_outputs() est la seule fonction de ce fichier qui ecrit sur disque.

#' Tableau « état de preuve » du pipeline démo
#'
#' Pour chaque étape du brief technique : ce qui a tourné sur données `réel`, `réel
#' réduit` (extrait réel de `inst/extdata`) ou `synthétique` (jeu fabriqué, préfixe
#' `synth_`), ou n'a pas tourné (`non exécuté`). Spécification : `docs/spec.md`
#' (objection B1 de la mission 000). Les critères du § 7 du brief restent « non
#' atteints » tant qu'ils n'ont pas tourné sur données réelles.
#'
#' @param n_ifn Nombre de placettes IFN lues (pour le détail ; `NA` si inconnu).
#' @return Un `data.frame` : `etape`, `etat`, `dans_ce_run` (`oui` si l'étape a
#'   tourné dans le pipeline démo, `non` sinon : une ligne réelle non exécutée ici
#'   reste réelle mais hors de ce run), `detail`.
#' @examples
#' evidence_table()
#' @export
evidence_table <- function(n_ifn = NA_integer_) {
  ifn <- if (is.na(n_ifn)) "placettes IFN de inst/extdata" else
    paste0(n_ifn, " placettes IFN de inst/extdata")
  e <- function(etape, etat, detail, dans_ce_run = "oui") {
    data.frame(etape = etape, etat = etat, dans_ce_run = dans_ce_run, detail = detail,
               stringsAsFactors = FALSE)
  }
  out <- rbind(
    e("1. Emprise et grille", "r\u00e9el r\u00e9duit",
      "Contour SER simplifi\u00e9 (ser_extrait.gpkg) ; grille de 25 m calcul\u00e9e sur l'emprise de d\u00e9monstration."),
    e("2. LiDAR HD et MNT (incr\u00e9ment 1)", "r\u00e9el r\u00e9duit",
      "4 dalles r\u00e9elles trait\u00e9es lors de la mission 003, hors pipeline d\u00e9mo ; la d\u00e9mo utilise un MNT synth\u00e9tique (synth_dtm.tif).",
      dans_ce_run = "non"),
    e("3. D\u00e9riv\u00e9s du terrain", "synth\u00e9tique",
      "Calcul\u00e9s sur le MNT synth\u00e9tique ; MRVBF et hauteur au r\u00e9seau non calcul\u00e9s (WhiteboxTools/TOPAGE absents)."),
    e("4. G\u00e9ologie", "r\u00e9el r\u00e9duit",
      "Extrait BD Charm-50 de l'emprise test ; recodage lithologique provisoire, non valid\u00e9."),
    e("5. Placettes IFN (lecture, filtres)", "r\u00e9el r\u00e9duit", paste0(ifn, " (localis\u00e9es \u00e0 700 m)")),
    e("6. Gradients des placettes", "synth\u00e9tique",
      "Valeurs indicatrices et climat synth\u00e9tiques sur des placettes r\u00e9elles : r\u00e9sultat synth\u00e9tique."),
    e("7. Points d'ancrage (GBIF) et relev\u00e9s GNSS", "synth\u00e9tique",
      "Points fabriqu\u00e9s ; fonctions d'ancrage int\u00e9gr\u00e9es au paquet (mission 007), non branch\u00e9es au pipeline d\u00e9mo ; aucun relev\u00e9 GNSS r\u00e9el."),
    e("8. Sols (GlobalSoilMap)", "non ex\u00e9cut\u00e9", "Couches de sols absentes de la d\u00e9mo.", dans_ce_run = "non"),
    e("9. Mod\u00e8les, validation crois\u00e9e spatiale, zone d'applicabilit\u00e9", "synth\u00e9tique",
      "Ajust\u00e9s sur les points synth\u00e9tiques ; le mod\u00e8le r\u00e9gional IFN utilise des gradients synth\u00e9tiques."),
    e("10. Typologie (seuils, fusion des types rares)", "synth\u00e9tique",
      "Seuils provisoires par quantiles, non valid\u00e9s par un \u00e9cologue."),
    e("11. Caract\u00e9risation des types", "synth\u00e9tique", "Flore et arbres fabriqu\u00e9s."),
    e("12. Cl\u00e9 de d\u00e9termination terrain", "synth\u00e9tique", "Observables fabriqu\u00e9s."),
    e("13. Validation statistique et th\u00e9matique", "synth\u00e9tique",
      "Validation crois\u00e9e et \u00ab terrain \u00bb synth\u00e9tiques ; aucun relev\u00e9 GNSS r\u00e9el."),
    e("14. Comparaison \u00e0 la r\u00e9f\u00e9rence (\u00a7 9)", "synth\u00e9tique",
      "R\u00e9f\u00e9rence synth\u00e9tique (synth_reference.tif) ; rasters AgroParisTech non obtenus."),
    e("15. Sorties et rapport", "synth\u00e9tique", "Fichiers pr\u00e9fix\u00e9s synth_.")
  )
  out
}

.write_table_csv <- function(x, path) {
  utils::write.table(x, path, sep = ";", dec = ".", row.names = FALSE, na = "",
                     fileEncoding = "UTF-8", qmethod = "double")
}

.write_raster_cog <- function(r, path, cog) {
  use_cog <- isTRUE(cog) && "COG" %in% terra::gdal(drivers = TRUE)$name
  if (use_cog) {
    # compression par defaut du pilote COG (l'option COMPRESS passee via terra produit un
    # message GDAL sur le pilote MEM intermediaire)
    terra::writeRaster(r, path, filetype = "COG", overwrite = TRUE)
  } else {
    terra::writeRaster(r, path, filetype = "GTiff", overwrite = TRUE,
                       gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
  }
  if (use_cog) "COG" else "GTiff"
}

#' Écrire les sorties du catalogue
#'
#' Seule fonction d'écriture du jeu de sorties : crée `out_dir/<ser_code>/` et y écrit
#' (formats ouverts) les rasters en GeoTIFF (**COG** si le pilote GDAL `COG` est
#' disponible, sinon GeoTIFF tuilé compressé), un GeoPackage de la carte des types
#' (polygones, lisible hors ligne dans QGIS) et des tables CSV (séparateur `;`,
#' décimale `.`, UTF-8). Si `synthetic = TRUE`, **tous les fichiers sont préfixés
#' `synth_`** (CLAUDE.md) : le préfixe est la marque portée par les fichiers, car le
#' pilote COG ne conserve pas les balises `terra::metags`. Le tableau « état de
#' preuve » est écrit en CSV avec les autres tables.
#'
#' @param out_dir Dossier racine des sorties (`read_config()$out_dir`).
#' @param ser_code Code SER (sous-dossier).
#' @param types `SpatRaster` à une couche de codes entiers de types (EPSG:2154).
#' @param type_legend `data.frame` (`id`, `type`) : le type de chaque code de `types`.
#' @param gradients `SpatRaster` des gradients prédits.
#' @param uncertainty `SpatRaster` d'incertitude (écart-type, zone d'applicabilité...)
#'   ou `NULL`.
#' @param tables Liste nommée de `data.frame` écrits en CSV (le nom de l'élément fait
#'   le nom du fichier).
#' @param evidence Tableau d'état de preuve ([evidence_table()]).
#' @param synthetic `TRUE` pour préfixer les fichiers par `synth_`.
#' @param cog Demander un COG (par défaut oui, si GDAL le permet).
#' @return Un `data.frame` (`fichier`, `format`) des fichiers écrits, de façon
#'   invisible.
#' @examples
#' \dontrun{
#' write_outputs(tempdir(), "D11", types, legende, gradients, tables = list(types = tab))
#' }
#' @export
write_outputs <- function(out_dir, ser_code, types, type_legend, gradients,
                          uncertainty = NULL, tables = list(),
                          evidence = evidence_table(), synthetic = TRUE, cog = TRUE) {
  if (!is.character(out_dir) || length(out_dir) != 1L || !nzchar(out_dir)) {
    stop("`out_dir` doit \u00eatre un chemin.", call. = FALSE)
  }
  if (!is.character(ser_code) || length(ser_code) != 1L || !nzchar(ser_code)) {
    stop("`ser_code` doit \u00eatre un code SER.", call. = FALSE)
  }
  if (!inherits(types, "SpatRaster") || terra::nlyr(types) != 1L) {
    stop("`types` doit \u00eatre un SpatRaster \u00e0 une couche.", call. = FALSE)
  }
  if (!inherits(gradients, "SpatRaster")) stop("`gradients` doit \u00eatre un SpatRaster.", call. = FALSE)
  if (!is.null(uncertainty) && !inherits(uncertainty, "SpatRaster")) {
    stop("`uncertainty` doit \u00eatre un SpatRaster ou NULL.", call. = FALSE)
  }
  if (!is.data.frame(type_legend) || !all(c("id", "type") %in% names(type_legend))) {
    stop("`type_legend` doit avoir les colonnes id et type.", call. = FALSE)
  }
  if (!is.list(tables) || (length(tables) && (is.null(names(tables)) || any(!nzchar(names(tables))) ||
                                              !all(vapply(tables, is.data.frame, logical(1)))))) {
    stop("`tables` doit \u00eatre une liste nomm\u00e9e de data.frame.", call. = FALSE)
  }
  for (r in list(types, gradients, uncertainty)) if (!is.null(r)) assert_crs_2154(r)

  dir <- file.path(out_dir, ser_code)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  pre <- if (isTRUE(synthetic)) "synth_" else ""
  chemin <- function(nom) file.path(dir, paste0(pre, nom))
  ecrits <- data.frame(fichier = character(), format = character(), stringsAsFactors = FALSE)
  noter <- function(f, fmt) ecrits[nrow(ecrits) + 1L, ] <<- list(f, fmt)

  # rasters
  tp <- types
  names(tp) <- "type_id"
  f <- chemin("types.tif"); noter(f, .write_raster_cog(tp, f, cog))
  f <- chemin("gradients.tif"); noter(f, .write_raster_cog(gradients, f, cog))
  if (!is.null(uncertainty)) {
    f <- chemin("incertitude.tif"); noter(f, .write_raster_cog(uncertainty, f, cog))
  }

  # GeoPackage : carte des types (polygones) + table des types
  poly <- sf::st_as_sf(terra::as.polygons(tp, dissolve = TRUE))
  poly$type <- type_legend$type[match(poly$type_id, type_legend$id)]
  poly$area_ha <- as.numeric(sf::st_area(poly)) / 1e4
  poly$synthetic <- isTRUE(synthetic)
  f <- chemin("types.gpkg")
  sf::st_write(poly, f, layer = "types", delete_dsn = TRUE, quiet = TRUE)
  tt <- if ("types" %in% names(tables)) tables[["types"]] else type_legend
  sf::st_write(tt, f, layer = "table_types", append = TRUE, quiet = TRUE)
  noter(f, "GPKG")

  # tables CSV
  tout <- c(tables, list(etat_de_preuve = evidence, legende_types = type_legend))
  for (nm in names(tout)) {
    f <- chemin(paste0(nm, ".csv"))
    .write_table_csv(tout[[nm]], f)
    noter(f, "CSV")
  }
  invisible(ecrits)
}

#' Appliquer les fusions de [merge_rare()] à un vecteur de types
#'
#' Rejoue, dans l'ordre, les fusions (`de` vers `vers`) de la table de traçabilité de
#' [merge_rare()] : utile pour porter sur des points de terrain la typologie finale.
#'
#' @param types Vecteur de types (caractère).
#' @param merges Table `attr(<merge_rare()>, "merges")` (colonnes `de`, `vers`).
#' @return Le vecteur de types fusionnés.
#' @examples
#' apply_merges(c("a", "b", "c"), data.frame(de = c("a", "b"), vers = c("b", "c")))
#' @export
apply_merges <- function(types, merges) {
  if (is.null(merges) || !nrow(merges)) return(as.character(types))
  if (!all(c("de", "vers") %in% names(merges))) {
    stop("`merges` doit avoir les colonnes de et vers.", call. = FALSE)
  }
  t <- as.character(types)
  for (i in seq_len(nrow(merges))) t[!is.na(t) & t == merges$de[i]] <- merges$vers[i]
  t
}

#' Raster des types à partir des types de cellules
#'
#' Pose les types (caractères) de certaines cellules d'un raster modèle dans un raster
#' de codes entiers, et renvoie la légende. Les codes suivent l'ordre alphabétique des
#' types.
#'
#' @param template `SpatRaster` modèle (EPSG:2154).
#' @param cells Numéros de cellules du modèle (comme `terra::as.data.frame(cells = TRUE)`).
#' @param types Type de chaque cellule de `cells`.
#' @return Une liste : `raster` (une couche `type_id`, entiers) et `legend`
#'   (`data.frame` `id`, `type`).
#' @examples
#' r <- terra::rast(nrows = 2, ncols = 2, xmin = 1007000, xmax = 1007050,
#'                  ymin = 6790000, ymax = 6790050, crs = "EPSG:2154")
#' type_raster(r, 1:3, c("b", "a", "b"))$legend
#' @export
type_raster <- function(template, cells, types) {
  if (!inherits(template, "SpatRaster")) stop("`template` doit \u00eatre un SpatRaster.", call. = FALSE)
  assert_crs_2154(template)
  if (length(cells) != length(types)) {
    stop("`cells` et `types` doivent avoir la m\u00eame longueur.", call. = FALSE)
  }
  ok <- !is.na(types)
  niv <- sort(unique(as.character(types[ok])))
  r <- terra::rast(template, nlyrs = 1)
  terra::values(r) <- NA_real_
  r[cells[ok]] <- match(as.character(types[ok]), niv)
  names(r) <- "type_id"
  list(raster = r, legend = data.frame(id = seq_along(niv), type = niv,
                                       stringsAsFactors = FALSE))
}
