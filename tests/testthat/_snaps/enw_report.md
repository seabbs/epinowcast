# enw_report supports non-parametric models

    Code
      rep <- enw_report(~ 1 + day_of_week, data = pobs)
      rep$inits <- NULL
      rep
    Output
      $formula
      $formula$non_parametric
      [1] "~1 + day_of_week"
      
      
      $data
      $data$rep_fintercept
      [1] 1
      
      $data$rep_fnrow
      [1] 7
      
      $data$rep_findex
           [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13] [,14]
      [1,]    1    2    3    4    5    6    7    1    2     3     4     5     6     7
           [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25] [,26]
      [1,]     1     2     3     4     5     6     7     1     2     3     4     5
           [,27] [,28] [,29] [,30] [,31] [,32] [,33] [,34] [,35] [,36] [,37] [,38]
      [1,]     6     7     1     2     3     4     5     6     7     1     2     3
           [,39] [,40] [,41] [,42] [,43] [,44] [,45] [,46] [,47] [,48] [,49] [,50]
      [1,]     4     5     6     7     1     2     3     4     5     6     7     1
           [,51] [,52] [,53] [,54] [,55] [,56] [,57] [,58] [,59] [,60]
      [1,]     2     3     4     5     6     7     1     2     3     4
      
      $data$rep_fnindex
      [1] 60
      
      $data$rep_fncol
      [1] 6
      
      $data$rep_rncol
      [1] 0
      
      $data$rep_fdesign
        day_of_weekMonday day_of_weekSaturday day_of_weekSunday day_of_weekThursday
      1                 0                   0                 0                   0
      2                 0                   0                 0                   0
      3                 0                   0                 0                   1
      4                 0                   0                 0                   0
      5                 0                   1                 0                   0
      6                 0                   0                 1                   0
      7                 1                   0                 0                   0
        day_of_weekTuesday day_of_weekWednesday
      1                  1                    0
      2                  0                    1
      3                  0                    0
      4                  0                    0
      5                  0                    0
      6                  0                    0
      7                  0                    0
      
      $data$rep_rdesign
        (Intercept)
      1           1
      2           1
      3           1
      4           1
      5           1
      6           1
      attr(,"assign")
      [1] 0
      
      $data$rep_agg_p
      [1] 0
      
      $data$rep_agg_indicators
      list()
      
      $data$rep_t
      [1] 60
      
      $data$model_rep
      [1] 1
      
      
      $priors
            variable                                             description
      1: rep_beta_sd Standard deviation of scaled pooled report date effects
                  distribution mean sd
      1: Zero truncated normal    0  1
      

