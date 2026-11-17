# Mission 015 : valeurs indicatrices reelles (Tichy et al. 2023) et pedotransfert
# (Bruand et al. 2004). Extraits REELS de inst/extdata, aucun telechargement.

tichy_ext <- function() system.file("extdata", "tichy_2023_extrait.csv", package = "sylvostation")
taxref_ext <- function() system.file("extdata", "taxref_v18_extrait.csv", package = "sylvostation")
flore_ifn <- function() {
  utils::read.delim(system.file("extdata", "ifn_flore.csv", package = "sylvostation"),
                    sep = ";", colClasses = "character")
}

test_that("read_taxref : colonnes utiles, texte, csv et zip", {
  tx <- read_taxref(taxref_ext())
  expect_named(tx, c("CD_NOM", "CD_REF", "LB_NOM", "RANG"))
  expect_true(all(vapply(tx, is.character, logical(1))))
  expect_equal(tx$LB_NOM[tx$CD_NOM == "79319"], "Abies alba")   # CD_NOM de l'IFN, v18
  # archive zip : le TAXREFv*.txt est extrait dans un dossier temporaire, puis supprime
  d <- withr::local_tempdir()
  txt <- file.path(d, "TAXREFv99.txt")
  w <- tx[1:3, ]
  w$X <- "a"   # colonne inutile, ignoree
  utils::write.table(w, txt, sep = "\t", quote = TRUE, row.names = FALSE, na = "")
  zip <- file.path(d, "t.zip")
  oldwd <- setwd(d); on.exit(setwd(oldwd), add = TRUE)
  utils::zip(zip, "TAXREFv99.txt", flags = "-q")
  setwd(oldwd)
  expect_equal(read_taxref(zip), tx[1:3, ], ignore_attr = TRUE)
  expect_error(read_taxref(file.path(d, "absent.txt")), "introuvable")
  bad <- file.path(d, "bad.csv")
  writeLines("A;B\n1;2", bad)
  expect_error(read_taxref(bad), "Colonnes TAXREF absentes")
})

test_that("read_tichy : x et vides en NA, colonnes lues REACTION/NUTRIENTS/MOISTURE", {
  ti <- read_tichy(tichy_ext())
  expect_named(ti, c("taxon", "ph", "azote", "humidite"))
  expect_true(all(vapply(ti[-1], is.numeric, logical(1))))
  # valeurs lues dans le classeur Zenodo : Abies alba, M 6,1 ; R 5,3 ; N 5,5
  a <- ti[ti$taxon == "Abies alba", ]
  expect_equal(c(a$ph, a$azote, a$humidite), c(5.3, 5.5, 6.1))
  expect_true(anyNA(ti$ph))   # "x" (indifferent) devient NA, jamais 0
  expect_error(read_tichy("absent.xlsx"), "introuvable")
  bad <- withr::local_tempfile(fileext = ".csv")
  writeLines("A;B\n1;2", bad)
  expect_error(read_tichy(bad), "Colonnes attendues")
})

test_that("load_indicator_values : format de synth_indicateurs.csv, non synthetique", {
  ind <- load_indicator_values("tichy", tichy_ext(), taxref_ext())
  syn <- utils::read.delim(system.file("extdata", "synth_indicateurs.csv", package = "sylvostation"),
                           sep = ";")
  expect_equal(names(ind), names(syn))
  expect_false(any(ind$synthetic))
  expect_equal(ind$ph[ind$nom == "Abies alba"], 5.3)
  expect_equal(ind$cd_ref[ind$nom == "Abies alba"], 79319)
  expect_equal(attr(ind, "licence"), "CC BY 4.0")
  expect_s3_class(attr(ind, "non_apparies"), "data.frame")
  # compatible avec compute_gradients (colonnes ph et azote numeriques)
  expect_true(is.numeric(ind$ph) && is.numeric(ind$azote))
})

