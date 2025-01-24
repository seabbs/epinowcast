#' @rawNamespace import(data.table, except = transpose)
#' @import cmdstanr
#' @import ggplot2
#' @importFrom stats median rnorm
NULL

#' @title Check an object is a Date
#' @description Checks that an object is a date
#' @param x An object
#' @return A logical
#' @family utils
is.Date <- function(x) {
  # nolint
  inherits(x, "Date")
}

#' Read in a stan function file as a character string
#'
#' @inheritParams enw_stan_to_r
#' @return A character string in the of stan functions.
#' @family utils
#' @importFrom purrr map_chr
stan_fns_as_string <- function(files, include) {
  functions <- paste0(
    "\n functions{ \n",
    paste(
      purrr::map_chr(
        files,
        ~ paste(readLines(file.path(include, .)), collapse = "\n")
      ),
      collapse = "\n"
    ),
    "\n }"
  )
  return(functions)
}

#' Load a package example
#'
#' Loads examples of nowcasts produced using example scripts. Used to streamline
#' examples, in package tests and to enable users to explore package
#' functionality without needing to install `cmdstanr`.
#'
#' @param type A character string indicating the example to load.
#' Supported options are
#'  * "nowcast", for [epinowcast()] applied to [germany_covid19_hosp]
#'  * "preprocessed_observations", for [enw_preprocess_data()] applied to
#'  [germany_covid19_hosp]
#'  * "observations", for [enw_latest_data()] applied to [germany_covid19_hosp]
#'  * "script", the code used to generate these examples.
#'
#' @return Depending on `type`, a `data.table` of the requested output OR
#' the file name(s) to generate these outputs (`type` = "script")
#'
#' @family data
#' @export
#' @examples
#' # Load the nowcast
#' enw_example(type = "nowcast")
#'
#' # Load the preprocessed observations
#' enw_example(type = "preprocessed_observations")
#'
#' # Load the latest observations
#' enw_example(type = "observations")
#'
#' # Load the script used to generate these examples
#' # Optionally source this script to regenerate the example
#' readLines(enw_example(type = "script"))
enw_example <- function(type = c(
                          "nowcast", "preprocessed_observations",
                          "observations", "script"
                        )) {
  type <- match.arg(type)

  if (type %in% c("nowcast", "preprocessed_observations", "observations")) {
    return(readRDS(
      system.file("extdata", sprintf("%s.rds", type), package = "epinowcast")
    ))
  } else if (type == "script") {
    return(
      system.file("examples", "germany_dow.R", package = "epinowcast")
    )
  }
}

#' @title Coerce Dates
#'
#' @description Provides consistent coercion of inputs to [IDate]
#' with error handling
#'
#' @param dates A vector-like input, which the function attempts
#' to coerce via [data.table::as.IDate()]. Defaults to NULL.
#'
#' @return An [IDate] vector.
#'
#' @details If any of the elements of `dates` cannot be coerced,
#' this function will result in an error, indicating all indices
#' which cannot be coerced to [IDate].
#'
#' Internal methods of [epinowcast] assume dates are represented
#' as [IDate].
#'
#' @export
#' @importFrom data.table as.IDate
#' @importFrom cli cli_abort cli_warn
#' @family utils
#' @examples
#' # works
#' coerce_date(c("2020-05-28", "2020-05-29"))
#' # does not, indicates index 2 is problem
#' tryCatch(
#'   coerce_date(c("2020-05-28", "2020-o5-29")),
#'   error = function(e) {
#'     print(e)
#'   }
#' )
coerce_date <- function(dates = NULL) {
  if (is.null(dates)) {
    return(data.table::as.IDate(numeric()))
  }
  if (length(dates) == 0) {
    return(data.table::as.IDate(dates))
  }

  res <- data.table::as.IDate(vapply(dates, function(d) {
    tryCatch(
      data.table::as.IDate(d, optional = TRUE),
      error = function(e) {
        return(data.table::as.IDate(NA))
      }
    )
  }, FUN.VALUE = data.table::as.IDate(0)))

  if (anyNA(res)) {
    cli::cli_abort(paste0(
      "Failed to parse with `as.IDate`: {toString(dates[is.na(res)])} ",
      "(indices {toString(which(is.na(res)))})."
    ))
  } else {
    return(res)
  }
}

