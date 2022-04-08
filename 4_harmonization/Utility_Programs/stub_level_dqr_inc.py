#!/usr/bin/env python
# coding: utf-8

################## Stub Level DQR -- Incarceration #####################

# Subscript that is called by stub_level_dqr_with_dcteam.py for Court data harmonization.
# Calculates the following dimensions of the data and saves them as csv or html files.

# - table and line graphs for caseload counts over time of variables inc_entry_dt* and inc_exit_dt*
# - composition (count & pct) of:
#     - inc_flc_cd
#     - inc_entry_cd
#     - inc_exit_cd
#     - inc_st_ori_fips
#     - inc_cnty_ori_fips
#     - missing/non missing cjars_ids
########################

# Relevant Libraries
import pandas as pd
import numpy as np
from pandas import DataFrame, Series
import time, re, datetime
import os, sys, glob
from os import listdir
from os.path import isfile, join

pd.set_option('max_colwidth', 256)
pd.set_option('display.max_rows', 9000)
pd.set_option('display.max_columns', 100)

import matplotlib.pyplot as plt
import seaborn as sns
plt.style.use("ggplot")
sns.set_style("whitegrid")

full_inc_path = "O:/anonymized_records/2_cleaned/NE/St/DOC/20210206/cleaned_incarceration.dta"

path_to_save = "O:/output/adqc_reports/stub_level_dqr/"


# In[1]:


import random

randint = random.randint(0,1000)
randint = str(randint)


# ### Preparing NPS and NCRP Data for stub level benchmarking 

# Reading in NPS Data
nps = pd.read_stata("O:/_temp/benchmarking/2020/validation data/National/NPS/data/1978-2018/DS0001/37639-0001-Data.dta",
                   convert_categoricals=False)


nps['nps_entry'] = nps.ADTOTM + nps.ADTOTF
nps['nps_exit'] = nps.RLTOTM + nps.RLTOTF
nps_count = nps.copy()[['STATEID','STATE','YEAR','nps_entry','nps_exit']]

# Reading in 2019 NPS data
p19t08 = pd.read_csv("O:/_temp/benchmarking/2020/validation data/National/prisoners_in/p19t08.csv", encoding="unicode_escape",
           header=11, thousands=',')

# Keep only the relevant columns
p19t08 = p19t08.copy()[['Unnamed: 1', '2019 total', '2019 total.1' ]]

# Change column names to appropriate naming
p19t08.columns = ['STATE', 'nps_entry','nps_exit']

# Create new column called YEAR to be able to append to the master table
p19t08['YEAR'] = 2019

# Keep only the relevant rows
p19t08 = p19t08.copy().iloc[3:,:]

# Drop rows with ALL NULL VALUES
p19t08 = p19t08.copy()[p19t08.STATE.notnull()]


# Change state names to state abbreviations so that I can merge the 2019 count to the master count table
state_name_replace_dic = {'Alabama':'AL', 'Alaska/h':'AL','Arizona':'AZ', 'Arkansas':'AK', 'California':'CA',
                         'Colorado':'CA','Connecticut/h':'CT','Delaware/h,i':'DE','Florida/j':'FL','Georgia':'GA',
                         'Hawaii/h':'HI','Idaho':'ID','Illinois/k':'IL','Indiana':'IN','Iowa':'IA','Kansas':'KS',
                         'Kentucky':'KY', 'Louisiana':'LA','Maine/l':'ME','Maryland/m':'MD','Massachusetts':'MA',
                         'Michigan':'MI','Minnesota':'MN','Mississippi':'MS','Missouri':'MO','Montana':'MT',
                          'Nebraska':'NE','Nevada/n':'NV','New Hampshire':'NH','New Jersey':'NJ','New York':'NY',
                          'North Carolina':'NC','North Dakota/o':'ND','Ohio/o':'OH','Oklahoma':'OK','Oregon/p':'OR',
                          'Pennsylvania':'PA','Rhode Island/h':'RI','South Carolina':'SC','Tennessee':'TN',
                          'Texas':'TX','Utah':'UT', 'Vermont/h,p':'VT','Virginia/q':'VA','Washington/o':'WA',
                          'West Virginia':'WV','Wisconsin':'WI','Wyoming':'WY', 'New Mexico/o':'NM',
                         'South Dakota':'SD'}

p19t08['STATE'] = p19t08['STATE'].replace(state_name_replace_dic)

# Append 2019 count data to the master count table
nps_count = pd.concat([nps_count, p19t08], axis=0)

# Fill in missing stateid using the values of the same STATE group observations
nps_count['STATEID'] = nps_count.groupby('STATE')['STATEID'].ffill().bfill()


# **NCRP**

