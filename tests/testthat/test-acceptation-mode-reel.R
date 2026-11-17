# Mission 017 : tests d'acceptation du mode réel (`demo: false`), écrits SANS lire le code
# de la mission 016 (R/pipeline_reel.R, _targets.R non lus). Sources :
#  - docs/brief-technique.md § 7 (lignes 236-243) : critères d'acceptation ;
#  - docs/spec.md (« Critères d'acceptation », état de preuve, objection B1) ;
#  - pilotage/missions/016-mode-reel.md, rubrique « Contrat avec les tests d'acceptation de
#    017 » : `offline: true` (config) = mode réel sans réseau sur les extraits de inst/extdata ;
#    les tests lancent `demo: false, offline: true` (jamais de téléchargement) ; sorties
#    etat_de_preuve.csv, types.tif, rapport.qmd, rapport.html ; libellés exacts
#    « non atteint (entrée absente) » (GNSS) et « sautée (entrée absente) » (référence) ;
#    colonne logique `azonal` dans legende_types.csv ; clés `gnss_path`, `reference_path`,
#    `max_tiles` ; SYLVOSTATION_REEL_DIR = dossier de travail déjà exécuté (config.yml,
#    magasin `_targets/` et sorties), seulement relu ;
#  - CLAUDE.md (« Règles métier » : synth_, EPSG:2154, règle 700 m / 25 m) ;
#  - man/evidence_table.Rd (colonnes etape, etat, dans_ce_run, detail), man/write_outputs.Rd.
#
# SAUT PROPRE : seul le message exact « Mode réel non branché », levé à la sonde (source de
# _targets.R avec demo: false), fait sauter les tests (016 non fusionnée) : un saut ne
# prouve rien. Toute erreur de tar_make finit en rouge, même si elle cite « offline ».
#
# Boîte noire : pipeline lancé une seule fois dans un dossier temporaire, avec
# max_tiles = 1 et SANS gnss_path ni reference_path ; on inspecte out_dir/<ser_code>/.
#
# Non couvert : mécanisme de simulation des téléchargements de 016 (inconnu) ; noms exacts
# des cibles et colonnes des tables de types (inconnus : recherche par motifs) ; surface
# « forestière » (pas de masque forestier connu : on compte les cellules non NA du raster
# des types) ; chemin gnss_path / reference_path fourni mais fichier inexistant.

TXT_GNSS_ABSENT <- "non atteint (entrée absente)"   # fiche 016, « Contrat avec ... 017 »
TXT_REF_ABSENTE <- "sautée (entrée absente)"          # idem

.reel <- new.env()

