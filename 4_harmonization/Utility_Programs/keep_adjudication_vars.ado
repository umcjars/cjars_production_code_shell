/*==============================================================================
Keep Adjudication Variables
===========================
Utility program for keeping standardized variables specified in CJARS schema. This 
program is invoked at the end of `clean_adjudication.do`.
==============================================================================*/
#delimit;
program define keep_adjudication_vars, rclass;
    /*Adjudication variables*/
	keep cjars_id book_id case_id
	adj_grd_cd
	adj_grd_cd_src
	adj_file_dt_yyyy
	adj_file_dt_mm
	adj_file_dt_dd
	adj_chrg_off_cd
	adj_chrg_off_cd_src
	adj_disp_dt_yyyy
	adj_disp_dt_mm
	adj_disp_dt_dd
	adj_disp_cd
	adj_disp_cd_src
	adj_disp_off_cd
	adj_disp_off_cd_src
	adj_off_dt_yyyy
	adj_off_dt_mm
	adj_off_dt_dd
	adj_sent_dt_yyyy
	adj_sent_dt_mm
	adj_sent_dt_dd
	adj_sent_serv
	adj_sent_dth
	adj_sent_inc
	adj_sent_pro
	adj_sent_rest
    adj_sent_sus
	adj_sent_trt
	adj_sent_fine
	adj_sent_src
	adj_sent_inc_min
	adj_sent_inc_max
	adj_st_ori_fips
	adj_cnty_ori_fips 
	adj_off_lgl_cd 
	adj_off_lgl_cd_src 
	adj_dv_off;
	order cjars_id book_id case_id;
end;
