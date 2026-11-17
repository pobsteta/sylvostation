# Mission 017 : tests d'acceptation du mode réel (`demo: false`), écrits SANS lire le code
# de la mission 016 (R/pipeline_reel.R, _targets.R non lus). Sources :
#  - docs/brief-technique.md § 7 (lignes 236-243) : critères d'acceptation ;
#  - docs/spec.md (« Critères d'acceptation », état de preuve, objection B1) ;
#  - pilotage/missions/016-mode-reel.md (clés `gnss_path`, `reference_path`, `max_tiles`,
#    entrées absentes signalées dans l'état de preuve) et 017 (cas à couvrir) ;
#  - CLAUDE.md (« Règles métier » : synth_, EPSG:2154, règle 700 m / 25 m) ;
#  - man/evidence_table.Rd (colonnes etape, etat, dans_ce_run, detail), man/write_outputs.Rd.
#
# SAUT PROPRE : tant que le mode réel n'est pas branché (la source de _targets.R avec
# demo: false lève encore « Mode réel non branché »), les tests qui dépendent d'une
# exécution réelle sont SAUTÉS, pas verts : un saut ne prouve rien.
#
# Boîte noire : on lance le pipeline en mode réel dans un dossier temporaire, avec
# max_tiles = 1 (option décrite en 016) et SANS gnss_path ni reference_path, puis on
# inspecte out_dir/<ser_code>/. Réseau : ces tests ne téléchargent rien eux-mêmes ; si le
# mode réel exige le réseau, définir SYLVOSTATION_REEL_DIR vers un dossier de travail déjà
# produit (contenant config.yml et le magasin `_targets`) : il est alors seulement relu.
#
# Non couvert : mécanisme de simulation des téléchargements de 016 (inconnu) ; noms exacts
# des cibles et colonnes des tables de types (inconnus : recherche par motifs) ; surface
# « forestière » (pas de masque forestier connu : on compte les cellules non NA du raster
# des types) ; chemin gnss_path / reference_path fourni mais fichier inexistant.

TXT_GNSS_ABSENT <- "non atteint (entrée absente)"   # fiche 017, « Cas à couvrir »

.reel <- new.env()

# Lance (une fois) le pipeline réel ; renvoie list(dir, cfg) ou saute le test.
reel_run <- function() {
  if (!is.null(.reel$res)) return(.reel$res)
  skip_on_cran()
  skip_if_not_installed("targets")
  pre <- Sys.getenv("SYLVOSTATION_REEL_DIR", "")
  if (nzchar(pre)) {
    skip_if_not(file.exists(file.path(pre, "config.yml")), "SYLVOSTATION_REEL_DIR sans config.yml")
    .reel$res <- list(dir = normalizePath(pre), cfg = read_config(file.path(pre, "config.yml")))
    return(.reel$res)
  }
  racine <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(racine, "_targets.R")) &&
                file.exists(file.path(racine, "config.yml")),
              "_targets.R et config.yml absents (paquet installé)")
  racine <- normalizePath(racine)
  d <- tempfile("reel_")
  dir.create(d)
  file.copy(file.path(racine, c("_targets.R", "config.yml")), d)
  cfg_txt <- readLines(file.path(d, "config.yml"), encoding = "UTF-8")
  cfg_txt <- sub("^demo: true", "demo: false", cfg_txt)
  # entrées optionnelles absentes : on retire toute clé gnss_path / reference_path
  cfg_txt <- cfg_txt[!grepl("^(gnss_path|reference_path|max_tiles):", cfg_txt)]
  writeLines(c(cfg_txt, "max_tiles: 1"), file.path(d, "config.yml"), useBytes = TRUE)
  old <- setwd(d)
  on.exit(setwd(old), add = TRUE)
  # sonde : le mode réel est-il branché ?
  sonde <- tryCatch({ source("_targets.R", local = new.env()); NULL },
                    error = function(e) conditionMessage(e))
  skip_if(!is.null(sonde) && grepl("Mode réel non branché", sonde),
          "mode réel non branché (mission 016 non fusionnée) : tests sautés")
  for (p in c("ranger", "CAST", "rpart", "indicspecies", "mgcv")) skip_if_not_installed(p)
  targets::tar_make(callr_function = NULL, reporter = "silent")
  .reel$res <- list(dir = normalizePath(d), cfg = read_config("config.yml"))
  .reel$res
}

