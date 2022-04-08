/*==============================================================================
Harmonization
=============
Main program for running harmonization. Invoked by `master_code.do`. This program 
first loads in `Dataset.csv` to identify all of the active datasets that either 
need to be harmonized or re-harmonized. After the dataset has been succeesffully 
harmonized, this code will update `harmonize_run` field in `Dataset.csv` to keep 
track of when the dataset was last harmonized. If the harmonization failed, 
`harmonize_run` will be set to `-999` to indicate runtime error.
==============================================================================*/
#delimit ;
adopath + ${codedir}/4_harmonization/Utility_Programs;
clear all ;
capture log close;


import delim "${codedir}/Dataset.csv", varn(1) delim(",");

keep if active_use==1;
*telling stata which data stubs need to be harmonized;

/*Note that this will require the user to get rid of the date in this column if it is supposed to be run*/
keep if (cjars_id_state_push_run>harmonization_run | harmonization_run==. | harmonization_run==0 | harmonization_run<harmonization_cd_cmpl_dt | harmonization_run<toc_vintage) & cjars_id_state_push_run != 0
	& harmonization_cd_cmpl_dt != . & harmonization_cd_cmpl_dt != 0 & toc_vintage != .;
	
levelsof datasetid, local(dataset_ID);
clear;
foreach data of local dataset_ID{;
	capture{;
		shell mkdir "O:/anonymized_records/2_cleaned/`data'";
	};
	
	local file_list: dir "O:/anonymized_records/2_cleaned/`data'" files "*.dta";	// Store list of *.dta files as local macro `file_list'
	foreach file of local file_list {;	// Loop over each file in the directory
		rm "O:/anonymized_records/2_cleaned/`data'/`file'";	// Delete out any preexisting files from prior rounds of harmonization
	};
	
	display "`data'";
	capture{;

		harmonize `data';
		noisily: display "Harmoinization complete.";

		clear;
		import delim "${codedir}/Dataset.csv", varn(1) delim(",");

		tempvar year month day conc;
		gen str4 `year'=string(year(date(c(current_date), "DMY")));
		gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
		gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

		egen `conc'=concat(`year' `month' `day');
		destring `conc', replace;
		replace harmonization_run=`conc' if datasetid=="`data'";
		drop `year' `month' `day' `conc';

		export delim "${codedir}/Dataset.csv", replace delim(",");
		noisily: display "Harmoinization logged.";
	};
	if _rc != 0{;
		quietly{;
			clear;
			import delim "${codedir}/Dataset.csv", varn(1) delim(",");

			tempvar conc;
			gen `conc'=-999;
			replace harmonization_run=`conc' if datasetid=="`data'";
			drop `conc';

			export delim "${codedir}/Dataset.csv", replace delim(",");
			noisily: display "Error logged.";
		};
	};
};

