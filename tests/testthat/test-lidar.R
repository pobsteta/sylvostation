# Mission 003 : run_lasr() et point_lidar_metrics(). Aucun test ne touche au réseau.
# Jeu d'essai : extrait réel de 80 m x 80 m de la dalle 1015-6794 (inst/extdata/SOURCES.md),
# carré x [1015500 ; 1015580], y [6793500 ; 6793580] (EPSG:2154).

laz_extrait <- function() {
  system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
}

pts_lidar <- function(prec = 5, x = 1015540, y = 6793540) {
  sf::st_sf(id = 1, loc_precision_m = prec,
            geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154))
}

# --- run_lasr ------------------------------------------------------------------
test_that("run_lasr (lasR) : MNT et MHC à 1 m alignés, rognés à la dalle, valeurs plausibles", {
  skip_if_not_installed("lasR")
  skip_if(!nzchar(laz_extrait()))
  out <- file.path(tempdir(), "t_lasr")
  r <- run_lasr(laz_extrait(), out, res = 1, ncores = 1, buffer = 0, engine = "lasr")
  expect_equal(r$tile_id, "1015-6794")
  expect_true(file.exists(r$mnt) && file.exists(r$mhc))
  expect_equal(basename(r$mnt), "mnt_1015-6794.tif")
  expect_false(dir.exists(file.path(out, "_raw")))
  mnt <- terra::rast(r$mnt)
  mhc <- terra::rast(r$mhc)
  expect_true(sf::st_crs(terra::crs(mnt)) == sf::st_crs(2154))
  expect_equal(terra::res(mnt), c(1, 1))
  # alignement sur des multiples de 1 m et emprise = carré de l'extrait (à 1 m près)
  expect_equal(terra::xmin(mnt) %% 1, 0)
  expect_equal(terra::ymin(mnt) %% 1, 0)
  e <- as.vector(terra::ext(mnt))
  expect_true(e[["xmin"]] >= 1015499 && e[["xmax"]] <= 1015582)
  expect_true(e[["ymin"]] >= 6793499 && e[["ymax"]] <= 6793582)
  # la cellule de (1015540.5 ; 6793540.5) existe et porte une altitude du massif (399-652 m
  # sur la dalle entière, mesure de l'incrément 1)
  z <- terra::extract(mnt, cbind(1015540.5, 6793540.5))[1, 1]
  expect_false(is.na(z))
  expect_true(z > 399 && z < 652)
  v <- terra::values(mhc, na.rm = TRUE)
  expect_gt(length(v), 0.8 * terra::ncell(mhc))
  expect_true(min(v) > -2 && max(v) < 60)
  # aucune valeur nodata non déclarée (~ -2.147e7) ne subsiste dans les produits écrits
  expect_false(any(terra::values(mnt, na.rm = TRUE) < -1e6))
  expect_false(any(terra::values(mhc, na.rm = TRUE) < -1e6))
  tm <- attr(r, "timing")
  expect_equal(tm$engine, "lasr")
  expect_lt(tm$download_s, 0.5)
  expect_gt(tm$laz_bytes, 1e6)
})

test_that("run_lasr : un LAZ local n'est jamais supprimé (keep_laz = FALSE)", {
  skip_if_not_installed("lasR")
  skip_if(!nzchar(laz_extrait()))
  copie <- file.path(tempdir(), "LHD_FXX_1015_6794_copie.laz")
  file.copy(laz_extrait(), copie, overwrite = TRUE)
  run_lasr(copie, file.path(tempdir(), "t_lasr2"), ncores = 1, buffer = 0, keep_laz = FALSE,
           engine = "lasr")
  expect_true(file.exists(copie))
})

test_that("run_lasr (lidR) : repli cohérent avec lasR sur le MNT", {
  skip_if_not_installed("lasR")
  skip_if_not_installed("lidR")
  skip_if(!nzchar(laz_extrait()))
  a <- run_lasr(laz_extrait(), file.path(tempdir(), "t_a"), ncores = 1, buffer = 0, engine = "lasr")
  b <- run_lasr(laz_extrait(), file.path(tempdir(), "t_b"), ncores = 1, buffer = 0, engine = "lidr")
  expect_equal(attr(b, "timing")$engine, "lidr")
  ma <- terra::rast(a$mnt)
  mb <- terra::rast(b$mnt)
  mb <- terra::resample(mb, ma, method = "near")
  d <- terra::values(ma - mb, na.rm = TRUE)
  expect_gt(length(d), 1000)
  expect_lt(abs(stats::median(d)), 0.5)
})

test_that("run_lasr (lidR seul) : MNT et MHC produits sans lasR", {
  skip_if_not_installed("lidR")
  skip_if(!nzchar(laz_extrait()))
  r <- run_lasr(laz_extrait(), file.path(tempdir(), "t_lidr"), ncores = 1, buffer = 0,
                engine = "lidR")
  expect_equal(attr(r, "timing")$engine, "lidr")
  mnt <- terra::rast(r$mnt)
  mhc <- terra::rast(r$mhc)
  expect_equal(terra::res(mnt), c(1, 1))
  z <- terra::extract(mnt, cbind(1015540.5, 6793540.5))[1, 1]
  expect_true(!is.na(z) && z > 399 && z < 652)
  expect_true(max(terra::values(mhc), na.rm = TRUE) < 60)
})

test_that("run_lasr : arguments invalides", {
  expect_error(run_lasr(character(0), tempdir()), "laz_files")
  expect_error(run_lasr("absent.laz", tempdir(), engine = "lasr"), "introuvable|install")
  expect_error(run_lasr(laz_extrait(), tempdir(), res = -1), "res")
  expect_error(run_lasr(laz_extrait(), tempdir(), buffer = -5), "buffer")
})

