# Mission 022 : rapport PDF (en plus du HTML). Aucun téléchargement : les sorties sont
# fabriquées ici (préfixe synth_, synthetic = TRUE) ou posées à la main. Le PDF n'est
# jamais obligatoire : sans Quarto ou sans LaTeX, les tests de rendu sont sautés (motif
# dit) et le test du repli vérifie que le HTML est livré seul, avec un avertissement.

rendre_src <- function() {
  f <- system.file("rapport", "rendre_rapport.R", package = "sylvostation")
  if (!nzchar(f)) f <- testthat::test_path("..", "..", "inst", "rapport", "rendre_rapport.R")
  e <- new.env()
  sys.source(f, e)
  e
}

modele_rapport <- function() {
  f <- system.file("rapport", "rapport.qmd", package = "sylvostation")
  if (!nzchar(f)) f <- testthat::test_path("..", "..", "inst", "rapport", "rapport.qmd")
  f
}

# Sorties minimales du pipeline, en Lambert-93 (x = est, y = nord), 4 x 4 cellules de 25 m.
sorties_rapport <- function(synthetic = TRUE) {
  g <- terra::rast(nrows = 4, ncols = 4, xmin = 1007000, xmax = 1007100,
                   ymin = 6790000, ymax = 6790100, crs = "EPSG:2154")
  ty <- g
  terra::values(ty) <- rep(c(1, 1, 2, 2), 4)
  gr <- c(g, g, g)
  terra::values(gr) <- cbind(seq_len(16), rev(seq_len(16)), rep(1:4, 4))
  names(gr) <- c("trophic", "hydric", "bioclim")
  inc <- c(g, g)
  terra::values(inc) <- cbind(rep(0.5, 16), rep(c(1, 0), 8))
  names(inc) <- c("sd_cv_trophic", "aoa_trophic")
  tt <- data.frame(type = c("T1-H1-B1", "T2-H1-B1"), id = 1:2, azonal = FALSE,
                   area_ha = c(0.05, 0.05), part_surface = c(0.5, 0.5), n_placettes = c(3L, 4L))
  out <- tempfile("sorties_rapport")
  write_outputs(out, "D11", ty, data.frame(id = 1:2, type = tt$type, azonal = FALSE), gr, inc,
                tables = list(types = tt), synthetic = synthetic, cog = FALSE)
  file.path(out, "D11")
}

