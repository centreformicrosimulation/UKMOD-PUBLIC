***************************************************
*** LCF-FRS imputation of consumption data
*** master file
***************************************************

* Authors: 			Matteo Richiardi, Daria Popova 
* LAST UPDATE:          8 Oct 2026 DP 

	
	cd "$dir_do_consumption"
	
*** Set macros and scalars
	scalar pct = 10	// income percentiles used for matching
	global CPI = 1 // we are now using 2024/25 LCF data 
	

* Prepare UKMOD and LCF data
	do 1a-data-prepare-UKMOD-input.do
	do 1b-data-prepare-LCF.do

* Run this only to check that the matching variables are similarly distributed in UKMOD and LCF data
	do 2-data-descriptive.do

* Compute Mahlanobis distance between UKMOD and LCF data, by deciles of net income
	do 3-data-matching.do

* Compute Mahlanobis distance between UKMOD and LCF data, by deciles of net income
	do 4-reduction-to-4digits.do
