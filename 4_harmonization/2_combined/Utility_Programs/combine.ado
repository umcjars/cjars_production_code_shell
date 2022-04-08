/*==============================================================================
Combine Within State
====================
Utility program that is called in line 62 of the combine.do script
for combining harmonized datasets by state. The program first 
creates empty temporary files for arrest, adjudication, incarceration, parole, 
and probation using `gen_*_vars.ado` function. Afterwards, the program will loop 
through all of the active datasets and check for `cleaned_*.dta` file(s) in the 
cleaned output folder. If `cleaned_*.dta` file(s) exist, these are appended to the 
temporary files initially created. If not, the program continues to the next dataset 
within the state. After looping through all of the datasets, the program will 
save all of the appended data as one single `combined_*.dta` file in the state 
output folder.
==============================================================================*/
#delimit;

program define combine, rclass;

    syntax anything(name=state);

	local combined="${anondir}/3_combined/`state'";

    /* Remove any existing files */
    shell del /q "`combined'";

    /* Make directories */
    shell mkdir "`combined'";

    tempfile cleaned_arrest cleaned_adjudication cleaned_incarceration cleaned_probation cleaned_parole;
    clear;
	gen_arrest_vars;
	save `cleaned_arrest', replace;
	clear;
	gen_adjudication_vars;
	save `cleaned_adjudication', replace;
	clear;
	gen_incarceration_vars;
	save `cleaned_incarceration', replace;
	clear;
	gen_probation_vars;
	save `cleaned_probation', replace;
	clear;
	gen_parole_vars;
	save `cleaned_parole', replace;
	clear;

	import delim "${codedir}/Dataset.csv", varn(1) delim(",") clear;
	keep if active_use==1 & harmonization_run>0 & !missing(harmonization_run) & state=="`state'";
	levelsof datasetid, local(dataset_ID) clean;

	foreach data of local dataset_ID{;
		/* Identify Source Jurisdiction */
		if regexm("`data'", "[/]([A-Za-z]+([_][A-Za-z]+)*)([/][0-9]+([_]*[A-Za-z]+)*)") {;
			local data_source = "`=regexs(1)'";
		};
		else {;
			local data_source = "Unidentified Dataset Format: `data'";
		};
		/* Set Resource Indicators */
		local is_le = inlist("`data_source'", "Police", "Sheriff");
		local is_crt = inlist("`data_source'", "Courts", "Court_Clerk", "County_Clerk", "District_Clerk", "Judiciary");
		local is_doc = inlist("`data_source'", "DOC");
		local is_rep = inlist("`data_source'", "DPS", "DPS_Scrape");
		local is_cc = inlist("`data_source'", "CommCorr");  

		/* Check that at least one source was chosen */
        capture assert `is_le' + `is_crt' + `is_doc' + `is_rep' + `is_cc' == 1;
        if _rc 		di as error _n(5) "The record source dummy variables do not sum to 1!" _n(5);

		local cleaned="${anondir}/2_cleaned/`data'";
		foreach file in cleaned_arrest cleaned_adjudication cleaned_incarceration cleaned_probation cleaned_parole {;
			capture confirm file "`cleaned'//`file'.dta";
			if _rc==0{;
				use "`cleaned'//`file'.dta", replace;

				/* Get a table stub from the filename: e.g., cleaned_arrest -> arr */
				local tabstub = substr("`file'", 9, 3);

				/* Truncate String Variables in cleaned_adjudication */
				if "`file'"=="cleaned_adjudication" {;
					replace adj_grd_cd_src = substr(adj_grd_cd_src, 1, 10);
					replace adj_chrg_off_cd_src = substr(adj_chrg_off_cd_src, 1, 30);
					replace adj_disp_off_cd_src = substr(adj_disp_off_cd_src, 1, 30);
					replace adj_disp_cd_src = substr(adj_disp_cd_src, 1, 10);
					replace adj_sent_src = substr(adj_sent_src, 1, 30);
					replace adj_sent_fine = round(adj_sent_fine, 0.01) if adj_sent_fine != .;
					replace adj_sent_rest = round(adj_sent_rest, 0.01) if adj_sent_rest != .;
					replace adj_sent_inc = round(adj_sent_inc, 0.01) if adj_sent_inc != .;
					replace adj_sent_pro = round(adj_sent_pro, 0.01) if adj_sent_pro != .;
					replace adj_sent_inc_min = round(adj_sent_inc_min, 0.01) if adj_sent_inc_min != . ;
					replace adj_sent_inc_max = round(adj_sent_inc_max, 0.01) if adj_sent_inc_max != .;
					compress adj_grd_cd_src adj_chrg_off_cd_src adj_disp_off_cd_src adj_disp_cd_src adj_sent_src;
					clean adj_grd_cd_src adj_chrg_off_cd_src adj_disp_off_cd_src adj_disp_cd_src adj_sent_src;
				};

				/* Gen vars for this table using local tabstub */
				gen_record_vars_`tabstub';

				/* Recode record source variables using local tabstub */
				if `is_le' 			replace `tabstub'_rec_src_le = 1;
				else if `is_crt' 	replace `tabstub'_rec_src_crt = 1;
				else if `is_doc'	replace `tabstub'_rec_src_doc = 1;
				else if `is_rep'	replace `tabstub'_rec_src_rep = 1;
				else if `is_cc'		replace `tabstub'_rec_src_cc = 1;

				d, f;

				/* Round float variables to simplify precision */
				local month_length_vars "adj_sent_inc adj_sent_pro adj_sent_inc_min adj_sent_inc_max";
				foreach mon_var of local month_length_vars {;
					capture confirm variable `mon_var';
	                if !_rc 		replace `mon_var' = round(`mon_var', .01);
				};
				/* Plan to round these in a slightly different way soon*/
				local dollar_vars "adj_sent_rest adj_sent_fine";
				foreach dol_var of local dollar_vars {;
					capture confirm variable `dol_var';
	                if !_rc 		replace `dol_var' = round(`dol_var', .01);
				};
				
				/* Coding missing values as 9999 or UU */
				foreach var of varlist *_cd{;
					if "`var'"=="adj_chrg_off_cd" | "`var'"=="adj_disp_off_cd" | "`var'"=="arr_off_cd"{;
						replace `var'="9999" if `var'=="";
					};
					else{;
						replace `var'="UU" if `var'=="";
					};
				};
				
				/* create a source variable as dataset ID to distinguish local/state records in the
					adjudication data coverage resolution stage */
				if "`file'"=="cleaned_adjudication"{;
					gen source = "`data'";
				};	

				append using ``file'';
				save ``file'', replace;
			};
		};

	};
	clear;

	foreach file in cleaned_arrest cleaned_adjudication cleaned_incarceration cleaned_probation cleaned_parole {;
		local type=subinstr("`file'", "cleaned_","",.);
		use ``file'', replace;
		quietly count;
		if r(N)>0{;
			duplicates drop;
			
			/* Resolve overlapping spells and update disposition + booking dates */
			if "`file'"=="cleaned_arrest"{;
				arrest_chrg_resolution;
			};
			if "`file'"=="cleaned_adjudication"{;
				adj_coverage_resolution;
				adjudication_chrg_resolution;
				adjudication_collapse;
			};
			if "`file'"=="cleaned_incarceration"{;
				incarceration_spell_resolution;
			};
			if "`file'"=="cleaned_probation"{;
				probation_spell_resolution;
			};
			if "`file'"=="cleaned_parole"{;
				parole_spell_resolution;
			};
			
			qui compress;
			save "`combined'/combined_`type'.dta", replace;
		};
	};
	clear;
	confirmdir "${anondir}/4_episode_resolved/`state'";
	if _rc!=0{;
		mkdir "${anondir}/4_episode_resolved/`state'";
	};

end;
