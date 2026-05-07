# obs_grid

add columns of

## Usage

``` r
obs_grid(
  min.x,
  max.x,
  min.y,
  max.y,
  numpix.x,
  numpix.y,
  coarse.factor = 1,
  adaptive = TRUE
)
```

## Arguments

- min.x:

  grid indices

- max.x:

  grid indices

- min.y:

  grid indices

- max.y:

  grid indices

- numpix.x:

  number pixels x

- numpix.y:

  number pixels y

- coarse.factor:

  integer to coarse the grid resolution

- adaptive:

  logical, to use adaptive gridding

## Value

return footprint

## See also

Other helpers legacy:
[`obs_id2pos()`](https://atmoschem.github.io/rtorf/reference/obs_id2pos.md),
[`obs_info2id()`](https://atmoschem.github.io/rtorf/reference/obs_info2id.md),
[`obs_julian()`](https://atmoschem.github.io/rtorf/reference/obs_julian.md),
[`obs_normalize_dmass()`](https://atmoschem.github.io/rtorf/reference/obs_normalize_dmass.md),
[`obs_traj_foot()`](https://atmoschem.github.io/rtorf/reference/obs_traj_foot.md)

## Examples

``` r
obs_grid(1, 10, 1, 10, 100, 100, 1)
#>    xpart ypart gridname
#>    <num> <num>    <num>
#> 1:     0     0        4
```
