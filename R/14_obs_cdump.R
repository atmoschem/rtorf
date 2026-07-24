# ============================================================
#  14_obs_cdump.R
#  Read HYSPLIT binary concentration files (cdump) and write
#  CF-compliant NetCDF with dimensions (time, z, y, x)
#
#  Functions:
#    obs_hysplit_cdump_read — parse the binary cdump file
#    obs_hysplit_cdump_nc   — write a CF-compliant NetCDF
#    obs_hysplit_cdump2nc   — read + write in one call
# ============================================================

# ------------------------------------------------------------
#  internal helpers (not exported)
# ------------------------------------------------------------

# read one Fortran sequential record, return the raw payload
# (NULL when the end of file is reached)
.cdump_record <- function(con, path) {
  len <- readBin(con, "integer", n = 1L, size = 4L, endian = "big")
  if (length(len) == 0L) {
    return(NULL)
  }
  payload <- readBin(con, "raw", n = len)
  tail <- readBin(con, "integer", n = 1L, size = 4L, endian = "big")
  if (length(payload) != len || length(tail) == 0L) {
    stop(paste("Truncated record in", path))
  }
  payload
}

# 4-byte character id without NULs or padding spaces
.cdump_char4 <- function(rr) {
  trimws(rawToChar(rr[rr != as.raw(0L)]))
}

# big-endian 4-byte integers / floats out of a raw vector
.cdump_ints <- function(rr) {
  readBin(rr, "integer", n = length(rr) %/% 4L, size = 4L, endian = "big")
}
.cdump_dbls <- function(rr) {
  readBin(rr, "double", n = length(rr) %/% 4L, size = 4L, endian = "big")
}

# read a text file into a single string (NULL if disabled or missing)
.cdump_embed_file <- function(f) {
  if (is.null(f) || is.na(f) || !file.exists(f)) {
    return(NULL)
  }
  paste(readLines(f, warn = FALSE), collapse = "\n")
}

# ------------------------------------------------------------
#  obs_hysplit_cdump_read
# ------------------------------------------------------------

