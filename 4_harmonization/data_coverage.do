/* Mandatory header **********************************************************/
#delimit ;
adopath + ${codedir}/4_harmonization/Utility_Programs;
cjars_globals;
/* Mandatory header **********************************************************

    This code is run to empirically document the coverage of the data from a
	data drive procedure if we don't otherwise have the relevant institutional
	knowledge.

    MAJOR TASKS

    -   Import each harmonized dataset.
	- 	Identify if the dataset is a snapshot or has continuous coverage.
	- 	Identify coverage start and stop dates if it is a continuous file.
	- 	Write to data coverage .csv if and only if the information is not already populated with hand-entered institutional information.


    OPERATION

    1.  Called from the master_code file. It should not be run on it's own.


******************************************************************************/

clear;
import delim "${codedir}/Dataset.csv", varn(1) delim(",");
keep if active_use==1 & harmonization_run > combine_run & harmonization_run != . ;
levelsof datasetid, local(dataset_ID);

// Testing a select set of datastubs for debugging the data coverage ado file.  Leave commented out unless troubleshooting.
foreach data of local dataset_ID{;

	clear;
	import delim "${codedir}/utility/data_coverage_files/Dataset_Coverage.csv", varn(1) delim(",");
	drop if coverage_source == "data-driven" & datasetid == "`data'";
	export delim "${codedir}/utility/data_coverage_files/Dataset_Coverage.csv", replace delim(",") datafmt;

	clear;
	data_coverage `data';

};

/*****************
 Now input the datasetid level coverage to generate two output files:
  1) First, a guidance file for the combine stage to indicate whether records should be "primary" or "secondary" sourced (e.g. charges from court records or from correctional records) or rely on state-level or county-level data sources (e.g. prioritize local TX court data over imprecise quasi-statewide iDocket data) 
  2) Second, a series of cjars-wide datasets that indicates coverage at the state/county level for producing data documentation information. 
*****************/
/* Setting up some utility files on all plausibly covered fips codes/states with associated population counts in 2018 */
clear;
import delim "O:\utility\raw\Census\State and County Populations\2010-2019\County_population_2010_2018.csv", varn(1) delim(",");
keep state county popestimate2018;
drop if state == 0 | county == 0;
rename state 	st_fips;
rename county 	cnty_fips;
tempfile county_pop;
save "`county_pop'", replace;

clear;
import delim "O:\utility\raw\Census\State and County Populations\2010-2019\State_population_2010_2019.csv", varn(1) delim(",");
keep state popestimate2018;
drop if state == 0;
rename state 	st_fips;
rename popestimate2018 st_popestimate2018;
tempfile state_pop;
save "`state_pop'", replace;

/* Task 1 - Create a guidance file for prioritizing overlapping/conflicting datasources */
clear;
import delim "${codedir}/utility/data_coverage_files/Dataset_Coverage.csv", varn(1) delim(",");

/*Hierarchy of coverage sources*/
gen cjars_discretion	= coverage_source == "hand-coded";
gen documentation 		= coverage_source == "agency-documentation";
gen empirical     		= coverage_source == "data-driven";

bys datasetid cjars_table st_fips cnty_fips: egen any_cjars_handcode = max(cjars_discretion);
bys datasetid cjars_table st_fips cnty_fips: egen any_agency_doc = max(documentation);
bys datasetid cjars_table st_fips cnty_fips: egen any_data_driven = max(empirical);
drop if empirical == 1 		& (any_cjars_handcode  == 1 | any_agency_doc == 1); // ignore data-driven if either agency documentation or a cjars verified entry exists
drop if documentation == 1 	& (any_cjars_handcode  == 1 ); // ignore agency documentation if a cjars verified entry exists

gen flag = start_month == "none" | end_month == "none"; // This code block allows series without any confirmed converage to still get processed in the combine stage. The 1900m1 should be ignored in all documentation and in the coverage files sent on to census.
replace start_month = "1900m1" if flag == 1;
replace end_month = "1900m1" if flag == 1;
drop flag;

foreach var in start_month end_month{;
	gen temp_var = monthly(`var', "YM");
	drop `var';
	rename temp_var `var';
};
gen 	src_primary = 0;
replace src_primary = 1 if cjars_table == "ARR" & (regexm(datasetid, "Sheriff") == 1 | regexm(datasetid, "Police") == 1);
replace src_primary = 1 if regexm(cjars_table, "ADJ") == 1 & (regexm(datasetid, "Judiciary") == 1 | regexm(datasetid, "Clerk") == 1 | regexm(datasetid, "Court") == 1 | (regexm(datasetid, "DPS") == 1 ) ); 
replace src_primary = 1 if regexm(cjars_table, "ADJ") == 1 & datasetid == "MO/St/DOC/20211020"; /*Adding in MO adjudication data since it acts like DPS data even though it came from a DOC. - MMS*/
replace src_primary = 1 if inlist(cjars_table, "INC", "PRO", "PAR") == 1 & (regexm(datasetid, "DOC") == 1 | regexm(datasetid, "DPS") == 1);

gen src_secondary = src_primary == 0;

gen src_state = regexm(datasetid, "St/") == 1;
gen src_local = src_state == 0;

preserve;
	keep if cnty_fips == "statewide";
	drop cnty_fips;
	joinby st_fips using "`county_pop'", unmatched(none); 
	drop popestimate2018;
	tempfile statewide_records;
	save "`statewide_records'", replace;
restore;
drop if cnty_fips == "statewide";
destring cnty_fips, replace;
append using "`statewide_records'";
preserve;
	keep if start_month == monthly("1900m1", "YM");
	tempfile none_entries;
	save "`none_entries'", replace;
restore;

drop if start_month == monthly("1900m1", "YM");
egen first_start = min(start_month);
summ first_start;
local begin = r(mean);
egen last_end = max(end_month);
summ last_end;
local end = r(mean);
local duration = `end' - `begin' + 1;
drop first_start last_end;
expand `duration';
bys datasetid st_fips cnty_fips cjars_table coverage_source:	gen month = [_n] + `begin' - 1;
format month start_month end_month %tm;
keep if month >= start_month & month <= end_month;
append using "`none_entries'";
replace month = monthly("1900m1", "YM") if start_month == monthly("1900m1", "YM");
bys datasetid cjars_table month: egen any_primary_coverage = max(src_primary);
drop if src_secondary == 1 & any_primary_coverage == 1;
bys datasetid cjars_table month: egen any_local_coverage = max(src_local);
drop if src_state == 1 & any_local_coverage == 1;
gen snapshot_begin = month == start_month & snapshot_start == 1;

collapse (max) src_primary src_secondary src_local src_state snapshot_begin, by(st_fips cnty_fips cjars_table month);
order  st_fips cnty_fips cjars_table month;
sort  st_fips cnty_fips cjars_table month;

bys st_fips cnty_fips cjars_table (month): gen coverage_spell = [_n];
bys st_fips cnty_fips cjars_table (month): replace coverage_spell = coverage_spell[_n-1] if (month == month[_n-1]+1 & month[_n-1] != .) & (src_primary == src_primary[_n-1] & src_primary[_n-1] != .) & (src_local == src_local[_n-1] & src_local[_n-1] != .);

bys st_fips cnty_fips cjars_table (month): egen first_month = min(month);
replace snapshot = 0 if month != first_month;

tempfile for_documentation;
save "`for_documentation'", replace;

collapse  (min) start_month = month (max) end_month = month snapshot src_*, by(st_fips cnty_fips cjars_table coverage_spell);
drop coverage_spell;

bys st_fips cnty_fips cjars_table (start_month): gen order = [_n];
reshape wide start_month end_month snapshot_begin src_primary src_secondary src_local src_state, i( st_fips cnty_fips cjars_table) j(order);

export delim "${codedir}/utility/data_coverage_files/Jurisdiction_Coverage_Guidance.csv", replace delim(",") datafmt;

/* Task #2 - Create Coverage information for documentation purposes*/
use "`for_documentation'", replace;

collapse snapshot src_*, by(st_fips cnty_fips cjars_table month);
merge m:1 st_fips cnty_fips using "`county_pop'", keep(master match) nogen;
merge m:1 st_fips using "`state_pop'", keep(master match) nogen;
preserve;
	collapse (mean) src_* [fw=popestimate2018], by(st_fip cjars_table month);
	tempfile src_vars;
	save "`src_vars'", replace;
restore;
collapse (sum) popestimate2018 (mean) st_popestimate2018, by(st_fip cjars_table month);
merge 1:1 st_fip cjars_table month using "`src_vars'", nogen;
gen share_covered = popestimate2018/st_popestimate2018;
/* We are claiming statewide coverage if we have 75% or more of the resident population in the state living in jurisdictions for which we hold relevant CJ records that are at least 75% primary sourced. */
gen 	coverage = "statewide" if share_covered >= .75 & src_primary >= .75 ; 
replace coverage = "partial" if share_covered < .75 | src_primary < .75 ;
replace coverage = "only-secondary" if src_primary < .05 ;
rename share_covered share_any_coverage;
rename src_primary   share_primary_coverage;
replace share_primary_coverage = share_primary_coverage*share_any_coverage;
replace share_any_coverage = round(share_any_coverage, 0.01);
replace share_primary_coverage = round(share_primary_coverage, 0.01);

order st_fips cjars_table month coverage share_any_coverage share_primary_coverage;
keep st_fips cjars_table month coverage share_any_coverage share_primary_coverage;

export delim "O:\output\data_documentation\metadata\coverage\Statewide_Coverage_Documentation.csv", replace delim(",") datafmt;

use "`for_documentation'", replace;
levelsof st_fips, local(states);
foreach st in `states'{;
	use "`for_documentation'", replace;
	keep if st_fips == `st';
	gen 	coverage = "primary"   if src_primary == 1;
	replace coverage = "secondary" if src_primary == 0;
	keep st_fips cnty_fips cjars_table month coverage; 
	export delim "O:\output\data_documentation\metadata\coverage\State_`st'_Coverage_Documentation.csv", replace delim(",") datafmt;
};
