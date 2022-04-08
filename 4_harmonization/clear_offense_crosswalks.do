/*==============================================================================
Clear Offense Crosswalks
========================
Utility program primarily used to remove existing offense crosswalks when the 
Text-based Offense Classification (TOC) model has been updated. This is done to 
prevent charge code classifications produced by outdated TOC model.
==============================================================================*/
#delimit;

adopath + D:/Users/`c(username)'/Desktop/code/ado;

clear;

set processors 6; // Use only ~50% of CPU

set max_memory 100g; // Use only 100gb of RAM


clear all ;
capture log close;

local XWALK_PATH = "O:/utility/cleaned/harmonization/offense_classification/cjars/cleaned";

local xwalks: dir "`XWALK_PATH'" files "cleaned_cjars_crosswalk_*.dta";

local num_xwalks: word count `xwalks';

if `num_xwalks'>0 {;
	foreach file of local xwalks {;
		capture erase "`XWALK_PATH'/`file'";
	};
};
