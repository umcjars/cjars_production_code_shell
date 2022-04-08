/*==============================================================================
TEMPLATE TO CLEAN PROBATION DATA - For example, see
User action is required to:
1. Change the working directory to location of the data
2. Load the appropriate data into stata memory - this could be either one file (STEP 2B)
	or multiple appended files (STEP 2A), depending on the data structure
3. Use gen_probation_vars command to generate all CJARS probation variables
4. Fill in all relevant CJARS probation variables using replace statements
5. Check code by running validation exercises
6. Use keep_probation_vars to keep only the CJARS probation variables
7. Once all harmonization code for the data is complete, fill in the
	harmonization_cd_cmpl_dt in dataset.csv to signal that the data is ready to
	be harmonized

TIER 1 VARIABLES (High priority)
--------------------------------
+ pro_bgn_dt_yyyy:			Probation begin date year
+ pro_bgn_dt_mm:			Probation begin date month
+ pro_bgn_dt_dd:			Probation begin date day
+ pro_end_dt_yyyy:			Probation end date year
+ pro_end_dt_mm:			Probation end date month
+ pro_end_dt_dd:			Probation end date day
+ pro_st_ori_fips:			State FIPS code (first 2 digits of a 5-digit county FIPS code as string)
+ pro_cnty_ori_fips:		County FIPS code (last 3 digits of a 5-digit county FIPS code as string)
+ pro_st_juris_fips:		Agency State FIPS code

TIER 2 VARIABLES (Next priority)
--------------------------------
+ pro_cond_cd_src:			Raw probation conditions from source
+ pro_end_cd_src:			Raw probation exit status from source
+ pro_cond_cd:				CJARS standardized probation conditions
+ pro_end_cd:				CJARS standardized probation exit status (BJS probation exit codes)
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
Standardized Probation Condition Codes
======================================
Pass in probation description and state of origin using `classify_pro_cond` 
command.

Example:
	. classify_pro_cond, state("wa") desc(PROB_STATUS);
	
Generates: (pro_cond_code) used to set pro_cond_cd.
------------------------------------------------------------------------------*/
classify_pro_cond, state("`state'");

/*------------------------------------------------------------------------------
Standardized Probation Exit Codes
=================================
Pass in probation exit description and state of origin using `classify_pro_exit` 
command.

Example:
	. classify_pro_exit, state("wa") desc(PROB_TERM_STATUS);
	
Generates: (pro_exit_code) used to set pro_end_cd.
------------------------------------------------------------------------------*/
classify_pro_exit, state("`state'");

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
gen_probation_vars;	// See: ..\code\4_harmonization\Utility_Programs\gen_probation_vars.ado

/* STEP 4: Update variables generated from previous command by replacing [PLACEHOLDER] */
/*------------------*/
/* Tier 1 Variables */
/*------------------*/
/*Coding probation entry date*/
replace pro_bgn_dt_dd = [PLACEHOLDER];
replace pro_bgn_dt_mm = [PLACEHOLDER];
replace pro_bgn_dt_yyyy = [PLACEHOLDER];
/*Coding probation exit date*/
replace pro_end_dt_dd = [PLACEHOLDER];
replace pro_end_dt_mm = [PLACEHOLDER];
replace pro_end_dt_yyyy = [PLACEHOLDER];
/* County & State FIPS */
replace pro_st_ori_fips = [PLACEHOLDER];
replace pro_cnty_ori_fips = [PLACEHOLDER];
replace pro_st_juris_fips = [PLACEHOLDER];

/*------------------*/
/* Tier 2 Variables */
/*------------------*/
/*Coding probation conditions*/
replace pro_cond_cd = pro_cond_code;
replace pro_cond_cd_src = pro_cond_raw;
/*Coding probation exit status*/
replace pro_end_cd = pro_exit_code;
replace pro_end_cd_src = pro_exit_raw;
/* Booking & Case Number(s) */
*replace book_id = [PLACEHOLDER];
*replace case_id = [PLACEHOLDER];

/*Program to check for invalid dates. Any invalid dates will be set to missing and flagged in a .txt document in the harmonization directory*/
invalid_date_probation `dataset_id';

/* STEP 5: Validation exercises to make sure that code is correct (stub_level_har_dqr included in validate ado files) */
validate_probation `dataset_id';

/* STEP 6: Keep relevant event variables */
keep_probation_vars;	// See: ..\code\4_harmonization\Utility_Programs\keep_probation_vars.ado

/* STEP 7: Notify Code Reviewer After Pushing Code */

