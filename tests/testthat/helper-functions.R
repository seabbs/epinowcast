on_ci <- function() {
  isTRUE(as.logical(Sys.getenv("CI")))
}

not_on_cran <- function() {
  identical(Sys.getenv("NOT_CRAN"), "true")
}

epinowcast_as_data <- function(...) {
  nowcast <- suppressMessages(epinowcast(
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        return(data.table::data.table(init = list(init), data = list(data)))
      }
    ),
    model = NULL
  ))
  return(nowcast)
}

skip_on_local <- function() {
  if (on_ci()) {
    return(invisible(TRUE))
  }
  testthat::skip("Not on CI")
}

round_numerics <- function(dt) {
  cols <- colnames(dt)[purrr::map_lgl(dt, is.numeric)]
  dt <- dt[, (cols) := lapply(.SD, round, 0), .SDcols = cols]
  return(dt)
}

dt_copies <- function(...) {
  lapply(list(...), data.table::copy)
}

dt_compare_all <- function(ref_copies, ...) {
  all(mapply(function(l, r) all(l == r), ref_copies, list(...)))
}

check_r_version <- function(min_major = 4, min_minor = 0) {

  current_version <- as.numeric(
    paste0(
      R.version[["major"]],
      ".",
      gsub("(\\d+)\\..*", "\\1", R.version[["minor"]])
    )
  )

  target_min_version <- as.numeric(
    paste0(min_major, ".", min_minor)
  )

  if (current_version >= target_min_version) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

# A function to filter data used in test suite
run_window_filter <- function(
  x, filter_report_remove = 10, filter_reference_include = 10
) {
  obs <- enw_filter_report_dates(x, remove_days = filter_report_remove)
  obs <- enw_filter_reference_dates(
    obs, include_days = filter_reference_include
  )
  return(obs)
}

silent_enw_sample <- function(...) {
  utils::capture.output(
    fit <- suppressMessages(enw_sample(...)) # nolint: implicit_assignment_linter
  )
  return(fit)
}

silent_enw_pathfinder <- function(...) {
  utils::capture.output(
    fit <- suppressMessages(enw_pathfinder(...)) # nolint: implicit_assignment_linter
  )
  return(fit)
}