test_that("load_indicator_values : Baseflor et EcoPlant refuses avec un message clair", {
  expect_error(load_indicator_values("baseflor", tichy_ext(), taxref_ext()), "Baseflor")
  expect_error(load_indicator_values("ecoplant", tichy_ext(), taxref_ext()), "EcoPlant")
  expect_error(load_indicator_values("tichy", tichy_ext(), data.frame(a = 1)), "CD_NOM")
})

test_that("load_indicator_values : non-appariés listés, jamais supprimés en silence", {
  tx <- data.frame(CD_NOM = c("1", "2", "3"), CD_REF = c("1", "1", "3"),
                   LB_NOM = c("Aa bb", "Cc dd", "Ee ff"), RANG = "ES")
  ti <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("SeqID;Taxon;LIGHT;TEMPERATURE;MOISTURE;REACTION;NUTRIENTS;SALINITY",
               "1;Aa bb;;;5;6;7;", "2;Cc dd;;;3;4;x;", "3;Zz zz;;;1;1;1;"), ti)
  ind <- load_indicator_values("tichy", ti, tx)
  # Aa bb et Cc dd sont deux noms du meme cd_ref 1 : moyenne ; azote x -> NA ignore
  expect_equal(ind$cd_ref, 1)
  expect_equal(ind$ph, 5)
  expect_equal(ind$azote, 7)
  expect_equal(ind$humidite, 4)
  expect_equal(attr(ind, "non_apparies")$taxon, "Zz zz")
  # mode taxa : 3 sans valeur (Ee ff absent de la source), 99 absent de TAXREF
  r <- load_indicator_values("tichy", ti, tx, taxa = c(2, 3, 99))
  expect_equal(r$cd_ref, 2)                 # code tel que donne (CD_NOM 2, nom du CD_REF 1)
  expect_equal(r$cd_ref_taxref, 1)
  expect_equal(r$appariement, "nom")
  na <- attr(r, "non_apparies")
  expect_equal(na$cd_ref, c(3, 99))
  expect_equal(na$motif, c("nom absent de la source", "CD_NOM absent de TAXREF"))
})

test_that("load_indicator_values : repli sur le binome et synonymes (option)", {
  tx <- data.frame(CD_NOM = c("1", "2", "3", "4", "5"), CD_REF = c("1", "2", "3", "3", "5"),
                   LB_NOM = c("Aa bb subsp. bb", "Aa", "Cc dd", "Ee ff", "Gg"),
                   RANG = c("SSES", "GN", "ES", "ES", "GN"))
  tx$CD_REF[1] <- "1"
  ti <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("SeqID;Taxon;LIGHT;TEMPERATURE;MOISTURE;REACTION;NUTRIENTS;SALINITY",
               "1;Aa bb;;;5;6;7;", "2;Ee ff;;;2;3;4;"), ti)
  r <- load_indicator_values("tichy", ti, tx, taxa = c(1, 3, 2))
  expect_equal(r$appariement, "binome")   # 1 : sous-espece -> binome "Aa bb"
  expect_equal(r$cd_ref, 1)
  # 3 (Cc dd) ne s'apparie que par son synonyme Ee ff, si on le demande
  expect_equal(attr(r, "non_apparies")$cd_ref, c(3, 2))
  expect_equal(attr(r, "non_apparies")$motif[2], "rang supérieur à l'espèce")
  s <- load_indicator_values("tichy", ti, tx, taxa = c(1, 3, 2), synonymes = TRUE)
  expect_equal(s$appariement, c("binome", "synonyme"))
  expect_equal(s$ph, c(6, 3))
})

