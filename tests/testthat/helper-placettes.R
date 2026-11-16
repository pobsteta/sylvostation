# Jeu IFN synthetique (synthetic = TRUE) : 5 placettes en Lambert-93, valeurs
# fabriquees pour verifier les calculs a la main. Jamais presente comme un resultat.
make_synth_ifn <- function() {
  pl <- data.frame(
    CAMPAGNE = 2020, IDP = 1:5, XL = 1010500 + 1000 * (0:4), YL = 6795500,
    DATEECO = as.Date(c("2020-06-10", "2020-01-15", "2020-07-20", "2020-08-05", "2020-09-01")),
    NINCID = c("0", "0", "4", "0", NA), INCID = c("0", "0", "2", "0", NA),
    PROF1 = c("2", NA, NA, NA, NA), PROF2 = c("6", "5", "5", "4", "5"),
    TEXT1 = c("6", NA, NA, NA, NA), TEXT2 = c("2", "4", "4", "1", "4"),
    CAILLOUX = c("2", "X", "0", "10", "0"), OBSPEDO = c(NA, NA, NA, NA, "5"),
    PGLEY = c("3", "X", NA, NA, NA), POX = c("X", "X", NA, "5", NA),
    PPSEUDO = c("5", "X", NA, NA, NA),
    synthetic = TRUE, stringsAsFactors = FALSE)
  pl$id_placette <- paste(pl$CAMPAGNE, pl$IDP, sep = "_")
  pl <- sf::st_as_sf(pl, coords = c("XL", "YL"), crs = 2154, remove = FALSE)
  pl <- mark_ifn(pl)
  fl <- data.frame(
    id_placette = paste0("2020_", c(1, 4, 5,   1, 2, 3, 4,   2,   1)),
    CD_REF      = c(            10, 10, 10,   20, 20, 20, 20,  30,  40),
    INCO_FLOR   = c(NA, NA, NA, NA, NA, NA, NA, NA, "3"),
    synthetic = TRUE)
  fl$CAMPAGNE <- 2020
  fl$IDP <- as.numeric(sub("2020_", "", fl$id_placette))
  structure(list(placettes = pl, flore = mark_ifn(fl), arbre = NULL), class = "sylvo_ifn")
}

# Valeurs indicatrices synthetiques associees (cd_ref 10, 20, 30 ; 99 absent)
make_synth_indic <- function() {
  data.frame(cd_ref = c(10, 20, 30, 40), ph = c(4, 6, 8, 5), azote = c(2, 4, 6, 5),
             synthetic = TRUE)
}

# Raster climat synthetique de maille 1 km (couvre l'emprise de test), constant par colonne.
make_synth_climat <- function(res = 1000) {
  r <- terra::rast(xmin = 1000000, xmax = 1030000, ymin = 6785000, ymax = 6810000,
                   resolution = res, crs = "EPSG:2154")
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  mk <- function(v, nom) { x <- r; terra::values(x) <- v; names(x) <- nom; x }
  c(mk(600 + (xy[, 1] - 1000000) / 1000, "p_sv"),   # mm
    mk(rep(450, nrow(xy)), "etp_sv"),
    mk(rep(8, nrow(xy)), "t_moy"))
}
