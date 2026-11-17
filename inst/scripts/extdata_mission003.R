# Fabrique les deux extraits réels de inst/extdata de la mission 003 (réseau requis).
#  - ser_extrait.gpkg : SER D11 et D12 de ser_l93.zip, simplifiées (tolérance 300 m) ;
#  - LHD_FXX_1015_6794_extrait.laz : carré de 80 m x 80 m d'une dalle LiDAR HD réelle.
# Usage : Rscript inst/scripts/extdata_mission003.R <dossier_de_travail> <dossier_extdata>
args <- commandArgs(TRUE)
work <- args[1]; dest <- args[2]
devtools::load_all(quiet = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)

# --- SER ---------------------------------------------------------------------
zip <- sylvostation:::.download_once(sylvostation:::.SER_URL, work)
ser <- sylvostation:::.read_ser_layer(zip)
ser <- ser[ser$codeser %in% c("D11", "D12"), c("codeser", "NomSER")]
codes <- c("D11", "D12")
g <- lapply(codes, function(k) sf::st_union(sf::st_geometry(ser[ser$codeser == k, ]))[[1]])
ser <- sf::st_sf(codeser = codes,
                 NomSER = ser$NomSER[match(codes, ser$codeser)],
                 geometry = sf::st_sfc(g, crs = 2154))
sf::st_geometry(ser) <- sf::st_simplify(sf::st_geometry(ser), dTolerance = 300)
unlink(file.path(dest, "ser_extrait.gpkg"))
sf::st_write(ser, file.path(dest, "ser_extrait.gpkg"), layer = "ser", quiet = TRUE)

# --- LAZ réduit (carré de 80 m au milieu de la dalle 1015-6794) ----------------
tuile <- sylvostation:::.download_once(
  "https://data.geopf.fr/telechargement/download/LiDARHD-NUALID/NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz",
  work)
x0 <- 1015500; y0 <- 6793500
out <- file.path(dest, "LHD_FXX_1015_6794_extrait.laz")
unlink(out)
pipe <- lasR::reader_rectangles(x0, y0, x0 + 80, y0 + 80) + lasR::write_las(out)
lasR::exec(pipe, on = tuile)
cat("LAZ :", file.size(out), "octets ; SER :", file.size(file.path(dest, "ser_extrait.gpkg")), "octets\n")
