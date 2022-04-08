/*==============================================================================
Classify FIPS Codes
===================
Utility program for merging in county and state FIPS codes from a pre-existing 
crosswalk on the Secure Data Enclave (SDE) server. When invoked, the program 
accepts arguments for county name and state abbreviation.

Output(s)
=========
- COUNTY_FIPS:			3-digit county FIPS code
- STATE_FIPS:			2-digit state FIPS code
==============================================================================*/
#delimit;
capture program drop classify_fips;
program define classify_fips, rclass;
	syntax, county(varname string) state(varname string);
	
	local FIPS_XWALK = "O:/anonymized_records/1_prepared/utility/fips.dta";
	if "`county'" != "COUNTY_NAME" {;
		gen COUNTY_NAME = strtrim(stritrim(upper(`county')));
	};
	else {;
		replace COUNTY_NAME = strtrim(stritrim(upper(COUNTY_NAME)));
	};
	if "`state'" != "STATE_NAME" {;
		gen STATE_NAME = strtrim(stritrim(upper(`state')));
	};
	else {;
		replace STATE_NAME = strtrim(stritrim(upper(STATE_NAME)));
	};
	
	merge m:1 COUNTY_NAME STATE_NAME using "`FIPS_XWALK'", nogen keep(matched master) keepusing(COUNTY_FIPS STATE_FIPS);
	
end;
