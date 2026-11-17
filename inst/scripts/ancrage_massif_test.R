# Mesure des mailles d'ancrage GBIF sur le massif test (mission 007).
# Usage (depuis la racine du depot) : LC_ALL=C.UTF-8 Rscript inst/scripts/ancrage_massif_test.R [dossier]
# Sorties sous `data/ancrage/` (ignore par git ; occurrences reelles CC BY-NC : ne pas versionner).
# Resultat commente dans docs/ancrage-massif-test.md.
#
# Les occurrences sont lues par l'API publique (sans compte), annee par annee, pages de
# 100 (les pages plus grandes et occ_search(limit = 100000) n'ont pas abouti dans la
# session d'origine). Valeurs indicatrices SYNTHETIQUES (pas de Baseflor) : toute espece
# compte comme indicatrice, les comptes de mailles sont une borne haute.
suppressMessages({
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE) else library(sylvostation)
  library(jsonlite)
})
args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args)) args[1] else "data/ancrage"
dir.create(file.path(out_dir, "years"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "foret"), recursive = TRUE, showWarnings = FALSE)

emprise <- c(1007000, 6790000, 1022000, 6805000)  # xmin ymin xmax ymax, EPSG:2154
wkt <- URLencode(sylvostation:::.emprise_wkt_wgs84(emprise), reserved = TRUE)
gbif_base <- paste0("https://api.gbif.org/v1/occurrence/search?taxonKey=7707728",
                    "&hasCoordinate=true&hasGeospatialIssue=false&limit=100&geometry=", wkt)

# --- 1. Occurrences (reprise possible : les pages valides deja la sont gardees) ---
valide <- function(f) file.exists(f) && !inherits(try(fromJSON(f), silent = TRUE), "try-error")
for (y in 2000:2026) {
  off <- 0
  repeat {
    f <- file.path(out_dir, "years", sprintf("%d_%d.json", y, off))
    for (essai in 1:6) {
      if (valide(f)) break
      system2("curl", c("-s", "--max-time", "60", "-o", shQuote(f),
                        shQuote(paste0(gbif_base, "&year=", y, "&offset=", off))))
    }
    if (!valide(f)) stop("echec de lecture : ", f)
    r <- fromJSON(f)
    if (isTRUE(r$endOfRecords) || !length(r$results)) break
    off <- off + 100
  }
}
keep <- c("gbifID", "species", "speciesKey", "decimalLongitude", "decimalLatitude",
          "coordinateUncertaintyInMeters", "datasetKey", "license", "year",
          "dataGeneralizations", "informationWithheld")
occ <- do.call(rbind, lapply(list.files(file.path(out_dir, "years"), full.names = TRUE), function(f) {
  df <- fromJSON(f, flatten = TRUE)$results
  if (!length(df)) return(NULL)
  for (k in setdiff(keep, names(df))) df[[k]] <- NA
  df[, keep]
}))
occ <- occ[!duplicated(occ$gbifID), ]
cat("occurrences lues :", nrow(occ), "\n")

# --- 2. BD Foret (WFS, couche et champ du par. 4 de docs/referentiels.md) ---
ff <- file.path(out_dir, "foret", "foret.json")
if (!file.exists(ff)) {
  system2("curl", c("-s", "--max-time", "300", "-o", shQuote(ff), shQuote(paste0(
    "https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature",
    "&TYPENAMES=LANDCOVER.FORESTINVENTORY.V2:formation_vegetale&SRSNAME=EPSG:2154",
    "&BBOX=1007000,6790000,1022000,6805000,EPSG:2154&OUTPUTFORMAT=application/json&COUNT=5000"))))
}
forest <- sf::st_transform(sf::read_sf(ff), 2154)

# --- 3. Nettoyage et mailles ---
p0 <- clean_occ(occ)
pf <- clean_occ(occ, forest = forest)
print(attr(pf, "clean_log"))
sp <- sort(unique(occ$species[!is.na(occ$species)]))
set.seed(1)
ind <- data.frame(nom = sp, ph = round(runif(length(sp), 1, 9), 1),
                  humidite = round(runif(length(sp), 1, 9), 1), synthetic = TRUE)
for (cell in c(50, 100)) for (ms in c(3, 5)) {
  g <- grid_bioindication(pf, ind, cell = cell, min_species = ms)
  cat(sprintf("foret, maille %3d m, >= %d esp. : occupees %d, exploitables %d\n", cell, ms,
              attr(g, "n_mailles_occupees"), nrow(g)))
}

# --- 4. Tableau des mailles exploitables (agregats : versionnables) ---
g50 <- grid_bioindication(pf, ind, 50, 5)
dominant <- function(z) names(sort(table(z), decreasing = TRUE))[1]
tab <- do.call(rbind, lapply(seq_len(nrow(g50)), function(i) {
  s <- pf[lengths(sf::st_intersects(pf, g50[i, ])) > 0, ]
  data.frame(x_min = g50$x_min[i], y_min = g50$y_min[i], poids = g50$poids[i],
             n_occ = g50$n_occ[i], jeux = length(unique(s$dataset_key)),
             annees = length(unique(s$year)), jeu_dominant = dominant(s$dataset_key),
             licence_dominante = dominant(s$license),
             # independante = au moins deux jeux ou deux annees (pas un releve unique)
             independante = length(unique(s$dataset_key)) > 1 || length(unique(s$year)) > 1)
}))
tab <- tab[order(-tab$poids, tab$x_min), ]
print(tab, row.names = FALSE)
utils::write.csv(tab, file.path(out_dir, "mailles_50m_exploitables.csv"), row.names = FALSE)
sf::st_write(g50, file.path(out_dir, "mailles_50m_exploitables.gpkg"), delete_dsn = TRUE, quiet = TRUE)
sf::st_write(grid_bioindication(pf, ind, 100, 5), file.path(out_dir, "mailles_100m_exploitables.gpkg"),
             delete_dsn = TRUE, quiet = TRUE)
