# Load packages
library(epinowcast)
library(data.table)

# Set cmdstan path
cmdstanr::set_cmdstan_path()

# Use 2 cores
options(mc.cores = 2)

# Load and filter germany hospitalisations
nat_germany_hosp <- germany_covid19_hosp[location == "DE"] |>
  _[age_group == "00+"] |>
  _[, age_group := NULL] |>
  _[, location := NULL]

nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)

nat_germany_hosp <- enw_filter_reference_dates(
  nat_germany_hosp,
  earliest_date = "2021-07-01"
)

nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp, timestep = "day"
)

enw_flag_report_day <- function(data) {
  data[, .report_day := ifelse(is.na(confirm), 0, 1)]
  return(data)
}

# Aggregate data to weekly reporting cycle
repcycle_germany_hosp <- nat_germany_hosp |>
  _[, day_of_week := weekdays(report_date)] |>
  epinowcast:::aggregate_rolling_sum(
    internal_timestep = 7,
    by = "reference_date",
    value_col = "confirm"
  ) |>
  _[, confirm := fifelse(day_of_week == "Wednesday", confirm, NA_real_)] |>
  enw_flag_report_day() |>
  enw_flag_observed_observations() |>
  enw_impute_na_observations() |>
  enw_add_incidence()

# Make sure observations are complete (we don't need to do this here as we have
# already done this above but for completeness we include it (as it would be
# needed for real data)) 
repcycle_germany_hosp <- enw_complete_dates(
  repcycle_germany_hosp, timestep = "day"
)

# Make a retrospective real-time dataset
rt_nat_germany <- enw_filter_report_dates(
  repcycle_germany_hosp,
  remove_days = 20
)
rt_nat_germany <- enw_filter_reference_dates(
  rt_nat_germany,
  include_days = 90
)

# Get latest observations for the same time period
latest_obs <- enw_latest_data(repcycle_germany_hosp)
latest_obs <- enw_filter_reference_dates(
  latest_obs,
  remove_days = 20, include_days = 7
)

# I think we need to skip data that is not on a reported day in the likelihood
# otherwise we are not identifying the reporting delay properly.

max_delay <- 7
# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(
  rt_nat_germany, max_delay = max_delay, timestep = "day"
)

# Create structual reporting data for wednesday reporting
metadata <- pobs$metareference[[1]] |>
  _[, key := 1] |>
  _[, .(key, .group, date)] |>
  _[pobs$metadelay[[1]][, key := 1], on = "key", allow.cartesian = TRUE] |>
  _[, .(.group, date, report_date = date + delay)] |>
  setorder(.group, date, report_date) |>
  _[, day_of_week := weekdays(report_date)] |>
  _[, report := ifelse(day_of_week == "Wednesday", 1, 0)]

# Generic munging to make it easier to find reporting
metadata <- metadata |>
  _[, cum_report := cumsum(report) + 1, by = .(.group, date)] |>
  _[day_of_week == "Wednesday", cum_report := cum_report - 1]

# Add columns for 1:max_delay
# Create a data.table with columns called delay_1 to delay_35 programmatically
delays <- data.table()
# Add columns delay_1 to delay_35
for (i in 1:max_delay) {
  delays[, paste0("delay_", i) := 0]
}

# Add delay columns to metadata
metadata <- metadata |>
  _[, key := 1] |>
  merge(delays[, key := 1], by = "key") |>
  _[, key := NULL]

# Fill in the delay columns based on reporting
metadata[report == 1, (paste0("delay_", 1:max_delay)) := as.list(
  as.numeric(cum_report == cum_report[which(report == 1)])
), by = .(.group, date)
]

# Join pobs$new_confirm to metadata
metadata <- pobs$new_confirm[[1]] |>
  _[, .(date = reference_date, report_date, .observed)] |>
  _[metadata, on = c("date", "report_date")]

# Check if .observed is 0 for all rows that aren't reported
metadata[isTRUE(.observed) && report == 0][]
metadata[isFALSE(.observed) && report == 1][]

# Split by date and group, and get delay_ vars as a matrix
agg_indicators <- metadata |>
  _[,
    c(".group", "date", grep("^delay_", names(metadata), value = TRUE)),
    with = FALSE
  ] |>
  split(by = ".group", drop = TRUE) |>
  purrr::map(\(group_data) {
    group_data |>
      split(by = "date", drop = TRUE) |>
      purrr::map(\(x) as.matrix(x[, -c(".group", "date")]))
  })

# Fit a simple nowcasting model with fixed growth rate and a
# log-normal reporting distribution.
# Add probability aggregation to "structural" argument to handle the fixed reporting cycle.
nowcast <- epinowcast(pobs,
  expectation = enw_expectation(~1, data = pobs),
  report = enw_report(structural = agg_indicators, data = pobs),
  fit = enw_fit_opts(
    init_method = "prior",
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500,
  ),
  obs = enw_obs(family = "negbin",
    observation_indicator = ".observed",
    data = pobs),
)
