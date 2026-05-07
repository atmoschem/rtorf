# 3D footprint gridding (lon, lat, time)

Bins particles into a 3D grid: longitude, latitude, and time. Supports
two methods: "simple" (bin-and-sum) and "kernel" (Gaussian smoothing).

## Usage

``` r
obs_grid_cube(
  x,
  lon_min,
  lat_min,
  lon_max,
  lat_max,
  res = 0.1,
  nt = 240L,
  t0 = 0,
  dt = 60,
  method = c("simple", "kernel"),
  bandwidth = res,
  use_haversine = FALSE,
  n_threads = 1L,
  npar = 1L
)
```

## Arguments

- x:

  A `data.table` or `data.frame` with columns `lat`, `lon`, `time`
  (minutes), and `foot`.

- lon_min, lat_min, lon_max, lat_max:

  Grid extent (degrees).

- res:

  Spatial resolution (degrees).

- nt:

  Number of time layers in the output cube.

- t0:

  Reference time for the first layer (minutes). Default `0`.

- dt:

  Time step per layer (minutes). Default `60` (1 hour).

- method:

  Character. Either `"simple"` for bin-and-sum or `"kernel"` for
  Gaussian smoothing. Default `"simple"`.

- bandwidth:

  Kernel standard deviation for `method = "kernel"`. In degrees if
  `use_haversine = FALSE`, or metres if `TRUE`. Default equals `res`.

- use_haversine:

  Logical. If `TRUE`, uses great-circle distances and `bandwidth` in
  metres for kernel smoothing.

- n_threads:

  Number of OpenMP threads.

- npar:

  Normalization factor (total particles released).

## Value

A named list:

- `grid`:

  Numeric 3D array of dimension `[ny x nx x nt]`.

- `lon, lat`:

  Cell-centre coordinates.

- `time`:

  Start time of each bin (minutes back from `t0`).
