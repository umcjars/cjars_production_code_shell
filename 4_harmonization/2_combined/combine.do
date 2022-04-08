/*==============================================================================
Combine
=======
Main program for combining harmonized data. The program first loads in `Dataset.csv` 
to identify any updated datasets that need to combined or re-combined for each 
criminal justice stage (arrest, adjudication, incarceration, parole, and/or 
probation). After identifying which data stubs are relevant for the combine stage,
combined files for states that contain those relevant data stubs will be removed.
There is a combine.ado subsidiary file that gets called in line 62 which does the
actual combine job. Combine job here refers to appending all the data stubs 
for a certain state, performing de-duplication, applying coverage files and
adding source files variables (e.g. data collected from primary source 
or secondary source).
After the program finishes running, it will create `combined_arrest.dta`, 
`combined_adjudication.dta`, `combined_incarceration.dta`, `combined_parole.dta`, 
and/or `combined_probation.dta` for each state and update `combine_run` field in 
`Dataset.csv` with the date of program execution. If the program runs into any 
errors, it will set `combine_run` to `-999`.
==============================================================================*/
#delimit ;
adopath + "${codedir}/4_harmonization/Utility_Programs";
adopath + "${codedir}/4_harmonization/2_combined/Utility_Programs";
clear all ;
capture log close;

*set processors 6; // Use only ~50% of CPU
set max_memory 200g;

/* Identify which combined files need to be rebuilt from scratch either because: 
 (1) an existing dataset in the combined files has had a revision to it's harmonization code and been re-run, or,
 (2) a new roster for a given state had been pushed therefor nullifying all data in the current combined data because it relies on an obsolete set of cjars_id's.

The full data has to be completely eliminated in either case because we cannot excise the out-of-date information from these records.
*/
import delim "${codedir}/Dataset.csv", varn(1) delim(",");
keep if active_use==1; // In Dataset.csv, active_use column == 1 means the data stub is in use and gets incorporated into the final combined files of CJARS
keep if combine_run!= 0 & combine_run != . & (harmonization_run > combine_run | cjars_id_state_push_run > combine_run);
levelsof state, local(state) clean;
clear;
foreach st of local state{;
	foreach file in arrest adjudication incarceration parole probation{;
		cap rm "O:\anonymized_records\3_combined\\`st'\combined_`file'.dta";
	};
};
/* Updating the combine_run date to 0 since we've now deleted out the state-specific combined files for states that need to be updated */
clear;
import delim "${codedir}/Dataset.csv", varn(1) delim(",");
foreach st of local state{;
	replace combine_run = 0 if state == "`st'";
};
export delim "${codedir}/Dataset.csv", replace delim(",");


/* Now starting the main part of the combine code */
clear;
import delim "${codedir}/Dataset.csv", varn(1) delim(",");
keep if active_use==1;
keep if harmonization_run>0 & !missing(harmonization_run) & harmonization_cd_cmpl_dt>0 & !missing(harmonization_cd_cmpl_dt);
keep if ((combine_run==0 | combine_run==.) & harmonization_run != .) | combine_run<harmonization_run;
levelsof state, local(state) clean;

clear;
foreach st of local state{;

	di "state: `st'";
	capture combine `st'; // combine.ado gets called and run
	local combine_error = _rc;

	import delim "${codedir}/Dataset.csv", varn(1) delim(",") clear;
	*import delim "${codedir}/test.csv", varn(1) delim(",");

	if `combine_error'==0{;
		tempvar year month day conc;
		gen str4 `year'=string(year(date(c(current_date), "DMY")));
		gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
		gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

		egen `conc'=concat(`year' `month' `day');
		destring `conc', replace;
		replace combine_run=`conc' if active_use==1 & harmonization_run>0 & !missing(harmonization_run) & state=="`st'" ;
		drop `year' `month' `day' `conc';
	};
	
	if `combine_error'!=0{;
		tempvar conc;
		gen `conc' = -999;
		replace combine_run = `conc' if active_use==1 & harmonization_run>0 & !missing(harmonization_run) & state=="`st'" ;
		drop `conc';
	};

	export delim "${codedir}/Dataset.csv", replace delim(",");
	*export delim "${codedir}/test.csv", replace delim(",");

};


