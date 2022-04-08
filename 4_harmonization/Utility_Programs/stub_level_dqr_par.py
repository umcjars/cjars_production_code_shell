#!/usr/bin/env python
# coding: utf-8

#################### Stub Level DQR -- Parole ####################

# Subscript that is called by stub_level_dqr_with_dcteam.py for Court data harmonization.
# Calculates the following dimensions of the data and saves them as csv or html files.

# - table and line graphs (monthly and yearly) for caseload counts over time of variables par_bgn_dt* & par_end_dt* 
# - composition (count & pct) of:
#     - par_end_cd
#     - par_st_ori_fips
#     - par_cnty_ori_fips
#     - missing/non missing cjars_ids
############################################################

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

# example of full par path
full_par_path = "O:/anonymized_records/2_cleaned/NE/St/DOC/20210206/cleaned_parole.dta"

## OR

full_par_path = "O:/anonymized_records/2_cleaned/FL/St/DOC/20190816/cleaned_parole.dta"

# Path for saving tables and figures as a result of dqr
path_to_save = "O:/output/adqc_reports/stub_level_dqr/"

import random

randint = random.randint(0,1000)
randint = str(randint)


# ### Annual Parole Survey Counts

# Reading in Parole Survey Data
npsurv = pd.read_stata("O:/_temp/benchmarking/2020/validation data/National/APS/Annual Parole Survey/data/combined/parole_totals.dta",
                      convert_categoricals=False)

# Add FIPS info to data

#fips = pd.read_csv("D:/Users/seukim/Desktop/code/state_fips.csv")
fips = pd.read_excel("O:/utility/raw/FIPS_Codes/US_FIPS_Codes.xls", header=1)

fips_with_state_abbr = pd.read_csv("O:/utility/cleaned/fips.csv")
fips_with_state_abbr.rename(columns={'state_fp':'fips'},inplace=True)

npsurv = npsurv.merge(fips_with_state_abbr[['state','fips']],how='left',on=['fips'])

# Reading in Parole Survey 2017 data
npsurv17 = pd.read_csv("O:/_temp/benchmarking/2020/validation data/National/probation_parole_report/ppus1718at13.csv",
                      header=11)

