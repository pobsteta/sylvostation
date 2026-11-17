# Fabrique inst/extdata/tichy_2023_extrait.csv et inst/extdata/taxref_v18_extrait.csv
# (mission 015) : extraits REELS limites aux especes de la flore IFN de inst/extdata.
# Sources : Tichy et al. (2023), Zenodo 10.5281/zenodo.7427088 (CC BY 4.0) ;
# TAXREF v18 (MNHN/PatriNat, Licence Ouverte). Voir inst/extdata/SOURCES.md.
# Usage (depuis la racine du depot), fichiers deja telecharges hors depot :
#   Rscript inst/scripts/extraire_indicateurs.R data/cache/Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx data/cache/TAXREF_v18_2025.zip
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage : Rscript extraire_indicateurs.R <tichy.xlsx> <TAXREF.zip>")
suppressMessages(devtools::load_all(quiet = TRUE))
fl <- utils::read.delim("inst/extdata/ifn_flore.csv", sep = ";", colClasses = "character")
tx <- read_taxref(args[[2]])
ti <- read_tichy(args[[1]])
ind <- load_indicator_values("tichy", args[[1]], tx, taxa = fl$CD_REF, synonymes = TRUE)
noms <- unique(c(ind$nom, .binome(ind$nom)))
ti_ext <- ti[ti$taxon %in% noms, , drop = FALSE]
# CSV a colonnes d'origine du classeur (SeqID, Taxon, ..., MOISTURE, REACTION, NUTRIENTS)
sortie <- data.frame(SeqID = match(ti_ext$taxon, ti$taxon), Taxon = ti_ext$taxon,
                     LIGHT = NA, TEMPERATURE = NA, MOISTURE = ti_ext$humidite,
                     REACTION = ti_ext$ph, NUTRIENTS = ti_ext$azote, SALINITY = NA)
utils::write.table(sortie, "inst/extdata/tichy_2023_extrait.csv", sep = ";", quote = TRUE,
                   row.names = FALSE, na = "", fileEncoding = "UTF-8")
refs <- tx$CD_REF[tx$CD_NOM %in% fl$CD_REF]
garde <- tx$CD_NOM %in% fl$CD_REF | tx$CD_NOM %in% refs |
  (tx$CD_REF %in% refs & tx$RANG == "ES") | tx$LB_NOM %in% ti_ext$taxon
tx_ext <- tx[garde, , drop = FALSE]
utils::write.table(tx_ext, "inst/extdata/taxref_v18_extrait.csv", sep = ";", quote = TRUE,
                   row.names = FALSE, na = "", fileEncoding = "UTF-8")
cat("Tichy :", nrow(ti_ext), "lignes ; TAXREF :", nrow(tx_ext), "lignes\n")
