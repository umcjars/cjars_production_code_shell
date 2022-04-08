/*==============================================================================
Deduplicate Arrest Charges
==========================
Utility program used to update charges with information from later extracts 
(if applicable). This is to prevent double counting duplicate events in the final 
combined data from multiple data extracts.
==============================================================================*/
#delimit;
set trace off;
capture program drop arrest_chrg_resolution;
program define arrest_chrg_resolution, rclass;

	
	/* Start by creating a sub_id (charge group) within charge for CJARS_IDs */
	sort cjars_id arr_arr_dt_yyyy;
	
	/* Charge group is identified on CJARS ID, case ID, arrest date, arrest offenses, and arrest state/county*/
	egen long chrg_grp = group(cjars_id case_id arr_off_cd arr_off_cd_src arr_arr_dt*
		arr_st_ori_fips arr_cnty_ori_fips), mi;
	
	preserve;
		/* note that arrest codes are nested in the chrg_grp so we dont need to keep them */
		keep cjars_id chrg_grp arr_book_dt_* arr_rec_src_*;	
		
		/* temp booking date */
		gen arr_book_dt_temp = mdy(arr_book_dt_mm, arr_book_dt_dd, arr_book_dt_yyyy);
		
		sort cjars_id chrg_grp arr_book_dt_temp;
		collapse (max) arr_book_dt_temp arr_rec_src_*, by(cjars_id chrg_grp);
		
		/* de-couple booking date */
		gen arr_book_dt_yyyy = year(arr_book_dt_temp);
		gen arr_book_dt_mm = month(arr_book_dt_temp);
		gen arr_book_dt_dd = day(arr_book_dt_temp);
		drop arr_book_dt_temp;
		
		foreach var of varlist arr_book_dt* arr_rec_src_*{;
			ren `var' col_`var';
		};
		
		tempfile arr_updt;
		save `arr_updt', replace;
	
	
	restore;

	merge m:1 cjars_id chrg_grp using `arr_updt', assert(3) nogen;
	
	/* only update records where we actually update the booking date */
	gen update_record = 1 if mi(arr_book_dt_yyyy) & !mi(col_arr_book_dt_yyyy);
	
	/* updating booking dates */
	foreach var of varlist arr_book_dt_* {;
		replace `var' = col_`var' if update_record==1;
	};
	
	/* updating sources if needed */
	foreach var of varlist arr_rec_src_*{;
		replace `var' = col_`var' if update_record==1 & col_`var'==1;
	};	
	
	drop col_* update_record chrg_grp;
	duplicates drop;


end;
