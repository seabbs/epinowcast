#' Evaluate nowcasts using proper scoring rules
#'
#' Acts as a wrapper to [scoringutils::score()]. In particular,
#' handling filtering nowcast summary output and linking this output to
#' observed data. See the documentation for the `scoringutils` package for more
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
#' [scoringutils::check_forecasts()] be used to check input nowcasts.
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
  if (!requireNamespace("scoringutils")) {
    cli::cli_abort(
      "The package `scoringutils` is required for this function to work."
    )
  }
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

  long_nowcast[, prediction := as.numeric(prediction)]
  long_nowcast[, true_value := as.numeric(true_value)]

  if (check) {
    scoringutils::check_forecasts(long_nowcast)
  }

  scores <- scoringutils::score(scoringutils::as_forecast(long_nowcast), ...)
  numeric_cols <- colnames(scores)[sapply(scores, is.numeric)]
  scores <- scores[, (numeric_cols) := lapply(.SD, signif, digits = round_to),
    .SDcols = numeric_cols
  ]
  return(scores[])
}
