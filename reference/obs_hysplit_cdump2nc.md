# Convert a HYSPLIT cdump file to CF-compliant NetCDF

One-call wrapper around
[`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md)
and
[`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md):
reads the binary HYSPLIT concentration file and writes the equivalent
CF-compliant NetCDF with dimensions `time`, `z`, `y`, `x`.

## Usage

``` r
obs_hysplit_cdump2nc(
  cdump,
  nc_out = NULL,
  drange = NULL,
  century = NULL,
  massunit = "1",
  pollutant = "pollutant",
  height_reference = c("sea_level", "ground_level"),
  control = NULL,
  setup = NULL,
  verbose = FALSE
)
```

## Arguments

- cdump:

  Path to the binary cdump file.

- nc_out:

  Path of the NetCDF file to create. Default `NULL` writes `<cdump>.nc`
  next to the source file.

- drange:

  Optional period to load, see
  [`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md).

- century:

  Integer century for the 2-digit years, see
  [`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md).

- massunit:

  Mass unit of the concentrations. Default `"1"`.

- pollutant:

  Species name used to build the CF `standard_name`. Default
  `"pollutant"`.

- height_reference:

  Reference of the level heights, see
  [`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md).

- control:

  Path of the CONTROL file to embed, see
  [`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md).

- setup:

  Path of the SETUP.CFG file to embed, see
  [`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md).

- verbose:

  Logical, to display more information.

## Value

The path of the created NetCDF file, invisibly.

## See also

[`obs_hysplit_cdump_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_read.md),
[`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
obs_hysplit_cdump2nc("cdump")
} # }
```
