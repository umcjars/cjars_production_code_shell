/*==============================================================================
Harmonization Wrapper
=====================
Utility program for running harmonization. For each dataset in Dataset.csv, this 
probram checks for the following DO-files in relevant code folders:

- clean_arrest.do:			Harmonization code for arrests
- clean_adjudication.do:	Harmonization code for adjudication
- clean_incarceration.do:	Harmonization code for incarceration
- clean_parole.do:			Harmonization code for parole
- clean_probation.do:		Harmonization code for probation

After running `clean_*.do` codes, the program will save the harmonized data 
as `cleaned_*.dta` in relevant folder.
==============================================================================*/
#delimit;

program define harmonize, rclass;

    syntax anything(name=dataset_id);
    
    local prepared="${anondir}/1_prepared/`dataset_id'";
    
    local cleaned="${anondir}/2_cleaned/`dataset_id'";
    
    local combined="${anondir}/3_combined/`dataset_id'";
    
    local harmonize_code="${codedir}/4_harmonization/1_prepared/`dataset_id'";
    
	/*--------------------------------------------------------------------------
	Remove existing files in the cleaned anonymized directory
	--------------------------------------------------------------------------*/
    shell del /q "`cleaned'";
	
    clear;
    capture confirm file "`harmonize_code'/clean_arrest.do";
    
    if _rc==0 {;
        do "`harmonize_code'/clean_arrest.do" `dataset_id';
        save "`cleaned'/cleaned_arrest.dta", replace;
    };

    clear;
    capture confirm file "`harmonize_code'/clean_adjudication.do";
    
    if _rc==0 {;
        do "`harmonize_code'/clean_adjudication.do" `dataset_id';
        save "`cleaned'/cleaned_adjudication.dta", replace;
    };
    
    clear;
    capture confirm file "`harmonize_code'/clean_incarceration.do";
    
    if _rc==0 {;
        do "`harmonize_code'/clean_incarceration.do" `dataset_id';
        save "`cleaned'/cleaned_incarceration.dta", replace;
    };
    
    clear;
    capture confirm file "`harmonize_code'/clean_probation.do";
    
    if _rc==0 {;
        do "`harmonize_code'/clean_probation.do" `dataset_id';
        save "`cleaned'/cleaned_probation.dta", replace;
    };
    
    
    clear;
    capture confirm file "`harmonize_code'/clean_parole.do";
    
    if _rc==0 {;
        do "`harmonize_code'/clean_parole.do" `dataset_id';
        save "`cleaned'/cleaned_parole.dta", replace;
    };
    
end;
