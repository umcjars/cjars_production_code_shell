/*==============================================================================
Adjudication Variables
======================
Utility program for generating standardized adjudication variables in CJARS 
schema. These variables are filled in during harmonization stage via 
`clean_adjudication.do` files for each relevant dataset.

Output(s)
=========
- adj_grd_cd:			Standardized offense grade
- adj_grd_cd_src:		Raw offense grade description
- adj_file_dt_yyyy:		Year of case file date
- adj_file_dt_mm:		Month of case file date
- adj_file_dt_dd:		Day of case file date
- adj_chrg_off_cd:		4-digit UCCCS code for charge
- adj_chrg_off_cd_src:	Raw charge description
- adj_disp_dt_yyyy:		Year of disposition date
- adj_disp_dt_mm:		Month of disposition date
- adj_disp_dt_dd:		Day of disposition date
- adj_disp_cd:			Standardized disposition outcome code
- adj_disp_cd_src:		Raw disposition outcomde
- adj_disp_off_cd:		4-digit UCCS code for offense
- adj_disp_off_cd_src:	Raw offense description
- adj_off_dt_yyyy:		Year of offense date
- adj_off_dt_mm:		Month of offense date
- adj_off_dt_dd:		Day of offense date
- adj_sent_dt_yyyy:		Year of sentence date
- adj_sent_dt_mm:		Month of sentence date
- adj_sent_dt_dd:		Day of sentence date
- adj_sent_serv:		Community service sentence
- adj_sent_dth:			Death sentence
- adj_sent_inc:			Length of incarceration (months)
- adj_sent_pro:			Length of probation (months)
- adj_sent_rest:		Restitution amount
- adj_sent_sus:			Suspended sentence
- adj_sent_trt:			Treatment sentence
- adj_sent_fine:		Fine amount
- adj_sent_src:			Raw sentence description
- adj_sent_inc_min:		Minimum incarceration sentence length (months)
- adj_sent_inc_max:		Maximum incarceration sentence length (months)
- adj_st_ori_fips:		Convicted State FIPS code
- adj_cnty_ori_fips:	Convicted County FIPS code
- book_id:				Booking number
- case_id:				Caser number
- adj_off_lgl_cd:		Standardized offense legal code
- adj_off_lgl_cd_src:	Raw offense legal description
- adj_dv_off:			Domestic violence indicator
==============================================================================*/
#delimit;
program define gen_adjudication_vars, rclass;
	/*Adjudication variables*/
	gen adj_grd_cd="";
	gen adj_grd_cd_src="";
	gen int adj_file_dt_yyyy=.;
	gen byte adj_file_dt_mm=.;
	gen byte adj_file_dt_dd=.;
	gen adj_chrg_off_cd="";
	gen adj_chrg_off_cd_src="";
	gen int adj_disp_dt_yyyy=.;
	gen byte adj_disp_dt_mm=.;
	gen byte adj_disp_dt_dd=.;
	gen adj_disp_cd="";
	gen adj_disp_cd_src="";
	gen adj_disp_off_cd="";
	gen adj_disp_off_cd_src="";
	gen int adj_off_dt_yyyy=.;
	gen byte adj_off_dt_mm=.;
	gen byte adj_off_dt_dd=.;
	gen int adj_sent_dt_yyyy=.;
	gen byte adj_sent_dt_mm=.;
	gen byte adj_sent_dt_dd=.;
	gen byte adj_sent_serv=.;
	gen byte adj_sent_dth=.;
	gen byte adj_sent_inc=.;
	gen byte adj_sent_pro=.;
	gen byte adj_sent_rest=.;
    gen byte adj_sent_sus=.;
	gen byte adj_sent_trt=.;
	gen byte adj_sent_fine=.;
	gen adj_sent_src="";
	gen byte adj_sent_inc_min=.;
	gen byte adj_sent_inc_max=.;
	gen adj_st_ori_fips="";
	gen adj_cnty_ori_fips="";
	gen book_id="";
	gen case_id="";
	gen adj_off_lgl_cd="";
	gen adj_off_lgl_cd_src="";
	gen adj_dv_off=.;
end;
