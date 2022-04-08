/*==============================================================================
Quality Assertion
=================
Utility program for running assertion tests for harmonized variables and distribution 
of missing values. This program is invoked in `validate_arrest.ado`, 
`validate_adjudication.ado`, `validate_incarceration.ado`, `validate_parole.ado`, 
and `validate_probation.ado` to check for validity of month date variables.
==============================================================================*/
#delimit;
set trace on;
capt program drop qa_assert;

program define qa_assert, rclass;
    syntax varname [if] [in], [noverbose] [assert] 
                              [miss_rate_max(numlist min=1 max=1 >=0 <=1)] 
                              [invalid_rate_max(numlist min=1 max=1 >=0 <=1)] 
                              [ks_test_p_min(numlist min=1 max=1 >=0 <=1)];
    marksample touse, novarlist;
    foreach param in miss_rate_max invalid_rate_max {;
        if !strlen("``param''") {;
            local `param' = 0;
        };
    };
    if !strlen("`ks_test_p_min'") {;
        local ks_test_p_min = .1;
    };

	/* Start */
    di _n "Quality tests for variable -`varlist'-";

	/* Variable type */
    local var_type: type `varlist';
    di _col(4) "Variable type: `var_type'";
    if strlen("`assert'") {;
        di _col(4) "Assertion: variable type is int";
        assert "`var_type'" == "int";
    };

	/* Count records in `touse' */
    quietly count if `touse';
    local n = `r(N)';
    if `n' == 0 {;
        di "Sample size for quality tests must be strictly positive" as error;
        assert `n' > 0;
    };

	/* Missingness */
    quietly count if `touse' & missing(`varlist');
    local n_miss = `r(N)';
    di _col(4) "Missingness rate:" %9.3g (`n_miss' / `n');
    if strlen("`assert'") {l
        di _col(4) "Assertion: missingness rate <= `miss_rate_max'";
        assert `n_miss' / `n' <= `miss_rate_max';
    };

	/* Nonmissing but invalid */
    quietly count if `touse' & !missing(`varlist') & !inrange(`varlist', 1, 12);
    local n_invalid = `r(N)';
    di _col(4) "[Nonmissing but] invalid rate:" %9.3g (`n_invalid' / `n');
    if strlen("`assert'") {;
        di _col(4) "Assertion: [nonmissing but] invalid rate <= `invalid_rate_max'";
        assert `n_invalid' / `n' <= `invalid_rate_max';
    };

	/* Test of equality of distribution
    ignoring missing and invalid values
    for month, cdf is discrete uniform cdf over (1,12)
    tab `varlist' */
    qui ksmirnov `varlist' = (`varlist' - 1 + 1) / (12 - 1 + 1) if `touse' & !missing(`varlist') & inrange(`varlist', 1, 12);
    di _col(4) "KS p-value for null of distribution equality:" %9.3g (`r(p_1)');
    if strlen("`assert'") {;
        di _col(4) "Assertion: KS p-value for rejecting null of distribution equality >= `ks_test_p_min'";
        /* di "`r(p_1)'" */
        /* di "`ks_test_p_min'" */
        assert `r(p_1)' >= `ks_test_p_min';
    };

	/* report deviation table */
    tempname mat_freq mat_name mat_dev itemlen;
    tab `varlist', nofreq matcell(`mat_freq') matrow(`mat_name');
    /* mat list `mat_freq' */
    /* mat list `mat_name' */
    mat `mat_dev' = J(rowsof(`mat_freq'), 3, 0);
    mat `itemlen' = rowsof(`mat_freq');
    /* mat list `itemlen' */
    local rownames "";
    forval r = 1/`=`itemlen'[1, 1]' {;
        mat `mat_dev'[`r', 1] = `mat_name'[`r', 1]';
        mat `mat_dev'[`r', 2] = abs( `mat_freq'[`r', 1] / (`n' - `n_miss' - `n_invalid') - 1 / 12);
        mat `mat_dev'[`r', 3] = `mat_freq'[`r', 1] / (`n' - `n_miss' - `n_invalid') - 1 / 12;
    };
    /* mat list `mat_dev' */
    mata : st_matrix("`mat_dev'", sort(st_matrix("`mat_dev'"), -2));
    /* mat list `mat_dev' */
    /* tab `varlist', sort */

    /* list of values sorted by deviation from expected probability */
    di _col(4) "List of values sorted by deviation from expected probability";
    di _col(8) "Value" _col(18) "Deviation from expected probability";
    forval r = 1/`=`itemlen'[1, 1]' {;
        di _col(8) %5.0f (`=`mat_dev'[`r', 1]') _col(44) %9.4f (`=`mat_dev'[`r', 3]');
    };

end;
