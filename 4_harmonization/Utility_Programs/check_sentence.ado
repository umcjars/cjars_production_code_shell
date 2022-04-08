/*==============================================================================
Utility program to ensure sentence variables are not all 0 and sets them to 
missing when relevant. Sentencing variables that are checked in this program are 
as follows:
- adj_sent_serv:		Community service
- adj_sent_dth:			Death sentence
- adj_sent_inc:			Incarceration length (months)
- adj_sent_pro:			Probation length (months)
- adj_sent_rest:		Restitution amount
- adj_sent_sus:			Suspended sentence
- adj_sent_trt:			Treatment sentence
- adj_sent_fine:		Fine amount
- adj_sent_inc_min:		Minimum incarceration sentence (months)
- adj_sent_inc_max:		Maximum incarceration sentence (months)
==============================================================================*/
#delimit;
program define check_sentence;

	foreach x in adj_sent_serv adj_sent_dth adj_sent_inc adj_sent_pro adj_sent_rest adj_sent_sus adj_sent_trt adj_sent_fine adj_sent_inc_min adj_sent_inc_max {;

		quietly count if `x'!=0 & !missing(`x');
		local count_1=r(N);
		quietly count if `x'==0;
		local count_0=r(N);

		if `count_1'==0 & `count_0'>0 {;
			replace `x'=.;
		};
	};

end;