# Read in NCRP Admissions data
ncrp_adm =pd.read_stata("O:/_temp/benchmarking/2020/validation data/National/NCRP/data/admissions/data/1991-2016/DS0002/37021-0002-Data.dta")

# Change Datatype of STATE variable to string from category
ncrp_adm['STATE'] = ncrp_adm['STATE'].astype("str")

# NCRP Admission Count
ncrp_adm_count = ncrp_adm.groupby(['STATE','ADMITYR']).size().to_frame()
ncrp_adm_count.columns = ['ncrp_entry']
ncrp_adm_count.reset_index(inplace=True)

# Read in NCRP Release data
ncrp_rel = pd.read_stata("O:/_temp/benchmarking/2020/validation data/National/NCRP/data/releases/data/1991-2016/DS0003/37021-0003-Data.dta")

# Change Datatype of STATE variable to string from category
ncrp_rel['STATE'] = ncrp_rel['STATE'].astype("str")

ncrp_rel['RELYR'] = ncrp_rel['RELYR'].replace({"Missing":np.nan})
ncrp_rel['RELYR'] = ncrp_rel['RELYR'].astype("float64")

# NCRP Release Count
ncrp_rel_count = ncrp_rel.groupby(['STATE','RELYR']).size().to_frame()
ncrp_rel_count.columns = ['ncrp_exit']
ncrp_rel_count.reset_index(inplace=True)

ncrp_count = pd.merge(ncrp_adm_count, ncrp_rel_count, how='outer', left_on=['STATE','ADMITYR'],
                     right_on=['STATE','RELYR'])

# Add FIPS info to data

#fips = pd.read_csv("D:/Users/seukim/Desktop/code/state_fips.csv")
fips = pd.read_excel("O:/utility/raw/FIPS_Codes/US_FIPS_Codes.xls", header=1)

ncrp_count = ncrp_count.merge(fips,how='left',left_on=['STATE'],right_on=['State'])

# Make a new unified YEAR columns
ncrp_count['YEAR'] = np.where(ncrp_count['ADMITYR'].isnull(), ncrp_count['RELYR'], ncrp_count['ADMITYR'])

ncrp_count = ncrp_count.copy()[['STATE','FIPS State','YEAR','ncrp_entry','ncrp_exit']]
ncrp_count.columns=['STATE','STATEID','YEAR','ncrp_entry','ncrp_exit']

# **Merge NPS and NCRP Counts**

# Merge NPS and NCRP count data together
nps_ncrp_merge = nps_count.merge(ncrp_count, on=['STATEID','YEAR'], how='outer')

nps_ncrp_merge['STATE_x'] = np.where(nps_ncrp_merge['STATE_x'].isnull(), nps_ncrp_merge['STATE_y'],
                                    nps_ncrp_merge['STATE_x'])

nps_ncrp_merge = nps_ncrp_merge.copy()[['STATEID','STATE_x','YEAR','nps_entry','nps_exit','ncrp_entry','ncrp_exit']]
nps_ncrp_merge.columns = ['STATEID','STATE','YEAR','nps_entry','nps_exit','ncrp_entry','ncrp_exit']

print("====================================================================================")

