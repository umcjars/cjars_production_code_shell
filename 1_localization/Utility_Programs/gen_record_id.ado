#delimit ;
/*==============================================================================
Generate record id
==============================
Generate a unique record ID for each row in the localized data

Output(s)
=========
- record_id
==============================================================================*/
capture program drop gen_record_id;
program define gen_record_id, rclass;
    /*
        `1': First field (currently Dataset ID)
        `2': Middle field (currently sequential file id)
        Returns unique by-row record identifer
        gen_record_id AZ/St/DOC 3   -->      record_id
                                             AZ/St/DOC-3-0001
                                             AZ/St/DOC-3-0002
    */
    tempvar id;
	gen double `id' = _n;
    local len = ceil(log10(_N));
  	/* pad with leading 0s */
    gen record_id = string(`id',"%0`len'.0f");
    quietly replace record_id = "`1'" + "-" + "`2'" + "-" + record_id;
    capture order record_id;
end;
