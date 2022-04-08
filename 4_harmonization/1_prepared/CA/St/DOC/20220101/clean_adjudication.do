/*==============================================================================
TEMPLATE TO CLEAN ADJUDICATION DATA - For example, see TX\St\DOC\20180910_prob
User action is required to:
1. Change the working directory to location of the data
2. Load the appropriate data into stata memory - this could be either one file (STEP 2B)
	or multiple appended files (STEP 2A), depending on the data structure
3. Use gen_adjudication_vars command to generate all CJARS adjudication variables
4. Fill in all relevant CJARS adjudication variables using replace statements
5. Check code by running validation exercises
6. Use keep_adjudication_vars to keep only the CJARS adjudication variables
7. Once all harmonization code for the data is complete, fill in the
	harmonization_cd_cmpl_dt in dataset.csv to signal that the data is ready to
	be harmonized

TIER 1 VARIABLES (High priority)
--------------------------------
+ adj_grd_cd:				CJARS standardized offense grade
+ adj_grd_cd_src:			Raw offense grade from source (e.g. Felony, Citation, Misd.)
+ adj_disp_cd:				CJARS standardized disposition
+ adj_disp_cd_src:			Raw disposition from source
+ adj_file_dt_yyyy:			Filing date year
+ adj_file_dt_mm:			Filing date month
+ adj_file_dt_dd:			Filing date day
+ adj_disp_dt_yyyy:			Disposition date year
+ adj_disp_dt_mm:			Disposition date month
+ adj_disp_dt_dd:			Disposition date day
+ adj_sent_src:				Raw sentence from source
+ adj_sent_dt_yyyy:			Sentence date year
+ adj_sent_dt_mm:			Sentence date month
+ adj_sent_dt_dd:			Sentence date day
+ adj_sent_serv:			Community service (boolean)
+ adj_sent_dth:				Death sentence (boolean)
+ adj_sent_inc:				Incarceration length (in months)
+ adj_sent_pro:				Probation length (in months)
+ adj_sent_rest:			Restitution (in $ amount)
+ adj_sent_sus:				Suspended sentence (boolean)
+ adj_sent_trt:				Treatment sentence (boolean)
+ adj_sent_fine:			Sentence fines (in $ amount)
+ adj_sent_inc_min:			Sentence incarceration minimum (in months)
+ adj_sent_inc_max:			Sentence incarceration maximum (in months)
+ adj_st_ori_fips:			State FIPS code (first 2 digits of a 5-digit county FIPS code as string)
+ adj_cnty_ori_fips:		County FIPS code (last 3 digits of a 5-digit county FIPS code as string)

TIER 2 VARIABLES (Next priority)
--------------------------------
+ adj_off_dt_yyyy:			Offense date year
+ adj_off_dt_mm:			Offense date month
+ adj_off_dt_dd:			Offense date day
+ adj_off_lgl_cd:			CJARS standardized offense legal code
+ adj_off_lgl_cd_src:		Raw legal code from source (e.g., ordinance violation)
+ adj_chrg_off_cd_src:		Raw charge offense from source
+ adj_chrg_off_cd:			CJARS standardized charge offense
+ adj_disp_off_cd:			CJARS standardized disposition offense
+ adj_disp_off_cd_src:		Raw disposition offense from sourcece
+ book_id:					Cleaned booking number (if available)
+ case_id:					Cleaned case number (if available)
==============================================================================*/

#delimit;

clear all;

set processors 2; // Use <25% of CPU

set max_memory 20g; // Use only 20gb of RAM

/* STEP 0: Add adopath containing gen_*.ado, keep_*.ado, and qa_assert.ado */
if "${codedir}"=="" {;
	global codedir "D:/Users/`c(username)'/Desktop/code";
};
adopath + ${codedir}/4_harmonization/Utility_Programs;

/* STEP 1: Change working directory */
local dataset_id = "CA/St/DOC/20220101";	// Copy & paste dataset id from Dataset.csv
local state = lower(substr("`dataset_id'", 1, 2));
cd "O:/anonymized_records/1_prepared/`dataset_id'";	// Change directory to the anonymized dataset

