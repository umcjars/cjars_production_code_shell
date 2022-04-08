#!/usr/bin/env python
# coding: utf-8

######################## Stub Level DQR -- Arrest ########################

# Subscript that is called by stub_level_dqr_with_dcteam.py for Court data harmonization.
# Calculates the following dimensions of the data and saves them as csv or html files.

# - table and line graphs for caseload counts over time of variables arr_arr_dt* and arr_book_dt*
# - composition (count & pct) of:
#     - arr_off_cd
#     - arrest offense type (1st letter of arr_off_cd)
#     - arr_st_ori_fips
#     - arr_cnty_ori_fips
#     - arr_dv_off
#     - missing & non missing cjars_ids
########################################################################


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

full_arr_path = "O:/anonymized_records/2_cleaned/CA/Mu/Los_Angeles/Police/20200811/cleaned_arrest.dta"

path_to_save = "O:/output/adqc_reports/stub_level_dqr/"

import random

randint = random.randint(0,1000)
randint = str(randint)


def stub_level_arr_dqr(dataframe, datasetid):
    
    ## Read in cleaned_arrest from datastub of interest
    #arr_df = pd.read_stata(dataframe)
    arr_df = dataframe
    ##########################################################
    ##########################################################
    # arrest offense code breakdown
    try:
        arr_off_cd_df = arr_df.groupby('arr_off_cd').size().to_frame().reset_index()
        arr_off_cd_df.rename(columns={0:'cnt'}, inplace=True)
        arr_off_cd_df.sort_values('cnt',ascending=False, inplace=True)
        arr_off_cd_df['pct'] = arr_off_cd_df['cnt'] * 100 / arr_off_cd_df['cnt'].sum()
            # save arrest offense code breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_off_cd_df.to_csv(path_to_save+ datasetid + "/arr_off_cd_tb.csv",index=False)
        else:
            arr_off_cd_df.to_csv(path_to_save+ datasetid + "/arr_off_cd_tb.csv",index=False)
            
    except:
        print("error occurred in arrest offense code breakdown")
        raise
    
    ##########################################################
    ##########################################################
    # arrest offense type breakdown
    try:
        arr_df['off_type'] = arr_df['arr_off_cd'].apply(lambda x: x[0])
        arr_off_type_df = arr_df.groupby('off_type').size().to_frame().reset_index()
        arr_off_type_df.rename(columns={0:'cnt'}, inplace=True)
        arr_off_type_df.sort_values('cnt',ascending=False, inplace=True)
        arr_off_type_df['pct'] = arr_off_type_df['cnt'] * 100 / arr_off_type_df['cnt'].sum()
            # save arrest offense type breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_off_type_df.to_csv(path_to_save+ datasetid + "/arr_off_type_tb.csv",index=False)
        else:
            arr_off_type_df.to_csv(path_to_save+ datasetid + "/arr_off_type_tb.csv",index=False)
    except:
        print("Error occurred in arrest offense type breakdown")
        raise
    ##########################################################
    ##########################################################

    # arrest state breakdown
    try:
        arr_st_ori_fips_df = arr_df.groupby('arr_st_ori_fips').size().to_frame().reset_index()
        arr_st_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        arr_st_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        arr_st_ori_fips_df['pct'] = arr_st_ori_fips_df['cnt'] * 100 / arr_st_ori_fips_df['cnt'].sum()
            # save arrest state breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/arr_state_tb.csv",index=False)
        else:
            arr_st_ori_fips_df.to_csv(path_to_save+ datasetid + "/arr_state_tb.csv",index=False)
    except:
        print("Error occurred in arrest state breakdown")
        raise
    ##########################################################
    ##########################################################
    
    # arrest county breakdown
    try:
        arr_cnty_ori_fips_df = arr_df.groupby('arr_cnty_ori_fips').size().to_frame().reset_index()
        arr_cnty_ori_fips_df.rename(columns={0:'cnt'}, inplace=True)
        arr_cnty_ori_fips_df.sort_values('cnt',ascending=False, inplace=True)
        arr_cnty_ori_fips_df['pct'] = arr_cnty_ori_fips_df['cnt'] * 100 / arr_cnty_ori_fips_df['cnt'].sum()
            # save arrest county breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/arr_cnty_tb.csv",index=False)
        else:
            arr_cnty_ori_fips_df.to_csv(path_to_save+ datasetid + "/arr_cnty_tb.csv",index=False)
    except:
        print("Error occurred in arrest county breakdown")
        raise
    ##########################################################
    ##########################################################
    
    # arrest offense dv breakdown
    try:
        arr_dv_off_df = arr_df.groupby('arr_dv_off').size().to_frame().reset_index()
        arr_dv_off_df.rename(columns={0:'cnt'}, inplace=True)
        arr_dv_off_df.sort_values('cnt',ascending=False, inplace=True)
        arr_dv_off_df['pct'] = arr_dv_off_df['cnt'] * 100 / arr_dv_off_df['cnt'].sum()
            # save arrest offense dv breakdown table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_dv_off_df.to_csv(path_to_save+ datasetid + "/arr_off_dv_tb.csv",index=False)
        else:
            arr_dv_off_df.to_csv(path_to_save+ datasetid + "/arr_off_dv_tb.csv",index=False)
    except:
        print("Error occurred in arrest offense dv breakdown")
        raise    
    ##########################################################
    ##########################################################
    # arrest cjars_ids missing check
    
    try:
        arr_df['cjars_id_miss'] = np.where((arr_df['cjars_id'].isnull() | arr_df['cjars_id'].isin(["", " "])), 1, 0)
        arr_cjars_id_miss_df = arr_df.groupby('cjars_id_miss').size().to_frame().reset_index()
        arr_cjars_id_miss_df.rename(columns={0:'cnt'}, inplace=True)
        arr_cjars_id_miss_df.sort_values('cnt',ascending=False, inplace=True)
        arr_cjars_id_miss_df['pct'] = arr_cjars_id_miss_df['cnt'] * 100 / arr_cjars_id_miss_df['cnt'].sum()
            # save arrest cjars_ids missing check table
        if not os.path.exists(path_to_save+ datasetid):
            os.makedirs(path_to_save+ datasetid)
            arr_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/arr_cjarsid_miss_tb.csv",index=False)
        else:
            arr_cjars_id_miss_df.to_csv(path_to_save+ datasetid + "/arr_cjarsid_miss_tb.csv",index=False)
    except:
        print("Error occurred in arrest cjars_id missing check")
        raise    
    
    ##########################################################
    ##########################################################   
    # arrest date YEARLY caseloads over time
    arr_df = arr_df.copy()[(arr_df.arr_arr_dt_yyyy.notnull()) & (arr_df.arr_arr_dt_mm.notnull())]
    arr_df['arr_arr_dt_yyyy'] = arr_df['arr_arr_dt_yyyy'].astype('int').astype('str')
    arr_arr_dt_y_df = arr_df.groupby(['arr_arr_dt_yyyy']).size().to_frame().reset_index()
    arr_arr_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    arr_arr_dt_y_df['pct'] = arr_arr_dt_y_df['cnt'] * 100 / arr_arr_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = arr_arr_dt_y_df, x='arr_arr_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Arrest Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Arrest Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/arr_arr_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/arr_arr_dt_yearly_graph.png")
    
    ##########################################################
    ##########################################################
    
    # Booking date YEARLY caseloads over time

    arr_df = arr_df.copy()[(arr_df.arr_book_dt_yyyy.notnull()) & (arr_df.arr_book_dt_mm.notnull())]
    arr_df['arr_book_dt_yyyy'] = arr_df['arr_book_dt_yyyy'].astype('int').astype('str')
    arr_book_dt_y_df = arr_df.groupby(['arr_book_dt_yyyy']).size().to_frame().reset_index()
    arr_book_dt_y_df.rename(columns={0:'cnt'}, inplace=True)
    arr_book_dt_y_df['pct'] = arr_book_dt_y_df['cnt'] * 100 / arr_book_dt_y_df['cnt'].sum()

    plt.figure(figsize=(20,8))
    sns.lineplot(data = arr_book_dt_y_df, x='arr_book_dt_yyyy', y='cnt', sort=False)
    plt.xlabel("Booking Year", fontsize=15)
    plt.xticks(rotation=90)
    plt.ylabel("Count", fontsize=15)
    plt.title("Caseload Counts over time (Booking Year)", fontsize=15)
    if not os.path.exists(path_to_save+ datasetid):
        os.makedirs(path_to_save+ datasetid)
        plt.savefig(path_to_save+ datasetid + "/arr_book_dt_yearly_graph.png")
    else:
        plt.savefig(path_to_save+ datasetid + "/arr_book_dt_yearly_graph.png")    
    ##########################################################
    ##########################################################
    
   


print("================= Stub Level DQR for CLEANED ARREST is OVER ======================")