test_that(".tile_id_from_name et .tile_extent : identifiant et emprise d'une dalle", {
  f <- "LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz"
  expect_equal(sylvostation:::.tile_id_from_name(f), "1015-6794")
  expect_true(is.na(sylvostation:::.tile_id_from_name("autre.laz")))
  # coin nord-ouest (1015 km, 6794 km) : x [1015000 ; 1016000], y [6793000 ; 6794000]
  expect_equal(as.vector(sylvostation:::.tile_extent("1015-6794")),
               c(xmin = 1015000, xmax = 1016000, ymin = 6793000, ymax = 6794000))
})

# --- point_lidar_metrics ---------------------------------------------------------
test_that("point_lidar_metrics refuse les placettes IFN, même sans lidR", {
  p <- mark_ifn(pts_lidar())
  expect_error(point_lidar_metrics("absent.laz", p), "IFN|700")
  # tableau marqué seulement par la colonne
  q <- pts_lidar(prec = 700)
  expect_error(point_lidar_metrics("absent.laz", q), "pr.cision|25")
  # précision absente
  r <- pts_lidar()
  r$loc_precision_m <- NULL
  expect_error(point_lidar_metrics("absent.laz", r), "pr.cision|25")
})

test_that("point_lidar_metrics : points précis, métriques dans le disque", {
  skip_if_not_installed("lidR")
  skip_if(!nzchar(laz_extrait()))
  las <- lidR::readLAS(laz_extrait())
  p <- rbind(pts_lidar(prec = 5),
             pts_lidar(prec = 5, x = 1015000, y = 6793000)) # hors de l'extrait
  p$id <- 1:2
  m <- point_lidar_metrics(las, p, radius = 15)
  expect_s3_class(m, "sf")
  expect_true(all(c("lidar_n_pts", "lidar_zmean", "lidar_zq95", "lidar_cover2") %in% names(m)))
  expect_gt(m$lidar_n_pts[1], 1000)
  expect_true(m$lidar_zmean[1] > 399 && m$lidar_zmean[1] < 652) # Z absolus (non normalisés)
  expect_true(is.na(m$lidar_n_pts[2]))
  # le disque de 15 m contient moins de points que le carré de 80 m
  expect_lt(m$lidar_n_pts[1], lidR::npoints(las))
  # fichiers en entrée
  m2 <- point_lidar_metrics(laz_extrait(), p[1, ], radius = 15)
  expect_equal(m2$lidar_n_pts, m$lidar_n_pts[1])
  # points IFN refusés aussi avec des données valides
  expect_error(point_lidar_metrics(las, mark_ifn(p)), "IFN|700")
  expect_error(point_lidar_metrics(las, p, radius = 0), "radius")
})

# --- Classes exclues du MHC (mission 014, referentiels § 17) -------------------------
test_that("MHC : classe 66 exclue, 65 n'est plus citee, sol inchange (2, 9, 66)", {
  expect_equal(sylvostation:::.CLASSES_EXCLUES_MHC, 66L)
  expect_equal(sylvostation:::.FILTRE_MHC, "Classification %out% 66")
  expect_false(grepl("65", sylvostation:::.FILTRE_MHC))
  expect_equal(sylvostation:::.CLASSES_SOL, c(2L, 9L, 66L))
})

test_that("run_lasr (lasR) : un point virtuel de classe 66 ne fait pas le MHC", {
  skip_if_not_installed("lasR")
  skip_if_not_installed("lidR")
  # sol plat z = 0 (classe 2) sur 40 m x 40 m, un arbre (classe 5, z = 12) en (10,5 ; 10,5)
  # et un point virtuel (classe 66, z = 30) en (30,5 ; 30,5), repere local + 1015000/6793000.
  x0 <- 1015000; y0 <- 6793000
  g <- expand.grid(x = seq(0.5, 39.5, by = 1), y = seq(0.5, 39.5, by = 1))
  d <- data.frame(X = c(g$x, 10.5, 30.5) + x0, Y = c(g$y, 10.5, 30.5) + y0,
                  Z = c(rep(0, nrow(g)), 12, 30),
                  Classification = c(rep(2L, nrow(g)), 5L, 66L))
  d$ReturnNumber <- 1L; d$NumberOfReturns <- 1L
  # classe 66 : LAS 1.4, format de point 6 (classes sur 8 bits)
  h <- lidR::LASheader(d)
  h[["Version Minor"]] <- 4L; h[["Point Data Format ID"]] <- 6L
  h[["Header Size"]] <- 375L; h[["Offset to point data"]] <- 375L
  las <- suppressWarnings(lidR::LAS(d, header = h, check = FALSE))
  sf::st_crs(las) <- 2154
  f <- file.path(tempdir(), "synth_mhc66.las")
  suppressWarnings(lidR::writeLAS(las, f))
  out <- file.path(tempdir(), "t_mhc66")
  r <- run_lasr(f, out, res = 1, ncores = 1, buffer = 0, engine = "lasr")
  mhc <- terra::rast(r$mhc)
  arbre <- terra::cellFromXY(mhc, cbind(x0 + 10.5, y0 + 10.5))   # x = est, y = nord
  virt <- terra::cellFromXY(mhc, cbind(x0 + 30.5, y0 + 30.5))
  expect_equal(mhc[arbre][[1]], 12, tolerance = 1e-3)
  expect_true(is.na(mhc[virt][[1]]) || mhc[virt][[1]] < 1)
})
