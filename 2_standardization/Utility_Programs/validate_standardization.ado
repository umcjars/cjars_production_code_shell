/******************************************************************************
	Program name:  validate_standardization 
	Function	: Perform various individual data stub level checks
	Arguments	: none
			
******************************************************************************/

#delimit;

program define validate_standardization;

	/* Checking whether each variable contains appropriate data types */
	
		/* String Variables */
	confirm string variable record_id;
	confirm string variable name_last;
	confirm string variable name_first;
	confirm string variable name_middle;
	confirm string variable name_first_clean;
	confirm string variable name_middle_clean;
	confirm string variable name_suffix;
	confirm string variable name_middle_initial;
	confirm string variable birth_loc_city;
	confirm string variable birth_loc_ctry;
	confirm string variable birth_loc_st;
	confirm string variable state_id;
	confirm string variable state_id_ori;
	confirm string variable county_id;
	confirm string variable state_id_ori;
	confirm string variable agency_id;
	confirm string variable state_id_ori;
	confirm string variable ssn;
	confirm string variable ssn_4;
	confirm string variable fbi_num;
	confirm string variable addr_raw;
	confirm string variable addr_bldnum;
	confirm string variable addr_str;
	confirm string variable addr_city;
	confirm string variable addr_zip;
	confirm string variable addr_st;
	confirm string variable addr_ctry;

		/* Numerical Variables */
	confirm byte variable alias;
	confirm int variable dob_dd;
	confirm int variable dob_mm;
	confirm int variable dob_yyyy;
	confirm byte variable birth_loc_foreign;
	confirm byte variable sex;
	confirm byte variable race;
	
	local data "`1'";
	display "`data'";
	local last=strrpos("`data'", "/")+1;
	local year=substr("`data'",`last',4);

	/* Checking DOB Formatting and whether it looks normal / appropriate */
	tempvar juvenile;
	gen `juvenile' = inrange(dob_yyyy,`year'-17,`year') == 1 if dob_yyyy != . & !missing(dob_yyyy); /* Just set 10 as an arbitrary age for the youngest criminal */
	sum `juvenile';
	local rate = r(mean);
	display "Rate of offenders below age 17 at date of data acquisition: `rate'";
	tempvar missing_dob;
	gen `missing_dob' = dob_yyyy == . | dob_mm == . | dob_dd == .;
	sum `missing_dob';
	local rate = r(mean);
	display "Rate of observations with missing date of birth information: `rate'";
	assert inrange(dob_mm, 1, 12) == 1 if dob_mm != .;
	assert inrange(dob_dd, 1, 31) == 1 if dob_dd != .;
	
	drop _*;
	
	/* Checking whether values in SEX and RACE are appropriate */
	assert inlist(sex_raw, 1, 2) == 1 if sex_raw != . & !missing(sex_raw);
	assert inlist(race_raw, 1, 2, 3, 4, 5, 6) == 1 if race_raw != . & !missing(race_raw);

	/* Checking for really long string values that take up a lot of disk space */
	foreach var in name_last name_first name_middle name_first_clean name_middle_clean name_suffix name_middle_initial birth_loc_city birth_loc_ctry birth_loc_st addr_bldnum addr_str addr_city addr_zip addr_st addr_ctry {;
		assert length(`var') <= 30;
	};
	assert length(name_raw) <= 100;
	assert length(addr_raw) <= 150;

	/* Checking if extraneous variables are included after keep_cjars_vars */
	foreach var of varlist * {;
		assert inlist("`var'", "record_id", "alias", "name_raw", "name_last", "name_first", "name_middle", "name_suffix", "name_middle_initial", "dob_dd") == 1 | 
		inlist("`var'", "dob_mm","dob_yyyy", "sex_raw", "race_raw","birth_loc_city","birth_loc_st", "birth_loc_ctry", "birth_loc_foreign", "state_id") == 1 |
		inlist("`var'", "state_id_ori", "county_id","county_id_ori", "agency_id", "agency_id_ori", "ssn", "ssn_4", "fbi_num", "addr_raw")==1 | 
		inlist("`var'","addr_bldnum","addr_str","addr_city","addr_st","addr_zip","addr_ctry") == 1 | 
		inlist("`var'", "name_first_clean", "name_middle_clean") == 1;
	};

	
end;