/*==============================================================================
Code agency ID
==============================
Generate agency ID based on dataset ID. Note that this is not an official ORI
but rather a CJARS-specific identifier.

Output(s)
=========
- agency_id_ori:			Formatted agency ID
==============================================================================*/

#delimit;

count if missing(agency_id_ori);
if r(N)>0 {;
    tempvar type_data;
    gen `type_data'=substr("`1'", 4, 2);
    
    if `type_data'=="St" {;
        tempvar state_agency;
        gen `state_agency'=regexs(1) if regexm("`1'", "/St/([A-Za-z]*)/")==1;
        replace agency_id_ori=substr("`1'", 1, 2)+"_"+`state_agency';
    };
    
    if `type_data'!="St" {;
        tempvar county mun location agency;
        gen `county'=regexs(1) if regexm("`1'", "/Co/([A-Za-z_]*)/")==1;
        gen `mun'=regexs(1) if regexm("`1'", "/Mu/([A-Za-z_]*)/")==1;
        gen `location'=`county' if `county'!="";
        replace `location'=`mun' if `mun'!="";
	    gen `agency'=regexs(1) if regexm("`1'", "/Mu/[A-Za-z_]*/([A-Za-z_]*)/")==1;
        replace `agency'=regexs(1) if regexm("`1'", "/Co/[A-Za-z_]*/([A-Za-z_]*)/")==1 & `agency'=="";

        replace agency_id_ori=substr("`1'", 1, 2)+"_"+substr("`1'", 4, 2)+"_"+`location'+"_"+`agency';
    };
	
};
