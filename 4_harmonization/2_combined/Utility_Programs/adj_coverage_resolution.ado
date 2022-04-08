/*==============================================================================
Adjudication Coverage
=====================
Utility program to validate county coverage of CJARS data
==============================================================================*/
#delimit;
set trace off;
capture program drop adj_coverage_resolution;
capture program define adj_coverage_resolution, rclass;		
		
		gen disp_date = ym(adj_disp_dt_yyyy, adj_disp_dt_mm);
		gen file_date = ym(adj_file_dt_yyyy, adj_file_dt_mm);
		gen off_date = ym(adj_off_dt_yyyy, adj_off_dt_mm);
		format disp_date file_date off_date %tm;
		gen compare_date = disp_date;
		replace compare_date = file_date if mi(compare_date) & !mi(file_date);
		replace compare_date = off_date if mi(compare_date) & !mi(off_date);
		drop disp_date file_date off_date;
		format compare_date %tm;
		
		gen src_state = regexm(source, "St/") == 1;
		gen local_source = src_state == 0;
		drop source src_state;
		
		/* state to pass in to coverage file */
		destring adj_st_ori_fips, gen(st_tmp);
		sum st_tmp;
		local st_tmp_lcl = `r(min)';
		drop st_tmp;
	
	preserve;
		keep cjars_id;
		duplicates drop;
		tempfile ids_in_adj;
		save `ids_in_adj', replace;
	restore;
	
	
	/* Data coverage file set up */
	preserve;
		import delim "${codedir}/utility/data_coverage_files/Jurisdiction_Coverage_Guidance.csv", clear;
		
		/* extract the value for looping over columns */
		ds;
		gen last_two = "`r(varlist)'";
		replace last_two = substr(last_two,-2,2);
		foreach i in `c(alpha)'{;
			replace last_two = subinstr(last_two, "`i'", "", .);
		};
		destring last_two, replace;
		sum last_two;
		local loop_count = `r(max)';
		drop last_two;
		di "`loop_count'";

		/* just the state we're working with and convert FIPS to match cleaned files */
		keep if st_fips==`st_tmp_lcl';
		tostring st_fips, replace;
		replace st_fips = "0" + st_fips if strlen(st_fips)==1;
		assert strlen(st_fips)==2;
		tostring cnty_fips, replace;
		replace cnty_fips = "00" + cnty_fips if strlen(cnty_fips)==1;
		replace cnty_fips = "0" + cnty_fips if strlen(cnty_fips)==2;
		assert strlen(cnty_fips)==3;
		
		/* just want the adjudication rows */
		keep if inlist(cjars_table, "ADJ_MI", "ADJ_FE");
		replace cjars_table = substr(cjars_table, -2, 2);
		ren cjars_table adj_grd_cd;
		ren st_fips adj_st_ori_fips;
		ren cnty_fips adj_cnty_ori_fips;
		
		tempfile data_coverage;
		save `data_coverage', replace;
	restore;
	
	/* Merge to data coverage file. Note that all types of merges are possible.  
		Master only will be where missing county information or adj_grd_cd.
		Using only are where we have coverage but no qualifying offenses.
		Matches are obvious. */	
	merge m:1 adj_grd_cd adj_st_ori_fips adj_cnty_ori_fips using `data_coverage', keep(1 3) gen(coverage_match);
	cou if coverage_match==3;
	local match_count = `r(N)';
	
	/* Nest keep procedure conditional on having non-zero matches */
	if `match_count'>0{;
		assert (mi(adj_cnty_ori_fips) | adj_grd_cd=="UU") | (inlist(adj_grd_cd, "JF", "JM", "JU")) if coverage_match==1;
		
			/* convert string dates to numeric and construct bounds for UU offenses. 
			The bounds are conservative across the union of FE/MI offenses.
			Note that no UU codes in the coverage file means these bound constructions occur after merge*/
			forvalues i = 1/`loop_count'{;
			
				gen start_mt_nm`i' = monthly(start_month`i', "YM");
				gen end_mt_nm`i' = monthly(end_month`i', "YM");
				format start_mt_nm`i' end_mt_nm`i' %tm;
				drop start_month`i' end_month`i';
				
				/* date bounds for UU offenses */
				replace start_mt_nm`i' = . if adj_grd_cd=="UU";
				replace end_mt_nm`i' = . if adj_grd_cd=="UU";
				bys adj_st_ori_fips adj_cnty_ori_fips: egen first_st_dt = min(start_mt_nm`i');
				bys adj_st_ori_fips adj_cnty_ori_fips: egen last_end_dt = max(end_mt_nm`i');
				format first_st_dt last_end_dt %tm;
				replace start_mt_nm`i' = first_st_dt if adj_grd_cd=="UU";
				replace end_mt_nm`i' = last_end_dt if adj_grd_cd=="UU";
				drop first_st_dt last_end_dt;
				order start_mt_nm`i' end_mt_nm`i', before(snapshot_begin`i');
				
				
				/* types for UU offenses */
				foreach var in src_primary src_secondary src_local src_state{;
					replace `var'`i' = . if adj_grd_cd=="UU";
				};	
				bys adj_st_ori_fips adj_cnty_ori_fips: egen max_prim = max(src_primary`i');
				bys adj_st_ori_fips adj_cnty_ori_fips: egen max_secondary = max(src_secondary`i');
				bys adj_st_ori_fips adj_cnty_ori_fips: egen max_local = max(src_local`i');
				bys adj_st_ori_fips adj_cnty_ori_fips: egen max_state = max(src_state`i');
				assert max_prim ==1 | max_secondary==1 if (!mi(max_prim) & !mi(max_secondary));
				assert max_local==1 | max_state==1 if (!mi(max_local) & !mi(max_state));
				replace src_primary`i' = max_prim if adj_grd_cd=="UU";
				replace src_secondary`i' = max_secondary if adj_grd_cd=="UU";
				replace src_local`i' = max_local if adj_grd_cd=="UU";
				replace src_state`i' = max_state if adj_grd_cd=="UU";
				drop max_prim max_secondary max_local max_state;
				
			};
				
			sort cjars_id compare_date;

			/* Hierarchical procedure for record keeping */
			gen record_keep = 0;
			
				/* just keep these since we have no matches */
				replace record_keep = 1 if mi(adj_cnty_ori_fips);
				replace record_keep = 1 if mi(compare_date);
				
				/* Keep all juvenile records */
				replace record_keep = 1 if inlist(adj_grd_cd, "JF", "JM", "JU");
				
				/* loop over the wide-file sources */
				forvalues i = 1/`loop_count'{;
				
					/* 1) keep if primary source, we have local court data, it is a local record, and it is a court record */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_primary`i'==1 & src_local`i'==1 & local_source==1 & adj_rec_src_crt==1 & record_keep==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
					
					/* 2) keep if primary source, only have statewide court, it is a statewide court, and is a court record */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_primary`i'==1 & src_local`i'==0 & src_state`i'==1 & local_source==0 & adj_rec_src_crt==1 & record_keep==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
						
						/* 2A) keep if we should have a local record, but only statewide source and no other observed record within a year */
						by cjars_id: replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
							& src_primary`i'==1 & src_local`i'==1 & local_source==0 & adj_rec_src_crt==1 & record_keep==0
							& compare_date[_n] - compare_date[_n-1] >12 & compare_date[_n+1] - compare_date[_n]>12
							& compare_date[_n] - compare_date[_n-1]!=. & compare_date[_n+1]!=.
							& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
							
							/* 2A.1) Special end point condition for first record.
								Same parameters as 2A, but allow for _n-1 to be missing. */
							by cjars_id: replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
								& src_primary`i'==1 & src_local`i'==1 & local_source==0 & adj_rec_src_crt==1 & record_keep==0
								& compare_date[_n] - compare_date[_n-1] >12 & compare_date[_n+1] - compare_date[_n]>12
								& compare_date[_n-1]==. & compare_date[_n+1]!=.
								& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
						
						/* 2B) keep if we should have primary source, but only secondary source and no other observed record within a year */
						by cjars_id: replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
							& src_primary`i'==1 & adj_rec_src_crt==0 & record_keep==0 
							& compare_date[_n] - compare_date[_n-1] >12 & compare_date[_n+1] - compare_date[_n]>12
							& compare_date[_n] - compare_date[_n-1]!=. & compare_date[_n+1]!=.
							& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
							
							/* 2B.1) Special end point condition for first record.
								Same parameters as 2B, but allow for _n-1 to be missing. */
								by cjars_id: replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
									& src_primary`i'==1 & adj_rec_src_crt==0 & record_keep==0 
									& compare_date[_n] - compare_date[_n-1] >12 & compare_date[_n+1] - compare_date[_n]>12
									& compare_date[_n-1]==. & compare_date[_n+1]!=.
									& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
									
					/* 3) Keep if primary source, not court records (e.g., repo), don't have local, statewide source */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_primary`i'==1 & src_local`i'==0 & local_source==0 & adj_rec_src_crt==0 & record_keep==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');				
					
					/* 4) Keep if secondary source, court records, statewide */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_secondary`i'==1 & src_local`i'==0 & local_source==0 & adj_rec_src_crt==1 & record_keep==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
						
					/* 5) keep if secondary source (not court), local source, and is not a court record */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_secondary`i'==1 & src_local`i'==1 & local_source==1 & adj_rec_src_crt==0 & record_keep==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
						
					/* 6) keep if secondary source (not court), have statewide source, and is not a court record */
					replace record_keep = 1 if compare_date>=start_mt_nm`i' & compare_date<=end_mt_nm`i'
						& src_secondary`i'==1 & src_state`i'==1 & local_source==0 & adj_rec_src_crt==0
						& !mi(start_mt_nm`i') & !mi(end_mt_nm`i');
				
				};
				
				/* want to keep records that are outside of the earliest observed coverage bound */
				replace record_keep = 1 if compare_date <= start_mt_nm1;
				
				/* Want to keep if it's the only record we observe for a person */
				bys cjars_id: replace record_keep = 1 if _N==1;
				
				/* last step to make merge work - just keep records that we know should be good, but don't fall into the windows based on source */
				bys cjars_id: egen any_record = max(record_keep);
				replace record_keep = 1 if any_record==0;
				drop any_record;
				
			keep if record_keep==1;
			merge m:1 cjars_id using `ids_in_adj', assert(3) nogen;
			
			drop local_source start_mt_nm* end_mt_nm* src_primary* src_secondary* compare_date record_keep src_local* src_state* snapshot_*;
			cap drop _merge;
			cap drop coverage_match;
		};
		/* End nest */
	
		/* if no matches, keep everything */
		if `match_count'==0{;
			drop local_source start_* end_* src_primary* src_secondary* compare_date src_local* src_state* snapshot_*;
			cap drop _merge;
			cap drop coverage_match;
		};	
	
end;	
