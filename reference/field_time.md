# Durée de terrain estimée

Pour les points de rang 0 : relevé (`t_releve_min`) et tarière
(`t_tariere_min`), marche aller-retour depuis le tronçon
(`2 * cout_m * detour` à `v_marche_kmh`), route entre points visités
dans l'ordre du plus proche voisin depuis le point le plus à l'ouest
(distance à vol d'oiseau `* detour` à `v_route_kmh`). Le trajet depuis
la base n'est pas compté. **Tous les paramètres sont provisoires**, à
confirmer par Pascal.

## Usage

``` r
field_time(
  plan,
  t_releve_min = 60,
  t_tariere_min = 20,
  v_marche_kmh = 2,
  v_route_kmh = 30,
  detour = 1.3,
  h_jour = 7
)
```

## Arguments

- plan:

  Résultat de
  [`sampling_plan()`](https://pobsteta.github.io/sylvostation/reference/sampling_plan.md).

- t_releve_min, t_tariere_min:

  Durées par point, en minutes (60 et 20).

- v_marche_kmh:

  Vitesse de marche hors piste (2 km/h).

- v_route_kmh:

  Vitesse sur route et chemin (30 km/h).

- detour:

  Facteur de détour appliqué aux distances à vol d'oiseau (1,3).

- h_jour:

  Heures de terrain utiles par jour (7).

## Value

Liste : `par_point` (`ordre`, `id`, `releve_min`, `marche_min`,
`route_min`), `total_h`, `jours`, `parametres`.

## Examples

``` r
if (FALSE) { # \dontrun{
field_time(p)$jours
} # }
```
