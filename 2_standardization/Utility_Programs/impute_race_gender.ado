/***** Gender Logic
Logic statements for sex.
	General Strategy:
	If all sex imputations agree with original, then just use the agreed sex imputation
	If there are disrepencies:
	1. Original takes precedence
	2. If Original is missing, first name x region takes precedence over census x first name x yob
**** Race Logic
Logic statements for race. 
	General Strategy:
	Prioritize race (minority to majority): AIAN, Asian, Hispanic, Black, White
	Use alternative thresholds for missing race versus overwriting race.
	Also alternative threshold if entire stub is missing race
	For males:
	If overwriting, either race_last > 95% | race_first > 95% | race_census > 95% | race_lastfirst > `mid_threshold'
	If imputing for missing, either race_last > 75% | race_first > 75% | race_census > 75% | race_lastfirst > 0.65
	
	For females:
	If overwriting, either race_first > 95% | race_lastfirst > 0.6
	If imputing for missing, either race_first > 50% | race_lastfirst > 0.35
	If either still missing, use race_last | race_census with same threhsolds.
	Last step: re-write race to race_raw if imputed race == white or other.	
		
	if missing for entire stub, 
	Then just use 50% for all thresholds for now. 
	*/
#delimit;

program define impute_race_gender;
    
	syntax anything(name=dataset_id);
	quietly import delim "${codedir}/Dataset.csv", varn(1) delim(",");
    quietly keep if datasetid=="`dataset_id'";
    quietly levelsof census_region, local(region) clean;
	quietly levelsof state, local(state) clean;
	local state = lower("`state'");
	local merge_dirs "\\cjarsfs\data\pii\utility";
	
  
    clear;
	capture confirm file "${cleanpiidir}//`dataset_id'/cleaned_pii_noimpute.dta";
	if _rc == 0 {;
		use "${cleanpiidir}//`dataset_id'/cleaned_pii_noimpute.dta";
		gen race = .;
		gen sex = .;
    };
	if _rc != 0 {;
		use "${cleanpiidir}//`dataset_id'/cleaned_pii.dta";
		drop race sex race_imputed sex_imputed;
		gen race = .;
		gen sex = .;
    };
* Set threshold for imputations based on criterion;
	
		*race_raw not missing, no subcategory of race is missing;
