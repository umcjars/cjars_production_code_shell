#!/usr/bin/env python
# coding: utf-8

########################### Stub Level DQR -- Adjudication ###############################
# Subscript that is called by stub_level_dqr_with_dcteam.py for Court data harmonization.
# Calculates the following dimensions of the data and saves them as csv or html files.
# - table and line graphs for caseload counts over time of variables inc_entry_dt* and inc_exit_dt*
# - composition (count & pct) of:
#     - adj_grd_cd
#     - adj_off_lgl_cd
#     - adj_chrg_off_cd
#     - adj_disp_off_cd
#     - off type : adj_chrg_off_cd
#     - off type : adj_disp_off_cd
#     - adj_disp_cd (parent class)
#     - adj_disp_cd (children class)
#     - adj_sent_serv
#     - adj_sent_dth
#     - adj_sent_sus
#     - adj_sent_trt
#     - adj_st_ori_fips
#     - adj_cnty_ori_fips
#     - missing/non missing cjars_ids

##################################################################


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


full_adj_path = "O:/anonymized_records/2_cleaned/NE/St/DOC/20210206/cleaned_adjudication.dta"

path_to_save = "O:/output/adqc_reports/stub_level_dqr/"


import random

randint = random.randint(0,1000)
randint = str(randint)


# In[2]:


