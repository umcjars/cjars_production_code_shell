/*==============================================================================
Arrest Variables
================
Utility program for generating standardized arrest variables in CJARS 
schema. These variables are filled in during harmonization stage via 
`clean_arrest.do` files for each relevant dataset.

Output(s)
=========
- arr_arr_dt_yyyy:			Year of arrest date
- arr_arr_dt_mm:			Month of arrest date
- arr_arr_dt_dd:			Day of arrest date
- arr_book_dt_yyyy:			Year of booking date
- arr_book_dt_mm:			Month of booking date
- arr_book_dt_dd:			Day of booking date
- arr_off_cd:				4-digit UCCS code for arrested charge
- arr_off_cd_src:			Raw charge description
- arr_st_ori_fips:			Convicted State FIPS code
- arr_cnty_ori_fips:		Convicted County FIPS code
- book_id:					Booking number
- case_id:					Case number
- arr_dv_off:				Domestic violence indicator
==============================================================================*/
#delimit;
program define gen_arrest_vars, rclass;
	/*Arrest and booking variables*/
	gen int arr_arr_dt_yyyy=.;
	gen byte arr_arr_dt_mm=.;
	gen byte arr_arr_dt_dd=.;
	gen int arr_book_dt_yyyy=.;
	gen byte arr_book_dt_mm=.;
	gen byte arr_book_dt_dd=.;
	gen arr_off_cd="";
	gen arr_off_cd_src="";
	gen arr_st_ori_fips="";
	gen arr_cnty_ori_fips="";
	gen book_id="";
	gen case_id="";
	gen arr_dv_off=.;
end;
