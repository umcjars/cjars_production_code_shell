/*==============================================================================
Validation Tests for Clean Adjudication
=======================================
Utility program to validate values of harmonized variables for adjudication. The 
program first invokes `qa_assert.ado` to check for validity of all of the month 
date variables. Afterwards, it tabulates values of all of the date variables as 
well as assertion tests to (i) ensure correct data type for each variable and to 
(ii) check for standardized values of code variables.
==============================================================================*/
#delimit;
capture program drop validate_adjudication;
program define validate_adjudication, rclass;
	local dataset_id "`1'";
	if "${VALIDATE}"=="0" {;
		di "Skipping validation for `dataset_id'";
	};
	else {;
		count;
		local total `r(N)';
		/* NOTE: qa_assert.ado only works with month variables at the moment */
		count if missing(adj_disp_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert adj_disp_dt_mm;
		};
		count if missing(adj_sent_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert adj_sent_dt_mm;
		};
		count if missing(adj_off_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert adj_off_dt_mm;
		};
		count if missing(adj_file_dt_mm);
		local miss `r(N)';
		if `total'!=`miss' {;
			qa_assert adj_file_dt_mm;
		};
		

		tab adj_file_dt_dd;
		tab adj_file_dt_mm;
		tab adj_file_dt_yyyy;

		tab adj_disp_dt_dd;
		tab adj_disp_dt_mm;
		tab adj_disp_dt_yyyy;

		tab adj_sent_dt_dd;
		tab adj_sent_dt_mm;
		tab adj_sent_dt_yyyy;
		
		tab adj_off_dt_dd;
		tab adj_off_dt_mm;
		tab adj_off_dt_yyyy;
		/*Check to make sure that the adjudication dates follow a sequence that makes sense*/
		/*Check 1: Do disposition dates happen after filing dates? The average value
		should be greater than 0. There should be very few observations with values<0*/
		gen check1 = mdy(adj_disp_dt_mm, adj_disp_dt_dd, adj_disp_dt_yyyy)
			- mdy(adj_file_dt_mm, adj_file_dt_dd, adj_file_dt_yyyy);
		su check1, d;

		/*Check 2: Do sentence dates happen after disposition dates? The average value
		should be greater than 0. There should be very few observations with values<0*/
		gen check2 = mdy(adj_sent_dt_mm, adj_sent_dt_dd, adj_sent_dt_yyyy) 
			- mdy(adj_disp_dt_mm, adj_disp_dt_dd, adj_disp_dt_yyyy);
		su check2, d;

		/*Are the incarceration and probation sentences expressed in months? Are there
		strange negative values or outliers ?*/
		su adj_sent_pro, d;
		su adj_sent_inc, d;

		/*Are the fines in dollars? Are there strange outliers or negative values?*/
		su adj_sent_fine, d;
	};
	
	/*Ensure variable are in their proper format*/
	confirm string variable cjars_id;
	confirm string variable adj_grd_cd;
	confirm string variable adj_grd_cd_src;
	confirm int variable adj_file_dt_yyyy;
	confirm byte variable adj_file_dt_mm;
	confirm byte variable adj_file_dt_dd;
	confirm string variable adj_chrg_off_cd;
	confirm string variable adj_chrg_off_cd_src;
	confirm int variable adj_disp_dt_yyyy;
	confirm byte variable adj_disp_dt_mm;
	confirm byte variable adj_disp_dt_dd;
	confirm string variable adj_disp_cd;
	confirm string variable adj_disp_cd_src;
	confirm string variable adj_disp_off_cd;
	confirm string variable adj_disp_off_cd_src;
	confirm int variable adj_off_dt_yyyy;
	confirm byte variable adj_off_dt_mm;
	confirm byte variable adj_off_dt_dd;
	confirm int variable adj_sent_dt_yyyy;
	confirm byte variable adj_sent_dt_mm;
	confirm byte variable adj_sent_dt_dd;
	confirm byte variable adj_sent_serv;
	confirm byte variable adj_sent_dth;
	confirm numeric variable adj_sent_inc;
	confirm numeric variable adj_sent_pro;
	confirm numeric variable adj_sent_rest;
	confirm byte variable adj_sent_sus;
	confirm byte variable adj_sent_trt;
	confirm numeric variable adj_sent_fine;
	confirm string variable adj_sent_src;
	confirm numeric variable adj_sent_inc_min;
	confirm numeric variable adj_sent_inc_max;
	confirm string variable adj_st_ori_fips;
	confirm string variable adj_cnty_ori_fips;
	confirm string variable adj_off_lgl_cd;
	confirm string variable adj_off_lgl_cd_src;
 
	/* Verifying that variables fall into acceptable values */
	local data="`1'";
	local last=strrpos("`data'", "/");
	local date=substr("`data'",`last',.);
	local st_date=date("`date'", "YMD");
	local year=year(`st_date');
	
	assert inlist(adj_grd_cd, "FE", "MI", "UU", "JF", "JM", "JU") == 1;
	assert length(adj_grd_cd_src) <= 30;
	assert inrange(adj_file_dt_yyyy, 0, `year') == 1 if adj_file_dt_yyyy != .;
	assert inrange(adj_file_dt_mm, 1, 12) == 1 if adj_file_dt_mm != .;
	assert inrange(adj_file_dt_dd, 1, 31) == 1 if adj_file_dt_dd != .;
	/* range test pending for adj_chrg_off_cd */
	assert length(adj_chrg_off_cd_src) <= 30;
	assert inrange(adj_disp_dt_yyyy, 0, `year') == 1 if adj_disp_dt_yyyy != .;
	assert inrange(adj_disp_dt_mm, 1, 12) == 1 if adj_disp_dt_mm != .;
	assert inrange(adj_disp_dt_dd, 1, 31) == 1 if adj_disp_dt_dd != .;
	assert inlist(adj_disp_cd, "DU", "GC", "GJ", "GP", "GI", "GU", "UU") == 1 | inlist(adj_disp_cd, "NA", "ND", "NI", "NM", "NP", "NU", "PT", "PU") == 1 ;
	assert length(adj_disp_cd_src) <= 30;
	/* range test pending for adj_disp_off_cd */
	assert length(adj_disp_off_cd_src) <= 30;
	assert inrange(adj_off_dt_yyyy, 0, `year') == 1 if adj_off_dt_yyyy != .;
	assert inrange(adj_off_dt_mm, 1, 12) == 1 if adj_off_dt_mm != .;
	assert inrange(adj_off_dt_dd, 1, 31) == 1 if adj_off_dt_dd != .;
	assert inrange(adj_sent_dt_yyyy, 0, `year') == 1 if adj_sent_dt_yyyy != .;
	assert inrange(adj_sent_dt_mm, 1, 12) == 1 if adj_sent_dt_mm != .;
	assert inrange(adj_sent_dt_dd, 1, 31) == 1 if adj_sent_dt_dd != .;
	assert inlist(adj_sent_serv, 0, 1) == 1 if adj_sent_serv != .;
	assert inlist(adj_sent_dth, 0, 1) == 1 if adj_sent_dth != .;
	assert inrange(adj_sent_inc, 0, 1200) == 1 | adj_sent_inc == -99999 | adj_sent_inc ==  -88888 if adj_sent_inc != .;
	assert inrange(adj_sent_pro, 0, 120) == 1 if adj_sent_pro != .;
	assert inrange(adj_sent_rest, 0, 500000) == 1 if adj_sent_rest != .;
	assert inlist(adj_sent_sus, 0, 1) == 1 if adj_sent_sus != .;
	assert inlist(adj_sent_trt, 0, 1) == 1 if adj_sent_trt != .;
	assert inrange(adj_sent_fine, -500000, 500000) == 1 if adj_sent_fine != .;
	assert length(adj_sent_src) <= 30 ;
	assert inrange(adj_sent_inc_min, 0, 1200) == 1 | adj_sent_inc_min == -99999 | adj_sent_inc_min ==  -88888 if adj_sent_inc_min != .;
	assert inrange(adj_sent_inc_max, 0, 1200) == 1 | adj_sent_inc_max == -99999 | adj_sent_inc_max ==  -88888 if adj_sent_inc_max != .;
	assert inlist(adj_st_ori_fips, "01", "02", "04", "05", "06", "08", "09", "10", "11") == 1 | inlist(adj_st_ori_fips, "12", "13", "15", "16", "17", "18", "19", "20", "21") == 1 | inlist(adj_st_ori_fips, "22", "23", "24", "25", "26", "27", "28", "29", "30") == 1 | inlist(adj_st_ori_fips, "31", "32", "33", "34", "35", "36", "37", "38", "39") == 1 |  inlist(adj_st_ori_fips, "40", "41", "42", "44", "45", "46", "47", "48", "49") == 1 | inlist(adj_st_ori_fips, "50", "51", "53", "54", "55") == 1 | inlist(adj_st_ori_fips, "56", "60", "66", "72", "78") == 1;
	/* range test pending for adj_cnty_ori_fips */
	assert inlist(adj_off_lgl_cd, "ST", "OR", "UU","MO","CO") == 1;
	assert length(adj_off_lgl_cd_src) <= 30;
	
	/* Format Binary/Byte Variables */
	recast byte adj_file_dt_mm adj_file_dt_dd adj_disp_dt_mm adj_disp_dt_dd adj_off_dt_mm adj_off_dt_dd adj_sent_dt_mm adj_sent_dt_dd adj_sent_serv adj_sent_dth adj_sent_trt;
	
	/* Format Integer Variables */
	recast int adj_file_dt_yyyy adj_disp_dt_yyyy adj_off_dt_yyyy adj_sent_dt_yyyy;
	
	/* Assessing rate of "UU" coding for variable */
	noisily: display "Assessing the degree of UU usage throughout the file:";
	foreach var of varlist *_cd{;
		qui gen uu_ind = `var' == "UU";
		qui summ uu_ind;
		local rate = round(r(mean),0.01)*100;
		noisily: display "`var' has an unknown/missing rate of `rate'%.";
		if `rate'> 10{;
			noisily: display " --> This rate is higher than 10% and warrants further investigation. <-- ";
		};
		qui drop uu_ind;
	};
	
	*stub_level_har_dqr `dataset_id';
	
end;
