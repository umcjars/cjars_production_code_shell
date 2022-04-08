#delimit;

program define id_enumeration, eclass;
	syntax anything(name=dataset_id);

	local state=substr("`dataset_id'", 1,2);
	quietly count;

	/***************************************************************************
	*                 Creating a state-level CJARS roster from the matched pairs
	*                 This will give every person in the database a CJARS ID
	***************************************************************************/
	
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
	
	use "O:\pii\roster\production_files\ready_for_id_enumeration.dta", replace;
	
	if r(N) != 0{;
		keep cjars_id_1 canon_id_2;
		duplicates drop;
		rename cjars_id_1 cjars_id;
		rename canon_id_2 canon_id;
		tempfile canon_to_cjars_link;
		
		save "`canon_to_cjars_link'", replace;
	};
	clear;
	use	"${cleanpiidir}/`dataset_id'/data_level_roster.dta";
	duplicates drop;
	merge 1:m record_id using "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", nogen keep(master matched);		
	if "`aliasdrop'"=="1"{;     
		drop if alias == 1;
	};
	drop record_id;
	duplicates drop;

	gen dob_mm_string = string(dob_mm);
	gen dob_dd_string = string(dob_dd);
	gen dob_yyyy_string = string(dob_yyyy);
	gen dob_string = dob_mm_string + "/" + dob_dd_string + "/" + dob_yyyy_string 
		if dob_mm_string != "." | dob_dd_string != "." | dob_yyyy_string != "." ; 
			
	capture{;
		joinby canon_id using "`canon_to_cjars_link'", unmatched(master) ;
		drop _m;
	};

	append using "O:\pii\roster\production_files\old_roster_sufficient_pii.dta", gen(roster);
	destring cjars_id, replace ignore("`state'");
	gen long missing_fill = [_n];

	summ missing_fill;
	replace cjars_id = cjars_id + r(max) if cjars_id != .;
	replace cjars_id = missing_fill if cjars_id == .;
	replace canon_id = canon_id + r(max) if canon_id != .;
	replace canon_id = missing_fill if canon_id == .;

	preserve;
		egen long new_cjars_id = group(cjars_id canon_id);
		
		keep cjars_id canon_id new_cjars_id;
		duplicates drop;
		format * %12.0f;
		
		local j=1;
		while `j'!=0 {;
			clonevar clone=new_cjars_id;
			
			quietly bys cjars_id: egen long test_id=min(new_cjars_id);
			quietly replace new_cjars_id=test_id;
			drop test_id;
			
			quietly bys canon_id: egen long test_id=min(new_cjars_id);
			quietly replace new_cjars_id=test_id;
			drop test_id;
			
			count if clone!=new_cjars_id;
			local j=r(N);
			drop clone;
		};
		
		duplicates drop;
		
		tempfile new_ids;
		save     "`new_ids'", replace;		

	restore;

	merge m:1 cjars_id canon_id using "`new_ids'";
	drop canon_id cjars_id;
	rename new_cjars_id cjars_id;
	order cjars_id;
	drop missing_fill _merge roster;

	/*removing observations that are missing PII and are not linked with other full-PII obs*/
	gen missing_nm_dob= ( (missing(name_first) | missing(name_last)) | (missing(dob_dd) & missing(dob_mm) & missing(dob_yyyy)) );
	replace missing_nm_dob=0 if missing_nm_dob==.;
	bys cjars_id: egen all_miss=min(missing_nm_dob);
	bys all_miss name_first name_middle name_last dob_dd dob_mm dob_yyyy: egen long min_id=min(cjars_id);
	replace cjars_id= min_id if all_miss==1;
	drop missing_nm_dob all_miss min_id;
	duplicates drop;

	tempvar length;
	gen `length'=length(string(cjars_id));
	quietly su `length';
	local len=r(max);
	gen cjars_id_string=string(cjars_id, "%0`len'.0f");
	drop cjars_id;
	rename cjars_id_string cjars_id;
	replace cjars_id="`state'"+cjars_id;
	order cjars_id;
	drop `length';
	/*Compressing file to save space*/
	compress;
	
	save "O:\pii\roster\production_files\almost_done.dta", replace;
	
end;