sorties_reel <- function() {
  r <- reel_run()
  d <- file.path(r$dir, r$cfg$out_dir, r$cfg$ser_code)
  expect_true(dir.exists(d), info = paste("dossier de sorties absent :", d))
  list(dir = d, files = list.files(d, full.names = TRUE, recursive = TRUE), cfg = r$cfg,
       work = r$dir)
}

lire_csv <- function(f) utils::read.delim(f, sep = ";", encoding = "UTF-8",
                                          stringsAsFactors = FALSE, check.names = FALSE)
norm <- function(x) tolower(iconv(x, "UTF-8", "ASCII//TRANSLIT"))
texte_lignes <- function(df) {
  if (nrow(df) == 0) return(character(0))
  apply(df, 1, function(r) paste(norm(as.character(r)), collapse = " | "))
}
vrai <- function(x) toupper(as.character(x)) %in% c("TRUE", "T", "1")

# --- 1. aucune marque synthétique en mode réel -------------------------------------
test_that("mode réel : aucun fichier de sortie ne porte le préfixe synth_", {
  s <- sorties_reel()
  expect_gt(length(s$files), 0)
  expect_false(any(grepl("^synth_", basename(s$files))))
})

test_that("mode réel : aucune sortie ne porte synthetic = TRUE (colonnes, attributs)", {
  s <- sorties_reel()
  for (f in s$files[grepl("\\.csv$", s$files)]) {
    t <- lire_csv(f)
    if ("synthetic" %in% names(t)) expect_false(any(vrai(t$synthetic)), info = f)
  }
  for (f in s$files[grepl("\\.gpkg$", s$files)]) {
    v <- terra::vect(f)
    if ("synthetic" %in% names(v)) expect_false(any(vrai(v$synthetic)), info = f)
  }
  # Le pilote COG ne conserve pas les balises : le préfixe (test précédent) reste la marque.
  for (f in s$files[grepl("\\.tif$", s$files)]) {
    m <- terra::metags(terra::rast(f))
    if (length(m) && "synthetic" %in% rownames(m)) expect_false(vrai(m["synthetic", 1]), info = f)
  }
})

test_that("mode réel : l'état de preuve est écrit sans préfixe et ne contient pas d'étape 'synthétique'", {
  s <- sorties_reel()
  f <- file.path(s$dir, "etat_de_preuve.csv")
  expect_true(file.exists(f))
  ep <- lire_csv(f)
  expect_true(all(c("etape", "etat") %in% names(ep)))
  expect_false("synthétique" %in% ep$etat)
})

# --- 2. entrées optionnelles absentes : signalées, jamais remplacées ---------------
test_that("GNSS absent : critère 'non atteint (entrée absente)' dans l'état de preuve", {
  s <- sorties_reel()
  l <- texte_lignes(lire_csv(file.path(s$dir, "etat_de_preuve.csv")))
  ok <- grepl("gnss", l) & grepl(norm(TXT_GNSS_ABSENT), l, fixed = TRUE)
  expect_true(any(ok), info = paste("texte exact attendu :", TXT_GNSS_ABSENT))
})

test_that("GNSS absent : aucun relevé GNSS fabriqué dans les sorties", {
  s <- sorties_reel()
  expect_false(any(grepl("synth_gnss", basename(s$files))))
})

test_that("référence absente : comparaison sautée et signalée dans l'état de preuve", {
  s <- sorties_reel()
  l <- texte_lignes(lire_csv(file.path(s$dir, "etat_de_preuve.csv")))
  # formulation exacte non fixée par la fiche : on accepte 'entrée absente' ou 'sautée'
  expect_true(any(grepl("reference", l) & grepl("entree absente|sautee", l)))
})

