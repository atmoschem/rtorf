# Build synthetic HYSPLIT binary concentration files (cdump) for testing.
# Format: big-endian Fortran sequential records (4-byte length markers
# around each payload).

.cdumpw_payload <- function(items) {
  rc <- rawConnection(raw(0), "wb")
  on.exit(close(rc))
  for (it in items) {
    tag <- it[[1]]
    val <- it[[2]]
    switch(tag,
      i = writeBin(as.integer(val), rc, size = 4L, endian = "big"),
      i2 = writeBin(as.integer(val), rc, size = 2L, endian = "big"),
      f = writeBin(as.double(val), rc, size = 4L, endian = "big"),
      c = writeBin(charToRaw(substr(sprintf("%-4s", val), 1L, 4L)), rc),
      stop("unknown tag")
    )
  }
  rawConnectionValue(rc)
}

.cdumpw_record <- function(con, items) {
  p <- .cdumpw_payload(items)
  writeBin(length(p), con, size = 4L, endian = "big")
  writeBin(p, con)
  writeBin(length(p), con, size = 4L, endian = "big")
  invisible(NULL)
}

# default content: two 1-hour sampling periods, levels 100 and 500 m,
# species TEST, known sparse values
default_cdump_times <- function() {
  list(
    list(
      start = c(24L, 6L, 15L, 1L, 0L),
      end = c(24L, 6L, 15L, 2L, 0L),
      levels = list(
        list(
          lev = 100L, x = c(1L, 2L, 5L), y = c(1L, 3L, 4L),
          conc = c(1.5, 2.5, 3.5)
        ),
        list(lev = 500L, x = 3L, y = 2L, conc = 4.5)
      )
    ),
    list(
      start = c(24L, 6L, 15L, 2L, 0L),
      end = c(24L, 6L, 15L, 3L, 0L),
      levels = list(
        list(lev = 100L, x = 4L, y = 4L, conc = 5.5),
        list(lev = 500L, x = integer(0), y = integer(0), conc = numeric(0))
      )
    )
  )
}

# writes a one-species ("TEST") cdump and returns path invisibly
write_test_cdump <- function(path,
                             n_sources = 2L,
                             nlat = 4L,
                             nlon = 5L,
                             dlat = 0.5,
                             dlon = 0.5,
                             ll_lat = -16.5,
                             ll_lon = -48.5,
                             levels = c(100L, 500L),
                             times = default_cdump_times()) {
  con <- file(path, "wb")
  on.exit(close(con))

  # record 1: meteorological model, number of release locations
  .cdumpw_record(con, list(
    list("c", "GFS0"),
    list("i", 2024L), list("i", 6L), list("i", 15L), list("i", 0L),
    list("i", 0L), list("i", as.integer(n_sources)), list("i", 0L)
  ))

  # record 2: release locations
  for (s in seq_len(n_sources)) {
    .cdumpw_record(con, list(
      list("i", 24L), list("i", 6L), list("i", 15L), list("i", 0L),
      list("f", -15.79 - s), list("f", -47.88 - s), list("f", 1500),
      list("i", 0L)
    ))
  }

  # record 3: concentration grid
  .cdumpw_record(con, list(
    list("i", as.integer(nlat)), list("i", as.integer(nlon)),
    list("f", dlat), list("f", dlon),
    list("f", ll_lat), list("f", ll_lon)
  ))

  # record 4: vertical levels (top heights, m)
  .cdumpw_record(con, c(
    list(list("i", as.integer(length(levels)))),
    lapply(levels, function(l) list("i", as.integer(l)))
  ))

  # record 5: pollutants
  .cdumpw_record(con, list(list("i", 1L), list("c", "TEST")))

  # data blocks
  for (tb in times) {
    .cdumpw_record(con, c(
      lapply(tb$start, function(v) list("i", as.integer(v))),
      list(list("i", 0L))
    ))
    .cdumpw_record(con, c(
      lapply(tb$end, function(v) list("i", as.integer(v))),
      list(list("i", 0L))
    ))
    for (lb in tb$levels) {
      ne <- length(lb$x)
      rec8 <- list(
        list("c", "TEST"),
        list("i", as.integer(lb$lev)),
        list("i", as.integer(ne))
      )
      for (e in seq_len(ne)) {
        rec8 <- c(rec8, list(
          list("i2", as.integer(lb$x[e])),
          list("i2", as.integer(lb$y[e])),
          list("f", lb$conc[e])
        ))
      }
      .cdumpw_record(con, rec8)
    }
  }
  invisible(path)
}
