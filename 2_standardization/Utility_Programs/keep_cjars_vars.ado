/******************************************************************************
	Program name:  keep_cjars_vars 
	Function	: drops all variables that are not cjars variables
	Arguments	: none
			
******************************************************************************/

#delimit;

program define keep_cjars_vars;
	keep record_id alias name_raw name_last name_first name_middle 
	name_suffix	name_middle_initial dob_dd dob_mm dob_yyyy sex_raw race_raw birth_loc_city
	birth_loc_st birth_loc_ctry birth_loc_foreign state_id state_id_ori
	county_id county_id_ori	agency_id agency_id_ori ssn ssn_4 fbi_num addr_raw 
	addr_bldnum	addr_str addr_city addr_st addr_zip addr_ctry;

end;