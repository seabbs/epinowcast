#' Reference date logit hazard reporting  model module
#'
#' @param parametric A formula (as implemented in [enw_formula()]) describing
#' the parametric reference date delay model. This can use features
#' defined by report date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. Note that this formula will be applied to all
#' summary statistics of the chosen parametric distribution but each summary
#' parameter will have separate effects. Use `~ 0` to not use a parametric
#' model.
#'
#' @param distribution A character vector describing the parametric delay
#' distribution to use. Current options are: "none", "lognormal", "gamma",
#' "exponential", and "loglogistic", with the default being "lognormal".
#'
#' @param non_parametric A formula (as implemented in [enw_formula()])
#' describing the non-parametric logit hazard model. This can use features
#' defined by reference date and by delay. It draws on a linked `data.frame`
#' using `metareference` and `metadelay` as produced by [enw_preprocess_data()].
#' When an effect per delay is specified this approximates the cox proportional
#' hazard model in discrete time with a single strata. When used in conjunction
#' with a parametric model it likely makes sense to disable the intercept in
#' order to make the joint model identifiable (i.e. `~ 0 + (1 | delay)`).
#'
#' @return A list containing the supplied formulas, data passed into a list
#' describing the models, a `data.frame` describing the priors used, and a
#' function that takes the output data and priors and returns a function that
#' can be used to sample from a tightened version of the prior distribution.
#'
#' @inheritParams enw_obs
#' @family modelmodules
#' @importFrom cli cli_abort
#' @export
#' @examples
#' # Parametric model with a lognormal distribution
#' enw_reference(
#'  parametric = ~1, distribution = "lognormal",
#'  data = enw_example("preprocessed")
#' )
#'
#' # Non-parametric model with a random effect per delay
#' enw_reference(
#'  parametric = ~ 0, non_parametric = ~ 1 + (1 | delay),
#'  data = enw_example("preprocessed")
#' )
#'
#' # Combined parametric and non-parametric model
#' enw_reference(
#'  parametric = ~ 1, non_parametric = ~ 0 + (1 | delay_cat),
#'  data = enw_example("preprocessed")
#' )
enw_reference <- function(
  parametric = ~1,
  distribution = c("lognormal", "none", "exponential", "gamma", "loglogistic"),
  non_parametric = ~0, data
) {
  if (as_string_formula(parametric) == "~0") {
    distribution <- "none"
    parametric <- ~1
  }
  distribution <- match.arg(distribution)
  if ((as_string_formula(non_parametric) == "~0") && distribution == "none") {
    cli::cli_abort(
      paste0(
        "A non-parametric model must be specified if no parametric model ",
        "is specified"
      )
    )
  }
  if (as_string_formula(non_parametric) == "~0") {
    non_parametric <- ~1
    model_refnp <- 0
  }else {
    model_refnp <- 1
  }

  distribution <- data.table::fcase(
    distribution == "none", 0,
    distribution == "exponential", 1,
    distribution == "lognormal", 2,
    distribution == "gamma", 3,
    distribution == "loglogistic", 4
  )
  # Define parametric model
  pform <- enw_formula(parametric, data$metareference[[1]], sparse = TRUE)
  check_design_matrix_sparsity(
    pform$fixed$design, name = "parametric reference date effects"
  )

  pdata <- enw_formula_as_data_list(
    pform,
    prefix = "refp", drop_intercept = TRUE
  )
  pdata$model_refp <- distribution

  # Define non-parametric model
  metanp <- merge(
    data.table::copy(data$metareference[[1]])[, delay := NULL][, id := 1],
    data.table::copy(data$metadelay[[1]])[, id := 1],
    by = "id",
    allow.cartesian = TRUE
  )[, id := NULL]

  npform <- enw_formula(
    non_parametric, metanp, sparse = FALSE
  )
  check_design_matrix_sparsity(
    npform$fixed$design, name = "non-parametric reference date effects"
  )

  npdata <- enw_formula_as_data_list(
    npform,
    prefix = "refnp", drop_intercept = TRUE
  )
  npdata$model_refnp <- model_refnp

  # Map models to output
  out <- list()
  out$formula$parametric <- pform$formula
  out$formula$non_parametric <- npform$formula
  out$data <- c(pdata, npdata)
  out$priors <- data.table::data.table(
    variable = c(
      "refp_mean_int", "refp_sd_int", "refp_mean_beta_sd", "refp_sd_beta_sd",
      "refnp_int", "refnp_beta_sd"
    ),
    description = c(
      "Log mean intercept for parametric reference date delay",
      "Log standard deviation for the parametric reference date delay",
      "Standard deviation of scaled pooled parametric mean effects",
      "Standard deviation of scaled pooled parametric sd effects",
      "Intercept for non-parametric reference date delay",
      "Standard deviation of scaled pooled non-parametric effects"
    ),
    distribution = c(
      "Normal", rep("Zero truncated normal", 3),
      "Normal", "Zero truncated normal"
    ),
    mean = c(1, 0.5, 0, 0, 0, 0),
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        refp_mean_int = numeric(0),
        refp_sd_int = numeric(0),
        refp_mean_beta = numeric(0),
        refp_sd_beta = numeric(0),
        refp_mean_beta_sd = numeric(0),
        refp_sd_beta_sd = numeric(0),
        refnp_int = numeric(0),
        refnp_beta = numeric(0),
        refnp_beta_sd = numeric(0)
      )
      if (data$model_refp > 0) {
        init$refp_mean_int <- array(rnorm(
          1, priors$refp_mean_int_p[1], priors$refp_mean_int_p[2] / 10
        ))
      }
      if (data$model_refp > 1) {
        init$refp_sd_int <- array(abs(
          rnorm(1, priors$refp_sd_int_p[1], priors$refp_sd_int_p[2] / 10)
        ))
      }
      init$refp_mean <- rep(init$refp_mean_int, data$refp_fnrow)
      init$refp_sd <- rep(init$refp_sd_int, data$refp_fnrow)
      if (data$refp_fncol > 0) {
        init$refp_mean_beta <- array(
          rnorm(data$refp_fncol, 0, 0.01)
        )
        if (data$model_refp > 1) {
          init$refp_sd_beta <- array(
            rnorm(data$refp_fncol, 0, 0.01)
          )
        }
      }
      if (data$refp_rncol > 0) {
        init$refp_mean_beta_sd <- array(abs(rnorm(
          data$refp_rncol, priors$refp_mean_beta_sd_p[1],
          priors$refp_mean_beta_sd_p[2] / 10
        )))
        if (data$model_refp > 1) {
          init$refp_sd_beta_sd <- array(abs(rnorm(
            data$refp_rncol, priors$refp_sd_beta_sd_p[1],
            priors$refp_sd_beta_sd_p[2] / 10
          )))
        }
      }
      if (data$model_refnp > 0) {
        if (data$refnp_fintercept > 0) {
          init$refnp_int <- array(rnorm(
            1, priors$refnp_int_p[1], priors$refnp_int_p[2] / 10
          ))
        }
        if (data$refnp_fncol > 0) {
          init$refnp_beta <- array(rnorm(data$refnp_fncol, 0, 0.01))
        }
        if (data$refnp_rncol > 0) {
          init$refnp_beta_sd <- array(abs(rnorm(
            data$refnp_rncol, priors$refnp_beta_sd_p[1],
            priors$refnp_beta_sd_p[2] / 10
          )))
        }
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Report date logit hazard reporting  model module
#'
#' @param non_parametric A formula (as implemented in [enw_formula()])
#' describing the non-parametric logit hazard model. This can use features
#' defined by report date as defined in `metareport` as produced by
#' [enw_preprocess_data()]. Note that the intercept for this model is set to 0
#' as it should be used for specifying report date related hazards vs time
#' invariant hazards which should instead be modelled using the
#' `non_parametric` argument of [enw_reference()]
#'
#' @param structural A nested list of matrices by group and reference date
#' describing the known reporting structure (i.e weekday only reporting).
#' Each matrix should have dimensions of max_delay x max_delay, where
#' each column represents the probability of an observation being reported
#' on a specific day given the delay. This is particularly useful for
#' modeling fixed reporting cycles, such as weekly reporting on Wednesdays
#' as seen in the German hospitalization data example.
#'
#' @inherit enw_reference return
#' @inheritParams enw_obs
#' @inheritParams enw_formula
#' @importFrom cli cli_abort
#' @family modelmodules
#' @export
#' @examples
#' enw_report(data = enw_example("preprocessed"))
enw_report <- function(non_parametric = ~0, structural = NULL, data) {
  if (as_string_formula(non_parametric) == "~0") {
    non_parametric <- ~1
  }

  form <- enw_formula(non_parametric, data$metareport[[1]], sparse = TRUE)
  check_design_matrix_sparsity(
    form$fixed$design, name = "report date effects"
  )

  data_list <- enw_formula_as_data_list(
    form,
    prefix = "rep", drop_intercept = TRUE
  )

  # Check for structural model and define
  if (!is.null(structural)) {
    cli::cli_alert_warning(
      "The structural reporting model is in experimental development"
    )
    if (!is.list(structural) ||
        length(structural) != data$groups[[1]] ||
        !all(sapply(structural, function(x) length(x) == data$time[[1]])) ||
        !all(sapply(structural, function(x) {
          all(
            sapply(
              x, function(y) all(dim(y) == c(data$max_delay, data$max_delay))
            )
          )
        })
      )) {
      cli::cli_abort(
        paste0(
          "`structural` should be a list of groups, each containing a list of ",
          "reference times, where each entry is a matrix of Max Delay x Max
           Delay."
        )
      )
    }
    data_list$rep_agg_p <- 1
    data_list$rep_agg_indicators <- array(
      unlist(structural),
      dim = c(
        data$groups[[1]], data$time[[1]], data$max_delay, data$max_delay
      )
    )
  } else {
    data_list$rep_agg_p <- 0
    data_list$rep_agg_indicators <- list()
  }

  # map report date effects to groups and times
  data_list$rep_findex <- t(
    matrix(
      data_list$rep_findex,
      ncol = data$groups[[1]],
      nrow = data$time[[1]] +
        data$max_delay - 1
    )
  )
  data_list$rep_t <- data$time[[1]] +
    data$max_delay - 1
  data_list$model_rep <- as.numeric(
    as_string_formula(non_parametric) != "~1"
  )

  out <- list()
  out$formula$non_parametric <- form$formula
  out$data <- data_list
  out$priors <- data.table::data.table(
    variable = "rep_beta_sd",
    description = "Standard deviation of scaled pooled report date effects",
    distribution = "Zero truncated normal",
    mean = 0,
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        rep_beta = numeric(0),
        rep_beta_sd = numeric(0)
      )
      if (data$rep_fncol > 0) {
        init$rep_beta <- array(rnorm(data$rep_fncol, 0, 0.01))
      }
      if (data$rep_rncol > 0) {
        init$rep_beta_sd <- array(abs(rnorm(
          data$rep_rncol, priors$rep_beta_sd_p[1],
          priors$rep_beta_sd_p[2] / 10
        )))
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Expectation model module
#'
#' @param r A formula (as implemented in [enw_formula()]) describing
#' the generative process used for expected incidence. This can use features
#' defined by reference date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. By default this is set to use a daily random effect
#' by group. This parameterisation is highly flexible and so may not be the
#' most appropriate choice when data is sparsely reported or reporting delays
#' are substantially. These settings an alternative could be a group specific
#' weekly random walk (specified as `rw(week, by = .group`).
#'
#' @param generation_time A numeric vector that sums to 1 and defaults to 1.
#' Describes the weighting to apply to previous generations (i.e as part of a
#' renewal equation). When set to 1 (the default) this corresponds to modelling
#' the daily growth rate.
#'
#' @param observation A formula (as implemented in [enw_formula()]) describing
#' the modifiers used to adjust expected observations. This can use features
#' defined by reference date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. By default no modifiers are used but a common choice
#' might be to adjust for the day of the week. Note as the baseline is no
#' modification an intercept is always used and it is set to 0.
#'
#' @param latent_reporting_delay A numeric vector that defaults to 1.
#' Describes the weighting to apply to past and current latent expected
#' observations (from most recent to least). This can be used both to convolve
#' based on some assumed reporting delay and to rescale observations (by
#' multiplying a probability mass function by some fraction) to account
#' ascertainment etc. A list of PMFs can be provided to allow for time-varying
#' PMFs. This should be the same length as the modelled time period plus the
#' length of the generation time if supplied.
#'
#' @param ... Additional parameters passed to [enw_add_metaobs_features()]. The
#' same arguments as passed to `enw_preprocess_data()` should be used here.
#' @inherit enw_report return
#' @inheritParams enw_obs
#' @family modelmodules
#' @importFrom purrr map2_dbl
#' @importFrom cli cli_abort
#' @export
#' @examples
#' enw_expectation(data = enw_example("preprocessed"))
enw_expectation <- function(r = ~ 0 + (1 | day:.group), generation_time = 1,
                            observation = ~1, latent_reporting_delay = 1,
                            data, ...) {
  if (as_string_formula(r) == "~0") {
    cli::cli_abort("An expectation model formula for r must be specified")
  }
  if (as_string_formula(observation) == "~0") {
    observation <- ~1
  }
  if (sum(generation_time) != 1) {
    cli::cli_abort("The generation time must sum to 1")
  }

  # Set up growth rate features
  r_features <- data$metareference[[1]]
  if (length(latent_reporting_delay) > 1) {
    r_features <- enw_extend_date(
      r_features,
      days = length(latent_reporting_delay) - 1, direction = "start"
    )
    suppressWarnings(enw_add_metaobs_features(r_features, ...))
  }
  r_features <- r_features[
    date >= (min(date) + length(generation_time))
  ]

  # Growth rate indicator variables & generation time terms
  r_list <- list(
    r_seed = length(generation_time),
    gt_n = length(generation_time),
    lrgt = log(rev(generation_time)),
    t = nrow(r_features) / data$groups[[1]],
    obs = 0
  )

  r_list$g <- cumsum(
    rep(r_list$t, data$groups[[1]])
  ) - r_list$t
  r_list$ft <- r_list$t + r_list$r_seed

  # Initial prior for seeding observations
  latest_matrix <- latest_obs_as_matrix(data$latest[[1]])
  seed_obs <- (latest_matrix[1, ] + 1) * sum(latent_reporting_delay)
  seed_obs <- purrr::map(seed_obs, ~ rep(log(.), r_list$gt_n))
  seed_obs <- round(unlist(seed_obs), 1)

  # Growth rate model formula
  r_form <- enw_formula(r, r_features, sparse = FALSE)
  check_design_matrix_sparsity(r_form$fixed$design, name = "r")

  r_data <- enw_formula_as_data_list(
    r_form,
    prefix = "expr", drop_intercept = TRUE
  )

  # Observation indicator variables
  obs_list <- list(
    lrd_n = ifelse(is.list(latent_reporting_delay),
      length(latent_reporting_delay[[1]]), length(latent_reporting_delay)
    ),
    lrd = convolution_matrix(
      latent_reporting_delay, r_list$ft,
      include_partial = FALSE
    )
  )

  obs_list$obs <- as.numeric(
    sum(latent_reporting_delay) != 1 || obs_list$lrd_n != 1 ||
      as_string_formula(observation) != "~1"
  )
  # Observation formula
  obs_form <- enw_formula(observation, data$metareference[[1]], sparse = FALSE)
  check_design_matrix_sparsity(
    obs_form$fixed$design, name = "observation"
  )

  obs_data <- enw_formula_as_data_list(
    obs_form,
    prefix = "expl", drop_intercept = TRUE
  )

  out <- list()
  out$formula$r <- r_form$formula
  out$formula$observation <- obs_form$formula
  out$data_raw$r <- r_features
  out$data_raw$observation <- data$metareference[[1]]

  names(r_list) <- paste0("expr_", names(r_list))
  names(obs_list) <- paste0("expl_", names(obs_list))
  out$data <- c(r_list, r_data, obs_list, obs_data)

  out$priors <- data.table::data.table(
    variable = c(
      "expr_r_int", "expr_beta_sd",
      rep("expr_lelatent_int", length(seed_obs)),
      "expl_beta_sd"
    ),
    dimension = c(1, 1, seq_along(seed_obs), 1),
    description = c(
      "Intercept of the log growth rate",
      "Standard deviation of scaled pooled log growth rate effects",
      rep("Intercept for initial log observations (ordered by group and then
          time)", length(seed_obs)),
      "Standard deviation of scaled pooled log growth rate effects"
    ),
    distribution = c(
      "Normal", "Zero truncated normal", rep("Normal", length(seed_obs)),
      "Zero truncated normal"
    ),
    mean = c(0, 0, seed_obs, 0),
    sd = c(0.2, 1, rep(1, length(seed_obs)), 1)
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        expr_beta = numeric(0),
        expr_beta_sd = numeric(0),
        expr_lelatent_int = matrix(
          purrr::map2_dbl(
            as.vector(priors$expr_lelatent_int_p[1]),
            as.vector(priors$expr_lelatent_int_p[2]),
            function(x, y) {
              rnorm(1, x, y * 0.1)
            }
          ),
          nrow = data$expr_gt_n, ncol = data$g
        ),
        expr_r_int = numeric(0),
        expl_beta = numeric(0),
        expl_beta_sd = numeric(0)
      )
      if (data$expr_fncol > 0) {
        init$expr_beta <- array(rnorm(data$expr_fncol, 0, 0.01))
      }
      if (data$expr_rncol > 0) {
        init$expr_beta_sd <- array(abs(rnorm(
          data$expr_rncol, priors$expr_beta_sd_p[1],
          priors$expr_beta_sd_p[2] / 10
        )))
      }
      if (data$expr_fintercept > 0) {
        init$expr_r_int <- array(rnorm(
          1, priors$expr_r_int_p[1], priors$expr_r_int_p[2] * 0.1
        ))
      }
      if (data$expl_fncol > 0) {
        init$expl_beta <- array(rnorm(data$expl_fncol, 0, 0.01))
      }
      if (data$expl_rncol > 0) {
        init$expl_beta_sd <- array(abs(rnorm(
          data$expl_rncol, priors$expl_beta_sd_p[1],
          priors$expl_beta_sd_p[2] / 10
        )))
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Missing reference data model module
#'
#' @param formula A formula (as implemented in [enw_formula()]) describing
#' the missing data proportion on the logit scale by reference date. This can
#' use features defined by reference date as defined in `metareference` as
#' produced by [enw_preprocess_data()]. "~0" implies no model is required.
#' Otherwise an intercept is always needed
#'
#' @inherit enw_reference return
#' @inheritParams enw_obs
#' @inheritParams enw_formula
#' @family modelmodules
#' @importFrom data.table setorderv dcast
#' @importFrom purrr map
#' @importFrom cli cli_abort cli_warn
#' @export
#' @examples
#' # Missingness model with a fixed intercept only
#' enw_missing(data = enw_example("preprocessed"))
#'
#' # No missingness model specified
#' enw_missing(~0, data = enw_example("preprocessed"))
enw_missing <- function(formula = ~1, data) {
  if (nrow(data$missing_reference[[1]]) == 0 &&
    as_string_formula(formula) != "~0") {
    cli::cli_abort(
      paste0(
        "A missingness model has been specified, but no observations ",
        "with missing reference date are in the preprocessed data."
      )
    )
  }

  if (as_string_formula(formula) == "~0") {
    # empty data list required by stan
    data_list <- enw_formula_as_data_list(
      prefix = "miss", drop_intercept = FALSE
    )
    data_list$missing_reference <- numeric(0)
    data_list$obs_by_report <- numeric(0)
    data_list$miss_st <- numeric(0)
    data_list$miss_cst <- numeric(0)
    data_list$model_miss <- 0
    data_list$miss_obs <- 0
  } else {
    # Make formula for effects
    form <- enw_formula(formula, data$metareference[[1]], sparse = FALSE)
    check_design_matrix_sparsity(
      form$fixed$design, name = "missing"
    )
    data_list <- enw_formula_as_data_list(
      form,
      prefix = "miss",
      drop_intercept = TRUE
    )

    # Get report dates that cover all reference dates up to the max delay
    rep_w_complete_ref <- enw_reps_with_complete_refs(
      data$new_confirm[[1]],
      max_delay = data$max_delay,
      by = ".group"
    )

    # Get the indexes for when grouped observations start and end
    miss_lookup <- coerce_dt(rep_w_complete_ref)
    data_list$miss_st <- miss_lookup[, n := seq_len(.N), by = ".group"]
    data_list$miss_st <- data_list$miss_st[, .(n = max(n)), by = ".group"]$n
    data_list$miss_cst <- miss_lookup[, n := seq_len(.N)]
    data_list$miss_cst <- data_list$miss_cst[, .(n = max(n)), by = ".group"]$n

    # Get (and order) reported cases with a missing reference date
    missing_reference <- coerce_dt(data$missing_reference[[1]])
    data.table::setkeyv(missing_reference, c(".group", "report_date"))
    data_list$missing_reference <- coerce_dt(missing_reference)[
      rep_w_complete_ref,
      on = c("report_date", ".group")
    ][, confirm]

    # Build a look up between reports and reference dates
    reference_by_report <- enw_reference_by_report(
      missing_reference,
      reps_with_complete_refs = rep_w_complete_ref,
      metareference = data$metareference[[1]],
      max_delay = data$max_delay
    )
    data_list$obs_by_report <- as.matrix(reference_by_report[, -1])

    # Add indicator and length/shape variables
    data_list$model_miss <- 1
    data_list$miss_obs <- length(data_list$missing_reference)
  }

  out <- list()
  out$formula <- as_string_formula(formula)
  out$data <- data_list
  # Define default priors
  out$priors <- data.table::data.table(
    variable = c("miss_int", "miss_beta_sd"),
    description = c(
      "Intercept on the logit scale for the proportion missing reference dates",
      "Standard deviation of scaled pooled logit missing reference date
       effects"
    ),
    distribution = c("Normal", "Zero truncated normal"),
    mean = c(0, 0),
    sd = c(1, 1)
  )
  # Define a function for sampling from the priors and data
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        miss_int = numeric(0),
        miss_beta = numeric(0),
        miss_beta_sd = numeric(0)
      )
      if (data$model_miss) {
        init$miss_int <- array(
          rnorm(1, priors$miss_int_p[1], priors$miss_int_p[2])
        )
        if (data$miss_fncol > 0) {
          init$miss_beta <- array(rnorm(data$miss_fncol, 0, 0.01))
        }
        if (data$miss_rncol > 0) {
          init$miss_beta_sd <- array(abs(rnorm(
            data$miss_rncol, priors$miss_beta_sd_p[1],
            priors$miss_beta_sd_p[2] / 10
          )))
        }
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Setup observation model and data
#'
#' @param family Character string, the observation model to use in the
#' likelihood; enforced by [base::match.arg()]. By default this is a
#' negative binomial ("negbin") with Poisson ("poisson") also being
#' available. Support for additional observation models is planned,
#' please open an issue with suggestions.
#'
#' @param observation_indicator A character string, the name of the column in
#' the data that indicates whether an observation is observed or not (using a
#' logical variable) and therefore whether or not it should be used in the
#' likelihood. This variable should be present in the data input to
#' [enw_preprocess_data()]. It can be generated using `flag_observation` in
#' [enw_complete_dates()] or it can be created directly using
#' [enw_flag_observed_observations()]. If either of these approaches are used
#' then the variable will be name `.observed`. Default is `NULL`.
#'
#' @param data Output from [enw_preprocess_data()].
#'
#' @return A list as required by stan.
#' @family modelmodules
#' @export
#' @examples
#' enw_obs(data = enw_example("preprocessed"))
enw_obs <- function(family = c("negbin", "poisson"),
                   observation_indicator = NULL, data) {
  family <- match.arg(family)

  # copy new confirm for processing
  new_confirm <- coerce_dt(
    data$new_confirm[[1]],
    required_cols = c(
      "reference_date", "delay", "confirm", observation_indicator
    )
  )
  data.table::setkeyv(new_confirm, c(".group", "reference_date", "delay"))
  check_observation_indicator(new_confirm, observation_indicator)

  # filter out observations beyond the maximum observation
  new_confirm <- add_max_observed_delay(new_confirm, observation_indicator)
  filt_new_confirm <- new_confirm[delay <= max_obs_delay]

  # Add a look up for observations
  filt_new_confirm[, lookup := seq_len(.N)]

  # Filter out missing observations
  if (!is.null(observation_indicator)) {
    filt_new_confirm <- filt_new_confirm[(get(observation_indicator))]
  }

  # Format indexing and observed data
  # See stan code for docs on what all of these are
  proc_data <- list(
    n = nrow(filt_new_confirm),
    t = data$time[[1]],
    s = data$snapshots[[1]],
    g = data$groups[[1]],
    groups = 1:data$groups[[1]]
  )

  # Add in incidence observation metadata
  proc_data <- c(
    proc_data,
    extract_obs_metadata(
      new_confirm, observation_indicator = observation_indicator
    )
  )

  # Add in maximum delay indexes
  proc_data <- c(
    proc_data,
    list(
      dmax = data$max_delay,
      sdmax = rep(data$max_delay, data$snapshots[[1]]),
      csdmax = cumsum(rep(data$max_delay, data$snapshots[[1]])),
      obs = as.matrix(data$reporting_triangle[[1]][, -(1:2)])
    )
  )

  # Add in observations in flat format without missing observations
  proc_data$flat_obs <- filt_new_confirm$new_confirm

  # Add link between flat observations and complete ones
  proc_data$flat_obs_lookup <- filt_new_confirm$lookup

  # How do observations relate to where we are in the data
  # Add matrix of latest observed data
  proc_data$latest_obs <- latest_obs_as_matrix(data$latest[[1]])

  # Add a switch for the observation model
  proc_data$model_obs <- data.table::fcase(
    family == "poisson", 0,
    family == "negbin", 1
  )

  out <- list()
  out$family <- family
  out$data <- proc_data
  out$priors <- data.table::data.table(
    variable = "sqrt_phi",
    description = "One over the square root of the reporting overdispersion",
    distribution = "Zero truncated normal",
    mean = 0,
    sd = 0.5
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        sqrt_phi = numeric(0),
        phi = numeric(0)
      )
      if (data$model_obs == 1) {
        init$sqrt_phi <- array(
          abs(rnorm(1, priors$sqrt_phi_p[1], priors$sqrt_phi_p[2] / 10))
        )
        init$phi <- 1 / (init$sqrt_phi^2)
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Format model fitting options for use with stan
#'
#' @param sampler A function that creates an object that be used to extract
#' posterior samples from the specified model. By default this is [enw_sample()]
#' which makes use of [cmdstanr::sample()].
#'
#' @param nowcast Logical, defaults to `TRUE`. Should a nowcast be made using
#' posterior predictions of the unobserved future reported notifications.
#'
#' @param pp Logical, defaults to `FALSE`. Should posterior predictions be made
#' for observed data. Useful for evaluating the performance of the model.
#'
#' @param likelihood Logical, defaults to `TRUE`. Should the likelihood be
#' included in the model
#'
#' @param likelihood_aggregation Character string, aggregation over which
#' stratify the likelihood when `threads_per_chain` is greater than 1; enforced
#' by [base::match.arg()]. Currently supported options:
#'  * "snapshots" which aggregates over report dates and groups (i.e the lowest
#' level that observations are reported at),
#'  * "groups" which aggregates across user defined groups.
#'
#' Note that some model modules override this setting depending on model
#' requirements. For example, the [enw_missing()] module model forces
#' "groups" option. Generally, Users should typically want the default
#' "snapshots" aggregation.
#'
#' @param threads_per_chain Integer, defaults to `1`. The number of threads to
#' use within each MCMC chain. If this is greater than `1` then components of
#' the likelihood will be calculated in parallel within each chain.
#'
#' @param debug Logical, defaults to `FALSE`. Should within model debug
#' information be returned.
#'
#' @param output_loglik Logical, defaults to `FALSE`. Should the
#' log-likelihood be output. Disabling this will speed up fitting
#' if evaluating the model fit is not required.
#'
#' @param sparse_design Logical, defaults to `FALSE`. Should a sparse design
#' matrices be used for all design matrices. This reduces memory requirements
#' and may reduce computation time when fitting models with very sparse
#' design matrices (90% or more zeros).
#'
#' @param ... Additional arguments to pass to the fitting function being used
#' by [epinowcast()]. By default this will be [enw_sample()] and so `cmdstanr`
#' options should be used.
#'
#' @return A list containing the specified sampler function, data as a list
#' specifying the fitting options to use, and additional arguments to pass
#' to the sampler function when it is called.
#'
#' @importFrom data.table fcase
#' @family modelmodules
#' @export
#' @examples
#' # Default options along with settings to pass to enw_sample
#' enw_fit_opts(iter_sampling = 1000, iter_warmup = 1000)
enw_fit_opts <- function(sampler = epinowcast::enw_sample,
                         nowcast = TRUE, pp = FALSE, likelihood = TRUE,
                         likelihood_aggregation = c("snapshots", "groups"),
                         threads_per_chain = 1L,
                         debug = FALSE, output_loglik = FALSE,
                         sparse_design = FALSE, ...) {
  if (pp) {
    nowcast <- TRUE
  }
  likelihood_aggregation <- match.arg(likelihood_aggregation)
  likelihood_aggregation <- fcase(
    likelihood_aggregation == "snapshots", 0,
    likelihood_aggregation == "groups", 1
  )

  out <- list(sampler = sampler)
  out$data <- list(
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    likelihood_aggregation = likelihood_aggregation,
    parallelise_likelihood = as.integer(threads_per_chain > 1),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast),
    ologlik = as.numeric(output_loglik),
    sparse_design = as.integer(sparse_design)
  )
  out$args <- list(threads_per_chain = threads_per_chain, ...)
  return(out)
}
