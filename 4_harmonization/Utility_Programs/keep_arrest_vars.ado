/*==============================================================================
Keep Arrest Variables
=====================
Utility program for keeping standardized variables specified in CJARS schema. This 
program is invoked at the end of `clean_arrest.do`.
==============================================================================*/
#delimit;
program define keep_arrest_vars, rclass;
	/*Arrest and booking variables*/
    keep cjars_id book_id case_id 
	arr_arr_dt_yyyy 
	arr_arr_dt_mm 
	arr_arr_dt_dd 
	arr_book_dt_yyyy 
	arr_book_dt_mm 
	arr_book_dt_dd 
	arr_off_cd 
	arr_off_cd_src 
	arr_dv_off 
	arr_st_ori_fips 
	arr_cnty_ori_fips;
	order cjars_id book_id case_id;
end;
