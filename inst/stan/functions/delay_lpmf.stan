/**
 * Log probability mass function for delayed snapshot data
 * 
 * Computes the log probability mass for a range of time indexes in delayed
 * snapshot data. It applies filters to identify relevant observations and
 * calculates the expected log observations based on various inputs.
 *
 * @copydoc common_parameters_delay_lpmf_funcs
 *
 * @param dummy Dummy array parameter, not used in the calculation.
 *
 * @return Log probability mass of the observations for the specified range.
 * 
 * @note This function performs the following operations:
 *  1. Determines the relevant range of observed data and lookup indexes.
 *  2. Filters the observed data and lookup indexes for the specified range.
 *  3. Computes expected log observations using `expected_obs_from_snaps`.
 *  4. Applies the observation error model using `obs_lpmf`.
 *
* Dependencies:
 * - `filt_obs_indexes`
 * - `expected_obs_from_snaps`
 * - `obs_lpmf`
 *
 * This function is similar to `delay_group_lpmf` but operates on snapshot
 * data rather than group data.
 */
real delay_snap_lpmf(array[] int dummy, int start, int end, array[] int obs,
                     array[] int sl, array[] int csl,
                     array[] int nsl, array[] int cnsl, array[] int obs_lookup,
                     array[] vector imp_obs, array[] int sg,
                     array[] int st, array[,] int rdlurd,
                     vector srdlh, matrix refp_lh, array[] int dpmfs,
                     int ref_p, int rep_h, int ref_as_p, array[] real phi,
                     int model_obs, vector refnp_lh, int ref_np,
                     array[] int sdmax, array[] int csdmax,
                     int rep_agg_p, array[,] matrix rep_agg_indicators) {
  real tar = 0;
  // Where am I in the observed data?
  array[3] int nc = filt_obs_indexes(start, end, cnsl, nsl);
  // Where am I in the observed data filling in gaps?
  array[3] int n = filt_obs_indexes(start, end, csl, sl);
  if (nc[3]) {
    // Filter observed data and observed data lookup
    array[nc[3]] int filt_obs = segment(obs, nc[1], nc[3]);
    array[nc[3]] int filt_obs_lookup = segment(obs_lookup, nc[1], nc[3]);
    array[nc[3]] int filt_obs_lookup_local;
    for (i in 1:nc[3]) {
      filt_obs_lookup_local[i] = filt_obs_lookup[i] - n[1] + 1;
    }
  
    // What is going to be used for storage
    vector[n[3]] log_exp_obs;

    // combine expected final obs and time effects to get expected obs
    log_exp_obs = expected_obs_from_snaps(
      start, end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sl, csl, sg, st, n[3], refnp_lh, ref_np, sdmax, csdmax, rep_agg_p, rep_agg_indicators
    );

    // observation error model (across all reference dates and groups)
    profile("model_likelihood_neg_binomial") {
    tar = obs_lpmf(
      filt_obs | log_exp_obs[filt_obs_lookup_local], phi, model_obs
    );
    }
  }
  return(tar);
}

/**
 * Log probability mass function for delayed group data
 * 
 * Computes the log probability mass for a range of time indexes in delayed
 * group data. It manages data filtering, allocation for expected log 
 * observations, and handles missing data if applicable.
 *
 * @copydoc common_parameters_delay_lpmf_funcs
 *
 * @param groups Array of group identifiers.
 *
 * @param t Integer representing the current time index.
 *
 * @param groups Array of group identifiers.
 *
 * @param ts Array of snapshot indices by time and group.
 *
 * @param model_miss Binary flag indicating if missing observations should be modeled (0 = no, 1 = yes).
 *
 * @param miss_obs Number of observations with missing reference dates.
 *
 * @param missing_reference Array of observations reported without a reference date (by reporting time).
 *
 * @param obs_by_report Array of observation indices by reference date for entries in missing_reference.
 *
 * @param miss_ref_lprop Vector of log probabilities for missing reference dates.
 *
 * @param miss_st Array of start indices for observations by group in missing_reference.
 *
 * @param miss_cst Array of cumulative start indices for observations by group in missing_reference.
 *
 * @return Log probability mass of the observations for the specified range.
 *
 * @note This function performs the following operations:
 *  1. Determines the relevant range for observed and missing data.
 *  2. Filters and allocates expected log observations, handling missing data.
 *  3. Computes expected log observations using `expected_obs_from_snaps`.
 *  4. Applies the observation error model using `obs_lpmf`.
 *  5. Additionally, handles missing data using
 *    `apply_missing_reference_effects` and `log_expected_by_report`
 *     if `model_miss` is 1.
 * 
 * Dependencies:
 * - `filt_obs_indexes`
 * - `expected_obs_from_snaps`
 * - `obs_lpmf`
 * - `allocate_observed_obs`
 * - `apply_missing_reference_effects`
 * - `log_expected_by_report`.
 *
 * This function is similar to `delay_snap_lpmf` but is specifically designed 
 * for group data and includes additional steps for missing data.
 */
