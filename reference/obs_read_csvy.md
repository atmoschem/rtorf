# reads CSVY

Reads CSVY, print YAML and fread file.

## Usage

``` r
obs_read_csvy(f, n = 100, ...)
```

## Arguments

- f:

  path to csvy file

- n:

  number of files to search for "—" yaml

- ...:

  extra data.table arguments

## Value

a data.table from a csvy file

## See also

Other helpers:
[`fex()`](https://atmoschem.github.io/rtorf/reference/fex.md),
[`obs_footname()`](https://atmoschem.github.io/rtorf/reference/obs_footname.md),
[`obs_format()`](https://atmoschem.github.io/rtorf/reference/obs_format.md),
[`obs_freq()`](https://atmoschem.github.io/rtorf/reference/obs_freq.md),
[`obs_list.dt()`](https://atmoschem.github.io/rtorf/reference/obs_list.dt.md),
[`obs_out()`](https://atmoschem.github.io/rtorf/reference/obs_out.md),
[`obs_rbind()`](https://atmoschem.github.io/rtorf/reference/obs_rbind.md),
[`obs_roundtime()`](https://atmoschem.github.io/rtorf/reference/obs_roundtime.md),
[`obs_trunc()`](https://atmoschem.github.io/rtorf/reference/obs_trunc.md),
[`obs_write_csvy()`](https://atmoschem.github.io/rtorf/reference/obs_write_csvy.md),
[`rtorf-deprecated`](https://atmoschem.github.io/rtorf/reference/rtorf-deprecated.md),
[`sr()`](https://atmoschem.github.io/rtorf/reference/sr.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Do not run
df <- data.frame(a = rnorm(n = 10),
                 time = Sys.time() + 1:10)

f <- paste0(tempfile(), ".csvy")
notes <- c("notes",
           "more notes")
obs_write_csvy(dt = df, notes = notes, out = f)
s <- obs_read_csvy(f)
s
# or
readLines(f)
data.table::fread(f)
} # }
```
