# Fabrique inst/extdata/synth_reference.tif : carte de reference SYNTHETIQUE (mission 010).
# Les rasters de la carte de Gegout et al. (2008) (AgroParisTech) n'ont pas ete obtenus.
# Ce fichier est un substitut fabrique (gradients vrais synthetiques agreges a 50 m +
# bruit), balise synthetic = TRUE ; il ne dit rien sur la vraie carte.
# Usage (depuis la racine du depot) : Rscript inst/scripts/synth_reference.R
suppressMessages(devtools::load_all(quiet = TRUE))
cfg <- read_config("config.yml")
e <- cfg$emprise_test
demo_emprise <- c(e$xmin, e$ymin, e$xmin + 2500, e$ymin + 2500)  # idem _targets.R
grid <- build_grid(demo_emprise, cfg$resolution_m)
dtm <- synth_demo_dtm(grid)
terrain <- suppressWarnings(derive_terrain(dtm, tpi_radii = c(100, 300)))
climat <- synth_demo_climat(c(e$xmin, e$ymin, e$xmax, e$ymax))
truth <- synth_demo_truth(demo_predictors(terrain, dtm, climat))
ref <- synth_demo_reference(truth, res = 50)
terra::writeRaster(ref, "inst/extdata/synth_reference.tif", overwrite = TRUE,
                   datatype = "FLT4S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
cat("Écrit : inst/extdata/synth_reference.tif (",
    file.size("inst/extdata/synth_reference.tif"), "octets )\n")
