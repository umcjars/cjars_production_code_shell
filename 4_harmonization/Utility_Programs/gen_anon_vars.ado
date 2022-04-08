/******************************************************************************
	Program name: gen_anon_vars  
	Function	: Generates the CJARS variables when cleaning anon data
	Arguments	: No arguments
			
******************************************************************************/
#delimit;
program define gen_anon_vars, rclass;
	/*Arrest and booking variables*/
	gen UArN="";
	gen IPN="";
	gen int arr_arr_dt_yyyy=.;
	gen byte arr_arr_dt_mm=.;
	gen byte arr_arr_dt_dd=.;
	gen int arr_book_dt_yyyy=.;
	gen byte arr_book_dt_mm=.;
	gen byte arr_book_dt_dd=.;
	gen arr_off_cd="";
	gen arr_off_cd_src="";
	gen arr_off_cd_src_fmt="";
	
	/*Adjudication variables*/
	
	gen UCN="";
	gen UAN="";
	gen ptsa_grd_cd="";
	gen ptsa_grd_cd_src="";
	gen ptsa_grd_cd_src_fmt="";
	gen int ptsa_file_dt_yyyy=.;
	gen byte ptsa_file_dt_mm=.;
	gen byte ptsa_file_dt_dd=.;
	gen ptsa_chrg_off_cd="";
	gen ptsa_chrg_off_cd_src="";
	gen ptsa_chrg_off_cd_src_fmt="";
	gen int ptsa_disp_dt_yyyy=.;
	gen byte ptsa_disp_dt_mm=.;
	gen byte ptsa_disp_dt_dd=.;
	gen ptsa_disp_cd="";
	gen ptsa_disp_cd_src="";
	gen ptsa_disp_cd_src_fmt="";
	gen ptsa_disp_off_cd="";
	gen ptsa_disp_off_cd_src="";
	gen ptsa_disp_off_cd_src_fmt="";
	gen int ptsa_sent_dt_yyyy=.;
	gen byte ptsa_sent_dt_mm=.;
	gen byte ptsa_sent_dt_dd=.;
	gen byte ptsa_sent_cd_serv=.;
	gen byte ptsa_sent_cd_dth=.;
	gen byte ptsa_sent_cd_dadj=.;
	gen byte ptsa_sent_cd_fine=.;
	gen byte ptsa_sent_cd_inc=.;
	gen byte ptsa_sent_cd_pdiv=.;
	gen byte ptsa_sent_cd_pro=.;
	gen byte ptsa_sent_cd_rest=.;
	gen byte ptsa_sent_cd_sus=.;
	gen byte ptsa_sent_cd_trt=.;
	gen ptsa_sent_cd_src="";
	gen ptsa_sent_cd_src_fmt="";
	gen ptsa_sent_fine="";
	gen ptsa_sent_inc_min="";
	gen ptsa_sent_inc_max="";
	gen ptsa_sent_prob_min="";
	gen ptsa_sent_prob_max="";
	
	/*Incarceration variables*/
	
	gen UISN="";
	gen inc_fcl_cd="";
	gen inc_fcl_cd_src="";
	gen inc_fcl_cd_src_fmt="";
	gen int inc_entry_dt_yyyy=.;
	gen byte inc_entry_dt_mm=.;
	gen byte inc_entry_dt_dd=.;
	gen inc_entry_cd="";
	gen inc_entry_cd_src="";
	gen inc_entry_cd_src_fmt="";
	gen int inc_exit_dt_yyyy=.;
	gen byte inc_exit_dt_mm=.;
	gen byte inc_exit_dt_dd=.;
	gen inc_exit_cd="";
	gen inc_exit_cd_src="";
	gen inc_exit_cd_src_fmt="";

	/*Probation variables*/
	gen UPrSN="";
	gen pro_cond_cd="";
	gen pro_cond_cd_src="";
	gen pro_cond_cd_src_fmt="";
	gen int pro_bgn_dt_yyyy=.;
	gen byte pro_bgn_dt_mm=.;
	gen byte pro_bgn_dt_dd=.;
	gen pro_bgn_cd="";
	gen pro_bgn_cd_src="";
	gen pro_bgn_cd_src_fmt="";	
	gen int pro_end_dt_yyyy=.;
	gen byte pro_end_dt_mm=.;
	gen byte pro_end_dt_dd=.;
	gen pro_end_cd="";
	gen pro_end_cd_src="";
	gen pro_end_cd_src_fmt="";
	
	/*Parole*/
	gen UPaSN="";
	gen int par_bgn_dt_yyyy=.;
	gen byte par_bgn_dt_mm=.;
	gen byte par_bgn_dt_dd=.;
	gen int par_end_dt_yyyy=.;
	gen byte par_end_dt_mm=.;
	gen byte par_end_dt_dd=.;
	gen par_end_cd="";
	gen par_end_cd_src="";
	gen par_end_cd_src_fmt="";
	
end;
