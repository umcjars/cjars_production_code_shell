/*==============================================================================
names_standardized
==============================
Merge in standardized forms of names that are most likely nicknames

Output(s)
=========
- name_first
- name_middle
==============================================================================*/

#delimit;

program define names_standardized;


	merge m:1 name_first using "\\cjarsfs\data\pii\nickname.dta", nogen keep(master match) keepusing(name_first_standard);
	gen name_first_clean=name_first_standard;
	replace name_first_clean=name_first if name_first_clean=="";

	drop name_first_standard;

	merge m:1 name_middle using "\\cjarsfs\data\pii\nickname.dta", nogen keep(master match) keepusing(name_middle_standard);
	gen name_middle_clean=name_middle_standard;
	replace name_middle_clean=name_middle if name_middle_clean=="";
	
	drop name_middle_standard;
	
end;
