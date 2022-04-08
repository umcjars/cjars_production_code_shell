/*==============================================================================
Keep Parole Variables
=====================
Utility program for keeping standardized variables specified in CJARS schema. This 
program is invoked at the end of `clean_parole.do`.
==============================================================================*/
#delimit;
program define keep_parole_vars, rclass;
	/*Parole variables*/
	keep cjars_id book_id case_id 
	par_bgn_dt_yyyy
	par_bgn_dt_mm
	par_bgn_dt_dd
	par_end_dt_yyyy
	par_end_dt_mm
	par_end_dt_dd
	par_end_cd
	par_end_cd_src
	par_st_ori_fips
	par_cnty_ori_fips 
	par_st_juris_fips;
	order cjars_id book_id case_id;
end;