def stub_level_inc_dqr(dataframe, datasetid):
    
    ## Read in cleaned_incarceration from datastub of interest
    #inc_df = pd.read_stata(full_inc_path)
    inc_df = dataframe
    
    ##########################################################
    ##########################################################
    # inc facility code breakdown
    try:
        inc_fcl_cd_df = inc_df.groupby('inc_fcl_cd').size().to_frame().reset_index()
        inc_fcl_cd_df.rename(columns={0:'cnt'}, inplace=True)
        inc_fcl_cd_df.sort_values('cnt',ascending=False, inplace=True)
        inc_fcl_cd_df['pct'] = inc_fcl_cd_df['cnt'] * 100 / inc_fcl_cd_df['cnt'].sum()
            # save inc facility code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_fcl_cd_df.to_csv(path_to_save+ datasetid + "/inc_fcl_cd_tb.csv",index=False)
        else:
            inc_fcl_cd_df.to_csv(path_to_save+ datasetid + "/inc_fcl_cd_tb.csv",index=False)
    except:
        print("error occurred in inc facility code breakdown")
        raise
    
    ##########################################################
    ##########################################################
    # inc entry code breakdown
    try:
        inc_entry_cd_df = inc_df.groupby('inc_entry_cd').size().to_frame().reset_index()
        inc_entry_cd_df.rename(columns={0:'cnt'}, inplace=True)
        inc_entry_cd_df.sort_values('cnt',ascending=False, inplace=True)
        inc_entry_cd_df['pct'] = inc_entry_cd_df['cnt'] * 100 / inc_entry_cd_df['cnt'].sum()
            # save inc entry code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_entry_cd_df.to_csv(path_to_save+ datasetid + "/inc_entry_cd_tb.csv",index=False)
        else:
            inc_entry_cd_df.to_csv(path_to_save+ datasetid + "/inc_entry_cd_tb.csv",index=False)
    except:
        print("Error occurred in inc entry code breakdown")
        raise
    ##########################################################
    ##########################################################

    # inc exit code breakdown
    try:
        inc_exit_cd_df = inc_df.groupby('inc_exit_cd').size().to_frame().reset_index()
        inc_exit_cd_df.rename(columns={0:'cnt'}, inplace=True)
        inc_exit_cd_df.sort_values('cnt',ascending=False, inplace=True)
        inc_exit_cd_df['pct'] = inc_exit_cd_df['cnt'] * 100 / inc_exit_cd_df['cnt'].sum()
            # save inc exit code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_exit_cd_df.to_csv(path_to_save+ datasetid + "/inc_exit_cd_tb.csv",index=False)
        else:
            inc_exit_cd_df.to_csv(path_to_save+ datasetid + "/inc_exit_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in inc exit code breakdown")
        raise
    ##########################################################
    ##########################################################
    
    # inc county breakdown
    try:
        inc_cnty_ori_fips_df = inc_df.groupby('inc_cnty_ori_fips').size().to_frame().reset_index()
        inc_cnty_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        inc_cnty_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        inc_cnty_ori_fips_df['pct'] = inc_cnty_ori_fips_df['cnt'] * 100 / inc_cnty_ori_fips_df['cnt'].sum()
            # save inc county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/inc_cnty_tb.csv",index=False)
        else:
            inc_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/inc_cnty_tb.csv",index=False)
    except:
        print("Error occurred in inc county breakdown")
        raise
        
    ##########################################################
    ##########################################################
    
    # inc state breakdown
    try:
        inc_st_ori_fips_df = inc_df.groupby('inc_st_ori_fips').size().to_frame().reset_index()
        inc_st_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        inc_st_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        inc_st_ori_fips_df['pct'] = inc_st_ori_fips_df['cnt'] * 100 / inc_st_ori_fips_df['cnt'].sum()
            # save inc county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/inc_st_tb.csv",index=False)
        else:
            inc_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/inc_st_tb.csv",index=False)
    except:
        print("Error occurred in inc state breakdown")
        raise
        
    ##########################################################
    ##########################################################
    # inc cjars_ids missing check
    
    try:
        inc_df['cjars_id_miss'] = np.where((inc_df['cjars_id'].isnull() | inc_df['cjars_id'].isin(["", " "])), 1, 0)
        inc_cjars_id_miss_df = inc_df.groupby('cjars_id_miss').size().to_frame().reset_index()
        inc_cjars_id_miss_df.rename(columns={0:'cnt'}, inplace=True)
        inc_cjars_id_miss_df.sort_values('cnt',ascending=False, inplace=True)
        inc_cjars_id_miss_df['pct'] = inc_cjars_id_miss_df['cnt'] * 100 / inc_cjars_id_miss_df['cnt'].sum()
            # save inc cjars_ids missing check table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            inc_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/inc_cjarsid_miss_tb.csv",index=False)
        else:
            inc_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/inc_cjarsid_miss_tb.csv",index=False)
    except:
        print("Error occurred in inc cjars_id missing check")
        raise    

    ##########################################################
    ##########################################################
    # Inc Entry date YEARLY caseloads over time
    inc_df = inc_df.copy()[(inc_df.inc_entry_dt_yyyy.notnull()) & (inc_df.inc_entry_dt_mm.notnull())]
    inc_df['inc_entry_dt_yyyy'] = inc_df['inc_entry_dt_yyyy'].astype('int').astype('str')
    inc_entry_dt_y_df = inc_df.groupby(['inc_entry_dt_yyyy']).size().to_frame().reset_index()
    inc_entry_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    inc_entry_dt_y_df['pct'] = inc_entry_dt_y_df['cnt'] * 100 / inc_entry_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = inc_entry_dt_y_df, x='inc_entry_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Inc Entry Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Inc Entry Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/inc_entry_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/inc_entry_dt_yearly_graph.png")
    
    ##########################################################
    ##########################################################
    
    # Inc Exit date YEARLY caseloads over time

    inc_df = inc_df.copy()[(inc_df.inc_exit_dt_yyyy.notnull()) & (inc_df.inc_exit_dt_mm.notnull())]
    inc_df['inc_exit_dt_yyyy'] = inc_df['inc_exit_dt_yyyy'].astype('int').astype('str')
    inc_exit_dt_y_df = inc_df.groupby(['inc_exit_dt_yyyy']).size().to_frame().reset_index()
    inc_exit_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    inc_exit_dt_y_df['pct'] = inc_exit_dt_y_df['cnt'] * 100 / inc_exit_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = inc_exit_dt_y_df, x='inc_exit_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Inc Exit Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Inc Exit Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/inc_exit_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/inc_exit_dt_yearly_graph.png")
    
    ##########################################################
    ##########################################################
    # Extract State Info from Dataset Id
    state = datasetid[:2]
    
    # Fill in missing entry and exit years with 0 for the sake of coding in the next line
    inc_df['inc_entry_dt_yyyy'].fillna(0,inplace=True)
    inc_df['inc_exit_dt_yyyy'].fillna(0,inplace=True)

    # Change datatype of entry and exit years to integer from float
    inc_df['inc_entry_dt_yyyy'] = inc_df['inc_entry_dt_yyyy'].astype('int')
    inc_df['inc_exit_dt_yyyy'] = inc_df['inc_exit_dt_yyyy'].astype('int')
    
    comb_inc_entry_count = inc_df.groupby(['inc_st_juris_fips','inc_entry_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_inc_entry_count.columns = ['sde_entry']
    comb_inc_entry_count.reset_index(inplace=True)

    comb_inc_exit_count = inc_df.groupby(['inc_st_juris_fips','inc_exit_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_inc_exit_count.columns = ['sde_exit']
    comb_inc_exit_count.reset_index(inplace=True)
    
    # Change datatype of inc_st_juris_fips to integer before final merging
    comb_inc_entry_count['inc_st_juris_fips'] = comb_inc_entry_count['inc_st_juris_fips'].astype('int')
    comb_inc_exit_count['inc_st_juris_fips'] = comb_inc_exit_count['inc_st_juris_fips'].astype('int')
    
    # Merge combined Incarceration entry count data and exit count data
    comb_inc_count =     comb_inc_entry_count.merge(comb_inc_exit_count,left_on=['inc_st_juris_fips','inc_entry_dt_yyyy'],
                               right_on=['inc_st_juris_fips','inc_exit_dt_yyyy'], how='outer')
    
    # Make a new unified YEAR columns
    comb_inc_count['YEAR'] = np.where(comb_inc_count['inc_entry_dt_yyyy'].isnull(), 
                                  comb_inc_count['inc_exit_dt_yyyy'], comb_inc_count['inc_entry_dt_yyyy'])
    
    comb_inc_count = comb_inc_count.copy()[['inc_st_juris_fips','YEAR','sde_entry','sde_exit']] 
    # Only keep the relevant variables
    comb_inc_count.columns=['STATEID','YEAR','sde_entry','sde_exit'] # Rename Columns

    # Change Year datatype to integer
    comb_inc_count['YEAR'] =comb_inc_count['YEAR'].astype('int') 
    
    # keep only the relevant (stub related) nps / ncrp counts
    global nps_ncrp_merge
    nps_ncrp_merge = nps_ncrp_merge.copy()[nps_ncrp_merge.STATE == state]
    
    # Merge combined incarceration count into the previously merged data above
    total_count = nps_ncrp_merge.merge(comb_inc_count, on=['STATEID','YEAR'], how='outer')
    
    # Entry Count Graph
    plt.figure(figsize=(15,5))
    plt.plot('YEAR','nps_entry', data=total_count[total_count.STATE==state], marker='o')
    plt.plot('YEAR','ncrp_entry', data=total_count[total_count.STATE==state], marker='*')
    plt.plot('YEAR','sde_entry', data=total_count[total_count.STATE==state])
    plt.xticks(rotation=90)
    plt.legend(['NPS','NCRP','SDE'])
    plt.title("FIPS = {} Entry".format(state))
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid +"/inc_{}_entry_val_graph.png".format(state))
    else:
        plt.savefig(path_to_save + datasetid +"/inc_{}_entry_val_graph.png".format(state))
    
    plt.figure(figsize=(15,5))
    plt.plot('YEAR','nps_exit', data=total_count[total_count.STATE==state], marker='o')
    plt.plot('YEAR','ncrp_exit', data=total_count[total_count.STATE==state], marker='*')
    plt.plot('YEAR','sde_exit', data=total_count[total_count.STATE==state])
    plt.xticks(rotation=90)
    plt.legend(['NPS','NCRP','SDE'], loc=2)
    plt.title("FIPS = {} Exit".format(state))
    #plt.xlim(1975,2019)
    #plt.ylim(0,100000)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid + "/inc_{}_exit_val_graph.png".format(state))
    else:
        plt.savefig(path_to_save + datasetid + "/inc_{}_exit_val_graph.png".format(state))
    ##########################################################
    ##########################################################
 
print("================= Stub Level DQR for CLEANED INCARCERATION is OVER ======================")