real delay_group_lpmf(array[] int groups, int start, int end, array[] int obs,
                      array[] int sl, array[] int csl, array[] int nsl,
                      array[] int cnsl, array[] int obs_lookup,
                      array[] vector imp_obs, int t, array[] int sg,
                      array[,] int ts, array[] int st,
                      array[,] int rdlurd, vector srdlh, matrix refp_lh,
                      array[] int dpmfs, int ref_p, int rep_h, int ref_as_p,
                      array[] real phi, int model_obs, int model_miss,
                      int miss_obs, array[] int missing_reference,
                      array[,] int obs_by_report, vector miss_ref_lprop,
                      array[] int sdmax, array[] int csdmax,
                      array[] int miss_st, array[] int miss_cst,
                      vector refnp_lh, int ref_np,
                      int rep_agg_p, array[,] matrix rep_agg_indicators) {
  // Where am I?
  real tar = 0;
  int i_start = ts[1, start];
  int i_end = ts[t, end];
  // Where am I in the observed data?
  array[3] int nc = filt_obs_indexes(i_start, i_end, cnsl, nsl);
  // Where am I in the observed data filling in gaps?
  array[3] int n = filt_obs_indexes(i_start, i_end, csl, sl);

  // What is going to be used for storage
  vector[n[3]] log_exp_obs;
  vector[model_miss ? miss_obs : 0]  log_exp_obs_miss;

  // Combine expected final obs and time effects to get expected obs
  // If missing reference module in place calculate all expected obs vs 
  // just those observed and allocate if missing or not.
  if (model_miss) {
    array[3] int f = filt_obs_indexes(i_start, i_end, csdmax, sdmax);
    array[3] int l = filt_obs_indexes(start, end, miss_cst, miss_st);
    vector[f[3]] log_exp_all;

    // Calculate all expected observations
    log_exp_all = expected_obs_from_snaps(
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sdmax, csdmax, sg, st, f[3], refnp_lh, ref_np, sdmax, csdmax, rep_agg_p, rep_agg_indicators
    );

    // Allocate to just those actually observed
    log_exp_obs = allocate_observed_obs(
      i_start, i_end, log_exp_all, sl, csl, sdmax, csdmax
    );
    log_exp_obs = apply_missing_reference_effects(
      i_start, i_end, log_exp_obs, sl, csl, log1m_exp(miss_ref_lprop)
    );

    // Allocate expected cases by reporting time
    if (miss_obs) {
      log_exp_all = apply_missing_reference_effects(
        i_start, i_end, log_exp_all, sdmax, csdmax, miss_ref_lprop
      );
      log_exp_obs_miss = log_expected_by_report(
        log_exp_all, obs_by_report[l[1]:l[2]]
      );
    }
  }else{
    log_exp_obs = expected_obs_from_snaps(
      i_start, i_end, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, sl, csl, sg, st, n[3], refnp_lh, ref_np, sdmax, csdmax, rep_agg_p, rep_agg_indicators
    );
  }
  // Observation error model (across all reference dates and groups)
  profile("model_likelihood_neg_binomial") {
  if (nc[3]) {
    // Filter observed data and observed data lookup
    array[nc[3]] int filt_obs = segment(obs, nc[1], nc[3]);
    array[nc[3]] int filt_obs_lookup = segment(obs_lookup, nc[1], nc[3]);
    array[nc[3]] int filt_obs_lookup_local;
    for (i in 1:nc[3]) {
      filt_obs_lookup_local[i] = filt_obs_lookup[i] - n[1] + 1;
    }
    print("Observed");
    print(filt_obs);
    print("Expected");
    print(log_exp_obs);
    print("Expected observed");
    print(log_exp_obs[filt_obs_lookup_local]);

    tar = obs_lpmf(
      filt_obs | log_exp_obs[filt_obs_lookup_local], phi, model_obs
    );
  }
  if (model_miss && miss_obs) {
    array[3] int l = filt_obs_indexes(start, end, miss_cst, miss_st);
    array[l[3]] int filt_miss_ref = segment(missing_reference, l[1], l[3]);
    tar += obs_lpmf(filt_miss_ref | log_exp_obs_miss, phi, model_obs);
  }
  }
  return(tar);
}
