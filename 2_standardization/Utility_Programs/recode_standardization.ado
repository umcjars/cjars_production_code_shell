/******************************************************************************
	Program name:  recode_standardization 
	Function	: Applies uniform recoding decisions across all standardized pii files
	Arguments	: none
			
******************************************************************************/

#delimit;

program define recode_standardization;

	foreach var in name_last name_first name_middle name_first_clean name_middle_clean name_suffix name_middle_initial addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry{;
		replace `var' = substr(`var',1,30) if length(`var')>30;
	};
	replace addr_raw = substr(addr_raw,1,150) if length(addr_raw)>150;
	replace name_raw = substr(name_raw,1,100) if length(name_raw)>100;
	
end;