# Lance UNE seule fois (échec compris) le pipeline réel en `demo: false, offline: true`
# (aucun téléchargement) ; renvoie list(dir, cfg) ou saute le test.
reel_run <- function() {
  if (!is.null(.reel$skip)) skip(.reel$skip)
  if (!is.null(.reel$res)) return(.reel$res)
  sauter <- function(msg) { .reel$skip <- msg; skip(msg) }
  skip_on_cran()
  skip_if_not_installed("targets")
  pre <- Sys.getenv("SYLVOSTATION_REEL_DIR", "")
  if (nzchar(pre)) {
    if (!file.exists(file.path(pre, "config.yml"))) sauter("SYLVOSTATION_REEL_DIR sans config.yml")
    .reel$res <- list(dir = normalizePath(pre), cfg = read_config(file.path(pre, "config.yml")))
    return(.reel$res)
  }
  racine <- testthat::test_path("..", "..")
  if (!(file.exists(file.path(racine, "_targets.R")) && file.exists(file.path(racine, "config.yml"))))
    sauter("_targets.R et config.yml absents (paquet installé)")
  racine <- normalizePath(racine)
  d <- tempfile("reel_")
  dir.create(d)
  file.copy(file.path(racine, c("_targets.R", "config.yml")), d)
  cfg_txt <- readLines(file.path(d, "config.yml"), encoding = "UTF-8")
  cfg_txt <- sub("^demo: true", "demo: false", cfg_txt)
  # entrées optionnelles absentes : on retire toute clé gnss_path / reference_path
  cfg_txt <- cfg_txt[!grepl("^(gnss_path|reference_path|max_tiles|offline|demo):", cfg_txt)]
  writeLines(c(cfg_txt, "demo: false", "offline: true", "max_tiles: 1"),
             file.path(d, "config.yml"), useBytes = TRUE)
  old <- setwd(d)
  on.exit(setwd(old), add = TRUE)
  # sonde : le mode réel (et l'interface offline de 016) est-il branché ?
  sonde <- tryCatch({ source("_targets.R", local = new.env()); NULL },
                    error = function(e) conditionMessage(e))
  if (!is.null(sonde) && grepl("Mode réel non branché", sonde, fixed = TRUE))
    sauter("mode réel / interface offline non branchés (mission 016 non fusionnée) : tests sautés")
  for (p in c("ranger", "CAST", "rpart", "indicspecies", "mgcv"))
    if (!requireNamespace(p, quietly = TRUE)) sauter(paste("paquet absent :", p))
  err <- tryCatch({ targets::tar_make(callr_function = NULL, reporter = "silent"); NULL },
                  error = function(e) conditionMessage(e))
  .reel$res <- list(dir = normalizePath(d), cfg = read_config("config.yml"), erreur = err)
  # le run est mis en cache ; une erreur de tar_make fait échouer le premier test
  expect_null(err, info = "tar_make a échoué en mode réel offline")
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
    for (ly in terra::vector_layers(f)) {
      v <- terra::vect(f, layer = ly)
      if ("synthetic" %in% names(v)) expect_false(any(vrai(v$synthetic)), info = paste(f, ly))
    }
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

test_that("référence absente : ligne 'sautée (entrée absente)' et aucune sortie de comparaison", {
  s <- sorties_reel()
  l <- texte_lignes(lire_csv(file.path(s$dir, "etat_de_preuve.csv")))
  ok <- grepl("reference", l) & grepl(norm(TXT_REF_ABSENTE), l, fixed = TRUE)
  expect_true(any(ok), info = paste("texte exact attendu :", TXT_REF_ABSENTE))
  autres <- setdiff(basename(s$files), c("etat_de_preuve.csv"))
  expect_false(any(grepl("compar|referen", autres, ignore.case = TRUE)),
               info = paste(autres, collapse = ", "))
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

est_fine <- function(v) {
  l <- tolower(v)
  l %in% tolower(FINE_VARIABLES) | startsWith(l, .FINE_PREFIXES[1]) |
    startsWith(l, .FINE_PREFIXES[2]) | startsWith(l, .FINE_PREFIXES[3])
}

test_that("mode réel : aucune variable fine renseignée sur points IFN, de précision NA ou > 25 m", {
  s <- sorties_reel()
  old <- setwd(s$work)
  on.exit(setwd(old), add = TRUE)
  noms <- targets::tar_meta(fields = "name", complete_only = TRUE)$name
  expect_gt(length(noms), 0)
  vus <- 0
  for (n in noms) {
    o <- tryCatch(targets::tar_read_raw(n), error = function(e) NULL)
    if (is.data.frame(o) && "loc_precision_m" %in% names(o)) {
      p <- suppressWarnings(as.numeric(o$loc_precision_m))
      src <- if ("source" %in% names(o)) o$source %in% "ifn" else rep(FALSE, nrow(o))
      lignes <- src | is.na(p) | p > 25
      if (any(lignes)) {
        vus <- vus + 1
        interdit <- names(o)[est_fine(names(o))]
        remplies <- vapply(interdit, function(v) any(!is.na(o[[v]][lignes])), logical(1))
        expect_false(any(remplies), info = paste(n, ":", paste(interdit[remplies], collapse = ",")))
      }
    }
  }
  # limite dite : si aucune table à contrôler n'est lisible, le test ne prouve rien
  skip_if(vus == 0, "aucune table de points IFN / imprécis trouvée dans le magasin")
})

# --- 4. système de coordonnées -------------------------------------------------------
test_that("mode réel : toutes les sorties spatiales sont en EPSG:2154", {
  s <- sorties_reel()
  sp <- s$files[grepl("\\.(tif|gpkg)$", s$files)]
  expect_gt(length(sp), 0)
  for (f in sp) {
    couches <- if (grepl("\\.tif$", f)) list(terra::rast(f)) else
      lapply(terra::vector_layers(f), function(ly) terra::vect(f, layer = ly))
    for (x in couches) {
      expect_identical(terra::crs(x, describe = TRUE)$code, "2154", info = f)
      if (inherits(x, "SpatRaster")) expect_error(assert_crs_2154(x), NA, info = f)
    }
  }
})

# --- 5. couverture des types ---------------------------------------------------------
test_that("mode réel : chaque type de la légende couvre >= 1 % des cellules non NA ou est azonal", {
  s <- sorties_reel()
  f_tif <- s$files[grepl("(^|/)types\\.tif$", s$files)]
  expect_length(f_tif, 1)
  f_leg <- s$files[grepl("(^|/)legende_types\\.csv$", s$files)]
  expect_length(f_leg, 1)
  leg <- lire_csv(f_leg)
  expect_true(all(c("id", "type", "azonal") %in% names(leg)),
              info = "colonnes id, type, azonal attendues dans legende_types.csv")
  fr <- terra::freq(terra::rast(f_tif)[[1]])
  fr <- fr[!is.na(fr$value), ]
  total <- sum(fr$count)
  expect_gt(total, 0)
  # type_id -> type par la légende ; un type absent du raster compte 0 %
  cnt <- fr$count[match(leg$id, fr$value)]
  cnt[is.na(cnt)] <- 0
  part <- tapply(cnt, leg$type, sum) / total
  azonal <- tapply(vrai(leg$azonal), leg$type, any)
  for (ty in names(part)) {
    expect_true(part[[ty]] >= 0.01 || isTRUE(azonal[[ty]]),
                info = paste("type", ty, ":", round(100 * part[[ty]], 2), "% sans azonal = TRUE"))
  }
  # tout code du raster doit être dans la légende
  expect_true(all(fr$value %in% leg$id))
})

# --- 6. rapport ----------------------------------------------------------------------
test_that("mode réel : le rapport existe et a une section 'Limites' (marginales, applicabilité, parcelle)", {
  skip_if_not_installed("quarto")
  skip_if(is.null(quarto::quarto_path()), "Quarto absent : le rapport n'est pas rendu")
  s <- sorties_reel()
  qmd <- s$files[basename(s$files) == "rapport.qmd"]
  html <- s$files[basename(s$files) == "rapport.html"]
  expect_length(qmd, 1)
  expect_length(html, 1)
  brut <- readLines(qmd, warn = FALSE, encoding = "UTF-8")
  expect_true(any(grepl("^#+ .*Limites", brut)), info = "titre de section 'Limites' absent du .qmd")
  txt <- norm(paste(brut, collapse = "\n"))
  expect_true(grepl("marginale", txt))
  expect_true(grepl("applicabilite", txt))
  expect_true(grepl("parcelle", txt))
})
