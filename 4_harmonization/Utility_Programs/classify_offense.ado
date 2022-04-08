/*==============================================================================
Offense Classification
======================
Utility program for standardizing charge descriptions to uniform crime classification 
standard (UCCS) charge codes and generating state specific crosswalks with domestic 
violence indicator using the Text-based Offense Classification (TOC) tool. The 
program first checks for the most recent version of the trained model from `toc_vintage` 
variable in Dataset.csv. If a crosswalk already exists, the program will run the 
TOC tool for only the unmatched charged descriptions and append them to the crosswalk 
after classification. If not, the program will collapse the data so that each row 
contains unique combination of `code`, `desc`, and `grade` to generate a new crosswalk. 
To invoke, user must pass in state abbreviation (`state`), dataset identifier (`stub`), 
and at least the charge description (`desc`). As optional arguments, statute number 
(`code`), charge grade/level (`grade`), and/or NCIC charge codes (`ncic`) can be 
passed in. If `grade` is passed in, the standardized CJARS values will be set by 
the conditions set in `classify_grade.ado`. Otherwise, the program will fill in 
these values based on the charge code. If `ncic` is passed in, the program will 
merge in NCIC charge descriptions from an existing NCIC crosswalk for the TOC tool.

Output(s)
=========
- state_code:			Raw statute number (`code`)
- state_description:	Raw charge description (`desc`)
- grade_raw:			Raw charge grade description (`grade`)
- uccs_code:			4-digit UCCS charge code
- dv:					Domestic violence indicator (set to 1 if charge involved domestic violence)
==============================================================================*/
#delimit;
capture program drop classify_offense;
program define classify_offense, rclass sortpreserve;
	syntax, state(string) stub(string) [ code(varname string) desc(varname string) grade(varname string) ncic(varname string)];

	/**************************/
	/*** Load `toc_vintage' ***/
	local GIT_ROOT = "D:/Users/`c(username)'/Desktop/code";
	preserve;
		import delim "`GIT_ROOT'/Dataset.csv", varn(1) delim(",") clear;
		*import delim "`GIT_ROOT'/test.csv", varn(1) delim(",") clear;
		keep if datasetid=="`stub'";
		local toc_alg = toc_vintage[1];
	restore;
	/**************************/
	
	local ORIG_DIR `c(pwd)';
	local state = lower("`state'");
	/* Directory Macros */
	local XWALK_ROOT = "O:/utility/toc/alg/`toc_alg'";
	local XWALK = "`XWALK_ROOT'/cleaned_cjars_crosswalk_`state'.dta";
	
	local NCIC_XWALK = "O:/utility/cleaned/harmonization/offense_classification/misc/crosswalk/ncic_uccs_crosswalk.dta";
	

	/* Predict Code Macros */
	local PRED_CODE_PATH = "O:/utility/toc";
	local PRED_CODE = "O:/utility/toc/predict.py";
	local PRED_PATH = "O:/utility/toc/prediction";
	
	/* Save filenames with current username as suffix for concurrency */
	local PRED_INPUT = "`PRED_PATH'/predict_`c(username)'.csv";
	local PRED_OUTPUT = "`PRED_PATH'/predict_output_`c(username)'.csv";
	local UCCS_MFJ_XWALK = "`PRED_CODE_PATH'/clf/schema/uccs_mfj_crosswalk.dta";	
	
	/* Erase existing user-specific files if they already exist */
	capture confirm file "`PRED_INPUT'";
	if !_rc {;
		qui erase "`PRED_INPUT'";
	};
	capture confirm file "`PRED_OUTPUT'";
	if !_rc {;
		qui erase "`PRED_OUTPUT'";
	};

	capture shell mkdir "`PRED_PATH'";

	/* Clean Merge Variables */
	if "`code'"=="" {;
		gen state_code = "";
	};
	else {;
		/*** Normalize letters with diacritical marks ***/
		replace `code' = ustrto(ustrnormalize(`code', "nfd"), "ascii", 2);
		gen state_code = `code';
		replace state_code = strtrim(stritrim(subinstr(state_code, ",", " ", .)));
	};
	if "`desc'"=="" {;
		gen state_description = "";
	};
	else {;
		/*** Normalize letters with diacritical marks ***/
		replace `desc' = ustrto(ustrnormalize(`desc', "nfd"), "ascii", 2);
		gen state_description = `desc';
		replace state_description = strtrim(stritrim(subinstr(state_description, ",", " ", .)));
	};
	if "`grade'"=="" {;
		gen grade_raw = "";
	};
	else {;
		/*** Normalize letters with diacritical marks ***/
		replace `grade' = ustrto(ustrnormalize(`grade', "nfd"), "ascii", 2);
		gen grade_raw = `grade';
		replace grade_raw = strtrim(stritrim(subinstr(grade_raw, "," , " ", .)));
	};
	/* Merge in NCIC description if passed in */
	if "`ncic'"!="" {;
		gen NCIC = `ncic';
		tostring NCIC, replace;
		replace NCIC = substr(NCIC, 1, 4);
		replace NCIC = "" if NCIC==".";
		merge m:1 NCIC using "`NCIC_XWALK'", nogen keep(matched master) keepusing(ncic_description);
		replace state_description = ncic_description if !missing(ncic_description) & missing(state_description);
		drop NCIC ncic_description;
	};
	
	tostring state_code, replace;
	replace state_code = "" if state_code==".";
	/* In some places (e.g. FL/Co/Duval/County_Clerk), state_description can contain 
	commas which can offset the predict_output.csv once it's imported into State */
	replace state_description = subinstr(state_description, ",", " ", .);
	replace state_description = subinstr(state_description, `"""', " ", .);	
	clean state_code state_description grade_raw;
	
	tempfile base_file;
	save "`base_file'";	
	
	/* UPDATING CROSSWALK FOR NEW OFFENSES */
	/* Check to see if there are new unclassified values in the source data and  */
	di "Identifying new descriptions to be classified";
	/* Below statement has capture in case "`XWALK'" does not exist yet */
	cap: merge m:1 state_code state_description grade_raw using "`XWALK'", nogen keep(master); 
	if [_N] > 0{;
		/* Generate predict_USER.csv */
		keep state_code state_description grade_raw;
		tostring state_code, replace;
		replace state_code = "" if state_code==".";
		cap: tostring state_description, replace;
		replace state_description = "" if state_description==".";
		gen n=1;
		collapse (count) n, by(state_code state_description grade_raw);
		export delimited using "`PRED_INPUT'", delim(",") replace;
		
		/* Predict Offense Codes */
		di "Running offense classification code. Please wait for code to finish running";
		di "Input: `PRED_INPUT'";
		di "Output: `PRED_OUTPUT'";
		cd "`PRED_CODE_PATH'";
		shell C:\Anaconda3\python.exe "`PRED_CODE'" "`stub'";
		
		/* Load Predicted Crosswalk */
		di "Finished predicting offense codes";
		import delimited using "`PRED_OUTPUT'", delim(",") varnames(1) case(preserve) clear;
		
		/* Clean descriptors */
		tostring state_code state_description grade_raw, replace;
		tostring state_code, replace force;
		replace state_description = "" if state_description==".";
		replace grade_raw = "" if grade_raw==".";
		replace state_code = "" if state_code==".";
		
		/* Generate Offense Grade */
		capture confirm variable grade_raw;
		if !_rc {;
			di "Standardizing Offense Grades using grade_raw";
			tostring grade_raw, replace;
			replace grade_raw = "" if grade_raw==".";
		};
		else {;
			gen grade_raw = "";
			di "Standardizing Offense Grades";
		};
		
		/*** Classify Offense Grade ***/
		classify_grade, state("`state'");

		tostring state_code state_description grade_raw, replace;
		replace state_code = "" if state_code==".";
		replace state_description = "" if state_description==".";
		replace grade_raw = "" if grade_raw==".";
		
		/* Applying automatic fill ins for grade for offenses that are universally misdemeanors or felonies */
		replace grade = "FE" if inlist(uccs_code, "1010", "1011", "1012") 		& inlist(grade, "", "UU");
		replace grade = "FE" if inlist(uccs_code, "1020", "1021", "1022") 		& inlist(grade, "", "UU");
		replace grade = "FE" if inlist(uccs_code, "1030", "1031", "1032") 		& inlist(grade, "", "UU");
		replace grade = "FE" if inlist(uccs_code, "1040", "1041", "1042") 		& inlist(grade, "", "UU");
		replace grade = "FE" if inlist(uccs_code, "1050", "1051", "1052") 		& inlist(grade, "", "UU");
		replace grade = "FE" if inlist(uccs_code, "9010", "9011", "9012") 		& inlist(grade, "", "UU");
		replace grade = "MI" if inlist(uccs_code, "9020", "9021", "9022") 		& inlist(grade, "", "UU");
		
		/* Mapping over offense grades and offense classifications when missing for exact combination of (state_code state_description grade_raw) but available for (state_code) or (state_description) individually and there are not conflicting classifications */
		replace uccs_code = "9999" if missing(uccs_code);
		replace grade = "UU" if missing(grade);	
		cap: append using "`XWALK'";
		foreach map_var in state_code state_description{;
			foreach value_var in uccs_code grade{;
				bys `map_var': 				gen temp_var = [_N]  if (`value_var' != "999" & `value_var' != "UU");
				bys `map_var': 		       egen map_count = max(temp_var);
				drop temp_var;
				bys `map_var' `value_var': 	gen temp_var = [_N] if (`value_var' != "999" & `value_var' != "UU");
				bys `map_var': 		  	   egen map_value_count = max(temp_var);
				drop temp_var;
				gen temp_var = `value_var' if (`value_var' != "999" & `value_var' != "UU");
				bys `map_var' (temp_var): gen fill_in_value = temp_var[_N] ;
				replace `value_var' = fill_in_value if map_count == map_value_count & (`value_var' == "999" | `value_var' == "UU") & `map_var' != "";
				drop temp_var fill_in_value map_count map_value_count ;
			};
		};
		gsort state_code state_description grade_raw -n;
		collapse (sum) n (max) Dmstc_pred Gang_pred Gun_pred HabitualOffndrFlag_pred, by(state_code state_description grade_raw grade uccs_code);
		
		/* Just making sure nothing is left as "" */
		replace uccs_code = "9999" if missing(uccs_code);
		replace grade = "UU" if missing(grade);	
		/* Filling in grade where missing and the mfj_code is highly skewed towards felonies or misdemeanors */
		gen uccs_felony 	= grade == "FE" if grade != "UU";
		gen uccs_misd 	= grade == "MI" if grade != "UU";
		bys uccs_code: egen tot_N = total(n) if grade != "UU";
		gen pre_avg_felony = n/tot_N * uccs_felony;
		bys uccs_code: egen avg_felony = total(pre_avg_felony);
		gen pre_avg_misd = n/tot_N * uccs_misd;
		bys uccs_code: egen avg_misd = total(pre_avg_misd);		
		replace grade = "FE" if avg_felony > 0.95 & grade == "UU" & avg_felony != .;
		replace grade = "MI" if avg_misd > 0.95 & grade == "UU" & avg_misd != .;
		drop uccs_felony uccs_misd avg_misd avg_felony pre_avg_misd pre_avg_felony tot_N;
		collapse (sum) n (max)  Dmstc_pred Gang_pred Gun_pred HabitualOffndrFlag_pred, by(state_code state_description grade_raw grade uccs_code);
		/* One final check to make sure that we still have only one entry per state_code state_description grade_raw */
		bys state_code state_description grade_raw: gen N = [_N];
		bys state_code state_description grade_raw (grade): gen i = [_n];
		drop if i!=N;
		drop i N;
		
		/* Overwrite ordinance, infractions, etc. to UU */
		replace grade_raw = strtrim(stritrim(grade_raw));
		count if !missing(grade_raw);
		if r(N)>0 {;
			tempfile full_xwalk;
			save `full_xwalk', replace;
			drop if missing(grade_raw);
			classify_grade, state("`state'");
			tempfile regraded;
			save `regraded', replace;
			use `full_xwalk', clear;
			keep if missing(grade_raw);
			append using `regraded';
		};
		
		/* Recast string_description as non-StrL type */
		gen len = strlen(state_description);
		summ len;
		local max_len = r(max);
		if `max_len'>0 {;
			recast str`max_len' state_description;
		};
		drop len;
		
		/* Save/update the crosswalk */
		order state_code state_description grade_raw grade n uccs_code;
		save "`XWALK'", replace;
	};
	
	
	/* Now merge on the mfj_code and the offense_grade */
	use "`base_file'", replace;
	di "Mergining on EXISTING (state_code state_description grade_raw) using `XWALK'";
	merge m:1 state_code state_description grade_raw using "`XWALK'", nogen keep(matched master) keepusing(uccs_code Dmstc_pred grade);
	rename Dmstc_pred dv;
	
	/* Although the variable is named `mfj_code', it is actually referencing 
		the 4-digit UCCS codes */
	replace uccs_code = "9999" if missing(uccs_code);
	replace uccs_code = "9999" if inlist(uccs_code, "999", ".", "");
	replace grade = "UU" if missing(grade);
	
	cd "`ORIG_DIR'";

end;
