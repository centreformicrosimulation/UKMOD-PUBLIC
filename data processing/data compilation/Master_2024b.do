***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         Master_2023b.do
* DESCRIPTION:          Main do-file to set the main parameters (country, paths) and
*                       create the final database
*						Do-file appends the latest three FRS waves
************************************************************************
* COUNTRY:              UK
* FRS VERSION:        	Family Resources Survey 2021/22, 2022/23, 2023/24
* NATIONAL MODELLERS:   Justin Van de Ven, Daria Popova 
* AUTHORS: 				Paola De Agostini, Iva Tasseva, Daria Popova 
* LAST UPDATE:          15/06/2026
***************************************************************************************
clear all
set type double
set more off
************************************************************************
* Define folder paths for the analysis
************************************************************************
global path_proj "D:\Dasha\ESSEX\UKMOD\input-dataset" 
global data "${path_proj}\Data\"
global yrl2f "FRS-2022-23" // folder where lag 2 data are stored
global yrl1f "FRS-2023-24" // folder where lag 1 data are stored
global yrf "FRS-2024-25" // folder where latest data are stored
global pooled_data "${path_proj}\Data\Pooled_data\" // where to store final pooled dataset

************************************************************************
* Define the FRS year, i.e. when was collected
* (will be used in the name of output files)
************************************************************************
global yrl2 2022_a2 // lag 2 data
global yrl1 2023_a3 // lag 1 data
global yr 2024 // latest data year

************************************************************************
* Define EUROMOD-UK/UKMOD database source, i.e. x in CC_year_x# (eg. uk_2006_a1)
* (will be used in the name of the final output file)	
************************************************************************
global data_source "b"	// a=single FRS wave, b=3 appended FRS waves

************************************************************************
* Define EUROMOD-UK/UKMOD database version, i.e. # in CC_year_x# (eg. uk_2006_a1)
************************************************************************
global data_ver "1"	

*******************************************************************************************
* Append datasets, give a value variables with missing values and create pooled dataset
*******************************************************************************************
* append relevant EM input files
use "${data}\$yrl2f\UK_${yrl2}.dta", clear 
append using "${data}\$yrl1f\UK_${yrl1}.dta"
append using "${data}\$yrf\UK_${yr}_a${data_ver}.dta"

order dpd idhh idperson

*** check appended files for missing values and replace with meaningfull values
* variables aca and aco no longer available from FRS 2018/19; 
* ddi02, ddipd00, bhoen*, lim, limiv no longer needed and not provided in the 2018 data
* dot introduced with 2018 data - added to 2017/2018
/*
qui foreach var in  ddi02 ddipd00 dot lim limiv { //aca aco
	replace `var' = -1 if `var'==.
}
*/
	
* default values for IB and c-ESA set to zero if variable is missing
qui foreach var of varlist bdict*  {
	replace `var' = 0 if `var'==.
}

* info on number of years in current self-employment available only since FRS 2017/18. 
* the variable is used in the calculation of the Minimum Income Floor in Universal Credit. 
* a value of 1 for 2016/17 data implies none of the self-employed is exempt from the MIF.
replace yseny = 1 if yseny==. 

*** adjust sample weights
ge dwtorig = dwt // store original weight value
replace dwt = dwt/3 // divide by number of appended waves
drop dwtorig

*** adjust hbai weights 
foreach var in hbai_gs_ad hbai_gs_bu hbai_gs_ch hbai_gs_hh hbai_gs_pn hbai_gs_pp hbai_gs_wa { 
gen `var'_orig = `var' // store original weight value
replace `var' = `var'/3 // divide by number of appended waves
drop `var'_orig
} 


*** some household/person IDs may be the same across FRS waves, so need to adjust them
foreach var in idhh idperson idpartner idmother idfather idmotherbio idfatherbio { 
	egen temp1=concat(dpd `var') if `var'!=0, format(%15.0g) // combine data year (dpd) and ID to create new IDs
	destring temp1, gen(temp2)
	replace `var' = temp2  
	replace `var' = 0 if `var'==.
	format `var'  %16.0g
	cap drop temp1 temp2 
}


* replace missing values 
replace dcz = 1 if dcz!=1 

* default values for variables that are not available in some datasets  
foreach var in lcwnm  { //bhomy ddipd bhootlmcee bwkmcee lmcse bwkmcse
	replace `var' = -1 if `var'==.
}


foreach var of varlist _all {
	replace `var'=-1 if `var'==.
	assert `var' !=. 
}


sort idhh idperson

/***set tmu04 to tmu02 in 2018 due to low quality of data in 2018/19
bysort dpd: sum tmu04
replace tmu04=tmu02 if dpd==2018
bysort dpd: sum tmu04
*/

display "Run finished on $S_DATE at $S_TIME"
capture log close

save "${pooled_data}\UK_${yr}_${data_source}${data_ver}.dta", replace
outsheet using "${pooled_data}\UK_${yr}_${data_source}${data_ver}.txt", replace nol


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