#' Read a HYSPLIT binary concentration file (cdump)
#'
#' Parses the binary concentration output written by the HYSPLIT
#' dispersion model (usually named \code{cdump}). The file is a
#' sequence of big-endian Fortran records: a header with the
#' meteorological model, the release locations, the concentration
#' grid and the vertical levels, followed by one block per sampling
#' time with the non-zero concentrations stored in sparse form
#' (1-based longitude index, latitude index, concentration).
#'
#' The sparse values are scattered into dense 4-D arrays with
#' dimensions \code{[x, y, z, time]}, where \code{x} and \code{y}
#' are the 1-based HYSPLIT grid indices. Missing cells are zero
#' concentration. Grid points are the centers of the sampling cells.
#'
#' @param cdump Path to the binary cdump file.
#' @param drange Optional vector of length 2 with the start and end
#'   of the period to load (coerced with
#'   \code{\link[base]{as.POSIXct}}, time zone UTC). Sampling periods
#'   fully inside \code{drange} are kept; reading stops after the
#'   first period starting after \code{drange[2]}. Default
#'   \code{NULL} loads everything.
#' @param century Integer century (e.g. \code{2000}) used to expand
#'   the 2-digit years stored in the file. Default \code{NULL}
#'   guesses it from the first release year (\code{< 50} maps to
#'   2000, otherwise 1900).
#' @param massunit Mass unit of the concentrations, used only for
#'   metadata. Default \code{"1"} (unit emission).
#' @param pollutant Species name used to build the CF
#'   \code{standard_name} of the concentration variables. Default
#'   \code{"pollutant"}.
#' @param verbose Logical, to display more information.
#'
#' @return A named list (invisible \code{NULL} with a warning when
#'   the file has no non-zero concentration in the requested period):
#' \describe{
#'   \item{\code{cdump}}{Path of the source file.}
#'   \item{\code{species}}{Character vector with the species found.}
#'   \item{\code{concentrations}}{Named list with one 4-D numeric
#'     array \code{[x, y, z, time]} per species.}
#'   \item{\code{x}, \code{y}}{Integer vectors with the 1-based
#'     HYSPLIT grid indices spanned by the data.}
#'   \item{\code{lon}, \code{lat}}{Numeric vectors with the
#'     cell-center coordinates (degrees) for \code{x} and \code{y}.}
#'   \item{\code{z}}{Numeric vector with the height of the center of
#'     each vertical layer (m).}
#'   \item{\code{z_bounds}}{Matrix \code{[z, 2]} with the bottom and
#'     top of each vertical layer (m).}
#'   \item{\code{level_heights}}{Integer vector with the level top
#'     heights (m) from the file header.}
#'   \item{\code{time}}{\code{POSIXct} vector (UTC) with the middle
#'     of each sampling period.}
#'   \item{\code{time_start}, \code{time_end}}{\code{POSIXct} vectors
#'     with the start and end of each sampling period.}
#'   \item{\code{atts}}{Named list with the global attributes
#'     extracted from the header (meteorological model, sources,
#'     grid definition, levels, species and sampling period).}
#'   \item{\code{massunit}, \code{pollutant}}{The input arguments,
#'     carried over for \code{\link{obs_hysplit_cdump_nc}}.}
#' }
#'
#' @note Longitudes equal or above 180.001 degrees are wrapped to
#'   the -180/180 range. The vertical levels reported in the data
#'   are the tops of the layers declared in the header; the level
#'   bounds are (0, h1), (h1, h2), ... and the reported \code{z} is
#'   the layer midpoint.
#'
#' @seealso \code{\link{obs_hysplit_cdump_nc}} to write the result
#'   as CF-compliant NetCDF, \code{\link{obs_hysplit_cdump2nc}} for
#'   a one-call conversion, \code{\link{obs_hysplit_control_read}}
#'   for the HYSPLIT CONTROL file.
#'
#' @export
#' @examples \dontrun{
#' cd <- obs_hysplit_cdump_read("cdump")
#' str(cd$concentrations[[cd$species[1]]])
#' }
obs_hysplit_cdump_read <- function(
  cdump,
  drange = NULL,
  century = NULL,
  massunit = "1",
  pollutant = "pollutant",
  verbose = FALSE
) {
  if (missing(cdump) || !is.character(cdump) || length(cdump) != 1L) {
    stop("cdump must be a single string with the path of the file")
  }
  if (!file.exists(cdump)) {
    stop(paste("File not found:", cdump))
  }
  if (!is.null(drange)) {
    drange <- as.POSIXct(drange, tz = "UTC")
    if (length(drange) != 2L || any(is.na(drange))) {
      stop("drange must have length 2 (start, end)")
    }
  }

  con <- file(cdump, "rb")
  on.exit(close(con))

  # record 1: meteorological model and number of release locations
  p <- .cdump_record(con, cdump)
  if (is.null(p) || length(p) != 32L) {
    stop(paste("Invalid cdump header (record 1) in", cdump))
  }
  r1 <- .cdump_ints(p[5:32])
  nstart <- r1[6]
  atts <- list(
    meteorological_model = .cdump_char4(p[1:4]),
    source_count = nstart
  )
  if (verbose) {
    cat("Meteorological model:", atts$meteorological_model, "\n")
    cat("Number of release locations:", nstart, "\n")
  }

  # record 2: one per release location
  s_lat <- s_lon <- s_ht <- numeric(nstart)
  r_time <- matrix(NA_integer_, nrow = nstart, ncol = 5L)
  for (i in seq_len(nstart)) {
    p <- .cdump_record(con, cdump)
    if (is.null(p) || length(p) != 32L) {
      stop(paste("Invalid cdump header (record 2) in", cdump))
    }
    r2 <- .cdump_ints(c(p[1:16], p[29:32]))
    r2f <- .cdump_dbls(p[17:28])
    r_time[i, ] <- r2
    s_lat[i] <- r2f[1]
    s_lon[i] <- r2f[2]
    s_ht[i] <- r2f[3]
  }
  if (is.null(century)) {
    century <- if (r_time[1, 1] < 50) 2000 else 1900
    if (verbose) {
      cat("Guessing century for HYSPLIT concentration file:", century, "\n")
    }
  }
  atts$source_dates <- sprintf(
    "%04d%02d%02d.%02d%02d00",
    century + r_time[, 1], r_time[, 2], r_time[, 3], r_time[, 4], r_time[, 5]
  )
  atts$source_latitudes <- s_lat
  atts$source_longitudes <- s_lon
  atts$source_heights <- s_ht

  # record 3: concentration grid
  p <- .cdump_record(con, cdump)
  if (is.null(p) || length(p) != 24L) {
    stop(paste("Invalid cdump header (record 3) in", cdump))
  }
  r3 <- .cdump_ints(p[1:8])
  r3f <- .cdump_dbls(p[9:24])
  nlat <- r3[1]
  nlon <- r3[2]
  dlat <- r3f[1]
  dlon <- r3f[2]
  llcrnr_lat <- r3f[3]
  llcrnr_lon <- r3f[4]
  atts$latitude_point_count <- nlat
  atts$longitude_point_count <- nlon
  atts$latitude_spacing <- dlat
  atts$longitude_spacing <- dlon
  atts$latitude_min <- llcrnr_lat
  atts$longitude_min <- llcrnr_lon
  if (verbose) {
    cat("Grid:", nlon, "x", nlat, "from", llcrnr_lon, ",", llcrnr_lat, "\n")
  }

  # record 4: vertical levels (level top heights, m)
  p <- .cdump_record(con, cdump)
  if (is.null(p) || length(p) < 8L) {
    stop(paste("Invalid cdump header (record 4) in", cdump))
  }
  r4 <- .cdump_ints(p)
  nlev <- r4[1]
  levht <- r4[2:(nlev + 1L)]
  atts$level_count <- nlev
  atts$level_heights <- levht

  # record 5: pollutants (names here are ignored; the species stored
  # in each data record below are the ones used)
  p <- .cdump_record(con, cdump)
  if (is.null(p) || length(p) < 4L) {
    stop(paste("Invalid cdump header (record 5) in", cdump))
  }
  npoll <- .cdump_ints(p[1:4])[1]
  atts$number_of_species <- npoll

  # data blocks: one per sampling time, npoll x nlev sparse matrices
  sp_blocks <- list() # species -> list of list(x, y, lev, conc, t)
  time_start <- .POSIXct(double(0), tz = "UTC")
  time_end <- .POSIXct(double(0), tz = "UTC")
  sampling_period_hours <- numeric(0)
  repeat {
    p <- .cdump_record(con, cdump)
    if (is.null(p)) {
      break
    }
    if (length(p) != 24L) {
      stop(paste("Invalid sampling start record in", cdump))
    }
    r6 <- .cdump_ints(p)
    p <- .cdump_record(con, cdump)
    if (is.null(p) || length(p) != 24L) {
      stop(paste("Invalid sampling stop record in", cdump))
    }
    r7 <- .cdump_ints(p)
    pdate1 <- ISOdatetime(
      century + r6[1], r6[2], r6[3], r6[4], r6[5], 0,
      tz = "UTC"
    )
    pdate2 <- ISOdatetime(
      century + r7[1], r7[2], r7[3], r7[4], r7[5], 0,
      tz = "UTC"
    )
    sampling_period_hours <- as.numeric(difftime(pdate2, pdate1, units = "hours"))
    if (verbose) {
      cat("Sample time", format(pdate1, usetz = TRUE), "to",
        format(pdate2, usetz = TRUE), "\n"
      )
    }
    savedata <- TRUE
    if (!is.null(drange)) {
      if (pdate1 >= drange[1] && pdate1 <= drange[2] && pdate2 <= drange[2]) {
        savedata <- TRUE
      } else if (pdate1 > drange[2] || pdate2 > drange[2]) {
        break
      } else {
        savedata <- FALSE
      }
    }
    saved_time <- FALSE
    for (ipoll in seq_len(npoll)) {
      for (ilev in seq_len(nlev)) {
        p <- .cdump_record(con, cdump)
        if (is.null(p) || length(p) < 12L) {
          stop(paste("Invalid concentration record in", cdump))
        }
        sp <- .cdump_char4(p[1:4])
        lev <- .cdump_ints(p[5:8])[1]
        ne <- .cdump_ints(p[9:12])[1]
        if (length(p) != 12L + 8L * ne) {
          stop(paste("Invalid concentration record length in", cdump))
        }
        if (ne >= 1L && savedata) {
          if (!saved_time) {
            time_start <- c(time_start, pdate1)
            time_end <- c(time_end, pdate2)
            saved_time <- TRUE
          }
          m <- matrix(p[13:(12L + 8L * ne)], nrow = 8L)
          block <- list(
            x = readBin(as.vector(m[1:2, ]), "integer",
              n = ne, size = 2L, endian = "big"
            ),
            y = readBin(as.vector(m[3:4, ]), "integer",
              n = ne, size = 2L, endian = "big"
            ),
            lev = rep(lev, ne),
            conc = readBin(as.vector(m[5:8, ]), "double",
              n = ne, size = 4L, endian = "big"
            ),
            t = rep(length(time_start), ne)
          )
          sp_blocks[[sp]] <- c(sp_blocks[[sp]], list(block))
        }
      }
    }
  }

  species <- names(sp_blocks)
  atts$Species_ID <- paste(species, collapse = ", ")
  atts$sampling_period_hours <- sampling_period_hours
  atts[["Coordinate time description"]] <- "Middle of sampling time"

  if (length(species) == 0L) {
    warning(paste("No concentration data found in", cdump))
    return(invisible(NULL))
  }

  # dense grid: continuous 1-based index ranges, missing cells are zero
  all_x <- unlist(lapply(sp_blocks, function(sp) {
    unlist(lapply(sp, `[[`, "x"), use.names = FALSE)
  }), use.names = FALSE)
  all_y <- unlist(lapply(sp_blocks, function(sp) {
    unlist(lapply(sp, `[[`, "y"), use.names = FALSE)
  }), use.names = FALSE)
  x_idx <- seq.int(min(all_x), max(all_x))
  y_idx <- seq.int(min(all_y), max(all_y))

  # cell-center coordinates (full grid, then subset)
  lat_full <- llcrnr_lat + (seq_len(nlat) - 1) * dlat
  lon_full <- llcrnr_lon + (seq_len(nlon) - 1) * dlon
  lon_full[lon_full >= 180.001] <- lon_full[lon_full >= 180.001] - 360
  lat <- lat_full[y_idx]
  lon <- lon_full[x_idx]

  # vertical layers from the levels present in the data
  all_lev <- unique(unlist(lapply(sp_blocks, function(sp) {
    unlist(lapply(sp, `[[`, "lev"), use.names = FALSE)
  }), use.names = FALSE))
  missing_lev <- setdiff(all_lev, levht)
  if (length(missing_lev) > 0L) {
    stop(paste(
      "Level", missing_lev[1],
      "not found in the level heights of the header"
    ))
  }
  z_vals <- sort(all_lev)
  k <- match(z_vals, levht)
  z_bottom <- ifelse(k == 1L, 0, levht[k - 1L])
  z_bounds <- cbind(z_bottom, z_vals)
  colnames(z_bounds) <- c("bottom", "top")
  z <- (z_bottom + z_vals) / 2

  time_start <- .POSIXct(as.numeric(time_start), tz = "UTC")
  time_end <- .POSIXct(as.numeric(time_end), tz = "UTC")
  time_mid <- time_start + (time_end - time_start) / 2

  # scatter the sparse data into dense [x, y, z, time] arrays
  nt <- length(time_start)
  nx <- length(x_idx)
  ny <- length(y_idx)
  nz <- length(z_vals)
  dnames <- list(
    x = as.character(x_idx),
    y = as.character(y_idx),
    z = as.character(z),
    time = format(time_mid, "%Y-%m-%d %H:%M:%S", tz = "UTC")
  )
  concentrations <- lapply(sp_blocks, function(blocks) {
    arr <- array(0, dim = c(nx, ny, nz, nt), dimnames = dnames)
    xs <- unlist(lapply(blocks, `[[`, "x"), use.names = FALSE)
    ys <- unlist(lapply(blocks, `[[`, "y"), use.names = FALSE)
    ls <- unlist(lapply(blocks, `[[`, "lev"), use.names = FALSE)
    cs <- unlist(lapply(blocks, `[[`, "conc"), use.names = FALSE)
    ts <- unlist(lapply(blocks, `[[`, "t"), use.names = FALSE)
    idx <- cbind(
      xs - x_idx[1] + 1L,
      ys - y_idx[1] + 1L,
      match(ls, z_vals),
      ts
    )
    arr[idx] <- cs
    arr
  })

  list(
    cdump = cdump,
    species = species,
    concentrations = concentrations,
    x = x_idx,
    y = y_idx,
    lon = lon,
    lat = lat,
    z = z,
    z_bounds = z_bounds,
    level_heights = levht,
    time = time_mid,
    time_start = time_start,
    time_end = time_end,
    atts = atts,
    massunit = massunit,
    pollutant = pollutant
  )
}

