/*==============================================================================
Keep Probation Variables
========================
Utility program for keeping standardized variables specified in CJARS schema. This 
program is invoked at the end of `clean_probation.do`.
==============================================================================*/
#delimit;
program define keep_probation_vars, rclass;
	/*Probation variables*/
	keep cjars_id book_id case_id 
	pro_cond_cd
	pro_cond_cd_src
	pro_bgn_dt_yyyy
	pro_bgn_dt_mm
	pro_bgn_dt_dd
	pro_end_dt_yyyy
	pro_end_dt_mm
	pro_end_dt_dd
	pro_end_cd
	pro_end_cd_src
	pro_st_ori_fips
	pro_cnty_ori_fips 
	pro_st_juris_fips;
	order cjars_id book_id case_id;
end;
