/* Mandatory header **********************************************************/
#delimit ;
/* Mandatory header **********************************************************

    This code is run to replace missing fields with zeros in Dataset.csv to ensure
	accurate data processing for new stubs added to the repository.

******************************************************************************/

import delim "${codedir}/Dataset.csv", varn(1) delim(",");

foreach var in localization_run standardization_run impute_run entity_resolution_run supercluster_flag alias_drop state_roster_run national_roster_run cjars_id_push_run cjars_id_state_push_run harmonization_run combine_run episode_resolution_run metadata_run{;
	replace `var' = 0 if missing(`var') == 1;
};

foreach var in current_working_roster toc_vintage{;
	levelsof `var' if missing(`var') == 0, local(value);
	replace `var' = `value' if missing(`var') == 1;
};

export delim "${codedir}/Dataset.csv", replace delim(",");