/*==============================================================================
Invalid Adjudication Date
=========================
Utility program for logical validation of adjudication date variables. Dates set 
later than data intake date are set to missing (e.g. file date takes place later 
than the data intake date is set to missing). In addition, the program updates 
standardized code values (`*_cd`) to unknown values if the raw description 
(`*_cd_src`) is missing as well as to truncate raw descriptions to 30 characters 
to reduce the size of harmonized files. Finally, this program sets an upper limit 
value for numerical variables such as fine amount (`adj_sent_fine`) and restitution 
(`adj_sent_rest`).
==============================================================================*/
#delimit;
program define invalid_date_adjudication;
	local data="`1'";
	local last=strrpos("`data'", "/");
	if `last' == 0{;
		local last=strrpos("`data'", "\");
	};
	local date_temp=substr("`data'",`last',.);
	if regexm("`date_temp'", "([0-9]+)") local date=regexs(1);
	local st_date=date("`date'", "YMD");

	/* Invalid Date Adjustment */
	foreach stub in adj_file adj_disp adj_sent adj_off {;
		quietly count if `stub'_dt_dd!=.;
		if r(N)>0 {;
			quietly count if mdy(`stub'_dt_mm,`stub'_dt_dd,`stub'_dt_yyyy)>(`st_date') & !missing(`stub'_dt_dd);
			local count=r(N);
			local j=1;
			if r(N)>0{;
				if `j'==1{;
					file open myfile using "${codedir}\4_harmonization\1_prepared\\`data'\\invalid_date_adj.txt", write replace;
					file write myfile "variable,count_invalid"_n;
					file close myfile;
				};
				file open myfile using "${codedir}\4_harmonization\1_prepared\\`data'\\invalid_date_adj.txt", write append;
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
	/* Recoding _cd variables with "UU" if it is missing */
	foreach var of varlist *_cd{;
		if "`var'"=="adj_chrg_off_cd" | "`var'"=="adj_disp_off_cd" | "`var'"=="arr_off_cd"{;
			replace `var'="9999" if `var'=="";
		};
		else{;
			replace `var'="UU" if `var'=="";
		};
	};
	
	/* _src truncation */
	foreach var of varlist *_src{;
		replace `var' = substr(`var', 1, 30);
	};
	compress *_src;
	
	/* Value topcoding */
	replace adj_sent_pro 		= 120		if adj_sent_pro 	> 120 		& adj_sent_pro != .; 		//  10   year probation cap
	replace adj_sent_inc 		= 1200 		if adj_sent_inc 	> 1200 		& adj_sent_inc != .;		//  100 year incarceration cap
	replace adj_sent_inc_min 	= 1200 		if adj_sent_inc_min > 1200 		& adj_sent_inc_min != .;	//  100 year incarceration cap
	replace adj_sent_inc_max 	= 1200 		if adj_sent_inc_max > 1200 		& adj_sent_inc_max != .;	//  100 year incarceration cap
	replace adj_sent_fine 		= 500000 	if adj_sent_fine 	> 500000 	& adj_sent_fine != .;		//  $500,000 fine cap
	replace adj_sent_fine 		= -500000 	if adj_sent_fine 	< -500000 	& adj_sent_fine != .;		// -$500,000 fine floor
	replace adj_sent_rest 		= 500000 	if adj_sent_rest 	> 500000 	& adj_sent_rest != .;		//  $500,000 restitution cap
	replace adj_sent_rest 		= 0 		if adj_sent_rest 	< -0 		& adj_sent_rest != .;		//   cannot be assigne a negative restitution value

	/* Conviction recoding when we have a missing disposition but sentencing information */
	replace adj_disp_cd_src = "CONV. IMPLD FROM SENT. INFO"	if inlist(adj_disp_cd, "PU", "UU") == 1 & ((adj_sent_pro > 0 & adj_sent_pro != .) | (adj_sent_inc > 0 & adj_sent_inc != .) | (adj_sent_fine > 0 & adj_sent_fine != .) | adj_sent_dt_yyyy != .);
	replace adj_disp_cd 	= "GU"		if inlist(adj_disp_cd, "PU", "UU") == 1 & ((adj_sent_pro > 0 & adj_sent_pro != .) | (adj_sent_inc > 0 & adj_sent_inc != .) | (adj_sent_fine > 0 & adj_sent_fine != .));
	
end;
