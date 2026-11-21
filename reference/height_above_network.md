# Hauteur au-dessus du réseau hydrographique

HAND (*height above nearest drainage*) : pour chaque cellule du MNT,
altitude moins celle de la **première cellule du réseau** atteinte en
suivant les directions d'écoulement D8 (les mêmes que `surface_drainee`
de
[`derive_terrain()`](https://pobsteta.github.io/sylvostation/reference/derive_terrain.md),
sans remplissage). Le réseau est rastérisé (cellules touchées).

## Usage

``` r
height_above_network(dtm, network)
```

## Arguments

- dtm:

  `SpatRaster` à une couche, EPSG:2154, maille carrée.

- network:

  Réseau de lignes (`sf` ou `SpatVector`, EPSG:2154), p. ex.
  [`get_hydro_network()`](https://pobsteta.github.io/sylvostation/reference/get_hydro_network.md).

## Value

Un `SpatRaster` à une couche nommée `hauteur_reseau` (m, \>= 0). Tout
`NA` avec avertissement de classe `sylvostation_non_calcule` si aucun
tronçon ne touche le MNT.

## Details

**Cuvettes** (mission 027) : sur le MNT LiDAR à 5 m, l'écoulement D8
finit souvent dans une cuvette intérieure (remblai de route, artefact) ;
70 % des `NA` des 4 dalles d'essai venaient de 40 cuvettes. Chaque
cuvette (puits ni sur le réseau, ni au bord du MNT) est désormais reliée
au bassin voisin par son **col de débordement**, choisi comme dans un
remplissage par inondation prioritaire (Barnes, Lehman et Mulla 2014,
*Computers & Geosciences* 62, 117-127) : arbre couvrant minimal des
bassins, poids = altitude du col. Le MNT n'est pas modifié ; une cellule
de cuvette plus basse que le réseau atteint vaut **0**. Le HAND publié
(Rennó et al. 2008, *Remote Sensing of Environment* 112, 3469-3481 ;
Nobre et al. 2011, *Journal of Hydrology* 404, 13-29) part d'un MNT
hydrologiquement corrigé (détail du traitement des cuvettes **à
vérifier** dans le texte, non lu).

Résultat `NA` là où l'écoulement n'atteint pas le réseau dans l'emprise
(sortie du MNT, cellule en aval du dernier point du réseau) ; **jamais
négatif**. Variable **fine** : jamais aux coordonnées des placettes IFN.

## Examples

``` r
d <- terra::rast(nrows = 20, ncols = 20, xmin = 980000, xmax = 980500,
                 ymin = 6800000, ymax = 6800500, crs = "EPSG:2154")
terra::values(d) <- 500 + 0.1 * (terra::yFromCell(d, seq_len(terra::ncell(d))) - 6800000)
ln <- terra::vect(matrix(c(980000, 6800250, 980500, 6800250), ncol = 2, byrow = TRUE),
                  type = "lines", crs = "EPSG:2154")
height_above_network(d, ln)
#> class       : SpatRaster
#> size        : 20, 20, 1  (nrow, ncol, nlyr)
#> resolution  : 25, 25  (x, y)
#> extent      : 980000, 980500, 6800000, 6800500  (xmin, xmax, ymin, ymax)
#> coord. ref. : RGF93 v1 / Lambert-93 (EPSG:2154)
#> source(s)   : memory
#> name        : hauteur_reseau
#> min value   :              0
#> max value   :           22.5
```
