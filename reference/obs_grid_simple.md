# Bin-and-sum footprint gridding

Bins STILT/HYSPLIT particles into a regular longitude/latitude grid and
sums the `foot` sensitivity values per cell. This is the primary
scientific output: no smoothing is applied, no foot is redistributed
spatially, and the grid total exactly equals the particle total.

## Usage

``` r
obs_grid_simple(
  x,
  lon_min,
  lat_min,
  lon_max,
  lat_max,
  res = 0.1,
  n_threads = 1L,
  npar = 1L
)
```

## Arguments

- x:

  A `data.table` or `data.frame` with at least the columns `lat`
  (degrees), `lon` (degrees), and `foot` (sensitivity, ppm / (umol m-2
  s-1)).

- lon_min:

  Western edge of the output grid (degrees).

- lat_min:

  Southern edge of the output grid (degrees).

- lon_max:

  Eastern edge of the output grid (degrees).

- lat_max:

  Northern edge of the output grid (degrees).

- res:

  Cell size in degrees. Both longitude and latitude use the same value
  (square cells). Default `0.1`.

- n_threads:

  Number of OpenMP threads passed to the Fortran routine. Default `1L`.
  Increase for large particle sets (\> ~50 000 rows); for smaller sets
  the thread-management overhead outweighs the gain.

- npar:

  Number of particles used for normalization. The output grid is divided
  by this value to return the average footprint sensitivity. Default
  `1L`.

## Value

A named list with three elements:

- `grid`:

  Numeric matrix of dimension `[nlon x nlat]` containing the summed
  `foot` per cell, divided by `npar`. Row `i` corresponds to `lon[i]`,
  column `j` to `lat[j]`.

- `lon`:

  Numeric vector of cell-centre longitudes (length `nlon`).

- `lat`:

  Numeric vector of cell-centre latitudes (length `nlat`).

## Note

Particles whose coordinates fall outside the rectangle
`[lon_min, lon_max) x [lat_min, lat_max)` are silently discarded. Add a
small buffer to the grid extent if edge particles matter.

## See also

[`obs_grid_kernel`](https://atmoschem.github.io/rtorf/reference/obs_grid_kernel.md)
for a smoothed alternative,
[`obs_grid_check`](https://atmoschem.github.io/rtorf/reference/obs_grid_check.md)
to compare totals.

## Examples

``` r
if (FALSE) { # \dontrun{
library(data.table)
dat <- fread("PARTICLE.DAT")
d   <- dat[time %in% sort(unique(time))[1:4]]   # first hour

bs <- obs_grid_simple(
  x         = d,
  lon_min   = floor(min(d$lon))   - 0.1,
  lat_min   = floor(min(d$lat))   - 0.1,
  lon_max   = ceiling(max(d$lon)) + 0.1,
  lat_max   = ceiling(max(d$lat)) + 0.1,
  res       = 0.1,
  n_threads = 4L
)
image(bs$lon, bs$lat, log1p(bs$grid), main = "Bin and sum")
} # }
```
