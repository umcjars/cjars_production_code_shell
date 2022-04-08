#!/usr/bin/env python
# coding: utf-8

################### Stub Level DQR -- Probation ###################

# Subscript that is called by stub_level_dqr_with_dcteam.py for Court data harmonization.
# Calculates the following dimensions of the data and saves them as csv or html files.

# - table and line graphs for caseload counts over time of variables inc_entry_dt* and inc_exit_dt*
# - composition (count & pct) of:
#     - pro_cond_cd
#     - pro_bgn_dt* & pro_end_dt* ==> yearly and year-month-ly counts
#     - pro_end_cd
#     - pro_st_ori_fips
#     - pro_cnty_ori_fips
#     - missing/non missing cjars_ids
############################################################################

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

# example of full pro path
full_pro_path = "O:/anonymized_records/2_cleaned/FL/St/DOC/20190816/cleaned_probation.dta"

# Path for saving tables and figures as a result of dqr
path_to_save = "O:/output/adqc_reports/stub_level_dqr/"

import random

randint = random.randint(0,1000)
randint = str(randint)


# ### Reading in Annual Probation Survey and calculating counts

# Reading in Parole Survey Data
npsurv = pd.read_stata("O:/_temp/benchmarking/2020/validation data/National/APS/Annual Probation Survey/data/combined/probation_totals.dta",
                      convert_categoricals=False)

# Add FIPS info to data


fips = pd.read_excel("O:/utility/raw/FIPS_Codes/US_FIPS_Codes.xls", header=1)

fips_with_state_abbr = pd.read_csv("O:/utility/cleaned/fips.csv")

fips_with_state_abbr.rename(columns={'state_fp':'fips'},inplace=True)

npsurv = npsurv.merge(fips_with_state_abbr[['state','fips']],how='left',on=['fips'])

# Reading in Probation Survey 2017 data
npsurv17 = pd.read_csv("O:/_temp/benchmarking/2020/validation data/National/probation_parole_report/ppus1718at10.csv",
                      header=11)

# Reading in Probation Survey 2018 data
npsurv18 = pd.read_csv("O:/_temp/benchmarking/2020/validation data/National/probation_parole_report/ppus1718at02.csv",
                      header=11)

npsurv17 = npsurv17.copy()[['Unnamed: 1', 'Reported','Reported.1']].iloc[3:,:]
npsurv17.columns = ['State name','TOTEN','TOTEX']
npsurv17['year'] = 2017

npsurv18 = npsurv18.copy()[['Unnamed: 1', 'Reported','Reported.1']].iloc[3:,:]
npsurv18.columns = ['State name','TOTEN','TOTEX']
npsurv18['year'] = 2018 

# Remove ".." which indicates missing value so that I can change these variables' data type to float from string
npsurv17['TOTEN'] = npsurv17['TOTEN'].replace({'..':np.nan})
npsurv18['TOTEN'] = npsurv18['TOTEN'].replace({'..':np.nan})

npsurv17['TOTEX'] = npsurv17['TOTEX'].replace({'..':np.nan})
npsurv18['TOTEX'] = npsurv18['TOTEX'].replace({'..':np.nan})

# Remove "," in numbers
npsurv17['TOTEN'] = npsurv17['TOTEN'].str.replace(',',"")
npsurv18['TOTEN'] = npsurv18['TOTEN'].str.replace(',',"")

npsurv17['TOTEX'] = npsurv17['TOTEX'].str.replace(',',"")
npsurv18['TOTEX'] = npsurv18['TOTEX'].str.replace(',',"")

# Change data type to float from string since it's counts
npsurv17['TOTEN'] = npsurv17['TOTEN'].astype('float64')
npsurv18['TOTEN'] = npsurv18['TOTEN'].astype('float64')

npsurv17['TOTEX'] = npsurv17['TOTEX'].astype('float64')
npsurv18['TOTEX'] = npsurv18['TOTEX'].astype('float64')

# Fix some abnormal state names so that I can merge later to the master table properly
npsurv17['State name'] = npsurv17['State name'].replace({'Vermont/c':'Vermont','Florida/c':'Florida',
                                                         'New Mexico/c':'New Mexico','Kentucky/c':'Kentucky',
                                                        'Rhode Island/c':'Rhode Island','Alabama/c':'Alabama',
                                                        'Washington/c':'Washington','North Dakota/c':'North Dakota',
                                                        'Wisconsin/c,d':'Wisconsin','Michigan/c':'Michigan',
                                                        'Alaska/c':'Alaska','Georgia/c':'Georgia','Colorado/c':'Colorado',
                                                        'Ohio/c':'Ohio','Montana/c':'Montana'})
