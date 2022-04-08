/*==============================================================================
Combine All-State
=================
Utility program for combining all of the state-specific combined files by stage. 
The program will generate final `combined_arrest.dta`, `combined_adjudication.dta`, 
`combined_incarceration.dta`, `combined_parole.dta`, and `combined_probation.dta` 
consisting of all of the states covered by CJARS data.
==============================================================================*/
#delimit;

program define all_state_combine, rclass;

    import delim "${codedir}/Dataset.csv", varn(1) delim(",");

	keep if active_use==1 & combine_run>0 & !missing(combine_run);

	
/*Note that this will require the user to get rid of the date in this column if it is supposed to be run*/

	levelsof state, local(state) clean;
	
	local combined="${anondir}/3_combined/All-States";
    
    tempfile combined_arrest combined_adjudication combined_incarceration combined_probation combined_parole;
    clear;
	gen_arrest_vars;
	save `combined_arrest', replace;
	clear;
	gen_adjudication_vars;
	save `combined_adjudication', replace;
	clear;
	gen_incarceration_vars;
	save `combined_incarceration', replace;
	clear;
	gen_probation_vars;
	save `combined_probation', replace;
	clear;
	gen_parole_vars;
	save `combined_parole', replace;
	clear;
	
	foreach st of local state{;
		display "Working on state: `st'";
		local state_combined="${anondir}/3_combined/`st'";
		foreach file in combined_arrest combined_adjudication combined_incarceration combined_probation combined_parole{;
		
			capture confirm file "`state_combined'//`file'.dta";
			local exist=_rc;
			if `exist'==0{;
				display "File `file' exists";
				use "`state_combined'//`file'.dta", replace;
				append using ``file'';
				save ``file'', replace;
			};
		};
	};
	
	
	foreach file in combined_arrest combined_adjudication combined_incarceration combined_probation combined_parole {;
		
		capture confirm file ``file'';
		
		if _rc==0{;
			use ``file'', replace;	
			save "`combined'/`file'.dta", replace;
		};
	};
    
	
end;
