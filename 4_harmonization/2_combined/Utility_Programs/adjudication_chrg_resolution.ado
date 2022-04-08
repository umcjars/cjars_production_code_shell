/*==============================================================================
Deduplicate Adjudication Charges
================================
Utility program used to update charges with information from later extracts 
(if applicable). This is to prevent double counting duplicate events in the final 
combined data from multiple data extracts.
==============================================================================*/
#delimit;
set trace off;
capture program drop adjudication_chrg_resolution;
program define adjudication_chrg_resolution, rclass;
	
	/* Start by creating a sub_id within charge for CJARS_IDs (charge group) */
	sort cjars_id adj_disp_dt_yyyy;
	
	/* Charge group is identified on CJARS ID, case ID, offense grade, file date, offense date,
		offense code + source description, and state/county information */
	egen long chrg_grp = group(cjars_id case_id adj_grd_cd adj_grd_cd_src adj_file_dt_* adj_off_dt_* 
		adj_disp_off_cd adj_disp_off_cd_src adj_st_ori_fips adj_cnty_ori_fips), mi;
	
	preserve;
		/* keeping identifiers, source indicators, disposition outcomes, and sentencing outcomes - upating the latter three */
		keep cjars_id chrg_grp adj_disp_dt_* adj_disp_cd adj_disp_cd_src adj_sent_* adj_rec_src_*;
		sort cjars_id chrg_grp adj_disp_dt_*;
		foreach var in adj_disp_cd{;
			replace `var' = "" if `var'=="UU";
		};	
		
		/* also replace disp_cd_src and sentencing source with missing so we pull from
			the same row for firstnm disp_cd, disp_cd_src, and inc_sent_src */
		foreach var in adj_disp_cd_src adj_sent_src{;
			replace `var' = "" if adj_disp_cd=="";
		};	
		
		/* temp max disp date and sentence date variable */
		gen adj_disp_dt_temp = mdy(adj_disp_dt_mm, adj_disp_dt_dd, adj_disp_dt_yyyy);
		gen adj_sent_dt_temp = mdy(adj_sent_dt_mm, adj_sent_dt_dd, adj_sent_dt_yyyy);
		
		sort cjars_id chrg_grp adj_disp_dt_temp adj_disp_cd adj_disp_cd_src;
		collapse (max) adj_disp_dt_temp  adj_sent_dt_temp
			adj_sent_serv adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest adj_sent_sus 
			adj_sent_trt adj_sent_fine adj_sent_inc_min adj_sent_inc_max adj_rec_src_*
			(firstnm) adj_sent_src adj_disp_cd adj_disp_cd_src, by(cjars_id chrg_grp);
		
		/* de-couple temp disp and sentence dates */
		gen adj_disp_dt_yyyy = year(adj_disp_dt_temp);
		gen adj_disp_dt_mm = month(adj_disp_dt_temp);
		gen adj_disp_dt_dd = day(adj_disp_dt_temp);
		drop adj_disp_dt_temp;
		
		gen adj_sent_dt_yyyy = year(adj_sent_dt_temp);
		gen adj_sent_dt_mm = month(adj_sent_dt_temp);
		gen adj_sent_dt_dd = day(adj_sent_dt_temp);
		drop adj_sent_dt_temp;
		
		foreach var of varlist adj_disp_dt* adj_disp_cd adj_disp_cd_src adj_sent_* adj_rec_src_*{;
			ren `var' col_`var';
		};

		tempfile disp_updt;
		save `disp_updt', replace;
	
	
	restore;

	merge m:1 cjars_id chrg_grp using `disp_updt', assert(3) nogen;

	gen update_record = 1 if mi(adj_disp_dt_yyyy) & !mi(col_adj_disp_dt_yyyy);

	/* update disposition dates */
	foreach var in adj_disp_dt_dd adj_disp_dt_mm adj_disp_dt_yyyy {;
		replace `var' = col_`var' if update_record==1;
	};
	
	/* update adjudication source indicators to allow for possibly multiple sources */
	foreach var of varlist adj_rec_src_*{;
		replace `var' = col_`var' if update_record==1 & col_`var'==1;
	};	
	

	/* update numerical sentencing outcomes */
	foreach var of varlist adj_sent_dt_yyyy adj_sent_dt_mm adj_sent_dt_dd adj_sent_serv 
		adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest adj_sent_sus adj_sent_trt 
		adj_sent_fine adj_sent_inc_min adj_sent_inc_max{;
		replace `var' = col_`var' if update_record==1 & !mi(col_`var');
	};

	/* update disposition codes; first disp_cd then the accompanying source, then sentencing source */
	foreach var in adj_disp_cd {;
		replace `var' = col_`var' if  update_record==1 & col_`var'!="UU" & col_`var'!="";
	};
	foreach var in adj_disp_cd_src adj_sent_src{;
		replace `var' = col_`var' if  update_record==1 & col_`var'!="";
	};
	
	drop col_* update_record chrg_grp;
	duplicates drop;


end;