/* STEP 2: Load relevant data file(s) */

/* ==========================================================================================================
Have you thoroughly understood the structure of the data to determine the right kind of merge (1:1? 1:m? etc) and which tables to use?

Is the pivot_id you are using to merge really the RIGHT PIVOD ID? (can it be really used to link different relationable tables?)
In some cases, variables that you thought was the pivot_id may only be a unique identifier within a table, not across tables
MD/St/Judiciary/a-e stubs are good examples (at a glimpse, ID seems to be the pivot id but CASE_NUMBER, in fact, is the real one)
After you merge two(or more) tables using that pivot id and discover barely any observations are matching with the master and using,
that probably means pivot_id you specified is not the correct one!
==============================================================================================================*/
local file_list: dir "O:/anonymized_records/1_prepared/`dataset_id'" files "*.dta";	// Store list of *.dta files as local macro `file_list'
foreach file of local file_list {;	// Loop over each file in the directory
	append using "`file'";	// Append files into one dataset
};
/* OR */
use [FILE_NAME];

/* ==========================================================================================================

Are you properly using classify_offense for coding adj_chrg_off_cd and adj_disp_off_cd? 
We default offense codes to fill in adj_disp_off_cd rather than adj_chrg_off_cd. 
Adj_chrg_off_cd should really only be filled in if we can confirm both variables and becuase they aren't 100% always the same thing
so usually we would just do the following:
classify_offense, state(`"state"') for creating variables relevant to adj_chrg_off_cd &
feed in all other relevant inputs for adj_disp_off_cd (e.g. classify_offense, state(`"state"') code(STATUTE) desc(OFFENSEDESCRIPTION)...)
========================================================================================================== */

/*------------------------------------------------------------------------------
Standardized Charge Codes
=========================
Fill in charge code (e.g. state statute), charge description, and charge grade 
as well as state of origin using `classify_offense` command.

Example:
	. classify_offense, state("tx") stub("TX/Co/Bexar/Sheriff/..") code(CHARGE_STATUTE) desc(CHARGE_DESC) grade(LEVEL);
	
Generates: (state_code state_description grade_raw grade mfj_code) where 
	adj_chrg_off_cd = mfj_code. Rename if data provides both charge and 
	disposition offense information.
------------------------------------------------------------------------------*/
classify_offense, state("`state'") stub("`dataset_id'");
rename (state_code state_description grade_raw grade mfj_code dv) (charge_code charge_desc charge_grade_raw charge_grade mfj_charge charge_dv);

/*------------------------------------------------------------------------------
Standardized Offense Codes
==========================
Fill in offense code (e.g. state statute), offense description, and offense grade 
as well as state of origin using `classify_offense` command. Note that the most 
important arguments are `desc` (string offense description) and `grade` (e.g. 
felony, misdemeanor, etc.).

Example:
	. classify_offense, state("tx") stub("TX/Co/Bexar/Sheriff/..") code(STATUTE) desc(OFFENSE) grade(GRADE);

Generates: (state_code state_description grade_raw grade mfj_code) where 
	adj_disp_off_cd = mfj_code.
------------------------------------------------------------------------------*/
classify_offense, state("`state'") stub("`dataset_id'");
rename (state_code state_description grade_raw grade mfj_code dv) (offense_code offense_desc offense_grade_raw offense_grade mfj_offense disp_dv);
egen dv = rowmax(charge_dv disp_dv);

