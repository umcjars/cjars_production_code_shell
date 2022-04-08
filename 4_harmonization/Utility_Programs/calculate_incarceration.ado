/*==============================================================================
Calculate Incarceration Length
==============================
Utility program for calculating incarceration length in cleaned adjudication 
data. User must create at least 3 variables for length of (i) years, (ii), months, 
and (iii) days with optional arguments to pass in indicator variables for DEATH 
and LIFE sentences (1==True, 0==False) as well as hours.

Output(s)
=========
- sent_len_inc:			Incarceration length in months
==============================================================================*/
#delimit;
capture program drop calculate_incarceration;
program define calculate_incarceration, rclass;
	syntax, yr(name) mo(name) da(name)[ hr(name) dth(name) lfe(name)];
	
	/* Generate temporary variable for hours which gets dropped at the end - set to missing if not specified */
	if "`hr'"=="" {;
		gen hr = .;
	};
	else {;
		gen hr = `hr';
	};
	
	destring `yr' `mo' `da' hr, replace;
	
	/* Generate indicator variable for missing incarceration information */
	tempvar missing_inc;
	gen `missing_inc' = missing(`yr') & missing(`mo') & missing(`da') & missing(hr);
	
	/* Set missing values to 0 for calculating total length */
	foreach var in `yr' `mo' `da' hr {;
		replace `var' = 0 if missing(`var');
	};
	
	/* Calculate incarceration length in months */
	gen sent_len_inc = ((`yr'*365)+(`mo'*30.25)+`da'+(hr/24))/30.25;
	
	/* Reset missing sentence terms from 0 to . */
	replace sent_len_inc = . if `missing_inc'==1;
	
	/* Set Death & Life Sentences */
	if "`lfe'"!="" {;
		replace sent_len_inc = -88888 if `lfe'==1;
	};
	if "`dth'"!="" {;
		replace sent_len_inc = -99999 if `dth'==1;
	};
	drop hr;
end;
