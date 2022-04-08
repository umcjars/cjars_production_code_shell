/******************************************************************************
	Program name: gen_cjars_vars  
	Function	: Generates the CJARS variables when cleaning PII
	Arguments	: No arguments
			
******************************************************************************/


#delimit;

program define gen_cjars_vars, rclass;

	gen byte alias=.;
	gen name_raw="";
	gen name_last="";
	gen name_first="";
	gen name_middle="";
	gen name_suffix="";
	gen name_middle_initial="";

	gen int dob_dd=.;
	gen int dob_mm=.;
	gen int dob_yyyy=.;

	gen birth_loc_city="";
	gen birth_loc_st="";
	gen birth_loc_ctry="";
	gen byte birth_loc_foreign=.;

	gen byte sex_raw=.;	
	gen byte race_raw=.;
	
	gen state_id ="";
	gen state_id_ori="";
	gen county_id ="";
	gen county_id_ori="";
	gen agency_id="";
	gen agency_id_ori="";
	gen ssn="";
	gen ssn_4="";
	gen fbi_num="";
	gen addr_raw="";
	gen addr_bldnum="";
	gen addr_str="";
	gen addr_city="";
	gen addr_st="";
	gen addr_zip="";
	gen addr_ctry="";


    
    

end;
