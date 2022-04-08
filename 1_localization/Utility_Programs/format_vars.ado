/*==============================================================================
Format variables
==============================
Set all of the variable names to upper case

==============================================================================*/
#delimit;
capture program drop format_vars;
program define format_vars, rclass;

	qui desc, varlist;
	local variables `r(varlist)';
	foreach var in `variables' {;
		capture confirm string variable `var';
		if !_rc {;
			replace `var' = strtrim(stritrim(`var'));
			compress `var';
		};
		local new_var = strupper("`var'");
		rename `var' `new_var';
	};

end;
