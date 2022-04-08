/*==============================================================================
Deduplicate Probation Spells
============================
Utility program used to update probation spells with information from later 
extracts (if applicable). This is to prevent double counting duplicate spells in 
the final combined data from multiple data extracts.
==============================================================================*/
#delimit;
set trace off;
capture program drop probation_spell_resolution;
program define probation_spell_resolution, rclass;

	sort cjars_id pro_bgn_dt_yyyy;

	foreach var in pro_cond_cd pro_end_cd{;
		replace `var' = "" if `var'=="UU";
	};

	
		/* Generate spells */
		egen long spell_id = group(cjars_id pro_bgn_dt*), mi;
		
		/* Taking most descriptive source variable within spell */
		foreach var in pro_cond_cd_src pro_end_cd_src{;
			bys spell_id: gen src_len = strlen(`var');
			egen max_len = max(src_len), by(spell_id);
			gen src_flg = `var' if src_len==max_len;
			egen md_src = mode(src_flg), by(spell_id);
			replace `var' = md_src;
			drop src_len max_len src_flg md_src;
		};
		
		
		/* For each spell, replace the variable equal to the one corresponding to  */
		/* the modal value across the spells */
		foreach var in book_id case_id pro_cond_cd pro_cond_cd_src pro_end_cd pro_end_cd_src pro_st_ori_fips pro_cnty_ori_fips pro_st_juris_fips{;
			
			/* compute mode for if missing a variable value associated with max facility record */
			egen md_`var' = mode(`var'), by(spell_id) minmode;	
			
			/* create collapse var */
			gen coll_`var' = md_`var';
			drop md_`var';
		};
		
		/* create exit date, then deconstruct into components after collapsing */
		gen pro_end_dt_temp = mdy(pro_end_dt_mm, pro_end_dt_dd, pro_end_dt_yyyy);
		

		collapse (firstnm) coll_* (max) pro_end_dt_temp pro_rec_src_*
			, by(cjars_id pro_bgn_dt_yyyy pro_bgn_dt_mm pro_bgn_dt_dd);


		ren coll_* *;
		gen pro_end_dt_yyyy = year(pro_end_dt_temp);
		gen pro_end_dt_mm	 = month(pro_end_dt_temp);
		gen pro_end_dt_dd 	 = day(pro_end_dt_temp);
		drop pro_end_dt_temp;
		
		/* recoding for harmonization post-collapse */
		foreach var in pro_end_cd pro_cond_cd{;
			replace `var' = "UU" if `var'=="";
		};
		
		
		/* checking source variables have at least 1 indicator */
		egen chk = rowtotal(pro_rec_src_*);
		assert chk>=1 & chk!=.;
		drop chk;

		
		/* Harmonizing Nested and Overlapping Spells */
		gen entry_dt = mdy(pro_bgn_dt_mm, pro_bgn_dt_dd, pro_bgn_dt_yyyy);
		gen exit_dt = mdy(pro_end_dt_mm, pro_end_dt_dd, pro_end_dt_yyyy);
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
			replace pro_bgn_dt_mm = month(entry_dt_tmp) if pro_bgn_dt_mm!=month(entry_dt_tmp) & !mi(exit_dt_tmp);
			replace pro_bgn_dt_dd = day(entry_dt_tmp) if pro_bgn_dt_dd!=day(entry_dt_tmp)  & !mi(exit_dt_tmp);
			replace pro_bgn_dt_yyyy = year(entry_dt_tmp) if pro_bgn_dt_yyyy!=year(entry_dt_tmp)  & !mi(exit_dt_tmp);

			replace pro_end_dt_mm = month(exit_dt_tmp) if pro_end_dt_mm!=month(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace pro_end_dt_dd = day(exit_dt_tmp) if pro_end_dt_dd!=day(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			replace pro_end_dt_yyyy = year(exit_dt_tmp) if pro_end_dt_yyyy!=year(exit_dt_tmp)  & !mi(exit_dt_tmp) & !mi(exit_dt);
			
			/* Note: there will be a \emph{very} small (e.g., 35 / 500k) handful of observations with overlapping beginning dates during this stage.
				This is because of missing end dates which we preserve. Removing the non-missing exit_dt condition will bring in information
				from the special condition step on line 192. */
			
			drop entry_dt_tmp exit_dt_tmp entry_dt exit_dt cjars_id_sub;
			foreach var of varlist _all{;
				label var `var' "";
			};
			/* drop variables to deal with error in Michigan, but cannot recreate it outside of production run */
			cap drop total_ct;
			cap drop max_src;
			
			duplicates drop;
			cap order cjars_id book_id case_id pro_bgn_dt_* pro_cond_cd* pro_end_dt_* pro_end_cd* pro_st_ori_fips
				pro_cnty_ori_fips pro_st_juris_fips pro_rec_src*;
			

end;