/*------------------------------------------------------------------------------
Standardized Disposition Codes
==============================
If there is a variable for disposition outcome, use that to set adj_disp_cd_src 
(fill in [PLACEHOLDER]) below and code it accordingly to the schema listed below 
as comment headers. If not, set `disp_raw` to missing string.
------------------------------------------------------------------------------*/
gen disp_raw = strtrim(stritrim(lower([PLACEHOLDER])));
*gen disp_raw = "";
gen disp_code = "";
/*** DU - Diversion-Unclassified ***/
replace disp_code = "DU" if inlist(disp_raw, "");
/*** GC - Guilty-Court Trial ***/
replace disp_code = "GC" if inlist(disp_raw, "");
/*** GJ - Guilty-Jury Trial ***/
replace disp_code = "GJ" if inlist(disp_raw, "");
/*** GP - Guilty-Plea ***/
replace disp_code = "GP" if inlist(disp_raw, "");
/*** GI - Guilty-Insanity ***/
replace disp_code = "GI" if inlist(disp_raw, "");
/*** GU - Guilty-Unclassified (Incl. Appeal Affirmed/Revoked/Writ Granted) ***/
replace disp_code = "GU" if inlist(disp_raw, "");
/*** NA - Acquittal ***/
replace disp_code = "NA" if inlist(disp_raw, "");
/*** ND - Dismissal ***/
replace disp_code = "ND" if inlist(disp_raw, "");
/*** NI - Dismissal-Insanity ***/
replace disp_code = "NI" if inlist(disp_raw, "");
/*** NM - Mistrial ***/
replace disp_code = "NM" if inlist(disp_raw, "");
/*** NP - Not Guilty Plea ***/
replace disp_code = "NP" if inlist(disp_raw, "");
/*** NU - Not Guilty-Unclassified ***/
replace disp_code = "NU" if inlist(disp_raw, "");
/*** PT - Procedural-Transfer (Incl. Appeal Remanded/Reversed) ***/
replace disp_code = "PT" if inlist(disp_raw, "");
/*** PU - Procedural-Unclassified ***/
replace disp_code = "PU" if inlist(disp_raw, "");
/*** UU - Unknown ***/
replace disp_code = "UU" if missing(disp_code);
ta disp_raw if disp_code=="UU";

/*------------------------------------------------------------------------------
Generate Disposition Crosswalk for Review
=========================================
Saves a list of disposition descriptions missing standardized code for further 
review. These crosswalks are saved as 
`O:/output/disposition/{State}_{Level}_{Geography}_{Agency}_{IntakeDate}.dta`
------------------------------------------------------------------------------*/
validate_disposition, dataset("`dataset_id'") desc(disp_raw) code(disp_code);

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
gen_adjudication_vars;	// See: ..\code\4_harmonization\Utility_Programs\gen_adjudication_vars.ado

/*------------------------------------------------------------------------------
Standardized Offense Legal Code
===============================
- For adjudication imputed from (e.g.) DOC data, set `adj_off_lgl_cd_src` to "PRISON RECORD"
	+	If not sure, consult with the data collection team for clarification
- For standardized `adj_off_lgl_cd`:
	+ "ST" for state cases
	+ "OR" for ordinance
	+ "UU" for others as determined by the data collection team
------------------------------------------------------------------------------*/
replace adj_off_lgl_cd = [PLACEHOLDER];
replace adj_off_lgl_cd_src = [PLACEHOLDER];

/* STEP 4: Update variables generated from previous command by replacing [PLACEHOLDER] */
/*------------------*/
/* Tier 1 Variables */
/*------------------*/

/* ========================================================================================
Are the date variables being processed correctly? 
Commands like date( ) can run without any issues 
but the date vars might be populated with missing values (e.g. string var with dates containing 2byte format for years, then
date( ) won't work unless you specify which century it is ==> date(date, ""MDY"", 2020))
======================================================================================== */

/* Offense Grade */
replace adj_grd_cd = offense_grade;
replace adj_grd_cd_src = offense_grade_raw;

/* Disposition */
replace adj_disp_cd = [PLACEHOLDER];
replace adj_disp_cd_src = [PLACEHOLDER];

/* File Date */
replace adj_file_dt_yyyy = [PLACEHOLDER];
replace adj_file_dt_mm = [PLACEHOLDER];
replace adj_file_dt_dd = [PLACEHOLDER];

/* Disposition Date */
replace adj_disp_dt_yyyy = [PLACEHOLDER];
replace adj_disp_dt_mm = [PLACEHOLDER];
replace adj_disp_dt_dd = [PLACEHOLDER];

