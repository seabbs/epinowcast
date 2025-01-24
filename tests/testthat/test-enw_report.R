# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_report supports non-parametric models", {
  expect_snapshot({
    rep <- enw_report(~ 1 + day_of_week, data = pobs)
    rep$inits <- NULL
    rep
  })
  rep <- enw_report(
    ~ 1 + day_of_week,
    data = pobs
  )
  expect_named(rep$inits(rep$data, rep$priors)(), c("rep_beta", "rep_beta_sd"))
  expect_identical(
    enw_report(~0, data = pobs)$formula$non_parametric, "~1"
  )
  expect_identical(enw_report(~0, data = pobs)$data$model_rep, 0)
})
