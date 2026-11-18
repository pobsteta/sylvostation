# Rendu du rapport (mission 022) : HTML toujours, PDF si Quarto et LaTeX le permettent.
#
# Ce fichier n'appartient pas aux fonctions exportees du paquet : il est lu par la cible
# `rapport` de _targets.R (source(system.file("rapport", "rendre_rapport.R", ...))) et par
# les tests. Il ne calcule rien : il rend inst/rapport/rapport.qmd, qui ne lit que les
# fichiers ecrits par write_outputs(). Le PDF n'est jamais obligatoire : si LaTeX manque
# ou si son rendu echoue, le HTML est livre seul et le motif est donne dans l'attribut
# `pdf_message` du resultat (jamais en silence).

# TRUE si un moteur LaTeX (xelatex) est utilisable : dans le PATH, ou installe par tinytex.
latex_disponible <- function() {
  if (nzchar(Sys.which("xelatex"))) return(TRUE)
  if (requireNamespace("tinytex", quietly = TRUE)) {
    racine <- tryCatch(tinytex::tinytex_root(error = FALSE), error = function(e) "")
    return(is.character(racine) && length(racine) == 1L && nzchar(racine))
  }
  FALSE
}

# Rend le rapport dans `dossier` et renvoie les chemins des fichiers produits (HTML, puis
# PDF s'il a ete rendu). `pdf_disponible` : fonction sans argument (remplacable en test).
rendre_rapport <- function(dossier, prefixe, ser_code, hors_ligne,
                           modele = system.file("rapport", "rapport.qmd", package = "sylvostation"),
                           pdf_disponible = latex_disponible) {
  dossier <- normalizePath(dossier)
  qmd <- file.path(dossier, "rapport.qmd")
  file.copy(modele, qmd, overwrite = TRUE)
  parametres <- list(dossier = dossier, prefixe = prefixe, ser_code = ser_code,
                     hors_ligne = isTRUE(hors_ligne))
  html <- file.path(dossier, "rapport.html")
  pdf <- file.path(dossier, "rapport.pdf")
  if (file.exists(pdf)) file.remove(pdf)  # pas de PDF d'un run precedent

  quarto::quarto_render(qmd, output_format = "html", execute_params = parametres, quiet = TRUE)
  sortie <- html
  msg <- NULL
  if (!isTRUE(pdf_disponible())) {
    msg <- "PDF non produit : moteur LaTeX (xelatex) absent ; HTML seul."
  } else {
    ok <- tryCatch({
      quarto::quarto_render(qmd, output_format = "pdf", execute_params = parametres, quiet = TRUE)
      file.exists(pdf)
    }, error = function(e) {
      msg <<- paste0("PDF non produit : le rendu a échoué (", conditionMessage(e), ") ; HTML seul.")
      FALSE
    })
    if (isTRUE(ok)) sortie <- c(html, pdf) else if (file.exists(pdf)) file.remove(pdf)
  }
  if (!is.null(msg)) warning(msg, call. = FALSE)
  structure(sortie, pdf_message = msg)
}