test_that("taux d'appariement des 100 placettes IFN reelles (extraits reels)", {
  fl <- flore_ifn()
  ind <- load_indicator_values("tichy", tichy_ext(), taxref_ext(), taxa = fl$CD_REF)
  m <- indicator_match_rate(fl, ind)
  # chiffres mesures sur les fichiers complets (Zenodo v2, TAXREF v18), 2026-11-17
  expect_equal(m$n_especes, 269)
  expect_equal(m$n_apparies, 185)
  expect_equal(m$taux_especes, 185 / 269)
  expect_equal(m$n_occurrences, 2238)
  expect_equal(as.integer(m$par_appariement[c("nom", "binome", "agregat")]), c(137L, 36L, 12L))
  # tous les non-apparies sont listes, avec leur nom, leur rang et un motif
  expect_equal(nrow(m$non_apparies), 269 - 185)
  expect_false(anyNA(m$non_apparies$motif))
  expect_equal(sum(m$non_apparies$n_releves) + round(m$taux_occurrences * 2238), 2238 + 0)
  expect_equal(ind$ph[ind$nom == "Hedera helix aggr."], 6.2)   # agregat de la source
  # le mode prudent n'utilise aucun synonyme
  expect_false("synonyme" %in% ind$appariement)
  s <- load_indicator_values("tichy", tichy_ext(), taxref_ext(), taxa = fl$CD_REF,
                             synonymes = TRUE)
  expect_equal(indicator_match_rate(fl, s)$n_apparies, 191)
  # sans repli sur les agregats : retour aux 173 de la premiere version
  sa <- load_indicator_values("tichy", tichy_ext(), taxref_ext(), taxa = fl$CD_REF, agregats = FALSE)
  expect_equal(indicator_match_rate(fl, sa)$n_apparies, 173)
})

test_that("indicator_match_rate : entrées refusées, taux calculé à la main", {
  fl <- data.frame(CD_REF = c(1, 1, 2, 3), id_placette = "a")
  m <- indicator_match_rate(fl, data.frame(cd_ref = 1, appariement = "nom"))
  expect_equal(c(m$n_especes, m$n_apparies), c(3, 1))
  expect_equal(m$taux_occurrences, 2 / 4)
  expect_equal(m$non_apparies$cd_ref, c(2, 3))
  expect_error(indicator_match_rate(1, data.frame(cd_ref = 1)), "CD_REF")
  expect_error(indicator_match_rate(fl, data.frame(x = 1)), "cd_ref")
})

test_that("jointure : les indicateurs reels alimentent compute_gradients", {
  fl <- flore_ifn()
  ind <- load_indicator_values("tichy", tichy_ext(), taxref_ext(), taxa = fl$CD_REF)
  ifn <- make_synth_ifn()
  ifn$flore$CD_REF <- c(79319, 79319, 79319, 100787, 100787, 100787, 100787, 79319, 79319)
  g <- compute_gradients(ifn, ind)
  expect_true(all(!is.na(g$grad_trophique[!is.na(g$grad_trophique)])))
  expect_equal(attr(g, "methode_trophique"), "indicateurs")
})

# ---- Bruand et al. 2004 -----------------------------------------------------

