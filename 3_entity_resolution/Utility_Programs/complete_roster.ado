#delimit;

program define complete_roster, eclass;
	syntax anything(name=dataset_id);

	local state=substr("`dataset_id'", 1,2);
	
	/*Save new roster file*/
	display "Finally saving the new roster file";
	use "O:\pii\roster\production_files\almost_done.dta", replace;
	capture{;
		merge m:1 cjars_id using "O:\pii\roster\production_files\non_clustered_ids.dta", keep(master match) nogen;
		replace cjars_id = new_cjars_id if new_cjars_id != "";
		egen long id_var = group(cjars_id);
		replace cjars_id = "`state'"+string(id_var, "%0`len'.0f");
	};
	keep cjars_id alias name_raw name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy birth_loc_city birth_loc_st birth_loc_ctry birth_loc_foreign sex sex_raw sex_imputed race race_raw race_imputed state_id state_id_ori county_id county_id_ori agency_id agency_id_ori ssn fbi_num addr_raw addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry name_first_clean name_middle_clean;
	
	gen length=length(subinstr(cjars_id,"`st'","",.));
	quietly su length, d;
	local len=r(max);
	tempvar cjars_id_num;
	destring cjars_id, gen(`cjars_id_num') ignore("`state'");
	replace cjars_id="`state'"+string(`cjars_id_num', "%0`len'.0f");
	drop length `cjars_id_num';
	drop if agency_id_ori == "";
	
	duplicates drop;
	
	/* Finally deal with the records that have insufficient PII for entity resolution */
	
	capture confirm file "O:\pii\roster\production_files\old_roster_insufficient_pii.dta";
	if _rc!=0{;
		append using "O:\pii\roster\production_files\old_roster_insufficient_pii.dta", gen(old_roster_insuf_pii);
	};
	capture confirm file "O:\pii\roster\production_files\insufficient_pii_for_linking.dta";
	if _rc!=0{;
		merge m:1 alias name_raw name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy birth_loc_city birth_loc_st birth_loc_ctry birth_loc_foreign sex_raw race_raw state_id state_id_ori county_id county_id_ori agency_id agency_id_ori ssn fbi_num addr_raw addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry name_first_clean name_middle_clean race sex race_imputed sex_imputed using "O:\pii\roster\production_files\insufficient_pii_for_linking.dta", gen(new_data_insuf_pii);
	};
	
	sort cjars_id;
	gen long list_order = [_n];
	bys cjars_id: egen long min_list_order = min(list_order);
	replace list_order = min_list_order if cjars_id != "";
	egen long id_var = group(min_list_order);
	tostring id_var, gen(str_list_order);
	gen length=length(str_list_order);
	quietly su length, d;
	local len=r(max);	
	replace cjars_id = "`state'"+string(id_var, "%0`len'.0f");
	
	keep cjars_id alias name_raw name_last name_first name_middle name_suffix name_middle_initial dob_dd dob_mm dob_yyyy birth_loc_city birth_loc_st birth_loc_ctry birth_loc_foreign sex_raw race_raw state_id state_id_ori county_id county_id_ori agency_id agency_id_ori ssn fbi_num addr_raw addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry name_first_clean name_middle_clean race sex race_imputed sex_imputed;
	order cjars_id alias name_raw name_last name_first name_first_clean name_middle name_middle_clean name_suffix name_middle_initial dob_dd dob_mm dob_yyyy birth_loc_city birth_loc_st birth_loc_ctry birth_loc_foreign sex sex_imputed sex_raw race race_imputed race_raw  state_id state_id_ori county_id county_id_ori agency_id agency_id_ori ssn fbi_num addr_raw addr_bldnum addr_str addr_city addr_st addr_zip addr_ctry ;
	
	save "${rosterdir}/cjars_roster_`state'.dta", replace;
	
	/*Daily Archive in the event of superclusters*/
	local c_date=c(current_date);
	local date_string=subinstr("`c_date'"," ","",.);
	
	save "${rosterdir}/backups/cjars_roster_`state'_`date_string'.dta", replace;

	/*At this point, we have a state-level roster. The final step is to go back to
	each folder and update the pointer files and PII files with each observation's
	new cjars_id. This will require loading dataset.csv to see what other
	dataset_id is included in the current roster. We then need to push the
	new cjars_id to each of the data folders that have already undegone 
	entity resolution. This will include creating new versions of the 
	anonymized data. Remember that we should have all PII variables collected
	in a .txt file.*/

	
end;
