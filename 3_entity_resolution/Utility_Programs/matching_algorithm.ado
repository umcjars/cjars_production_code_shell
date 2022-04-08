#delimit;

program define matching_algorithm, eclass;
	syntax anything(name=dataset_id);
    timer clear;
    timer on 10;
	
	
	preserve;
		clear;
		import delim "${codedir}/Dataset.csv", varn(1) delim(",");
		keep if datasetid=="`dataset_id'";
		levelsof alias_drop, local(alias) clean;
		if "`alias'"=="1"{;
			local aliasdrop=1 ;
		};
		else{;
			local aliasdrop=0 ;
		};
	restore;

	
	use "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", clear;	
			
	
	if "`aliasdrop'"=="1"{;
		drop if alias == 1;
	};
	
	/***************************************************************************
	*
	*        Generating the necessary variables to run the matching algorithm
	***************************************************************************/
	keep record_id alias name_* dob_* race* sex* state_id county_id agency_id ssn fbi_num;
	duplicates drop;

	replace name_middle = "" if name_middle == name_first;

	gen dob_mm_string = string(dob_mm);
	gen dob_dd_string = string(dob_dd);
	gen dob_yyyy_string = string(dob_yyyy);
	gen dob_string = dob_mm_string + "/" + dob_dd_string + "/" + dob_yyyy_string 
		if dob_mm_string != "." | dob_dd_string != "." | dob_yyyy_string != "." ; 
	
	replace dob_dd_string = "0"+dob_dd_string if length(dob_dd_string) == 1 ;
	replace dob_mm_string = "0"+dob_mm_string if length(dob_mm_string) == 1 ;
	
	gen first_sndx 	= soundex(name_first);
	gen last_sndx 	= soundex(name_last);
	
	drop if name_first == "" | name_last == "" | (dob_mm == . & dob_dd == . & dob_yyyy == .);
	drop if strlower(name_last) == "doe" & (strlower(name_first) == "john" | strlower(name_first) == "jane");

	foreach var in first last{;
		rename name_`var' tophonex;
		do "O:\_temp\entity_resolution\prg\utility\phonex.do";
		rename phonexed `var'_phnx;
		rename tophonex name_`var' ;
	};

	local block_set "0 1 2 3 4 5 6 7 8 9";

	egen block0 = group(dob_string last_sndx) ;
	egen block1 = group(dob_string first_sndx) ;
	egen block2 = group(first_sndx last_sndx dob_mm);
	egen block3 = group(first_sndx last_sndx dob_dd);
	egen block4 = group(first_sndx last_sndx dob_yyyy);
	egen block5 = group(dob_string last_phnx) ;
	egen block6 = group(dob_string first_phnx) ;
	egen block7 = group(first_phnx last_phnx dob_mm);
	egen block8 = group(first_phnx last_phnx dob_dd);
	egen block9 = group(first_phnx last_phnx dob_yyyy);
	
	egen long group_id = group(record_id);
	
	bys name_first name_middle name_last dob_dd dob_mm dob_yyyy (group_id): gen obs_num=_n;
	bys name_first name_middle name_last dob_dd dob_mm dob_yyyy (group_id): gen obs_max=_N;

	tempfile pii_with_group_id;
	
	save `pii_with_group_id';
	
	keep if obs_num==1;
	tempfile matches;
	/*Creating the matching pairs within each block*/
	display "Creating blocks";
	foreach b in `block_set' {;
		preserve;
			capture{;
				drop if block`b' == .; 
				rename * *_2;
				rename block`b'_2 block`b';
				drop block*_2;
				tempfile temp_file;
				
				save `temp_file', replace;
			
				rename *_2 *_1;
				joinby block`b' using `temp_file';
				
				drop if record_id_1 == record_id_2;
				
				***********************;
				***********************;
				***********************;

				drop if state_id_1 == state_id_2 	& state_id_1 != "" 	& state_id_2 != "";
				drop if county_id_1 == county_id_2 	& county_id_1 != "" & county_id_2 != "";
				drop if agency_id_1 == agency_id_2 	& agency_id_1 != "" & agency_id_2 != "";
				/*drop if ssn_1 == ssn_2 				& ssn_1 != "" 		& ssn_2 != "";*/
				drop if fbi_num_1 == fbi_num_2 		& fbi_num_1 != "" 	& fbi_num_2 != "";
				
				***********************;
				***********************;
				***********************;
				desc;
				egen long min_group = rowmin(group_id_1 group_id_2);
				egen long max_group = rowmax(group_id_1 group_id_2);
				bys min_group max_group: gen group_n = [_n];
				drop if group_n > 1;
				drop min_group max_group group_n;
				tempfile matches`b';
				
				save `matches`b'', replace;
			};
		restore;
	};
	
	/*Appending pairs from each block together*/
	display "Combining blocks";
	clear;
	foreach b in `block_set' {;
		capture{;
			append using `matches`b'';
		};
	};
	
	/*Making sure that each pair of observations only appears once to improve 
	efficiency*/
	display "Deduplicating after combining blocks";
	egen long min_group = rowmin(group_id_1 group_id_2);
	egen long max_group = rowmax(group_id_1 group_id_2);
	bys min_group max_group: gen group_n = [_n];
	drop if group_n > 1;
	
	tempfile placeholder;
	save "`placeholder'";

	local record_count = [_N];
	
	tempfile base_data;
	save "`base_data'";
	

	display "Comparator creation and predictions";
	use "`base_data'", replace;

	/*Calling the string edit distance program*/
	comparator_build ;
	global comparator_list "name_last_match name_last_match_uniq name_last_sdx_match name_last_phx_match name_last_jw name_last_jw_uniq name_last_norm1 name_last_norm1_uniq name_last_normEdt name_last_normEdt_uniq name_first_match name_first_match_uniq name_first_sdx_match name_first_clean_match name_first_phx_match name_first_jw name_first_jw_uniq name_first_clean_jw name_first_norm1 name_first_norm1_uniq name_first_clean_norm1 name_first_normEdt name_first_normEdt_uniq name_first_clean_normEdt name_middle_match name_middle_match_uniq name_middle_sdx_match name_middle_clean_match name_middle_phx_match name_middle_jw name_middle_jw_uniq name_middle_clean_jw name_middle_norm1 name_middle_norm1_uniq name_middle_clean_norm1 name_middle_normEdt name_middle_normEdt_uniq name_middle_clean_normEdt name_middle_miss dob_numgap dob_dd_string_normEdt dob_mm_string_normEdt dob_yyyy_string_normEdt dob_dd_numgap dob_mm_numgap dob_yyyy_numgap mid_miss_1plus mid_miss_both mid_init_1plus mid_init_both female_1plus female_both white_1plus white_both black_1plus black_both hisp_1plus hisp_both dob_jan1_both dob_jan1_1plus";
	keep record_id_1 record_id_2 ${comparator_list};
	
	/*Executing Match*/
	gen match = 0;
	order record_id_1 record_id_2 match;
	outsheet using "O:\pii\roster\production_files\data.csv", replace comma;
	local convert_script_path = "${codedir}/3_entity_resolution/Utility_Programs/rf_CJARS_predict.py";
	shell C:\Anaconda3\python.exe `convert_script_path' ;

	/*Determining the threshold for a match*/
	preserve;
		clear;
		
		import delim "${modeldir}/Utility_Programs/match_threshold.txt";
		quietly su v1;
		local threshold=r(mean);

	restore;
	
	/*Code now is going to interate through varying threshold levels*/
	/*Will default to the optimal threshold level and then increase the standard*/
	/*for clusters that contain more than 6 unique combinations of names/dob*/
	/*unitl no clusters with more than 6 combinations of pii exist*/
	clear;
	insheet using "O:\pii\roster\production_files\results.csv", comma; 	
												
	gen long results_id = [_n];
	tempfile results;
	save "`results'", replace;
	
	summ stat_match;
	local any_stat_match = r(max);
	
	if `any_stat_match' == 1{; 
		forval thres = 0(0.1)1{;
			cap rm "`final_not_okay'";
			display "Threshold `thres'";
			if `thres' == 0 | `thres' >= `threshold'{;
				clear;
				use "`results'", replace;
				replace probability = 1-probability if stat_match == 0;
				rename probability score;
				
				if "`not_okay_records'"!=""{;
					display "Limiting to just records from superclusters";
					reshape long record_id_, i(results_id) j(order);			
					rename record_id_ record_id;
					merge m:1 record_id using "`not_okay_records'", keep(master match);
					rename _merge merge_status;
					rename record_id record_id_;
					reshape wide record_id_ merge_status, i(results_id) j(order);
					keep if merge_status1 == 3 & merge_status2 == 3;
					count;
					drop merge_status*;
				};
				if `thres'<=`threshold'{;
					keep if score>=`threshold';
				};
				else{;
					keep if score>=`thres' | score == 1; 		
				};
				local match_count = [_N];
				if `match_count' > 0{;
					tempfile comparisons_fullset;
					save "`comparisons_fullset'", replace;
				
					/***************************************************************************
					*
					*                 Creating a roster from the matched pairs
					***************************************************************************/
					use "`placeholder'", replace;
					merge 1:1 record_id_1 record_id_2 using "`comparisons_fullset'", keep(match) nogen;
					keep record_id* group_id*;
					
					/*Canon ID is the common ID for each matched pair*/
					gen long canon_id=min(group_id_1, group_id_2);
					
					tempfile pairs;
					save "`pairs'";
					
					rename (group_id_1 group_id_2 record_id_1 record_id_2) (group_id_2 group_id_1 record_id_2 record_id_1);

					append using "`pairs'";
					
					count;
					if r(N) != 0{;
						local j=1;
						while `j'!=0 {;
							clonevar clone=canon_id;
							bys group_id_1: egen long test_id=min(canon_id);
							
							replace canon_id=test_id;
							
							drop test_id;
							
							bys group_id_2: egen long test_id=min(canon_id);
							replace canon_id=test_id;
							drop test_id;
							
							count if clone!=canon_id;
							local j=r(N);
							drop clone;
						};
					};
					
					keep group_id_1 record_id_1 canon_id;
					
					rename (group_id_1 record_id_1) (group_id record_id);

					cap: duplicates drop;
					
					/*Now, we merge back to the original PII file to get a data level ID*/
					
					merge 1:1 record_id using "`pii_with_group_id'", nogen;
					if "`already_okay'"!=""{;
						merge 1:1 record_id using "`already_okay'", keep(master) nogen;
					};
					if [_N] > 0{;
						bys name_first name_middle name_last dob_dd dob_mm dob_yyyy: egen long duplicate_id=min(canon_id);
						replace canon_id=duplicate_id if duplicate_id!=. & canon_id==.;
						drop duplicate_id;
						
						bys name_first name_middle name_last dob_dd dob_mm dob_yyyy: egen long duplicate_id=min(group_id);
						
						replace canon_id	=duplicate_id if canon_id==. & (name_first!="" & name_last!="" & dob_dd!=. & dob_mm!=. & dob_yyyy!=.);

						drop duplicate_id obs_num;
						
						replace canon_id=group_id if canon_id==.;
						
						drop group_id block*;
						
						/*Hard coding in matches by biometric IDs*/
						quietly count;
						local total=r(N);
						local id_var;
						foreach x of varlist state_id agency_id county_id /*ssn*/ fbi_num {;
							count if missing(`x');
							if (`total'-r(N))!=0 {;
								local id_var="`id_var' `x'";
							};
						};
						local j=0;
						foreach x of local id_var {;
							local j=`j'+1;
							gen id_var_`j'=`x';
						};
						gen long new_canon_id=canon_id;
						
						if `j'>0{;
							local i=1;
							while `i'!=0 {;	
								clonevar clone=new_canon_id;

								forval k = 1(1)`j'{;
									bys id_var_`k': 	egen long id_link 	 =min(new_canon_id) if id_var_`k'!="";		
									bys new_canon_id: 	egen long update_var  =min(id_link) ;		
									replace new_canon_id=update_var if update_var !=.;
									drop id_link update_var;
								};
								count if clone!=new_canon_id;
								local i=r(N);
								drop clone;
							};

						};
						drop canon_id;
						capture drop id_var*;
						drop obs_max;
						rename new_canon_id canon_id;
						
						tempfile prelim_data_level_roster;
						save "`prelim_data_level_roster'", replace;
						keep record_id canon_id;
						merge 1:1 record_id using "`pii_with_group_id'", keep(master match) nogen;
						keep canon_id name_first name_last name_middle dob_dd dob_mm dob_yyyy;
						duplicates drop;
						bys canon_id: gen N = [_N];
						keep if canon_id != . & N > 6;
						if [_N] > 0{;
							keep canon_id;
							duplicates drop;
							preserve;
								merge 1:m canon_id using "`prelim_data_level_roster'", keep(using);
								if [_N] > 0{;
									if "`okay_records'" == ""{;
										tempfile okay_records;
										save "`okay_records'", replace;
										keep record_id;
										duplicates drop;
										tempfile already_okay;
										save "`already_okay'", replace;
									};
									else{;
										display "Appending new records";
										append using "`okay_records'";
										save "`okay_records'", replace;
										keep record_id;
										duplicates drop;
										save "`already_okay'", replace;								
									};	
								};
							restore;
							preserve;
								if [_N] > 0{;
									merge 1:m canon_id using "`prelim_data_level_roster'", keep(match);
									tempfile final_not_okay;
									save "`final_not_okay'", replace;
									keep record_id;
									duplicates drop;
									tempfile not_okay_records;
									save "`not_okay_records'", replace;
								};
							restore;
						};
						if [_N] == 0{;
							if "`okay_records'" == ""{;
								use "`prelim_data_level_roster'", replace;
								tempfile okay_records;
								save "`okay_records'", replace;
								keep record_id;
								duplicates drop;
								tempfile already_okay;
								save "`already_okay'", replace;
							};				
							local not_okay_records "";
							cap rm "`final_not_okay'";
						};
					};
				};
				if `match_count' == 0 & `thres' == 0{;
					clear;
					use `pii_with_group_id', replace;
					gen canon_id = group_id;
					tempfile okay_records;
					save "`okay_records'", replace;
					keep record_id;
					duplicates drop;
					tempfile already_okay;
					save "`already_okay'", replace;
				};
				
			};	
		};
	};	
	if `any_stat_match' == 0{; 
		use `pii_with_group_id', replace;
		egen canon_id = group(name_first name_middle name_last dob_dd dob_mm dob_yyyy), missing;
		tempfile okay_records;
		save "`okay_records'", replace;	
	};
	
	use "`okay_records'", replace;
	cap append using "`final_not_okay'";	
	
	if [_N] > 0{;
		/*Merging back in any records that didn't get a canon ID either due to insufficient PII or being in a supercluster*/
		merge 1:m record_id using "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", nogen keepusing(name_first name_last name_middle dob_dd dob_mm dob_yyyy alias) update;
		if "`aliasdrop'"=="1"{;
			drop if alias == 1;
		};		
	};
	if [_N] == 0{;
		use "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", replace;
		if "`aliasdrop'"=="1"{;
			drop if alias == 1;
		};		
		keep name_first name_last name_middle dob_dd dob_mm dob_yyyy;
		gen long canon_id = .;
	};
	
	egen long final_canon_id = group(canon_id name_first name_last name_middle dob_dd dob_mm dob_yyyy), missing;
	bys canon_id: egen long min_final_canon_id = min(final_canon_id);
	replace final_canon_id = min_final_canon_id if canon_id != .;
	egen long temp_var = group(final_canon_id);
	replace canon_id = temp_var;
	
	drop final_canon_id min_final_canon_id temp_var;
	
	keep record_id canon_id;
	duplicates drop ;
	
	save "${cleanpiidir}/`dataset_id'/data_level_roster.dta", replace;

	cap rm "O:\pii\roster\production_files\data.csv";
	cap rm "O:\pii\roster\production_files\results.csv";
	
timer off 10;
timer list 10;
end;
