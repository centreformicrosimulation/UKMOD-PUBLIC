***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         01_AdjustFRS.do
* DESCRIPTION:          change capital letters of variable names to small letters
* LAST UPDATE:          09/06/2025
***************************************************************************************
dir "${origydata}/*.dta"
foreach f in accounts adult assets benefits benunit care child chldcare endowmnt extchild frs2324 govpay househol job maint mortcont mortgage oddjob owner penprov pension rentcont renter   {
	use "${origydata}/`f'.dta", clear
	foreach var of varlist _all {
		rename `var' `=lower("`var'")'
	}
	save "`f'.dta", replace
}

