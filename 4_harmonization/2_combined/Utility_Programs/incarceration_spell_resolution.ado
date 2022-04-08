/*==============================================================================
Deduplicate Incarceration Spells
================================
Utility program used to update incarceration spells with information from later 
extracts (if applicable). This is to prevent double counting duplicate spells in 
the final combined data from multiple data extracts.
==============================================================================*/
#delimit;
set trace off;
capture program drop incarceration_spell_resolution;
program define incarceration_spell_resolution, rclass;

	sort cjars_id inc_entry_dt_yyyy;
	
	local str_var "inc_fcl_cd inc_entry_cd inc_exit_cd";

	foreach var in `str_var'{;
		replace `var' = "" if `var'=="UU";
	};
	
	/* Hierarchical coding to partially account for transfers with the same start date - take most severe observed facility code
		and place an emphasis on ones that we know the location of. Note there is no obvious hierarchy for entry/exit codes,
		so we leave those as the modal non-missing code. */
	gen hier_fcl_code = .;
	replace hier_fcl_code = -1 if mi(inc_fcl_cd);						
	replace hier_fcl_code = 0 if inc_fcl_cd=="OT";						
	replace hier_fcl_code = 1 if inc_fcl_cd=="LJ";						
	replace hier_fcl_code = 2 if inc_fcl_cd=="CM";						
	replace hier_fcl_code = 3 if inc_fcl_cd=="MN" ;					
	replace hier_fcl_code = 4 if inc_fcl_cd=="MD" | inc_fcl_cd=="SP";
	replace hier_fcl_code = 5 if inc_fcl_cd=="MX"	;					
	replace hier_fcl_code = 6 if inc_fcl_cd=="FD" | inc_fcl_cd=="AD";	
	replace hier_fcl_code = -1 if inc_fcl_cd=="UN";
	assert hier_fcl_code!=.;

	
		/* For each spell, find the maximum facility code */
		egen long spell_id = group(cjars_id inc_entry_dt*), mi;
		egen max_facil = max(hier_fcl_code), by(spell_id);
		
		/* Taking most descriptive source variable within spell */
		foreach var in inc_entry_cd_src inc_exit_cd_src inc_fcl_cd_src{;
			
			/* want to preserve information associated with max facility if possible */
			gen max_src = `var' if hier_fcl_code==max_facil;
			bys spell_id: egen max_src_md = mode(max_src), minmode;
			
			/* otherwise take the longest string */
			bys spell_id: gen src_len = strlen(`var');
			egen max_len = max(src_len), by(spell_id);
			gen src_flg = `var' if src_len==max_len;
			egen md_src = mode(src_flg), by(spell_id);
			replace `var' = max_src_md if !mi(max_src_md);
			replace `var' = md_src if mi(max_src_md);
			drop src_len max_len src_flg md_src max_src max_src_md;
		};
		

		
		/* For each spell, replace the variable equal to the one corresponding to the max_facil entry, */
		/*	otherwise take the modal value across the spells */
		foreach var in book_id case_id inc_fcl_cd inc_fcl_cd_src inc_entry_cd inc_entry_cd_src inc_exit_cd inc_exit_cd_src inc_st_ori_fips inc_cnty_ori_fips inc_st_juris_fips{;
			
			/* initialize value equal to entry associated with max facility record */
			gen mx_`var' = `var' if hier_fcl_code==max_facil;
			egen mdmx_`var' = mode(mx_`var'), by(spell_id) minmode; 
			
			/* compute mode for if missing a variable value associated with max facility record */
			egen md_`var' = mode(`var'), by(spell_id) minmode;	
			
			/* create collapse var */
			gen coll_`var' = mdmx_`var';
			replace coll_`var' = md_`var' if mi(mdmx_`var') & !mi(md_`var');
			drop mx_`var' mdmx_`var' md_`var';
		};
		
		/* create exit date, then deconstruct into components after collapsing */
		gen inc_exit_dt_temp = mdy(inc_exit_dt_mm, inc_exit_dt_dd, inc_exit_dt_yyyy);
		

		collapse (firstnm) coll_* (max) hier_fcl_code inc_exit_dt_temp inc_rec_src*
			, by(cjars_id inc_entry_dt_yyyy inc_entry_dt_mm inc_entry_dt_dd);
			


		ren coll_* *;
		gen inc_exit_dt_yyyy = year(inc_exit_dt_temp);
		gen inc_exit_dt_mm	 = month(inc_exit_dt_temp);
		gen inc_exit_dt_dd 	 = day(inc_exit_dt_temp);
		drop inc_exit_dt_temp;
		
		/* recoding for harmonization post-collapse */
		foreach var in inc_entry_cd inc_exit_cd{;
			replace `var' = "UU" if `var'=="";
		};
		
		replace inc_fcl_cd = "UU" if hier_fcl_code==-1;
		drop hier_fcl_code;
		
		/* checking source variables */
		egen chk = rowtotal(inc_rec_src_*);
		assert chk>=1 & chk!=.;
		drop chk;
		

		
		
		/* Harmonizing Nested and Overlapping Spells */
		gen entry_dt = mdy(inc_entry_dt_mm, inc_entry_dt_dd, inc_entry_dt_yyyy);
		gen exit_dt = mdy(inc_exit_dt_mm, inc_exit_dt_dd, inc_exit_dt_yyyy);
		sort cjars_id entry_dt;
		
		by cjars_id: gen ct = _n;
		tostring ct, replace;
		gen cjars_id_sub = cjars_id + "_" + ct;
		drop ct;
		
		tempfile incarceration_base;
		save `incarceration_base', replace;
		
		keep cjars_id entry_dt exit_dt cjars_id_sub;
		collapse (firstnm) cjars_id_sub, by(cjars_id entry_dt exit_dt);
		
			/* Begin hybrid procedure that identifies nested and overlapping spells */
			egen min_entry = min(entry_dt), by(cjars_id);
			egen max_exit = max(exit_dt), by(cjars_id);
			
			gen bound_spell_obs = (min_entry==entry_dt & max_exit==exit_dt) if !mi(entry_dt) & !mi(exit_dt);
			egen max_bound = max(bound_spell_obs), by(cjars_id);
			gen drop_these = max_bound - bound_spell_obs ;
			drop if drop_these==1;
			drop drop_these;
			
			sort cjars_id entry_dt;
			gen drop_flag_full = 0;
			by cjars_id: gen ct = _n;
			sum ct;
			forvalues i = 1/`r(max)'{;
			
				gen exit_bound_t = exit_dt if ct==`i';
				egen exit_bound = mean(exit_bound_t), by(cjars_id);
				gen entry_bound_t = entry_dt if ct==`i';
				egen entry_bound = mean(entry_bound_t), by(cjars_id);
				
				/* Flagging spells that are completely contained in the other spell	*/
				replace drop_flag_full = 1 if (entry_dt > entry_bound) & (exit_dt < exit_bound)
					& !mi(entry_dt) & !mi(exit_dt) & !mi(entry_bound) & !mi(exit_bound)
					& ct!=`i';
				
				drop exit_bound* entry_bound*;	

			};
			
			drop if drop_flag_full==1;
			drop ct;
			
			sort cjars_id entry_dt;
			by cjars_id: gen ct = _n;
			
			/* Identifying partiall overlapping spells */
			gen partial_overlap_mn = 0;
			gen partial_overlap_mx = 0;
			sum ct;
			forvalues i = 1/`r(max)'{;
					
				by cjars_id: replace partial_overlap_mx = ct[_n] if (entry_dt[_n] <= exit_dt[_n-1])
					& (exit_dt[_n] >= exit_dt[_n-1]) & !mi(exit_dt) & !mi(entry_dt) & _n>1 & ct==`i';	
					
				by cjars_id: replace partial_overlap_mn = ct[_n] if (entry_dt[_n+1] <= exit_dt[_n])
					& (exit_dt[_n] >= exit_dt[_n-1]) & !mi(exit_dt) & !mi(entry_dt) & _n>1 & ct==`i';
			};
			
			/* End point condition */
			by cjars_id: replace partial_overlap_mx = ct[_n] if (entry_dt[_n+1] <= exit_dt[_n]) 
				& !mi(entry_dt[_n+1]) & !mi(exit_dt[_n]) & _n==1;
				
			/* Special condition for missing exit date in second spell but overlapping dates */
			by cjars_id: replace partial_overlap_mx = ct[_n] if (entry_dt[_n] <= exit_dt[_n-1]) 
				& mi(exit_dt[_n]) & !mi(exit_dt[_n-1]) & !mi(entry_dt) & !mi(entry_dt[_n-1]);
			
			egen overlap_cts = rowmax(partial_overlap*); 
			
			gen entry_dt_tmp = entry_dt;
			gen exit_dt_tmp = exit_dt;
			
			gen overlapping_spell = (overlap_cts>0);
			
			keep cjars_id entry_dt exit_dt entry_dt_tmp exit_dt_tmp overlapping_spell cjars_id_sub ;
			sort cjars_id entry_dt;
			by cjars_id: gen ct = _n;
			sum ct;
			forvalues i = 1/`r(max)'{;
			
				by cjars_id: replace entry_dt_tmp = entry_dt_tmp[_n-1] if overlapping_spell==1 & 
					entry_dt_tmp[_n-1] <= entry_dt_tmp[_n] & overlapping_spell[_n-1]==1;
					
				by cjars_id: replace exit_dt_tmp = exit_dt_tmp[_n+1] if overlapping_spell==1 & 
					exit_dt_tmp[_n] <= exit_dt_tmp[_n+1] & exit_dt_tmp[_n+1]!=. & overlapping_spell[_n+1]==1;
			
			};
			
			keep cjars_id entry_dt_tmp exit_dt_tmp cjars_id_sub;
			collapse (firstnm) cjars_id_sub, by(cjars_id entry_dt_tmp exit_dt_tmp);
			
			tempfile overlap_clean;
			save `overlap_clean';
			
			/* Merge back to pre-existing data */
			use `incarceration_base', replace;
			merge 1:1 cjars_id_sub using `overlap_clean', assert(1 3) keep(3) nogen;
				
			/* Now the temp dates are the "spell bounds" so replace observed dates based on those.
				Note that we only bound if we know the end date. */
			replace inc_entry_dt_mm = month(entry_dt_tmp) if inc_entry_dt_mm!=month(entry_dt_tmp) & !mi(exit_dt_tmp);
			replace inc_entry_dt_dd = day(entry_dt_tmp) if inc_entry_dt_dd!=day(entry_dt_tmp)  & !mi(exit_dt_tmp);
			replace inc_entry_dt_yyyy = year(entry_dt_tmp) if inc_entry_dt_yyyy!=year(entry_dt_tmp)  & !mi(exit_dt_tmp);
			replace inc_exit_dt_mm = month(exit_dt_tmp) if inc_exit_dt_mm!=month(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace inc_exit_dt_dd = day(exit_dt_tmp) if inc_exit_dt_dd!=day(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace inc_exit_dt_yyyy = year(exit_dt_tmp) if inc_exit_dt_yyyy!=year(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
		
			
			drop entry_dt_tmp exit_dt_tmp entry_dt exit_dt cjars_id_sub;
			foreach var of varlist _all{;
				label var `var' "";
			};
			/* drop variables to maintain consistency with probation code */
			cap drop total_ct;
			cap drop max_src;
			duplicates drop;
			cap order cjars_id book_id case_id inc_fcl_cd* inc_entry_dt* inc_entry_cd* inc_exit_dt* inc_exit_cd* 
				inc_st_ori_fips inc_cnty_ori_fips inc_st_juris_fips inc_rec_src*;
			

end;
