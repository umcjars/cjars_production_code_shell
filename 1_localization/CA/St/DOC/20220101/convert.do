/* Placeholder -- no conversion implemented. Only necessary if files can't be 
imported by localize.ado 

If this file is present, it will be used to process each raw data file in turn.

The script takes a single filename as an argument - import the file and leave it
in memory.


This example deals with a potential situation where a single spreadsheet contains
multiple tables, which the default conversion logic will not be able to handle.

The example imports the tables separately and then appends them. It then merges
the resulting table with an external crosswalk containing statute information.
*/

#delimit;

local filename = "`1'";

local STATUTE = "path_to_statute_crosswalk.dta";

if "`filename'"=="example_file.xlsx" {;

	import excel using "example_file.xlsx", firstrow cellrange(A1:Q130) sheet("Sheet1") case(upper) all clear;
	tempfile tmp;
	save `tmp', replace;
	
	import excel using "example_file.xlsx", firstrow cellrange(A131:P4378) sheet("Sheet1") case(upper) all clear;
	
	append using `tmp';
	
	merge m:1 CHARGE_CODE using "`CSTATUTE'", keep(matched master) keepusing(CHARGE_DESC);
	drop _merge;
	
};