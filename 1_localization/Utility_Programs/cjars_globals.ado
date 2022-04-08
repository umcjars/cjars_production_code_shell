/*
Set global CJARS Stata variables
*/
#delimit;

program define cjars_globals;

    /* Code */
    global codedir "D:/Users/`c(username)'/Desktop/code";

    /* Data */
    global cjars_data_dictionary "\\cjarsfs\data\utility\cleaned\cjars_data_dictionary.csv";

    /* Crosswalks, both cleaned external and internal */
    global crossdir "O:/utility/cleaned";

    /* Ensure $tempdir available (without replacing any existing $tempdir) */
    if "${tempdir}" == "" {;
        tempfile get_path;
        global tempdir = substr("`get_path'",1,strpos("`get_path'",".tmp")-1);
    };

end;
