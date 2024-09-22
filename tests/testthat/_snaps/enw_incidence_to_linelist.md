# enw_incidence_to_linelist can return a linelist

    Code
      enw_incidence_to_linelist(incidence, reference_date = "onset_date",
        report_date = "test_date")
    Output
                id onset_date location age_group  test_date delay
          1:     1 2021-10-11       DE       00+ 2021-10-11     0
          2:     2 2021-10-11       DE       00+ 2021-10-11     0
          3:     3 2021-10-11       DE       00+ 2021-10-11     0
          4:     4 2021-10-11       DE       00+ 2021-10-11     0
          5:     5 2021-10-11       DE       00+ 2021-10-11     0
         ---                                                     
      16227: 16227 2021-10-20       DE       80+ 2021-10-20     6
      16228: 16228 2021-10-20       DE       80+ 2021-10-20     6
      16229: 16229 2021-10-20       DE       80+ 2021-10-20     6
      16230: 16230 2021-10-20       DE       80+ 2021-10-20     6
      16231: 16231 2021-10-20       DE       80+ 2021-10-20     6

---

    Code
      enw_incidence_to_linelist(incidence)
    Output
                id reference_date location age_group report_date delay
          1:     1     2021-10-11       DE       00+  2021-10-11     0
          2:     2     2021-10-11       DE       00+  2021-10-11     0
          3:     3     2021-10-11       DE       00+  2021-10-11     0
          4:     4     2021-10-11       DE       00+  2021-10-11     0
          5:     5     2021-10-11       DE       00+  2021-10-11     0
         ---                                                          
      16227: 16227     2021-10-20       DE       80+  2021-10-20     6
      16228: 16228     2021-10-20       DE       80+  2021-10-20     6
      16229: 16229     2021-10-20       DE       80+  2021-10-20     6
      16230: 16230     2021-10-20       DE       80+  2021-10-20     6
      16231: 16231     2021-10-20       DE       80+  2021-10-20     6

