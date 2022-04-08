/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/2_standardization/Utility_Programs;
cjars_globals;
/* Mandatory header **********************************************************

    This code is run to impute sex and race for all PII data.

    MAJOR TASKS


    OPERATION

    1.  Called from the master_code file. It should not be run on it's own.

******************************************************************************/
local piidir="//cjarsfs/data/pii";

clear;

import delim "${codedir}/Dataset.csv", varn(1) delim(",");
*telling stata which data stubs need to be imputed;
keep if active_use==1 & standardization_run!=-999 & standardization_run!=0 & standardization_run!=. & (impute_run<standardization_run | impute_run==. | impute_run==0) ;

levelsof state, local(state) clean;
levelsof census_region, local(census_region) clean;
levelsof datasetid, local(dataset_ID) clean;

foreach region of local census_region {;
	clear;
    import delim "${codedir}/Dataset.csv", varn(1) delim(",");
	keep if active_use==1 & census_region=="`region'" & standardization_run>0 & standardization_run!=.;
	quietly levelsof datasetid, local(data) clean;
    clear;
	*Check if the race/sex x region code exists;
	capture noisily confirm file "`piidir'/utility/`region'_sex_rates.dta";
	if _rc == 0{;
		di "Race and Sex files for census regions `region' exist.";
	};
	else if _rc != 0 {;
		di "Race and Sex files don't exist for census regions `region'";
		foreach dat of local data{;
			capture noisily confirm file "${cleanpiidir}/`dat'/cleaned_pii_noimpute.dta";
			if _rc==0 {;
				append using "${cleanpiidir}/`dat'/cleaned_pii_noimpute.dta";
			};
		};
		
		gen source = regexs(1) if regexm(record_id, "([0-9a-zA-Z\_/]*)-") == 1;
		gen hisp = race_raw == 4;
		bys source: egen any_hispanic = max(hisp);
				
		capture confirm file "\\cjarsfs\data\utility\cleaned\Census\Race-Ethnicity Names\Names_2010Census.dta";
		if _rc == 0 {;
			merge m:1 name_last using "\\cjarsfs\data\utility\cleaned\Census\Race-Ethnicity Names\Names_2010Census.dta", nogen keep(master matched) keepusing(pcthispanic);
		};
		
		replace race_raw = 4 if pcthispanic>67 & pcthispanic!=. & any_hispanic == 0;	
		drop pcthispanic hisp any_hispanic source;
		
		keep name_* dob_* race_raw sex_raw;
		duplicates drop;

		preserve;
			keep if race_raw!=. & name_first!="";
			keep name_first race_raw;
			if _N>0 {;
				gen white = race_raw == 1;
				gen black = race_raw == 2;
				gen asian = race_raw==3;
				gen hispanic = race_raw==4;
				gen aian = race_raw == 5;
				gen other_race = race_raw == 6;
				gen x = 1;
				collapse (mean) white black asian hispanic aian other_race (sum) n = x, by(name_first);
				rename (white black asian hispanic aian other_race n) (first_white first_black first_asian first_hispanic first_aian first_other_race n_first);
				replace first_white = round(first_white, 0.01);
				replace first_black = round(first_black, 0.01);
				replace first_asian = round(first_asian, 0.01);
				replace first_hispanic = round(first_hispanic, 0.01);
				replace first_aian = round(first_aian, 0.01);
				replace first_other_race = round(first_other_race, 0.01);
				*We can add a statement here to only keep names with minimum count threshold ;
				save "`piidir'/utility/`region'_race_rates_first.dta", replace;
			}; 
		restore;
	

		preserve;
			keep if race_raw!=. & name_last!="";
			keep name_last race_raw;
			if _N>0 {;
				gen white = race_raw == 1;
				gen black = race_raw == 2;
				gen asian = race_raw==3;
				gen hispanic = race_raw==4;
				gen aian = race_raw == 5;
				gen other_race = race_raw == 6;
				gen x = 1;
				collapse (mean) white black asian hispanic aian other_race (sum) n = x, by(name_last);
				rename (white black asian hispanic aian other_race n) (last_white last_black last_asian last_hispanic last_aian last_other_race n_last);
				replace last_white = round(last_white, 0.01);
				replace last_black = round(last_black, 0.01);
				replace last_asian = round(last_asian, 0.01);
				replace last_hispanic = round(last_hispanic, 0.01);
				replace last_aian = round(last_aian, 0.01);
				replace last_other_race = round(last_other_race, 0.01);
				*We can add a statement here to only keep names with minimum count threshold ;
				save "`piidir'/utility/`region'_race_rates_last.dta", replace;
			}; 
		restore;
	
		preserve;
			keep if sex_raw!=. & name_first!="";
			keep name_first sex_raw;
			if _N>0 {;
				gen male = sex_raw == 1;
				gen female = sex_raw == 2;
				collapse (mean) male female, by(name_first);
				tempfile sex_rates;
				replace male = round(male, 0.01);
				replace female = round(female, 0.01);
				*We can add a statement here to only keep names with minimum count threshold ;
				save "`piidir'/utility/`region'_sex_rates.dta", replace;
			};    
		restore;
	};
};
		
foreach data of local dataset_ID{;
	clear;
	impute_race_gender `data';

	clear;
    
	import delim "${codedir}/Dataset.csv", varn(1) delim(",");
	
	tempvar year month day conc;
	gen str4 `year'=string(year(date(c(current_date), "DMY")));
	gen str2 `month'=string(month(date(c(current_date), "DMY")), "%02.0f");
	gen str2 `day'=string(day(date(c(current_date), "DMY")), "%02.0f");

	egen `conc'=concat(`year' `month' `day');
	destring `conc', replace;

	replace impute_run=`conc' if datasetid=="`data'";
	drop `year' `month' `day' `conc';

	export delim "${codedir}/Dataset.csv", replace delim(",");
	
};



