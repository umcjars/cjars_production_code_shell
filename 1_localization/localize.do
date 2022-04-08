/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/1_localization/Utility_Programs;
*cjars_globals;
/* Mandatory header **********************************************************/


/*

    This code is run on each new data collection.

    MAJOR TASKS

    -   Import each raw data table.
    -   Use any necessary dictionary found in
            1_localization/${dataset_id}/dictionaries/.dct
    -   Fix fundamental dataset issues needed for proper conversion via
            1_localization/${dataset_id}/fix.do
    -   Generate row-specific CJARS record_id.
    -   Save each data table into a separate .dta file.
    -   Run final_localize.do (if present -- should be rare).

    OPERATION

    1.  Called from master_code file.
    

******************************************************************************/
clear;

import delim "${codedir}/Dataset.csv", varn(1) delim(",");
keep if active_use==1;
*telling stata which data stubs need to be localized;

keep if (localization_run==. | localization_run==0 | localization_run < localize_cd_cmpl_dt) & localize_cd_cmpl_dt != .;

levelsof datasetid, local(dataset_ID);

foreach data of local dataset_ID{;
	clear;
	display "Localizing `data'";
	localize `data';
	clear;
	import delim "${codedir}/Dataset.csv", varn(1) delim(",");

	tempvar year month day conc;
	gen str4 `year'=string(year(date(c(current_date), "DMY")));
	gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
	gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

	egen `conc'=concat(`year' `month' `day');
	destring `conc', replace;

	*replace localize_cd_cmpl_dt=`conc' if datasetid=="`data'";
	replace localization_run=`conc' if datasetid=="`data'";
	
	drop `year' `month' `day' `conc';

	export delim "${codedir}/Dataset.csv", replace delim(",");
	clear;
};
