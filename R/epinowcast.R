#' @title Nowcast using partially observed data
#'
#' @description Provides a user friendly interface around package functionality
#' to produce a nowcast from observed preprocessed data, and a series of user
#' defined models. By default a model that assumes a fixed parametric reporting
#' distribution with a flexible expectation model is used. Explore the
#' individual model components for additional documentation and see the package
#' case studies for example model specifications for different tasks.
#'
#' @param reference The reference date indexed reporting process model
#' specification as defined using [enw_reference()].
#'
#' @param report The report date indexed reporting process model
#' specification as defined using [enw_report()].
#'
#' @param expectation The expectation model specification as defined using
#' [enw_expectation()]. By default this is set to be a highly flexible random
#' effect by reference date for each group and thus weakly informed. Depending
#' on your context (and in particular the density of data reporting) other
#' choices that enforce more assumptions may be more appropriate (for example a
#' weekly random walk (specified using `rw(week, by = .group)`)).
#'
#' @param missing The missing reference date model specification as defined
#' using [enw_missing()]. By default this is set to not be used.
#'
#' @param obs The observation model as defined by [enw_obs()].
#' Observations are also processed within this function for use in modelling.
#'
#' @param fit Model fit options as defined using [enw_fit_opts()]. This includes
#' the sampler function to use (with the package default being [enw_sample()]),
#' whether or now a nowcast should be used, etc. See [enw_fit_opts()] for
#' further details.
#'
#' @param model The model to use within `fit`. By default this uses
#' [enw_model()].
#'
#' @param priors A `data.frame` with the following variables:
#' `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions. Priors in this data.frame
#' replace the default priors specified by each model component. See the
#' package vignette for more details on how to specify `priors`.
#'
#' @param ... Additional model modules to pass to `model`. User modules may
#' be used but currently require the supplied `model` to be adapted.
#'
#' @return A object of the class "epinowcast" which inherits from
#' [enw_preprocess_data()] and `data.table`, and combines the input data,
#' priors, and output from the sampler specified in `enw_fit_opts()`.
#' @inheritParams enw_obs
#' @importFrom purrr map transpose flatten walk
#' @importFrom cli cli_warn
#' @family epinowcast
#' @export
#' @examplesIf interactive()
#' # Load data.table and ggplot2
#' library(data.table)
#' library(ggplot2)
#'
#' # Use 2 cores
#' options(mc.cores = 2)
#' # Load and filter germany hospitalisations
#' nat_germany_hosp <-
#'   germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' nat_germany_hosp <- enw_filter_report_dates(
#'   nat_germany_hosp,
#'   latest_date = "2021-10-01"
#' )
#' # Make sure observations are complete
#' nat_germany_hosp <- enw_complete_dates(
#'   nat_germany_hosp,
#'   by = c("location", "age_group")
#' )
#' # Make a retrospective dataset
#' retro_nat_germany <- enw_filter_report_dates(
#'   nat_germany_hosp,
#'   remove_days = 40
#' )
#' retro_nat_germany <- enw_filter_reference_dates(
#'   retro_nat_germany,
#'   include_days = 40
#' )
#' # Get latest observations for the same time period
#' latest_obs <- enw_latest_data(nat_germany_hosp)
#' latest_obs <- enw_filter_reference_dates(
#'   latest_obs,
#'   remove_days = 40, include_days = 20
#' )
#' # Preprocess observations (note this maximum delay is likely too short)
#' pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)
#' # Fit the default nowcast model and produce a nowcast
#' # Note that we have reduced samples for this example to reduce runtimes
#' nowcast <- epinowcast(pobs,
#'   fit = enw_fit_opts(
#'     save_warmup = FALSE, pp = TRUE,
#'     chains = 2, iter_warmup = 500, iter_sampling = 500
#'   )
#' )
#' nowcast
#' # plot the nowcast vs latest available observations
#' plot(nowcast, latest_obs = latest_obs)
#'
#' # plot posterior predictions for the delay distribution by date
#' plot(nowcast, type = "posterior") +
#'   facet_wrap(vars(reference_date), scale = "free")
epinowcast <- function(data,
                       reference = epinowcast::enw_reference(
                         parametric = ~1,
                         distribution = "lognormal",
                         non_parametric = ~0,
                         data = data
                       ),
                       report = epinowcast::enw_report(
                         non_parametric = ~0,
                         structural = ~0,
                         data = data
                       ),
                       expectation = epinowcast::enw_expectation(
                         r = ~ 0 + (1 | day:.group),
                         generation_time = 1,
                         observation = ~1,
                         latent_reporting_delay = 1,
                         data = data
                       ),
                       missing = epinowcast::enw_missing(
                         formula = ~0,
                         data = data
                       ),
                       obs = epinowcast::enw_obs(
                         family = "negbin", data = data
                       ),
                       fit = epinowcast::enw_fit_opts(
                         sampler = epinowcast::enw_sample,
                         nowcast = TRUE, pp = FALSE,
                         likelihood = TRUE, debug = FALSE,
                         output_loglik = FALSE
                       ),
                       model = epinowcast::enw_model(),
                       priors,
                       ...) {
  modules <- list(
    expectation, reference, report, missing, obs, fit, ...
  )
  names(modules) <- as.character(seq_len(length(modules)))
  purrr::walk(modules, check_module)
  check_modules_compatible(modules)

  modules <- purrr::transpose(modules)
  data_as_list <- purrr::flatten(modules$data)

  default_priors <- data.table::rbindlist(
    modules$priors,
    fill = TRUE, use.names = TRUE
  )

  if (!missing(priors)) {
    priors <- enw_replace_priors(default_priors, priors)
  } else {
    priors <- default_priors
  }

  data_as_list <- c(
    data_as_list,
    enw_priors_as_data_list(priors)
  )

  if (missing$formula != "~0") {
    cli::cli_warn(
      paste0(
        "The missing data model is highly experimental. There is a ",
        "significant chance of bugs in its implementation."
      )
    )
  }

  inits <- purrr::compact(modules$inits)
  init_fns <- purrr::map(names(inits), ~ inits[[.]](data_as_list, priors))

  init_fn <- function(init_fns = init_fns) {
    init_inner_fn <- function() {
      inits <- purrr::map(init_fns, do.call, args = list())
      inits <- purrr::flatten(inits)
      return(inits)
    }
    return(init_inner_fn)
  }

  fit <- do.call(
    fit$sampler, c(
      list(
        data = data_as_list,
        model = model,
        init = init_fn(init_fns)
      ),
      fit$args
    )
  )

  out <- cbind(data, priors = list(priors), fit)
  class(out) <- c("epinowcast", "enw_preprocess_data", class(out))
  return(out[])
}
