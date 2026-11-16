# Contrat d'interface : le pipeline `targets` s'exécute de bout en bout en mode démo
# (jeux synthétiques de inst/extdata, sans réseau). Ne prouve rien sur données réelles.

test_that("le pipeline démo s'exécute de bout en bout et écrit des sorties synthétiques", {
  skip_on_cran()
  skip_if_not_installed("targets")
  for (p in c("ranger", "CAST", "rpart", "indicspecies", "mgcv")) skip_if_not_installed(p)
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")) &&
                file.exists(file.path(racine, "config.yml")),
              "_targets.R et config.yml absents (paquet installé)")
  racine <- normalizePath(racine)

  targets::tar_dir({
    file.copy(file.path(racine, c("_targets.R", "config.yml")), ".")
    cfg <- read_config("config.yml")
    expect_true(cfg$demo)

    # callr_function = NULL : le pipeline tourne dans cette session (paquet chargé par
    # devtools::load_all ou installé), pas dans un sous-processus.
    targets::tar_make(callr_function = NULL, reporter = "silent")
    prog <- targets::tar_progress()
    expect_true(all(prog$progress == "completed"), info = paste(prog$name[prog$progress != "completed"], collapse = ", "))
    expect_gte(nrow(prog), 30)
    expect_null(tryCatch(targets::tar_validate(callr_function = NULL), error = function(e) e$message))

    d <- file.path(cfg$out_dir, cfg$ser_code)
    fichiers <- list.files(d)
    # tout fichier de sortie des données est préfixé synth_ (le rapport et son modèle sont des documents)
    donnees <- setdiff(fichiers, c("rapport.html", "rapport.qmd"))
    expect_true(all(startsWith(donnees, "synth_")))
    for (f in c("synth_types.tif", "synth_gradients.tif", "synth_incertitude.tif",
                "synth_types.gpkg", "synth_types.csv", "synth_etat_de_preuve.csv",
                "synth_validation_stats.csv", "synth_cle_terrain.csv")) {
      expect_true(f %in% fichiers, info = f)
    }

    # Grille en Lambert-93, origine multiple de 50 m, et un point connu dans la bonne cellule.
    ty <- terra::rast(file.path(d, "synth_types.tif"))
    expect_error(assert_crs_2154(ty), NA)
    expect_equal(terra::xmin(ty) %% 50, 0)
    expect_equal(terra::ymin(ty) %% 50, 0)
    expect_equal(terra::res(ty), c(cfg$resolution_m, cfg$resolution_m))
    cel <- terra::cellFromXY(ty, cbind(cfg$emprise_test$xmin + 1010, cfg$emprise_test$ymin + 40))
    # 1010 m à l'est : colonne 41 ; 40 m au nord du bord sud (2 500 m de haut) : ligne 100 - 1
    expect_equal(unname(terra::rowColFromCell(ty, cel)), cbind(99, 41))

    # L'état de preuve est écrit, et rien n'est « réel » complet.
    ep <- utils::read.delim(file.path(d, "synth_etat_de_preuve.csv"), sep = ";",
                            encoding = "UTF-8")
    expect_true(all(c("réel réduit", "synthétique") %in% ep$etat))
    expect_false("réel" %in% ep$etat)

    # La règle bloquante est passée : les placettes IFN n'ont reçu que du climat à maille large.
    ig <- targets::tar_read(ifn_gradients)
    expect_true(all(ig$loc_precision_m == cfg$ifn_precision_m))
    expect_true(all(c("coarse_p_etp_sv", "coarse_t_moy") %in% names(ig)))
    expect_false(any(names(ig) %in% c("pente", "twi", "tpi_300", "mnt")))

    # Validation : les trois gradients, repères du brief
    vs <- utils::read.delim(file.path(d, "synth_validation_stats.csv"), sep = ";")
    expect_equal(vs$gradient, c("trophic", "hydric", "bioclim"))
    expect_equal(vs$r2_repere, c(0.36, 0.43, 0.52))
    expect_true(all(vs$synthetic))

    # Rapport Quarto (seulement si le CLI est disponible)
    if (requireNamespace("quarto", quietly = TRUE) && !is.null(quarto::quarto_path())) {
      expect_true("rapport.html" %in% fichiers)
      html <- paste(readLines(file.path(d, "rapport.html"), warn = FALSE), collapse = "\n")
      expect_match(html, "DONNÉES SYNTHÉTIQUES", fixed = TRUE)
      expect_match(html, "non atteints", fixed = TRUE)
      expect_match(html, "Limites", fixed = TRUE)
      expect_match(html, "tat de preuve", fixed = TRUE)
    }

    # Relancer ne refait rien (cache de targets)
    targets::tar_make(callr_function = NULL, reporter = "silent")
    expect_true(all(targets::tar_progress()$progress == "skipped"))
  })
})

test_that("le mode réel non branché s'arrête avec un message clair", {
  skip_on_cran()
  skip_if_not_installed("targets")
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")), "_targets.R absent")
  racine <- normalizePath(racine)
  targets::tar_dir({
    file.copy(file.path(racine, "_targets.R"), ".")
    cfg <- readLines(file.path(racine, "config.yml"))
    writeLines(sub("^demo: true", "demo: false", cfg), "config.yml")
    expect_error(source("_targets.R"), "Mode réel non branché")
  })
})
