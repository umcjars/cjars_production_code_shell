#========================================================================#
# Random Forest Classifier Entity Resolution                             #
# ---------------------------------------------------------------------- #
# This code was intentionally written in an un-Pythonic manner to        #
# resemble Stata code for mental mapping purposes.						 #
# - J.C. (2020/02/14)                                                    #
#========================================================================#
from sklearn.tree import export_graphviz
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, precision_recall_curve
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
import matplotlib as mpl
import seaborn as sns
import pandas as pd
import numpy as np
#import pydotplus
import datetime
import random
import joblib
import time
import math
import mkl
import csv
import sys
import os
username = os.getlogin()

print('Starting entity resolution - this may take awhile')

mkl.set_num_threads(8)		# More stable way to control number of threads than `n_jobs` parameter

start = datetime.datetime.now()

#=================#
# Directory Paths #
#=================#
DATA_PATH = r'O:\pii\roster\production_files'
CODE_PATH = r'd:\Users\{}\Desktop\code\3_entity_resolution\Utility_Programs'.format(username)
OUTPUT_PATH = r'd:\Users\{}\Desktop\code\3_entity_resolution\Utility_Programs'.format(username)

#============#
# File Paths #
#============#
FILE_PATH = os.path.join(DATA_PATH, 'roster_data.csv')

#====================#
# Relevant Variables #
#====================#
## List of variables to use as features
FEATURES = [
	'name_last_jw', 'name_last_norm1', 'name_last_normEdt', 'name_last_match', 
	'name_first_jw', 'name_first_norm1', 'name_first_normEdt', 'name_first_match', 
	'name_middle_jw', 'name_middle_norm1', 'name_middle_normEdt', 'name_middle_miss', 
	'name_middle_match', 'name_first_clean_jw', 'name_first_clean_norm1', 
	'name_first_clean_normEdt', 'name_first_clean_match', 'name_middle_clean_jw', 
	'name_middle_clean_norm1', 'name_middle_clean_normEdt', 'name_middle_clean_match', 
	'dob_dd_string_normEdt', 'dob_mm_string_normEdt', 'dob_yyyy_string_normEdt', 
	'name_last_sdx_match', 'name_first_sdx_match', 'name_middle_sdx_match', 
	'name_last_phx_match', 'name_first_phx_match', 'name_middle_phx_match', 
	'dob_numgap', 'dob_dd_numgap', 'dob_mm_numgap', 'dob_yyyy_numgap', 
	'name_last_match_uniq', 'name_last_jw_uniq', 'name_last_norm1_uniq', 
	'name_last_normEdt_uniq', 'name_first_match_uniq', 'name_first_jw_uniq', 
	'name_first_norm1_uniq', 'name_first_normEdt_uniq', 'name_middle_match_uniq', 
	'name_middle_jw_uniq', 'name_middle_norm1_uniq', 'name_middle_normEdt_uniq',
	'mid_miss_1plus', 'mid_miss_both', 'mid_init_1plus', 'mid_init_both', 
	'female_1plus', 'female_both', 'white_1plus', 'white_both', 'black_1plus',
	'black_both', 'hisp_1plus', 'hisp_both', 'dob_jan1_both', 'dob_jan1_1plus'
]
## Target variable to predict
TARGET = 'match'
## Variables to keep in prediction output (a.k.a. ID variables)
KEYS = [
	'record_id_1', 'record_id_2', 
	'match'
]

#========================================================================#
# Load Model                                                             #
# ---------------------------------------------------------------------- #
# It turns out that I do not need to preprocess and generate vectors     #
# since this is working with numerical data. This section of the code    #
# will also save a copy of the estimates so that it can be reused later. #
# - J.C. (2020/02/14)                                                    #
#========================================================================#
CACHED_MODEL = os.path.join(OUTPUT_PATH, 'rf_CJARS_production.pkl')
## Initialize classifier if there is no saved file
clf = joblib.load(CACHED_MODEL)
print(f'Loaded estimates using {CACHED_MODEL}')
	
	
#=========================#
# Initialize Testing Data #
#=========================#
print(f'Importing OOS data using {FILE_PATH}')
## Overwrite variables used for training data to release memory
df = pd.read_csv(FILE_PATH, sep=',')
X = df[FEATURES]
Y = df[TARGET]

## DataFrame to store predicted values and probabilities
PREDICTED_DF = df[KEYS]
PREDICTED_PATH = os.path.join(DATA_PATH, 'roster_results.csv')

#======================#
# Make New Predictions #
#======================#
pred_start = datetime.datetime.now()
preds = clf.predict(X)
#with open(os.path.join(OUTPUT_PATH, 'duration_of_prediction.txt'), 'w') as outfile:
#	print('{}'.format(str(datetime.datetime.now() - pred_start)), file=outfile)
print('Finished predicting data')
probs = np.amax(clf.predict_proba(X), axis=1)
PREDICTED_DF = PREDICTED_DF.assign(
	stat_match_rf_demog_enhanced=preds, 
	probability=probs
)
PREDICTED_DF.to_csv(PREDICTED_PATH, sep=',', index=False)
print(f'Saved predicted results in {PREDICTED_PATH}')

