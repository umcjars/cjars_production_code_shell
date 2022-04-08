/*==============================================================================
Keep Incarceration Variables
============================
Utility program for keeping standardized variables specified in CJARS schema. This 
program is invoked at the end of `clean_incarceration.do`.
==============================================================================*/
#delimit;
program define keep_incarceration_vars, rclass;
	/*Incarceration variables*/
	keep cjars_id book_id case_id 
	 inc_fcl_cd
	 inc_fcl_cd_src
	 inc_entry_dt_yyyy
	 inc_entry_dt_mm
	 inc_entry_dt_dd
	 inc_entry_cd
	 inc_entry_cd_src
	 inc_exit_dt_yyyy
	 inc_exit_dt_mm
	 inc_exit_dt_dd
	 inc_exit_cd
	 inc_exit_cd_src
	 inc_st_ori_fips
	 inc_cnty_ori_fips 
	 inc_st_juris_fips;
	 order cjars_id book_id case_id;
end;
