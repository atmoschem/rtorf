# Gaussian kernel footprint gridding

Computes a gridded footprint by spreading each particle's `foot` value
over neighbouring cells using a 2-D isotropic Gaussian kernel. The
kernel integrates to 1 (cell area `lon_res * lat_res` is included in the
weight), so the total `foot` is approximately conserved — the small
residual arises from truncation at ±3 sigma.

## Usage

``` r
obs_grid_kernel(
  x,
  lon_min,
  lat_min,
  lon_max,
  lat_max,
  lon_res = 0.1,
  lat_res = 0.1,
  bandwidth = lon_res,
  use_haversine = FALSE,
  n_threads = 1L,
  npar = 1L
)
```

## Arguments

- x:

  A `data.table` or `data.frame` with columns `lat`, `lon`, and `foot`
  (same units as
  [`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md)).

- lon_min:

  Western edge of the output grid (degrees).

- lat_min:

  Southern edge of the output grid (degrees).

- lon_max:

  Eastern edge of the output grid (degrees).

- lat_max:

  Northern edge of the output grid (degrees).

- lon_res:

  Cell width in longitude (degrees). Default `0.1`.

- lat_res:

  Cell height in latitude (degrees). Default `0.1`.

- bandwidth:

  Kernel standard deviation. Units depend on `use_haversine`:

  - `use_haversine = FALSE` (default) — degrees. Recommended starting
    value: `lon_res` (one cell). Increase to `2 * lon_res` for sparser
    particle sets.

  - `use_haversine = TRUE` — metres. A typical value for 0.1-degree
    grids is `11000` (approximately one degree at mid-latitudes).

  Default `lon_res`.

- use_haversine:

  Logical. If `FALSE` (default), Cartesian distance in degrees is used —
  fast and adequate for domains smaller than ~1000 km and latitudes
  below ~60 degrees. If `TRUE`, great-circle distance via the Haversine
  formula is used — accurate at high latitudes and continental-scale
  domains; `bandwidth` must then be supplied in metres. A warning is
  issued when `use_haversine = TRUE` and `bandwidth < 100`, which
  suggests degrees were passed instead of metres.

- n_threads:

  Number of OpenMP threads. Default `1L`.

- npar:

  Number of particles for normalization. Default `1L`.

## Value

A named list with the same structure as
[`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md):

- `grid`:

  Numeric matrix `[nlon x nlat]` of kernel-smoothed `foot`.

- `lon`:

  Cell-centre longitude vector.

- `lat`:

  Cell-centre latitude vector.

## Details

Use this function when particle density is too low to fill every grid
cell, or for display purposes. For analyses that require exact
conservation of the total sensitivity, prefer
[`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md).

## Note

The Fortran routine skips particles with `foot == 0` before entering the
kernel loop, so sparse footprints with many zero-weight particles incur
no unnecessary computation.

## See also

[`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md)
for the unsmoothed primary output,
[`obs_grid_check`](https://atmoschem.github.io/rtorf/reference/obs_grid_check.md)
to verify conservation between the two methods.

## Examples

``` r
if (FALSE) { # \dontrun{
library(data.table)
dat <- fread("PARTICLE.DAT")
d   <- dat[time %in% sort(unique(time))[1:4]]

# Cartesian mode (degrees, fast)
gk <- obs_grid_kernel(
  x             = d,
  lon_min       = floor(min(d$lon))   - 0.1,
  lat_min       = floor(min(d$lat))   - 0.1,
  lon_max       = ceiling(max(d$lon)) + 0.1,
  lat_max       = ceiling(max(d$lat)) + 0.1,
  lon_res       = 0.1,
  lat_res       = 0.1,
  bandwidth     = 0.2,          # 2-cell sigma in degrees
  use_haversine = FALSE,
  n_threads     = 4L
)
image(gk$lon, gk$lat, log1p(gk$grid), main = "Gaussian kernel")

# Haversine mode (metres, accurate at high latitudes)
gk_hav <- obs_grid_kernel(
  x             = d,
  lon_min       = -130, lat_min = 55,
  lon_max       = -100, lat_max = 75,
  lon_res       = 0.1,  lat_res = 0.1,
  bandwidth     = 15000,        # 15 km
  use_haversine = TRUE,
  n_threads     = 4L
)
} # }
```