# --- 3. règle bloquante -------------------------------------------------------------
test_that("extraction fine forcée sur placettes IFN : l'assertion est levée", {
  skip_if_not_installed("lidR")
  laz <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
  if (!nzchar(laz)) laz <- file.path(testthat::test_path("..", "..", "inst", "extdata"),
                                     "LHD_FXX_1015_6794_extrait.laz")
  skip_if_not(file.exists(laz))
  h <- lidR::readLASheader(laz)
  x <- (h@PHB[["Min X"]] + h@PHB[["Max X"]]) / 2
  y <- (h@PHB[["Min Y"]] + h@PHB[["Max Y"]]) / 2
  ifn <- mark_ifn(data.frame(x = x, y = y))
  msg <- "IFN|700|25|pr.cision|loc_precision_m"
  expect_error(point_lidar_metrics(laz, ifn), msg, ignore.case = TRUE)
  expect_error(assert_no_fine_extract_on_ifn(ifn, "pente"), msg, ignore.case = TRUE)
})

test_that("mode réel : aucune cible ne porte de variable fine renseignée sur des points IFN", {
  s <- sorties_reel()
  old <- setwd(s$work)
  on.exit(setwd(old), add = TRUE)
  noms <- targets::tar_meta(fields = "name", complete_only = TRUE)$name
  expect_gt(length(noms), 0)
  vus <- 0
  for (n in noms) {
    o <- tryCatch(targets::tar_read_raw(n), error = function(e) NULL)
    if (is.data.frame(o) && "loc_precision_m" %in% names(o)) {
      ifn <- if ("source" %in% names(o)) o$source %in% "ifn" else o$loc_precision_m > 25
      if (any(ifn)) {
        vus <- vus + 1
        interdit <- intersect(names(o), FINE_VARIABLES)
        remplies <- vapply(interdit, function(v) any(!is.na(o[[v]][ifn])), logical(1))
        expect_false(any(remplies), info = paste(n, ":", paste(interdit, collapse = ",")))
      }
    }
  }
  # limite dite : si aucune table IFN n'est lisible, le test ne prouve rien
  skip_if(vus == 0, "aucune table de points IFN trouvée dans le magasin")
})

# --- 4. système de coordonnées -------------------------------------------------------
test_that("mode réel : toutes les sorties spatiales sont en EPSG:2154", {
  s <- sorties_reel()
  sp <- s$files[grepl("\\.(tif|gpkg)$", s$files)]
  expect_gt(length(sp), 0)
  for (f in sp) {
    x <- if (grepl("\\.tif$", f)) terra::rast(f) else terra::vect(f)
    expect_identical(terra::crs(x, describe = TRUE)$code, "2154", info = f)
    if (inherits(x, "SpatRaster")) expect_error(assert_crs_2154(x), NA, info = f)
  }
})

# --- 5. couverture des types ---------------------------------------------------------
test_that("mode réel : chaque type couvre au moins 1 % de la surface ou est marqué azonal", {
  s <- sorties_reel()
  f_tif <- s$files[grepl("(^|/)types\\.tif$", s$files)]
  expect_length(f_tif, 1)
  ty <- terra::rast(f_tif)
  fr <- terra::freq(ty[[1]])
  fr <- fr[!is.na(fr$value), ]
  part <- stats::setNames(fr$count / sum(fr$count), fr$value)
  rares <- names(part)[part < 0.01]
  if (length(rares)) {
    csvs <- s$files[grepl("\\.csv$", s$files)]
    lignes <- unlist(lapply(csvs, function(f) texte_lignes(lire_csv(f))))
    for (code in rares) {
      motif <- paste0("(^|[^0-9])", code, "([^0-9]|$)")
      expect_true(any(grepl("azonal", lignes) & grepl(motif, lignes)),
                  info = paste("type", code, ":", round(100 * part[[code]], 2), "% sans marque azonal"))
    }
  }
  expect_true(all(part > 0))
})

# --- 6. rapport ----------------------------------------------------------------------
test_that("mode réel : le rapport a une section 'Limites' (marginales, applicabilité, parcelle)", {
  s <- sorties_reel()
  rap <- s$files[grepl("rapport\\.(qmd|html)$", s$files)]
  skip_if(length(rap) == 0, "aucun rapport (Quarto indisponible : la cible rapport est facultative)")
  txt <- norm(paste(unlist(lapply(rap, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n"))
  expect_true(grepl("limites", txt))
  expect_true(grepl("marginale", txt))
  expect_true(grepl("applicabilite", txt))
  expect_true(grepl("parcelle", txt))
})
