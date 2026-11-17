fabrique_sorties <- function() {
  g <- terra::rast(nrows = 4, ncols = 4, xmin = 1007000, xmax = 1007100,
                   ymin = 6790000, ymax = 6790100, crs = "EPSG:2154")
  ty <- g
  terra::values(ty) <- rep(c(1, 1, 2, 2), 4)
  names(ty) <- "type_id"
  gr <- c(g, g)
  terra::values(gr) <- cbind(seq_len(16), rev(seq_len(16)))
  names(gr) <- c("trophic", "hydric")
  inc <- g
  terra::values(inc) <- 0.5
  names(inc) <- "sd_cv_trophic"
  list(types = ty, legend = data.frame(id = 1:2, type = c("T1-H1", "T2-H1")),
       gradients = gr, uncertainty = inc)
}

test_that("write_outputs écrit rasters, GeoPackage et CSV préfixés synth_ dans out_dir/<ser>/", {
  s <- fabrique_sorties()
  out <- file.path(tempfile("sorties"), "x")
  tab <- data.frame(type = c("T1-H1", "T2-H1"), area_ha = c(0.1, 0.1), synthetic = TRUE)
  w <- write_outputs(out, "D11", s$types, s$legend, s$gradients, s$uncertainty,
                     tables = list(types = tab), synthetic = TRUE)
  d <- file.path(out, "D11")
  expect_true(dir.exists(d))
  expect_true(all(startsWith(list.files(d), "synth_")))
  expect_true(all(file.exists(w$fichier)))
  expect_setequal(basename(w$fichier),
                  c("synth_types.tif", "synth_gradients.tif", "synth_incertitude.tif",
                    "synth_types.gpkg", "synth_types.csv", "synth_etat_de_preuve.csv",
                    "synth_legende_types.csv"))
  # raster relu : EPSG:2154, valeurs conservées ; le point (est 1007010, nord 6790010)
  # est dans la cellule du coin sud-ouest (ligne 4, colonne 1 = cellule 13)
  r <- terra::rast(file.path(d, "synth_gradients.tif"))
  expect_error(assert_crs_2154(r), NA)
  expect_equal(names(r), c("trophic", "hydric"))
  expect_equal(unname(unlist(r[terra::cellFromXY(r, cbind(1007010, 6790010))])), c(13, 4))
  # GeoPackage : polygones des types en EPSG:2154, surface totale = 100 m x 100 m = 1 ha
  p <- sf::st_read(file.path(d, "synth_types.gpkg"), layer = "types", quiet = TRUE)
  expect_error(assert_crs_2154(p), NA)
  expect_equal(sort(p$type), c("T1-H1", "T2-H1"))
  expect_equal(sum(p$area_ha), 1, tolerance = 1e-9)
  expect_true(all(p$synthetic))
  expect_equal(nrow(sf::st_read(file.path(d, "synth_types.gpkg"), layer = "table_types",
                                quiet = TRUE)), 2)
  # CSV : séparateur ;, UTF-8, relu à l'identique
  csv <- utils::read.delim(file.path(d, "synth_types.csv"), sep = ";", encoding = "UTF-8")
  expect_equal(csv$type, tab$type)
  ep <- utils::read.delim(file.path(d, "synth_etat_de_preuve.csv"), sep = ";",
                          encoding = "UTF-8")
  expect_true(all(ep$etat %in% c("réel", "réel réduit", "synthétique",
                                 "non exécuté")))
})

