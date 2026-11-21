# Lire la table de valeurs indicatrices de Tichý et al. (2023)

Lit la feuille finale `Tab-IVs-Tichy-et-al2023` du classeur Zenodo
`Indicator.values-tables-2022-11-07-Zenodo.v2.xlsx` (colonnes lues sur
le fichier : `SeqID`, `Taxon`, `LIGHT`, `TEMPERATURE`, `MOISTURE`,
`REACTION`, `NUTRIENTS`, `SALINITY`, une ligne d'en-tête puis une ligne
`Average`), ou un extrait CSV (`;`) de mêmes colonnes. Le symbole `x`
(indifférent) et les cases vides deviennent `NA`.

## Usage

``` r
read_tichy(path)
```

## Arguments

- path:

  Chemin du `.xlsx` (paquet `readxl`) ou du `.csv`.

## Value

Un `data.frame` (`taxon`, `ph` = `REACTION`, `azote` = `NUTRIENTS`,
`humidite` = `MOISTURE`), valeurs numériques de type Ellenberg.

## Examples

``` r
f <- system.file("extdata", "tichy_2023_extrait.csv", package = "sylvostation")
read_tichy(f)
#>                             taxon  ph azote humidite
#> 1                      Abies alba 5.3   5.5      6.1
#> 2                  Acer campestre 7.3   5.4       NA
#> 3                Acer platanoides 6.5   6.3      5.6
#> 4             Acer pseudoplatanus 5.8   6.6       NA
#> 5           Adenostyles alliariae 6.0   7.8      6.2
#> 6             Agrostis capillaris 3.5   3.3      4.9
#> 7                   Ajuga reptans  NA    NA      6.2
#> 8              Alliaria petiolata 7.3   8.0      5.4
#> 9                 Alnus glutinosa 5.9   6.3      9.2
#> 10              Anagallis tenella 4.8   2.0      8.9
#> 11               Anemone nemorosa 5.2    NA      5.9
#> 12    Anthoxanthum odoratum aggr.  NA   3.2       NA
#> 13                 Arum maculatum 7.3   7.4      6.0
#> 14          Asplenium trichomanes  NA   2.9      4.1
#> 15          Athyrium filix-femina 5.3   5.6       NA
#> 16             Atropa bella-donna 7.4   7.6      5.2
#> 17              Avenella flexuosa 2.1   2.7      5.3
#> 18                 Betula pendula 3.8   3.4       NA
#> 19               Blechnum spicant 2.6   2.8      6.5
#> 20        Brachypodium sylvaticum 6.4   5.6      5.4
#> 21               Calluna vulgaris 1.5   1.4      5.6
#> 22              Calystegia sepium 7.0   7.9      7.0
#> 23           Campanula trachelium 7.8   7.1      5.5
#> 24             Cardamine flexuosa  NA   5.6      7.9
#> 25          Cardamine heptaphylla 7.7   6.0      5.0
#> 26                Carex brizoides 3.6   3.1       NA
#> 27                  Carex divulsa 5.7    NA       NA
#> 28                 Carex elongata 6.5   5.5      8.8
#> 29                  Carex pendula 6.5   5.9      8.4
#> 30               Carex pilulifera 2.9   3.1      5.2
#> 31                   Carex remota 5.9    NA       NA
#> 32                Carex sylvatica 6.6   5.1      5.7
#> 33               Carpinus betulus 5.5   5.3      5.4
#> 34                Castanea sativa 4.3   4.2      5.3
#> 35  Chrysosplenium oppositifolium 5.4   5.2      9.3
#> 36              Circaea lutetiana 7.0   6.7       NA
#> 37                Cirsium arvense 6.1   6.6       NA
#> 38               Clematis vitalba 7.3   6.3       NA
#> 39            Clinopodium vulgare 6.8   3.2      4.3
#> 40            Convallaria majalis 5.6   3.8      4.9
#> 41               Cornus sanguinea 7.5   4.8       NA
#> 42               Corylus avellana 5.9    NA      5.6
#> 43            Crataegus laevigata 6.2   4.8      5.2
#> 44             Crataegus monogyna  NA    NA      4.4
#> 45              Cytisus scoparius 3.3   3.1      4.5
#> 46             Dactylis glomerata  NA    NA       NA
#> 47    Deschampsia cespitosa aggr.  NA    NA       NA
#> 48                Digitalis lutea 6.8   5.0      5.0
#> 49             Digitalis purpurea 3.0    NA      5.2
#> 50          Digitaria sanguinalis 5.6    NA      3.7
#> 51           Drymochloa sylvatica  NA   5.6      5.6
#> 52       Dryopteris affinis aggr. 4.6   4.8       NA
#> 53   Dryopteris carthusiana aggr. 3.6    NA       NA
#> 54           Dryopteris filix-mas 5.3   5.6       NA
#> 55                 Elymus caninus 7.1   7.1      6.3
#> 56             Epilobium montanum 5.8   5.4      5.5
#> 57              Equisetum hyemale 6.9   5.9      6.8
#> 58             Euonymus europaeus 7.6   5.0      5.0
#> 59          Eupatorium cannabinum 6.6   7.0      7.3
#> 60                Fagus sylvatica 5.7    NA      5.5
#> 61                  Ficaria verna 6.8   6.8      6.4
#> 62            Filipendula ulmaria 5.8   5.0      7.9
#> 63                 Fragaria vesca 6.8   5.0      4.9
#> 64             Fraxinus excelsior 7.3   6.6      6.7
#> 65       Galeopsis tetrahit aggr.  NA   6.5       NA
#> 66                 Galium aparine 6.3   7.6       NA
#> 67           Galium mollugo aggr. 6.8    NA      4.3
#> 68                Galium odoratum 6.3   5.3      5.4
#> 69           Galium rotundifolium  NA    NA      5.3
#> 70                Galium saxatile 2.2   2.6      5.5
#> 71              Galium sylvaticum 6.0   5.0      5.0
#> 72           Geranium robertianum 6.2   6.8      5.5
#> 73                   Geum urbanum 6.8   7.0      5.7
#> 74             Glechoma hederacea 6.3   6.9      5.9
#> 75          Gnaphalium sylvaticum 3.8    NA       NA
#> 76             Hedera helix aggr. 6.2    NA      5.3
#> 77          Heracleum sphondylium 6.6   7.2      5.5
#> 78           Hieracium lachenalii 4.0   2.4      5.0
#> 79           Hieracium laevigatum 3.1   2.2      5.0
#> 80              Hieracium murorum 5.2   3.6      5.1
#> 81             Hieracium sabaudum 3.8   2.4      4.8
#> 82                 Holcus lanatus 5.5   4.7       NA
#> 83                  Holcus mollis 2.7   3.0      5.6
#> 84             Hypericum hirsutum 6.9    NA      4.9
#> 85             Hypericum montanum 7.1   2.7      4.0
#> 86           Hypericum perforatum 6.1   3.9      3.9
#> 87             Hypericum pulchrum 3.2   2.4      5.0
#> 88                Ilex aquifolium 4.0   4.5      5.2
#> 89         Impatiens noli-tangere 6.7   6.3      6.9
#> 90           Impatiens parviflora 6.6   6.7      5.4
#> 91              Jacobaea vulgaris 6.6   5.0      3.8
#> 92                  Juglans regia 7.1   6.3      5.3
#> 93          Juncus bufonius aggr.  NA    NA       NA
#> 94           Juncus conglomeratus 4.4   3.6      7.6
#> 95                 Juncus effusus 4.5   3.8      8.0
#> 96                  Juncus tenuis 5.0   4.8      6.2
#> 97           Knautia dipsacifolia 6.8   4.3      6.0
#> 98                Lactuca muralis 7.0   5.8      5.1
#> 99             Lamium galeobdolon 7.0   5.7      5.7
#> 100              Lapsana communis 6.6   7.0       NA
#> 101                 Larix decidua 5.0   3.4      4.3
#> 102           Lathyrus linifolius 3.5   2.5      5.0
#> 103             Ligustrum vulgare 7.6   4.1       NA
#> 104                Linaria repens 4.8   5.3      4.5
#> 105         Lonicera periclymenum 4.0   4.1      5.7
#> 106            Lonicera xylosteum 7.3   5.2       NA
#> 107              Lunaria rediviva 7.0   7.8      6.3
#> 108             Luzula luzuloides 3.2   3.9      4.8
#> 109                 Luzula pilosa 4.7   3.9      5.2
#> 110              Luzula sylvatica 3.0   3.7       NA
#> 111            Lysimachia nemorum 5.7   5.7      7.7
#> 112           Melampyrum pratense 3.0   2.2      5.1
#> 113               Melica uniflora 6.4   5.1      5.3
#> 114       Melittis melissophyllum  NA   3.1       NA
#> 115               Mentha aquatica 6.6   5.0      8.8
#> 116          Mercurialis perennis 7.4   6.6      5.5
#> 117                Milium effusum 5.8   5.1       NA
#> 118          Moehringia trinervia 6.6   6.4      5.4
#> 119             Myosotis arvensis 5.3   5.8      4.5
#> 120            Neottia nidus-avis 7.3   4.9      5.2
#> 121             Oxalis acetosella 4.4   5.8       NA
#> 122             Paris quadrifolia 7.3   6.5      6.4
#> 123           Persicaria maculosa 6.4   7.0       NA
#> 124                   Picea abies 3.8   4.2      5.8
#> 125         Pilosella officinarum 5.3   1.8      3.9
#> 126              Pinus sylvestris 3.8   2.0      5.2
#> 127           Plantago lanceolata 5.9   4.8      4.5
#> 128                Plantago major 5.8   5.9       NA
#> 129                   Poa chaixii 3.7   3.9       NA
#> 130                 Poa nemoralis 6.0   4.0      5.4
#> 131       Polygonatum multiflorum 6.6   4.9      5.2
#> 132     Polygonatum verticillatum 5.0   5.0       NA
#> 133            Polypodium vulgare 3.8   2.8      4.9
#> 134         Polystichum aculeatum 6.6   6.1      6.0
#> 135         Polystichum setiferum 5.7   5.3      6.1
#> 136               Populus tremula 5.0   4.8      5.3
#> 137           Potentilla sterilis 6.2   5.0      4.7
#> 138           Prenanthes purpurea 5.0   5.2      5.3
#> 139             Prunella vulgaris 5.8    NA      5.6
#> 140                  Prunus avium 6.6   5.0      5.3
#> 141                Prunus spinosa 6.4    NA      4.0
#> 142           Pteridium aquilinum 3.4   3.0      5.2
#> 143        Pulmonaria officinalis 7.2   6.0      5.4
#> 144                Pyrus communis  NA    NA      5.0
#> 145               Quercus petraea  NA    NA      5.1
#> 146                 Quercus robur 5.0    NA      5.7
#> 147           Ranunculus bulbosus 6.5   2.9      3.9
#> 148             Ranunculus repens 5.8   6.5      7.3
#> 149            Ribes rubrum aggr. 6.3   6.1      7.4
#> 150          Robinia pseudoacacia 6.4   7.5      4.4
#> 151                 Rosa arvensis 7.0   4.7       NA
#> 152             Rosa canina aggr. 7.0    NA       NA
#> 153        Rubus fruticosus aggr.  NA    NA       NA
#> 154                  Rubus idaeus 5.8    NA      5.5
#> 155                 Rumex acetosa  NA    NA       NA
#> 156              Rumex acetosella  NA   2.0      3.7
#> 157            Rumex obtusifolius 6.5   8.4       NA
#> 158                  Salix caprea 6.4   5.6       NA
#> 159                 Salix cinerea 5.3   4.4       NA
#> 160                Sambucus nigra 6.7   8.0       NA
#> 161             Sambucus racemosa 5.0   7.2      5.2
#> 162         Schedonorus giganteus 6.5   6.5       NA
#> 163                Scilla bifolia 6.9   6.1      6.2
#> 164           Scrophularia nodosa 6.6   6.9      6.3
#> 165            Senecio sylvaticus 4.4    NA       NA
#> 166                 Silene dioica 6.8   7.5       NA
#> 167            Solidago virgaurea  NA    NA      5.2
#> 168              Sorbus aucuparia  NA   3.6      5.8
#> 169             Sorbus torminalis 6.6   3.8      4.1
#> 170             Stachys sylvatica 7.1   7.1      7.0
#> 171            Stellaria graminea 4.5   3.8       NA
#> 172            Stellaria holostea 5.7   4.9      5.5
#> 173               Stellaria media 6.5   7.7       NA
#> 174             Stellaria nemorum 5.6   6.9       NA
#> 175                 Taxus baccata 7.1   4.7       NA
#> 176           Teucrium scorodonia 2.8   3.0      4.1
#> 177            Tilia platyphyllos 7.3   6.3      5.1
#> 178                 Urtica dioica 6.9   8.5       NA
#> 179           Vaccinium myrtillus 1.9   2.5       NA
#> 180         Vaccinium vitis-idaea 2.0   1.9      4.8
#> 181     Veronica chamaedrys aggr. 6.5   4.9      4.6
#> 182              Veronica montana  NA   6.0       NA
#> 183          Veronica officinalis 3.1   3.3      4.7
#> 184                  Vicia sepium 6.5   5.3      5.0
#> 185                   Vinca minor 6.6   6.2      5.3
#> 186                   Viola hirta 7.9   2.6      3.3
#> 187         Viola reichenbachiana 7.1   5.6      5.3
#> 188               Viola riviniana 4.8    NA      4.7
#> 189                  Viscum album  NA    NA       NA
```
