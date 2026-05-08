# obs_load_ncdf

NetCDF list of var and attributes

## Usage

``` r
obs_load_ncdf(
  ncname,
  vars = NULL,
  grps = NULL,
  dims = TRUE,
  useoldfoot = FALSE,
  attribs = "Conventions",
  var.attribs = NULL,
  gz = FALSE,
  tmpdir = tempdir(),
  tmpfile = tempfile("load.ncdf4", tmpdir = tmpdir),
  clean = TRUE,
  lowercase = FALSE,
  gsubdot = FALSE,
  verbose = FALSE
)
```

## Arguments

- ncname:

  pathname of NetCDF4 file

- vars:

  specify variables to retrieve otherwise all are returned (NOTE: '/'
  indicates only return root group)

- grps:

  groups

- dims:

  return variable dimensions TRUE/FALSE

- useoldfoot:

  old footprints have dim order: lat,lon,time but new footprints (CF-1.6
  convention and on) have dim order: lon,lat,time; this option flips
  lat/lon dim order of returned footprints for backwards compatibility;
  TRUE =\> flips new footprints to old convention; FALSE =\> flips old
  footprints to new convention

- attribs:

  array of names of global file attributes to return (NOTE: this is for
  backwards compatibility - current version automatically returns all
  global file attributes)

- var.attribs:

  array of names of variable attributes to return (NOTE: this is for
  backwards compatibility - current version automatically returns all
  attributes for variables and dimensions)

- gz:

  netCDF file is gzipped. Note that .nc may be already compressed.

- tmpdir:

  temporary directory to unzip netCDF file

- tmpfile:

  temporary unzipped netCDF file name

- clean:

  remove temporary file after processing

- lowercase:

  return all list names in lowercase

- gsubdot:

  substitute '\_' with '.' in all list variable names

- verbose:

  logical, to show more messages

## Value

list of NetCDF vars and attributes

## See also

Other helpers legacy:
[`obs_decimal_to_POSIX`](https://atmoschem.github.io/rtorf/reference/obs_decimal_to_POSIX.md)`()`,
[`obs_grid`](https://atmoschem.github.io/rtorf/reference/obs_grid.md)`()`,
[`obs_id2pos`](https://atmoschem.github.io/rtorf/reference/obs_id2pos.md)`()`,
[`obs_info2id`](https://atmoschem.github.io/rtorf/reference/obs_info2id.md)`()`,
[`obs_interpret_udunits_time`](https://atmoschem.github.io/rtorf/reference/obs_interpret_udunits_time.md)`()`,
[`obs_julian`](https://atmoschem.github.io/rtorf/reference/obs_julian.md)`()`,
[`obs_normalize_dmass`](https://atmoschem.github.io/rtorf/reference/obs_normalize_dmass.md)`()`,
[`obs_traj_foot`](https://atmoschem.github.io/rtorf/reference/obs_traj_foot.md)`()`

## Examples
