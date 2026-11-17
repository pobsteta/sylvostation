# Surface analytique synthetique : plan incline de 10 %, descendant vers le sud
# (altitude croissante vers le nord), 240 x 240 cellules de 25 m (6 km), origine
# multiple de 50 m en Lambert-93. z = 500 + 0,1 * (y - ymin).
make_synth_dtm <- function(nc = 240, res = 25, xmin = 980000, ymin = 6800000,
                           fun = function(x, y) 500 + 0.1 * (y - ymin)) {
  r <- terra::rast(nrows = nc, ncols = nc, xmin = xmin, xmax = xmin + nc * res,
                   ymin = ymin, ymax = ymin + nc * res, crs = "EPSG:2154")
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))  # x = est, y = nord
  terra::values(r) <- fun(xy[, 1], xy[, 2])
  names(r) <- "synth_dtm"
  r
}
