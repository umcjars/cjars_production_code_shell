/*==============================================================================
Parole Variables
================
Utility program for generating standardized parole variables in CJARS 
schema. These variables are filled in during harmonization stage via 
`clean_parole.do` files for each relevant dataset.

Output(s)
=========
- par_bgn_dt_yyyy:		Year of parole start date
- par_bgn_dt_mm:		Month of parole start date
- par_bgn_dt_dd:		Day of parole start date
- par_end_dt_yyyy:		Year of parole end date
- par_end_dt_mm:		Month of parole end date
- par end_dt_dd:		Day of parole end date
- par_end_cd:			Standardized parole exit description
- par_end_cd_src:		Raw parole exit description
- par_st_ori_fips:		Convicted State FIPS code
- par_cnty_ori_fips:	Convicted County FIPS code
- par_st_juris_fips:	Source State FIPS code
- book_id:				Booking number
- case_id:				Case number
==============================================================================*/
#delimit;
program define gen_parole_vars, rclass;
	/*Parole*/
	gen int par_bgn_dt_yyyy=.;
	gen byte par_bgn_dt_mm=.;
	gen byte par_bgn_dt_dd=.;
	gen int par_end_dt_yyyy=.;
	gen byte par_end_dt_mm=.;
	gen byte par_end_dt_dd=.;
	gen par_end_cd="";
	gen par_end_cd_src="";
	gen par_st_ori_fips="";
	gen par_cnty_ori_fips="";
	gen par_st_juris_fips="";
	gen book_id="";
	gen case_id="";
end;