npsurv18['State name'] = npsurv18['State name'].replace({'Vermont/c':'Vermont','New Mexico/c':'New Mexico',
                                                         'Florida/c':'Florida','Rhode Island/c':'Rhode Island',
                                                         'Missouri/c':'Missouri','Wisconsin/c,d':'Wisconsin',
                                                         'Michigan/c':'Michigan','Alaska/c':'Alaska','Georgia/c':'Georgia',
                                                         'Ohio/c':'Ohio','Montana/c':'Montana','Washington/c':'Washington'})


npsurv17 = npsurv17.copy()[npsurv17['State name'].notnull()]
npsurv18 = npsurv18.copy()[npsurv18['State name'].notnull()]

fips.rename(columns={'State':'State name'},inplace=True)

npsurv17 = npsurv17.merge(fips[['State name','FIPS State']], on=['State name'])
npsurv18 = npsurv18.merge(fips[['State name','FIPS State']], on=['State name'])

npsurv17.rename(columns={'FIPS State':'fips'},inplace=True)
npsurv18.rename(columns={'FIPS State':'fips'},inplace=True)

npsurv = npsurv.copy()[['TOTEN','TOTEX','year','fips','state']]

fips.rename(columns={'FIPS State':'fips'},inplace=True)

npsurv = npsurv.merge(fips[['State name','fips']],on=['fips'],how='left')

# Append 2017 and 2018 data to master table
npsurv = pd.concat([npsurv,npsurv17,npsurv18], axis=0)

# Drop missing observations
npsurv = npsurv.copy()[npsurv['State name'].notnull()]

# Fill in missing state abbreviation using the values of the other observations in the same State name group
npsurv['state'] = npsurv.groupby('State name')['state'].ffill().bfill()

npsurv.head()

