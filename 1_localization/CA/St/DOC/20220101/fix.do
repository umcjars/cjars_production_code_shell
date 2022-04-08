/* Placeholder -- no fixes implemented. */

/* Perform any cleaning or formatting needed before saving the localized data */

/* This example assumes that some unwanted files were converted and uses regular
expressions to clear them from the temp directory before they get copied to the 
formatted directory */

#delimit;

// This is the temp folder where files are saved after initial conversion
local tmp "`1'";
// This is the ready folder where files are moved after any additional cleaning, before being permanently saved
local rdy "`2'";

local file_list : dir "`tmp'" files "*";

/* Delete files whose names match a particular pattern */
foreach file of local file_list {;
	if !regexm("`file'", "some_pattern") {;
		erase "`tmp'/`file'";
	};
};