# Reading in Parole Survey 2018 data
npsurv18 = pd.read_csv("O:/_temp/benchmarking/2020/validation data/National/probation_parole_report/ppus1718at05.csv",
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
npsurv17['State name'] = npsurv17['State name'].replace({'Wisconsin/d':'Wisconsin', 'California/c':'California'})
npsurv18['State name'] = npsurv18['State name'].replace({'Wisconsin/e':'Wisconsin', 'California/c,d':'California',
                                                        'Massachusetts/c':'Massachusetts','Alaska/c':'Alaska',
                                                        'Ohio/c':'Ohio','Pennsylvania/c':'Pennsylvania',
                                                        'Connecticut/c':'Connecticut','Vermont/c':'Vermont'})

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

npsurv.rename(columns={'fips':'STATE_FIPS'},inplace=True)

print("=============================================================================================")

def stub_level_par_dqr(dataframe, datasetid):
    
    #pro_df = pd.read_stata(full_par_path)
    par_df = dataframe
    
    ##########################################################
    ##########################################################
    # Probation Condition code breakdown
    try:
        par_end_cd_df = par_df.groupby('par_end_cd').size().to_frame().reset_index()
        par_end_cd_df.rename(columns={0:'cnt'}, inplace=True)
        par_end_cd_df.sort_values('cnt',ascending=False, inplace=True)
        par_end_cd_df['pct'] = par_end_cd_df['cnt'] * 100 / par_end_cd_df['cnt'].sum()
            # save par end condition code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            par_end_cd_df.to_csv(path_to_save+ datasetid + "/par_end_cond_cd_tb.csv",index=False)
        else:
            par_end_cd_df.to_csv(path_to_save+ datasetid + "/par_end_cond_cd_tb.csv",index=False)
    except:
        print("error occurred in pro condition code breakdown")
        raise
    
    ##########################################################
    ##########################################################
    
    # par county breakdown
    try:
        par_cnty_ori_fips_df = par_df.groupby('par_cnty_ori_fips').size().to_frame().reset_index()
        par_cnty_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        par_cnty_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        par_cnty_ori_fips_df['pct'] = par_cnty_ori_fips_df['cnt'] * 100 / par_cnty_ori_fips_df['cnt'].sum()
            # save par county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            par_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/par_cnty_tb.csv",index=False)
        else:
            par_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/par_cnty_tb.csv",index=False)
    except:
        print("Error occurred in par county breakdown")
        raise
        
    ##########################################################
    ##########################################################
    
    # par state breakdown
    try:
        par_st_ori_fips_df = par_df.groupby('par_st_ori_fips').size().to_frame().reset_index()
        par_st_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        par_st_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        par_st_ori_fips_df['pct'] = par_st_ori_fips_df['cnt'] * 100 / par_st_ori_fips_df['cnt'].sum()
            # save par state breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            par_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/par_st_tb.csv",index=False)
        else:
            par_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/par_st_tb.csv",index=False)
    except:
        print("Error occurred in par state breakdown")
        raise
        
    ##########################################################
    ##########################################################
    # par cjars_ids missing check
    
    try:
        par_df['cjars_id_miss'] = np.where((par_df['cjars_id'].isnull() | par_df['cjars_id'].isin(["", " "])), 1, 0)
        par_cjars_id_miss_df = par_df.groupby('cjars_id_miss').size().to_frame().reset_index()
        par_cjars_id_miss_df.rename(columns={0:'cnt'}, inplace=True)
        par_cjars_id_miss_df.sort_values('cnt',ascending=False, inplace=True)
        par_cjars_id_miss_df['pct'] = par_cjars_id_miss_df['cnt'] * 100 / par_cjars_id_miss_df['cnt'].sum()
            # save par cjars_ids missing check table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            par_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/par_cjarsid_miss_tb.csv",index=False)
        else:
            par_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/par_cjarsid_miss_tb.csv",index=False)
    except:
        print("Error occurred in par cjars_id missing check")
        raise    

    ##########################################################
    ##########################################################
    # Par Begin date YEARLY caseloads over time
    par_df = par_df.copy()[(par_df.par_bgn_dt_yyyy.notnull()) & (par_df.par_bgn_dt_mm.notnull())]
    par_df['par_bgn_dt_yyyy'] = par_df['par_bgn_dt_yyyy'].astype('int').astype('str')
    par_bgn_dt_y_df = par_df.groupby(['par_bgn_dt_yyyy']).size().to_frame().reset_index()
    par_bgn_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    par_bgn_dt_y_df['pct'] = par_bgn_dt_y_df['cnt'] * 100 / par_bgn_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = par_bgn_dt_y_df, x='par_bgn_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Par Begin Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Par Begin Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/par_begin_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/par_begin_dt_yearly_graph.png")
    ##########################################################
    ##########################################################
    
    # Par End date YEARLY caseloads over time
    
    par_df = par_df.copy()[(par_df.par_end_dt_yyyy.notnull()) & (par_df.par_end_dt_mm.notnull())]
    par_df['par_end_dt_yyyy'] = par_df['par_end_dt_yyyy'].astype('int').astype('str')
    par_end_dt_y_df = par_df.groupby(['par_end_dt_yyyy']).size().to_frame().reset_index()
    par_end_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    par_end_dt_y_df['pct'] = par_end_dt_y_df['cnt'] * 100 / par_end_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = par_end_dt_y_df, x='par_end_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Par End Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Par End Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/par_end_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/par_end_dt_yearly_graph.png")
    ##########################################################
    ##########################################################
        
        ##### Parole Entry Counts Graph ######
    
    # extract state info from datasetid
    state_info = datasetid[:2]
    
    # Fill in missing entry and exit years with 0 for the sake of coding in the next line
    par_df['par_bgn_dt_yyyy'].fillna(0,inplace=True)
    par_df['par_end_dt_yyyy'].fillna(0,inplace=True)
    
    # Change datatype of entry and exit years to integer from float
    par_df['par_bgn_dt_yyyy'] = par_df['par_bgn_dt_yyyy'].astype('int')
    par_df['par_end_dt_yyyy'] = par_df['par_end_dt_yyyy'].astype('int')

    # Remove the "0" that we used to fill in missing years back to NaN
    par_df['par_bgn_dt_yyyy'].replace({0:np.nan},inplace=True)
    par_df['par_end_dt_yyyy'].replace({0:np.nan},inplace=True)
    
    comb_par_entry_count = par_df.groupby(['par_st_juris_fips','par_bgn_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_par_entry_count.columns = ['sde_entry']
    comb_par_entry_count.reset_index(inplace=True)
    
    comb_par_exit_count = par_df.groupby(['par_st_juris_fips','par_end_dt_yyyy']).cjars_id.nunique().to_frame()
    comb_par_exit_count.columns = ['sde_exit']
    comb_par_exit_count.reset_index(inplace=True)
    
    # Change datatype of par_st_juris_fips to integer before final merging
    comb_par_entry_count['par_st_juris_fips'] = comb_par_entry_count['par_st_juris_fips'].astype('int')
    comb_par_exit_count['par_st_juris_fips'] = comb_par_exit_count['par_st_juris_fips'].astype('int')
    
    # Merge combined Parole entry count data and exit count data
    comb_par_count =     comb_par_entry_count.merge(comb_par_exit_count,left_on=['par_st_juris_fips','par_bgn_dt_yyyy'],
                               right_on=['par_st_juris_fips','par_end_dt_yyyy'], how='outer')
    
    # Make a new unified YEAR columns
    comb_par_count['YEAR'] = np.where(comb_par_count['par_bgn_dt_yyyy'].isnull(), 
                                  comb_par_count['par_end_dt_yyyy'], comb_par_count['par_bgn_dt_yyyy'])
    
    # Only keep the relevant variables
    comb_par_count = comb_par_count.copy()[['par_st_juris_fips','YEAR','sde_entry','sde_exit']] 
    comb_par_count.columns=['STATE_FIPS','YEAR','sde_entry','sde_exit'] # Rename Columns
    
    # Change Year datatype to integer
    comb_par_count['YEAR'] =comb_par_count['YEAR'].astype('int') 

    comb_par_count.rename(columns={'YEAR':'year'},inplace=True)

    global npsurv
    npsurv.rename(columns={'fips':'STATE_FIPS'},inplace=True)
    npsurv = npsurv.copy()[npsurv.state==state_info]

    # Merge combined parole count into npsurv data
    total_count = comb_par_count.merge(npsurv, on=['STATE_FIPS','year'],how='outer')
    
    # Change Column Names
    #total_count.columns = ['STATE_FIPS','year','sde_entry','npsur_entry','sde_exit','npsur_exit']
    total_count.rename(columns={'TOTEN':'npsur_entry','TOTEX':'npsur_exit'}, inplace=True)
    
    # Change STATE FIPS code datatype from float to int
    total_count['STATE_FIPS'] = total_count['STATE_FIPS'].astype('int')
    total_count['STATE_FIPS'] = total_count['STATE_FIPS'].astype('int')
    
    # Get Rid of "0" Years cuz they were originally missing years/values
    total_count = total_count.copy()[total_count.year != 0.0]
    total_count = total_count.copy()[total_count.year != 0.0]

    # Parole Entry Counts
    plt.figure(figsize=(15,5))
    plt.plot('year','npsur_entry', data=total_count[total_count.state==state_info], marker='*')
    plt.plot('year','sde_entry', data=total_count[total_count.state==state_info], marker='o')
    plt.xticks(rotation=90)
    plt.legend(['Annual Parole Survey', 'SDE'], loc=2)
    plt.title("State = {} Entry".format(list(set(total_count[total_count.state==state_info].state))[0]))
#     plt.xlim(1990,2020)
#     plt.ylim(5000,60000)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid +"/par_{}_entry_val_graph.png".format(state_info))
    else:
        plt.savefig(path_to_save + datasetid +"/par_{}_entry_val_graph.png".format(state_info))
    
    plt.figure(figsize=(15,5))
    plt.plot('year','npsur_exit', data=total_count[total_count.state==state_info], marker='*')
    plt.plot('year','sde_exit', data=total_count[total_count.state==state_info], marker='o')
    #plt.xticks(rotation=90)
    plt.legend(['Annual Parole Survey', 'SDE'], loc=2)
    plt.title("State = {} Exit".format(list(set(total_count[total_count.state==state_info].state))[0]))
#     plt.xlim(1992,2020)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save + datasetid + "/par_{}_exit_val_graph.png".format(state_info))
    else:
        plt.savefig(path_to_save + datasetid + "/par_{}_exit_val_graph.png".format(state_info))
    ##########################################################
    ##########################################################    



print("================= Stub Level DQR for CLEANED PROBATION is OVER ======================")
