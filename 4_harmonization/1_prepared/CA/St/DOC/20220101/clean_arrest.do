/*==============================================================================
TEMPLATE TO CLEAN ARREST DATA - For example, see Fort Worth/Police/20171110 file
User action is required to:
1. Change the working directory to location of the data
2. Load the appropriate data into stata memory - this could be either one file (STEP 2B)
	or multiple appended files (STEP 2A), depending on the data structure
3. Use gen_arrest_vars command to generate all CJARS arrest variables
4. Fill in all relevant CJARS arrest variables using replace statements
5. Check code by running validation exercises
6. Use keep_arrest_vars to keep only the CJARS arrest variables
7. Once all harmonization code for the data is complete, fill in the
	harmonization_cd_cmpl_dt in dataset.csv to signal that the data is ready to
	be harmonized

TIER 1 VARIABLES (High priority)
--------------------------------
+ arr_arr_dt_yyyy:			Arrest date year
+ arr_arr_dt_mm:			Arrest date month
+ arr_arr_dt_dd:			Arrest date day
+ arr_book_dt_yyyy:			Booking date year
+ arr_book_dt_mm:			Booking date month
+ arr_book_dt_dd:			Booking date day
+ arr_off_cd_src:			Raw offense code from source
+ arr_st_ori_fips:			State FIPS code (first 2 digits of a 5-digit county FIPS code as string)
+ arr_cnty_ori_fips:		County FIPS code (last 3 digits of a 5-digit county FIPS code as string)

TIER 2 VARIABLES (Next priority)
--------------------------------
+ arr_off_cd:				CJARS standardized offense code
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
Standardized Charge Codes
=========================
Fill in charge code (e.g. state statute), charge description, and charge grade 
as well as state of origin using `classify_offense` command.

Example:
	. classify_offense, state("tx") stub("TX/Co/Bexar/Sheriff/..") code(CHARGE_STATUTE) desc(CHARGE_DESC) grade(LEVEL);
	
Generates: (state_code state_description grade_raw grade mfj_code) where 
	arr_off_cd = mfj_code.
------------------------------------------------------------------------------*/
classify_offense, state("`state'") stub("`dataset_id'");

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
gen_arrest_vars;	// See: ..\code\4_harmonization\Utility_Programs\gen_arrest_vars.ado

/* STEP 4: Update variables generated from previous command (sample code from Fort Worth/Police/20171110) */
/*------------------*/
/* Tier 1 Variables */
/*------------------*/
/*Coding the booking date*/
replace arr_book_dt_yyyy = [PLACEHOLDER];
replace arr_book_dt_mm = [PLACEHOLDER];
replace arr_book_dt_dd = [PLACEHOLDER];

/*Coding the arrest date*/
replace arr_arr_dt_yyyy = [PLACEHOLDER];
replace arr_arr_dt_mm = [PLACEHOLDER];
replace arr_arr_dt_dd = [PLACEHOLDER];

/*Coding the raw offense code*/
replace arr_off_cd = mfj_code;
replace arr_off_cd_src = state_description;
replace arr_dv_off = dv;

/* County & State FIPS */
replace arr_st_ori_fips = [PLACEHOLDER];
replace arr_cnty_ori_fips = [PLACEHOLDER];

/*------------------*/
/* Tier 2 Variables */
/*------------------*/
/* Booking & Case Numbers */
*replace book_id = [PLACEHOLDER];
*replace case_id = [PLACEHOLDER];

/*Program to check for invalid dates. Any invalid dates will be set to missing and flagged in a .txt document in the harmonization directory*/
invalid_date_arrest `dataset_id';

/* STEP 5: Validation exercises to make sure that code is correct (stub_level_har_dqr included in validate ado files) */
validate_arrest `dataset_id';

/* STEP 6: Keep relevant event variables */
keep_arrest_vars;	// See: ..\code\4_harmonization\Utility_Programs\keep_arrest_vars.ado

/* STEP 7: Notify Code Reviewer After Pushing Code */

