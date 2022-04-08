/*==============================================================================
Collapse Adjudication
=====================
The purpose of this file is to more aggressively collapse adjudication charges 
together that may be duplicates. We define an observation to collapse on as the 
CJARS-ID, Disposition Date, Charge Grade, Charge Code, Disposition Outcome, 
Geographic combination. We take the earliest observed file and offense dates, 
the max of any source/sentencing variables, longest string source variables, and 
first non-missing for any book_id, case_id. For disposition outcomes, we create 
a hierarchical structure to prioritize keeping G(non-U) when we have that data.	
==============================================================================*/
#delimit;
set trace off;
capture program drop adjudication_collapse;
program define adjudication_collapse, rclass;
	/* File, Offense, Sentence Date Coupling (and disposition date for collapse/sort) */
	gen file_date = mdy(adj_file_dt_mm, adj_file_dt_dd, adj_file_dt_yyyy);
	gen off_date = mdy(adj_off_dt_mm, adj_off_dt_dd, adj_off_dt_yyyy);
	gen sent_date = mdy(adj_sent_dt_mm, adj_sent_dt_dd, adj_sent_dt_yyyy);
	gen disp_date = mdy(adj_disp_dt_mm, adj_disp_dt_dd, adj_disp_dt_yyyy);

	/* Disposition Code Hierarchy - Preserving non "*U" codes where possible */
	gen guilty = (substr(adj_disp_cd,1,1)=="G");
	gen not_guilty = (substr(adj_disp_cd,1,1)=="N");
	gen diversion = (substr(adj_disp_cd,1,1)=="D");
	gen procedural = (substr(adj_disp_cd,1,1)=="P");
	gen unknown = (substr(adj_disp_cd,1,1)=="U");
	
		gen guilty_hierarchy = 0;
		replace guilty_hierarchy = 1 if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI") & guilty==1;
		gen ng_hierarchy = 0;
		replace ng_hierarchy = 1 if inlist(adj_disp_cd, "NA", "ND", "NI", "NM", "NP") & not_guilty==1;
		gen procedure_hierarchy = 0;
		replace procedure_hierarchy = 1 if inlist(adj_disp_cd, "PT") & procedural==1;
		
	/* Initial Sort 
		ID, Grade, Offense Code, Adjudication Outcome + hierarchy, source prioritizes keeping firstnm info from court records which we think are generally highest quality for this data table. */
	gsort cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd adj_disp_off_cd disp_date -guilty -guilty_hierarchy -not_guilty -ng_hierarchy -diversion 
		-procedural -procedure_hierarchy unknown -adj_rec_src_crt -adj_rec_src_rep -adj_rec_src_doc -adj_rec_src_cc -adj_rec_src_le;
		
	/* First collapse using all available data, including disp_off_cd in the collapse parameters */
	collapse (min) file_date off_date /* Earliest offense/filing dates auxiliary dates */
			 (max) sent_date adj_sent_serv adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest 
					adj_sent_sus adj_sent_trt adj_sent_fine adj_sent_inc_min adj_sent_inc_max /* Maximum of all sentencing variables, note that if two minimums, we take the larger of the two since that's the binding one */	
					adj_rec_src_* /* Maximum of source indicators */
			 (firstnm) book_id case_id /* Misc. case variables */ 
					   adj_grd_cd_src adj_chrg_off_cd adj_chrg_off_cd_src adj_disp_cd adj_disp_cd_src adj_disp_off_cd_src /* Adjudication grade and disposition variables */
					   adj_sent_src adj_off_lgl_cd adj_off_lgl_cd_src, /* Sentencing source and legal offense source */
			  by(cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd adj_disp_off_cd disp_date guilty not_guilty diversion procedural unknown); /* Note collapsing on outcome indicators allows to separate multiple identical charges that have different outcomes */
	
	/* Second collapse accounting for disp_off_cd==9999.
		We consider the set of collapse parameters, less adj_disp_off_cd as groups.
		Set adj_disp_off_cd==9999 to missing, then compute modal within group.
		Perform same collapse as above with the new codes added. */
	replace adj_disp_off_cd = "" if adj_disp_off_cd=="9999";
	gen impute_code = (adj_disp_off_cd=="");
	egen long group = group(cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd disp_date guilty not_guilty diversion procedural unknown), mi;
	egen mode_cd = mode(adj_disp_off_cd), by(group) minmode;
	replace adj_disp_off_cd = mode_cd if !mi(mode_cd) & mi(adj_disp_off_cd) & impute_code==1;
	replace adj_disp_off_cd = "9999" if mi(adj_disp_off_cd);
	assert adj_disp_off_cd!="";
	drop mode_cd;
	
		/* recreate hierarchy measures */
		gen guilty_hierarchy = 0;
		replace guilty_hierarchy = 1 if inlist(adj_disp_cd, "GC", "GJ", "GP", "GI") & guilty==1;
		gen ng_hierarchy = 0;
		replace ng_hierarchy = 1 if inlist(adj_disp_cd, "NA", "ND", "NI", "NM", "NP") & not_guilty==1;
		gen procedure_hierarchy = 0;
		replace procedure_hierarchy = 1 if inlist(adj_disp_cd, "PT") & procedural==1;
	
	/* resort for collapse, adding the impute code so that when we take firstnm strings, we get the original source string to try and minimize conflicts */
	gsort cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd adj_disp_off_cd disp_date -guilty -guilty_hierarchy -not_guilty -ng_hierarchy -diversion 
		-procedural -procedure_hierarchy unknown impute_code -adj_rec_src_crt -adj_rec_src_rep -adj_rec_src_doc -adj_rec_src_cc -adj_rec_src_le;
		
	collapse (min) file_date off_date /* Earliest offense/filing dates auxiliary dates */
		 (max) sent_date adj_sent_serv adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest 
				adj_sent_sus adj_sent_trt adj_sent_fine adj_sent_inc_min adj_sent_inc_max /* Maximum of all sentencing variables, note that if two minimums, we take the larger of the two since that's the binding one */	
				adj_rec_src_* /* Maximum of source indicators */
		 (firstnm) book_id case_id /* Misc. case variables */ 
				   adj_grd_cd_src adj_chrg_off_cd adj_chrg_off_cd_src adj_disp_cd adj_disp_cd_src adj_disp_off_cd_src /* Adjudication grade and disposition variables */
				   adj_sent_src adj_off_lgl_cd adj_off_lgl_cd_src, /* Sentencing source and legal offense source */
		  by(cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd adj_disp_off_cd disp_date guilty not_guilty diversion procedural unknown); /* Note collapsing on outcome indicators allows to separate multiple identical charges that have different outcomes */
	
	/* Third, extension of data coverage logic to resolve scenarios with non-missing adjudication codes, but where data coverage includes all types.*/
	preserve;
		keep cjars_id;
		duplicates drop;
		tempfile ids; /* tempfile to assert that we don't delete out any records */
		save `ids', replace;
	restore;
	
	egen long group = group(cjars_id adj_st_ori_fips adj_cnty_ori_fips adj_grd_cd disp_date guilty not_guilty diversion procedural unknown), mi;
	egen any_court_src_grp = max(adj_rec_src_crt), by(group); /* any court records in this group */
	gen any_court_src = adj_rec_src_crt; /* does this record have a court source associated with it */
	egen non_crt_src = rowmax(adj_rec_src_le adj_rec_src_doc adj_rec_src_rep adj_rec_src_cc); /* record sourced from non-court records */
	gen drop_flag = 0;
	replace drop_flag = 1 if any_court_src_grp==1 & any_court_src==0 & non_crt_src==1; /* drop flag if records sourced from only non-court sources, but there should be court sourced records from the court in this time-period */
	replace drop_flag = 0 if any_court_src_grp==0; /* pre-emptively keep any ids that were edge cases from the data coverage file and only sourced from non-court records. Also captures singletons from non-court sourced. */

		/* sub-routine - every group should have a minimum drop flag of 0. If not, then they are an edge case, so keep all records associated with that observation. 
			In theory there should be no edge cases (option for assert here?) */
		bys group: egen min_drop_flag = min(drop_flag);
		replace drop_flag = 0 if min_drop_flag==1;
		
	drop if drop_flag==1;
	merge m:1 cjars_id using `ids', assert(3) nogen;
	drop group any_court_src any_court_src_grp non_crt_src drop_flag min_drop_flag;
	
	/* Date Uncoupling */
	foreach stem in file off sent disp{;
		gen adj_`stem'_dt_yyyy = year(`stem'_date);
		gen adj_`stem'_dt_mm = month(`stem'_date);
		gen adj_`stem'_dt_dd = day(`stem'_date);
		
		drop `stem'_date;
	};

	/* Any Quality Checks */
	assert substr(adj_disp_cd,1,1)=="G" if guilty==1;
	assert substr(adj_disp_cd,1,1)=="N" if not_guilty==1;
	assert substr(adj_disp_cd,1,1)=="D" if diversion==1;
	assert substr(adj_disp_cd,1,1)=="P" if procedural==1;
	assert substr(adj_disp_cd,1,1)=="U" if unknown==1;
	drop guilty not_guilty diversion procedural unknown;
	
	/* Final Cleaning, Ordering */
	order cjars_id book_id case_id adj_grd_cd adj_grd_cd_src adj_file_dt_yyyy adj_file_dt_mm adj_file_dt_dd 
		adj_chrg_off_cd adj_chrg_off_cd_src adj_disp_dt_yyyy adj_disp_dt_mm adj_disp_dt_dd adj_disp_cd adj_disp_cd_src 
		adj_disp_off_cd adj_disp_off_cd_src adj_off_dt_yyyy adj_off_dt_mm adj_off_dt_dd adj_sent_dt_yyyy adj_sent_dt_mm adj_sent_dt_dd 
		adj_sent_serv adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest adj_sent_sus adj_sent_trt adj_sent_fine adj_sent_src
		adj_sent_inc_min adj_sent_inc_max adj_st_ori_fips adj_cnty_ori_fips adj_off_lgl_cd adj_off_lgl_cd_src adj_rec_src_le 
		adj_rec_src_crt adj_rec_src_doc adj_rec_src_rep adj_rec_src_cc;
		
	foreach var of varlist _all{;
		label var `var' "";
	};
	
	duplicates drop;

end;
