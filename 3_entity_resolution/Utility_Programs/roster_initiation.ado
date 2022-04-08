#delimit;

program define roster_initiation, eclass;
	syntax anything(name=dataset_id);
	
local state=substr("`dataset_id'", 1,2);
	
capture confirm file "${rosterdir}/cjars_roster_`state'.dta";
		
if _rc!=0 {;
	display "Roster does not exist";
	drop record_id;
	duplicates drop;
	gen long cjars_id = canon_id;
	format cjars_id %12.0f;
	tostring cjars_id, replace;
	replace cjars_id="`state'"+cjars_id;
	drop canon_id;

	gen length=length(subinstr(cjars_id,"`state'","",.));
	quietly su length, d;
	local len=r(max);
	tempvar cjars_id_num;
	destring cjars_id, gen(`cjars_id_num') ignore("`state'");			
	replace cjars_id="`state'"+string(`cjars_id_num', "%0`len'.0f");
	drop length `cjars_id_num';
	save "${rosterdir}/cjars_roster_`state'.dta";
};

end;
