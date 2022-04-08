/*==============================================================================
pii_standardize
==============================
Infrastructure script that manages files and directories for standardization, then runs
clean_pii.do and associated cleaning scripts.

Uses Datasets.csv to determine which datasets need to be standardized, and writes
results back to Datasets.csv.

Output files are stored in the pii directory according to dataset_id

==============================================================================*/

#delimit;

program define pii_standardize, rclass;

    syntax anything(name=dataset_id);
    timer clear 64;
    timer on 64;

	shell mkdir "${cleanpiidir}/`dataset_id'";
	
    /* Formatted data directory */
    local formatdir "O:/original/formatted/`dataset_id'";
    cd "`formatdir'";
    
    /* .do file directory for these data */
    local dodir "${codedir}/2_standardization/`dataset_id'";
	local output_dirs "${cleanpiidir}/`dataset_id'";
	

    /* Abolish any old cleaned PII files a */

    
    local olddata: dir "`output_dirs'" files "*.dta";
    local oldreport: dir "`output_dir'" files "variables_cleaned.csv";
    local oldfiles `"`olddata' `oldreport'"';
        /*"*/
	foreach file of local oldfiles {;
		disp "Deleting previous `output_dir'/`file'";
		rm "`output_dirs'/`file'";
	};
*/   
	clear;
	/*Determine if the data set ID is a pivot table*/
	
	import delim "${codedir}/dataset.csv", varn(1) delim(",");
	keep if datasetid=="`dataset_id'";
	
	/*If the data set is NOT a pivot table*/
	if pivot_table==.{;
	
		local pivot="false";
		display "IS NOT A PIVOT TABLE";
		
	};

	/*If the data set IS a pivot table*/
	if pivot_table==1{;
		local pivot="true";	
		display "IS A PIVOT TABLE";
		levelsof pivot_id, local(pivot_id) clean;
		
	};
	
	clear;
	
	if "`pivot'"=="true" {;
		local file_list : dir "`formatdir'" files "*.dta";
		append using `file_list', keep(record_id `pivot_id');
		save "`output_dirs'/pointer_file.dta", replace;
		clear;
		run "`dodir'/clean_pii.do" `dataset_id';
		names_cleaning;
		names_missing;
		names_standardized;
		do "D:/Users/`c(username)'/Desktop/code/3_entity_resolution/Utility_Programs/agency_id_ori_code.do" `dataset_id';
		recode_standardization;
		validate_standardization `dataset_id';
		compress;
		save "`output_dirs'/cleaned_pii_noimpute.dta", replace;
	
	};

	if "`pivot'"=="false" {;
		
		display "Cleaning PII";
		run "`dodir'/clean_pii.do" `dataset_id';
		names_cleaning;
		names_missing;
		names_standardized;
		do "D:/Users/`c(username)'/Desktop/code/3_entity_resolution/Utility_Programs/agency_id_ori_code.do" `dataset_id';
		recode_standardization;
		validate_standardization `dataset_id';
		compress;		
		save "`output_dirs'/cleaned_pii_noimpute.dta", replace;
		
	
	};
	
	
	
end;
