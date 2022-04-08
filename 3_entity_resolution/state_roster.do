/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/3_entity_resolution/Utility_Programs;
*cjars_globals;
/* Mandatory header **********************************************************

    This code is run to complete entity resolution by creating/updating the national roster. 
	It is called from the master_code file and should only be run from that file.

******************************************************************************/

clear all ;
set max_memory 200g;
capture log close;
timer clear;
timer on 5;

import delim "${codedir}/Dataset.csv", varn(1) delim(",");

keep if active_use==1;
*telling stata which data stubs need to be added to the roster files;

/*Note that this will require the user to get rid of the date in this column if it is supposed to be run*/
keep if (state_roster_run==0 | state_roster_run<entity_resolution_run) & (entity_resolution_run >= impute_run) & entity_resolution_run != 0 & entity_resolution_run != . & supercluster_flag!=1;

levelsof datasetid, local(dataset_ID);
clear;

foreach data of local dataset_ID{;

	state_match_integration `data';
	
	clear;

	import delim "${codedir}/Dataset.csv", varn(1) delim(",");

	tempvar year month day conc;
	gen str4 `year'=string(year(date(c(current_date), "DMY")));
	gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
	gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

	egen `conc'=concat(`year' `month' `day');
	destring `conc', replace;
	replace state_roster_run=`conc' if datasetid=="`data'";
	drop `year' `month' `day' `conc';

	export delim "${codedir}/Dataset.csv", replace delim(",");
};
timer off 5;
timer list 5;
