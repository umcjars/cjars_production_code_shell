/*******************************************************************************
4 places where user action is required.
1. Load files that include PII data into memory
2. List the PII variables in the pii_var local macro.
3. Code PII variables into CJARS format
4. Save the code as clean_pii.do in the appropriate folder within 
	code/2_standardization/dataset_ID. 
******************************************************************************/


/******************************************************************************

				Cleaning the CA DOC data (example for demonstration)
				
******************************************************************************/
#delimit;

/******************************************************************************
1. Specify the files that should be loaded into memory. Note that this can be
either one file, or appending many files together.

an example is:

use "\\cjarsfs\data\original\formatted\<dataset_id>\data_-_mueller-smith_-_1980.dta";

or

/* Did you append ALL RELEVANT tables ? */

*******************************************************************************/

use "[FILE HERE]";
*OR'
append "[WRITE FILE1 FILE2 FILE3...]"

adopath + D:/Users/`c(username)'/Desktop/code/2_standardization/Utility_Programs;

/*This gen_cjars_vars is a user written command that generates all of the CJARS
PII variables.*/

gen_cjars_vars;


/******************************************************************************
Listing all of the PII variables that will be stripped from the data for the 
harmonization process. We will make a .txt file which lists these variables.
This .txt file will be recalled in the entity resolution process to create a 
harmonization data extract.
******************************************************************************/
/******************************************************************************
2. Insert PII variables between quotes below. An example is:
local pii_var "PII_VAR1 PII_VAR2 PII_VAR3....";
******************************************************************************/
local pii_var "[LIST PII_VARS HERE]";

/*Takes the argument and turns it into a local macro*/
local dataset_id="`1'";


preserve;
clear;

