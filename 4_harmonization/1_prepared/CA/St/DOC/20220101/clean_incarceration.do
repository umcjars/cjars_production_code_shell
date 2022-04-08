/*==============================================================================
TEMPLATE TO CLEAN INCARCERATION DATA USING NJ DOC DATA
User action is required to:
1. Change the working directory to location of the data
2. Load the appropriate data into stata memory - this could be either one file (STEP 2B)
	or multiple appended files (STEP 2A), depending on the data structure
3. Use gen_incarceration_vars command to generate all CJARS incarceration variables
4. Fill in all relevant CJARS incarceration variables using replace statements
5. Check code by running validation exercises
6. Use keep_incarceration_vars to keep only the CJARS incarceration variables
7. Once all harmonization code for the data is complete, fill in the
	harmonization_cd_cmpl_dt in dataset.csv to signal that the data is ready to
	be harmonized

TIER 1 VARIABLES (High priority)
--------------------------------
+ inc_entry_dt_yyyy:		Entry date year
+ inc_entry_dt_mm:			Entry date month
+ inc_entry_dt_dd:			Entry date day
+ inc_exit_dt_yyyy:			Exit date year
+ inc_exit_dt_mm:			Exit date month
+ inc_exit_dt_dd:			Exit date day
+ inc_st_ori_fips:			State FIPS code (first 2 digits of a 5-digit county FIPS code as string)
+ inc_cnty_ori_fips:		County FIPS code (last 3 digits of a 5-digit county FIPS code as string)
+ inc_st_juris_fips:		Agency State FIPS code

TIER 2 VARIABLES (Next priority)
--------------------------------
+ inc_fcl_cd_src:			Raw facility type from source
+ inc_entry_cd_src:			Raw entry status from source
+ inc_exit_cd_src:			Raw exit status from source
+ inc_fcl_cd:				CJARS standardized facility type
+ inc_entry_cd:				CJARS standardized entry status
+ inc_exit_cd:				CJARS standardized exit status
+ book_id:					Cleaned booking number (if available)
+ case_id:					Cleaned case number (if available)
==============================================================================*/
#delimit;

clear;

set processors 2; // Use <25% of CPU

set max_memory 20g; // Use only 20gb of RAM

/* STEP 0: Add adopath containing gen_*.ado, keep_*.ado, and qa_assert.ado */
adopath + ${codedir}/4_harmonization/Utility_Programs;

/* STEP 1: Change working directory */
local dataset_id = "CA/St/DOC/20220101";	// Copy & paste dataset id from Dataset.csv
local state = lower(substr("`dataset_id'", 1, 2));
cd "O:/anonymized_records/1_prepared/`dataset_id'";	// Change directory to the anonymized dataset


/* STEP 2: Load relevant data file(s) */
local file_list: dir "O:/anonymized_records/1_prepared/`dataset_id'" files "*.dta";	// Store list of *.dta files as local macro `file_list'
foreach file of local file_list {;	// Loop over each file in the directory
	append using "`file'";	// Append files into one dataset
};
/* OR */
use [FILE_NAME];

/*------------------------------------------------------------------------------
Standardized Incarceration ENTRY Codes
=======================================
Fill in prison entry description and state of origin using `classify_inc_entry` 
command.

Example:
	. classify_inc_exit, state("wa") desc(ADMIT_MVRS_DE);
	
Generates: (inc_entry_code) where inc_entry_cd = inc_entry_code.
------------------------------------------------------------------------------*/
classify_inc_entry, state("`state'");

/*------------------------------------------------------------------------------
Standardized Incarceration EXIT Codes
=====================================
Fill in prison exit description and state of origin using `classify_inc_exit` 
command.

Example:
	. classify_inc_entry, state("wa") desc(REL_MVRS_DE);
	
Generates: (inc_exit_code) where inc_exit_cd = inc_exit_code.
------------------------------------------------------------------------------*/
classify_inc_entry, state("`state'");

/*------------------------------------------------------------------------------
Standardized Facility Codes
===========================
Fill in raw facility name, type of facility, and state of origin using 
`classify_facility` command.

Example:
	. classify_facility, state("wa");
	. classify_facility, state("nc") desc(FACILITY) type(SECURITY_LEVEL);
	
Generates: (facility_code) where inc_fcl_cd = facility_code.
------------------------------------------------------------------------------*/
classify_facility, state("`state'");

/*------------------------------------------------------------------------------
Clean Booking & Case Numbers
============================
Use `clean` command with `nop` and `nos` (no punctuation, no space) arguments 
for consistenct.

Example:
	. clean BOOKING_NUMBER CASE_NUMBER, nop(BOOKING_NUMBER CASE_NUMBER) nos(BOOKING_NUMBER CASE_NUMBER);
------------------------------------------------------------------------------*/
clean [PLACEHOLDER], nop([PLACEHOLDER]) nos([PLACEHOLDER]);

/* STEP 3: Generate the relevant variables */
gen_incarceration_vars;	// See: ..\code\4_harmonization\Utility_Programs\gen_incarceration_vars.ado

/* STEP 4: Update variables generated from previous command (sample code from NJ DOC) */
/*------------------*/
/* Tier 1 Variables */
/*------------------*/
/*Coding the prison entry date below*/
replace inc_entry_dt_yyyy = [PLACEHOLDER];
replace inc_entry_dt_mm = [PLACEHOLDER];
replace inc_entry_dt_dd = [PLACEHOLDER];

/*Coding the prison exit date*/
replace inc_exit_dt_yyyy = [PLACEHOLDER];
replace inc_exit_dt_mm = [PLACEHOLDER];
replace inc_exit_dt_dd = [PLACEHOLDER];

/* County & State FIPS */
replace inc_st_ori_fips = [PLACEHOLDER];
replace inc_cnty_ori_fips = [PLACEHOLDER];
replace inc_st_juris_fips = [PLACEHOLDER];

/*------------------*/
/* Tier 2 Variables */
/*------------------*/
/*Coding the facility type*/
replace inc_fcl_cd = facility_code;
replace inc_fcl_cd_src = facility_name;

/*Coding the entry status*/
replace inc_entry_cd = inc_entry_code;
replace inc_entry_cd_src = inc_entry_raw;

/*Coding the exity status*/
replace inc_exit_cd = inc_exit_code;
replace inc_exit_cd_src = inc_exit_raw;

/* Booking & Case Numbers */
*replace book_id = [PLACEHOLDER];
*replace case_id = [PLACEHOLDER];

/*Program to check for invalid dates. Any invalid dates will be set to missing and flagged in a .txt document in the harmonization directory*/
invalid_date_incarceration `dataset_id';

/* STEP 5: Validation exercises to make sure that code is correct (stub_level_har_dqr included in validate ado files) */
validate_incarceration `dataset_id';

/* STEP 6: Keep relevant event variables */
keep_incarceration_vars;	// See: ..\code\4_harmonization\Utility_Programs\keep_incarceration_vars.ado


/* STEP 7: Notify Code Reviewer After Pushing Code */

