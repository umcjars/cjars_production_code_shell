/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/2_standardization/Utility_Programs;
cjars_globals;
/* Mandatory header **********************************************************

    This code is run to standardize each new data collection.

    MAJOR TASKS
	
    -   Import each formatted .dta.
    -   Identify, clean, and standardize all PII to CJARS standards.
    -   Export .dta of PII data to data/pii/cleaned/${dataset_id}.
    

    OPERATION

    1.  Called from the master_code file. It should not be run on its own.

******************************************************************************/


clear;

import delim "${codedir}/Dataset.csv", varn(1) delim(",");
keep if active_use==1;
*telling stata which data stubs need to be standardized;
keep if (standardization_run==. | standardization_run<standardization_cd_cmpl_dt | standardization_run<localization_run) & standardization_cd_cmpl_dt != . & standardization_cd_cmpl_dt != 0;

levelsof datasetid, local(dataset_ID);

foreach data of local dataset_ID{;
	display "Now processing `data'";
	capture{;
		pii_standardize `data';
		noisily: display "Standardization complete.";
		
		clear;
		import delim "${codedir}/Dataset.csv", varn(1) delim(",");

		tempvar year month day conc;
		gen str4 `year'=string(year(date(c(current_date), "DMY")));
		gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
		gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

		egen `conc'=concat(`year' `month' `day');
		destring `conc', replace;

		replace standardization_run=`conc' if datasetid=="`data'";
		drop `year' `month' `day' `conc';

		export delim "${codedir}/Dataset.csv", replace delim(",");
		noisily: display "Standardization logged.";		
	};
	if _rc != 0{;
		quietly{;
			clear;
			import delim "${codedir}/Dataset.csv", varn(1) delim(",");

			tempvar conc;
			gen `conc'=-999;
			replace standardization_run=`conc' if datasetid=="`data'";
			drop `conc';

			export delim "${codedir}/Dataset.csv", replace delim(",");
			noisily: display "Error logged.";
		};
	};	
	
};
