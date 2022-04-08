#!/usr/bin/env python
# coding: utf-8

###################### Stub Level DQR with DC Team######################
# Main Python Script that generates stub level data quality reports 
# by calling subscripts(utility programs) that pertain to different
# kinds of harmonization types (e.g. incarceration, adjudication). 
# The subscripts are stub_level_dqr_adj.py, stub_level_dqr_arr.py, 
# stub_level_dqr_par.py, stub_level_dqr_pro.py and stub_level_dqr_inc.py
# which you can see are called starting line 142 depending
# on specific conditions (e.g. if statements).

########################################################################

print("================= Stub Level DQR with DC Team Starts Now =================")

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


from stub_level_dqr_arr import stub_level_arr_dqr
#from stub_level_dqr_inc import stub_level_inc_dqr
# from stub_level_dqr_adj import stub_level_adj_dqr
# from stub_level_dqr_pro import stub_level_pro_dqr
# from stub_level_dqr_par import stub_level_par_dqr



# #### Defining Full Path to Cleaned_file

path = "O:/anonymized_records/production_files/har_data_forstub_level_dqr" + "/"


# #### Read in harmonized data ready for stub level dqr & datasetid

#%time
df = pd.read_stata(path + "data_for_dqr.dta")

datasetid_df = pd.read_stata("O:/anonymized_records/production_files/har_data_forstub_level_dqr/datasetid_dqr.dta")
datasetid = datasetid_df['datasetid'][0]


# #### performing DQR on stub

import traceback

#if os.path.isfile(full_arr_path):
if "arr_arr_dt_yyyy" in df.columns:
    print("========== Performing DQR on {} ==========".format("arr harmonization script"))
    try:
        stub_level_arr_dqr(df,datasetid)
        print("DQR on cleaned_arrest SUCCESS!")
    except:
        print("Error occurred while performing DQR on {}".format("arr harmonization script"))
        raise
        traceback.print_exc()
    
# if os.path.isfile(full_adj_path):
if "adj_disp_cd" in df.columns:
    print("========== Performing DQR on {} ==========".format("adj harmonization script"))
    try:
        stub_level_adj_dqr(df,datasetid)
        print("DQR on cleaned_adj SUCCESS!")
    except:
        print("Error occurred while performing DQR on {}".format("adj harmonization script"))
        raise
        
#if os.path.isfile(full_inc_path):
if "inc_fcl_cd" in df.columns:
    print("========== Performing DQR on {} ==========".format("inc harmonization script"))
    try:
        stub_level_inc_dqr(df,datasetid)
        print("DQR on cleaned_inc SUCCESS!")
    except:
        print("Error occurred while performing DQR on {}".format("inc harmonization script"))
        raise
        traceback.print_exc()

#if os.path.isfile(full_pro_path):
if "pro_end_dt_yyyy" in df.columns:
    print("========== Performing DQR on {} ==========".format("pro harmonization script"))
    try:
        stub_level_pro_dqr(df,datasetid)
        print("DQR on cleaned_pro SUCCESS!")
    except:
        print("Error occurred while performing DQR on {}".format("pro harmonization script"))
        raise
        traceback.print_exc()
        
#if os.path.isfile(full_par_path):
if "par_end_dt_yyyy" in df.columns:
    print("============ Performing DQR on {} ==========".format("par harmonization script"))
    try:
        stub_level_par_dqr(df,datasetid)
        print("DQR on cleaned_par SUCCESS!")
    except:
        print("Error occurred while performing DQR on {}".format("par harmonization script"))    
        raise
        traceback.print_exc()
