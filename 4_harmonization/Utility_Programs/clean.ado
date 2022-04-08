/*==============================================================================
Clean Variable for Harmonization
--------------------------------
Utility program for cleaning data values. Optional parameters can be passed for 
list of string variables to remove punctuation marks and spaces. Otherwise, the 
program will remove leading and trailing spaces, collapse contiguous spaces into 
one, and lowercase all of the letters in the string. Numeric variables can also 
be formatted to avoid displaying the data using scientific notation. Lastly, date 
variables can be passed in as optional argument to convert from an integer 
to "Month Day, Year" format in display mode.

Output(s)
=========
- None
==============================================================================*/
#delimit;
capture program drop clean;
program define clean, rclass;
	syntax varlist(min=1) [if] [in] [, NOPunct(varlist) NOSpace(varlist) DATevars(varlist)];
	local ALL_PUNCT = "`~!@#$%^&*()_-+=/\|]}[{;:/?.>,<";
	
	/* Strip punctuation */
	if "`nopunct'"!="" {;
		foreach var in `nopunct' {;
			local p_len = strlen("`ALL_PUNCT'");
			if `p_len'>0 {;
				forval i=1/`p_len' {;
					local p = substr("`ALL_PUNCT'", `i', 1);
					qui replace `var' = subinstr(`var', "`p'", "", .);
				};
				qui replace `var' = subinstr(`var', `"""', "", .);
			};
			qui replace `var' = strtrim(stritrim(`var'));
		};
	};
	
	
	/* Loop Through Variables */
	foreach var in `varlist' {;
		/* Clean STRING */
		capture confirm string variable `var';
		if !_rc {;
			/* Standardize */
			replace `var' = strtrim(lower(stritrim(`var')));
			tempvar len;
			gen `len' = strlen(`var');
			qui su `len';
			local max `r(max)';
			if `max'>0 {;
				recast str`max' `var';
			};
			compress `var';
		};
		
		/* Clean NUMERIC */
		capture confirm numeric variable `var';
		if !_rc {;
			format `var' %15.2fc;
		};
	};
	
	/* Strip Space if in `nospace' */
	foreach v in `nospace' {;
		replace `v' = subinstr(`v', " ", "", .);
		replace `v' = strtrim(`v');
		compress `v';
	};
	
	/* Clean Date Variable */
	foreach v in `datevars' {;
		format `v' %dM_d,_CY;
	};
	
end;
