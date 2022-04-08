/*==============================================================================
Localize
==============================
This script converts raw files into Stata's .dta format.

The script's logic will automatically convert most filetypes, but reverts to dataset-specific 
custom conversion scripts if they are present.

Output(s)
=========
- formatted Stata datasets converted from raw data files
==============================================================================*/

#delimit ;
capture program drop localize;
program define localize, rclass;
    /* 
        `dataset_id'    standard dataset id
        csvnonames         passed on to CSV
    */

    syntax anything(name=dataset_id)
        [, csvnonames];

    if substr("`dataset_id'", 1, 7) == "utility"{;
        display as error "ERROR: Utility files are no longer localized here.";
        assert substr("`dataset_id'", 1, 7) != "utility";
    };
    if strpos("`dataset_id'", "\") {;
        local dataset_id = subinstr("`dataset_id'", "\", "/", .);
    };
    if !strpos("`dataset_id'", "/") {;
        disp as error "`dataset_id' is not a valid dataset id.";
        exit;
    };
    disp "`dataset_id'";
    timer clear 64;
    timer on 64;
    /** GLOBALS ***********************************/
  
    /* Stat transfer program -- also a constant */
    global stat_transfer "C:/Program Files/StatTransfer13-64/st.exe";


    /** LOCALS ***********************************/

    /* Fix code -- placeholder will be created if nonexistent */
    local fixdir "${codedir}/1_localization/`dataset_id'";
    /* Data dictionary directory for fixed format files */
    local dictdir "`fixdir'/dictionaries";

    /* Raw data directory */
    local rawdir "O:/original/raw/`dataset_id'";
    cd "`rawdir'";

    /* Temporary "ready" storage post-dta, post-fix, pre-record-id */
    local readydir "${tempdir}/ready";

    /* Formatted data directory */
    local formatdir "O:/original/formatted/`dataset_id'";

    /*********************************************
        Create directories for temp and formatted files
    *********************************************/
	/*Create the directory for coding the PII*/
	shell mkdir "${codedir}/2_standardization/`dataset_id'";
	
    /* Temp files : If temp directory does not exist, create it. If temp
    directory exists, remove any files it contains to make sure no old
    tempfiles are included in the subsequent steps. */

    /* Make directories */
    shell mkdir "${tempdir}";
    shell mkdir "`readydir'";
    /* Remove any existing files */
    shell del /q "${tempdir}";
    shell del /q "`readydir'";

    /** All files in the raw data directory **/

    local raw_file_list : dir "`rawdir'" files "*";

    /* 
        Use stat transfer to create a .dta version of each file in directory
        ------------------------------------------
        --The output files are stored as tempfiles
        --This code accomodates:
            Fixed format types
                .dat
                .txt (non-delimited)
            Other file types:
                .xlsx and .xls (with single or multiple sheets)
                .mdb and .accdb (Access with multiple data tables)
                .csv and delimited .txt
                .dta (Stata)
                .sas7bdat (SAS)
                .sav (SPSS)
        --The program checks to see if a .dct file exists for a given filename.
        If it does, the program treats the file as fixed format. Otherwise, it
        processes the files using stat transfer.
    */

    local numrawfiles : word count `raw_file_list';
    display "Converting `numrawfiles' files for ${dataset_id}...";

	if `numrawfiles'==0 {;
		/* Check if there is `convert.do` for nested raw folder structures */
		capture confirm file "`fixdir'/convert.do";
		local has_convert_do = !_rc;
		if `has_convert_do' {;
			*if regexm("`file'", ",") {;
				*local file = subinstr("`file'",",","",.);
			*};
            do "`fixdir'/convert.do";
			*count;
			*if r(N)>0 {;
				*save "${tempdir}/`filename_clean'.dta", replace;
			*};
        };		
		
		
	};
	
    /* Convert each file individually */
    foreach file of local raw_file_list {;

        /* Ideally these would be deleted beforehand */
        if lower("`file'") == "thumbs.db" {;
            continue;
        };

        tokenize "`file'", parse(".");
        local fileparts = subinstr("`file'", ".", " ", .);
        /* Fix to properly get the last word */
        foreach part of local fileparts {;
            local extension = "`part'";
        };
        if "`file'" == "`part'" {;
            local filename="`file'";
            local extension = "[none]";
        };
        else {;
            local filename = regexr("`file'", "\.`extension'$", "");
        };
        /* Replace all spaces/dots with underscores */
		local filename = subinstr("`filename'", ".wp", "", 1);
        local filename_clean = subinstr("`filename'"," ","_",.);
        local filename_clean = subinstr("`filename_clean'",".","_",.);
        display " File: `file'    Extension: `extension'";
        display "Clean: `filename_clean'";


        capture confirm file "`fixdir'/convert.do";
        local has_convert_do = !_rc;
        capture confirm file "`dictdir'/`filename'.dct";
        local has_dct = !_rc;
		local no_dct=_rc;
        
    
        /* Check if a dictionary exists (for this file) */
        if `has_dct' {;
			clear;
            display "Using provided dictionary for fixed format file.";
            infile using "`dictdir'/`filename'.dct", clear;
            save "${tempdir}/`filename_clean'.dta", replace;
        };

        /* Check if this datasetid has a convert.do */
        else if `has_convert_do' & `no_dct' {;
			if regexm("`file'", ",") {;
				local file = subinstr("`file'",",","",.);
			};
            do "`fixdir'/convert.do" "`file'";
			count;
			if r(N)>0 {;
				save "${tempdir}/`filename_clean'.dta", replace;
			};
        };		
       
        /* No convert.do and no .dct: a standardized process to create dta */
        else {;
            /* Convert each sheet of Excel files */
            if inlist("`extension'","xls","xlsx"){;
                clear;
                odbc query "Excel Files;DBQ=`rawdir'/`file'",
                    dialog(complete);
                local table_tally `.__ODBC_INFO.TABLE.arrnels';
                local real_tables 0;
                forvalues i = 1/`table_tally' {;
                    if strpos("`.__ODBC_INFO.TABLE[`i']'", "$") {;
                        local real_tables = `real_tables' + 1;
                    };
                };
                if `real_tables' == 1 {;
                    shell "C:\Program Files\StatTransfer13-64\st.exe"
                    "`rawdir'/`file'" "${tempdir}/`filename_clean'.dta" -y;
                };
                else {;
                    /*  Multiple tables: must use Stata's ODBC, not StatTransfer */
                    forvalues i = 1/`table_tally'{;
                        clear;
                        local tablename `.__ODBC_INFO.TABLE[`i']';
                        if !strpos("`tablename'", "$") {;
                            disp "Skipping `tablename' -- expecting $ at end of valid name.";
                        };
                        else {;
                            local tablename_clean = subinstr("`tablename'", "_", "", .);
                            local tablename_clean = subinstr("`tablename_clean'", "$", "", .);
                            local tablename_clean = subinstr("`tablename_clean'", "&", "", .);
                            local tablename_clean = subinstr("`tablename_clean'", "'", "", .);
                            local tablename_clean = subinstr("`tablename_clean'", " ", "", .);
                            local final_file = "`filename_clean'_`tablename_clean'";
                            disp "Final filename: `final_file'.dta";
                            odbc desc "`tablename'";
							/* NOTE: The ``allstring`` option does NOT work well~ */
                            odbc load, table("`tablename'" ) allstring sqlshow;
                            save "${tempdir}/`final_file'.dta", replace;
                        };
                    };
                };
                clear;
            };
            /* Insheet CSVs. */
            else if inlist("`extension'","csv") {;
                clear;
                if "`csvnonames'"!="" {;
                    quietly import delimited using "`rawdir'/`filename'.csv",
                        csvnonames stringcols(_all);
                };
                else {;
                    quietly import delimited using "`rawdir'/`filename'.csv",
                        varnames(1) stringcols(_all);
                };
                save "${tempdir}/`filename_clean'.dta";
            };

            /* Convert each data table of Access files */
            else if inlist("`extension'","mdb","accdb"){;
                clear;
                quietly odbc query "MS Access Database;DBQ=`rawdir'/`file'", dialog(complete);
                local table_tally `.__ODBC_INFO.TABLE.arrnels';
                forvalues i = 1/`table_tally'{;
                    clear;
                    local tablename `.__ODBC_INFO.TABLE[`i']';
                    shell "${stat_transfer}" "`rawdir'/`file'"
                      "${tempdir}/`filename_clean'_`tablename'.dta" "-t`tablename'" -y;
                    display "The tempfile `filename_clean'_`tablename'.dta is saved.";
                };
            };

            /*
                For any non-handled data file types, we'll try StatTransfer
                Runs StatTransfer in the shell.
                -y option confirms okay to overwrite existing file.
            */
			
			else if inlist("`extension'", "dta") {;
				display "File is .dta and no stat transfer is needed";
				save "${tempdir}/`filename_clean'.dta";
			};
			
            else {;
                disp as error "Not sure what kind of file (extension=`extension') is.";
                disp as error "Trying a blind StatTransfer...";
                shell "${stat_transfer}" "`rawdir'/`file'"
                    "${tempdir}/`filename_clean'.dta" -y;
            };
        };
    };


    /* Run the fix.do file for this dataset */
    capture confirm file  "`fixdir'/fix.do";
    if !_rc {;
        cd "`fixdir'";
        do "`fixdir'/fix.do" "${tempdir}" "`readydir'";
    };
    /* Or create a placeholder if a fix.do does not exist. */
    else {;
        shell mkdir "`fixdir'";
        file open placeholder using "`fixdir'/fix.do", write;
        file write placeholder "/* Placeholder -- no fixes implemented. */" _n;
        file close placeholder;
        disp "Created placeholder `fixdir'/fix.do";
    };

    /* If no ready files have been created, that was a placeholder */
    local temp_dtas_list: dir "${tempdir}" files "*.dta";
	

    foreach file of local temp_dtas_list{;
        disp "Checking whether `readydir'/`file' was created...";
        capture confirm file "`readydir'/`file'";
        if !_rc {;
            disp "`file' handled by fix.do.";
        };
        else {;
            disp "`file' copied.";
            quietly copy "${tempdir}/`file'" "`readydir'/`file'";
        };
		
		capture erase "${tempdir}/`file'";
    };

    /* Loop through all files to create record_id and save */
    local file_id = 1;
    /* First capturing the number of files */
    local ready_list : dir "`readydir'" files "*";
    local numfiles : word count `ready_list';
    local file_id_len = strlen(string(`numfiles'));
    /* Add unique identifier to each row of each dataset
       Output files are saved in the directory created earlier. */

    /* Create and clear out the directory. */
    shell mkdir "`formatdir'";
    shell del /q "`formatdir'";
    foreach file of local ready_list{;
        use "`readydir'/`file'", clear;
        /*Make all variables uppercase*/
        quietly rename *, u;
        /* Pad with zeros. */
        local file_id_str = string(`file_id',"%0`file_id_len'.0f");
        gen_record_id `dataset_id' `file_id_str';
        /* Save formatted .dta file */
        save "`formatdir'/`file'";
		capture erase "`readydir'/`file'";
        local file_id = `file_id'+1;
    };
    clear;
	
    timer off 64;
    capture timer list 64;
    local run_seconds = round(r(t64));
    local run_m = int(`run_seconds'/60);
    local run_s = mod(`run_seconds', 60);
    disp "Runtime: `run_m'm `run_s's.";
end;
