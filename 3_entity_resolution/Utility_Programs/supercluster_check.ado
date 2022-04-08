#delimit;

program define supercluster_check, eclass;
	syntax anything(name=dataset_id);
	
	local state=substr("`dataset_id'", 1,2);
		
	/*Review new ID's for potential supercluster emergence*/
	use "O:\pii\roster\production_files\almost_done.dta", replace;
	keep cjars_id name_last name_first name_first_clean name_middle_clean name_middle dob_dd dob_mm dob_yyyy dob_string dob_dd_string dob_mm_string dob_yyyy_string sex race;
	duplicates drop;
	bys cjars_id: gen N = [_N];
	keep if N > 6;
	if [_N] > 0{;
		/*Need to reexecute comparison and matching for IDs that have exceeded our max number of name/dob combinations*/
		gen long record_id = [_n];
		foreach var in record_id name_last name_first name_first_clean name_middle_clean name_middle dob_dd dob_mm dob_yyyy dob_string dob_dd_string dob_mm_string dob_yyyy_string sex race{;
			rename `var' `var'_2;
		};
		tempfile file2;
		save "`file2'";
		foreach var in record_id name_last name_first name_first_clean name_middle_clean name_middle dob_dd dob_mm dob_yyyy dob_string dob_dd_string dob_mm_string dob_yyyy_string sex race{;
			rename `var'_2 `var'_1;
		};				
		joinby cjars_id using "`file2'";
		drop if record_id_1 >= record_id_2;
		preserve;
			keep cjars_id record_id_1 record_id_2;
			duplicates drop;
			tempfile pre_fixed_records;
			save "`pre_fixed_records'", replace;
		restore;
		comparator_build;   /**** SAVE TIME BY MERGING BACK ON PREVIOUSLY SAVED COMPARATOR VALUES ***/
		global comparator_list "name_last_match name_last_match_uniq name_last_sdx_match name_last_phx_match name_last_jw name_last_jw_uniq name_last_norm1 name_last_norm1_uniq name_last_normEdt name_last_normEdt_uniq name_first_match name_first_match_uniq name_first_sdx_match name_first_clean_match name_first_phx_match name_first_jw name_first_jw_uniq name_first_clean_jw name_first_norm1 name_first_norm1_uniq name_first_clean_norm1 name_first_normEdt name_first_normEdt_uniq name_first_clean_normEdt name_middle_match name_middle_match_uniq name_middle_sdx_match name_middle_clean_match name_middle_phx_match name_middle_jw name_middle_jw_uniq name_middle_clean_jw name_middle_norm1 name_middle_norm1_uniq name_middle_clean_norm1 name_middle_normEdt name_middle_normEdt_uniq name_middle_clean_normEdt name_middle_miss dob_numgap dob_dd_string_normEdt dob_mm_string_normEdt dob_yyyy_string_normEdt dob_dd_numgap dob_mm_numgap dob_yyyy_numgap mid_miss_1plus mid_miss_both mid_init_1plus mid_init_both female_1plus female_both white_1plus white_both black_1plus black_both hisp_1plus hisp_both dob_jan1_both dob_jan1_1plus";
		keep record_id_1 record_id_2 ${comparator_list};
		gen match = 0;
		order record_id_1 record_id_2 match;
		outsheet using "O:\pii\roster\production_files\roster_data.csv", replace comma;
		local convert_script_path = "${codedir}/3_entity_resolution/Utility_Programs/rf_CJARS_roster.py";
		shell C:\Anaconda3\python.exe `convert_script_path' ;
		clear;
		insheet using "O:\pii\roster\production_files\roster_results.csv", comma; 	
		replace probability = 1-probability if stat_match == 0;
		rename probability score;

		/*Determining the threshold for a match*/
		preserve;
			clear;				
			import delim "${modeldir}/Utility_Programs/match_threshold.txt";
			quietly su v1;
			local threshold=r(mean);			
		restore;			
		
		forval thres = 0(0.1)1{;
			display "Evaluating threshold `thres' compared to `threshold'";
			if `thres' == 0 | `thres' >= `threshold' {;
				if `thres'<=`threshold'{;
					display "stage 1";
					gen new_match = score>=`threshold';
					gen long new_ids = [_n] if new_match == 1;
					/*Iterating to hopefully identify full chain of matches*/
					local j=1;
					while `j'!=0 {;
						clonevar clone=new_ids;
						bys record_id_1: egen long test_id=min(new_ids);
						
						replace new_ids=test_id;
						
						drop test_id;
						
						bys record_id_2: egen long test_id=min(new_ids);
						replace new_ids=test_id;
						drop test_id;
						
						count if clone!=new_ids;
						local j=r(N);
						drop clone;
					};
					bys new_ids: gen ID_count = [_N];
				};
				else{;
					display "stage 2";					
					/* The combinatorial problem of 6 choose 2 is equal to 15.  Any ID with more than 15 combinations implies greater than 6 combinations of name/dobs */
					replace new_match = score>=`thres' if ID_count>	15;
					drop new_ids ID_count;
					gen long new_ids = [_n] if new_match == 1;
					/*Iterating to hopefully identify full chain of matches*/
					local j=1;
					while `j'!=0 {;
						clonevar clone=new_ids;
						bys record_id_1: egen long test_id=min(new_ids);
						
						replace new_ids=test_id;
						
						drop test_id;
						
						bys record_id_2: egen long test_id=min(new_ids);
						replace new_ids=test_id;
						drop test_id;
						
						count if clone!=new_ids;
						local j=r(N);
						drop clone;
					};
					bys new_ids: gen ID_count = [_N];						
				};	
			};
		};
		merge 1:1 record_id_1 record_id_2 using "`pre_fixed_records'";
		gen new_cjars_id = cjars_id+"_"+string(new_ids, "%0`len'.0f");
	};
	
	save "O:\pii\roster\production_files\non_clustered_ids.dta", replace; 
	
end;
