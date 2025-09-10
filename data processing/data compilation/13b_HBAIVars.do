***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         13b_HBAIVars.do
* DESCRIPTION:          Create HBAI variables 
* INPUT FILE:           individual, hbai_2023
* OUTPUT FILE:          hbai
* NEW VARs:
*                       - xhc_hbai      Expenditure - Total housing cost from HBAI (used to compute UKMOD AHC disposable income)

*                       - hbai_xhc02    SPI'd HBAI total housing costs
*                       - hbai_ben_ind  spi'd total benefit income 
*                       - hbai_ypt_ind  spi'd private benefit income 
*                       - hbai_yem_ind  gross, spi'd  employment income
*                       - hbai_yse_ind  gross, spi'd  self-employment income 
*                       - hbai_yiy_ind  gross, spi'd  investment income 
*                       - hbai_ypp_ind  gross, spi'd  occupational pension income 
*                       - hbai_yot_ind  spi'd total miscellaneous income 
*                       - hbai_yor_ind  gross, spi'd income 
*                       - hbai_yds_ind  net, spi'd income 

*                       - hbai_ben_hh  spi'd total benefit income for the household + amount of disability benefits paid to a child/ren for the household
*                       - hbai_ypt_hh  spi'd private benefit income for the household
*                       - hbai_yem_hh  gross, spi'd  employment income for the household
*                       - hbai_yse_hh  gross, spi'd  self-employment income for the household
*                       - hbai_yiy_hh  gross, spi'd  investment income for the household
*                       - hbai_ypp_hh  gross, spi'd  occupational pension income for the household
*                       - hbai_yot_hh  spi'd miscellaneous income for the household + total childrens income in the household
*                       - hbai_xmp_hh  spi'd other deductions for the household 
*                       - hbai_yor_hh  gross, spi'd gross household income (Before Housing Costs)
*                       - hbai_yds_hh   spi'd household net income (Before Housing Costs)
*                       - hbai_ydsa_hh  spi'd net household income (After Housing Costs)
*                       - hbai_egro_hh  Gross, SPI'd, deflated, equivalised household income - includes self-employment household income
*                       - hbai_ebhc_hh  Net, SPI'd, deflated, equivalised household income (BHC) 
*                       - hbai_eahc_hh  Net, SPI'd, deflated, equivalised household income (AHC) 

*                       - hbai_gs_ad    spi'd grossing factor for an adult
*                       - hbai_gs_bu	spi'd grossing factor for the family (benefit unit)
*                       - hbai_gs_ch	spi'd grossing factor for dependant children
*                       - hbai_gs_hh	spi'd grossing factor for the household 
*                       - hbai_gs_pn	spi'd grossing factor for pensioners
*                       - hbai_gs_pp	spi'd grossing factor for all individuals
*                       - hbai_gs_wa	spi'd grossing factor for working-age adults
* LAST UPDATE:           09/06/2025
***************************************************************************************
cap log close
log using "${log}\13b_HBAIVars.log", replace

set more off
use sernum person hrpid using individual, clear // open FRS data with household identifier
sort sernum person
gen idhh = sernum  
gen double idperson=(idhh*100+ person)


**********************************
*merge household level variables *
**********************************
merge m:m idhh idperson using "${hbai}\hbai_${frsyr}.dta", keepusing(xhc_hbai hbai_* idheadbu idspousebu) // merge individuals from the FRS and HBAI
if ${use_assert} assert _merge!=2 //HBAI sample has fewer cases so could be that _merge=1
drop _merge

*Housing costs 
replace xhc_hbai = xhc_hbai*(52/12) // convert to monthly amount
replace xhc_hbai=0 if hrpid!=1 // set to 0 if person is not household reference person
recode xhc_hbai (.=0)
label var xhc_hbai "HBAI total housing costs"

*SPI'd Housing costs 
replace hbai_xhc02 = hbai_xhc02*(52/12) // convert to monthly amount
replace hbai_xhc02=0 if hrpid!=1 // set to 0 if person is not household reference person
recode hbai_xhc02 (.=0)
label var hbai_xhc02 "SPI'd HBAI total housing costs"

sum xhc_hbai hbai_xhc02

 
*SPI'd household level income variables 
foreach var in hbai_ben_hh hbai_ypt_hh hbai_yem_hh hbai_yse_hh hbai_yiy_hh hbai_ypp_hh hbai_yot_hh hbai_yor_hh hbai_xmp_hh hbai_yds_hh hbai_ydsa_hh hbai_egro_hh hbai_ebhc_hh hbai_eahc_hh {
replace `var' = `var'*(52/12) // convert to monthly amount
replace `var'=0 if hrpid!=1 // set to 0 if person is not household reference person
recode `var' (.=0)
sum `var'
 }
 
*SPI'd head of benefit unit level income variabls   
foreach var in hbai_ben_headbu	hbai_ypt_headbu hbai_yem_headbu hbai_yse_headbu hbai_yiy_headbu hbai_ypp_headbu hbai_yot_headbu hbai_yor_headbu hbai_yds_headbu  {
replace `var' = `var'*(52/12) // convert to monthly amount
replace `var'=0 if idheadbu != idperson // set to 0 if person is not head of benefit unit 
recode `var' (.=0)
sum `var'
 }
 
*SPI'd spouse of benefit unit level income variabls   
foreach var in hbai_ben_spousebu	hbai_ypt_spousebu hbai_yem_spousebu hbai_yse_spousebu hbai_yiy_spousebu hbai_ypp_spousebu hbai_yot_spousebu hbai_yor_spousebu hbai_yds_spousebu  {
replace `var' = `var'*(52/12) // convert to monthly amount
replace `var'=0 if idspousebu != idperson // set to 0 if person is not spouse of benefit unit 
recode `var' (.=0)
sum `var'
 }
 
 
*SPI'd individual level (head + spouse of benefit unit)
gen hbai_ben_ind = hbai_ben_headbu + hbai_ben_spousebu //spi'd total benefit income 
gen hbai_ypt_ind = hbai_ypt_headbu + hbai_ypt_spousebu //spi'd private benefit income 
gen hbai_yem_ind = hbai_yem_headbu + hbai_yem_spousebu //gross, spi'd  employment income
gen hbai_yse_ind = hbai_yse_headbu + hbai_yse_spousebu //gross, spi'd  self-employment income 
gen hbai_yiy_ind = hbai_yiy_headbu + hbai_yiy_spousebu //gross, spi'd  investment income 
gen hbai_ypp_ind = hbai_ypp_headbu + hbai_ypp_spousebu //gross, spi'd  occupational pension income 
gen hbai_yot_ind = hbai_yot_headbu + hbai_yot_spousebu //spi'd total miscellaneous income 
gen hbai_yor_ind = hbai_yor_headbu + hbai_yor_spousebu //gross, spi'd income 
gen hbai_yds_ind = hbai_yds_headbu + hbai_yds_spousebu //net, spi'd income 
 

 
*HBAI Grossing factors
foreach var in hbai_gs_ad hbai_gs_bu hbai_gs_ch hbai_gs_hh hbai_gs_pn hbai_gs_pp hbai_gs_wa  {
recode `var' (.=0)
sum `var'
 }
 
 
drop idheadbu idspousebu hrpid *_headbu *_spousebu
save "${data}\hbai", replace 

cap log close
