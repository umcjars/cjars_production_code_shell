/*==============================================================================
All State Combine
=================
Utility wrapper program for combining harmonized data across states.
==============================================================================*/
#delimit ;
adopath + "${codedir}/4_harmonization/Utility_Programs";
adopath + "${codedir}/4_harmonization/2_combined/Utility_Programs";
clear all ;
set max_memory 200g;
capture log close;


all_state_combine;