def stub_level_pro_dqr(dataframe, datasetid):
    
    #pro_df = pd.read_stata(full_pro_path)
    pro_df = dataframe
    
    ##########################################################
    ##########################################################
    # Probation Condition code breakdown
    try:
        pro_cond_cd_df = pro_df.groupby('pro_cond_cd').size().to_frame().reset_index()
        pro_cond_cd_df.rename(columns={0:'cnt'}, inplace=True)
        pro_cond_cd_df.sort_values('cnt',ascending=False, inplace=True)
        pro_cond_cd_df['pct'] = pro_cond_cd_df['cnt'] * 100 / pro_cond_cd_df['cnt'].sum()
            # save pro condition code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            pro_cond_cd_df.to_csv(path_to_save+ datasetid + "/pro_cond_cd_tb.csv",index=False)
        else:
            pro_cond_cd_df.to_csv(path_to_save+ datasetid + "/pro_cond_cd_tb.csv",index=False)
    except:
        print("error occurred in pro condition code breakdown")
        raise
    
    ##########################################################
    ##########################################################

    # pro end code breakdown
    try:
        pro_end_cd_df = pro_df.groupby('pro_end_cd').size().to_frame().reset_index()
        pro_end_cd_df.rename(columns={0:'cnt'}, inplace=True)
        pro_end_cd_df.sort_values('cnt',ascending=False, inplace=True)
        pro_end_cd_df['pct'] = pro_end_cd_df['cnt'] * 100 / pro_end_cd_df['cnt'].sum()
            # save pro end code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            pro_end_cd_df.to_csv(path_to_save+ datasetid + "/pro_end_cd_tb.csv",index=False)
        else:
            pro_end_cd_df.to_csv(path_to_save+ datasetid + "/pro_end_cd_tb.csv",index=False)
    except:
        print("Error occurred in pro end code breakdown")
        raise
    ##########################################################
    ##########################################################
    
    # pro county breakdown
    try:
        pro_cnty_ori_fips_df = pro_df.groupby('pro_cnty_ori_fips').size().to_frame().reset_index()
        pro_cnty_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        pro_cnty_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        pro_cnty_ori_fips_df['pct'] = pro_cnty_ori_fips_df['cnt'] * 100 / pro_cnty_ori_fips_df['cnt'].sum()
            # save pro county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            pro_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/pro_cnty_tb.csv",index=False)
        else:
            pro_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/pro_cnty_tb.csv",index=False)
    except:
        print("Error occurred in pro county breakdown")
        raise
        
    ##########################################################
    ##########################################################
    
    # pro state breakdown
    try:
        pro_st_ori_fips_df = pro_df.groupby('pro_st_ori_fips').size().to_frame().reset_index()
        pro_st_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        pro_st_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        pro_st_ori_fips_df['pct'] = pro_st_ori_fips_df['cnt'] * 100 / pro_st_ori_fips_df['cnt'].sum()
            # save pro state breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            pro_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/pro_st_tb.csv",index=False)
        else:
            pro_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/pro_st_tb.csv",index=False)
    except:
        print("Error occurred in pro state breakdown")
        raise
        
    ##########################################################
    ##########################################################
    # pro cjars_ids missing check
    
    try:
        pro_df['cjars_id_miss'] = np.where((pro_df['cjars_id'].isnull() | pro_df['cjars_id'].isin(["", " "])), 1, 0)
        pro_cjars_id_miss_df = pro_df.groupby('cjars_id_miss').size().to_frame().reset_index()
        pro_cjars_id_miss_df.rename(columns={0:'cnt'}, inplace=True)
        pro_cjars_id_miss_df.sort_values('cnt',ascending=False, inplace=True)
        pro_cjars_id_miss_df['pct'] = pro_cjars_id_miss_df['cnt'] * 100 / pro_cjars_id_miss_df['cnt'].sum()
            # save pro cjars_ids missing check table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            pro_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/pro_cjarsid_miss_tb.csv",index=False)
        else:
            pro_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/pro_cjarsid_miss_tb.csv",index=False)
    except:
        print("Error occurred in pro cjars_id missing check")
        raise    

    ##########################################################
    ##########################################################
    # Pro Begin date YEARLY caseloads over time
    pro_df = pro_df.copy()[(pro_df.pro_bgn_dt_yyyy.notnull()) & (pro_df.pro_bgn_dt_mm.notnull())]
    pro_df['pro_bgn_dt_yyyy'] = pro_df['pro_bgn_dt_yyyy'].astype('int').astype('str')
    pro_bgn_dt_y_df = pro_df.groupby(['pro_bgn_dt_yyyy']).size().to_frame().reset_index()
    pro_bgn_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    pro_bgn_dt_y_df['pct'] = pro_bgn_dt_y_df['cnt'] * 100 / pro_bgn_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = pro_bgn_dt_y_df, x='pro_bgn_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Pro Begin Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Pro Begin Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/pro_begin_dt_yearly_graph.png".format(randint))
    else:
        plt.savefig(path_to_save+ datasetid + "/pro_begin_dt_yearly_graph.png".format(randint))
    
    ##########################################################
    ##########################################################
    
    # Pro End date YEARLY caseloads over time
    
    pro_df = pro_df.copy()[(pro_df.pro_end_dt_yyyy.notnull()) & (pro_df.pro_end_dt_mm.notnull())]
    pro_df['pro_end_dt_yyyy'] = pro_df['pro_end_dt_yyyy'].astype('int').astype('str')
    pro_end_dt_y_df = pro_df.groupby(['pro_end_dt_yyyy']).size().to_frame().reset_index()
    pro_end_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    pro_end_dt_y_df['pct'] = pro_end_dt_y_df['cnt'] * 100 / pro_end_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = pro_end_dt_y_df, x='pro_end_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Pro End Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Pro End Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/pro_end_dt_yearly_graph.png".format(randint))
    else:
        plt.savefig(path_to_save+ datasetid + "/pro_end_dt_yearly_graph.png".format(randint))
    
    ##########################################################
    ##########################################################
    ############# Probation Entry and Exit Counts Graph #############
    
    # Extract state information from dataset id
    state_info = datasetid[:2]
    
    # Fill in missing entry and exit years with 0 for the sake of coding in the next line
    pro_df['pro_bgn_dt_yyyy'].fillna(0,inplace=True)
    pro_df['pro_end_dt_yyyy'].fillna(0,inplace=True)
    
    # Change datatype of entry and exit years to integer from float
    pro_df['pro_bgn_dt_yyyy'] = pro_df['pro_bgn_dt_yyyy'].astype('int')
    pro_df['pro_end_dt_yyyy'] = pro_df['pro_end_dt_yyyy'].astype('int')

    # Remove the "0" that we used to fill in missing years back to NaN
    pro_df['pro_bgn_dt_yyyy'].replace({0:np.nan},inplace=True)
    pro_df['pro_end_dt_yyyy'].replace({0:np.nan},inplace=True)
    
    # Calculate Probation Entry Count
    comb_pro_entry_count = pro_df.groupby(['pro_st_juris_fips','pro_bgn_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_pro_entry_count.columns = ['sde_entry']
    comb_pro_entry_count.reset_index(inplace=True)
    
    # Calculate Probation Exit Count
    comb_pro_exit_count = pro_df.groupby(['pro_st_juris_fips','pro_end_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_pro_exit_count.columns = ['sde_exit']
    comb_pro_exit_count.reset_index(inplace=True)
    
    # Change datatype of par_st_juris_fips to integer before final merging
    comb_pro_entry_count['pro_st_juris_fips'] = comb_pro_entry_count['pro_st_juris_fips'].astype('int')
    comb_pro_exit_count['pro_st_juris_fips'] = comb_pro_exit_count['pro_st_juris_fips'].astype('int')
    
    # Merge combined Probation entry count data and exit count data
    comb_pro_count =     comb_pro_entry_count.merge(comb_pro_exit_count,left_on=['pro_st_juris_fips','pro_bgn_dt_yyyy'],
                               right_on=['pro_st_juris_fips','pro_end_dt_yyyy'], how='outer')
    
    # Make a new unified YEAR columns
    comb_pro_count['YEAR'] = np.where(comb_pro_count['pro_bgn_dt_yyyy'].isnull(), 
                                      comb_pro_count['pro_end_dt_yyyy'], comb_pro_count['pro_bgn_dt_yyyy'])
    
    # Only keep the relevant variables
    comb_pro_count = comb_pro_count.copy()[['pro_st_juris_fips','YEAR','sde_entry','sde_exit']] 
    comb_pro_count.columns=['STATE_FIPS','YEAR','sde_entry','sde_exit'] # Rename Columns\
    
    # Change Year datatype to integer
    comb_pro_count['YEAR'] =comb_pro_count['YEAR'].astype('int') 
    
    global npsurv
    npsurv.rename(columns={'fips':'STATE_FIPS'},inplace=True)
    comb_pro_count.rename(columns={'YEAR':'year'},inplace=True)
    
    # Merge combined probation count into npsurv data
    total_count = comb_pro_count.merge(npsurv, on=['STATE_FIPS','year'],how='outer')
    
    #total_count = total_count.copy()[['STATE_FIPS','year','sde_entry','TOTEN','sde_exit','TOTEX']]
    
    # Change Column Names
    #total_count.columns = ['STATE_FIPS','year','sde_entry','npsur_entry','sde_exit','npsur_exit']
    total_count.rename(columns={'TOTEN':'npsur_entry','TOTEX':'npsur_exit'}, inplace=True)
    
    # Change STATE FIPS code datatype from float to int
    total_count['STATE_FIPS'] = total_count['STATE_FIPS'].astype('int')
    total_count['STATE_FIPS'] = total_count['STATE_FIPS'].astype('int')
    
    # Get Rid of "0" Years cuz they were originally missing years/values
    total_count = total_count.copy()[total_count.year != 0.0]
    total_count = total_count.copy()[total_count.year != 0.0]
    
    # Probation Entry Counts Graph
    plt.figure(figsize=(15,5))
    plt.plot('year','npsur_entry', data=total_count[total_count.state==state_info], marker='*')
    plt.plot('year','sde_entry', data=total_count[total_count.state==state_info], marker='o')
    plt.xticks(rotation=90)
    plt.legend(['Annual Probation Survey', 'SDE'], loc=1)
    plt.title("State = {} Entry".format(list(set(total_count[total_count.state==state_info].state))[0]))
    #plt.xlim(1990,2020)

    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid +"/pro_{}_entry_val_graph.png".format(state_info))
    else:
        plt.savefig(path_to_save + datasetid +"/pro_{}_entry_val_graph.png".format(state_info))
 
    # Probation Exit Counts Graph
    plt.figure(figsize=(15,5))
    plt.plot('year','npsur_exit', data=total_count[total_count.state==state_info], marker='*')
    plt.plot('year','sde_exit', data=total_count[total_count.state==state_info], marker='o')
    plt.xticks(rotation=90)
    plt.legend(['Annual Probation Survey', 'SDE'], loc=1)
    plt.title("FIPS = {} Exit".format(list(set(total_count[total_count.state==state_info].state))[0]))
#     plt.xlim(1992,2020)
#     plt.ylim(10000,27000)

    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid +"/pro_{}_exit_val_graph.png".format(state_info))
    else:
        plt.savefig(path_to_save + datasetid +"/pro_{}_exit_val_graph.png".format(state_info))

print("================= Stub Level DQR for CLEANED PROBATION is OVER ======================")

