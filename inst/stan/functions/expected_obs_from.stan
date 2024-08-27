/**
 * Calculate expected observations for a given index
 * 
 * Computes the expected observations for a specific time index by combining
 * final observed/imputed expected observation with time effects. This function
 * integrates various hazard effects and reference adjustments to produce the 
 * expected observations.
 * 
 * @param i Index for accessing elements in various arrays.
 *
 * @param imp_obs Array of imputed observed data, organized by group and time.
 *
 * @param rdlurd Array indicating reporting dates lookup reference data.
 *
 * @param srdlh Vector of standardized reporting date log hazards.
 *
 * @param refp_lh Matrix of reference date logit hazards.
 *
 * @param dpmfs Array of indices for accessing reference date effects in 
 * `refp_lh`.
 *
 * @param ref_p, rep_h, ref_as_p Flags indicating presence of reference date,
 * reporting hazards, and reference-as-probability.

 * @param g, t, l, p Group, time, length, and position parameters for data 
 * access and processing.
 *
 * @param refnp_lh Vector of non-parametric reference log hazards.
 *
 * @param ref_np Flag indicating presence of non-parametric reference effects.
 * 
 * @return A vector of expected observations for the given index.
 * 
 * @note This function performs several steps:
 *       1. Retrieves the final observed/imputed expected observation for the 
 *          given group and time.
 *       2. Aggregates various hazard effects using `combine_logit_hazards`.
 *       3. Combines the final expected observation with the time-varying
 *          effects  to compute the expected observations using `expected_obs`.
 *
 * Dependencies:
 *  - `combine_logit_hazards`
 *  - `expected_obs`
 *
 */
vector expected_obs_from_index(int i, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix refp_lh, array[] int dpmfs, int ref_p,
                               int rep_h, int ref_as_p, int g, int t, int l,
                               vector refnp_lh, int ref_np, int p) {
  vector[l] lh;
  vector[l] log_exp_obs;
  if (imp_obs[g][t] == negative_infinity() || imp_obs[g][t] == positive_infinity()) {
    reject("imp_obs for group ", g, " and time ", t, " is -Inf or Inf");
  }
  if (is_nan(imp_obs[g][t])) {
    reject("imp_obs for group ", g, " and time ", t, " is NaN");
  }
  profile("model_likelihood_hazard_allocations") {
    lh = combine_logit_hazards(
      i, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, g, t, l, refnp_lh, ref_np,
      p
    );
  }
  // Find final observed/imputed expected observation
  // combine expected final obs and time effects to get expected obs
  profile("model_likelihood_expected_obs") {    
  int agg_probs = 0;
  matrix[1, 1] agg_indicator;
  agg_indicator[1, 1] = 0;
  log_exp_obs = expected_obs(imp_obs[g][t], lh, l, ref_as_p, agg_probs, agg_indicator);
  }
  return(log_exp_obs);
}

/**
 * Calculate expected observations for a set of indexes
 * 
 * Computes expected observations for a range of time indexes, effectively 
 * aggregating individual calculations over a specified range. This function
 * considers various factors like hazard effects, reference adjustments, and 
 * grouping to produce expected observations for each index within the range.
 * 
 * @param start, end Start and end indexes for the allocation range.
 *
 * @param imp_obs Array of imputed observed data, organized by group and time.
 *
 * @param rdlurd Array indicating reporting dates lookup reference data.
 *
 * @param srdlh Vector of standardized reporting date log hazards.
 *
 * @param refp_lh Matrix of reference date logit hazards.
 *
 * @param dpmfs, sl, csl, sg, st Arrays for accessing various indices and 
 * supporting data.
 *
 * @param ref_p, rep_h, ref_as_p Flags for presence of different hazard effects.
 *
 * @param n Number of discrete points for observations.
 *
 * @param refnp_lh Vector of non-parametric reference log hazards.
 *
 * @param ref_np Flag for non-parametric reference effects.
 *
 * @param sdmax, csdmax Arrays of maximum start dates and cumulative start
*  dates.
 * 
 * @return A vector of expected observations across the specified range of 
 *         indexes.
 * 
 * @note This function executes the following steps:
 *       1. Iteratively processes each index in the specified range.
 *       2. For each index, it identifies the relevant group, time, and length 
 *          parameters necessary for the calculation.
 *       3. Calls `expected_obs_from_index` for each index to compute the 
 *          expected observations.
 *       4. Aggregates these individual expected observations into a single 
 *          vector corresponding to the entire range.
 * 
 * Dependencies:
 *  - `expected_obs_from_index`
 */
vector expected_obs_from_snaps(int start, int end, array[] vector imp_obs,
                               array[,] int rdlurd, vector srdlh,
                               matrix refp_lh, array[] int dpmfs,
                               int ref_p, int rep_h, int ref_as_p,
                               array[] int sl, array[] int csl,
                               array[] int sg, array[] int st, int n,
                               vector refnp_lh, int ref_np, array[] int sdmax,
                               array[] int csdmax) {
  vector[n] log_exp_obs;
  int ssnap = 1;
  int esnap = 0;
  int g; 
  int t;
  int l;
  int p;

  for (i in start:end) {
    profile("allocations") {
    g = sg[i];
    t = st[i];
    l = sl[i];
    p = csdmax[i] - sdmax[i] + 1;
    }
    // combine expected final obs and time effects to get expected obs
    profile("expected_obs_from_index") {
    if (l) {
      esnap += l;
      log_exp_obs[ssnap:esnap] = expected_obs_from_index(
        i, imp_obs, rdlurd, srdlh, refp_lh, dpmfs, ref_p, rep_h, ref_as_p, g, t,
        l, refnp_lh, ref_np, p
      );
      ssnap += l;
    }
    }
  }
  return(log_exp_obs);
}
