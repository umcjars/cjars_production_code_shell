/*==============================================================================
Stub-level standardization data quality review
==============================
Produces figures and metrics for dataset-level quality review of standardization

==============================================================================*/

#delimit;
capture program drop stub_level_std_dqr; 
program define stub_level_std_dqr, rclass;
	
	local dataset_id "`1'";
	local dqrdir = "\\cjarsfs\data\output\adqc_reports\stub_level_dqr_std";
	di "Running stub level DQR reports for stub `dataset_id'";
	shell mkdir "`dqrdir'\\`dataset_id'";
	local filedir = "`dqrdir'\\`dataset_id'";
	local title = subinstr("`dataset_id'", "/", "_", .);
	preserve;
	*create local macros;
	foreach var in dob_yyyy dob_mm dob_dd name_first name_last sex_raw race_raw  {;
			local `var'_x = .;
	};
	*generate histograms for variables with discrete values. Use `varlist' to store the variables with histograms. Also count the number of missing;
	local varlist = "";
		foreach var in dob_yyyy dob_mm dob_dd sex_raw race_raw {;
			
			capture gen miss_`var' = (`var' == .);
			if _rc == 0 {;
			su miss_`var';
			local `var'_x : di %3.2f  r(mean);
			capture histogram `var', discrete title("`var'") name(`var', replace) nodraw;
			if _rc == 0 {;
				local varlist = "`varlist'" + " " + "`var'";
				};
			if _rc != 0 {;
				local `var'_x = 999;
			};
		};
	};
	*Count the number of missing for string variables;
	foreach var in name_first name_last {;
			
			capture gen miss_`var' = (`var' == "");
			if _rc == 0 {;
			su miss_`var';
			local `var'_x : di %3.2f  r(mean);
			};
			if _rc != 0 {;
				local `var'_x = 999;
			};
		};

	*Generate report of statistics and output the combined graphs;
		putpdf clear;
		putpdf begin;
		putpdf paragraph;
		putpdf text ("`title'"), bold;
		putpdf paragraph;
		putpdf paragraph;
		foreach var in dob_yyyy dob_mm dob_dd name_first name_last sex_raw race_raw  {;
			putpdf text ("`var' % missing"), underline;
			putpdf text (": ``var'_x'");
			putpdf paragraph;
	};
		putpdf text ("Note: if 999, then variable is missing from cleaned_pii.dta. ");
		putpdf paragraph, halign(center);
		di "`varlist'";
		graph combine `varlist';
		qui local title = subinstr("`dataset_id'", "/", "_", .);
	    graph export "`filedir'/`title'.png", replace;
		putpdf paragraph, halign(center);
		putpdf image "`filedir'/`title'.png";
		putpdf save "`filedir'//std_dqr_report.pdf", replace;
		restore;

	/* String Variables */
	confirm string variable record_id;
	confirm string variable name_last;
	confirm string variable name_first;
	confirm string variable name_middle;
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
	
	/* Checking for really long string values that take up a lot of disk space */
	foreach var in name_last name_first name_middle name_suffix name_middle_initial birth_loc_city birth_loc_ctry birth_loc_st addr_bldnum addr_str addr_city addr_zip addr_st addr_ctry {;
		assert length(`var') <= 30;
	};
	assert length(name_raw) <= 100;
	assert length(addr_raw) <= 150;	
	
	
end;
