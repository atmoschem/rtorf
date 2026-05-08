# list.dt

Some treatments for list of data.frames

## Usage

``` r
obs_list.dt(ldf, na, verbose = TRUE)
```

## Arguments

- ldf:

  list of data.frames

- na:

  common names in the final data.frame

- verbose:

  Logical to show more information

## Value

long data.table

## Note

1\. Filter out empty data.frames 2. identify common names 3. rbindlist
and return data.table

## See also

Other helpers:
[`fex()`](https://atmoschem.github.io/rtorf/reference/fex.md),
[`obs_footname()`](https://atmoschem.github.io/rtorf/reference/obs_footname.md),
[`obs_format()`](https://atmoschem.github.io/rtorf/reference/obs_format.md),
[`obs_freq()`](https://atmoschem.github.io/rtorf/reference/obs_freq.md),
[`obs_out()`](https://atmoschem.github.io/rtorf/reference/obs_out.md),
[`obs_rbind()`](https://atmoschem.github.io/rtorf/reference/obs_rbind.md),
[`obs_read_csvy()`](https://atmoschem.github.io/rtorf/reference/obs_read_csvy.md),
[`obs_roundtime()`](https://atmoschem.github.io/rtorf/reference/obs_roundtime.md),
[`obs_trunc()`](https://atmoschem.github.io/rtorf/reference/obs_trunc.md),
[`obs_write_csvy()`](https://atmoschem.github.io/rtorf/reference/obs_write_csvy.md),
[`rtorf-deprecated`](https://atmoschem.github.io/rtorf/reference/rtorf-deprecated.md),
[`sr()`](https://atmoschem.github.io/rtorf/reference/sr.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Do not run
} # }
```