# ------------------------------------------------------------
#  obs_hysplit_cdump_nc
# ------------------------------------------------------------

#' Write HYSPLIT concentrations as a CF-compliant NetCDF
#'
#' Writes the output of \code{\link{obs_hysplit_cdump_read}} as a
#' NetCDF-4 file following the CF conventions (version 1.9), with
#' dimensions \code{time}, \code{z}, \code{y}, \code{x} and
#' \code{bnds}. Each species is stored as a float variable
#' \code{(time, z, y, x)} with deflate compression. Cell bounds are
#' provided by the variables \code{time_bounds}, \code{z_bounds},
#' \code{latitude_bounds} and \code{longitude_bounds}, and the
#' spherical-earth grid mapping by the scalar variable \code{crs}.
#'
#' @param x A list produced by \code{\link{obs_hysplit_cdump_read}}.
#' @param nc_out Path of the NetCDF file to create.
#' @param height_reference Reference of the level heights:
#'   \code{"sea_level"} (default, z standard name
#'   \code{height_above_mean_sea_level}) or \code{"ground_level"}
#'   (\code{height_above_ground}, matching \code{KMSL = 0} in
#'   HYSPLIT).
#' @param control Path of the HYSPLIT CONTROL file to embed in the
#'   global attribute \code{hysplit_control}. Default \code{NULL}
#'   looks for \code{CONTROL} in the directory of the source cdump
#'   file; \code{NA} disables the embedding.
#' @param setup Path of the HYSPLIT SETUP.CFG file to embed in the
#'   global attribute \code{hysplit_setup}. Default \code{NULL}
#'   looks for \code{SETUP.CFG} in the directory of the source cdump
#'   file; \code{NA} disables the embedding.
#' @param verbose Logical, to display more information.
#'
#' @return The path of the created NetCDF file, invisibly.
#'
#' @note The \code{time} coordinate is hours since the start of the
#'   first sampling period, at the middle of each period, with
#'   calendar \code{standard}. The concentration units are
#'   \code{"<massunit> m-3"} and the standard name
#'   \code{mass_concentration_of_<pollutant>_in_air}, both carried
#'   from \code{\link{obs_hysplit_cdump_read}}.
#'
#' @seealso \code{\link{obs_hysplit_cdump_read}},
#'   \code{\link{obs_hysplit_cdump2nc}}, \code{\link{obs_nc_get}}
#'
#' @export
#' @examples \dontrun{
#' cd <- obs_hysplit_cdump_read("cdump")
#' obs_hysplit_cdump_nc(cd, "cdump.nc")
#' }
obs_hysplit_cdump_nc <- function(
  x,
  nc_out,
  height_reference = c("sea_level", "ground_level"),
  control = NULL,
  setup = NULL,
  verbose = FALSE
) {
  if (!is.list(x) || is.null(x$concentrations) || is.null(x$atts)) {
    stop("x must be the output of obs_hysplit_cdump_read")
  }
  if (missing(nc_out) || !is.character(nc_out) || length(nc_out) != 1L) {
    stop("nc_out must be a single string with the path of the file")
  }
  height_reference <- match.arg(height_reference)
  z_standard_name <- if (height_reference == "sea_level") {
    "height_above_mean_sea_level"
  } else {
    "height_above_ground"
  }
  z_long_name <- if (height_reference == "sea_level") {
    "height above mean sea level"
  } else {
    "height above ground level"
  }

  # time coordinate: hours since the start of the first sampling period
  ref <- x$time_start[1]
  time_units <- paste0(
    "hours since ",
    strftime(ref, "%Y-%m-%d %H:%M:%S", tz = "UTC"), "Z"
  )
  time_hours <- as.numeric(difftime(x$time, ref, units = "hours"))
  time_bounds <- rbind(
    as.numeric(difftime(x$time_start, ref, units = "hours")),
    as.numeric(difftime(x$time_end, ref, units = "hours"))
  )

  # dimensions
  xdim <- ncdf4::ncdim_def("x", "1", as.integer(x$x),
    longname = "x coordinate of projection"
  )
  ydim <- ncdf4::ncdim_def("y", "1", as.integer(x$y),
    longname = "y coordinate of projection"
  )
  zdim <- ncdf4::ncdim_def("z", "m", as.double(x$z), longname = z_long_name)
  tdim <- ncdf4::ncdim_def("time", time_units, time_hours,
    longname = "time at middle of sampling period"
  )
  bdim <- ncdf4::ncdim_def("bnds", "1", c(0L, 1L),
    longname = "index of bounds dimension"
  )

  # variables
  conc_vars <- lapply(x$species, function(sp) {
    ncdf4::ncvar_def(sp, paste(x$massunit, "m-3"),
      list(xdim, ydim, zdim, tdim),
      prec = "float", compression = 9
    )
  })
  names(conc_vars) <- x$species
  lat_var <- ncdf4::ncvar_def("latitude", "degrees_north", ydim,
    prec = "double", longname = "latitude"
  )
  lon_var <- ncdf4::ncvar_def("longitude", "degrees_east", xdim,
    prec = "double", longname = "longitude"
  )
  zb_var <- ncdf4::ncvar_def("z_bounds", "", list(bdim, zdim), prec = "double")
  lb_var <- ncdf4::ncvar_def("latitude_bounds", "", list(bdim, ydim),
    prec = "double"
  )
  nb_var <- ncdf4::ncvar_def("longitude_bounds", "", list(bdim, xdim),
    prec = "double"
  )
  tb_var <- ncdf4::ncvar_def("time_bounds", "", list(bdim, tdim),
    prec = "double",
    longname = "start and end times of sampling period"
  )
  crs_var <- ncdf4::ncvar_def("crs", "", list(),
    prec = "integer",
    longname = "Spherical earth with radius 6371.2 km"
  )

  if (verbose) {
    cat("Writing:", nc_out, "\n")
  }
  nc <- ncdf4::nc_create(
    nc_out,
    vars = c(conc_vars, list(
      latitude = lat_var, longitude = lon_var,
      z_bounds = zb_var, latitude_bounds = lb_var,
      longitude_bounds = nb_var, time_bounds = tb_var, crs = crs_var
    )),
    force_v4 = TRUE, verbose = FALSE
  )
  on.exit(if (!is.null(nc)) ncdf4::nc_close(nc), add = TRUE)

  for (sp in x$species) {
    ncdf4::ncvar_put(nc, sp, x$concentrations[[sp]])
    ncdf4::ncatt_put(nc, sp, "standard_name",
      paste0("mass_concentration_of_", x$pollutant, "_in_air"),
      prec = "text"
    )
  }
  ncdf4::ncvar_put(nc, "latitude", x$lat)
  ncdf4::ncvar_put(nc, "longitude", x$lon)
  ncdf4::ncvar_put(nc, "z_bounds", t(x$z_bounds))
  ncdf4::ncvar_put(
    nc, "latitude_bounds",
    rbind(x$lat - x$atts$latitude_spacing / 2, x$lat + x$atts$latitude_spacing / 2)
  )
  ncdf4::ncvar_put(
    nc, "longitude_bounds",
    rbind(x$lon - x$atts$longitude_spacing / 2, x$lon + x$atts$longitude_spacing / 2)
  )
  ncdf4::ncvar_put(nc, "time_bounds", time_bounds)
  ncdf4::ncvar_put(nc, "crs", 0L)

  # coordinate variable attributes
  ncdf4::ncatt_put(nc, "latitude", "standard_name", "latitude", prec = "text")
  ncdf4::ncatt_put(nc, "latitude", "axis", "Y", prec = "text")
  ncdf4::ncatt_put(nc, "latitude", "bounds", "latitude_bounds", prec = "text")
  ncdf4::ncatt_put(nc, "longitude", "standard_name", "longitude", prec = "text")
  ncdf4::ncatt_put(nc, "longitude", "axis", "X", prec = "text")
  ncdf4::ncatt_put(nc, "longitude", "bounds", "longitude_bounds", prec = "text")
  ncdf4::ncatt_put(nc, "z", "standard_name", z_standard_name, prec = "text")
  ncdf4::ncatt_put(nc, "z", "positive", "up", prec = "text")
  ncdf4::ncatt_put(nc, "z", "axis", "Z", prec = "text")
  ncdf4::ncatt_put(nc, "z", "bounds", "z_bounds", prec = "text")
  ncdf4::ncatt_put(nc, "time", "standard_name", "time", prec = "text")
  ncdf4::ncatt_put(nc, "time", "calendar", "standard", prec = "text")
  ncdf4::ncatt_put(nc, "time", "axis", "T", prec = "text")
  ncdf4::ncatt_put(nc, "time", "bounds", "time_bounds", prec = "text")
  ncdf4::ncatt_put(nc, "z_bounds", "comment", "Bounds", prec = "text")
  ncdf4::ncatt_put(nc, "latitude_bounds", "comment", "Bounds", prec = "text")
  ncdf4::ncatt_put(nc, "longitude_bounds", "comment", "Bounds", prec = "text")
  ncdf4::ncatt_put(nc, "crs", "grid_mapping_name", "latitude_longitude",
    prec = "text"
  )
  ncdf4::ncatt_put(nc, "crs", "earth_radius", 6371200.0, prec = "double")
  ncdf4::ncatt_put(
    nc, "crs", "comment",
    "This grid uses spherical Earth approximation. No EPSG code applies",
    prec = "text"
  )

  # global attributes (CONTROL and SETUP.CFG go last)
  now <- strftime(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  g_atts <- c(
    list(
      Conventions = "CF-1.9",
      history = paste0(
        "Created on ", now,
        " UTC by rtorf::obs_hysplit_cdump_nc"
      ),
      title = "HYSPLIT simulation air concentration data"
    ),
    x$atts,
    list(
      generation_datetime = now,
      created_by_script = paste0(
        "rtorf v", utils::packageVersion("rtorf"),
        "::obs_hysplit_cdump_nc"
      ),
      execution_command = paste(commandArgs(trailingOnly = FALSE),
        collapse = " "
      )
    )
  )
  if (is.null(control)) {
    control <- file.path(dirname(x$cdump), "CONTROL")
  }
  if (is.null(setup)) {
    setup <- file.path(dirname(x$cdump), "SETUP.CFG")
  }
  control_text <- .cdump_embed_file(control)
  setup_text <- .cdump_embed_file(setup)
  if (!is.null(control_text)) {
    g_atts$hysplit_control <- control_text
  }
  if (!is.null(setup_text)) {
    g_atts$hysplit_setup <- setup_text
  }
  for (nm in names(g_atts)) {
    val <- g_atts[[nm]]
    if (is.numeric(val)) {
      if (all(val %% 1 == 0)) {
        ncdf4::ncatt_put(nc, 0, nm, as.integer(val), prec = "integer")
      } else {
        ncdf4::ncatt_put(nc, 0, nm, as.double(val), prec = "double")
      }
    } else {
      ncdf4::ncatt_put(nc, 0, nm, paste(val, collapse = ", "), prec = "text")
    }
  }
  ncdf4::nc_close(nc)
  nc <- NULL
  if (verbose) {
    cat("Created:", nc_out, "\n")
  }
  invisible(nc_out)
}

# ------------------------------------------------------------
#  obs_hysplit_cdump2nc
# ------------------------------------------------------------

#' Convert a HYSPLIT cdump file to CF-compliant NetCDF
#'
#' One-call wrapper around \code{\link{obs_hysplit_cdump_read}} and
#' \code{\link{obs_hysplit_cdump_nc}}: reads the binary HYSPLIT
#' concentration file and writes the equivalent CF-compliant
#' NetCDF with dimensions \code{time}, \code{z}, \code{y}, \code{x}.
#'
#' @param cdump Path to the binary cdump file.
#' @param nc_out Path of the NetCDF file to create. Default
#'   \code{NULL} writes \code{<cdump>.nc} next to the source file.
#' @param drange Optional period to load, see
#'   \code{\link{obs_hysplit_cdump_read}}.
#' @param century Integer century for the 2-digit years, see
#'   \code{\link{obs_hysplit_cdump_read}}.
#' @param massunit Mass unit of the concentrations. Default
#'   \code{"1"}.
#' @param pollutant Species name used to build the CF
#'   \code{standard_name}. Default \code{"pollutant"}.
#' @param height_reference Reference of the level heights, see
#'   \code{\link{obs_hysplit_cdump_nc}}.
#' @param control Path of the CONTROL file to embed, see
#'   \code{\link{obs_hysplit_cdump_nc}}.
#' @param setup Path of the SETUP.CFG file to embed, see
#'   \code{\link{obs_hysplit_cdump_nc}}.
#' @param verbose Logical, to display more information.
#'
#' @return The path of the created NetCDF file, invisibly.
#'
#' @seealso \code{\link{obs_hysplit_cdump_read}},
#'   \code{\link{obs_hysplit_cdump_nc}}
#'
#' @export
#' @examples \dontrun{
#' obs_hysplit_cdump2nc("cdump")
#' }
obs_hysplit_cdump2nc <- function(
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
) {
  if (is.null(nc_out)) {
    nc_out <- paste0(cdump, ".nc")
  }
  x <- obs_hysplit_cdump_read(
    cdump,
    drange = drange,
    century = century,
    massunit = massunit,
    pollutant = pollutant,
    verbose = verbose
  )
  if (is.null(x)) {
    stop(paste("No concentration data to write from", cdump))
  }
  obs_hysplit_cdump_nc(
    x,
    nc_out,
    height_reference = height_reference,
    control = control,
    setup = setup,
    verbose = verbose
  )
}
