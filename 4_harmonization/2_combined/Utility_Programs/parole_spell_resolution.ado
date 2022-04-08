/*==============================================================================
Deduplicate Parole Spells
=========================
Utility program used to update parole spells with information from later extracts 
(if applicable). This is to prevent double counting duplicate spells in the final 
combined data from multiple data extracts.
==============================================================================*/
#delimit;
set trace off;
capture program drop parole_spell_resolution;
program define parole_spell_resolution, rclass;

	sort cjars_id par_bgn_dt_yyyy;

	foreach var in par_end_cd{;
		replace `var' = "" if `var'=="UU";
	};

	
		/* Generate spell */
		egen long spell_id = group(cjars_id par_bgn_dt*), mi;
		
		/* Taking most descriptive source variable within spell */
		foreach var in par_end_cd_src {;
			bys spell_id: gen src_len = strlen(`var');
			egen max_len = max(src_len), by(spell_id);
			gen src_flg = `var' if src_len==max_len;
			egen md_src = mode(src_flg), by(spell_id);
			replace `var' = md_src;
			drop src_len max_len src_flg md_src;
		};

		
		/* For each spell, replace the variable equal to the one corresponding */
		/*	tothe modal value across the spells */
		foreach var in book_id case_id par_end_cd par_end_cd_src par_st_ori_fips par_cnty_ori_fips par_st_juris_fips{;
			
			/* compute mode for if missing a variable value associated with max facility record */
			egen md_`var' = mode(`var'), by(spell_id) minmode;	
			
			/* create collapse var */
			gen coll_`var' = md_`var';
			drop md_`var';
		};
		
		/* create exit date, then deconstruct into components after collapsing */
		gen par_end_dt_temp = mdy(par_end_dt_mm, par_end_dt_dd, par_end_dt_yyyy);	

		
		collapse (firstnm) coll_* (max) par_end_dt_temp par_rec_src*
			, by(cjars_id par_bgn_dt_yyyy par_bgn_dt_mm par_bgn_dt_dd);
			
			
		ren coll_* *;
		gen par_end_dt_yyyy = year(par_end_dt_temp);
		gen par_end_dt_mm	 = month(par_end_dt_temp);
		gen par_end_dt_dd 	 = day(par_end_dt_temp);
		drop par_end_dt_temp;
		
		/* recoding for harmonization post-collapse */
		foreach var in par_end_cd{;
			replace `var' = "UU" if `var'=="";
		};
		
		
		/* checking source variables */
		egen chk = rowtotal(par_rec_src_*);
		assert chk>=1 & chk!=.;
		drop chk;

		
		
		/* Harmonizing Nested and Overlapping Spells */
		gen entry_dt = mdy(par_bgn_dt_mm, par_bgn_dt_dd, par_bgn_dt_yyyy);
		gen exit_dt = mdy(par_end_dt_mm, par_end_dt_dd, par_end_dt_yyyy);
		sort cjars_id entry_dt;
		
		by cjars_id: gen ct = _n;
		tostring ct, replace;
		gen cjars_id_sub = cjars_id + "_" + ct;
		drop ct;
		
		tempfile parole_base;
		save `parole_base', replace;
		
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
			use `parole_base', replace;
			merge 1:1 cjars_id_sub using `overlap_clean', assert(1 3) keep(3) nogen;

			/* Now the temp dates are the "spell bounds" so replace observed dates based on those */
			replace par_bgn_dt_mm = month(entry_dt_tmp) if par_bgn_dt_mm!=month(entry_dt_tmp) & !mi(exit_dt_tmp);
			replace par_bgn_dt_dd = day(entry_dt_tmp) if par_bgn_dt_dd!=day(entry_dt_tmp)  & !mi(exit_dt_tmp);
			replace par_bgn_dt_yyyy = year(entry_dt_tmp) if par_bgn_dt_yyyy!=year(entry_dt_tmp)  & !mi(exit_dt_tmp);

			replace par_end_dt_mm = month(exit_dt_tmp) if par_end_dt_mm!=month(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace par_end_dt_dd = day(exit_dt_tmp) if par_end_dt_dd!=day(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace par_end_dt_yyyy = year(exit_dt_tmp) if par_end_dt_yyyy!=year(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			
			/* Note: there will be a \emph{very} small (e.g., 35 / 500k) handful of observations with overlapping beginning dates during this stage.
				This is because of missing end dates which we preserve. Removing the non-missing exit_dt condition will bring in the information
				from the special condition step on line 191. */
			
			drop entry_dt_tmp exit_dt_tmp entry_dt exit_dt cjars_id_sub;
			foreach var of varlist _all{;
				label var `var' "";
			};
			/* drop variables to maintain consistency with probation code */
			cap drop total_ct;
			cap drop max_src;
			duplicates drop;
			cap order cjars_id book_id case_id par_bgn_dt* par_end_dt* par_end_cd* par_st_ori_fips
				par_cnty_ori_fips par_st_juris_fips par_rec_src*;
				
			/* One final exercise to deal with partial information from Texas where we only see the year that someone enters parole */
			preserve ;
				capture{;
					keep if !missing(par_bgn_dt_yyyy) & missing(par_bgn_dt_mm) & missing(par_bgn_dt_dd);
					drop book_id case_id;
					duplicates drop;
					tempfile missing_month_day;
					save "`missing_month_day'";
				};
			restore ;
			drop if !missing(par_bgn_dt_yyyy) & missing(par_bgn_dt_mm) & missing(par_bgn_dt_dd);
			capture merge m:1 cjars_id par_bgn_dt_yyyy using "`missing_month_day'", update nogen;


end;
