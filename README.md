# CJARS Production Code

This repository contains the data processing infrastructure for the Criminal Justice Administrative Records System (CJARS).

The execution of the various processing stages is managed by `master_code.do`. The control scripts for each stage refer to the metadata in `Dataset.csv`, which tracks the completion date for each stage along with other dataset-specific information used in the production process.

The production pipeline consists of four stages, listed here along with their respective primary control scripts and relevant sub-stages:

1. Localization
    - `/1_localization/localize.do`
        + `/1_localization/Utility_Programs/localize.ado`
        + `/1_localization/<dataset_id>/convert.do` and `fix.do`
2. Standardization
    - `/2_standardization/standardize.do`
        + `/2_standardization/<dataset_id>/clean_pii.do`
    - `/2_standardization/impute_race_gender.do`
3. Entity Resolution
    - `/3_entity_resolution/entity_resolution.do`
    - `/3_entity_resolution/state_roster.do`
    - `/3_entity_resolution/cjars_id_push_state.do`
4. Harmonization
    - `/4_harmonization/harmonize.do`
        + `/4_harmonization/1_prepared/<dataset_id>/clean_<table>.do`
    - `/4_harmonization/2_combined/data_coverage.do`
    - `/4_harmonization/2_combined/combine.do`
    - `/4_harmonization/2_combined/all_state_combine.do`


Most processing is handled in dataset-specific scripts stored in a directory structure that follows each dataset's *dataset ID*, an identifier with the following format:

    <state abbreviation>/<sub-state geographic type>/<city or county name>/<agency type>/<intake date>

For example, a dataset from a municipal source:

```
CA/Mu/Example_City/Police/20220101
```

State-level datasets (e.g. Department of Corrections) exclude the city or county name:

```
CA/St/DOC/20220101
```

Dataset IDs double as identifiers as well as filepaths which, when used in combination with the base folders for different data processing stages, point to the location of production code for each dataset.

For definitions of macros that occur frequently in CJARS code, as well as documentation for the fields in `Dataset.csv`, see the Glossary at the bottom of this readme.

**Note:** The code in this repository (including most of the macros described above) relies on a variety of resources only available on the CJARS secure server, including raw and processed data along with various utility files and supplemental data and crosswalks. The code is not intended to run outside of this environment and is provided for perusal only. All dataset-specific code has been redacted and replaced with a sample dataset with the dataset ID `CA/St/DOC/20220101`.

## Localization

Localization is the process of converting raw files (plaintext, csv, Excel, Microsoft Access, etc.) into Stata's `.dta` format, along with any cleaning necessary to make the data usable. This is generally limited to things like restoring missing variable names and checking types, so that the converted data is as 'raw' as possible.

The master localization script in `/1_localization/Utility_Programs/localize.ado` handles most raw files without intervention. For datasets that do not automatically convert successfully, a dataset-specific script, `/1_localization/<dataset_id>/convert.do`, is used to handle individual files; once all files are converted, any additional custom processing on the entire batch of files is taken care of in the optional `fix.do`.

## Standardization

Standardization is the process of extracting personally identifying information (PII) from the raw data and coding it into a standard CJARS roster format. On the level of the individual dataset, standardization is handled by `/2_standardization/<dataset_id>/clean_pii.do`. A template `clean_pii.do` script is provided that demonstrates the process of loading, cleaning, and extracting PII from the raw data.

As a sub-stage of standardization, race and sex are imputed based on name prevalence by region. No dataset-specific code is required; the imputation script `/2_standardization/impute_race_gender.do` runs automatically for each dataset during production.

## Entity Resolution

In order to track individuals across multiple criminal justice events, the entity resolution stage uses a probabilistic matching algorithm to link individual records and with a unique person-level identifier called a `cjars_id`. The sub-stages of entity resolution perform this matching within a given dataset, extend this matching process to the state level, and then build state rosters and push the resulting unique identifiers to the original raw data, which are stripped of PII.

## Harmonization

Harmonization is the process of bringing raw criminal justice data into the CJARS schema. For example, dates are split into separate year, month, and day fields and assigned to the appropriate variables for offense date, case filing date, disposition date, and so on. Offense grades are standardized, either from explicitly coded variables or from analysis of text descriptions, and a machine learning model matches raw offense descriptions to a uniform set of offense codes. Dataset-level harmonization scripts are located in `/4_harmonization/1_prepared/<dataset_id>/clean_<table>.do`, and the provided template files correspond with the CJARS tables for adjudication, arrest, parole, probation, and incarceration.

