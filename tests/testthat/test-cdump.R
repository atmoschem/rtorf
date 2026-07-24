# ── obs_hysplit_cdump_read ─────────────────────────────────

test_that("obs_hysplit_cdump_read reads header, grid and sparse data", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  write_test_cdump(tmp)

  x <- obs_hysplit_cdump_read(tmp)

  expect_equal(x$species, "TEST")
  expect_equal(x$x, 1:5)
  expect_equal(x$y, 1:4)
  expect_equal(x$lat, -16.5 + (0:3) * 0.5)
  expect_equal(x$lon, -48.5 + (0:4) * 0.5)
  expect_equal(x$z, c(50, 300))
  expect_equal(
    unname(x$z_bounds),
    matrix(c(0, 100, 100, 500), ncol = 2, byrow = TRUE)
  )
  expect_equal(
    x$time,
    as.POSIXct(c("2024-06-15 01:30:00", "2024-06-15 02:30:00"), tz = "UTC")
  )
  expect_equal(
    x$time_start,
    as.POSIXct(c("2024-06-15 01:00:00", "2024-06-15 02:00:00"), tz = "UTC")
  )
  expect_equal(
    x$time_end,
    as.POSIXct(c("2024-06-15 02:00:00", "2024-06-15 03:00:00"), tz = "UTC")
  )

  a <- x$concentrations$TEST
  expect_equal(dim(a), c(5L, 4L, 2L, 2L))
  expect_equal(a[1, 1, 1, 1], 1.5)
  expect_equal(a[2, 3, 1, 1], 2.5)
  expect_equal(a[5, 4, 1, 1], 3.5)
  expect_equal(a[3, 2, 2, 1], 4.5)
  expect_equal(a[4, 4, 1, 2], 5.5)
  expect_equal(sum(a), 1.5 + 2.5 + 3.5 + 4.5 + 5.5)
  # second period has no data on level 500 m
  expect_true(all(a[, , 2, 2] == 0))

  expect_equal(x$atts$meteorological_model, "GFS0")
  expect_equal(x$atts$source_count, 2L)
  expect_equal(x$atts$source_dates, rep("20240615.000000", 2))
  expect_equal(x$atts$latitude_point_count, 4L)
  expect_equal(x$atts$longitude_point_count, 5L)
  expect_equal(x$atts$level_heights, c(100L, 500L))
  expect_equal(x$atts$number_of_species, 1L)
  expect_equal(x$atts$Species_ID, "TEST")
  expect_equal(x$atts$sampling_period_hours, 1)
  expect_equal(
    x$atts[["Coordinate time description"]],
    "Middle of sampling time"
  )
})

test_that("obs_hysplit_cdump_read guesses or honours the century", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  write_test_cdump(tmp)

  # 2-digit year 24 guessed as 2024
  x <- obs_hysplit_cdump_read(tmp)
  expect_true(all(format(x$time_start, "%Y") == "2024"))

  # explicit century
  x <- obs_hysplit_cdump_read(tmp, century = 1900)
  expect_true(all(format(x$time_start, "%Y") == "1924"))
  expect_match(x$atts$source_dates[1], "^1924")
})

test_that("obs_hysplit_cdump_read filters with drange", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  write_test_cdump(tmp)

  # keep only the first period (second ends after drange[2])
  x <- obs_hysplit_cdump_read(
    tmp,
    drange = as.POSIXct(c("2024-06-15 01:00:00", "2024-06-15 02:00:00"),
      tz = "UTC"
    )
  )
  expect_equal(length(x$time), 1L)
  expect_equal(x$concentrations$TEST[4, 4, 1, 1], 0)

  # keep only the second period (data collapses to the spanned cells)
  x <- obs_hysplit_cdump_read(
    tmp,
    drange = as.POSIXct(c("2024-06-15 01:30:00", "2024-06-15 03:00:00"),
      tz = "UTC"
    )
  )
  expect_equal(length(x$time), 1L)
  expect_equal(x$x, 4L)
  expect_equal(x$y, 4L)
  expect_equal(x$concentrations$TEST[1, 1, 1, 1], 5.5)

  # invalid drange
  expect_error(
    obs_hysplit_cdump_read(tmp, drange = "2024-06-15"),
    "length 2"
  )
})

test_that("obs_hysplit_cdump_read wraps longitudes >= 180.001", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  wrap_times <- list(list(
    start = c(24L, 6L, 15L, 1L, 0L),
    end = c(24L, 6L, 15L, 2L, 0L),
    levels = list(
      list(lev = 100L, x = 1:3, y = 1L, conc = c(1, 2, 3)),
      list(lev = 500L, x = integer(0), y = integer(0), conc = numeric(0))
    )
  ))
  write_test_cdump(tmp, nlon = 3L, dlon = 1, ll_lon = 179.5, times = wrap_times)
  x <- obs_hysplit_cdump_read(tmp)
  expect_equal(x$lon, c(179.5, -179.5, -178.5))
})

