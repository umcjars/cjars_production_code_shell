/*==============================================================================
Code for generating list of disposition descriptions that need to be reviewed 
and/or classified.
==============================================================================*/
#delimit;
capture program drop validate_disposition;
program define validate_disposition, rclass;
	syntax, dataset(string)[ desc(varname string) code(varname string)];
	
	local OUTPUT = "O:/output/disposition";
	capture confirm file "`OUTPUT'";
	if _rc {;
		shell mkdir "`OUTPUT'";
	};
	
	local xwalk_fname = subinstr("`dataset'", "/", "_", .);
	local disp_xwalk = "`OUTPUT'/`xwalk_fname'.dta";
	
	if "`desc'"!="" & "`code'"!="" {;
		preserve;
			keep disp_raw disp_code;
			replace disp_code = "" if inlist(disp_code, "UU");
			drop if !missing(disp_code);
			gen n = 1;
			collapse (count) n, by(disp_raw disp_code);
			qui count;
			if r(_N)>0 {;
				gsort -n disp_raw;
				save "`disp_xwalk'", replace;
			};
		restore;
		di "Review `disp_xwalk' and make sure disposition descriptions are coded correctly";
	};
	else {;
		di "No disposition information passed. Make sure to follow up with the data collection team!";
	};

end;