After harmonization, another sub-stage combines the harmonized files of each type by state, and then across all states. The combine stage also performs deduplication to account for records that appear in more than one extract from the same data source.

# Glossary

## Macros

- `codedir`
    + Path of root code repository
- `VALIDATE`
    + Set to `"0"` in `master_code.do` to skip validation codes during harmonization for faster processing time
- `crossdir`
    + Root directory for utility data such as crosswalks and documentation files
- `tempdir`
    + A temporary directory unique for each instance of Stata - primarily used to store data files during localization that require additional processing
- `formatdir`
    + Root output folder for storing formatted data files after successful localization. This macro is concatenated with dataset ID to specify dataset-specific output folder
- `cleanpiidir`
    + Root output folder for storing data files containing cleaned PII after standardization. This macro is concatenated with dataset ID to specify dataset-specific output folder that contains `cleaned_pii.dta`, `data_level_roster.dta`, `pii_var.txt`, `pointer_file.dta`, and `record_id_cjars_id_crosswalk.dta`.
- `modeldir`
    + Root code folder for entity resolution codes
- `rosterdir`
    + Root output folder for storing state-specific roster files after successful entity resolution run
- `anondir`
    + Root output folder for storing anonymized data files after merging in `cjars_id` from entity resolution and dropping all of the variables listed in `pii_var.txt` from standardization

## Dataset.csv

- `datasetid`
    + Unique identifier to record each data extract. See below for syntax used to generate each `datasetid`s
- `pii_sufficient`
    + Binary variable to indicate that the raw data contains full personally identifiable information (PII). At the minimum, the raw data should provide offender's first and last names, and full date of birth.
- `active_use`
    + Binary variable to indicate whether the dataset should be included in the production run. If set to `0` for inactive use, the `inactive_reason` column should be filled in with a brief description
- `inactive_reason`
    + Filled in for inactive datasets to describe the reason for excluding them in production run
- `pivot_table`
    + Binary variable to indicate whether the data files are relational (set to `1`). If so, `pivot_id` must be filled in with relevant variable names
- `pivot_id`
    + Variable name(s) used to link one data file to another. Primarily used to propagate `cjars_id` to non-roster data files (data files without PII) when generating anonymized files
- `state`
    + State from where the data was sourced
- `census_region`
    + Census region where the state is in for metadata
- `geography`
    + Geography of where the data is from. For state-wide data, `geography` is set to the state name while county or city names are used for data from lower-level agencies
- `metro`
    + Metropolitan statistical areas (MSA) of the data provider
- `public`
    + Variable to denote whether data is publicly available (set to `1`) or not (set to `0`)
- `source`
    + Mechanism for data acquisition (e.g. scraping, data use agreement, freedom of information act)
- `sde_intake`
    + Date when the dataset was loaded on to the Secure Data Enclave (SDE) server
- `*_assigned`
    + Abbreviation of CJARS staff working on the production code for `*` processing stage
- `*_cd_start_dt`
    + Date when the person `*_assigned` started working on the production code
- `*_reviewer`
    + Abbreviation of CJARS staff who reviewed the production code written by `*_assigned`
- `*_cd_cmpl_dt`
    + Date when the `*_reviewer` finishes reviewing the production code. These fields must be filled in to enable production run.
- `*_run`
    + Date of last production run for `*` processing stage. These variables are automatically filled by running `master_code.do`. If the `*_run` date is earlier than `*_cd_cmpl_dt` (e.g. `localize_run`=`20220301` and `localize_cd_cmpl_dt`=`20220331`), `master_code.do` will re-run the code.
- `impute_run`
    + Date of last production run for imputing gender and race. Automatically updated from production run via `impute_race_gender.do`
- `entity_resolution_run`
    + Date of last entity resolution run. Automatically updated from production run via `entity_resolution.do`
- `supercluster_flag`
    + Binary variable to indicate if supercluster of `cjars_id` was created from entity resolution
- `alias_drop`
    + Binary variable to indiicate whether alias data should be dropped during entity resolution
- `state_roster_run`
    + Date of last time state roster was generated
- `cjars_id_state_push_run`
    + Date of last time anonymized files (`cjars_id` merged in) was generated for harmonization
- `toc_vintage`
    + The specific version of text-based offense classification tool to use for classifying charge descriptions
