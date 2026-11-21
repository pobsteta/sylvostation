# MNT et MHC à 1 m depuis des dalles LiDAR HD

Calcule, dalle par dalle, le modèle numérique de terrain (MNT :
triangulation des points de classes 2 sol, 9 eau et 66 points virtuels)
et le modèle de hauteur de canopée (MHC : maximum par cellule de la
hauteur au-dessus du MNT) en un seul passage `lasR`. Si `lasR` n'est pas
installé, repli sur `lidR` (MHC alors = MNS - MNT ; tampon d'au moins 1
m, exigé par lidR ; classes 2 et 9 seulement, le filtre de lidR refusant
la classe 66).

## Usage

``` r
run_lasr(
  laz_files,
  out_dir,
  res = 1,
  ncores = 3,
  buffer = 20,
  keep_laz = FALSE,
  engine = c("auto", "lasr", "lidr"),
  laz_dir = file.path(out_dir, "laz")
)
```

## Arguments

- laz_files:

  Chemins ou URL de fichiers LAZ/LAS/COPC.

- out_dir:

  Dossier de sortie (créé si besoin) : `mnt_<dalle>.tif`,
  `mhc_<dalle>.tif`.

- res:

  Résolution en mètres (1 par défaut).

- ncores:

  Nombre de cœurs (3 par défaut, valeur provisoire).

- buffer:

  Tampon en mètres lu autour de chaque dalle (20 par défaut, valeur
  provisoire de l'esquisse du brief).

- keep_laz:

  Garder les LAZ téléchargés (`FALSE` par défaut).

- engine:

  `"auto"` (lasR si installé, sinon lidR), `"lasr"` ou `"lidr"` (casse
  ignorée).

- laz_dir:

  Dossier des LAZ téléchargés.

## Value

Un `data.frame` : `tile_id`, `mnt`, `mhc` (chemins des GeoTIFF).
Attribut `timing` : liste `download_s`, `compute_s`, `laz_bytes`,
`engine`.

## Details

`laz_files` peut mêler des chemins locaux et des URL (`http`/`https`,
champ `url` de
[`list_tiles()`](https://pobsteta.github.io/sylvostation/reference/list_tiles.md)).
Les URL sont téléchargées dans `laz_dir`, **toutes avant le calcul**
(les voisines servent au tampon `buffer`), puis supprimées après le
calcul si `keep_laz = FALSE`. Les fichiers locaux fournis par l'appelant
ne sont **jamais** supprimés. Pour un massif entier, appeler la fonction
par blocs de 3 x 3 dalles contiguës (valeur provisoire, décision par
délégation : environ 1,7 Go de LAZ au pic). Chaque raster est rogné à
l'emprise de 1 km de sa dalle quand le nom du fichier suit
`LHD_FXX_XXXX_YYYY_*`.

## Examples

``` r
f <- system.file("extdata", "LHD_FXX_1015_6794_extrait.laz", package = "sylvostation")
if (nzchar(f) && requireNamespace("lasR", quietly = TRUE)) {
  run_lasr(f, tempfile("lidar"), buffer = 0)
}
#>     tile_id                                                 mnt
#> 1 1015-6794 /tmp/RtmppotWvD/lidar2cf11e347ab9/mnt_1015-6794.tif
#>                                                   mhc
#> 1 /tmp/RtmppotWvD/lidar2cf11e347ab9/mhc_1015-6794.tif
```
