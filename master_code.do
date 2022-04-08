/* Mandatory header **********************************************************/
#delimit ;
adopath + D:/Users/`c(username)'/Desktop/code/ado;
*cjars_globals;
/* Mandatory header **********************************************************

    This code is run to format, standardize and construct a roster. The program
	master_code will be executed, and the user will have the choice of which
	steps should be completed by commenting out the unwanted steps.



    OPERATION

    1.  Write a line at the end of this file to run on dataset_id.


******************************************************************************/

clear all ;

/*Setting max memory that can be used at approximately 80% of total server memory
which is 256 gb*/
set max_memory 200g;

/** GLOBALS ***********************************/

/* Code */
global codedir "D:/Users/`c(username)'/Desktop/code";

/* Validation - do not run validation codes for harmonization to save time */
global VALIDATE = "0";

/* Crosswalks, both cleaned external and internal */
global crossdir "O:/utility/cleaned";

/* Ensure $tempdir available (without replacing any existing $tempdir) */
if "${tempdir}" == "" {;
	tempfile get_path;
	global tempdir = substr("`get_path'",1,strpos("`get_path'",".tmp")-1);
};

/* Cleaned data directory for formatted output */
global formatdir "O:/original/formatted/";

/*Location of the anonymized data*/
global anondir "O:/anonymized_records/";

/* Cleaned data directory for PII output */
global cleanpiidir "O:/pii/cleaned/";

/*Matching model directory*/
global modeldir "${codedir}/3_entity_resolution";

/*Location of the CJARS roster*/
global rosterdir "O:/pii/roster/";


do "${codedir}/utility/clean_dataset_csv.do";

do "${codedir}/1_localization/localize.do";

do "${codedir}/2_standardization/standardize.do";
do "${codedir}/2_standardization/impute_race_gender.do";

do "${codedir}/3_entity_resolution/entity_resolution.do";
do "${codedir}/3_entity_resolution/state_roster.do";
do "${codedir}/3_entity_resolution/cjars_id_push_state.do";

do "${codedir}/4_harmonization/harmonize.do";
do "${codedir}/4_harmonization/data_coverage.do";
do "${codedir}/4_harmonization/2_combined/combine.do";
do "${codedir}/4_harmonization/2_combined/all_state_combine.do";

