#delimit;

program define match_predictions, eclass;
	syntax anything(name=dataset_id);

use "O:\pii\roster\production_files\with_comparators_added.dta", replace;
	
quietly count ;
local matchable=r(N);
if `matchable'>0 {;

	global comparator_list "name_last_match name_last_match_uniq name_last_sdx_match name_last_phx_match name_last_jw name_last_jw_uniq name_last_norm1 name_last_norm1_uniq name_last_normEdt name_last_normEdt_uniq name_first_match name_first_match_uniq name_first_sdx_match name_first_clean_match name_first_phx_match name_first_jw name_first_jw_uniq name_first_clean_jw name_first_norm1 name_first_norm1_uniq name_first_clean_norm1 name_first_normEdt name_first_normEdt_uniq name_first_clean_normEdt name_middle_match name_middle_match_uniq name_middle_sdx_match name_middle_clean_match name_middle_phx_match name_middle_jw name_middle_jw_uniq name_middle_clean_jw name_middle_norm1 name_middle_norm1_uniq name_middle_clean_norm1 name_middle_normEdt name_middle_normEdt_uniq name_middle_clean_normEdt name_middle_miss dob_numgap dob_dd_string_normEdt dob_mm_string_normEdt dob_yyyy_string_normEdt dob_dd_numgap dob_mm_numgap dob_yyyy_numgap mid_miss_1plus mid_miss_both mid_init_1plus mid_init_both female_1plus female_both white_1plus white_both black_1plus black_both hisp_1plus hisp_both dob_jan1_both dob_jan1_1plus";
		
	foreach var in ${comparator_list} {;
		replace `var' = 0 if `var' == .;
	};
	gen long record_id_1 = [_n];
	gen long record_id_2 = [_n];
	tempfile holding_file;
	save "`holding_file'", replace;
	keep record_id_1 record_id_2 ${comparator_list};

	/*Executing Match*/
	gen match = 0;
	order record_id_1 record_id_2 match;
	cap rm "O:\pii\roster\production_files\roster_data.csv";
	cap rm "O:\pii\roster\production_files\roster_results.csv";

	outsheet using "O:\pii\roster\production_files\roster_data.csv", replace comma;
	local convert_script_path = "${codedir}/3_entity_resolution/Utility_Programs/rf_CJARS_roster.py";
	shell C:\Anaconda3\python.exe `convert_script_path' ;

	/*Determining the threshold for a match*/
	preserve;
		clear;
		
		import delim "${modeldir}/Utility_Programs/match_threshold.txt";
		quietly su v1;
		local threshold=r(mean);

	restore;

	clear;
	insheet using "O:\pii\roster\production_files\roster_results.csv", comma; 	
			
	merge 1:1 record_id_1 record_id_2 using "`holding_file'", nogen;

	gen long results_id = [_n];

	replace probability = 1-probability if stat_match == 0;
	rename probability score;

	/*Keep if score is greater than the threshold*/
	keep if score>=`threshold';
		
	capture{;
		append using "O:\pii\roster\production_files\exact_match_pairs.dta";
	};
};

else{; 
	use "O:\pii\roster\production_files\exact_match_pairs.dta", replace;
};

save "O:\pii\roster\production_files\ready_for_id_enumeration.dta", replace;

end;
