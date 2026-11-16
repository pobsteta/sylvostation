# Pipeline sylvostation (mission 010), parametre par config.yml.
#
# Mode `demo: true` (config.yml) : tourne SANS RESEAU sur inst/extdata (jeux synth_*,
# synthetic = TRUE). Les resultats ne valent rien sur donnees reelles ; le rapport le
# dit (tableau « etat de preuve » et section « Limites »). Sorties : out_dir/<ser_code>/
# (sous data/, ignore par git).
# Mode reel (demo: false) : NON BRANCHE dans cette mission (telechargements SER/LiDAR/
# BD Charm-50, ancrage de la mission 007 integre au paquet mais non branche) : le script s'arrete avec un message.
#
# Les fonctions sont appelees avec le prefixe `sylvostation::` (paquet installe ou
# charge par devtools::load_all()).

library(targets)

cfg <- sylvostation::read_config("config.yml")
if (!isTRUE(cfg$demo)) {
  stop("Mode réel non branché (mission 010) : mettre `demo: true` dans config.yml. ",
       "À brancher : get_ser (téléchargement), list_tiles/run_lasr (LiDAR HD), ",
       "ancrage GBIF (mission 007).", call. = FALSE)
}

# Les SpatRaster ne se serialisent pas tels quels (pointeur externe) : tout objet cible
# est enregistre avec ses rasters « emballes » (terra::wrap), y compris dans les listes.
# Les fonctions du format sont autonomes (targets les execute hors de cet environnement).
tar_option_set(format = tar_format(
  read = function(path) {
    deb <- function(x) {
      if (inherits(x, "sylvo_emballe")) return(terra::unwrap(x$w))
      if (is.list(x) && !is.data.frame(x) && !inherits(x, "sf")) x[] <- lapply(x, deb)
      x
    }
    deb(readRDS(path))
  },
  write = function(object, path) {
    emb <- function(x) {
      # (suppressWarnings : une grille vide donne « raster has no values »)
      if (inherits(x, c("SpatRaster", "SpatVector"))) {
        return(structure(list(w = suppressWarnings(terra::wrap(x))), class = "sylvo_emballe"))
      }
      if (is.list(x) && !is.data.frame(x) && !inherits(x, "sf")) x[] <- lapply(x, emb)
      x
    }
    saveRDS(emb(object), path)
  },
  marshal = function(object) {
    emb <- function(x) {
      # (suppressWarnings : une grille vide donne « raster has no values »)
      if (inherits(x, c("SpatRaster", "SpatVector"))) {
        return(structure(list(w = suppressWarnings(terra::wrap(x))), class = "sylvo_emballe"))
      }
      if (is.list(x) && !is.data.frame(x) && !inherits(x, "sf")) x[] <- lapply(x, emb)
      x
    }
    emb(object)
  },
  unmarshal = function(object) {
    deb <- function(x) {
      if (inherits(x, "sylvo_emballe")) return(terra::unwrap(x$w))
      if (is.list(x) && !is.data.frame(x) && !inherits(x, "sf")) x[] <- lapply(x, deb)
      x
    }
    deb(object)
  }
))

extdata <- function(...) system.file("extdata", ..., package = "sylvostation")
rapport_modele <- function() system.file("rapport", "rapport.qmd", package = "sylvostation")

# Emprise de demonstration : carre de 2 500 m au sud-ouest de l'emprise test
# (x = est, y = nord, Lambert-93) ; 100 x 100 cellules de 25 m.
demo_emprise <- c(xmin = cfg$emprise_test$xmin, ymin = cfg$emprise_test$ymin,
                  xmax = cfg$emprise_test$xmin + 2500, ymax = cfg$emprise_test$ymin + 2500)
emprise_test <- c(cfg$emprise_test$xmin, cfg$emprise_test$ymin,
                  cfg$emprise_test$xmax, cfg$emprise_test$ymax)

# Prédicteurs de chaque gradient (fabriques : les gradients vrais synthetiques en dependent).
specs <- list(
  trophic = c("coarse_p_etp_sv", "pente", "tpi_300"),
  hydric  = c("twi", "pente", "tpi_300"),
  bioclim = c("mnt", "coarse_t_moy")
)
grad <- names(specs)

