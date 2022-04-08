/*==============================================================================
names_cleaning
==============================
Clean name variables, removing special characters and shortening very long names

Output(s)
=========
- name_first
- name_middle
- name_last
==============================================================================*/

#delimit;

program define names_cleaning;
	
	tempvar p1 p2 length;
	
	foreach x of varlist name_first name_middle name_last {;
		replace `x'=subinstr(`x', "'","",.);
		replace `x'=subinstr(`x', "."," ",.);
		replace `x'=subinstr(`x', ","," ",.);
		replace `x'=subinstr(`x', "#"," ",.);
		replace `x'=subinstr(`x', "_"," ",.);
		replace `x'=subinstr(`x', "*"," ",.);
		replace `x'=subinstr(`x', "-"," ",.);	
		replace `x'=subinstr(`x', "\"," ",.);
		replace `x'=subinstr(`x', "/"," ",.);
		replace `x'=subinstr(`x', "+"," ",.);
   		replace `x'=subinstr(`x', "@"," ",.);
        replace `x'=subinstr(`x', "$"," ",.);
		replace `x'=subinstr(`x', "&"," and ",.);
		replace `x'=subinstr(`x', `"""'," ",.);
		replace `x'=subinstr(`x', "}"," ",.);	
		replace `x'=subinstr(`x', "{"," ",.);
		
		replace `x'=regexs(1) if regexm(`x', "(.*)[ ]aka[ ]")==1;
		
		replace `x'=subinstr(`x', "deceased", "", .);
		gen `p1'=strpos(`x', "(");
		gen `p2'=strrpos(`x', ")");
		gen `length'=length(`x');
		replace `x'=substr(`x',1,`p1')+substr(`x',`p2',`length') if `p1'>0 & `p2'>0;
		drop `p1' `p2' `length';
        replace `x'=subinstr(`x', "("," ",.);		
		replace `x'=subinstr(`x', ")"," ",.);		
		
		tempvar zero_`x';
        gen `zero_`x''=regexm(`x',"[a-z]0[a-z]");
        replace `x'=subinstr(`x',"0","o",.) if `zero_`x''==1;
		
		drop `zero_`x'';
        
        forval n=0/9 {;
			replace `x'=subinstr(`x', "`n'"," ", .);
		};
		
	

		replace `x'=strtrim(`x');
		replace `x'=stritrim(`x');
	};
	
	replace name_middle_initial=substr(name_middle, 1,1);
	
	replace name_raw=substr(name_raw, 1,50);
	recast str50 name_raw;
	
	foreach x of varlist name_first name_middle name_last {;
		replace `x'=substr(`x',1,30);
		recast str30 `x';
	};
	
end;
	