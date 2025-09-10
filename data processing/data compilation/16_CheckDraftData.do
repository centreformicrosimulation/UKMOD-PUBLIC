***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         15_CheckDraftData.do
* INPUT FILE:           assembled
* OUTPUT FILE:          UK_2023_a*_0
* DESCRIPTION:          Create draft UKMOD database - before pension age reforms adjustments - merging previously created data files 
* LAST UPDATE:          09/06/2025
***************************************************************************************
cap log close
log using "${log}\15_CheckDraftData.log", replace
use assembled, clear
drop hrpid 

foreach var of varlist _all {
    count if missing(`var')
    if r(N) > 0 {
        di "`var' has " r(N) " missing values"
    }
}

// One CT per household (make sure only dhr=1 has a positive value)
forvalues i=1/4 {
replace tmu0`i'=0 if dhr==0
}

foreach var in bho bhoot xhcrt xhcmomi xhcot xhcsc xhcmomc xhc01 xhc xhc_hbai hbai_xhc02 {
	assert `var' >=0 & `var' !=.
	assert dhr==1 if `var'>0
	assert `var' ==0 if dhr==0
}
foreach var in tmu01 tmu02 tmu03 tmu04 { //
	assert `var' !=.
	assert dhr==1 if `var'>0
	assert `var' ==0 if dhr==0
}


* labour and income variables consistency checks

	tab2 les lcs
	tab2 les lfs  	
	tab2 les lin
	tab2 lhw les
	tab2 les loc
	tab2 les lowas
	tab2 les lcr01
	ta les if lhw>0

	ta les if yem>0
	ta les if yse>0
	ta les if lhw>0
	ta les if lhw00>0
	ta les if lhw01>0

drop sernum person
sort idhh idperson
save "UK_${frsyr}_${data_source}${data_ver}_15", replace					
label drop _all
des

********************
* from checkEMData:
*********************

* check for missing values
foreach var of varlist _all {
	qui count if `var' == .
	if (r(N) > 0) noi di in r "Error: variable `var' has " r(N) " missing values!"
}

***************************************************************
* Personal information
***************************************************************

noi sum d*

* tabs of categories

noi di
foreach var in dag dcz ddi dec dec02 deh dey dgn dms {  	// add other categorical Personal Information variables (if any)
	cap confirm var `var'
	if (!_rc) noi tab `var', m
	else noi di in w "Warning: variable `var' does not exist."
}

***************************************************************
* Labour market information
***************************************************************

noi sum l*

* tabs of categories, separating by those with earnings and without earnings

foreach var in les lin loc {							// add other categorical Labour market Information variables (if any)
	cap confirm var `var'
	if (!_rc) {
		tab `var' if yem + yse > 0, m
		tab `var' if yem + yse == 0, m
	}
	else noi di in w "Warning: variable `var' does not exist."
}

* hours of work, separating by those with earnings and without earnings

noi di in w "Distribution of hours of work with non-zero earnings"
noi sum lhw if yem != 0 | yse != 0
noi di in w "Distribution of hours of work with zero earnings"
noi sum lhw if yem == 0 & yse == 0

***************************************************************
* Income (Income, Benefits, Pensions, Taxes, Kind)
***************************************************************


* check aggregation of incomes, taxes, benefits, pensions and expenditures

foreach type in y  b  x { //
	foreach var of varlist `type'?? {
		local acro1 = substr("`var'",2,2)	
		capture sum `type'`acro1'?? 
		if (_rc == 0) {
			display in y " "
			display in y "Check aggregation of variable: `var'"
			display in y "_______________________________ "
			sum `var'*
			egen test_`var' = rowtotal(`type'`acro1'??)		
			compare `var' test_`var' 
		}
	}
}

drop test_*

* sum employment and self-employment incomes
noi di in w "Summarise positive earnings:"
foreach var of varlist yse yem {
	noi sum `var' if `var' > 0
	cap confirm `var'my
	if (!_rc) {
		noi sum `var'my if `var' > 0
		noi sum `var'my if `var' == 0
	}
}

* check for negative values
foreach var of varlist b* y* t*  {
	qui count if `var' < 0
	if (r(N) > 0) noi di in w "Warning: variable `var' has " r(N) " negative values."
}

***************************************************************
* Assets and Expenditures
***************************************************************

noi sum a* x*

* check for negative values
foreach var of varlist a* x* {
	qui count if `var' < 0
	if (r(N) > 0) noi di in w "Warning: variable `var' has " r(N) " negative values."
}

***********************************************************************************************************
* Non monetary variables at household level in the original dataset assigned to all the persons in the hh
***********************************************************************************************************

local hh_vars = "amrrm amrtn dct drgn1 dwt *_hh"     		// Add other variables at hh level assigned to all the persons in the hh (if any)

* check which ones exist
foreach var in `hh_vars' {
	cap confirm var `var'
	if (!_rc) local hh_vars1 = "`hh_vars1' `var'"
	else noi di in w "Warning: variable `var' does not exist."
}
*noi di in r "`hh_vars1'"

noi sum `hh_vars1'

* check that household variables are the same across all household members

sort idhh
foreach var of varlist `hh_vars1' {
	count if `var' != `var'[_n-1] & idhh == idhh[_n-1]
	if (r(N) > 0) noi di in r "Inconsistency: variable `var' has " r(N) " observations where the value is not the same across all household members!"
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson `var' if `var' != `var'[_n-1] & idhh == idhh[_n-1], sepby(idhh) 
}

* check that ddt variable (Date of interview) are the same across all household members

sort idhh
count if ddt != ddt[_n-1] & idhh == idhh[_n-1]
if (r(N) > 0) noi di in y "Warning: variable ddt has " r(N) " observations where the value is not the same across all household members!"


* tabs of categories

foreach var in dct ddt drgn1 amrtn {
	cap confirm var `var'
	if (!_rc) noi tab `var', m
	else noi di in w "Warning: variable `var' does not exist."
}



display "Run finished on $S_DATE at $S_TIME"
log close
