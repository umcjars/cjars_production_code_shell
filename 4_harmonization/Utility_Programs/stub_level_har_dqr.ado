/*==============================================================================
Harmonization Data Quality
==========================
Utility program for generating data quality reports relevant to the specified 
data stub. This utility program accepts dataset_id as an argument.
It is basically a STATA wrapper program that calls the python script called
stub_level_dqr_with_dcteam.py.
==============================================================================*/
#delimit;
program define stub_level_har_dqr, rclass;
	local dataset_id "`1'";
	
    timer clear;
    timer on 10;
	
	/* Save harmonized data */
	di "saving harmonize data for review";
	save "O:/anonymized_records/production_files/har_data_forstub_level_dqr/data_for_dqr.dta", replace;
	
	preserve;
	
	/* Save dataset_id */
	clear;
	di "saving dataset id for saving dqr output files later";
	import delimited using "D:/Users/`c(username)'/Desktop/code/Dataset.csv";
	keep datasetid;
	keep if datasetid == "`dataset_id'";
	save "O:/anonymized_records/production_files/har_data_forstub_level_dqr/datasetid_dqr.dta", replace;
	
	restore;
	
	di "Running stub level DQR on the harmonized data!!";
	
	capture {;
	shell C:\Anaconda3\python.exe "O:/utility/adqc_production/stub_level_dqr/stub_level_dqr_with_dcteam.py";
	};
	
	if _rc !=0 {;
	di "there is an issue with the dqr python code";
	};
	
timer off 10;
timer list 10;
end;
