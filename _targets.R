# Pipeline sylvostation (missions 010 et 016), parametre par config.yml.
#
# Mode `demo: true` (config.yml) : tourne SANS RESEAU sur inst/extdata (jeux synth_*,
# synthetic = TRUE). Les resultats ne valent rien sur donnees reelles ; le rapport le
# dit (tableau « etat de preuve » et section « Limites »). Sorties : out_dir/<ser_code>/
# (sous data/, ignore par git).
# Mode reel (`demo: false`, mission 016) : a partir du seul code SER, telecharge (cache
# sous data/), calcule et ecrit le catalogue sans prefixe synth_. Avec `offline: true`,
# AUCUN appel reseau : les sources sont les extraits reels de inst/extdata (une dalle
# LiDAR, BD Charm-50, IFN, TOPAGE, TAXREF, Tichy, SAFRAN 12 mailles). Les entrees
# absentes (GNSS, reference AgroParisTech, sols) sont declarees dans l'etat de preuve,
# jamais remplacees. Voir docs/pipeline.md.
#
# Les fonctions sont appelees avec le prefixe `sylvostation::` (paquet installe ou
# charge par devtools::load_all()).

library(targets)

cfg <- sylvostation::read_config("config.yml")

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

# =====================================================================================
# Mode reel (mission 016)
# =====================================================================================
if (!isTRUE(cfg$demo)) {
  src <- sylvostation::real_sources(cfg)
  hors_ligne <- isTRUE(src$offline)
  cache <- cfg$cache_dir
  lidar_dir <- file.path(cfg$data_dir, "lidar")
  annees <- seq(cfg$safran_annees[1], cfg$safran_annees[2])
  mois_sv <- seq(cfg$saison_vegetation[1], cfg$saison_vegetation[2])
  greco <- substr(cfg$ser_code, 1, 1)
  grad_reg <- c("trophic", "hydric")  # modeles regionaux ; bioclim est calcule
  gbif_ok <- function() all(nzchar(Sys.getenv(c("GBIF_USER", "GBIF_PWD", "GBIF_EMAIL"))))

  pipeline <- list(
    # --- emprise, dalles LiDAR (branchement dynamique par blocs), terrain --------------
    tar_target(ser, sylvostation::get_ser(cfg$ser_code, buffer_m = cfg$buffer_m,
                                          source = src$ser$source, path = src$ser$path,
                                          data_dir = cache)),
    tar_target(emprise, sylvostation::real_extent(ser, cfg)),
    tar_target(tiles, {
      t <- if (hors_ligne) sylvostation::local_tiles(src$laz) else sylvostation::list_tiles(emprise)
      sylvostation::select_tiles(t, cfg$max_tiles)
    }),
    tar_target(tile_blocks, sylvostation::tile_blocks(tiles, cfg$lidar_block_size),
               iteration = "list"),
    # une branche par bloc de 3 x 3 dalles ; une dalle deja calculee n'est pas refaite
    tar_target(lidar_files, sylvostation::run_tile_block(
      tile_blocks, lidar_dir, buffer = cfg$lidar_buffer_m, ncores = cfg$lidar_ncores),
      pattern = map(tile_blocks), format = "file"),
    tar_target(dtm, sylvostation::mosaic_tiles(lidar_files, "mnt", fact = 5,
                                               tile_ids = tiles$tile_id)),
    tar_target(grid, sylvostation::real_grid(emprise, dtm, cfg$resolution_m)),
    tar_target(hydro, {
      b <- sf::st_bbox(terra::ext(grid) + 1000, crs = sf::st_crs(2154))
      sylvostation::get_hydro_network(b, source = src$hydro$source, path = src$hydro$path)
    }),
    tar_target(terrain, sylvostation::real_terrain(dtm, grid, streams = hydro, mrvbf = TRUE)),
    tar_target(forest, if (isTRUE(cfg$forest_mask)) {
      sylvostation::forest_mask(lidar_files, grid, height = cfg$forest_height_m)
    } else NULL),

    # --- geologie BD Charm-50 ----------------------------------------------------------
    tar_target(geol_sf, sylvostation::read_geology(
      if (hors_ligne) src$geol$paths else
        vapply(src$geol$urls, sylvostation::fetch_cached, "", dir = file.path(cache, "bdcharm")),
      emprise = sf::st_bbox(terra::ext(grid) + 1000, crs = sf::st_crs(2154)))),
    # emprise: ser : la SER peut deborder des departements BD Charm-50 lus (avertissement)
    tar_target(geol_coverage, if (identical(cfg$emprise, "ser")) {
      sylvostation::geology_coverage(geol_sf, emprise, cfg$bdcharm_departements)
    } else NA_real_),
    tar_target(geol_classes, suppressWarnings(
      sylvostation::recode_lithology(sylvostation::list_formations(geol_sf)))),
    tar_target(geol_rast, sylvostation::rasterize_geol(geol_sf, grid, "classe", table = geol_classes)),
    tar_target(geol_dom, sylvostation::dominant_lithology(geol_rast, radius = cfg$ifn_precision_m)),

    # --- placettes IFN de la GRECO, valeurs indicatrices, climat SAFRAN ---------------
    tar_target(ifn, sylvostation::filter_releves(sylvostation::filter_greco(
      sylvostation::load_ifn(if (hors_ligne) src$ifn_dir else
        sylvostation::fetch_ifn(src$ifn_url, cache), precision_m = cfg$ifn_precision_m),
      greco))),
    tar_target(taxref, sylvostation::read_taxref(
      if (hors_ligne) src$taxref else sylvostation::fetch_cached(src$taxref, cache))),
    tar_target(indicateurs, sylvostation::load_indicator_values(
      "tichy", src$tichy, taxref, taxa = unique(ifn$flore$CD_REF))),
    tar_target(indicateurs_noms, sylvostation::load_indicator_values("tichy", src$tichy, taxref)),
    tar_target(safran, sylvostation::read_safran(
      if (hors_ligne) src$safran else {
        b <- sf::st_bbox(sf::st_union(c(sf::st_as_sfc(sf::st_bbox(ifn$placettes)),
                                       sf::st_as_sfc(sf::st_bbox(emprise)))))
        sylvostation::fetch_safran(annees, b, file.path(cache, "safran"))
      })),
    tar_target(climat, sylvostation::safran_climate(safran, months = mois_sv)),
    # gradients des placettes : maille large seulement (regle des 700 m)
    tar_target(ifn_gradients, sylvostation::ifn_real_gradients(
      ifn, indicateurs, climat, safran, ru_source = cfg$ru_source, annees = annees)),

    # --- carte hydrique de 25 m (mission 021) : k r.sun, RU par maille, BILJOU --------
    # k = rayonnement r.sun (ciel clair) de la pente / plat ; variable fine, grille seule
    tar_target(solar_k, {
      k <- sylvostation::solar_factor(terrain[["altitude"]], linke = cfg$solar_linke,
                                      albedo = cfg$solar_albedo, step = cfg$solar_step_h,
                                      nprocs = cfg$lidar_ncores)
      list(k = k, methode = attr(k, "methode"), repli = attr(k, "repli"))
    }),
    # RU uniforme par maille SAFRAN (provisoire) : mediane euptf2 des placettes IFN
    tar_target(ru_mailles, sylvostation::ru_by_safran_cell(
      ifn_gradients, safran, emprise = sf::st_bbox(terra::ext(grid), crs = sf::st_crs(2154)))),
    tar_target(hydric_grid, {
      h <- sylvostation::hydric_stress_grid(
        solar_k$k, ru_mailles, safran, altitude = terrain[["altitude"]], annees = annees,
        pas_k = cfg$hydric_pas_k, n_controle = cfg$hydric_n_controle, k_methode = solar_k$methode)
      list(r = h, methode = attr(h, "methode"), ecart = attr(h, "ecart"),
           mailles = attr(h, "mailles"), repli = attr(h, "repli"))
    }),

    # --- predicteurs, ancrages GBIF (en ligne), modeles ---------------------------------
    tar_target(soils, if (is.null(src$soils)) NULL else
      sylvostation::stack_soil_layers(src$soils, grid)),
    tar_target(predictors, {
      p <- sylvostation::coarse_predictors(climat, grid)
      fines <- setdiff(names(terrain), sylvostation::empty_layers(terrain))
      out <- c(p, terrain[[fines]])
      if (!is.null(soils)) out <- c(out, soils)
      out
    }),
    tar_target(coarse_vars, intersect(names(predictors), c("coarse_p_etp_sv", "coarse_t_moy"))),
    tar_target(anchors, if (hors_ligne) NULL else {
      occ <- sylvostation::get_gbif(emprise, method = if (cfg$gbif_method == "download" && gbif_ok())
        "download" else "search", path = file.path(cache, "gbif"))
      chm <- sylvostation::mosaic_tiles(lidar_files, "mhc", fact = 5)
      cl <- sylvostation::clean_occ(occ, canopy = chm)
      sylvostation::gbif_anchors(sylvostation::grid_bioindication(cl, indicateurs_noms), cl,
                                 predictors)
    }),
    tar_target(train, stats::setNames(lapply(grad_reg, function(g) {
      d <- ifn_gradients[!is.na(ifn_gradients[[g]]), ]
      d[stats::complete.cases(sf::st_drop_geometry(d)[, coarse_vars, drop = FALSE]), ]
    }), grad_reg)),
    tar_target(models, stats::setNames(lapply(grad_reg, function(g) {
      sylvostation::fit_gradient(train[[g]], g, coarse_vars, points_source = "ifn",
                                 ifn_precision_m = cfg$ifn_precision_m, num_trees = 500, seed = 1)
    }), grad_reg)),
    tar_target(cvs, stats::setNames(lapply(grad_reg, function(g) {
      sylvostation::spatial_cv(train[[g]], g, coarse_vars, k = 5, points_source = "ifn",
                               ifn_precision_m = cfg$ifn_precision_m, num_trees = 500, seed = 1)
    }), grad_reg)),
    # composante locale (en ligne seulement) : trophique sur les ancrages GBIF
    tar_target(local_trophic, {
      if (is.null(anchors)) return(NULL)
      v <- setdiff(names(predictors), character(0))
      d <- anchors[stats::complete.cases(sf::st_drop_geometry(anchors)[, c("trophic", v)]), ]
      if (nrow(d) < 20) return(NULL)
      list(model = sylvostation::fit_gradient(d, "trophic", v, num_trees = 500, seed = 1),
           cv = sylvostation::spatial_cv(d, "trophic", v, k = 5, num_trees = 500, seed = 1))
    }),
    tar_target(maps, {
      m <- stats::setNames(lapply(grad_reg, function(g) {
        sylvostation::predict_raster(models[[g]], predictors, cv = cvs[[g]])
      }), grad_reg)
      if (!is.null(local_trophic)) {
        m$trophic <- sylvostation::predict_raster(local_trophic$model, predictors,
                                                  cv = local_trophic$cv)
      }
      m
    }),
    tar_target(gradient_map, {
      b <- sylvostation::apply_bioclim(predictors, attr(ifn_gradients, "bioclim_axis"))
      # hydrique : -Istress de 25 m calcule (mission 021) ; le modele regional hydrique
      # (placettes IFN) ne sert qu'a la validation croisee
      r <- c(maps$trophic[["pred"]], hydric_grid$r[["grad_hydrique"]], b)
      names(r) <- c("trophic", "hydric", "bioclim")
      if (!is.null(forest)) r <- terra::mask(r, forest[["foret"]])
      r
    }),
    # incertitude des cartes modelisees : trophique seul (la carte hydrique est calculee,
    # l'incertitude du modele regional hydrique ne la decrit pas)
    tar_target(uncertainty, {
      r <- do.call(c, lapply("trophic", function(g) {
        nm <- intersect(c("sd_cv", "aoa"), names(maps[[g]]))
        x <- maps[[g]][[nm]]
        names(x) <- paste0(nm, "_", g)
        x
      }))
      if (!is.null(forest)) r <- terra::mask(r, forest[["foret"]])
      r
    }),

    # --- typologie, caracterisation, cle ------------------------------------------------
    tar_target(cells, terra::as.data.frame(gradient_map, cells = TRUE, na.rm = TRUE)),
    tar_target(thresholds, sylvostation::default_thresholds(cells[, grad])),
    tar_target(cell_types, sylvostation::discretise(cells[, grad], thresholds)),
    tar_target(plot_types, {
      d <- sf::st_drop_geometry(ifn_gradients)
      t <- sylvostation::discretise(d[, grad], thresholds)
      data.frame(id_placette = d$id_placette, type = t$type, stringsAsFactors = FALSE)
    }),
    tar_target(merged, {
      p <- plot_types$type
      p[!p %in% cell_types$type] <- NA  # placettes d'un type absent de la carte
      sylvostation::merge_rare(cell_types, plots = p)
    }),
    tar_target(type_map, sylvostation::type_raster(gradient_map[[1]], cells$cell, merged$type)),
    tar_target(type_legend, sylvostation::real_type_legend(type_map$legend)),
    tar_target(plot_types_final, {
      t <- sylvostation::apply_merges(plot_types$type, attr(merged, "merges"))
      t[!t %in% type_legend$type] <- NA
      data.frame(id_placette = plot_types$id_placette, type = t, stringsAsFactors = FALSE)
    }),
    tar_target(type_table, {
      id <- type_map$raster
      f <- terra::freq(id)
      out <- type_legend
      out$area_ha <- as.numeric(f[, "count"])[match(out$id, f[, "value"])] * prod(terra::res(id)) / 1e4
      out$part_surface <- out$area_ha / sum(out$area_ha)
      moy <- stats::aggregate(cells[, grad], list(type = merged$type), mean)
      out <- merge(out, moy, by = "type", sort = FALSE)
      out$n_placettes <- as.integer(table(factor(plot_types_final$type, out$type)))
      out[order(out$id), ]
    }),
    tar_target(typed_plots, plot_types_final[!is.na(plot_types_final$type), ]),
    tar_target(indicator, if (length(unique(typed_plots$type)) < 2) {
      data.frame(species = character(), type = character(), A = numeric(), B = numeric(),
                 indval = numeric(), p_value = numeric())
    } else
      sylvostation::indicator_species(
        sylvostation::ifn_flora_matrix(ifn$flore, typed_plots$id_placette),
        typed_plots$type, nperm = 99)),
    tar_target(fertility, sylvostation::real_fertility(
      sylvostation::ifn_trees(ifn$arbre),
      data.frame(plot = typed_plots$id_placette, type = typed_plots$type))),
    tar_target(key, {
      d <- sylvostation::ifn_observables(ifn$placettes)
      d$type <- typed_plots$type[match(d$id_placette, typed_plots$id_placette)]
      d <- d[!is.na(d$type), ]
      if (length(unique(d$type)) < 2) NULL else
        sylvostation::build_key(d, c("obs_pente", "obs_topo", "obs_humus"), maxdepth = 5)
    }),
    tar_target(key_lines, if (is.null(key)) data.frame(ligne = character()) else
      data.frame(ligne = utils::capture.output(print(key)))),
    tar_target(key_summary, if (is.null(key)) data.frame(
      accord_ajuste = NA_real_, accord_validation_croisee = NA_real_, seuil = 0.7,
      atteint = NA, profondeur = NA_integer_,
      motif = "moins de deux types parmi les placettes : cl\u00e9 non construite") else data.frame(
      accord_ajuste = key$accuracy, accord_validation_croisee = key$accuracy_cv,
      seuil = key$min_accuracy, atteint = key$meets_target, profondeur = key$depth)),

    # --- validation ---------------------------------------------------------------------
    tar_target(val_stats, {
      v <- sylvostation::validate_stats(cvs)
      if (!is.null(local_trophic)) {
        l <- sylvostation::validate_stats(list(trophic = local_trophic$cv))
        l$gradient <- "trophic (local, ancrages GBIF)"
        v <- rbind(v, l)
      }
      v
    }),
    tar_target(gnss_validation, if (is.null(src$gnss)) NULL else {
      g <- sylvostation::gnss_field_gradients(sylvostation::load_gnss(src$gnss), indicateurs_noms,
                                              predictors, attr(ifn_gradients, "bioclim_axis"))
      xy <- sf::st_coordinates(g)  # x = est, y = nord
      pm <- terra::extract(gradient_map[[c("trophic", "bioclim")]], xy)
      th <- thresholds[c("trophic", "bioclim")]
      v <- sylvostation::validate_maps(
        sylvostation::discretise(pm, th)$type,
        sylvostation::discretise(sf::st_drop_geometry(g)[, c("trophic", "bioclim")], th)$type)
      data.frame(n = v$n, kappa = v$kappa, accord_exact = v$accord_exact,
                 accord_une_classe = v$accord_une_classe,
                 axes = "trophique et bioclimatique (hydrique : \u00e9chelles non raccord\u00e9es)")
    }),

    # --- sorties ------------------------------------------------------------------------
    tar_target(evidence, sylvostation::evidence_table_real(list(
      offline = hors_ligne, ser_code = cfg$ser_code, n_tiles = nrow(tiles),
      n_ifn = nrow(ifn$placettes), greco = greco,
      mrvbf = !"mrvbf" %in% sylvostation::empty_layers(terrain), hydro_n = nrow(hydro),
      empty_layers = sylvostation::empty_layers(terrain),
      methode_hydrique = attr(ifn_gradients, "methode_hydrique"),
      n_gbif = if (is.null(anchors)) NA else nrow(anchors), soils = !is.null(soils),
      forest_mask = !is.null(forest), n_cells = nrow(cells), n_types = nrow(type_legend),
      key = !is.null(key), gnss = !is.null(gnss_validation), reference = !is.null(src$reference),
      taxref_version = cfg$taxref_version,
      safran_annees = paste(range(as.integer(substr(safran$DATE, 1, 4))), collapse = "-"),
      methode_hydrique_carte = hydric_grid$methode, k_methode = solar_k$methode,
      ru_origine = paste(sprintf("%s : %s mm, %s", ru_mailles$maille, round(ru_mailles$ru_mm),
                                 ru_mailles$origine), collapse = " ; "),
      n_controle = if (NROW(hydric_grid$ecart)) sum(hydric_grid$ecart$n_controle) else NA,
      ecart_moyen_abs = if (NROW(hydric_grid$ecart)) {
        stats::weighted.mean(hydric_grid$ecart$ecart_moyen_abs, hydric_grid$ecart$n_controle)
      } else NA,
      ecart_max_abs = if (NROW(hydric_grid$ecart)) max(hydric_grid$ecart$ecart_max_abs) else NA))),
    tar_target(outputs, {
      tabs <- list(types = type_table, especes_indicatrices = indicator, fertilite = fertility,
                   cle_terrain = key_lines, cle_resume = key_summary,
                   validation_stats = val_stats,
                   fusions_types = attr(merged, "merges"),
                   taxons_non_apparies = attr(indicateurs, "non_apparies"),
                   geologie_dominante = terra::freq(geol_dom))
      if (!is.null(gnss_validation)) tabs$validation_gnss <- gnss_validation
      if (!is.null(comparison_table)) {
        tabs$comparaison_gradients <- comparison_table
      }
      # carte hydrique de 25 m (mission 021) : ecart table / calcul direct, RU par maille
      if (NROW(hydric_grid$ecart)) tabs$hydrique_ecart_table <- hydric_grid$ecart
      tabs$hydrique_mailles <- if (is.null(hydric_grid$mailles)) ru_mailles else
        merge(ru_mailles, hydric_grid$mailles, by = "maille", all.x = TRUE)
      w <- sylvostation::write_outputs(
        out_dir = cfg$out_dir, ser_code = cfg$ser_code,
        types = type_map$raster, type_legend = type_legend,
        gradients = gradient_map, uncertainty = uncertainty,
        tables = tabs, evidence = evidence, synthetic = FALSE)
      # table attributaire jointe aux polygones (EPSG:2154), sans couche sans geometrie
      sylvostation::write_types_gpkg_real(w$fichier[basename(w$fichier) == "types.gpkg"], type_table)
      # couches de la carte hydrique (Istress de la pente et du plat, k_sv, RU de la maille)
      h <- hydric_grid$r[[c("is_topo", "nj_topo", "is_plat", "k_sv", "ru_maille")]]
      if (!is.null(forest)) h <- terra::mask(h, forest[["foret"]])
      fh <- file.path(cfg$out_dir, cfg$ser_code, "hydrique_25m.tif")
      terra::writeRaster(h, fh, overwrite = TRUE)
      c(w$fichier, fh)
    }, format = "file"),
    # comparaison a la reference : seulement si reference_path est fourni
    tar_target(comparison_table, if (is.null(src$reference)) NULL else {
      cmp <- sylvostation::compare_gradients(gradient_map,
                                             sylvostation::load_reference(src$reference), res = 50)
      cmp$correlation
    })
  )
}

# Rapport Quarto : seulement si le CLI Quarto est disponible.
if (requireNamespace("quarto", quietly = TRUE) && !is.null(quarto::quarto_path())) {
  pipeline <- c(pipeline, list(
    tar_target(rapport, {
      outputs  # dependance : les fichiers doivent exister
      dossier <- file.path(cfg$out_dir, cfg$ser_code)
      qmd <- file.path(dossier, "rapport.qmd")
      file.copy(rapport_modele(), qmd, overwrite = TRUE)
      quarto::quarto_render(qmd, execute_params = list(
        dossier = normalizePath(dossier), prefixe = if (isTRUE(cfg$demo)) "synth_" else "",
        ser_code = cfg$ser_code, hors_ligne = isTRUE(cfg$offline)),
        quiet = TRUE)
      file.path(dossier, "rapport.html")
    }, format = "file")
  ))
}

pipeline
