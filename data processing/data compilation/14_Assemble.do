***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         14_Assemble.do
* INPUT FILE:           pers, lab, income, exp. hbai, assets, earn_hours, pensions, nic_regime, invinc
* OUTPUT FILE:          assembled
* DESCRIPTION:          Create draft UKMOD database - before pension age reforms adjustments - merging previously created data files 
* LAST UPDATE:          28/06/2024
***************************************************************************************
cap log close
log using "${log}\14_Assemble.log", replace

use pers, clear
merge m:m sernum person using lab
assert _merge==3
drop _merge

	merge m:m sernum person using income
assert _merge==3
drop _merge

	merge m:m sernum person using exp
assert _merge==3
drop _merge

	merge m:m sernum person using hbai
assert _merge==3
drop _merge

	merge m:m sernum person using assets
assert _merge==3
drop _merge

	merge m:m sernum person using earn_hours
assert _merge==3
drop _merge


	merge m:m sernum person using pensions		/*adults records only*/
ta _merge
replace boact00=0 if _merge==1
replace boactcm=0 if _merge==1
drop _merge

	merge m:m sernum person using invinc
assert _merge==3
drop _merge

/*
merge m:m sernum using expend_LCF
drop _merge*/
	  
	foreach var of varlist _all {
      replace `var' = 0 if missing(`var') 
	  }
	  

sort sernum person 
save assembled, replace
des

cap log close
