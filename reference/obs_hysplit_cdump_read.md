# Read a HYSPLIT binary concentration file (cdump)

Parses the binary concentration output written by the HYSPLIT dispersion
model (usually named `cdump`). The file is a sequence of big-endian
Fortran records: a header with the meteorological model, the release
locations, the concentration grid and the vertical levels, followed by
one block per sampling time with the non-zero concentrations stored in
sparse form (1-based longitude index, latitude index, concentration).

## Usage

``` r
obs_hysplit_cdump_read(
  cdump,
  drange = NULL,
  century = NULL,
  massunit = "1",
  pollutant = "pollutant",
  verbose = FALSE
)
```

## Arguments

- cdump:

  Path to the binary cdump file.

- drange:

  Optional vector of length 2 with the start and end of the period to
  load (coerced with
  [`as.POSIXct`](https://rdrr.io/r/base/as.POSIXlt.html), time zone
  UTC). Sampling periods fully inside `drange` are kept; reading stops
  after the first period starting after `drange[2]`. Default `NULL`
  loads everything.

- century:

  Integer century (e.g. `2000`) used to expand the 2-digit years stored
  in the file. Default `NULL` guesses it from the first release year
  (`< 50` maps to 2000, otherwise 1900).

- massunit:

  Mass unit of the concentrations, used only for metadata. Default `"1"`
  (unit emission).

- pollutant:

  Species name used to build the CF `standard_name` of the concentration
  variables. Default `"pollutant"`.

- verbose:

  Logical, to display more information.

## Value

A named list (invisible `NULL` with a warning when the file has no
non-zero concentration in the requested period):

- `cdump`:

  Path of the source file.

- `species`:

  Character vector with the species found.

- `concentrations`:

  Named list with one 4-D numeric array `[x, y, z, time]` per species.

- `x`, `y`:

  Integer vectors with the 1-based HYSPLIT grid indices spanned by the
  data.

- `lon`, `lat`:

  Numeric vectors with the cell-center coordinates (degrees) for `x` and
  `y`.

- `z`:

  Numeric vector with the height of the center of each vertical layer
  (m).

- `z_bounds`:

  Matrix `[z, 2]` with the bottom and top of each vertical layer (m).

- `level_heights`:

  Integer vector with the level top heights (m) from the file header.

- `time`:

  `POSIXct` vector (UTC) with the middle of each sampling period.

- `time_start`, `time_end`:

  `POSIXct` vectors with the start and end of each sampling period.

- `atts`:

  Named list with the global attributes extracted from the header
  (meteorological model, sources, grid definition, levels, species and
  sampling period).

- `massunit`, `pollutant`:

  The input arguments, carried over for
  [`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md).

## Details

The sparse values are scattered into dense 4-D arrays with dimensions
`[x, y, z, time]`, where `x` and `y` are the 1-based HYSPLIT grid
indices. Missing cells are zero concentration. Grid points are the
centers of the sampling cells.

## Note

Longitudes equal or above 180.001 degrees are wrapped to the -180/180
range. The vertical levels reported in the data are the tops of the
layers declared in the header; the level bounds are (0, h1), (h1, h2),
... and the reported `z` is the layer midpoint.

## See also

[`obs_hysplit_cdump_nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump_nc.md)
to write the result as CF-compliant NetCDF,
[`obs_hysplit_cdump2nc`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_cdump2nc.md)
for a one-call conversion,
[`obs_hysplit_control_read`](https://atmoschem.github.io/rtorf/reference/obs_hysplit_control_read.md)
for the HYSPLIT CONTROL file.

## Examples

``` r
if (FALSE) { # \dontrun{
cd <- obs_hysplit_cdump_read("cdump")
str(cd$concentrations[[cd$species[1]]])
} # }
```
