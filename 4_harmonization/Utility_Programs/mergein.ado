/*==============================================================================
Merge in Specific Variables from Formatted Data
===============================================
Utility program for merging in specific variable(s) from formatted file to 
anonymized file. This program is primarily used (i) to validate uniqueness of 
`cjars_id` for a given identifier (e.g. Department of Corrections Offender Number) 
and (ii) to ensure precise merges for relational data tables.
==============================================================================*/
#delimit;
capture program drop mergein;
program define mergein, rclass;
	syntax namelist(min=1), stub(string) file(string);
	
	local dataset_id = subinstr("`stub'", "\", "/", .);
	local FORMATTED = "O:/original/formatted/`dataset_id'";
	
	merge 1:1 record_id using "`FORMATTED'/`file'", nogen keep(matched master) keepusing(`namelist');
	
end;
