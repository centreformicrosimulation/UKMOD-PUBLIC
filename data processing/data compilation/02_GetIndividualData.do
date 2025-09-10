***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         02_GetIndividualData.do
* DESCRIPTION:          append datasets with adult's and children's records
* INPUT FILE:           household, adult, child
* OUTPUT FILE:          individual
* LAST UPDATE:          09/06/2025
***************************************************************************************
cap log close 
log using "${log}/02_GetIndividualData.log", replace
*** number of households, adults, and children
	use $data/househol.dta, clear
	des,s
	use $data/adult.dta, clear
	des,s
	use $data/child.dta, clear
	gen adult=0
	des,s

*** append adult and child data to create an individual level database
	append using $data/adult.dta
	replace adult=1 if adult==.
	ta adult,m
	des,s
	sort sernum person 			/*note: sort by benefit unit inside hh implied*/
	save individual, replace

cap log close

