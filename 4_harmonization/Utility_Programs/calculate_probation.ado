/*==============================================================================
Calculate Probation Length
==========================
Utility program for calculating probation length in cleaned adjudication 
data. User must create at least 3 variables for length of (i) years, (ii), months, 
and (iii) days with optional argument for hours.

Output(s)
=========
- sent_len_pro:			Probation length in months
==============================================================================*/
#delimit;
capture program drop calculate_probation;
program define calculate_probation, rclass;
	syntax, yr(name) mo(name) da(name)[ hr(name)];
	
	/* Generate temporary variable for hours which gets dropped at the end - set to missing if not specified */
	if "`hr'"=="" {;
		gen hr = .;
	};
	else {;
		gen hr = `hr';
	};
	
	destring `yr' `mo' `da' hr, replace;
	/* Generate indicator variable for missing probation information */
	tempvar missing_pro;
	gen `missing_pro' = missing(`yr') & missing(`mo') & missing(`da') & missing(hr);
	
	/* Set missing values to 0 for calculating total length */
	foreach var in `yr' `mo' `da' hr {;
		replace `var' = 0 if missing(`var');
	};
	
	/* Calculate probation length in months */
	gen sent_len_pro = ((`yr'*365)+(`mo'*30.25)+`da'+(hr/24))/30.25;
	
	/* Reset missing sentence terms from 0 to . */
	replace sent_len_pro = . if `missing_pro'==1;
	drop hr;
	
end;
