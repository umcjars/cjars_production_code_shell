/*==============================================================================
Offense Grade Classification
============================
Utility program for coding charge grade/level descriptions to the standardized 
CJARS values ("FE" for felonies, "MI" for misdemeanors, and "UU" for unknown). 
If `classify_offense.ado` is invoked with the `grade` argument, this program 
overwrites imputed values set by universal felony and misdemeanor charge codes.

Output(s)
=========
- grade:			Standardized charge grade ("FE", "MI", "UU")
==============================================================================*/
#delimit;
capture program drop classify_grade;
program define classify_grade, rclass;
	syntax, state(string);
	
	capture confirm variable grade, exact;
	if !_rc {;
		drop grade;
		gen grade = "";
	};
	else {;
		gen grade = "";
	};
	
	replace grade_raw = strtrim(stritrim(lower(grade_raw)));
	
	order state_code state_description grade_raw grade;
	
	/*
		Code containing state-specific data values redacted
	*/
	
	replace grade = "FE" if missing(grade) & inlist(grade_raw, "fel");
	replace grade = "MI" if missing(grade) & inlist(grade_raw, "misd");
	
	replace grade = "UU" if missing(grade);

end;
