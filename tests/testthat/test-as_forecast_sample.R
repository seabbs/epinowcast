test_that("Can score nowcasts", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")
  nowcast <- enw_example("nowcast")
  summarised_nowcast <- summary(nowcast)
  obs <- enw_example("observations")

  expect_data_table(
    suppressPackageStartupMessages(suppressWarnings(suppressMessages(
      enw_score_nowcast(summarised_nowcast, obs)
    )))
  )
  expect_data_table(
    suppressWarnings(suppressMessages(
      enw_score_nowcast(
        summarised_nowcast, obs,
        log = TRUE
      )
    ))
  )
  expect_data_table(
    suppressWarnings(suppressMessages(enw_score_nowcast(
      summarised_nowcast, obs,
      check = TRUE
    )))
  )
})

test_that("Can convert epinowcast object to forecast_sample", {
  skip_on_cran()
  skip_if_not_installed("scoringutils")
  library(scoringutils)

  nowcast <- enw_example("nowcast")
  obs <- enw_example("observations")

  # Test basic conversion
  test <- expect_s3_class(
    suppressPackageStartupMessages(
      as_forecast_sample(nowcast, obs)
    ),
    "forecast_sample"
  )

  # Test with grouping variables
  obs$group <- "test"
  forecast_data <- suppressPackageStartupMessages(
    as_forecast_sample(nowcast, obs)
  )
  expect_true("group" %in% names(forecast_data))
  expect_true(all(forecast_data$group == "test"))

  expect_true(all(
    c("observed", "predicted", "sample_id") %in% names(forecast_data)
  ))

  unloadNamespace("scoringutils")
})