/* Sentence Date */
replace adj_sent_dt_yyyy = [PLACEHOLDER];
replace adj_sent_dt_mm = [PLACEHOLDER];
replace adj_sent_dt_dd = [PLACEHOLDER];

/* Sentence Information */
replace adj_sent_src = [PLACEHOLDER];
replace adj_sent_serv = [PLACEHOLDER];
replace adj_sent_dth = [PLACEHOLDER];

/* ===========================================================================================================
You can use calculate_incarceration.ado for calculating incarceration duration (adj_sent_inc) 
if you are given incarceration_yr, incarceration_month, incarceration_days variables. 
You don’t have to manually change the data type of those three variables into strings 
because the ado program already changes the values into strings in the first part of the script.
Same for calculating probation duration (adj_sent_pro) 
You can use calculate_probation.ado using probation_yr, probation_month, and probation_days as three inputs
Set adj_sent_inc to -99999 if death sentence, set adj_sent_inc to -88888 if it is prison for life
============================================================================================================ */
replace adj_sent_inc = [PLACEHOLDER];
replace adj_sent_pro = [PLACEHOLDER];

replace adj_sent_rest = [PLACEHOLDER];
replace adj_sent_sus = [PLACEHOLDER];
replace adj_sent_trt = [PLACEHOLDER];
replace adj_sent_fine = [PLACEHOLDER];
replace adj_sent_inc_min = [PLACEHOLDER];
replace adj_sent_inc_max = [PLACEHOLDER];

/* State & County of Conviction FIPS */
replace adj_st_ori_fips = [PLACEHOLDER];
replace adj_cnty_ori_fips = [PLACEHOLDER];

/*Program to make sure sentence variables are not all 0. Sets to missing when relevant*/
check_sentence;

/*------------------*/
/* Tier 2 Variables */
/*------------------*/
/* Offense Date */
replace adj_off_dt_yyyy = [PLACEHOLDER];
replace adj_off_dt_mm = [PLACEHOLDER];
replace adj_off_dt_dd = [PLACEHOLDER];
/* Offense Charged */
replace adj_chrg_off_cd = mfj_charge;
replace adj_chrg_off_cd_src = charge_desc;
/* Offense Disposed */
replace adj_disp_off_cd = mfj_offense;
replace adj_disp_off_cd_src = offense_desc;
replace adj_dv_off = dv;

/* Booking & Case Number */
*repalce book_id = "";
*replace case_id = "";

/*Program to check for invalid dates. Any invalid dates will be set to missing and flagged in a .txt document in the harmonization directory*/
invalid_date_adjudication `dataset_id';

/* STEP 5: Validation exercises to make sure that code is correct (stub_level_har_dqr included in validate ado files) */
validate_adjudication `dataset_id';

/* ============================================================================================================
Check for any "duplicates drop" statements you used throughout the script. 
This may lead to loss of precious observations we wanted to preserve. 
If you really think duplicates drop is necessary, just do ""duplicates drop"" on all variables instead of specifiying 
certain subsets of columns and forcing it (e.g. duplicates drop var1 var2... , force)"

"After you successfully run your harmonization code, the validate_adjudication will return missing rates at the end of the log. 
Make sure the missing rates(%) of categorical vars (e.g. adj_grd_cd) are looking normal 
(e.g. if the missing rate is 100%, then you know something is wrong -- either the offense_classify.ado or some part of your coding scheme). 
If it's some new data stub for which offense_CLASSIFY is not working as well, 
you might want to google external data / crosswalk to merge into so that you can manually fill in those missing adj_grd_cd 
(e.g. MD/St/Judiciary/e ) is a good example"
============================================================================================================ */

/* STEP 6: Keep relevant event variables */
keep_adjudication_vars;	// See: ..\code\4_harmonization\Utility_Programs\keep_adjudication_vars.ado

/* STEP 7: Notify Code Reviewer After Pushing Code */