foreach race in 1 2 3 4 5 6{;
	local high_threshold_`race' 0.95;
	local mid_threshold_`race'  0.75 ;
	local mid_threshold2_`race'  0.6 ;
	local low_threshold_`race' 0.45 ;
};
summ race_raw;
if r(N) == 0{;
	foreach race in 1 2 3 4 5 6{;
		local high_threshold_`race' 0.5;
		local mid_threshold_`race' 0.5 ;
		local mid_threshold2_`race'  0.35 ;
	};
};

foreach race in 1 2 3 4 5 6{;
	gen race_`race' = race_raw == `race';
	summ race_`race' ;
	if r(mean) <= 0.0001{;
	local high_threshold_`race' 0.5;
	local mid_threshold_`race' 0.5 ;
	local mid_threshold2_`race'  0.35 ;
	drop race_`race';
};
};


    capture confirm file "`merge_dirs'/`region'_race_rates_first.dta";
    if _rc==0 {;
        merge m:1 name_first using "`merge_dirs'/`region'_race_rates_first.dta", nogen keep(master matched);
    };
    
    capture confirm file "`merge_dirs'/`region'_race_rates_last.dta";
    
    if _rc==0 {;
        merge m:1 name_last using "`merge_dirs'/`region'_race_rates_last.dta", nogen keep(master matched);
    };
	
	capture noisily confirm file "`merge_dirs'/`region'_sex_rates.dta";
    if _rc==0 {;
        merge m:1 name_first using "`merge_dirs'/`region'_sex_rates.dta", nogen keep(master matched);
   };

	capture confirm file "\\cjarsfs\data\utility\cleaned\Census\Race-Ethnicity Names\Names_2010Census.dta";
	
	if _rc == 0 {;
		merge m:1 name_last using "\\cjarsfs\data\utility\cleaned\Census\Race-Ethnicity Names\Names_2010Census.dta", nogen keep(master matched);
	};

	capture noisily confirm file "\\cjarsfs\data\utility\cleaned\Census\Gender Names\namesbystate\\`state'.dta";
	
	if _rc == 0 {;
		capture rename name_first name;
		merge m:1 name dob_yyyy using "\\cjarsfs\data\utility\cleaned\Census\Gender Names\namesbystate\\`state'.dta", nogen keep(master matched);
		rename name name_first;
	};
	
	
    capture confirm variable first_white ;
    
    if _rc==0 {;
		capture gen race_first = .;
		capture gen race_firstmiss = .;
		replace first_aian = 0 if first_aian == .;
		replace first_asian = 0 if first_asian == .;
		replace first_hispanic = 0 if first_hispanic == .;
		replace first_black = 0 if first_black == .;
		replace first_white = 0 if first_white == .;
        replace race_first=5 if first_aian!=. & first_aian>`high_threshold_5' & race_first==.;
		replace race_first=3 if first_asian!=. & first_asian>`high_threshold_3' & race_first==.;
		replace race_first=4 if first_hispanic!=. & first_hispanic>`high_threshold_4' & race_first==.;
		replace race_first=2 if first_black!=. & first_black>`high_threshold_2' & race_first==.;
		replace race_first=1 if first_white!=. & first_white>`high_threshold_1' & race_first==.;
        
		replace race_firstmiss=5 if first_aian!=. & first_aian>`mid_threshold_5' & race_firstmiss==.;
		replace race_firstmiss=3 if first_asian!=. & first_asian>`mid_threshold_3' & race_firstmiss==.;
		replace race_firstmiss=4 if first_hispanic!=. & first_hispanic>`mid_threshold_4' & race_firstmiss==.;
		replace race_firstmiss=2 if first_black!=. & first_black>`mid_threshold_2' & race_firstmiss==.;
		replace race_firstmiss=1 if first_white!=. & first_white>`mid_threshold_1' & race_firstmiss==.;
        
        
    };
    
    capture confirm variable last_white ;
    if _rc==0 {;
		capture gen race_last = .;
		capture gen race_lastmiss = .;
		replace last_aian = 0 if last_aian == .;
		replace last_asian = 0 if last_asian == .;
		replace last_hispanic = 0 if last_hispanic == .;
		replace last_black = 0 if last_black == .;
		replace last_white = 0 if last_white == .;
        replace race_last=5 if last_aian!=. & last_aian>`high_threshold_5' & race_last==.;
		replace race_last=3 if last_asian!=. & last_asian>`high_threshold_3' & race_last==.;
		replace race_last=4 if last_hispanic!=. & last_hispanic>`high_threshold_4' & race_last==.;
		replace race_last=2 if last_black!=. & last_black>`high_threshold_2' & race_last==.;
		replace race_last=1 if last_white!=. & last_white>`high_threshold_1' & race_last==.;
               
		replace race_lastmiss=5 if last_aian!=. & last_aian>`mid_threshold_5' & race_lastmiss==.;
		replace race_lastmiss=3 if last_asian!=. & last_asian>`mid_threshold_3' & race_lastmiss==.;
		replace race_lastmiss=4 if last_hispanic!=. & last_hispanic>`mid_threshold_4' & race_lastmiss==.;
		replace race_lastmiss=2 if last_black!=. & last_black>`mid_threshold_2' & race_lastmiss==.;
		replace race_lastmiss=1 if last_white!=. & last_white>`mid_threshold_1' & race_lastmiss==.;
		
		capture gen race_firstlast = .;
		capture gen race_firstlastmiss = .;
		replace race_firstlast = 5 if (first_aian * last_aian) >= `mid_threshold_5' & race_firstlast == .;
		replace race_firstlast = 3 if (first_asian * last_asian) >= `mid_threshold_3' & race_firstlast == .;
		replace race_firstlast = 4 if (first_hispanic * last_hispanic) >= `mid_threshold_4' & race_firstlast == .;
		replace race_firstlast = 2 if (first_black * last_black) >= `mid_threshold_2' & race_firstlast == .;
		replace race_firstlast = 1 if (first_white * last_white) >= `mid_threshold_1' & race_firstlast == .;
		
		replace race_firstlastmiss = 5 if (first_aian * last_aian) >= `low_threshold_5' & race_firstlastmiss == .;
		replace race_firstlastmiss = 3 if (first_asian * last_asian) >= `low_threshold_3' & race_firstlastmiss == .;
		replace race_firstlastmiss = 4 if (first_hispanic * last_hispanic) >= `low_threshold_4' & race_firstlastmiss == .;
		replace race_firstlastmiss = 2 if (first_black * last_black) >= `low_threshold_2' & race_firstlastmiss == .;
		replace race_firstlastmiss = 1 if (first_white * last_white) >= `low_threshold_1' & race_firstlastmiss == .;
		*Females use alternative threshold to account for changing of last names post marriage;
		capture gen race_firstlastf = .;
		capture gen race_firstlastmissf = .;
		
		replace race_firstlastf = 5 if (first_aian * last_aian) >= `mid_threshold2_5' & race_firstlastf == .;
		replace race_firstlastf = 3 if (first_asian * last_asian) >= `mid_threshold2_3' & race_firstlastf == .;
		replace race_firstlastf = 4 if (first_hispanic * last_hispanic) >= `mid_threshold2_4' & race_firstlastf == .;
		replace race_firstlastf = 2 if (first_black * last_black) >= `mid_threshold2_2' & race_firstlastf == .;
		replace race_firstlastf = 1 if (first_white * last_white) >= `mid_threshold2_1' & race_firstlastf == .;
		
		replace race_firstlastmissf = 5 if (first_aian * last_aian) >= `mid_threshold2_5' & race_firstlastmissf == .;
		replace race_firstlastmissf = 3 if (first_asian * last_asian) >= `mid_threshold2_3' & race_firstlastmissf == .;
		replace race_firstlastmissf = 4 if (first_hispanic * last_hispanic) >= `mid_threshold2_4' & race_firstlastmissf == .;
		replace race_firstlastmissf = 2 if (first_black * last_black) >= `mid_threshold2_2' & race_firstlastmissf == .;
		replace race_firstlastmissf = 1 if (first_white * last_white) >= `mid_threshold2_2' & race_firstlastmissf == .;
		
        drop last_white last_black last_asian last_hispanic last_other_race last_aian;
		drop first_white first_black first_asian first_hispanic first_other_race first_aian;
	};
    
	capture confirm variable pctaian;
	if _rc==0{;
		capture gen race_census = .;
		capture gen race_censusmiss = .;
		replace pctwhite = round(pctwhite/100, .01);
		replace pctblack = round(pctblack/100, .01);
		replace pcthispanic = round(pcthispanic/100, .01);
		replace pctapi = round(pctapi/100, .01);
		replace pctaian = round(pctaian/100, .01);
        replace race_census=5 if pctaian!=. & pctaian>`high_threshold_5' & race_census==.;           
		replace race_census=3 if pctapi!=. & pctapi>`high_threshold_3' & race_census==.;
		replace race_census=4 if pcthispanic!=. & pcthispanic>`high_threshold_4' & race_census==.;
		replace race_census=2 if pctblack!=. & pctblack>`high_threshold_2' & race_census==.;
		replace race_census=1 if pctwhite!=. & pctwhite>`high_threshold_1' & race_census==.;
       
        replace race_censusmiss=5 if pctaian!=. & pctaian>`mid_threshold_5' & race_censusmiss==.; 
		replace race_censusmiss=3 if pctapi!=. & pctapi>`mid_threshold_3' & race_censusmiss==.;
		replace race_censusmiss=4 if pcthispanic!=. & pcthispanic>`mid_threshold_4' & race_censusmiss==.;
		replace race_censusmiss=2 if pctblack!=. & pctblack>`mid_threshold_2' & race_censusmiss==.;
		replace race_censusmiss=1 if pctwhite!=. & pctwhite>`mid_threshold_1' & race_censusmiss==.;
        drop pctwhite pctblack pctapi pcthispanic pctaian pct2prace;
	};

    capture confirm variable female;
	if _rc == 0{;
		capture gen cjars_sex = .;
        replace cjars_sex=1 if male!=. & male>.67 & cjars_sex==.;
        replace cjars_sex=2 if female!=. & female>.67 & cjars_sex==.;
            
        drop male female;
	};
	
	capture confirm variable tot_freq;
	if _rc == 0{;
		capture gen census_sex = .;
		replace prop_male = round(prop_male, 0.01);
		replace prop_female = round(prop_female, 0.01);
		replace census_sex=1 if prop_male !=. & prop_male > 0.67 & census_sex == .;
		replace census_sex=2 if prop_female != . & prop_female > 0.67 & census_sex ==.;
	};
		
	*Begin logic statements for gender;
	replace sex = sex_raw;
	replace sex = cjars_sex if sex_raw != census_sex & census_sex == cjars_sex & cjars_sex != .;
	replace sex = cjars_sex if sex == .;
	replace sex = census_sex if sex == .;
		
		
	*Begin logic statements for race;
	*Rules for overwriting raw_race & male;
	replace race = 5 if (race_first == 5 | race_last == 5 | race_census == 5 | race_firstlast == 5) & (sex == 1| sex == .) & race_raw != . & race_raw  != 6 & race == .;
	replace race = 5 if (race_firstmiss == 5 | race_lastmiss == 5 | race_censusmiss == 5 | race_firstlastmiss == 5) & (sex == 1| sex == .) & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 5 if (race_first == 5 | race_firstlastf == 5) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 5 if (race_last == 5 | race_census == 5) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 5 if (race_firstmiss == 5 | race_firstlastmissf == 5) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 5 if (race_lastmiss == 5 | race_censusmiss == 5) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	
	replace race = 3 if (race_first == 3 | race_last == 3 | race_census == 3 | race_firstlast == 3) & (sex == 1| sex == .) & race_raw != . & race_raw  != 6 & race == . ;
	replace race = 3 if (race_firstmiss == 3 | race_lastmiss == 3 | race_censusmiss == 3 | race_firstlastmiss == 3) & (sex == 1| sex == .) & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 3 if (race_first == 3 | race_firstlastf == 3) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 3 if (race_last == 3 | race_census == 3) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 3 if (race_firstmiss == 3 | race_firstlastmissf == 3) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 3 if (race_lastmiss == 3 | race_censusmiss == 3) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	
	replace race = 4 if (race_first == 4 | race_last == 4 | race_census == 4 | race_firstlast == 4) & (sex == 1| sex == .) & race_raw != . & race_raw  != 6 & race == . ;
	replace race = 4 if (race_firstmiss == 4 | race_lastmiss == 4 | race_censusmiss == 4 | race_firstlastmiss == 4) & (sex == 1| sex == .) & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 4 if (race_first == 4 | race_firstlastf == 4) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 4 if (race_last == 4 | race_census == 4) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 4 if (race_firstmiss == 4 | race_firstlastmissf == 4) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 4 if (race_lastmiss == 4 | race_censusmiss == 4) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	
	replace race = 2 if (race_first == 2 | race_last == 2 | race_census == 2 | race_firstlast == 2) & (sex == 1| sex == .) & race_raw != . & race_raw  != 6 & race == . ;
	replace race = 2 if (race_firstmiss == 2 | race_lastmiss == 2 | race_censusmiss == 2 | race_firstlastmiss == 2) & (sex == 1| sex == .) & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 2 if (race_first == 2 | race_firstlastf == 2) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 2 if (race_last == 2 | race_census == 2) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 2 if (race_firstmiss == 2 | race_firstlastmissf == 2) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 2 if (race_lastmiss == 2 | race_censusmiss == 2) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	
	replace race = 1 if (race_first == 1 | race_last == 1 | race_census == 1 | race_firstlast == 1) & (sex == 1| sex == .) & race_raw != . & race_raw  != 6 & race == . ;
	replace race = 1 if (race_firstmiss == 1 | race_lastmiss == 1 | race_censusmiss == 1 | race_firstlastmiss == 1) & (sex == 1| sex == .) & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 1 if (race_first == 1 | race_firstlastf == 1) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 1 if (race_last == 1 | race_census == 1) & sex == 2 & race_raw != . & race_raw  != 6 & race == .;
	replace race = 1 if (race_firstmiss == 1 | race_firstlastmissf == 1) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	replace race = 1 if (race_lastmiss == 1 | race_censusmiss == 1) & sex == 2 & (race_raw == . | race_raw  == 6) & race == .;
	*For either male or female, replace race with race_raw if race is still missing ;
	replace race = race_raw if race == .;
	
	*Generate imputation label;
	gen race_imputed = 0 if race == race_raw & race != .;
	replace race_imputed = 2 if (race == race_first | race == race_last | race == race_firstlast | 
		race == race_firstlastmiss | race == race_firstlastmissf | race == race_firstlastf | race == race_lastmiss | race == race_firstmiss) & 
		race != . & race_imputed == .;
	replace race_imputed = 1 if (race == race_census | race == race_censusmiss) & race != . & race_imputed == . ;
	replace race_imputed = 3 if (race == race_census | race == race_censusmiss) & (race == race_first | race == race_last | race == race_firstlast | 
		race == race_firstlastmiss | race == race_firstlastmissf | race == race_firstlastf | race == race_lastmiss | race == race_firstmiss) & race != .  & race_imputed != 0 ;
	capture label drop imp_label_sex;
	capture label drop imp_label;
	capture label define imp_label_sex 0 "No Impute" 1 "Imputation based on first name's sex prevalence using 2010 Census names' data set" 
	2 "Imputation based on first name's sex prevalence within the state among CJARS record with non-missing sex values" 
	3 "Imputation using Census names' and CJARS first names resulted in same outcome";
	capture label define imp_label 0 "No Impute" 1 "Imputation based on last name's racial/ethnic prevalence using 2000 Census Surnames' data set" 
	2 "Imputation based on last name and first name's racial/ethnic prevalence within Census region among CJARS record with non-missing race/ethnicity values" 
	3 "Imputation using Census surnames and CJARS full names resulted in same outcome";
	label values race_imputed imp_label;
	gen sex_imputed =0  if sex == sex_raw & sex != .;
	replace sex_imputed = 2 if (sex == cjars_sex) & sex != . & sex_imputed == .;
	replace sex_imputed = 1 if sex == census_sex & sex != . & sex_imputed == . ;
	replace sex_imputed = 3 if sex == census_sex & sex == cjars_sex & sex != . & sex_imputed != 0 ;
	label values sex_imputed imp_label_sex;
	
	keep record_id alias name_raw name_last name_first name_middle name_first_clean name_middle_clean
	name_suffix	name_middle_initial dob_dd dob_mm dob_yyyy sex_raw race_raw birth_loc_city
	birth_loc_st birth_loc_ctry birth_loc_foreign state_id state_id_ori
	county_id county_id_ori	agency_id agency_id_ori ssn ssn_4 fbi_num addr_raw 
	addr_bldnum	addr_str addr_city addr_st addr_zip addr_ctry race sex race_imputed sex_imputed ; 
	compress;
	
	save "${cleanpiidir}//`dataset_id'/cleaned_pii.dta", replace;
	capture rm "${cleanpiidir}//`dataset_id'//cleaned_pii_noimpute.dta";
end;

