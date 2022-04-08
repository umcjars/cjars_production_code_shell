/*==============================================================================
Validation Tests for Clean Probation
====================================
Utility program to validate values of harmonized variables for probation. The 
program first invokes `qa_assert.ado` to check for validity of all of the month 
date variables. Afterwards, it tabulates values of all of the date variables as 
well as assertion tests to (i) ensure correct data type for each variable and to 
(ii) check for standardized values of code variables.
==============================================================================*/
#delimit;
capture program drop validate_probation;
program define validate_probation, rclass;
	local dataset_id "`1'";
	if "${VALIDATE}"=="0" {;
		di "Skipping validation for `dataset_id'";
	};
	else {;
		count;
		local total `r(N)';
		/* NOTE: qa_assert.ado only works with month variables at the moment */
		count if missing(pro_bgn_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert pro_bgn_dt_mm;
		};
		count if missing(pro_end_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert pro_end_dt_mm;
		};
		/*look at distribution of dates to make sure that they follow a uniform distribution.
		This can also be accomplished by looking at a histogram. Note that there should 
		be slightly less density for shorter months (i.e. February) and days that only
		appear in longer months (i.e. 31st). This exercise will help you catch dates that
		are formated irregularly in the raw data. Do the years make sense given the 
		coverage of the data?*/
		tab pro_bgn_dt_dd;
		tab pro_bgn_dt_mm;
		tab pro_bgn_dt_yyyy;

		tab pro_end_dt_dd;
		tab pro_end_dt_mm;
		tab pro_end_dt_yyyy;
		
		/*Check to make sure that the incarceration durations are positive. In other words,
		make sure that incarceration end date comes after incarceration begin date.
		Duration gives the incarceration duration in days. The average incarceration time
		should be a positive value. You should make sure that there are not many
		observations with negative values*/
		gen duration = mdy(pro_end_dt_mm, pro_end_dt_dd, pro_end_dt_yyyy) 
			- mdy(pro_bgn_dt_mm, pro_bgn_dt_dd, pro_bgn_dt_yyyy);
		su duration, d;
	};

	/*Ensure variable are in their proper format*/
	confirm string variable cjars_id;
	confirm string variable pro_cond_cd;
	confirm string variable pro_cond_cd_src;
	confirm int variable pro_bgn_dt_yyyy;
	confirm byte variable pro_bgn_dt_mm;
	confirm byte variable pro_bgn_dt_dd;
	confirm int variable pro_end_dt_yyyy;
	confirm byte variable pro_end_dt_mm;
	confirm byte variable pro_end_dt_dd;
	confirm string variable pro_end_cd;
	confirm string variable pro_end_cd_src;
	confirm string variable pro_st_ori_fips;
	confirm string variable pro_cnty_ori_fips;
	confirm string variable pro_st_juris_fips;
 
	/* Verifying that variables fall into acceptable values */
	local data="`1'";
	local last=strrpos("`data'", "/");
	local date=substr("`data'",`last',.);
	local st_date=date("`date'", "YMD");
	local year=year(`st_date');
	
	assert inlist(pro_cond_cd, "PJ", "SP", "AD", "PR", "UU") == 1;
	assert length(pro_cond_cd_src) <= 30; 	
	assert inrange(pro_bgn_dt_yyyy, 0, `year') == 1 if pro_bgn_dt_yyyy != .;
	assert inrange(pro_bgn_dt_mm, 1, 12) == 1 if pro_bgn_dt_mm != .;
	assert inrange(pro_bgn_dt_dd, 1, 31) == 1 if pro_bgn_dt_dd != .;	
	assert inrange(pro_end_dt_yyyy, 0, `year') == 1 if pro_end_dt_yyyy != .;
	assert inrange(pro_end_dt_mm, 1, 12) == 1 if pro_end_dt_mm != .;
	assert inrange(pro_end_dt_dd, 1, 31) == 1 if pro_end_dt_dd != .;	    	
	assert inlist(pro_end_cd, "CO", "IN", "AB", "DI", "OU", "TR", "DE", "OT", "UU") == 1 ;
	assert length(pro_end_cd_src) <= 30; 	
	assert inlist(pro_st_ori_fips, "01", "02", "04", "05", "06", "08", "09", "10", "11") == 1 | inlist(pro_st_ori_fips, "12", "13", "15", "16", "17", "18", "19", "20", "21") == 1 | inlist(pro_st_ori_fips, "22", "23", "24", "25", "26", "27", "28", "29", "30") == 1 | inlist(pro_st_ori_fips, "31", "32", "33", "34", "35", "36", "37", "38", "39") == 1 |  inlist(pro_st_ori_fips, "40", "41", "42", "44", "45", "46", "47", "48", "49") == 1 | inlist(pro_st_ori_fips, "50", "51", "53", "54", "55") == 1 | inlist(pro_st_ori_fips, "56", "60", "66", "72", "78", "") == 1;
	/* range test pending for pro_cnty_ori_fips */
	assert inlist(pro_st_juris_fips, "01", "02", "04", "05", "06", "08", "09", "10", "11") == 1 | inlist(pro_st_juris_fips, "12", "13", "15", "16", "17", "18", "19", "20", "21") == 1 | inlist(pro_st_juris_fips, "22", "23", "24", "25", "26", "27", "28", "29", "30") == 1 | inlist(pro_st_juris_fips, "31", "32", "33", "34", "35", "36", "37", "38", "39") == 1 |  inlist(pro_st_juris_fips, "40", "41", "42", "44", "45", "46", "47", "48", "49") == 1 | inlist(pro_st_juris_fips, "50", "51", "53", "54", "55") == 1 | inlist(pro_st_juris_fips, "56", "60", "66", "72", "78") == 1;   
	
	/* Format Binary/Byte Variables */
	recast byte pro_bgn_dt_mm pro_bgn_dt_dd pro_end_dt_mm pro_end_dt_dd;
	
	/* Format Integer Variables */
	recast int pro_bgn_dt_yyyy pro_end_dt_yyyy;
	
	/* Assessing rate of "UU" coding for variable */
	display "Assessing the degree of UU usage throughout the file:";
	foreach var of varlist *_cd{;
		qui gen uu_ind = `var' == "UU";
		qui summ uu_ind;
		local rate = round(r(mean),0.01)*100;
		display "`var' has an unknown/missing rate of `rate'%.";
		if `rate'> 10{;
			display " --> This rate is higher than 10% and warrants further investigation. <-- ";
		};
		qui drop uu_ind;
	};

    *stub_level_har_dqr `dataset_id';
	
end;
