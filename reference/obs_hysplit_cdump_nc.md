# Write HYSPLIT concentrations as a CF-compliant NetCDF

Writes the output of
[`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md)
as a NetCDF-4 file following the CF conventions (version 1.9), with
dimensions `time`, `z`, `y`, `x` and `bnds`. Each species is stored as a
float variable `(time, z, y, x)` with deflate compression. Cell bounds
are provided by the variables `time_bounds`, `z_bounds`,
`latitude_bounds` and `longitude_bounds`, and the spherical-earth grid
mapping by the scalar variable `crs`.

## Usage

``` r
obs_hysplit_cdump_nc(
  x,
  nc_out,
  height_reference = c("sea_level", "ground_level"),
  control = NULL,
  setup = NULL,
  verbose = FALSE
)
```

## Arguments

- x:

  A list produced by
  [`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md).

- nc_out:

  Path of the NetCDF file to create.

- height_reference:

  Reference of the level heights: `"sea_level"` (default, z standard
  name `height_above_mean_sea_level`) or `"ground_level"`
  (`height_above_ground`, matching `KMSL = 0` in HYSPLIT).

- control:

  Path of the HYSPLIT CONTROL file to embed in the global attribute
  `hysplit_control`. Default `NULL` looks for `CONTROL` in the directory
  of the source cdump file; `NA` disables the embedding.

- setup:

  Path of the HYSPLIT SETUP.CFG file to embed in the global attribute
  `hysplit_setup`. Default `NULL` looks for `SETUP.CFG` in the directory
  of the source cdump file; `NA` disables the embedding.

- verbose:

  Logical, to display more information.

## Value

The path of the created NetCDF file, invisibly.

## Note

The `time` coordinate is hours since the start of the first sampling
period, at the middle of each period, with calendar `standard`. The
concentration units are `"<massunit> m-3"` and the standard name
`mass_concentration_of_<pollutant>_in_air`, both carried from
[`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md).

## See also

[`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md),
[`obs_hysplit_cdump2nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump2nc.md),
[`obs_nc_get`](https://atmoschem.github.io/rtorf/reference/obs_nc_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
cd <- obs_hysplit_cdump_read("cdump")
obs_hysplit_cdump_nc(cd, "cdump.nc")
} # }
```
