# obs_foot_flip

Reorders the axes of a 3-D footprint array produced by
[`obs_traj_foot`](https://atmoschem.github.io/rtorf/reference/obs_traj_foot.md)
so that its dimension order matches the CF-convention expected by
[`obs_nc`](https://atmoschem.github.io/rtorf/reference/obs_nc.md) /
`terra::rast()`, or converts back in the opposite direction.

## Usage

``` r
obs_foot_flip(arr, from = c("traj", "cf"), flip_lat = FALSE, flip_lon = FALSE)
```

## Arguments

- arr:

  A 3-D numeric array. Two layouts are accepted:

  - `"traj"` (default) — `[lat, lon, time]` as produced by
    `obs_traj_foot`. Converted to `[lon, lat, time]`.

  - `"cf"` — `[lon, lat, time]` (CF / terra layout). Converted back to
    `[lat, lon, time]`.

- from:

  Character string, either `"traj"` or `"cf"`. Describes the current
  axis order of `arr`. Default `"traj"`.

- flip_lat:

  Logical. If `TRUE` (default) the latitude axis is also reversed so
  that index 1 corresponds to the southern-most row, matching the
  south-to-north order expected by CF tools and `terra`. Set to `FALSE`
  if the array is already in south-to-north order.

- flip_lon:

  Logical. If `TRUE` (default) the longitude axis is reversed so that
  index 1 corresponds to the western-most column. Set to `FALSE` if the
  array is already in west-to-east order.

## Value

A 3-D array with reordered (and optionally flipped) axes.

## Details

**Why this is needed.** `obs_traj_foot` returns an array with dimensions
`[lat, lon, time]` (R row-major: row = latitude index). NetCDF files
written with `obs_nc` preserve that order, but `terra::rast()` follows
the CF / GIS convention where the *first* spatial dimension is longitude
(x-axis). Reading the file back with `terra` therefore transposes the
spatial plane, which is why a [`t()`](https://rdrr.io/r/base/t.html)
call was needed on the raster.

Calling `obs_foot_flip(arr)` before passing the array to `obs_nc` (or
after reading it back) resolves the mismatch without manual transposing.

## See also

[`obs_traj_foot`](https://atmoschem.github.io/rtorf/reference/obs_traj_foot.md),
[`obs_nc`](https://atmoschem.github.io/rtorf/reference/obs_nc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# foot.arr comes from obs_traj_foot: dims [lat, lon, time]
foot_cf <- obs_foot_flip(foot.arr)       # now [lon, lat, time]

obs_nc(
  lat      = lats,
  lon      = lons,
  time_nc  = time_vec,
  vars_out = "foot1",
  units_out = "(ppb/nanomol m-2 s-1)",
  nc_out   = "output.nc",
  larrays  = list(foot1 = foot_cf)
)
# terra::rast("output.nc") now reads correctly without t()
} # }
```
