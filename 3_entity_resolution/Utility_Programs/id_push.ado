#delimit;

program define id_push, eclass;
	syntax anything(name=dataset_id);
    timer clear;
    timer on 10;
	
	local st=substr("`dataset_id'",1,2);
	use "${cleanpiidir}/`dataset_id'/data_level_roster.dta", replace;
	duplicates drop;
	display "merge 1";
	merge 1:m record_id using "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", nogen keep(master match);
		keep record_id name_raw name_last name_first name_middle dob_* race sex;
		duplicates drop;

	display "merge 2";		
	merge m:1 name_raw name_last name_first name_middle dob_mm dob_dd dob_yyyy using "O:\pii\roster\temp_crosswalk_file_`st'.dta", keep(master match);
	
	keep record_id cjars_id;
	duplicates drop;
	save "${cleanpiidir}/`dataset_id'/record_id_cjars_id_crosswalk.dta", replace;
    gen length=length(subinstr(cjars_id,"`st'","",.));
	quietly su length, d;
	local len=r(max);
	tempvar cjars_id_num;
	destring cjars_id, gen(`cjars_id_num') ignore("`st'");
	
    
    capture confirm file "${cleanpiidir}/`dataset_id'//pointer_file.dta";
    
    if _rc==0 {;
		display "Pointer file exists for `dataset_id'";
        preserve;
            clear;   
            import delim "${codedir}/Dataset.csv", delim(",") varn(1);
            keep if datasetid=="`dataset_id'";  
            levelsof pivot_id, local(pointer) clean;     
        restore;
 
		display "merge 3";	   
        merge 1:1 record_id using "${cleanpiidir}/`dataset_id'/pointer_file.dta", nogen;
        bys `pointer': egen long fill_id=min(`cjars_id_num');
        replace `cjars_id_num'=fill_id if `cjars_id_num'==. & fill_id!=.;
        drop fill_id;
        drop if `cjars_id_num'==.;				        
    };
		
	replace cjars_id="`st'"+string(`cjars_id_num', "%0`len'.0f");
	drop `cjars_id_num';
	keep record_id cjars_id;
	duplicates drop;
    tempfile record_id_cjars_id;
	save `record_id_cjars_id';
    
    clear;
    import delim "${cleanpiidir}/`dataset_id'/pii_var.txt", delim(",") varn(1);       
    levelsof pii_var, local(pii_var) clean;  
    local format_files: dir "${formatdir}/`dataset_id'" files "*.dta";

	clear;	
	foreach file of local format_files {;
		use "${formatdir}`dataset_id'/`file'", replace;
		foreach var of local pii_var {;
			capture drop `var';
		};
	
		display "merge 4";		
		merge 1:1 record_id using `record_id_cjars_id', nogen keep(matched);		
		drop if cjars_id=="" | cjars_id=="`st'";
		capture save "${anondir}/1_prepared/`dataset_id'/`file'", replace;
		
	};
	clear;
	
	shell mkdir "${codedir}/4_harmonization/1_prepared/`dataset_id'"; 
	local do_files: dir "${codedir}/4_harmonization/1_prepared/`dataset_id'" files "*.do";
	local wc: word count `do_files';
 
	if `wc'==0 {;
		file open placeholder using "${codedir}/4_harmonization/1_prepared/`dataset_id'/placeholder.do", write;
		file write placeholder "/* Placeholder -- Code harmonization here. */" _n;
		file close placeholder;
	};
	
	/* Copy Reference Directories to O:/anonymized/1_prepared/`dataset_id' */
	local ref_dirs: dir "${formatdir}/`dataset_id'" dirs "*";
	foreach dir of local ref_dirs {;
		shell xcopy "${formatdir}/`dataset_id'/`dir'" "${anondir}/1_prepared/`dataset_id'/`dir'" /I /Y;
	};
	
timer off 10;
timer list 10;
end;
