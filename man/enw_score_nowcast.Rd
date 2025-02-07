% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model-validation.R
\name{enw_score_nowcast}
\alias{enw_score_nowcast}
\title{Evaluate nowcasts using proper scoring rules}
\usage{
enw_score_nowcast(
  nowcast,
  latest_obs,
  log = FALSE,
  check = FALSE,
  round_to = 3,
  ...
)
}
\arguments{
\item{nowcast}{A posterior nowcast or posterior prediction as returned by
\code{\link[=summary.epinowcast]{summary.epinowcast()}}, when used on the output of \code{\link[=epinowcast]{epinowcast()}}.}

\item{latest_obs}{A \code{data.frame} of the latest available observations as
produced by \code{\link[=enw_latest_data]{enw_latest_data()}} or otherwise.}

\item{log}{Logical, defaults to FALSE. Should scores be calculated on the
log scale (with a 0.01 shift) for both observations and nowcasts. Scoring in
this way can be thought of as a relative score vs the more usual absolute
measure. It may be useful when targets are on very different scales or when
the forecaster is more interested in good all round performance versus good
performance for targets with large values.}

\item{check}{Logical, defaults to FALSE. Should
input nowcasts be checked for consistency with the scoringutils package.}

\item{round_to}{Integer defaults to 3. Number of digits to round scoring
output to.}

\item{...}{
  Arguments passed on to \code{\link[scoringutils:score]{scoringutils::score}}
  \describe{
    \item{\code{forecast}}{A forecast object (a validated data.table with predicted and
observed values).}
    \item{\code{metrics}}{A named list of scoring functions. Names will be used as
column names in the output. See \code{\link[scoringutils:get_metrics]{get_metrics()}} for more information on the
default metrics used. See the \emph{Customising metrics} section below for
information on how to pass custom arguments to scoring functions.}
  }}
}
\value{
A \code{data.table} as returned by \code{\link[scoringutils:score]{scoringutils::score()}}.
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}}

This function is deprecated in favour of using
\code{\link[=as_forecast_sample.epinowcast]{as_forecast_sample.epinowcast()}} with \code{\link[scoringutils:score]{scoringutils::score()}}.
See the documentation for the \code{scoringutils} package for more details on
on forecast scoring.
}
\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
library(data.table)
library(scoringutils)

# Summarise example nowcast
nowcast <- enw_example("nowcast")
summarised_nowcast <- summary(nowcast)

# Load latest available observations
obs <- enw_example("observations")

# Keep the last 7 days of data
obs <- obs[reference_date > (max(reference_date) - 7)]

# score on the absolute scale
scores <- enw_score_nowcast(summarised_nowcast, obs)
summarise_scores(scores, by = "location")

# score overall on a log scale
log_scores <- enw_score_nowcast(summarised_nowcast, obs, log = TRUE)
summarise_scores(log_scores, by = "location")
\dontshow{\}) # examplesIf}
}
\seealso{
Other modelvalidation: 
\code{\link{as_forecast_sample.epinowcast}()}
}
\concept{modelvalidation}
