/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/3_entity_resolution/Utility_Programs;
*cjars_globals;
/* Mandatory header **********************************************************

    This code is run to complete entity resolution by creating/updating the national roster. 
	It is called from the master_code file and should only be run from that file.

******************************************************************************/

clear all ;
capture log close;

import delim "${codedir}/Dataset.csv", varn(1) delim(",");

keep if active_use==1;

/*Note that this will require the user to get rid of the date in this column if it is supposed to be run*/
keep if state_roster_run != 0 & state_roster_run != 20990101 & state_roster_run!=. & entity_resolution_run != 0 & entity_resolution_run != .;

/* This code will need to be re-run if any additional data has been added to the state's 
roster since the actual study id's for all of data get reset to accomodate the new merges */
* This will capture any changes that span multiple days ;
bys state: egen max_state_roster = max(state_roster_run);
replace max_state_roster = 0 if max_state_roster == .;
bys state: egen min_cjars_id_push 	 = min(cjars_id_state_push_run);
replace min_cjars_id_push = 0 if min_cjars_id_push == .;
gen flag = max_state_roster > min_cjars_id_push & !missing(max_state_roster) & !missing(min_cjars_id_push);


preserve;

	keep if flag==1;
	quietly count;
	if r(N)>0 {;
		levelsof state, local(state) clean;
	};
	
restore;

foreach st of local state {;
	preserve;
	
		keep if state=="`st'";
		quietly levelsof datasetid, local(`st'_dataset_ID) clean;
	restore;
};

capture levelsof current_working_roster,  local(roster_version) clean;

foreach st of local state {;
	use cjars_id name_raw name_last name_first name_middle dob_dd dob_mm dob_yyyy race sex using "O:/pii/roster/cjars_roster_`st'.dta",
	clear;
	bys name_raw name_last name_first name_middle dob_* race sex: gen n = [_n];
	drop if n > 1; 
	/*This is dropping out odd observations that didn't go through entity resolution but got linked
			in because of a agency_id.  The vast majority are companies and so don't really
			fit into CJARS anyway. */
	save "O:\pii\roster\temp_crosswalk_file_`st'.dta", replace;
	clear;

	foreach data of local `st'_dataset_ID {;
		
		shell mkdir "${anondir}/1_prepared/`data'";
		shell mkdir "${anondir}/2_cleaned/`data'";
		shell mkdir "${anondir}/3_combined/`data'";
		
		id_push `data';

		clear;
		import delim "${codedir}/Dataset.csv", varn(1) delim(",");

		tempvar year month day conc;
		gen str4 `year'=string(year(date(c(current_date), "DMY")));
		gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
		gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

		egen `conc'=concat(`year' `month' `day');
		destring `conc', replace;
		replace cjars_id_state_push_run=`conc' if datasetid=="`data'";
		drop `year' `month' `day' `conc';

		export delim "${codedir}/Dataset.csv", replace delim(",");
	};
	
	rm "O:\pii\roster\temp_crosswalk_file_`st'.dta";
};