test_that("write_outputs sans balise synthétique : pas de préfixe ; COG quand GDAL le permet", {
  s <- fabrique_sorties()
  out <- tempfile("sorties")
  w <- write_outputs(out, "D11", s$types, s$legend, s$gradients, synthetic = FALSE)
  expect_true(file.exists(file.path(out, "D11", "types.tif")))
  expect_false(any(startsWith(basename(w$fichier), "synth_")))
  fmt <- w$format[basename(w$fichier) == "types.tif"]
  if ("COG" %in% terra::gdal(drivers = TRUE)$name) {
    expect_equal(fmt, "COG")
    expect_true(any(grepl("LAYOUT=COG", terra::describe(file.path(out, "D11", "types.tif")))))
  } else {
    expect_equal(fmt, "GTiff")
  }
  w2 <- write_outputs(tempfile("sorties"), "D11", s$types, s$legend, s$gradients, cog = FALSE)
  expect_equal(w2$format[grepl("types.tif", w2$fichier)], "GTiff")
})

test_that("write_outputs refuse les entrées invalides sans rien écrire", {
  s <- fabrique_sorties()
  out <- tempfile("sorties")
  expect_error(write_outputs(out, "D11", "x", s$legend, s$gradients), "SpatRaster")
  expect_error(write_outputs(out, "D11", s$types, s$legend, "x"), "SpatRaster")
  expect_error(write_outputs(out, "D11", s$types, data.frame(a = 1), s$gradients), "id et type")
  expect_error(write_outputs(out, "", s$types, s$legend, s$gradients), "SER")
  expect_error(write_outputs(out, "D11", s$types, s$legend, s$gradients, tables = list(1)),
               "nomm")
  mauvais <- s$types
  terra::crs(mauvais) <- "EPSG:4326"
  expect_error(write_outputs(out, "D11", mauvais, s$legend, s$gradients), "EPSG|incorrect")
  expect_false(dir.exists(out))
})

test_that("evidence_table : trois états de preuve, géologie et IFN en réel réduit", {
  e <- evidence_table(n_ifn = 100)
  expect_named(e, c("etape", "etat", "dans_ce_run", "detail"))
  expect_equal(e$dans_ce_run[grepl("MNT", e$etape)], "non")
  expect_equal(e$dans_ce_run[grepl("Sols", e$etape)], "non")
  expect_equal(e$dans_ce_run[grepl("G\u00e9ologie", e$etape)], "oui")
  expect_true(all(e$etat %in% c("réel", "réel réduit", "synthétique",
                                "non exécuté")))
  expect_equal(e$etat[grepl("MNT", e$etape)], "réel réduit")
  expect_equal(e$etat[grepl("Géologie", e$etape)], "réel réduit")
  expect_equal(e$etat[grepl("Placettes IFN", e$etape)], "réel réduit")
  expect_true(grepl("100 placettes", e$detail[grepl("Placettes IFN", e$etape)]))
  expect_equal(e$etat[grepl("Modèles", e$etape)], "synthétique")
  expect_false("réel" %in% e$etat)   # rien n'a tourné sur données réelles complètes
})

test_that("apply_merges rejoue les fusions dans l'ordre", {
  m <- data.frame(de = c("a", "b"), vers = c("b", "c"))
  expect_equal(apply_merges(c("a", "b", "c", NA), m), c("c", "c", "c", NA))
  expect_equal(apply_merges(c("a", "x"), NULL), c("a", "x"))
  expect_error(apply_merges("a", data.frame(x = 1)), "de et vers")
})

test_that("type_raster pose les types aux bonnes cellules (Lambert-93)", {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 1007000, xmax = 1007050,
                   ymin = 6790000, ymax = 6790050, crs = "EPSG:2154")
  tr <- type_raster(r, c(1, 2, 4), c("b", "a", "b"))
  expect_equal(tr$legend$type, c("a", "b"))
  # (1007010, 6790040) : colonne 1, ligne 1 (nord-ouest) = cellule 1 -> « b » = 2
  expect_equal(tr$raster[terra::cellFromXY(r, cbind(1007010, 6790040))][[1]], 2)
  expect_equal(tr$raster[2][[1]], 1)
  expect_true(is.na(tr$raster[3][[1]]))
  expect_error(type_raster(r, 1:2, "a"), "même longueur")
  expect_error(type_raster("x", 1, "a"), "SpatRaster")
})
