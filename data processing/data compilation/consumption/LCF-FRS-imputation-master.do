***************************************************
*** LCF-FRS imputation of consumption data
*** master file
***************************************************

* Author: 			Matteo Richiardi, Daria Popova 
* First version: 	14 Feb 2025
* This version: 	17 Sep 2025 DP 

	
	cd "$dir_do_consumption"
	
*** Set macros and scalars
	scalar pct = 10	// income percentiles used for matching
	global CPI = 1.073 //CPI 2023 to 2022, because we use 2022 LCF data 
	

* Prepare UKMOD and LCF data
	do 1a-data-prepare-UKMOD-input.do
	do 1b-data-prepare-LCF.do

* Run this only to check that the matching variables are similarly distributed in UKMOD and LCF data
	do 2-data-descriptive.do

* Compute Mahlanobis distance between UKMOD and LCF data, by deciles of net income
	do 3-data-matching.do

* Compute Mahlanobis distance between UKMOD and LCF data, by deciles of net income
	do 4-reduction-to-4digits.do