test_that("obs_hysplit_cdump_read returns NULL for all-zero files", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  empty <- list(list(
    start = c(24L, 6L, 15L, 1L, 0L),
    end = c(24L, 6L, 15L, 2L, 0L),
    levels = list(
      list(lev = 100L, x = integer(0), y = integer(0), conc = numeric(0)),
      list(lev = 500L, x = integer(0), y = integer(0), conc = numeric(0))
    )
  ))
  write_test_cdump(tmp, times = empty)
  expect_warning(
    x <- obs_hysplit_cdump_read(tmp),
    "No concentration data"
  )
  expect_null(x)
})

test_that("obs_hysplit_cdump_read validates inputs", {
  expect_error(obs_hysplit_cdump_read(), "single string")
  expect_error(
    obs_hysplit_cdump_read(file.path(tempdir(), "no_such_cdump")),
    "not found"
  )
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  writeBin(raw(10), tmp)
  expect_error(obs_hysplit_cdump_read(tmp), "record 1")
})

# ── obs_hysplit_cdump_nc ───────────────────────────────────

test_that("obs_hysplit_cdump_nc writes a CF-compliant NetCDF", {
  tmp <- tempfile(fileext = ".bin")
  ncf <- tempfile(fileext = ".nc")
  on.exit(unlink(c(tmp, ncf)))
  write_test_cdump(tmp)
  x <- obs_hysplit_cdump_read(tmp)
  obs_hysplit_cdump_nc(x, ncf)

  nc <- ncdf4::nc_open(ncf)
  on.exit(ncdf4::nc_close(nc), add = TRUE)

  expect_true(all(c("x", "y", "z", "time", "bnds") %in% names(nc$dim)))
  expect_equal(nc$dim$bnds$len, 2L)
  expect_true(all(
    c(
      "TEST", "latitude", "longitude", "z_bounds", "latitude_bounds",
      "longitude_bounds", "time_bounds", "crs"
    ) %in% names(nc$var)
  ))

  # coordinate values
  expect_equal(as.vector(ncdf4::ncvar_get(nc, "time")), c(0.5, 1.5))
  expect_equal(
    ncdf4::ncvar_get(nc, "time_bounds"),
    matrix(c(0, 1, 1, 2), nrow = 2)
  )
  expect_equal(as.vector(ncdf4::ncvar_get(nc, "z")), c(50, 300))
  expect_equal(
    ncdf4::ncvar_get(nc, "z_bounds"),
    matrix(c(0, 100, 100, 500), nrow = 2)
  )
  expect_equal(
    as.vector(ncdf4::ncvar_get(nc, "latitude")),
    -16.5 + (0:3) * 0.5
  )
  expect_equal(
    as.vector(ncdf4::ncvar_get(nc, "longitude")),
    -48.5 + (0:4) * 0.5
  )
  expect_equal(
    ncdf4::ncvar_get(nc, "latitude_bounds")[, 1],
    c(-16.75, -16.25)
  )

  # data round-trip
  a <- ncdf4::ncvar_get(nc, "TEST")
  expect_equal(dim(a), c(5L, 4L, 2L, 2L))
  expect_equal(a[1, 1, 1, 1], 1.5, tolerance = 1e-6)
  expect_equal(a[3, 2, 2, 1], 4.5, tolerance = 1e-6)
  expect_equal(a[4, 4, 1, 2], 5.5, tolerance = 1e-6)

  # CF attributes of variables and coordinates
  expect_equal(
    ncdf4::ncatt_get(nc, "TEST", "units")$value,
    "1 m-3"
  )
  expect_equal(
    ncdf4::ncatt_get(nc, "TEST", "standard_name")$value,
    "mass_concentration_of_pollutant_in_air"
  )
  expect_equal(
    ncdf4::ncatt_get(nc, "time", "units")$value,
    "hours since 2024-06-15 01:00:00Z"
  )
  expect_equal(ncdf4::ncatt_get(nc, "time", "calendar")$value, "standard")
  expect_equal(ncdf4::ncatt_get(nc, "time", "axis")$value, "T")
  expect_equal(ncdf4::ncatt_get(nc, "time", "bounds")$value, "time_bounds")
  expect_equal(
    ncdf4::ncatt_get(nc, "z", "standard_name")$value,
    "height_above_mean_sea_level"
  )
  expect_equal(ncdf4::ncatt_get(nc, "z", "positive")$value, "up")
  expect_equal(ncdf4::ncatt_get(nc, "z", "axis")$value, "Z")
  expect_equal(ncdf4::ncatt_get(nc, "z", "bounds")$value, "z_bounds")
  expect_equal(ncdf4::ncatt_get(nc, "latitude", "axis")$value, "Y")
  expect_equal(
    ncdf4::ncatt_get(nc, "latitude", "bounds")$value,
    "latitude_bounds"
  )
  expect_equal(ncdf4::ncatt_get(nc, "longitude", "axis")$value, "X")
  expect_equal(
    ncdf4::ncatt_get(nc, "crs", "grid_mapping_name")$value,
    "latitude_longitude"
  )
  expect_equal(ncdf4::ncatt_get(nc, "crs", "earth_radius")$value, 6371200)

  # global attributes
  ga <- ncdf4::ncatt_get(nc, 0)
  expect_equal(ga$Conventions, "CF-1.9")
  expect_equal(ga$title, "HYSPLIT simulation air concentration data")
  expect_equal(ga$meteorological_model, "GFS0")
  expect_equal(ga$source_count, 2L)
  expect_equal(ga$level_heights, c(100L, 500L))
  expect_equal(ga$Species_ID, "TEST")
  expect_equal(ga$sampling_period_hours, 1)
  expect_true(all(c("history", "generation_datetime", "created_by_script") %in% names(ga)))
})

