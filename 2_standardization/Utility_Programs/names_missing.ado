/*==============================================================================
names_missing
==============================
Clears out names with common indicators for missingness - "john doe", "void", etc.

Output(s)
=========
- name_first
- name_middle
- name_last
==============================================================================*/

#delimit;

program define names_missing;
	
	tempvar john_doe jane_doe john jane null_first null_middle void_first void_middle void_last deceased_first deceased_last deceased_middle lnu fnu;
	
	gen `john_doe'=1 if name_first=="jonathan" & name_last=="doe";
	replace `john_doe'=1 if name_first=="john" & name_last=="doe";
	replace `john_doe'=1 if name_first=="jon" & name_last=="doe";
	replace `john_doe'=1 if name_first=="johnathan" & name_last=="doe";
	gen `jane_doe'=1 if name_first=="janet" & name_last=="doe";
	replace `jane_doe'=1 if name_first=="jane" & name_last=="doe";
	
	gen `john'=regexm(name_first, "(john)") if name_last=="doe";
	gen `jane'=regexm(name_first, "(jane)") if name_last=="doe";
	gen `null_first'=regexm(name_first, "^(null)");
	gen `null_middle'=regexm(name_middle, "^(null)");
	
	gen `void_first'=regexm(name_first, "^(void)");
	gen `void_middle'=regexm(name_middle, "^(void)");
	gen `void_last'=regexm(name_last, "^(void)");
	
	gen `lnu'=name_last=="lnu";
	gen `fnu'=name_first=="fnu";
	
	replace name_first="" if `john_doe'==1;
	replace name_last="" if `john_doe'==1;
	replace name_middle="" if `john_doe'==1;
	
	replace name_first="" if `jane_doe'==1;
	replace name_last="" if `jane_doe'==1;
	replace name_middle="" if `jane_doe'==1;
		
	replace name_first="" if `john'==1;
	replace name_last="" if `john'==1;
	replace name_middle="" if `john'==1;
	
	replace name_first="" if `jane'==1;
	replace name_last="" if `jane'==1;
	replace name_middle="" if `jane'==1;
	
	replace name_middle="" if `null_middle'==1;
	replace name_first="" if `null_first'==1;
	
	replace name_last="" if name_last=="null" & `null_first'==1;
	
	replace name_middle="" if `void_middle'==1;
	replace name_first="" if `void_first'==1;
	
	replace name_last="" if name_last=="void" & `void_first'==1;
	replace name_first="" if name_last=="void" & `void_first'==1;	
	
	replace name_last="" if name_last=="void" & name_first=="";	
	replace name_last="" if name_last=="void" & name_first=="ticket" | name_first=="tck";	
	replace name_first="" if name_last=="void" & name_first=="ticket" | name_first=="tck";
	
	replace name_last="" if `lnu'==1;
	replace name_first="" if `fnu'==1;

	
		
end;