test_that("le modèle de rapport a les trois parties demandées et les deux formats", {
  q <- paste(readLines(modele_rapport(), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_match(q, "^---\n")
  expect_match(q, "\n  html:\n", fixed = TRUE)
  expect_match(q, "\n  pdf:\n", fixed = TRUE)
  expect_match(q, "pdf-engine: xelatex", fixed = TRUE)
  for (t in c("## Données d'entrée", "## Calculs réalisés", "## Cartes produites",
              "### Carte du gradient hydrique à 25 m", "### Carte de l'incertitude",
              "## État de preuve", "## Limites")) {
    expect_true(grepl(t, q, fixed = TRUE), info = t)
  }
  # le rapport ne lit que les fichiers écrits : il n'appelle ni le paquet ni le réseau
  expect_false(grepl("sylvostation::", q, fixed = TRUE))
  expect_false(grepl("download\\.file|curl::|httr|rgbif::|fetch_|url\\(", q))
  expect_match(q, "EPSG:2154", fixed = TRUE)
})

test_that("latex_disponible() rend un logique et le repli est annoncé sans LaTeX", {
  e <- rendre_src()
  expect_type(e$latex_disponible(), "logical")
  expect_length(e$latex_disponible(), 1L)
})

test_that("fixture : un point connu tombe dans la bonne cellule de la grille (EPSG:2154)", {
  d <- sorties_rapport()
  ty <- terra::rast(file.path(d, "synth_types.tif"))
  expect_error(assert_crs_2154(ty), NA)
  # x = est 1007010, y = nord 6790010 : coin sud-ouest, ligne 4, colonne 1, cellule 13
  cel <- terra::cellFromXY(ty, cbind(1007010, 6790010))
  expect_equal(cel, 13)
  expect_equal(unname(terra::rowColFromCell(ty, cel)), cbind(4, 1))
})

test_that("mode démo : le PDF est rendu à côté du HTML, avec la mention synthétique", {
  skip_on_cran()
  skip_if_not_installed("quarto")
  skip_if(is.null(quarto::quarto_path()), "Quarto absent : le rapport n'est pas rendu")
  e <- rendre_src()
  skip_if(!isTRUE(e$latex_disponible()), "LaTeX (xelatex) absent : le PDF n'est pas rendu")
  d <- sorties_rapport(TRUE)
  res <- e$rendre_rapport(d, "synth_", "D11", FALSE, modele = modele_rapport())
  expect_setequal(basename(res), c("rapport.html", "rapport.pdf"))
  expect_null(attr(res, "pdf_message"))
  pdf <- file.path(d, "rapport.pdf")
  expect_gt(file.size(pdf), 10000)
  expect_equal(rawToChar(readBin(pdf, "raw", 5)), "%PDF-")
  html <- paste(readLines(file.path(d, "rapport.html"), warn = FALSE), collapse = "\n")
  expect_match(html, "DONNÉES SYNTHÉTIQUES", fixed = TRUE)
  expect_match(html, "Calculs réalisés", fixed = TRUE)
  skip_if(!nzchar(Sys.which("pdftotext")) || !nzchar(Sys.which("pdfinfo")),
          "pdftotext/pdfinfo absents : contenu du PDF non contrôlé")
  info <- system2("pdfinfo", pdf, stdout = TRUE)
  pages <- as.integer(sub("^Pages:\\s+", "", grep("^Pages:", info, value = TRUE)))
  expect_gte(pages, 5)
  txt <- paste(system2("pdftotext", c("-layout", shQuote(pdf), "-"), stdout = TRUE), collapse = "\n")
  txt <- gsub("\\s+", " ", txt)
  expect_match(txt, "DONNÉES SYNTHÉTIQUES", fixed = TRUE)
  for (t in c("Données d’entrée", "Calculs réalisés", "Cartes produites",
              "Figure 1", "Figure 2", "Figure 3", "Figure 4", "EPSG :2154|EPSG:2154")) {
    expect_true(grepl(t, txt), info = t)
  }
  # les cartes (types, hydrique, incertitude) sont présentes : leurs légendes aussi
  expect_match(txt, "Carte des types de stations", fixed = TRUE)
  expect_match(txt, "Gradient hydrique de 25 m", fixed = TRUE)
  expect_match(txt, "Zone d’applicabilité", fixed = TRUE)
})

test_that("sans LaTeX : HTML seul, avertissement, aucun PDF ; mode réel avec la carte hydrique", {
  skip_on_cran()
  skip_if_not_installed("quarto")
  skip_if(is.null(quarto::quarto_path()), "Quarto absent : le rapport n'est pas rendu")
  e <- rendre_src()
  d <- sorties_rapport(FALSE)
  # carte hydrique de 25 m posée à la main (couches is_topo et k_sv), EPSG:2154
  g <- terra::rast(nrows = 4, ncols = 4, xmin = 1007000, xmax = 1007100,
                   ymin = 6790000, ymax = 6790100, crs = "EPSG:2154")
  h <- c(g, g)
  terra::values(h) <- cbind(seq(70, 85, length.out = 16), rep(c(0.9, 1.1), 8))
  names(h) <- c("is_topo", "k_sv")
  terra::writeRaster(h, file.path(d, "hydrique_25m.tif"), overwrite = TRUE)
  file.create(file.path(d, "rapport.pdf"))  # un PDF d'un run précédent ne doit pas rester
  expect_warning(
    res <- e$rendre_rapport(d, "", "D11", TRUE, modele = modele_rapport(),
                            pdf_disponible = function() FALSE),
    "PDF non produit")
  expect_equal(basename(res), "rapport.html")
  expect_match(attr(res, "pdf_message"), "HTML seul", fixed = TRUE)
  expect_false(file.exists(file.path(d, "rapport.pdf")))
  html <- paste(readLines(file.path(d, "rapport.html"), warn = FALSE), collapse = "\n")
  expect_match(html, "MODE RÉEL HORS LIGNE", fixed = TRUE)
  expect_false(grepl("DONNÉES SYNTHÉTIQUES", html, fixed = TRUE))
  expect_match(html, "Carte du gradient hydrique", fixed = TRUE)
  expect_match(html, "Gradient hydrique de 25 m", fixed = TRUE)
  expect_match(html, "Données d.entrée")
})
