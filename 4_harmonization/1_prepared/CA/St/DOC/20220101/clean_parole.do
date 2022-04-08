/*==============================================================================
TEMPLATE TO CLEAN PAROLE DATA - For example, see
User action is required to:
1. Change the working directory to location of the data
2. Load the appropriate data into stata memory - this could be either one file (STEP 2B)
	or multiple appended files (STEP 2A), depending on the data structure
3. Use gen_parole_vars command to generate all CJARS parole variables
4. Fill in all relevant CJARS parole variables using replace statements
5. Check code by running validation exercises
6. Use keep_parole_vars to keep only the CJARS parole variables
7. Once all harmonization code for the data is complete, fill in the
	harmonization_cd_cmpl_dt in dataset.csv to signal that the data is ready to
	be harmonized

TIER 1 VARIABLES (High priority)
--------------------------------
+ par_bgn_dt_yyyy:			Parole begin date year
+ par_bgn_dt_mm:			Parole begin date month
+ par_bgn_dt_dd:			Parole begin date day
+ par_end_dt_yyyy:			Parole end date year
+ par_end_dt_mm:			Parole end date month
+ par_end_dt_dd:			Parole end date day
+ par_st_ori_fips:			State FIPS code (first 2 digits of a 5-digit county FIPS code as string)
+ par_cnty_ori_fips:		County FIPS code (last 3 digits of a 5-digit county FIPS code as string)
+ par_st_juris_fips:		Agency State FIPS code

TIER 2 VARIABLES (Next priority)
--------------------------------
+ par_end_cd_src:			Raw parole exit status from source
+ par_end_cd:				CJARS standardized parole exit status (BJS parole exit codes)
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
Standardized Parole Exit Codes
==============================
Pass in parole exit description and state of origin using `classify_par_exit` 
command.

Example:
	. classify_par_exit, state("tx") desc(PAROLE_STATUS);
	
Generates: (par_exit_code) used to set par_end_cd.
------------------------------------------------------------------------------*/
classify_par_exit, state("`state'");

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
gen_parole_vars;	// See: ..\code\4_harmonization\Utility_Programs\gen_parole_vars.ado

/* STEP 4: Update variables generated from previous command by replacing [PLACEHOLDER] */
/*------------------*/
/* Tier 1 Variables */
/*------------------*/
/*Coding parole entry date*/
replace par_bgn_dt_dd = [PLACEHOLDER];
replace par_bgn_dt_mm = [PLACEHOLDER];
replace par_bgn_dt_yyyy = [PLACEHOLDER];
/*Coding parole exit date*/
replace par_end_dt_dd = [PLACEHOLDER];
replace par_end_dt_mm = [PLACEHOLDER];
replace par_end_dt_yyyy = [PLACEHOLDER];
/* County & State FIPS */
replace par_st_ori_fips = [PLACEHOLDER];
replace par_cnty_ori_fips = [PLACEHOLDER];
replace par_st_juris_fips = [PLACEHOLDER];

/*------------------*/
/* Tier 2 Variables */
/*------------------*/
/*Coding parole exit status*/
replace par_end_cd = par_exit_code;
replace par_end_cd_src = par_exit_raw;
/* Booking & Case Number(s) */
*replace book_id = [PLACEHOLDER];
*replace case_id = [PLACEHOLDER];

/*Program to check for invalid dates. Any invalid dates will be set to missing and flagged in a .txt document in the harmonization directory*/
invalid_date_parole `dataset_id';

/* STEP 5: Validation exercises to make sure that code is correct (stub_level_har_dqr included in validate ado files) */
validate_parole `dataset_id';

/* STEP 6: Keep relevant event variables */
keep_parole_vars;	// See: ..\code\4_harmonization\Utility_Programs\keep_parole_vars.ado

/* STEP 7: Notify Code Reviewer After Pushing Code */