def stub_level_adj_dqr(dataframe, datasetid):
    
    ## Read in cleaned_adjudication from datastub of interest
    #inc_df = pd.read_stata(full_adj_path)
    adj_df = dataframe
    
    ##########################################################
    ##########################################################
    # adj grade code breakdown
    try:
        adj_grd_cd_df = adj_df.groupby('adj_grd_cd').size().to_frame().reset_index()
        adj_grd_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_grd_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_grd_cd_df['pct'] = adj_grd_cd_df['cnt'] * 100 / adj_grd_cd_df['cnt'].sum()
            # save adj grade code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_grd_cd_df.to_csv(path_to_save+ datasetid + "/adj_grd_cd_tb.csv",index=False)
        else:
            adj_grd_cd_df.to_csv(path_to_save+ datasetid + "/adj_grd_cd_tb.csv",index=False)
    except:
        print("error occurred in adj grade code breakdown")
        raise
    
    ##########################################################
    ##########################################################
    # adj legal code breakdown
    try:
        adj_off_lgl_cd_df = adj_df.groupby('adj_off_lgl_cd').size().to_frame().reset_index()
        adj_off_lgl_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_off_lgl_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_off_lgl_cd_df['pct'] = adj_off_lgl_cd_df['cnt'] * 100 / adj_off_lgl_cd_df['cnt'].sum()
            # save adj legal code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_off_lgl_cd_df.to_csv(path_to_save+ datasetid + "/adj_legal_cd_tb.csv",index=False)
        else:
            adj_off_lgl_cd_df.to_csv(path_to_save+ datasetid + "/adj_legal_cd_tb.csv",index=False)
    except:
        print("Error occurred in adj legal code breakdown")
        raise
    ##########################################################
    ##########################################################

    # adj_chrg_off_cd breakdown
    try:
        adj_chrg_off_cd_df = adj_df.groupby('adj_chrg_off_cd').size().to_frame().reset_index()
        adj_chrg_off_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_chrg_off_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_chrg_off_cd_df['pct'] = adj_chrg_off_cd_df['cnt'] * 100 / adj_chrg_off_cd_df['cnt'].sum()
            # save adj charge offense code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_chrg_off_cd_df.to_csv(path_to_save+ datasetid + "/adj_chrg_off_cd_tb.csv",index=False)
        else:
            adj_chrg_off_cd_df.to_csv(path_to_save+ datasetid + "/adj_chrg_off_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in adj_chrg_off_cd breakdown")
        raise
        
    ##########################################################
    ##########################################################

    # offense type - adj_chrg_off_cd breakdown
    try:
        adj_df['off_type_chrg_off'] = adj_df['adj_chrg_off_cd'].apply(lambda x: x[0])
        off_type_chrg_off_df = adj_df.groupby('off_type_chrg_off').size().to_frame().reset_index()
        off_type_chrg_off_df.rename(columns={0:'cnt'}, inplace=True)
        off_type_chrg_off_df.sort_values('cnt',ascending=False, inplace=True)
        off_type_chrg_off_df['pct'] = off_type_chrg_off_df['cnt'] * 100 / off_type_chrg_off_df['cnt'].sum()
            # save adj offense type - adj_chrg_off_cd breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            off_type_chrg_off_df.to_csv(path_to_save+ datasetid + "/adj_off_type_chrg_off_cd_tb.csv",index=False)
        else:
            off_type_chrg_off_df.to_csv(path_to_save+ datasetid + "/adj_off_type_chrg_off_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in offense type - adj_chrg_off_cd breakdown")
        raise
  
    ##########################################################
    ##########################################################

    # adj_disp_off_cd breakdown
    try:
        adj_disp_off_cd_df = adj_df.groupby('adj_disp_off_cd').size().to_frame().reset_index()
        adj_disp_off_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_disp_off_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_disp_off_cd_df['pct'] = adj_disp_off_cd_df['cnt'] * 100 / adj_disp_off_cd_df['cnt'].sum()
            # save adj disposition offense code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_disp_off_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_off_cd_tb.csv",index=False)
        else:
            adj_disp_off_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_off_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in adj_disp_off_cd breakdown")
        raise
        
    ##########################################################
    ##########################################################

    # offense type - adj_disp_off_cd breakdown
    try:
        adj_df['off_type_disp_off'] = adj_df['adj_disp_off_cd'].apply(lambda x: x[0])
        off_type_disp_off_df = adj_df.groupby('off_type_disp_off').size().to_frame().reset_index()
        off_type_disp_off_df.rename(columns={0:'cnt'}, inplace=True)
        off_type_disp_off_df.sort_values('cnt',ascending=False, inplace=True)
        off_type_disp_off_df['pct'] = off_type_disp_off_df['cnt'] * 100 / off_type_disp_off_df['cnt'].sum()
            # save adj offense type - adj_disp_off_cd breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            off_type_disp_off_df.to_csv(path_to_save+ datasetid + "/adj_off_type_disp_off_cd_tb.csv",index=False)
        else:
            off_type_disp_off_df.to_csv(path_to_save+ datasetid + "/adj_off_type_disp_off_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in offense type - adj_disp_off_cd breakdown")
        raise

    ##########################################################
    ##########################################################

    # adj_disp_cd (child class) breakdown
    try:
        adj_disp_cd_df = adj_df.groupby('adj_disp_cd').size().to_frame().reset_index()
        adj_disp_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_disp_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_disp_cd_df['pct'] = adj_disp_cd_df['cnt'] * 100 / adj_disp_cd_df['cnt'].sum()
            # save adj disposition code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_disp_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_cd_tb.csv",index=False)
        else:
            adj_disp_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in adj_disp_cd (child class) breakdown")
        raise
        
    ##########################################################
    ##########################################################

    # adj_disp_cd (parent class) breakdown
    try:
        adj_df['adj_disp_par_cd'] = adj_df['adj_disp_cd'].apply(lambda x: x[0])
        adj_disp_par_cd_df = adj_df.groupby('adj_disp_par_cd').size().to_frame().reset_index()
        adj_disp_par_cd_df.rename(columns={0:'cnt'}, inplace=True)
        adj_disp_par_cd_df.sort_values('cnt',ascending=False, inplace=True)
        adj_disp_par_cd_df['pct'] = adj_disp_par_cd_df['cnt'] * 100 / adj_disp_par_cd_df['cnt'].sum()
            # save adj disposition code (Parent) breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_disp_par_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_par_cd_tb.csv",index=False)
        else:
            adj_disp_par_cd_df.to_csv(path_to_save+ datasetid + "/adj_disp_par_cd_tb.csv",index=False)
    
    except:
        print("Error occurred in adj_disp_cd (parent class) breakdown")
        raise        
        
    ##########################################################
    ##########################################################

    # adj_sent_serv (community service) breakdown
    
    try:
        adj_sent_serv_df = adj_df.groupby('adj_sent_serv').size().to_frame().reset_index()
        adj_sent_serv_df.rename(columns={0:'cnt'}, inplace=True)
        adj_sent_serv_df.sort_values('cnt',ascending=False, inplace=True)
        adj_sent_serv_df['pct'] = adj_sent_serv_df['cnt'] * 100 / adj_sent_serv_df['cnt'].sum()
            # save adj community service code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_sent_serv_df.to_csv(path_to_save+ datasetid + "/adj_sent_serv_tb.csv",index=False)
        else:
            adj_sent_serv_df.to_csv(path_to_save+ datasetid + "/adj_sent_serv_tb.csv",index=False)
    except:
        print("Error occurred in community service sentence breakdown")
        raise        
        
    ##########################################################
    ##########################################################

    # adj_sent_dth (dealth sentence) breakdown
    
    try:
        adj_sent_dth_df = adj_df.groupby('adj_sent_dth').size().to_frame().reset_index()
        adj_sent_dth_df.rename(columns={0:'cnt'}, inplace=True)
        adj_sent_dth_df.sort_values('cnt',ascending=False, inplace=True)
        adj_sent_dth_df['pct'] = adj_sent_dth_df['cnt'] * 100 / adj_sent_dth_df['cnt'].sum()
            # save adj death sentence code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_sent_dth_df.to_csv(path_to_save+ datasetid + "/adj_sent_dth_tb.csv",index=False)
        else:
            adj_sent_dth_df.to_csv(path_to_save+ datasetid + "/adj_sent_dth_tb.csv",index=False)
    
    except:
        print("Error occurred in death sentence breakdown")
        raise                

    ##########################################################
    ##########################################################

    # life sentence (adj_sent_inc == -88888) breakdown
    
    try:
        adj_df['adj_sent_life'] = np.where(adj_df.adj_sent_inc == -88888, 1, 0)
        adj_sent_life_df = adj_df.groupby('adj_sent_life').size().to_frame().reset_index()
        adj_sent_life_df.rename(columns={0:'cnt'}, inplace=True)
        adj_sent_life_df.sort_values('cnt',ascending=False, inplace=True)
        adj_sent_life_df['pct'] = adj_sent_life_df['cnt'] * 100 / adj_sent_life_df['cnt'].sum()
            # save adj life sentence code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_sent_life_df.to_csv(path_to_save+ datasetid + "/adj_sent_life_tb.csv",index=False)
        else:
            adj_sent_life_df.to_csv(path_to_save+ datasetid + "/adj_sent_life_tb.csv",index=False)
    
    except:
        print("Error occurred in life sentence breakdown")
        raise                
        
    ##########################################################
    ##########################################################

    # adj_sent_sus (suspended sentence) breakdown
    
    try:
        adj_sent_sus_df = adj_df.groupby('adj_sent_sus').size().to_frame().reset_index()
        adj_sent_sus_df.rename(columns={0:'cnt'}, inplace=True)
        adj_sent_sus_df.sort_values('cnt',ascending=False, inplace=True)
        adj_sent_sus_df['pct'] = adj_sent_sus_df['cnt'] * 100 / adj_sent_sus_df['cnt'].sum()
            # save adj suspended sentence code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_sent_sus_df.to_csv(path_to_save+ datasetid + "/adj_sent_sus_tb.csv",index=False)
        else:
            adj_sent_sus_df.to_csv(path_to_save+ datasetid + "/adj_sent_sus_tb.csv",index=False)
    
    except:
        print("Error occurred in suspended sentence breakdown")
        raise                
                
    ##########################################################
    ##########################################################

    # adj_sent_trt (treatment sentence) breakdown
    
    try:
        adj_sent_trt_df = adj_df.groupby('adj_sent_trt').size().to_frame().reset_index()
        adj_sent_trt_df.rename(columns={0:'cnt'}, inplace=True)
        adj_sent_trt_df.sort_values('cnt',ascending=False, inplace=True)
        adj_sent_trt_df['pct'] = adj_sent_trt_df['cnt'] * 100 / adj_sent_trt_df['cnt'].sum()
            # save adj treatment sentence code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_sent_trt_df.to_csv(path_to_save+ datasetid + "/adj_sent_trt_tb.csv",index=False)
        else:
            adj_sent_trt_df.to_csv(path_to_save+ datasetid + "/adj_sent_trt_tb.csv",index=False)
    
    except:
        print("Error occurred in treatment sentence breakdown")
        raise                
                        
    ##########################################################
    ##########################################################
    
    # adj county breakdown
    try:
        adj_cnty_ori_fips_df = adj_df.groupby('adj_cnty_ori_fips').size().to_frame().reset_index()
        adj_cnty_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        adj_cnty_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        adj_cnty_ori_fips_df['pct'] = adj_cnty_ori_fips_df['cnt'] * 100 / adj_cnty_ori_fips_df['cnt'].sum()
            # save inc county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/adj_cnty_tb.csv",index=False)
        else:
            adj_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/adj_cnty_tb.csv",index=False)
    except:
        print("Error occurred in adj county breakdown")
        raise
        
    ##########################################################
    ##########################################################
    
    # adj state breakdown
    try:
        adj_st_ori_fips_df = adj_df.groupby('adj_st_ori_fips').size().to_frame().reset_index()
        adj_st_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        adj_st_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        adj_st_ori_fips_df['pct'] = adj_st_ori_fips_df['cnt'] * 100 / adj_st_ori_fips_df['cnt'].sum()
            # save adj state breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/adj_st_tb.csv",index=False)
        else:
            adj_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/adj_st_tb.csv",index=False)
    except:
        print("Error occurred in adj state breakdown")
        raise
        
    ##########################################################
    ##########################################################
    # adj cjars_ids missing check
    
    try:
        adj_df['cjars_id_miss'] = np.where((adj_df['cjars_id'].isnull() | adj_df['cjars_id'].isin(["", " "])), 1, 0)
        adj_cjars_id_miss_df = adj_df.groupby('cjars_id_miss').size().to_frame().reset_index()
        adj_cjars_id_miss_df.rename(columns={0:'cnt'}, inplace=True)
        adj_cjars_id_miss_df.sort_values('cnt',ascending=False, inplace=True)
        adj_cjars_id_miss_df['pct'] = adj_cjars_id_miss_df['cnt'] * 100 / adj_cjars_id_miss_df['cnt'].sum()
            # save adj cjars_ids missing check table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            adj_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/adj_cjarsid_miss_tb.csv",index=False)
        else:
            adj_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/adj_cjarsid_miss_tb.csv",index=False)
    except:
        print("Error occurred in adj cjars_id missing check")
        raise    

    ##########################################################
    ##########################################################
    # Adj File date YEARLY caseloads over time
    adj_df = adj_df.copy()[(adj_df.adj_file_dt_yyyy.notnull()) & (adj_df.adj_file_dt_mm.notnull())]
    adj_df['adj_file_dt_yyyy'] = adj_df['adj_file_dt_yyyy'].astype('int').astype('str')
    adj_file_dt_y_df = adj_df.groupby(['adj_file_dt_yyyy']).size().to_frame().reset_index()
    adj_file_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    adj_file_dt_y_df['pct'] = adj_file_dt_y_df['cnt'] * 100 / adj_file_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = adj_file_dt_y_df, x='adj_file_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Adj File Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Adj File Year)", fontsize=15)
    
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_file_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_file_dt_yearly_graph.png")

    ##########################################################
    ##########################################################
    # Adj Offense date YEARLY caseloads over time
    adj_df = adj_df.copy()[(adj_df.adj_off_dt_yyyy.notnull()) & (adj_df.adj_off_dt_mm.notnull())]
    adj_df['adj_off_dt_yyyy'] = adj_df['adj_off_dt_yyyy'].astype('int').astype('str')
    adj_off_dt_y_df = adj_df.groupby(['adj_off_dt_yyyy']).size().to_frame().reset_index()
    adj_off_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    adj_off_dt_y_df['pct'] = adj_off_dt_y_df['cnt'] * 100 / adj_off_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = adj_off_dt_y_df, x='adj_off_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Adj Offense Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Adj Offense Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_off_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_off_dt_yearly_graph.png")
    
    ##########################################################
    ##########################################################
    # Adj Disposition date YEARLY caseloads over time
    adj_df = adj_df.copy()[(adj_df.adj_disp_dt_yyyy.notnull()) & (adj_df.adj_disp_dt_mm.notnull())]
    adj_df['adj_disp_dt_yyyy'] = adj_df['adj_disp_dt_yyyy'].astype('int').astype('str')
    adj_disp_dt_y_df = adj_df.groupby(['adj_disp_dt_yyyy']).size().to_frame().reset_index()
    adj_disp_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    adj_disp_dt_y_df['pct'] = adj_disp_dt_y_df['cnt'] * 100 / adj_disp_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = adj_disp_dt_y_df, x='adj_disp_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Adj Disposition Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Adj Disposition Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_disp_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_disp_dt_yearly_graph.png")
        
    ##########################################################
    ##########################################################
    # Adj Sentencing date YEARLY caseloads over time
    adj_df = adj_df.copy()[(adj_df.adj_sent_dt_yyyy.notnull()) & (adj_df.adj_sent_dt_mm.notnull())]
    adj_df['adj_sent_dt_yyyy'] = adj_df['adj_sent_dt_yyyy'].astype('int').astype('str')
    adj_sent_dt_y_df = adj_df.groupby(['adj_sent_dt_yyyy']).size().to_frame().reset_index()
    adj_sent_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    adj_sent_dt_y_df['pct'] = adj_sent_dt_y_df['cnt'] * 100 / adj_sent_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = adj_sent_dt_y_df, x='adj_sent_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Adj Sentencing Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Adj Sentencing Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_dt_yearly_graph.png")
    
    ##########################################################
    ##########################################################
    
    ## adj_sent_inc ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_inc.notnull())]
    sns.distplot(adj_df[~adj_df['adj_sent_inc'].isin([-88888,-99999])].adj_sent_inc, hist=True)
    plt.xlim(0,400)
    plt.text(150, 0.01,"max adj_sent_inc value is {}".format(adj_df.adj_sent_inc.max()))
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_hist_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_hist_graph.png")

    ##########################################################
    ##########################################################
    
    ## adj_sent_inc_max ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_inc_max.notnull())]
    sns.distplot(adj_df[~adj_df['adj_sent_inc_max'].isin([-88888,-99999])].adj_sent_inc_max, hist=True)
    plt.xlim(0,400)
    plt.text(150, 0.01,"max adj_sent_inc_max value is {}".format(adj_df.adj_sent_inc_max.max()))    
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_max_hist_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_max_hist_graph.png")

    ##########################################################
    ##########################################################
    
    ## adj_sent_inc_min ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_inc_min.notnull())]
    sns.distplot(adj_df[~adj_df['adj_sent_inc_min'].isin([-88888,-99999])].adj_sent_inc_min, hist=True)
    plt.xlim(0,400)
    plt.text(150, 0.01,"max adj_sent_inc_min value is {}".format(adj_df.adj_sent_inc_min.max()))
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_min_hist_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_inc_min_hist_graph.png")

    
    ##########################################################
    ##########################################################
    
    ## adj_sent_pro ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_pro.notnull())]
    sns.distplot(adj_df.adj_sent_pro, hist=True)
    #plt.xlim(0,400)
    plt.text(150, 0.01,"max adj_sent_pro value is {}".format(adj_df.adj_sent_pro.max()))   
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_pro_hist_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_pro_hist_graph.png")
    
    ##########################################################
    ##########################################################
    
    ## adj_sent_rest ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_rest.notnull())]
    sns.distplot(adj_df.adj_sent_rest, hist=True)
    #plt.xlim(0,400)
    plt.text(150, 0.007,"min adj_sent_rest value is {}".format(adj_df.adj_sent_rest.min()))    
    plt.text(150, 0.01,"max adj_sent_rest value is {}".format(adj_df.adj_sent_rest.max()))  
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_rest_hist_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_rest_hist_graph.png")
    
    ##########################################################
    ##########################################################
    
    ## adj_sent_fine ==> Histogram 
    adj_df = adj_df.copy()[(adj_df.adj_sent_fine.notnull())]
    sns.distplot(adj_df.adj_sent_fine, hist=True)
    #plt.xlim(0,400)
    plt.text(150, 0.007,"min adj_sent_fine value is {}".format(adj_df.adj_sent_fine.min()))    
    plt.text(150, 0.01,"max adj_sent_fine value is {}".format(adj_df.adj_sent_fine.max()))  
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/adj_sent_fine_hist_grah.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/adj_sent_fine_hist_grah.png")


print("================= Stub Level DQR for CLEANED ADJUDICATION is OVER ======================")