test_that("ru_coefficients() : tableau 2 de Bruand et al. (2004), colonne défaut", {
  ru <- ru_coefficients()
  expect_true(attr(ru, "verifie"))
  expect_equal(attr(ru, "unite"), "mm/cm")
  expect_match(attr(ru, "source"), "Bruand")
  expect_named(ru, c("haut", "bas"))
  # valeurs du tableau, lues sur le PDF : S 0,60 (A) / 0,73 (BC) ; LM 2,13 / 2,07 ; AL 1,36 / 1,13
  expect_equal(unname(ru$haut[c("1", "7")]), c(0.60, 1.36))
  expect_equal(unname(ru$bas[c("1", "7")]), c(0.73, 1.13))
  # codes a plusieurs classes (dictionnaire IFN, mission 019) : moyenne des classes
  # qui ont une valeur
  expect_equal(unname(ru$haut["6"]), 2.13)                       # LM, LL (LL sans valeur)
  expect_equal(unname(ru$bas["6"]), 2.07)
  expect_equal(unname(ru$haut["5"]), mean(c(1.73, 1.67)))        # LA, LAS
  expect_equal(unname(ru$bas["5"]), mean(c(1.49, 1.48)))
  expect_equal(unname(ru$haut["4"]), mean(c(1.62, 1.43, 1.83)))  # LS, LSA, LMS (LLS sans valeur)
  expect_equal(unname(ru$bas["4"]), mean(c(1.27, 1.96)))         # LSA, LMS (LS, LLS sans valeur)
  expect_equal(unname(ru$haut["9"]), 1.24)                       # A sans valeur en horizon A : ALO
  expect_equal(unname(ru$bas["9"]), mean(c(0.93, 1.12)))         # A, ALO
  # reperes : 0 sans terre fine, H non compte, repli documente pour les cases "-"
  expect_equal(unname(ru$haut["0"]), 0)
  expect_true(is.na(ru$haut["H"]) && is.na(ru$bas["H"]))
  expect_true(attr(ru, "correspondance_verifiee"))   # dictionnaire IFN (mission 019)
  # codes IFN couverts
  expect_setequal(names(ru$haut), c("0", as.character(1:9), "H"))
  expect_equal(attr(ru, "correspondance")[["8"]], c("AS", "ALS"))   # Als : hors Aisne, sans valeur
  expect_equal(attr(ru, "correspondance")[["6"]], c("LM", "LL"))
  expect_equal(unname(ru$bas["8"]), 0.95)
})

test_that("ru_coefficients(\"provisoire\") : ancien vecteur, non vérifié", {
  ru <- ru_coefficients("provisoire")
  expect_false(attr(ru, "verifie"))
  expect_equal(unname(ru["6"]), 1.7)
  expect_error(ru_coefficients("autre"))
})

test_that("compute_gradients : RU de Bruand calculée à la main, ru_verifie = TRUE (dictionnaire IFN)", {
  g <- compute_gradients(make_synth_ifn(), make_synth_indic())
  expect_true(attr(g, "ru_verifie"))              # table relue, correspondance du dictionnaire IFN
  expect_true(attr(g, "correspondance_verifiee"))
  # P1 : 20 cm de limon (A : LM) + 40 cm de sable limoneux (bas 1,16), 20 % de cailloux
  expect_equal(g$ru_mm[1], (20 * 2.13 + 40 * 1.16) * 0.8)
  # P3 : 50 cm de limon sableux sous un seul horizon -> `bas` (LSA, LMS), sans cailloux
  expect_equal(g$ru_mm[3], 50 * mean(c(1.27, 1.96)))
  # P4 : 40 cm de sable (bas 0,73), 100 % de cailloux -> 0
  expect_equal(g$ru_mm[4], 0)
  # la table provisoire donne un autre chiffre et ru_verifie = FALSE
  g0 <- compute_gradients(make_synth_ifn(), make_synth_indic(),
                          ru_table = ru_coefficients("provisoire"))
  expect_equal(g0$ru_mm[3], 70)
  expect_false(attr(g0, "ru_verifie"))
  expect_error(compute_gradients(make_synth_ifn(), make_synth_indic(),
                                 ru_table = list(haut = 1)), "haut")
})

test_that("ru_verifie : vrai seulement si table publiee ET correspondance sourcee", {
  ru <- ru_coefficients()
  attr(ru, "correspondance_verifiee") <- TRUE
  g <- compute_gradients(make_synth_ifn(), make_synth_indic(), ru_table = ru)
  expect_true(attr(g, "ru_verifie"))
  expect_true(attr(g, "correspondance_verifiee"))
  attr(ru, "correspondance_verifiee") <- FALSE
  g <- compute_gradients(make_synth_ifn(), make_synth_indic(), ru_table = ru)
  expect_false(attr(g, "ru_verifie"))
  expect_false(attr(g, "correspondance_verifiee"))
})
