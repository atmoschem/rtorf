# Conservation check for gridded footprints

Compares the total `foot` between the outputs of
[`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md)
and
[`obs_grid_kernel`](https://atmoschem.github.io/rtorf/reference/obs_grid_kernel.md)
and prints a brief summary to the console. A relative difference larger
than 5% triggers a [`warning`](https://rdrr.io/r/base/warning.html) with
diagnostic suggestions.

## Usage

``` r
obs_grid_check(simple, kernel)
```

## Arguments

- simple:

  Output list from
  [`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md).

- kernel:

  Output list from
  [`obs_grid_kernel`](https://atmoschem.github.io/rtorf/reference/obs_grid_kernel.md).

## Value

Invisibly returns a named numeric vector with three elements: `simple`
(total foot from bin-and-sum), `kernel` (total foot from kernel method),
and `relative_diff_pct` (absolute percentage difference relative to
`simple`).

## Details

The kernel method loses a small amount of `foot` at the ±3 sigma
boundary of the truncated Gaussian. Larger differences usually indicate
a grid extent that is too tight (edge particles are discarded) or a
bandwidth that is large relative to the domain.

## See also

[`obs_grid_simple`](https://atmoschem.github.io/rtorf/reference/obs_grid_simple.md),
[`obs_grid_kernel`](https://atmoschem.github.io/rtorf/reference/obs_grid_kernel.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bs <- obs_grid_simple(d, lon_min, lat_min, lon_max, lat_max)
gk <- obs_grid_kernel(d, lon_min, lat_min, lon_max, lat_max,
                      bandwidth = 0.2)
chk <- obs_grid_check(bs, gk)
chk["relative_diff_pct"]
} # }
```