test_that("obs_hysplit_cdump_nc honours height_reference", {
  tmp <- tempfile(fileext = ".bin")
  ncf <- tempfile(fileext = ".nc")
  on.exit(unlink(c(tmp, ncf)))
  write_test_cdump(tmp)
  x <- obs_hysplit_cdump_read(tmp)
  obs_hysplit_cdump_nc(x, ncf, height_reference = "ground_level")
  nc <- ncdf4::nc_open(ncf)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  expect_equal(
    ncdf4::ncatt_get(nc, "z", "standard_name")$value,
    "height_above_ground"
  )
})

test_that("obs_hysplit_cdump_nc validates inputs", {
  expect_error(obs_hysplit_cdump_nc(list(), "x.nc"), "obs_hysplit_cdump_read")
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  write_test_cdump(tmp)
  x <- obs_hysplit_cdump_read(tmp)
  expect_error(obs_hysplit_cdump_nc(x), "single string")
})

# ── obs_hysplit_cdump2nc ───────────────────────────────────

test_that("obs_hysplit_cdump2nc converts and embeds CONTROL/SETUP.CFG", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  cdump <- file.path(dir, "cdump")
  write_test_cdump(cdump)
  writeLines("2024 06 15 00 00", file.path(dir, "CONTROL"))
  writeLines("&SETUP", file.path(dir, "SETUP.CFG"))

  ncf <- obs_hysplit_cdump2nc(cdump, verbose = TRUE)
  expect_equal(ncf, paste0(cdump, ".nc"))
  expect_true(file.exists(ncf))

  nc <- ncdf4::nc_open(ncf)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  ga <- ncdf4::ncatt_get(nc, 0)
  # embedded files are the last two global attributes
  expect_equal(tail(names(ga), 2), c("hysplit_control", "hysplit_setup"))
  expect_match(ga$hysplit_control, "2024 06 15 00 00")
  expect_match(ga$hysplit_setup, "&SETUP")
  expect_equal(dim(ncdf4::ncvar_get(nc, "TEST")), c(5L, 4L, 2L, 2L))
})

test_that("obs_hysplit_cdump2nc can skip the CONTROL/SETUP.CFG embedding", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  cdump <- file.path(dir, "cdump")
  write_test_cdump(cdump)
  writeLines("x", file.path(dir, "CONTROL"))

  ncf <- obs_hysplit_cdump2nc(cdump, control = NA, setup = NA)
  nc <- ncdf4::nc_open(ncf)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  ga <- ncdf4::ncatt_get(nc, 0)
  expect_false(any(c("hysplit_control", "hysplit_setup") %in% names(ga)))
})

test_that("obs_hysplit_cdump2nc fails when there is no data", {
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp))
  empty <- list(list(
    start = c(24L, 6L, 15L, 1L, 0L),
    end = c(24L, 6L, 15L, 2L, 0L),
    levels = list(
      list(lev = 100L, x = integer(0), y = integer(0), conc = numeric(0)),
      list(lev = 500L, x = integer(0), y = integer(0), conc = numeric(0))
    )
  ))
  write_test_cdump(tmp, times = empty)
  expect_error(
    suppressWarnings(obs_hysplit_cdump2nc(tmp)),
    "No concentration data"
  )
})
