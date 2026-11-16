# Mission 011 : tests d'acceptation de la règle bloquante (IFN 700 m / précision 25 m).
# Écrits sans lire R/ : seulement CLAUDE.md (« Règles métier »), docs/spec.md,
# docs/brief-technique.md (§ 3, encadré « Contrainte confirmée »), man/*.Rd, NAMESPACE.
#
# Sources des chiffres :
#  - 700 m : docs/brief-technique.md ligne 61 (« jusqu'à 700 m de ce point ») ;
#            CLAUDE.md ligne 53.
#  - 25 m  : docs/brief-technique.md lignes 40 et 85 (« 25 m ou mieux », « incertitude de
#            25 m au plus ») ; CLAUDE.md ligne 55 (« absente ou supérieure à 25 m ») ;
#            man/assert_no_fine_extract_on_ifn.Rd (max_precision_m = 25, « supérieure à »).
#            Valeur provisoire (mission 011).
#
# Assertion « bloque » : on exige une erreur dont le message évoque la règle
# (IFN, 700, 25, précision ou loc_precision_m) ; chaque cas qui bloque a un cas témoin
# voisin qui passe, pour qu'une fonction qui échouerait toujours soit détectée.
# La classe de condition et le texte exact du message ne sont pas documentés : non testés.

MSG_REGLE <- "IFN|700|25|pr.cision|loc_precision_m"

bloque <- function(points, variables, ...) {
  expect_error(assert_no_fine_extract_on_ifn(points, variables, ...), MSG_REGLE,
               ignore.case = TRUE)
}
passe <- function(points, variables, ...) {
  expect_no_error(assert_no_fine_extract_on_ifn(points, variables, ...))
}

pts_precis <- function(n = 3, prec = 10) {
  data.frame(x = 700000 + seq_len(n), y = 6600000 + seq_len(n), loc_precision_m = prec)
}
pts_ifn <- function(n = 3) {
  mark_ifn(data.frame(x = 700000 + seq_len(n), y = 6600000 + seq_len(n)))
}

# --- mark_ifn ---------------------------------------------------------------
test_that("mark_ifn pose source = 'ifn' et loc_precision_m = 700 (colonnes et attribut)", {
  p <- pts_ifn()
  expect_equal(p$source, rep("ifn", 3))
  expect_equal(p$loc_precision_m, rep(700, 3))
  expect_identical(attr(p, "source"), "ifn")
  expect_equal(nrow(p), 3)
})

# --- cas nominaux ------------------------------------------------------------
test_that("placettes IFN + variable fine : erreur", {
  bloque(pts_ifn(), "pente")
  bloque(pts_ifn(), c("twi", "pente"))
})

test_that("chaque variable de FINE_VARIABLES est refusée sur des placettes IFN", {
  expect_gt(length(FINE_VARIABLES), 0)
  for (v in FINE_VARIABLES) bloque(pts_ifn(), v)
})

test_that("points à 10 m + variables fines : passe, et renvoie TRUE de façon invisible", {
  expect_invisible(assert_no_fine_extract_on_ifn(pts_precis(prec = 10), c("pente", "twi")))
  expect_true(assert_no_fine_extract_on_ifn(pts_precis(prec = 10), "pente"))
  for (v in FINE_VARIABLES) passe(pts_precis(prec = 10), v)
})

test_that("IFN + variables larges : passe (COARSE_VARIABLES et préfixe coarse_)", {
  expect_gt(length(COARSE_VARIABLES), 0)
  for (v in COARSE_VARIABLES) passe(pts_ifn(), v)
  passe(pts_ifn(), "coarse_climat")
  passe(pts_ifn(), c("coarse_climat", "coarse_pedopaysage"))
})

test_that("IFN + mélange variable large et variable fine : erreur", {
  bloque(pts_ifn(), c("coarse_climat", "pente"))
})

# --- marquage perdu : la précision seule suffit -------------------------------
test_that("rbind qui perd l'attribut source mais garde loc_precision_m = 700 : erreur", {
  m <- rbind(pts_ifn(2), pts_ifn(2))
  attr(m, "source") <- NULL
  expect_null(attr(m, "source"))
  expect_true(all(m$loc_precision_m == 700))
  bloque(m, "pente")
})

test_that("jointure (merge) qui perd l'attribut source : erreur", {
  a <- pts_ifn(3)
  a$id <- 1:3
  attr(a, "source") <- NULL
  j <- merge(a, data.frame(id = 1:3, valeur = c(1, 2, 3)), by = "id")
  expect_null(attr(j, "source"))
  expect_true(all(j$loc_precision_m == 700))
  bloque(j, "pente")
})

