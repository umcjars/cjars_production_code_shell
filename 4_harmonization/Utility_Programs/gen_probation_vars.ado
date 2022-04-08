/*==============================================================================
Probation Variables
===================
Utility program for generating standardized probation variables in CJARS 
schema. These variables are filled in during harmonization stage via 
`clean_probation.do` files for each relevant dataset.

Output(s)
=========
- pro_cond_cd:			Standardized probation condition code
- pro_cond_cd_src:		Raw probation condition description
- pro_bgn_dt_yyyy:		Year of probation start date
- pro_bgn_dt_mm:		Month of probation start date
- pro_bgn_dt_dd:		Day of probation start date
- pro_end_dt_yyyy:		Year of probation end date
- pro_end_dt_mm:		Month of probation end date
- pro_end_dt_dd:		Day of probation end date
- pro_end_cd:			Standardized probation end condition code
- pro_end_cd_src:		Raw probation end condition description
- pro_st_ori_fips:		Convicted State FIPS code
- pro_cnty_ori_fips:	Convicted County FIPS code
- pro_st_juris_fips:	Source State FIPS code
- book_id:				Booking number
- case_id:				Case number
==============================================================================*/
#delimit;
program define gen_probation_vars, rclass;	
	/*Probation variables*/
	gen pro_cond_cd="";
	gen pro_cond_cd_src="";
	gen int pro_bgn_dt_yyyy=.;
	gen byte pro_bgn_dt_mm=.;
	gen byte pro_bgn_dt_dd=.;
	gen int pro_end_dt_yyyy=.;
	gen byte pro_end_dt_mm=.;
	gen byte pro_end_dt_dd=.;
	gen pro_end_cd="";
	gen pro_end_cd_src="";
	gen pro_st_ori_fips="";
	gen pro_cnty_ori_fips="";
	gen pro_st_juris_fips="";
	gen book_id="";
	gen case_id="";
end;
