#' sylvostation : catalogue de stations forestières par sylvoécorégion
#'
#' Fonctions du pipeline `sylvostation`. Les coordonnées sont toujours en
#' Lambert-93 (EPSG:2154), x = est, y = nord. Les placettes de l'IFN, localisées
#' à 700 m près, ne peuvent être croisées qu'avec des variables à maille large
#' (voir [assert_no_fine_extract_on_ifn()]).
#'
#' @keywords internal
#' @importFrom stats setNames
#' @importFrom utils head
"_PACKAGE"
