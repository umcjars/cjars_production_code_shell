* This do file calculates the phonex code for the variable
* `tophonex'.  The phonex code is contained in the new
* variable `phonexed'.  For documentation of the phonex
* algorithm, see Lait, A.J. and Randell, B., "An Assessment
* of Name Matching Algorithms," Technical Report Series-University
* of Newcastle Upon Tyne Computing Science, 1996

quietly{


gen workname=upper(tophonex)

* First remove any non-alpha characters

gen namelen=length(workname)
sum namelen
local longname=r(max)

replace workname=trim(workname)
replace workname=substr(workname,2,length(workname)-1) if regexm(substr(workname,1,1),"([A-Z])")~=1 & substr(workname,1,1)~=""

forvalues j=2(1)`longname'{
	replace workname=substr(workname,1,`j'-1)+substr(workname,`j'+1,length(workname)-`j') if regexm(substr(workname,`j',1),"([A-Z])")~=1 & substr(workname,`j',1)~=""
}


* Remove all trailing 'S' characters at the end of the name

replace workname=regexr(workname,"([S]+)$","")

* Convert special leading letter-pairs:

replace workname=subinstr(workname,"KN","N",1) if substr(workname,1,2)=="KN"
replace workname=subinstr(workname,"PH","F",1) if substr(workname,1,2)=="PH"
replace workname=subinstr(workname,"WR","R",1) if substr(workname,1,2)=="WR"

* Convert special leading single characters

replace workname=subinstr(workname,"H","",1) if substr(workname,1,1)=="H"
replace workname=subinstr(workname,"P","B",1) if substr(workname,1,1)=="P"
replace workname=subinstr(workname,"V","F",1) if substr(workname,1,1)=="V"
replace workname=subinstr(workname,"K","C",1) if substr(workname,1,1)=="K"
replace workname=subinstr(workname,"Q","C",1) if substr(workname,1,1)=="Q"
replace workname=subinstr(workname,"J","G",1) if substr(workname,1,1)=="J"
replace workname=subinstr(workname,"Z","S",1) if substr(workname,1,1)=="Z"
replace workname="A"+substr(workname,2,length(workname)-1) if substr(workname,1,1)=="E" | substr(workname,1,1)=="I" | substr(workname,1,1)=="O" | substr(workname,1,1)=="U" | substr(workname,1,1)=="Y"

* Code the pre-processed strings using the Phonex rules

gen fletter=substr(workname,1,1)
replace workname=substr(workname,2,length(workname)-1)
replace workname=workname+"#"

replace workname=subinstr(workname,"MD","M",.)
replace workname=subinstr(workname,"MG","M",.)
replace workname=subinstr(workname,"ND","N",.)
replace workname=subinstr(workname,"NG","N",.)

replace workname=subinstr(workname,"A","#",.)
replace workname=subinstr(workname,"E","#",.)
replace workname=subinstr(workname,"H","",.)
replace workname=subinstr(workname,"I","#",.)
replace workname=subinstr(workname,"O","#",.)
replace workname=subinstr(workname,"U","#",.)
replace workname=subinstr(workname,"W","",.)
replace workname=subinstr(workname,"Y","#",.)

replace workname=subinstr(workname,"B","1",.)
replace workname=subinstr(workname,"F","1",.)
replace workname=subinstr(workname,"P","1",.)
replace workname=subinstr(workname,"V","1",.)

replace workname=subinstr(workname,"C","*2",.)
replace workname=subinstr(workname,"G","2",.)
replace workname=subinstr(workname,"J","2",.)
replace workname=subinstr(workname,"K","2",.)
replace workname=subinstr(workname,"Q","2",.)
replace workname=subinstr(workname,"S","2",.)
replace workname=subinstr(workname,"X","2",.)
replace workname=subinstr(workname,"Z","2",.)

replace workname=subinstr(workname,"D","3",.)
replace workname=subinstr(workname,"T","3",.)
replace workname=subinstr(workname,"3*","",.)
replace workname=subinstr(workname,"3*","",.)

replace workname=subinstr(workname,"M","5",.)
replace workname=subinstr(workname,"N","5",.)

replace workname=subinstr(workname,"L#","4#",.)
replace workname=subinstr(workname,"L","",.)

replace workname=subinstr(workname,"R#","6#",.)
replace workname=subinstr(workname,"R","",.)

replace workname=subinstr(workname,"#","",.)
replace workname=subinstr(workname,"*","",.)


drop namelen
local i
forvalues i = 2(1)`longname' {
   replace workname=substr(workname,1,`i'-1)+"*"+substr(workname,`i'+1,length(workname)-`i') if (`i'<length(workname) | `i'==length(workname)) & (substr(workname,`i',1)==substr(workname,`i'-1,1))
}

replace workname=subinstr(workname,"*","",.)

* The value `codelength' determines the maximum number of coded characters (after
* the first character).  Adjust this to be longer or shorter as desired.  Standard 
* Phonex codes contain three digits after the initial character.

local codelength=3
forvalues i = 1(1)`codelength' {
   replace workname=workname+"0" if `i'>length(workname)
}
replace workname=substr(workname,1,`codelength')


gen phonexed=fletter+workname

drop fletter workname
}


