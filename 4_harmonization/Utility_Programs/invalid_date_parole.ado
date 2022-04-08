/*==============================================================================
Invalid Parole Date
===================
Utility program for logical validation of parole date variables. Dates set 
later than data intake date are set to missing (e.g. arrest date that takes place later 
than the data intake date is set to missing). In addition, the program updates 
standardized code values (`*_cd`) to unknown values if the raw description 
(`*_cd_src`) is missing as well as to truncate raw descriptions to 30 characters 
to reduce the size of harmonized files.
==============================================================================*/
#delimit;
program define invalid_date_parole;
	local data="`1'";
	local last=strrpos("`data'", "/");
	if `last' == 0{;
		local last=strrpos("`data'", "\");
	};	
	local date_temp=substr("`data'",`last',.);
	if regexm("`date_temp'", "([0-9]+)") local date=regexs(1);
	local st_date=date("`date'", "YMD");

	/* Invalid Date Adjustment */
	foreach stub in par_bgn par_end {;
		quietly count if `stub'_dt_dd!=.;
		if r(N)>0 {;
			quietly count if mdy(`stub'_dt_mm,`stub'_dt_dd,`stub'_dt_yyyy)>(`st_date') & !missing(`stub'_dt_dd);
			local count=r(N);
			local j=1;
			if r(N)>0{;
				if `j'==1{;
					file open myfile using "${codedir}\4_harmonization\1_prepared\\`data'\\invalid_date_par.txt", write replace;
					file write myfile "variable,count_invalid"_n;
					file close myfile;
				};
				file open myfile using "${codedir}\4_harmonization\1_prepared\\`data'\\invalid_date_par.txt", write append;
				file write myfile "`stub',`count'"_n;
				file close myfile;
				local j=`j'+1;

				tempvar date;
				gen `date'=mdy(`stub'_dt_mm,`stub'_dt_dd,`stub'_dt_yyyy);
				replace `stub'_dt_mm=. if `date'>`st_date';
				replace `stub'_dt_yyyy=. if `date'>`st_date';
				replace `stub'_dt_dd=. if `date'>`st_date';
				drop `date';

			};
		};
	};
	
	/* _src truncation */
	foreach var of varlist *_src{;
		replace `var' = substr(`var', 1, 30);
	};
	compress *_src;

	/* Recoding _cd variables with "UU" if it is missing */
	foreach var of varlist *_cd{;
		if "`var'"=="adj_chrg_off_cd" | "`var'"=="adj_disp_off_cd" | "`var'"=="arr_off_cd"{;
			replace `var'="999" if `var'=="";
		};
		else{;
			replace `var'="UU" if `var'=="";
		};
	};
	
end;
