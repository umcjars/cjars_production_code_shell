#delimit;

program define state_match_integration, eclass;
	syntax anything(name=dataset_id);
    timer clear 10;
    timer on 10;
	
	preserve;
		clear;
		import delim "${codedir}/Dataset.csv", varn(1) delim(",");
		keep if datasetid=="`dataset_id'";
		levelsof alias_drop, local(alias) clean;
		if "`alias'"=="1"{;
			local aliasdrop=1 ;
		};
		else{;
			local aliasdrop=0 ;
		};	
	restore;

	/*Clearing out any lingering production files from a prior run */
	foreach file in exact_match_pairs base_data with_comparators_added ready_for_id_enumeration almost_done non_clustered_ids insufficient_pii_for_linking{; 	
		cap rm  "O:\pii\roster\production_files\\`file'.dta";
	};
    
	/* Loading data */
   	use "${cleanpiidir}/`dataset_id'/data_level_roster.dta", replace;
	duplicates drop;
	merge 1:m record_id using "${cleanpiidir}/`dataset_id'/cleaned_pii.dta", nogen keep(master match);

	local state=substr("`dataset_id'", 1,2);
	if "`aliasdrop'"=="1"{;
		drop if alias == 1;
	};
	capture confirm file "${rosterdir}/cjars_roster_`state'.dta";
	if _rc!=0 {;
		display "Roster Initiation Stage";		
		roster_initiation `dataset_id' ;
	};
	else{;	
		display "Blocking Stage";
		blocking `dataset_id' ;		
		display "Comparator Build Stage";
		comparator_build  	`dataset_id';
		display "Predicting Matches Stage";
		match_predictions 	`dataset_id';
		display "Enumerating IDs Stage";
		id_enumeration		`dataset_id';				
		display "Checking for super clusters Stage";
		supercluster_check 	`dataset_id';
		display "Finish Roster Stage";
		complete_roster		`dataset_id';
	};
		
timer off 10;
timer list 10;
end;
