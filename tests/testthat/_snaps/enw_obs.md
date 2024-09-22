# enw_obs() produces the expected output

    Code
      obs <- enw_obs(family = "negbin", data = pobs)
      obs$inits <- NULL
      obs
    Output
      $family
      [1] "negbin"
      
      $data
      $data$n
      [1] 40
      
      $data$t
      [1] 10
      
      $data$s
      [1] 10
      
      $data$g
      [1] 1
      
      $data$groups
      [1] 1
      
      $data$st
       [1]  1  2  3  4  5  6  7  8  9 10
      
      $data$ts
             1
       [1,]  1
       [2,]  2
       [3,]  3
       [4,]  4
       [5,]  5
       [6,]  6
       [7,]  7
       [8,]  8
       [9,]  9
      [10,] 10
      
      $data$sl
       [1] 5 5 5 5 5 5 4 3 2 1
      
      $data$csl
       [1]  5 10 15 20 25 30 34 37 39 40
      
      $data$lsl
       [1] 5 5 5 5 5 5 4 3 2 1
      
      $data$clsl
       [1]  5 10 15 20 25 30 34 37 39 40
      
      $data$nsl
       [1] 5 5 5 5 5 5 4 3 2 1
      
      $data$cnsl
       [1]  5 10 15 20 25 30 34 37 39 40
      
      $data$sg
       [1] 1 1 1 1 1 1 1 1 1 1
      
      $data$dmax
      [1] 5
      
      $data$sdmax
       [1] 5 5 5 5 5 5 5 5 5 5
      
      $data$csdmax
       [1]  5 10 15 20 25 30 35 40 45 50
      
      $data$obs
             0  1  2  3  4
       [1,] 86 44  9  3 27
       [2,] 79 36  7 16 19
       [3,] 22 24 35 18 10
       [4,] 23 32 22 10  8
       [5,] 96 85 30 18 10
       [6,] 92 86 23 18  4
       [7,] 84 87 27  4  0
       [8,] 98 61 12  0  0
       [9,] 69 43  0  0  0
      [10,] 45  0  0  0  0
      
      $data$flat_obs
       [1] 86 44  9  3 27 79 36  7 16 19 22 24 35 18 10 23 32 22 10  8 96 85 30 18 10
      [26] 92 86 23 18  4 84 87 27  4 98 61 12 69 43 45
      
      $data$flat_obs_lookup
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
      
      $data$latest_obs
              1
       [1,] 169
       [2,] 157
       [3,] 109
       [4,]  95
       [5,] 239
       [6,] 223
       [7,] 202
       [8,] 171
       [9,] 112
      [10,]  45
      
      $data$model_obs
      [1] 1
      
      
      $priors
         variable                                              description
      1: sqrt_phi One over the square root of the reporting overdispersion
                  distribution mean  sd
      1: Zero truncated normal    0 0.5
      

---

    Code
      obs_missing <- enw_obs(family = "negbin", data = pobs_missing,
        observation_indicator = ".observed")
      obs_missing$inits <- NULL
      obs_missing
    Output
      $family
      [1] "negbin"
      
      $data
      $data$n
      [1] 39
      
      $data$t
      [1] 10
      
      $data$s
      [1] 10
      
      $data$g
      [1] 1
      
      $data$groups
      [1] 1
      
      $data$st
       [1]  1  2  3  4  5  6  7  8  9 10
      
      $data$ts
             1
       [1,]  1
       [2,]  2
       [3,]  3
       [4,]  4
       [5,]  5
       [6,]  6
       [7,]  7
       [8,]  8
       [9,]  9
      [10,] 10
      
      $data$sl
       [1] 5 5 5 5 5 5 4 3 2 1
      
      $data$csl
       [1]  5 10 15 20 25 30 34 37 39 40
      
      $data$lsl
       [1] 5 5 5 5 5 5 4 3 2 1
      
      $data$clsl
       [1]  5 10 15 20 25 30 34 37 39 40
      
      $data$nsl
       [1] 4 5 5 5 5 5 4 3 2 1
      
      $data$cnsl
       [1]  4  9 14 19 24 29 33 36 38 39
      
      $data$sg
       [1] 1 1 1 1 1 1 1 1 1 1
      
      $data$dmax
      [1] 5
      
      $data$sdmax
       [1] 5 5 5 5 5 5 5 5 5 5
      
      $data$csdmax
       [1]  5 10 15 20 25 30 35 40 45 50
      
      $data$obs
             0   1  2  3  4
       [1,]  0 130  9  3 27
       [2,] 79  36  7 16 19
       [3,] 22  24 35 18 10
       [4,] 23  32 22 10  8
       [5,] 96  85 30 18 10
       [6,] 92  86 23 18  4
       [7,] 84  87 27  4  0
       [8,] 98  61 12  0  0
       [9,] 69  43  0  0  0
      [10,] 45   0  0  0  0
      
      $data$flat_obs
       [1] 130   9   3  27  79  36   7  16  19  22  24  35  18  10  23  32  22  10   8
      [20]  96  85  30  18  10  92  86  23  18   4  84  87  27   4  98  61  12  69  43
      [39]  45
      
      $data$flat_obs_lookup
       [1]  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26
      [26] 27 28 29 30 31 32 33 34 35 36 37 38 39 40
      
      $data$latest_obs
              1
       [1,] 169
       [2,] 157
       [3,] 109
       [4,]  95
       [5,] 239
       [6,] 223
       [7,] 202
       [8,] 171
       [9,] 112
      [10,]  45
      
      $data$model_obs
      [1] 1
      
      
      $priors
         variable                                              description
      1: sqrt_phi One over the square root of the reporting overdispersion
                  distribution mean  sd
      1: Zero truncated normal    0 0.5
      

