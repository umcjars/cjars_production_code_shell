/*==============================================================================
Incarceration Variables
=======================
Utility program for generating standardized incarceration variables in CJARS 
schema. These variables are filled in during harmonization stage via 
`clean_incarceration.do` files for each relevant dataset.

Output(s)
=========
- inc_fcl_cd:			Standardized facility code
- inc_fcl_cd_src:		Raw facility level description
- inc_entry_dt_yyyy:	Year of incarceration start date
- inc_entry_dt_mm:		Month of incarceration start date
- inc_entry_dt_dd:		Day of incarceration start date
- inc_entry_cd:			Standardized incarceration entry description
- inc_entry_cd_src:		Raw incarceration entry description
- inc_exit_cd:			Standardized incarceration exit description
- inc_exit_cd_src:		Raw incarceration exit description
- inc_st_ori_fips:		Convicted State FIPS code
- inc_cnty_ori_fips:	Convicted County FIPS code
- inc_st_juris_fips:	Source State FIPS code
- book_id:				Booking number
- case_id:				Case number
==============================================================================*/
#delimit;
program define gen_incarceration_vars, rclass;	
	/*Incarceration variables*/
	gen inc_fcl_cd="";
	gen inc_fcl_cd_src="";
	gen int inc_entry_dt_yyyy=.;
	gen byte inc_entry_dt_mm=.;
	gen byte inc_entry_dt_dd=.;
	gen inc_entry_cd="";
	gen inc_entry_cd_src="";
	gen int inc_exit_dt_yyyy=.;
	gen byte inc_exit_dt_mm=.;
	gen byte inc_exit_dt_dd=.;
	gen inc_exit_cd="";
	gen inc_exit_cd_src="";
	gen inc_st_ori_fips="";
	gen inc_cnty_ori_fips="";
	gen inc_st_juris_fips="";
	gen book_id="";
	gen case_id="";
end;