#' Get internal timestep
#'
#' This function converts the string representation of the timestep to its
#' corresponding numeric value or returns the numeric input (if it is a whole
#' number). For "day", "week", it returns 1 and 7 respectively.
#' For "month", it returns "month" as months are not a fixed number of days.
#' If the input is a numeric whole number, it is returned as is.
#'
#' @param timestep The timestep to used. This can be a string ("day",
#' "week", "month") or a numeric whole number representing the number of days.
#'
#' @return A numeric value representing the number of days for "day" and
#' "week", "month" for "month",  or the input value if it is a numeric whole
#' number.
#' @importFrom cli cli_abort
#' @family utils
get_internal_timestep <- function(timestep) {
  # check if the input is a character
  if (is.character(timestep)) {
    switch(
      timestep,
      day = 1,
      week = 7,
      month = "month",  # months are not a fixed number of days
      cli::cli_abort(
        "Invalid timestep. Acceptable string inputs are 'day', 'week', 'month'."
      )
    )
  } else if (is.numeric(timestep) && timestep == round(timestep)) {
    # check if the input is a whole number
    return(timestep)
  } else {
    cli::cli_abort(
      paste0(
        "Invalid timestep. If timestep is a numeric, it should be a whole ",
        "number representing the number of days."
      )
    )
  }
}

#' Internal function to perform rolling sum aggregation
#'
#' This function takes a data.table and applies a rolling sum over a given
#' timestep, aggregating by specified columns. It's particularly useful for
#' aggregating observations over certain periods.
#'
#' @param dt A `data.table` to be aggregated.
#' @param internal_timestep An integer indicating the period over which to
#' aggregate.
#' @param by A character vector specifying the columns to aggregate by.
#' @param value_col A character string specifying the column to aggregate.
#' Defaults to "confirm".
#'
#' @return A modified data.table with aggregated observations.
#'
#' @importFrom data.table frollsum
#' @family utils
aggregate_rolling_sum <- function(dt, internal_timestep, by = NULL,
  value_col = "confirm") {
  dt[, value_col := {
    n_vals <- if (.N <= internal_timestep) {
      seq_len(.N)
    } else {
      c(
        1:(internal_timestep - 1),
        rep(internal_timestep, .N - (internal_timestep - 1))
      )
    }
    frollsum(value_col, n_vals, adaptive = TRUE)
  },
  by = by,
  env = list(internal_timestep = internal_timestep, value_col = value_col)
  ]

  return(dt[])
}

#' Convert date column to numeric and calculate its modulus with given timestep.
#'
#' This function processes a date column in a `data.table`, converting it to a
#' numeric representation and then computing the modulus with the provided
#' timestep.
#'
#' @param dt A data.table.
#'
#' @param date_column A character string representing the name of the date
#' column in dt.
#'
#' @param timestep An integer representing the internal timestep.
#'
#' @return A modified data.table with two new columns: one for the numeric
#' representation of the date minus the minimum date and another for its
#' modulus with the timestep.
#'
#' @family utils
date_to_numeric_modulus <- function(dt, date_column, timestep) {
  mod_col_name <- paste0(date_column, "_mod")

  dt[, c(mod_col_name) := as.numeric(
        get(date_column) - min(get(date_column), na.rm = TRUE)
      ) %% timestep
  ]
  return(dt[])
}

#' Cache location message for epinowcast package
#'
#' This function generates a message in the [epinowcast()] package
#' regarding the cache location. It checks the environment setting for the
#' cache location and provides guidance to the user on managing this setting.
#'
#' @details [cache_location_message()] examines the `enw_cache_location`
#' environment variable. If this variable is not set, it advises the user to
#' set the cache location using [enw_set_cache()] to optimize stan compilation
#' times. If `enw_cache_location` is set, it confirms the current cache
#' location to the user. Management and setting of the cache location can be
#' done using [enw_set_cache()].
#'
#' @return A character vector containing messages. If `enw_cache_location` is
#' not set, it returns instructions for setting the cache location and where to
#' find more details. If it is set, the function returns a confirmation message
#' of the current cache location.
#'
#' @keywords internal
cache_location_message <- function() {
    cache_location <- Sys.getenv("enw_cache_location")
    if (check_environment_unset(cache_location)) {
    # nolint start
        msg <- c(
            "!" = "`enw_cache_location` is not set.",
            i = "Using `tempdir()` at {tempdir()} for the epinowcast model cache location.",
            i = "Set a specific cache location using `enw_set_cache` to control Stan recompilation in this R session or across R sessions.",
            i = "For example: `enw_set_cache(tools::R_user_dir(package =
            \"epinowcast\", \"cache\"), type = c('session', 'persistent'))`.",
            i = "See `?enw_set_cache` for details."
        )
    # nolint end 
    } else {
        msg <- c(
            i = sprintf(
                "Using `%s` for the epinowcast model cache location.", # nolint line_length
                cache_location
            )
        )
    }

    return(msg)
}

#' Check environment setting
#'
#' This internal function checks whether a given environment variable is set or
#' not. It returns `TRUE` if the variable is either null or an empty string,
#' indicating that the environment variable is not set. Otherwise, it returns
#' `FALSE`.
#'
#' @param x The environment variable to be checked.
#'
#' @return Logical value indicating whether the environment variable is not set
#' (either null or an empty string).
#' @keywords internal
check_environment_unset <- function(x) {
  return(is.null(x) || x == "")
}

