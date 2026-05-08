# Generate files to perform inverse modeling

This function return a list of three elements.

## Usage

``` r
obs_invfiles(
  master,
  nc = "nc",
  path,
  value = "value",
  value_factor = 1e+09,
  Type = "continuous",
  SubType = "tower-insitu",
  Surface_Elev = 99999,
  Model_agl,
  Data_agl,
  Event = 99999,
  Institution,
  Scale,
  outdir
)
```

## Arguments

- master:

  data.table master file after filtering obspack

- nc:

  column name of master which indicate NetCDF footprints

- path:

  first part of the full path of the .nc footprint files

- value:

  column name with the pollutant

- value_factor:

  numeric factor

- Type:

  "continuous", "flask" or "hatsflask"

- SubType:

  "aircraft-insitu", "tower-insitu", "surface-insitu" and so on

- Surface_Elev:

  Site elevation, default 99999

- Model_agl:

  Model for agl, if missing is column \`altitude_final\`

- Data_agl:

  Model for agl, if missing is column \`altitude_final\`

- Event:

  Number of event

- Institution:

  Institution

- Scale:

  Scale

- outdir:

  String for the output dir

## Value

A list of data.frame

## Details

1\. Footprints_hera_hysplit with the full path to the NetCDF
footprints\\

2\. Obs_hysplit concentration associazted iwth each receptor

3\. Receptor_info_hysplit with receptor info

## Examples

``` r
if (FALSE) { # \dontrun{
# do not run
} # }
```
