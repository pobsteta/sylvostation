# Mission 022 : concordance du rapport avec ses sources. Le gabarit rapport.qmd recopie des
# volumes, versions, dates, URL et licences (il ne lit que des fichiers écrits). Ce test
# échoue si la source (SOURCES.md, docs/referentiels.md, config.yml, _targets.R) ne contient
# plus la valeur recopiée, ou si le gabarit ne la porte plus.

test_that("les valeurs recopiées dans rapport.qmd existent encore dans leurs sources", {
  lire_txt <- function(chemins) {
    f <- chemins[file.exists(chemins)][1]
    if (is.na(f)) return(NULL)
    paste(readLines(f, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  }
  racine <- testthat::test_path("..", "..")
  q <- lire_txt(c(system.file("rapport", "rapport.qmd", package = "sylvostation"),
                  file.path(racine, "inst", "rapport", "rapport.qmd")))
  src <- lire_txt(c(system.file("extdata", "SOURCES.md", package = "sylvostation"),
                    file.path(racine, "inst", "extdata", "SOURCES.md")))
  ref <- lire_txt(file.path(racine, "docs", "referentiels.md"))
  cfgt <- lire_txt(file.path(racine, "config.yml"))
  tgt <- lire_txt(file.path(racine, "_targets.R"))
  skip_if(is.null(q) || is.null(src), "rapport.qmd ou SOURCES.md introuvable")

  # (valeur telle qu'écrite dans le gabarit, valeur telle qu'écrite dans SOURCES.md)
  dans_sources <- list(
    c("661 polygones", "661 polygones"), c("94 formations", "94 "), c("189 taxons", "189 taxons"),
    c("80 m x 80 m", "80 m x 80 m"), c("0,3 million", "0,3 million"), c("12 mailles", "12 mailles"),
    c("07/10/2026", "07/10/2026"), c("16/11/2026", "16/11/2026"), c("03/2011", "03/2011"),
    c("1/200 000", "1/200 000"), c("2019-11-22", "2019-11-22"), c("2022-01-13", "2022-01-13"),
    c("2024-12-20", "2024-12-20"), c("IGN_AUTO_V5", "IGN_AUTO_V5"),
    c("22LHDVosgesRF", "22LHDVosgesRF"), c("1015-6794", "1015-6794"),
    c("https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip",
      "https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip"),
    c("https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip",
      "https://inventaire-forestier.ign.fr/dataifn/data/export_dataifn_2005_2025.zip"),
    c("GEO050K_HARM_088.zip", "GEO050K_HARM_067.zip"),
    c("https://services.sandre.eaufrance.fr/geo/topage2025",
      "https://services.sandre.eaufrance.fr/geo/topage2025"),
    c("https://assets.patrinat.fr/files/referentiel/TAXREF_v18_2025.zip",
      "https://assets.patrinat.fr/files/referentiel/TAXREF_v18_2025.zip"),
    c("10.5281/zenodo.7427088", "10.5281/zenodo.7427088"), c("2022-11-07", "2022-11-07"),
    c("NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz",
      "NUALHD_1-0__LAZ_LAMB93_RF_2024-12-20/LHD_FXX_1015_6794_PTS_LAMB93_IGN69.copc.laz"),
    c("Aucune condition ne s'applique", "Aucune condition ne s'applique"),
    c("Licence Ouverte Etalab 2.0", "Licence Ouverte Etalab 2.0"), c("CC BY 4.0", "CC BY 4.0"),
    c("Source : Météo-France", "Source : Météo-France"), c("Julve", "Julve"))
  for (v in dans_sources) {
    expect_true(grepl(v[1], q, fixed = TRUE), info = paste("absent du gabarit :", v[1]))
    expect_true(grepl(v[2], src, fixed = TRUE), info = paste("absent de SOURCES.md :", v[2]))
  }

  # licences et période, lues dans docs/referentiels.md (absent du paquet installé)
  if (!is.null(ref)) {
    for (v in c("lov2", "fr-lo", "1996-2025", "CC BY-NC 4.0", "Source : Météo-France")) {
      expect_true(grepl(v, ref, fixed = TRUE), info = paste("absent de referentiels.md :", v))
    }
  }

  # valeurs provisoires du tableau des calculs : config.yml, telles qu'écrites en français
  if (!is.null(cfgt)) {
    cfg <- yaml::yaml.load(cfgt)
    fr <- function(x) sub(".", ",", format(x), fixed = TRUE)
    attendu <- c(
      paste0(cfg$lidar_block_size, " x ", cfg$lidar_block_size, " dalles"),
      paste0("tampon de ", cfg$lidar_buffer_m, " m"),
      paste0("seuil de ", cfg$forest_height_m, " m"),
      paste0("Linke ", fr(sprintf("%.1f", cfg$solar_linke))),
      paste0("albédo ", fr(cfg$solar_albedo)),
      paste0("pas de ", fr(cfg$solar_step_h), " h"),
      paste0("pas de k ", fr(cfg$hydric_pas_k)),
      paste0(cfg$hydric_n_controle, " cellules de contrôle"))
    for (a in attendu) {
      expect_true(grepl(a, q, fixed = TRUE), info = paste("config.yml, absent du gabarit :", a))
    }
    expect_equal(paste(cfg$safran_annees, collapse = "-"), "1996-2025")
  }

  # arbres des forêts aléatoires : 200 en démo, 500 en réel (_targets.R)
  if (!is.null(tgt)) {
    expect_true(grepl("num_trees = 200", tgt, fixed = TRUE))
    expect_true(grepl("num_trees = 500", tgt, fixed = TRUE))
    expect_true(grepl('if (synth) "200" else "500"', q, fixed = TRUE))
  }
})