local j=0;
foreach x of local pii_var {;
	local j=`j'+1;
};

set obs `j';

gen pii_var="";

local i=1;

foreach x of local pii_var {;

	replace pii_var="`x'" if _n==`i';
	local i=`i'+1;
};

export delimit "${cleanpiidir}/`dataset_id'/pii_var.txt", delim(",") replace;

restore;
/******************************************************************************
3. Code the PII variables into CJARS format. We care about names, DOB, biometric
IDS (state, agency or county ID) and sex. 

3.1 Code all names as lower case

3.2 If there is one variable that contains a full address, do not spend
time coding it. Instead, use the address_raw variable. If the address is already 
split into components (as it is in this Harris County file), code them in cjars 
format. Below is an example using the Harris County District Clerk Data
*******************************************************************************/
/******************************************************************************
Name variables
*******************************************************************************/
/* Did you make sure name_raw is coded in [last name], [first name] [middle name] format? */
replace name_raw=DEF_NAM;
/******************************************************************************
Cleaning the raw name by making it lower case and removing data
inconsistencies.
******************************************************************************/
/* Did you make sure any alias information, if it exists, was fully utilized? (important for entity resolution) */ 

/* Don't forget to replace any placeholders like "restricted", "missing", "N/A"etc. 
with an empty string. Different datasets may use different placeholders, so examine
the data carefully. */

gen name_lower=strlower(DEF_NAM);
replace name_lower=strtrim(name_lower);
replace name_lower=subinstr(name_lower, " ,", ",", .);
replace name_lower=subinstr(name_lower, ", ", ",", .);
replace name_lower=subinstr(name_lower, "?", "", .);
replace name_lower=subinstr(name_lower, "_", " ", .);

/******************************************************************************
Using regular expression commands to code the suffix. Capturing any suffix that
appears after a comma and right before the end of the name string.
******************************************************************************/

replace name_suffix=regexs(1) if regexm(name_lower, 
	"[ ]+((jr)|(sr)|(ii)|(iii)|(iv)|(vi))[.]*$")==1;

/******************************************************************************
Using regular expression commands to remove the suffix from the raw name, once
it has been added to the name_suffix variable.
******************************************************************************/

replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[j][r][.]*$")==1;
replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[s][r][.]*$")==1;
replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[i][i][.]*$")==1;
replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[i][i][i][.]*$")==1;
replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[i][v][.]*$")==1;
replace name_lower=regexs(1) if regexm(name_lower, "(.*)[ ]+[v][i][.]*$")==1;

/******************************************************************************
Using regular expression commands to strip out the last, first and middle names.
The last name is anything that appears before the comma. The first name is the
first word that appears after the comma. The middle name is anything that 
appears after the first name. 
******************************************************************************/

replace name_last=regexs(1) if regexm(name_lower, "(.*),")==1;
replace name_first=regexs(1) if regexm(name_lower, ",[ ]*([.a-zA-Z\-]*)[ ]*")==1;
replace name_middle=regexs(1) if regexm(name_lower, ",[ ]*[.a-zA-Z\-]+[ ]+(.*)")==1;
replace name_middle=strtrim(name_middle);   


/******************************************************************************
Cleaning up suffixes that appear in the last name (before the comma in the raw
name.
******************************************************************************/
replace name_suffix=regexs(1) if regexm(name_last, 
	".*[ ]+((jr)|(sr)|(ii)|(iii)|(iv)|(vi))[.]*$")==1;
	
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[j][r][.]*$")==1 & name_suffix=="jr";
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[s][r][.]*$")==1 & name_suffix=="sr";	
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[i][i][.]*$")==1 & name_suffix=="ii";	
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[i][i][i][.]*$")==1 & name_suffix=="iii";	
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[i][v][.]*$")==1 & name_suffix=="iv";	
replace name_last=regexs(1) if regexm(name_last,
	"(.*)[ ]+[v][i][.]*$")==1 & name_suffix=="vi";	
	
replace name_middle=subinstr(name_middle, ".", "", .);
*Generate a middle initial;
replace name_middle_initial=substr(name_middle,1,1);

/******************************************************************************
Birth date variables
******************************************************************************/

tempvar birthdate;
gen `birthdate'=date(DEF_DOB, "YMD");

replace dob_dd=day(`birthdate');
replace dob_mm=month(`birthdate');
replace dob_yy=year(`birthdate');

/******************************************************************************
Capture 85 names that do not have commas in them
******************************************************************************/
gen tag=1 if name_last=="" & dob_mm!=.;
replace name_last=regexs(1) if regexm(name_lower, "^([.a-zA-Z\-]*)[ ]*")==1 & dob_mm!=. & name_last=="";
replace name_first=regexs(1) if regexm(name_lower, "^[.a-zA-Z\-]+[ ]([.a-zA-Z\-]*)[ ]*")==1 & dob_mm!=. & name_first=="";
replace name_middle=regexs(1) if regexm(name_lower, "^[.a-zA-Z\-]+[ ][.a-zA-Z\-]+[ ]([.a-zA-Z\-]*)")==1 & tag==1;
/* Did you make sure that first name, middle name, and last names do not contain any suffixes? Often times, first, middle and last names 
contain suffixes in various forms (e.g. Kim jr, jr kim, jr. kim etc.) */ 

/******************************************************************************
Gender : 1 if M(Male) and 2 if F(Female)
******************************************************************************/

/******************************************************************************
Race
Is the race coding in tandem with the standard race coding schema we have right now?
1 = white
2 = black
3 = Asian/Pacific Islander
4 = Hispanic
5 = American Indian / Native American
6 = Other
******************************************************************************/



/*******************************************************************************
State and agency IDs
*******************************************************************************/
tostring DEF_SPN, replace;
replace county_id=DEF_SPN;

/*We use the FIPS code of the county whenever relevant*/
replace county_id_ori="201";

/*We use the state FIPS code whenever relevant*/
replace state_id_ori="48";

/******************************************************************************
Address variables
*******************************************************************************/
/******************************************************************************
Cleaning and concatenating the address variable. In this data, the address is 
split into component parts so I do not need to use regular expressions. 
******************************************************************************/

replace addr_bldnum=strtrim(DEF_STNUM);
replace addr_str=strtrim(DEF_STNAM);

replace addr_city=strtrim(DEF_CTY);
replace addr_st=strtrim(DEF_ST);
tostring DEF_ZIP, replace;
replace addr_zip=strtrim(DEF_ZIP);

/******************************************************************************
Line below calls a program in the ado folder. This will keep 
only variables that are created by gen_cjars_vars. If there is another variable
that we need, feel free to contact Matt or Mike.
*******************************************************************************/

/***************************************************************************************************************************************************
 Before notifying the reviewer, always a good idea to run some lines of the validate file on your script 
Are name_raw and add_raw <= 30 string length? From my experience, this is the most frequent cause for getting flagged by validate_standardization 
******************************************************************************************************************************************************/

stub_level_std_dqr `dataset_id';

keep_cjars_vars;
