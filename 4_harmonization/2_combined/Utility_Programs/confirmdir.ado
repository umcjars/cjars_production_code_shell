/*==============================================================================
Confirm Directory
=================
Utility program to check if a folder exists. If it does, the program will 
change working directory to the file path passed in as the first positional 
argument.
==============================================================================*/
program define confirmdir, rclass
version 8

	local cwd `"`c(pwd)'"'
	quietly capture cd `"`1'"'
	local confirmdir=_rc
	quietly cd `"`cwd'"'
	return local confirmdir `"`confirmdir'"'
	
end
