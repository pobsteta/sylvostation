# Télécharger un fichier une seule fois (cache local), ou refuser hors ligne

Renvoie le chemin local de `url` dans `dir` : si le fichier y est déjà,
aucun accès réseau n'a lieu. Sinon, avec `offline = TRUE`, la fonction
**s'arrête** (le mode hors ligne ne télécharge jamais) ; sinon elle
télécharge par `downloader`.

## Usage

``` r
fetch_cached(
  url,
  dir,
  offline = FALSE,
  downloader = utils::download.file,
  retries = getOption("sylvostation.download_retries", 3L),
  wait = c(5, 20, 60),
  sleeper = Sys.sleep
)
```

## Arguments

- url:

  Adresse du fichier.

- dir:

  Dossier de cache (créé si besoin, hors dépôt : sous `data/`).

- offline:

  `TRUE` pour interdire tout téléchargement.

- downloader:

  Fonction de téléchargement, de signature de
  [`utils::download.file()`](https://rdrr.io/r/utils/download.file.html)
  (remplaçable dans les tests).

- retries:

  Nombre total de tentatives (au moins 1). Par défaut l'option
  `sylvostation.download_retries`, sinon 3 (valeur provisoire ; en mode
  réel, `_targets.R` pose l'option depuis la clé `download_retries` de
  `config.yml`).

- wait:

  Attentes (secondes) avant la 2e, la 3e... tentative ; la dernière
  valeur est répétée si besoin. Défaut : 5, 20, 60 (provisoire).

- sleeper:

  Fonction d'attente (remplaçable dans les tests).

## Value

Le chemin du fichier local.

## Details

**Reprise sur incident réseau** (mission 026) : un échec du
téléchargement (erreur ou état non nul, par exemple « Stream error in
the HTTP/2 framing layer ») est repris, jusqu'à `retries` tentatives au
total, avec une attente croissante (`wait`). Le fichier partiel est
supprimé avant chaque reprise et un message est émis à chaque tentative.
Après la dernière, la fonction s'arrête avec une erreur claire (adresse,
nombre de tentatives, dernière cause).

## Examples

``` r
d <- tempfile("cache")
dir.create(d)
writeLines("x", file.path(d, "a.csv"))
fetch_cached("https://exemple.invalid/a.csv", d, offline = TRUE)
#> [1] "/tmp/RtmppotWvD/cache2cf16d410841/a.csv"
```
