***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         18_DRD.do
* DESCRIPTION:          Produce statistics for the DRD
* INPUT FILES:          UKMOD input database (i.e. cc_yyyy_x#.dta) 
* OUTPUT FILES:         n/a
* LAST UPDATE:          15/06/2026
***************************************************************************************
capture log close
log using "${log}/DRD_UK_${frsyr}_${data_source}${data_ver}.log", replace     

use "UK_${frsyr}_${data_source}${data_ver}", clear			// Input data file 

***************************************************************************************
* Summary statistics
***************************************************************************************

************************************************************************
* IDs and Personal Information
************************************************************************

preserve
local var = "id* d*" // revise the list of variables to avoid recoding meaningful values as missing (e.g. dgn) 
qui recode `var'  (0=.)
recode dag dgn (.=0)
recode ddi dew dot (-1=.)
sum `var'  [aw=dwt], sep(0)
restore

************************************************************************
* Labour market information 
************************************************************************

preserve
local vars "l*" // revise the list of variables to avoid recoding meaningful values as missing 
foreach var of varlist `vars' {
	if "`var'" != "loc" recode `var' (0=.)
}
sum `vars' [aw=dwt], sep(0)
restore 

************************************************************************
* Income, Benefits and Taxes
************************************************************************

preserve
local var = "y* b* t*"
qui recode `var'  (0=.)
sum `var'  [aw=dwt], sep(0)
restore

************************************************************************
* Assets 
************************************************************************

preserve
local var = "a*" // revise the list of variables to avoid recoding meaningful values as missing 
qui recode `var'  (-1 0=.)
sum `var'  [aw=dwt], sep(0)
restore

************************************************************************
* Expenditures
************************************************************************

preserve
local var = "x*"
qui recode `var'  (0=.)
sum `var'  [aw=dwt], sep(0)
restore

************************************************************************
* HBAI vars 
************************************************************************

preserve
local var = "hbai_*"
qui recode `var'  (-1 0=.)
sum `var'  [aw=dwt], sep(0)
restore



***************************************************************************************
* Frequencies
***************************************************************************************

************************************************************************
* Personal Information
************************************************************************

foreach var of varlist d* {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}

************************************************************************
* Labour market information 
************************************************************************

foreach var of varlist l* {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}


************************************************************************
* Income, Benefits and Taxes
************************************************************************
*DP: bhomy is no longer available in 2021/22
/*
foreach var of varlist b*my {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}
*/

************************************************************************
* Assets 
************************************************************************

foreach var of varlist a* {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}


************************************************************************
* Expenditures
************************************************************************

foreach var of varlist x* {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}


************************************************************************
* HBAI 
************************************************************************

foreach var of varlist hbai* {
	qui inspect `var'
	if (r(N_unique) > 1 & r(N_unique) <= 20) tab `var' [iw=dwt]
}


***************************************************************************************
* Summary statistics of all variables
***************************************************************************************
aorder id* d* l* y* b* a* x* hbai*

* Define variables to exclude (all dummies) 
local exclude ddi ddi03 dgn dhr lcr01 lmcee lowas lcs lle

ds
local to_recode
foreach var of varlist `r(varlist)' {
    if strpos(" `exclude' ", " `var' ") == 0 {
        local to_recode `to_recode' `var'
    }
}

di "`to_recode'"
quietly recode `to_recode' (0=.)

recode dag (.=0)
recode ddi dew dot lindi loc amriv00 lcwnm  (-1=.) //bwkmcee
sum *  [aw=dwt], sep(0)

display "Run finished on $S_DATE at $S_TIME"
capture log close
