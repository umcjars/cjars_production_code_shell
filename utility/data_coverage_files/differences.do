clear

import delimited using "d:\Users\pappj\Desktop\code\utility\data_coverage_files\Dataset_Coverage.csv"


*This is used to understand whether or not ADJ coverage might be able to get split up
*keep if cjars_table == "ADJ" & coverage_source == "agency-documentation"

*checking ARR concordance
*keep if cjars_table == "ARR"
*Findings - no agency documentation for the ARR data


*checking INC concordance
/*
keep if cjars_table == "INC"
rename (start_month end_month snapshot_start) (start end snap)
replace coverage_source = "_data" if coverage_source == "data-driven"
replace coverage_source = "_agency" if coverage_source == "agency-documentation"
replace coverage_source = "_hand" if coverage_source == "hand-fix"
reshape wide snap start end, i(datasetid) j(coverage_source) string
order snap_agency snap_data snap_hand start_agency start_data end_agency end_data start_hand end_hand, after(datasetid)
drop cjars_table st_fips cnty_fips active_use

/* Findings - 
	CT - perfect match
	FL - observing early start
		 two things are unclear (1) should 1997 be actual start and (2) if we aren't processing this data accurately, this might impact calculated coverage
	IL - perfect match
	MI - transit data is a very close match 
		 scraped data start is early
	NJ - perfect match
	OH - perfect match
	WI - perfect match
*/
*/



/*
*checking PRO concordance
keep if cjars_table == "PRO"
rename (start_month end_month snapshot_start) (start end snap)
replace coverage_source = "_data" if coverage_source == "data-driven"
replace coverage_source = "_agency" if coverage_source == "agency-documentation"
replace coverage_source = "_hand" if coverage_source == "hand-fix"
reshape wide snap start end, i(datasetid) j(coverage_source) string
order snap_agency snap_data start_agency start_data end_agency end_data, after(datasetid)
drop cjars_table st_fips cnty_fips active_use

/* Findings - 
	FL - perfectly identifying snapshots
	MI - (movement) start date is off, but I question the agency knowledge
	     (scraped) start date is off, it thinks scraping date is start date even though the scraped data is three years of historical
	WI - perfect match
*/
*/



/*
*checking PAR concordance
keep if cjars_table == "PAR"
rename (start_month end_month snapshot_start) (start end snap)
replace coverage_source = "_data" if coverage_source == "data-driven"
replace coverage_source = "_agency" if coverage_source == "agency-documentation"
replace coverage_source = "_hand" if coverage_source == "hand-fix"
reshape wide snap start end, i(datasetid) j(coverage_source) string
order snap_agency snap_data start_agency start_data end_agency end_data, after(datasetid)
drop cjars_table st_fips cnty_fips active_use

/* Findings - 
	FL - accurately identifyng snapshots (one exception 20181031 stub)
	IL - perfect match
	MI - transit data is a prett close match (off by about 1 year) 
*/
*/

	