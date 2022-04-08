#delimit;
/*Program to create the string edit distances between pairs of observations. The 
program is run when there is a data set in memory that is properly formatted, 
i.e., name_1 name_2 etc.*/

program define comparator_build, rclass;

quietly count;
local matchable=r(N);
if `matchable'>0 {;

	adopath + D:/Users/`c(username)'/Desktop/code/3_entity_resolution/Utility_Programs;
	/*Generating string edit distances for first, middle, last names and DOB*/
	
	local stub "name_last name_first name_first_clean name_middle_clean name_middle dob_dd_string dob_mm_string dob_yyyy_string";
	display "`stub'";
	
	foreach x of local stub {;
		if "`x'" != "dob_dd_string" & "`x'" !=  "dob_mm_string" & "`x'" !=  "dob_yyyy_string" {;
			ustrdist `x'_1 `x'_2, gen(`x'_score);
			jarowinkler `x'_1 `x'_2, gen(`x'_jw)  ;
			gen 	`x'_length=max(strlen(`x'_1),strlen(`x'_2))	;
			gen 	`x'_norm1=(`x'_score/`x'_length);
			gen 	`x'_normEdt=`x'_score;
			if "`x'" == "name_middle" | "`x'" == "name_middle_clean"{;
				gen 	`x'_miss = `x'_norm1 == .;
				replace `x'_norm1=0 if `x'_miss == 1;
			};
			drop `x'_score `x'_length;
		};
		if "`x'" == "dob_dd_string" | "`x'" ==  "dob_mm_string" | "`x'" ==  "dob_yyyy_string" {;
			ustrdist `x'_1 `x'_2, gen(`x'_score);
			gen 	`x'_normEdt=`x'_score;
			drop 	`x'_score ;
		};
		gen `x'_match = `x'_1 == `x'_2 if `x'_1 != "" & `x'_2 != "";
		replace `x'_match = 0 if `x'_match == .;
	};
	ustrdist dob_string_1 dob_string_2, gen(dob_string_score);
	gen 	 dob_string_normEdt=dob_string_score;
	drop 	 dob_string_score ;	

	compress;

	* ACCOUNTING FOR NAME SWAPPING BETWEEN FIRST/MIDDLE NAMES, FIRST/LAST NAMES, AND MIDDLE/LAST NAMES;
	* Requires one exact match in the reordering to get processed to avoid reprocessing a lot of non-matches;
	foreach name1 in first middle{;
		foreach name2 in middle last{;
			if "`name1'" != "`name2'"{  ;  
				preserve;
					capture{;
						keep if name_`name1'_1 != name_`name1'_2 & name_`name2'_1 != name_`name2'_2 & (name_`name1'_1 == name_`name2'_2 | name_`name2'_1 == name_`name1'_2);
						ustrdist name_`name1'_1 name_`name2'_2, gen(flip1_score);
							gen 	flip1_length=max(strlen(name_`name1'_1),strlen(name_`name2'_2))	;
							gen 	flip1_norm1=(flip1_score/flip1_length);
							gen 	flip1_normEdt=flip1_score;
						ustrdist name_`name2'_1 name_`name1'_2, gen(flip2_score);
							gen 	flip2_length=max(strlen(name_`name2'_1),strlen(name_`name1'_2))	;
							gen 	flip2_norm1=(flip2_score/flip2_length);
							gen 	flip2_normEdt=flip2_score;
							
						replace name_`name1'_norm1 = flip1_norm1 if flip1_norm1 < name_`name1'_norm1 & flip1_norm1 != . & flip2_norm1 < name_`name2'_norm1 & flip2_norm1 != .;
						replace name_`name1'_norm1 = flip2_norm1 if flip2_norm1 < name_`name1'_norm1 & flip2_norm1 != . & flip1_norm1 < name_`name2'_norm1 & flip1_norm1 != .;
						replace name_`name2'_norm1 = flip1_norm1 if flip1_norm1 < name_`name1'_norm1 & flip1_norm1 != . & flip2_norm1 < name_`name2'_norm1 & flip2_norm1 != .;
						replace name_`name2'_norm1 = flip2_norm1 if flip2_norm1 < name_`name1'_norm1 & flip2_norm1 != . & flip1_norm1 < name_`name2'_norm1 & flip1_norm1 != .;
						
						replace name_`name1'_normEdt = flip1_normEdt if flip1_normEdt < name_`name1'_normEdt & flip1_normEdt != . & flip2_normEdt < name_`name2'_normEdt & flip2_normEdt != .;
						replace name_`name1'_normEdt = flip2_normEdt if flip2_normEdt < name_`name1'_normEdt & flip2_normEdt != . & flip1_normEdt < name_`name2'_normEdt & flip1_normEdt != .;
						replace name_`name2'_normEdt = flip1_normEdt if flip1_normEdt < name_`name1'_normEdt & flip1_normEdt != . & flip2_normEdt < name_`name2'_normEdt & flip2_normEdt != .;
						replace name_`name2'_normEdt = flip2_normEdt if flip2_normEdt < name_`name1'_normEdt & flip2_normEdt != . & flip1_normEdt < name_`name2'_normEdt & flip1_normEdt != .;
							drop flip*;
							
						jarowinkler name_`name1'_1 name_`name2'_2, gen(temp1_jw)  ;
						jarowinkler name_`name2'_1 name_`name1'_2, gen(temp2_jw)  ;
						replace name_`name1'_jw = temp1_jw if temp1_jw < name_`name1'_jw & temp1_jw != . & temp2_jw < name_`name2'_jw & temp2_jw != .;
						replace name_`name1'_jw = temp2_jw if temp2_jw < name_`name1'_jw & temp2_jw != . & temp1_jw < name_`name2'_jw & temp1_jw != .;
						replace name_`name2'_jw = temp1_jw if temp1_jw < name_`name1'_jw & temp1_jw != . & temp2_jw < name_`name2'_jw & temp2_jw != .;
						replace name_`name2'_jw = temp2_jw if temp2_jw < name_`name1'_jw & temp2_jw != . & temp1_jw < name_`name2'_jw & temp1_jw != .;
						drop temp*_jw ;
						
						keep record_id_1 record_id_2 *_norm1 *_jw;
						tempfile swapped_values;
						save "`swapped_values'";
					};
				restore;
				capture: merge 1:1 record_id_1 record_id_2 using "`swapped_values'", update replace nogen;
			}; 
		};
	};

	* SOUNDEX;
	foreach var in name_last name_first name_middle{;
		gen byte `var'_sdx_match = soundex(`var'_1)==soundex(`var'_2);
	};

	compress;

	* PHONEX; 
	foreach var in name_last name_first name_middle{;
		foreach iteration in 1 2{;
			rename `var'_`iteration' tophonex;
			do "${codedir}/3_entity_resolution/Utility_Programs/phonex.do";
			rename phonexed `var'_phnx_`iteration';
			rename tophonex `var'_`iteration';
		};		
		gen byte `var'_phx_match = `var'_phnx_1==`var'_phnx_2;
	};	

	* NUMERIC COMPARISON OF DATES;
	gen long dob_numgap = abs(mdy(dob_mm_1, dob_dd_1, dob_yyyy_1) - mdy(dob_mm_2, dob_dd_2, dob_yyyy_2));
	gen int dob_dd_numgap = abs(dob_dd_1 - dob_dd_2);
	gen int dob_mm_numgap = abs(dob_mm_1 - dob_mm_2);
	gen int dob_yyyy_numgap = abs(dob_yyyy_1 - dob_yyyy_2);
	*Dealing with partial missing dob elements;
	replace dob_dd_numgap = 15 if dob_dd_numgap == .;
	replace dob_mm_numgap = 6 if dob_mm_numgap == .;
	replace dob_yyyy_numgap = 5 if dob_yyyy_numgap == .;	
	replace dob_numgap = dob_dd_numgap+dob_mm_numgap*30+dob_yyyy_numgap*365 if dob_numgap == .;
	

	*UNIQUENESS SCORES;
	foreach var in name_last name_first name_middle{;
		foreach iteration in 1 2{;
			rename `var'_`iteration' `var';
			merge m:1 `var' using "${codedir}/3_entity_resolution/Utility_Programs/`var'_prevalence.dta", nogen keep(master match);
			rename `var' `var'_`iteration' ;
			rename `var'_unique `var'_`iteration'_unique;
			replace `var'_`iteration'_unique = 0 if `var'_`iteration'_unique == .;
		};
		gen `var'_unique = (`var'_1_unique + `var'_2_unique)/2;
		egen `var'_max_unique = rowmax(`var'_1_unique `var'_2_unique);
	};
	foreach var in name_last name_first name_middle{;
		gen `var'_match_uniq  	= `var'_match 	* `var'_unique;
		gen `var'_jw_uniq  		= `var'_jw 		* `var'_max_unique;
		gen `var'_norm1_uniq  	= `var'_norm1 	* `var'_max_unique;
		gen `var'_normEdt_uniq  = `var'_normEdt * `var'_max_unique;
	};
	
	gen miss_1 = name_middle_1 == "";
	gen miss_2 = name_middle_2 == "";
	gen init_1 = length(name_middle_1) == 1;
	gen init_2 = length(name_middle_1) == 1;

	gen mid_miss_1plus = miss_1 == 1 | miss_2 == 1;
	gen mid_miss_both  = miss_1 == 1 & miss_2 == 1;
	gen mid_init_1plus = init_1 == 1 | init_2 == 1;
	gen mid_init_both  = init_1 == 1 & init_2 == 1;

	gen female_1plus =  sex_1 == 2 |  sex_2 == 2;
	gen female_both  =  sex_1 == 2 &  sex_2 == 2;
	gen white_1plus  = race_1 == 1 | race_2 == 1;
	gen white_both   = race_1 == 1 & race_2 == 1;
	gen black_1plus  = race_1 == 2 | race_2 == 2;
	gen black_both   = race_1 == 2 & race_2 == 2;
	gen hisp_1plus   = race_1 == 4 | race_2 == 4;
	gen hisp_both    = race_1 == 4 & race_2 == 4;

	*Create January 1st flag since immigrants are more likely to pool on this day as their declared dob;
	gen dob_jan1_both =  (dob_mm_1 == 1 & dob_dd_1 == 1) & (dob_mm_2 == 1 & dob_dd_2 == 1);
	gen dob_jan1_1plus=  (dob_mm_1 == 1 & dob_dd_1 == 1) | (dob_mm_2 == 1 & dob_dd_2 == 1);

	save "O:\pii\roster\production_files\with_comparators_added.dta", replace; 
	
};
end;