pipeline <- list(
  # --- emprise, terrain, climat (synthetiques sauf le contour SER) -------------------
  tar_target(ser, sylvostation::get_ser(cfg$ser_code, buffer_m = cfg$buffer_m,
                                        source = "file", path = extdata("ser_extrait.gpkg"))),
  # controle d'emprise : l'emprise test doit intersecter la SER du config
  tar_target(ser_check, {
    box <- sf::st_as_sfc(sf::st_bbox(c(xmin = emprise_test[1], ymin = emprise_test[2],
                                       xmax = emprise_test[3], ymax = emprise_test[4]),
                                     crs = sf::st_crs(2154)))
    if (!any(sf::st_intersects(box, ser, sparse = FALSE))) {
      stop("L'emprise test n'intersecte pas la SER ", cfg$ser_code, ".", call. = FALSE)
    }
    TRUE
  }),
  tar_target(grid, {
    ser_check
    sylvostation::build_grid(demo_emprise, cfg$resolution_m)
  }),
  tar_target(dtm, sylvostation::synth_demo_dtm(grid)),
  tar_target(terrain, suppressWarnings(sylvostation::derive_terrain(dtm, tpi_radii = c(100, 300)))),
  tar_target(climat, sylvostation::synth_demo_climat(emprise_test)),
  tar_target(predictors, sylvostation::demo_predictors(terrain, dtm, climat)),
  tar_target(truth, sylvostation::synth_demo_truth(predictors)),

  # --- geologie (extrait reel BD Charm-50 ; recodage provisoire non valide) ----------
  tar_target(geol_sf, sf::st_read(extdata("bdcharm50_emprise_test.gpkg"), quiet = TRUE)),
  tar_target(geol_classes, suppressWarnings(
    sylvostation::recode_lithology(sylvostation::list_formations(geol_sf)))),
  tar_target(geol_rast, sylvostation::rasterize_geol(geol_sf, grid, "classe", table = geol_classes)),
  # rayon = precision de localisation des placettes IFN (config.yml)
  tar_target(geol_dom, sylvostation::dominant_lithology(geol_rast, radius = cfg$ifn_precision_m)),

  # --- placettes IFN (100 placettes reelles) : maille large seulement ----------------
  tar_target(ifn, sylvostation::filter_releves(
    sylvostation::load_ifn(extdata(), precision_m = cfg$ifn_precision_m))),
  tar_target(indicateurs, utils::read.delim(extdata("synth_indicateurs.csv"), sep = ";")),
  tar_target(ifn_gradients, {
    g <- sylvostation::compute_gradients(ifn, indicateurs, climat)
    g <- g[!is.na(g$grad_trophique), ]  # placettes retenues avec flore
    g$synthetic <- TRUE  # valeurs indicatrices et climat synthetiques
    g
  }),
  tar_target(model_regional, sylvostation::fit_gradient(
    ifn_gradients, "grad_trophique", c("coarse_p_etp_sv", "coarse_t_moy"),
    points_source = "ifn", ifn_precision_m = cfg$ifn_precision_m, num_trees = 200, seed = 1)),
  tar_target(cv_regional, sylvostation::spatial_cv(
    ifn_gradients, "grad_trophique", c("coarse_p_etp_sv", "coarse_t_moy"),
    block_size = 3000, k = 5, points_source = "ifn", ifn_precision_m = cfg$ifn_precision_m,
    num_trees = 200, seed = 1)),

  # --- points d'ancrage et releves de terrain (synthetiques) -------------------------
  # ancrage : mission 007 (get_gbif, clean_occ, grid_bioindication, load_gnss) integrees au paquet, non branchees au pipeline demo.
  tar_target(anchors, sylvostation::synth_demo_points(predictors, truth, n = 300, seed = 11)),
  tar_target(field, sylvostation::synth_demo_points(predictors, truth, n = 40, noise_sd = 0.3,
                                                    seed = 12)),

  # --- modeles par gradient, validation croisee spatiale, prediction -----------------
  tar_target(models, stats::setNames(lapply(grad, function(g) {
    sylvostation::fit_gradient(anchors, g, specs[[g]], num_trees = 200, seed = 1)
  }), grad)),
  tar_target(cvs, stats::setNames(lapply(grad, function(g) {
    sylvostation::spatial_cv(anchors, g, specs[[g]], block_size = 500, k = 5,
                             num_trees = 200, seed = 1)
  }), grad)),
  tar_target(maps, stats::setNames(lapply(grad, function(g) {
    sylvostation::predict_raster(models[[g]], predictors, cv = cvs[[g]])
  }), grad)),
  tar_target(gradient_map, {
    r <- do.call(c, lapply(grad, function(g) maps[[g]][["pred"]]))
    names(r) <- grad
    r
  }),
  tar_target(uncertainty, {
    r <- do.call(c, lapply(grad, function(g) {
      nm <- intersect(c("sd_cv", "aoa"), names(maps[[g]]))
      x <- maps[[g]][[nm]]
      names(x) <- paste0(nm, "_", g)
      x
    }))
    r
  }),

  # --- typologie, caracterisation, cle -----------------------------------------------
  tar_target(cells, terra::as.data.frame(gradient_map, cells = TRUE, na.rm = TRUE)),
  tar_target(thresholds, sylvostation::default_thresholds(cells[, grad])),
  tar_target(cell_types, sylvostation::discretise(cells[, grad], thresholds)),
  tar_target(anchor_types, sylvostation::discretise(sf::st_drop_geometry(anchors)[, grad],
                                                    thresholds)),
  tar_target(merged, sylvostation::merge_rare(cell_types, plots = anchor_types$type)),
  tar_target(type_map, sylvostation::type_raster(gradient_map[[1]], cells$cell, merged$type)),
  tar_target(type_table, {
    leg <- type_map$legend
    id <- type_map$raster
    area_ha <- as.numeric(terra::freq(id)[, "count"])[match(leg$id, terra::freq(id)[, "value"])] *
      prod(terra::res(id)) / 1e4
    moy <- stats::aggregate(cells[, grad], list(type = merged$type), mean)
    out <- cbind(leg, area_ha = area_ha)
    out$part_surface <- out$area_ha / sum(out$area_ha)
    out <- merge(out, moy, by = "type", sort = FALSE)
    out$n_ancrages <- as.integer(table(factor(attr(merged, "plots"), out$type)))
    out$synthetic <- TRUE
    out[order(out$id), ]
  }),
  tar_target(anchor_types_final, sylvostation::apply_merges(anchor_types$type,
                                                            attr(merged, "merges"))),
  tar_target(biotic, sylvostation::synth_demo_biotic(anchor_types_final)),
  tar_target(indicator, sylvostation::indicator_species(biotic$flore, anchor_types_final,
                                                        nperm = 99)),
  tar_target(fertility, sylvostation::fertility_by_type(biotic$arbres, biotic$plot_types)),
  tar_target(key, {
    d <- sf::st_drop_geometry(anchors)[, c("pente_obs", "humus", "position")]
    d$type <- anchor_types_final
    sylvostation::build_key(d, c("pente_obs", "humus", "position"), maxdepth = 5)
  }),
  tar_target(key_lines, data.frame(ligne = utils::capture.output(print(key)))),
  tar_target(key_summary, data.frame(
    accord_ajuste = key$accuracy, accord_validation_croisee = key$accuracy_cv,
    seuil = key$min_accuracy, atteint = key$meets_target, profondeur = key$depth,
    synthetic = TRUE)),

  # --- validation (jeux synthetiques) ------------------------------------------------
  tar_target(val_stats, sylvostation::validate_stats(cvs, synthetic = TRUE)),
  tar_target(val_regional, sylvostation::validate_stats(list(trophic = cv_regional),
                                                        synthetic = TRUE)),
  tar_target(val_maps, {
    fg <- sf::st_drop_geometry(field)[, grad]
    ft <- sylvostation::apply_merges(sylvostation::discretise(fg, thresholds)$type,
                                     attr(merged, "merges"))
    xy <- sf::st_coordinates(field)  # x = est, y = nord
    id <- terra::extract(type_map$raster, xy)[, 1]
    pt <- type_map$legend$type[match(id, type_map$legend$id)]
    v <- sylvostation::validate_maps(pt, ft)
    list(accord = data.frame(n = v$n, kappa = v$kappa, accord_exact = v$accord_exact,
                             accord_une_classe = v$accord_une_classe, synthetic = TRUE),
         confusion = as.data.frame(v$confusion), par_axe = v$par_axe)
  }),

  # --- comparaison a la reference (synthetique) --------------------------------------
  tar_target(reference, sylvostation::load_reference(extdata("synth_reference.tif"))),
  tar_target(comparison, sylvostation::compare_gradients(gradient_map, reference, res = 50)),
  tar_target(comparison_types, {
    refv <- terra::as.data.frame(comparison$ref, cells = TRUE, na.rm = TRUE)
    ov <- terra::as.data.frame(comparison$ours, cells = TRUE, na.rm = TRUE)
    commun <- intersect(ov$cell, refv$cell)
    ov <- ov[match(commun, ov$cell), grad, drop = FALSE]
    refv <- refv[match(commun, refv$cell), grad, drop = FALSE]
    # seuils de la reference : synthetiques ici (a obtenir de l'article, a verifier)
    th_ref <- sylvostation::default_thresholds(
      refv, n_classes = c(trophic = 6L, bioclim = 5L, hydric = 4L))
    v <- sylvostation::validate_maps(sylvostation::recode_3digits(ov, th_ref)$code3,
                                     sylvostation::recode_3digits(refv, th_ref)$code3)
    data.frame(n = v$n, kappa = v$kappa, accord_exact = v$accord_exact,
               accord_une_classe = v$accord_une_classe, synthetic = TRUE)
  }),
  tar_target(comparison_table, {
    out <- comparison$correlation
    out$synthetic <- TRUE
    out
  }),

  # --- sorties -----------------------------------------------------------------------
  tar_target(evidence, sylvostation::evidence_table(n_ifn = nrow(ifn$placettes))),
  tar_target(outputs, {
    w <- sylvostation::write_outputs(
      out_dir = cfg$out_dir, ser_code = cfg$ser_code,
      types = type_map$raster, type_legend = type_map$legend,
      gradients = gradient_map, uncertainty = uncertainty,
      tables = list(types = type_table, especes_indicatrices = indicator,
                    fertilite = fertility, cle_terrain = key_lines,
                    cle_resume = key_summary, validation_stats = val_stats,
                    validation_regional_ifn = val_regional,
                    validation_cartes = val_maps$accord,
                    validation_confusion = val_maps$confusion,
                    validation_par_axe = if (is.null(val_maps$par_axe)) data.frame() else val_maps$par_axe,
                    comparaison_gradients = comparison_table,
                    comparaison_types_3chiffres = comparison_types,
                    geologie_dominante = {
                      f <- terra::freq(geol_dom)
                      f$synthetic <- FALSE
                      f
                    }),
      evidence = evidence, synthetic = TRUE)
    w$fichier
  }, format = "file")
)

# Rapport Quarto : seulement si le CLI Quarto est disponible.
if (requireNamespace("quarto", quietly = TRUE) && !is.null(quarto::quarto_path())) {
  pipeline <- c(pipeline, list(
    tar_target(rapport, {
      outputs  # dependance : les fichiers doivent exister
      dossier <- file.path(cfg$out_dir, cfg$ser_code)
      qmd <- file.path(dossier, "rapport.qmd")
      file.copy(rapport_modele(), qmd, overwrite = TRUE)
      quarto::quarto_render(qmd, execute_params = list(
        dossier = normalizePath(dossier), prefixe = "synth_", ser_code = cfg$ser_code),
        quiet = TRUE)
      file.path(dossier, "rapport.html")
    }, format = "file")
  ))
}

pipeline
