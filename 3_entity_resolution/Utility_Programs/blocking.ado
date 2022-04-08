#delimit;

program define blocking, eclass;
	syntax anything(name=dataset_id);
	
display "Roster exists: now matching `dataset_id' to existing roster";

local state=substr("`dataset_id'", 1,2);

/* Setting aside records that have insufficient PII from roster. Each unique set of PII (including all of name_raw will get a unique CJARS_ID so the CJ interactions remain in the data even if the record is not PIK-able. ( Many of these are businesses or situations where a John Doe is charged with an offense. */	
preserve;
	clear;
	use "${rosterdir}/cjars_roster_`state'.dta", replace;
	keep if name_first=="" | name_last=="" | (dob_dd==. & dob_mm==. & dob_yyyy==.);
	if [_N] > 0{;
		drop cjars_id;
		save "O:\pii\roster\production_files\old_roster_insufficient_pii.dta", replace;
	};

	clear;
	use "${rosterdir}/cjars_roster_`state'.dta", replace;	
	keep if name_first!="" & name_last!="" & (dob_dd!=. | dob_mm!=. | dob_yyyy==.);
	save "O:\pii\roster\production_files\old_roster_sufficient_pii.dta", replace;	
restore;

/* Setting aside records that have insufficient PII. Each record will get a unique CJARS_ID so the CJ interactions remain in the data even if the record is not PIK-able. ( Many of these are businesses or situations where a John Doe is charged with an offense. */	
preserve;
	keep if name_first=="" | name_last=="" | (dob_dd==. & dob_mm==. & dob_yyyy==.);
	if [_N] > 0{;	
		drop record_id;
		duplicates drop;
		keep alias name_raw name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy birth_loc_city birth_loc_st birth_loc_ctry birth_loc_foreign sex_raw race_raw state_id state_id_ori county_id county_id_ori agency_id agency_id_ori ssn fbi_num addr_raw addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry name_first_clean name_middle_clean race sex race_imputed sex_imputed;
		save "O:\pii\roster\production_files\insufficient_pii_for_linking.dta", replace;
	};
restore;
drop if name_first=="" | name_last=="" | (dob_dd==. & dob_mm==. & dob_yyyy==.);		

/*Now we match with existing CJARS roster to get a cjars study ID*/
drop record_id name_raw birth* addr* state_id* agency_id* ssn* fbi_num county_id* sex_raw race_raw race_imputed sex_imputed;  /*Dropping out irrelevant information to help conserve memory*/
duplicates drop ;
/*Now we need to append this PII data to the master roster.*/

/*First eliminate any exact matches since those will perfectly match to a current CJARS ID cluster.*/
preserve;
	clear;
	use cjars_id name_last name_first name_middle dob_dd dob_mm dob_yyyy using "O:\pii\roster\production_files\old_roster_sufficient_pii.dta", replace;
	drop if name_first=="" | name_last=="" | (dob_dd==. & dob_mm==. & dob_yyyy==.);		
	duplicates drop;
	tempfile ID_crosswalk;
	save "`ID_crosswalk'";
restore;
merge m:1 name_last name_first name_middle dob_dd dob_mm dob_yyyy using "`ID_crosswalk'", keep(master match) keepusing(cjars_id);

/* Pull off exact matches and save for later in the code */
preserve;
	keep if _m == 3;
	if [_N] > 0{;
		drop _m;
		keep cjars_id canon_id alias name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy name_first_clean name_middle_clean race sex;
		foreach var in alias name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy name_first_clean name_middle_clean race sex{;
			gen `var'_2 = `var';
			rename `var' `var'_1;
		};
		rename cjars_id cjars_id_1;
		rename canon_id canon_id_2;

		save "O:\pii\roster\production_files\exact_match_pairs.dta", replace;
		
		qui sum canon_id_2;
		local count = r(N);
		
		noisily display "Identified `count' exact matches in this dataset.";
	};
restore;
	
/* Only retain non-exact matches now */
keep if _m == 1;
if [_N] > 0 {;
	drop _m;
	drop cjars_id;

	/* Append existing roster to build out definitions of blocks */
	append using "O:\pii\roster\production_files\old_roster_sufficient_pii.dta", gen(roster) keep(cjars_id alias name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy name_first_clean name_middle_clean race sex);
	duplicates drop ;

	gen dob_mm_string = string(dob_mm);
	gen dob_dd_string = string(dob_dd);
	gen dob_yyyy_string = string(dob_yyyy);
	gen dob_string = dob_mm_string + "/" + dob_dd_string + "/" + dob_yyyy_string 
		if dob_mm_string != "." | dob_dd_string != "." | dob_yyyy_string != "." ; 
	gen first_sndx 	= soundex(name_first);
	gen last_sndx 	= soundex(name_last);
	foreach var in first last{;
		rename name_`var' tophonex;
		do "${codedir}/3_entity_resolution/Utility_Programs/phonex.do";
		rename phonexed `var'_phnx;
		rename tophonex name_`var' ;
	};	
	local block_set "0 1 2 3 4 5 6 7 8 9";
	
	local block0 dob_string last_sndx;
	local block1 dob_string first_sndx;
	local block2 first_sndx last_sndx dob_mm;
	local block3 first_sndx last_sndx dob_dd;
	local block4 first_sndx last_sndx dob_yyyy;
	local block5 dob_string last_phnx;
	local block6 dob_string first_phnx;
	local block7 first_phnx last_phnx dob_mm;
	local block8 first_phnx last_phnx dob_dd;
	local block9 first_phnx last_phnx dob_yyyy;

	gen first_init = substr(name_first,1,1); 
	gen last_init = substr(name_last,1,1);
	
	preserve;
		keep if roster==1;
		foreach var of varlist *{;
			gen `var'_1 = `var';
		};
		keep dob_string last_sndx first_sndx dob_mm dob_dd dob_yyyy last_phnx first_phnx first_init last_init *_1;
		tempfile roster_with_blocks;
		save "`roster_with_blocks'";
	restore;

	preserve;
		keep if roster==0;
		foreach var of varlist *{;
			gen `var'_2 = `var';
		};
		keep dob_string last_sndx first_sndx dob_mm dob_dd dob_yyyy last_phnx first_phnx first_init last_init *_2;
		tempfile new_with_blocks;
		save "`new_with_blocks'";
	restore;

	/*Creating the matching pairs within each block*/
	foreach b in `block_set' {;
		clear;
		use "`roster_with_blocks'";
		
		joinby `block`b'' using "`new_with_blocks'";
		
		keep *_1 *_2;
		tempfile matches`b';
		save "`matches`b''", replace;
	};
	
	/*Merging pairs from each block together*/
	clear;
	use "`matches2'";
	foreach b in `block_set' {;
		merge 1:1 *_1 *_2 using "`matches`b''", nogen;
	};
	save "O:\pii\roster\production_files\base_data.dta", replace;
};
else{;
	clear;
};

display "Complete Blocking";

end;
