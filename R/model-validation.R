#' Evaluate nowcasts using proper scoring rules
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated in favour of using
#' [as_forecast_sample.epinowcast()] with [scoringutils::score()].
#' See the documentation for the `scoringutils` package for more details on
#' on forecast scoring.
#'
#' @param nowcast A posterior nowcast or posterior prediction as returned by
#' [summary.epinowcast()], when used on the output of [epinowcast()].
#'
#' @param latest_obs A `data.frame` of the latest available observations as
#' produced by [enw_latest_data()] or otherwise.
#'
#' @param log Logical, defaults to FALSE. Should scores be calculated on the
#' log scale (with a 0.01 shift) for both observations and nowcasts. Scoring in
#' this way can be thought of as a relative score vs the more usual absolute
#' measure. It may be useful when targets are on very different scales or when
#' the forecaster is more interested in good all round performance versus good
#' performance for targets with large values.
#'
#' @param check Logical, defaults to FALSE. Should
#' input nowcasts be checked for consistency with the scoringutils package.
#'
#' @param round_to Integer defaults to 3. Number of digits to round scoring
#' output to.
#'
#' @inheritDotParams scoringutils::score
#'
#' @return A `data.table` as returned by [scoringutils::score()].
#' @family modelvalidation
#' @importFrom data.table setnames
#' @importFrom cli cli_abort
#' @export
#' @examplesIf interactive()
#' library(data.table)
#' library(scoringutils)
#'
#' # Summarise example nowcast
#' nowcast <- enw_example("nowcast")
#' summarised_nowcast <- summary(nowcast)
#'
#' # Load latest available observations
#' obs <- enw_example("observations")
#'
#' # Keep the last 7 days of data
#' obs <- obs[reference_date > (max(reference_date) - 7)]
#'
#' # score on the absolute scale
#' scores <- enw_score_nowcast(summarised_nowcast, obs)
#' summarise_scores(scores, by = "location")
#'
#' # score overall on a log scale
#' log_scores <- enw_score_nowcast(summarised_nowcast, obs, log = TRUE)
#' summarise_scores(log_scores, by = "location")
enw_score_nowcast <- function(nowcast, latest_obs, log = FALSE,
                              check = FALSE, round_to = 3, ...) {
  lifecycle::deprecate_warn(
    "0.4.0",
    "enw_score_nowcast()",
    "as_forecast_sample.epinowcast()"
  )
  if (!requireNamespace("scoringutils")) {
    cli::cli_abort(
      "The package `scoringutils` is required for this function to work."
    )
  }

  # Convert to forecast_quantile format
  long_nowcast <- enw_quantiles_to_long(nowcast)
  if (!is.null(long_nowcast[["mad"]])) {
    long_nowcast[, "mad" := NULL]
  }

  latest_obs <- coerce_dt(latest_obs)
  data.table::setnames(latest_obs, "confirm", "true_value", skip_absent = TRUE)
  latest_obs[, report_date := NULL]

  cols <- intersect(colnames(nowcast), colnames(latest_obs))
  long_nowcast <- merge(long_nowcast, latest_obs, by = cols)

  if (log) {
    cols <- c("true_value", "prediction")
    long_nowcast[, (cols) := purrr::map(.SD, ~ log(. + 0.01)), .SDcols = cols]
  }

  forecast_data <- scoringutils::as_forecast_quantile(
    data = long_nowcast,
    observed = "true_value",
    predicted = "prediction",
    quantile_level = "quantile"
  )

  if (check) {
    print(forecast_data)
  }

  scores <- scoringutils::score(forecast_data, ...)
  numeric_cols <- colnames(scores)[sapply(scores, is.numeric)]
  scores <- scores[, (numeric_cols) := lapply(.SD, signif, digits = round_to),
    .SDcols = numeric_cols
  ]
  return(scores[])
}


#' @importFrom scoringutils as_forecast_sample
#' @export
scoringutils::as_forecast_sample

#' Convert an epinowcast object to a forecast_sample object
#'
#' This function is used to convert an `epinowcast` as returned by
#' [epinowcast()] object to a `forecast_sample` object which can be used for
#' scoring using the `scoringutils` package.
#'
#' @param data An `epinowcast` nowcast object as returned by
#' [epinowcast()].
#'
#' @param latest_obs Latest observations to use for the true values must
#' contain `confirm` and `observed` variables.
#'
#' @param ... Additional arguments passed to
#' [scoringutils::as_forecast_sample()]
#'
#' @return A `forecast_sample` object as returned by
#' [scoringutils::as_forecast_sample()]
#' @export
#' @method as_forecast_sample epinowcast
#' @family modelvalidation
#' @examplesIf interactive()
#' library(scoringutils)
#'
#' nowcast <- enw_example("nowcast")
#' latest_obs <- enw_example("observations")
#' as_forecast_sample(nowcast, latest_obs)
as_forecast_sample.epinowcast <- function(data, latest_obs, ...) {
  # Get samples from the nowcast
  samples <- summary(data, type = "nowcast_samples")
  samples[,
   c("confirm", ".chain", ".iteration", "max_confirm",
     "cum_prop_reported", "prop_reported"
    ) := NULL
  ]

  # Process latest observations
  latest_obs <- coerce_dt(
    latest_obs, required_cols = "confirm", dates = TRUE
  )
  latest_obs[, "report_date" := NULL]

  # Merge samples with observations
  cols <- intersect(colnames(samples), colnames(latest_obs))
  cols <- setdiff(cols, c("confirm", "sample", ".draw"))
  samples <- merge(samples, latest_obs, by = cols)


  # Convert to forecast_sample object using scoringutils column names
  scoringutils::as_forecast_sample(
    data = samples,
    observed = "confirm",
    predicted = "sample",
    sample_id = ".draw",
    ...)
}