test_that("tableau reconstruit à la main (ni attribut ni colonne source), précision 700 : erreur", {
  bloque(data.frame(x = 1, y = 2, loc_precision_m = 700), "pente")
})

test_that("sous-ensemble d'une table IFN : erreur", {
  bloque(pts_ifn(5)[2:3, ], "pente")
})

# --- mélange IFN + points précis ---------------------------------------------
test_that("mélange IFN (700) et points à 10 m : erreur sur l'ensemble", {
  ifn <- pts_ifn(2)[, c("x", "y", "loc_precision_m")]
  precis <- pts_precis(2, prec = 10)[, c("x", "y", "loc_precision_m")]
  bloque(rbind(ifn, precis), "pente")
  passe(precis, "pente")  # témoin : les points précis seuls passent
})

test_that("une seule ligne imprécise parmi des points précis suffit à refuser", {
  p <- pts_precis(5, prec = 10)
  p$loc_precision_m[3] <- 700
  bloque(p, "pente")
})

# --- loc_precision_m absente ou NA -------------------------------------------
test_that("colonne loc_precision_m absente : erreur (précision non garantie)", {
  bloque(data.frame(x = 1, y = 2), "pente")
  passe(data.frame(x = 1, y = 2), "coarse_climat")  # témoin : variable large
})

test_that("loc_precision_m NA (en entier ou sur une ligne) : erreur", {
  bloque(pts_precis(3, prec = NA_real_), "pente")
  p <- pts_precis(3, prec = 10)
  p$loc_precision_m[2] <- NA
  bloque(p, "pente")
})

# --- seuil de 25 m (provisoire) -----------------------------------------------
test_that("seuil : 25 m passe (borne incluse, « supérieure à »), au-dessus refuse", {
  passe(pts_precis(prec = 25), "pente")
  passe(pts_precis(prec = 24.9), "pente")
  bloque(pts_precis(prec = 25.1), "pente")
  bloque(pts_precis(prec = 26), "pente")
  bloque(pts_precis(prec = 100), "pente")
})

test_that("max_precision_m est paramétrable", {
  passe(pts_precis(prec = 50), "pente", max_precision_m = 50)
  bloque(pts_precis(prec = 50), "pente", max_precision_m = 25)
  bloque(pts_precis(prec = 10), "pente", max_precision_m = 5)
})

# --- marquage IFN sans précision cohérente ------------------------------------
test_that("marqué IFN (attribut) mais loc_precision_m = 10 : erreur", {
  p <- pts_precis(3, prec = 10)
  attr(p, "source") <- "ifn"
  bloque(p, "pente")
})

test_that("colonne source = 'ifn' seule (sans attribut), loc_precision_m = 10 : bloque", {
  p <- pts_precis(3, prec = 10)
  p$source <- "ifn"
  expect_null(attr(p, "source", exact = TRUE))
  bloque(p, "pente")
  passe(p, "coarse_climat")
})

# --- noms de variables ---------------------------------------------------------
test_that("noms en majuscules : insensible à la casse (FINE_VARIABLES.Rd)", {
  bloque(pts_ifn(), "PENTE")
  bloque(pts_ifn(), "Twi")
  bloque(pts_ifn(), toupper(FINE_VARIABLES[1]))
})

test_that("préfixes lidar_, mnt_, mhc_ sont fins (FINE_VARIABLES.Rd)", {
  for (v in c("lidar_h95", "mnt_5m", "mhc_moy")) {
    bloque(pts_ifn(), v)
    passe(pts_precis(prec = 10), v)
  }
})

test_that("variable inconnue ou suffixée (slope_5m) : traitée comme fine par prudence", {
  bloque(pts_ifn(), "slope_5m")
  bloque(pts_ifn(), "variable_inconnue")
  passe(pts_precis(prec = 10), "slope_5m")
})

# --- questions ouvertes ---------------------------------------------------------
test_that("le préfixe coarse_ est sensible à la casse : COARSE_climat bloque", {
  bloque(pts_precis(prec = 50), "COARSE_climat")
  bloque(pts_ifn(), "COARSE_climat")
  passe(pts_ifn(), "coarse_climat")
  passe(pts_precis(prec = 10), "COARSE_climat")
})

test_that("variables = character(0) ou NULL : passe (rien n'est extrait)", {
  passe(pts_ifn(), character(0))
  passe(pts_ifn(), NULL)
  passe(pts_precis(prec = 50), character(0))
})

test_that("objet sf marqué IFN + variable fine : erreur", {
  skip_if_not_installed("sf")
  p <- sf::st_as_sf(data.frame(x = c(700000, 700100), y = c(6600000, 6600100)),
                    coords = c("x", "y"), crs = 2154)
  p <- mark_ifn(p)
  bloque(p, "pente")
  passe(p, "coarse_climat")
})