#' Identify cache location in .Renviron
#'
#' This function retrieves environment variable settings and manages the
#' `.Renviron` file in the user's project or home directory.
#' The project directory will be examined first, if it exists.
#'
#' @return A list containing the contents of the `.Renviron` file and its path.
#' @keywords internal
get_renviron_contents <- function() {

  env_location <- getwd()

  if (file.exists(file.path(env_location, ".Renviron"))) {
    env_path <- file.path(env_location, ".Renviron")
  } else {
    env_location <- Sys.getenv("HOME")
    env_path <- file.path(env_location, ".Renviron")
  }

  if (!file.exists(env_path)) {
    file.create(env_path)
  }

  env_contents <- readLines(env_path)

  output <- list(
    env_contents = env_contents,
    env_path = env_path
  )

  return(output)
}

#' Remove Cache Location Setting from `.Renviron`
#'
#' This function searches for and removes the `enw_cache_location` setting from
#' the `.Renviron` file located in the user's project or home directory.
#' It utilizes the [get_renviron_contents]() function to access and
#' modify the contents of the `.Renviron` file. If the `enw_cache_location`
#' setting is found and successfully removed, a success message is displayed.
#' If the setting is not found, a warning message is displayed.
#'
#' @param alter_on_not_set A logical value indicating whether to display a
#' warning message if the `enw_cache_location` setting is not found in the
#' `.Renviron` file. Defaults to `TRUE`.
#'
#' @return Invisible NULL. The function is used for its side effect of modifying
#' the `.Renviron` file.
#' @seealso [get_renviron_contents()]
#' @keywords internal
unset_cache_from_environ <- function(alert_on_not_set = TRUE) {
    environ <- get_renviron_contents()
    cache_loc_environ <- check_renviron_for_cache(environ)
    if (any(cache_loc_environ)) {
      new_environ <- environ
      new_environ[["env_contents"]] <-
       environ[["env_contents"]][!cache_loc_environ]
      writeLines(new_environ$env_contents, new_environ$env_path)
      cli::cli_alert_success(
        "Removed `enw_cache_location` setting from `.Renviron`."
      )
    } else {
      if (isTRUE(alert_on_not_set)) {
        cli::cli_alert_danger(
          "`enw_cache_location` not set in `.Renviron`. Nothing to remove."
        )
      }
    }
    return(invisible(NULL))
}

#' Check `.Renviron` for cache location setting
#' @param environ A list containing the contents of the `.Renviron` file and
#' its path. This is the output of the [get_renviron_contents()] function.
#' @keywords internal
check_renviron_for_cache <- function(environ) {
  cache_loc_environ <- grepl(
    "enw_cache_location", environ[["env_contents"]], fixed = TRUE
  )
  return(cache_loc_environ)
}

#' Create Stan cache directory
#'
#' This function creates a cache directory for Stan models if it does not
#' already exist. This is useful for users who want to set a persistent
#' cache location but do not want to create the directory manually.
#'
#' @inheritParams enw_set_cache
#'
#' @return `NULL`
#' @keywords internal
#' @importFrom cli cli_alert_info cli_alert_success cli_abort
create_cache_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    if (dir.exists(path)) {
      cli::cli_alert_success(
        "Created cache directory at {path}"
      )
      return(invisible(NULL))
    } else {
      cli::cli_abort(
        "Failed to create cache directory at {path}"
      )
    }
  }
  return(invisible(NULL))
}

# This is an alternative to dir.create(recursive = TRUE) that doesn't throw
# warnings when some elements on the path already exist
dir_create_with_parents <- function(path) {
  dirs <- strsplit(path, "/+")[[1]]
  for (i in seq_along(dirs)) {
    path <- paste(dirs[seq_len(i)], collapse = "/")
    if (!dir.exists(path) && nzchar(path)) {
      dir.create(path)
    }
  }
}

utils::globalVariables(
  c(
    ".", ".draw", "max_treedepth", "no_at_max_treedepth",
    "per_at_max_treedepth", "q20", "q5", "q80", "q95", "quantile",
    "sd", "..by", "cmf", "day_of_week", "delay", "new_confirm",
    "observed", ".old_group", "reference_date", "report_date",
    "reported_cases", "s", "time", "extend_date", "effects",
    "confirm", "effects", "fixed", ".group", "logmean", "logsd",
    ".new_group", "observed", "latest_confirm", "mad", "variable",
    "fit", "patterns", ".draws", "prop_reported", "max_confirm",
    "run_time", "cum_prop_reported", "..by_with_group_id",
    "reference_missing", "prop_missing", "day", "posteriors",
    "formula", ".id", "n", ".confirm_avail", "prediction", "true_value",
    "person", "id", "latest", "type", "below_coverage", "num_reference_date",
    "num_report_date", "rep_mod", "ref_mod", "count", "reference_date_mod",
    "report_date_mod", "timestep", ".observed", "lookup", "max_obs_delay",
    "coverage"
  )
)
