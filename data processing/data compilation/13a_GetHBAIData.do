***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         13a_GetHBAIData.do
* DESCRIPTION:          Create HBAI housing cost and income data to be merged to the FRS
* INPUT FILE:           HBAI data
* OUTPUT FILE:          hbai_2023
* NEW VARs:
*                       - xhc_hbai             Expenditure - Total housing cost based on the HBAI data
*                       - preliminary vars for SPI'd HBAI incomes  
* LAST UPDATE:          09/06/2025
***************************************************************************************
cap log close
log using "${log}\13a_GetHBAIData.log", replace

set more off
* create a dataset with HBAI variablea for each HBAI wave
local v_2023 i2124e_2324prices // 2023/24 data 
foreach year in 2023 {
use "${orig_hbai}/`v_2023'.dta", clear // UKDA end user licence version //
rename *, lower

fre year 
keep if year==30 //keep 2023-24 year only


//create ids as in UKMOD input data
sort sernum person
rename sernum idhh  
//rename benunit idorigbenunit
gen double idperson=(idhh*100+ person)
gen idorigperson=person

gen idheadbu = (idhh*100+personhd)
gen idspousebu = (idhh*100+personsp) if personsp>0
replace idspousebu=0 if personsp==0 

*housing costs variable 
rename ehcost xhc_hbai

*SPI'd household level income variables 
gen hbai_ben_hh = esbenihh + chbenhh  //spi'd total benefit income for the household + amount of disability benefits paid to a child/ren for the household
rename espribhh	hbai_ypt_hh  //spi'd private benefit income for the household
rename esgjobhh	hbai_yem_hh //gross, spi'd  employment income for the household
rename esgrsehh	hbai_yse_hh //gross, spi'd  self-employment income for the household
rename esginvhh	hbai_yiy_hh  //gross, spi'd  investment income for the household
rename esgocchh	hbai_ypp_hh //gross, spi'd  occupational pension income for the household
gen hbai_yot_hh = esmischh+	inchilhh  //spi'd miscellaneous income for the household + total childrens income in the household
rename esothdhh	hbai_xmp_hh //spi'd other deductions for the household 

rename esginchh hbai_yor_hh //gross, spi'd gross household income (Before Housing Costs)

rename esninchh	hbai_yds_hh  //spi'd household net income (Before Housing Costs)
rename es_hcost	hbai_xhc02 //spi'd total housing costs
rename esahchh hbai_ydsa_hh //spi'd net household income (After Housing Costs)

rename s_oe_gro hbai_egro_hh //Gross, SPI'd, deflated, equivalised household income - includes self-employment household income
rename s_oe_bhc hbai_ebhc_hh //Net, SPI'd, deflated, equivalised household income (BHC) 
rename s_oe_ahc hbai_eahc_hh //Net, SPI'd, deflated, equivalised household income (AHC) 

sum bhcdef //income deflator (bhc) 
sum ahcdef //income deflator (ahc) 
sum eqobhchh //equivalisation factors (bhc) 
sum eqoahchh //equivalisation factors (ahc) 


*SPI'd head of benefit unit level  
rename esbenihd hbai_ben_headbu	//spi'd total benefit income for the head of the family (benefit unit)
rename espribhd	hbai_ypt_headbu //spi'd private benefit income for the head of the family (benefit unit)
rename esgjobhd	hbai_yem_headbu //gross, spi'd  employment income for the head of the family (benefit unit)
rename esgrsehd	hbai_yse_headbu //gross, spi'd  self-employment income for the head of the family (benefit unit)
rename esginvhd	hbai_yiy_headbu //gross, spi'd  investment income for the head of the family (benefit unit)
rename esgocchd	hbai_ypp_headbu //gross, spi'd  occupational pension income for the head of the family (benefit unit)
rename esmischd	hbai_yot_headbu //spi'd total miscellaneous income for the head of the family (benefit unit)
rename esginchd	hbai_yor_headbu //gross, spi'd income for the head of the family (benefit unit)
rename esninchd	hbai_yds_headbu //net, spi'd income for the head of the family (benefit unit)

*SPI'd spouse of benefit unit level  
rename esbenisp	hbai_ben_spousebu //spi'd total benefit income for the spouse of the family (benefit unit)
rename espribsp	hbai_ypt_spousebu //spi'd private benefit income for the spouse of the family (benefit unit)
rename esgjobsp	hbai_yem_spousebu //gross, spi'd  employment income for the spouse of the family (benefit unit)
rename esgrsesp	hbai_yse_spousebu //gross, spi'd  self-employment income for the spouse of the family (benefit unit)
rename esginvsp	hbai_yiy_spousebu //gross, spi'd  investment income for the spouse of the family (benefit unit)
rename esgoccsp	hbai_ypp_spousebu //gross, spi'd  occupational pension income for the spouse of the family (benefit unit)
rename esmiscsp	hbai_yot_spousebu //spi'd total miscellaneous income for the spouse of the family (benefit unit)
rename esgincsp	hbai_yor_spousebu //gross, spi'd  income for the spouse of the family (benefit unit)
rename esnincsp	hbai_yds_spousebu //net, spi'd income for the spouse of the family (benefit unit)


*HBAI Grossing factors
rename gs_indad hbai_gs_ad //spi'd grossing factor for an adult 
rename gs_indbu hbai_gs_bu //spi'd grossing factor for the family (benefit unit) 
rename gs_indch hbai_gs_ch //spi'd grossing factor for dependant children 
rename gs_indhh hbai_gs_hh //spi'd grossing factor for the household 
rename gs_indpn hbai_gs_pn //spi'd grossing factor for pensioners 
rename gs_indpp hbai_gs_pp //spi'd grossing factor for all individuals 
rename gs_indwa hbai_gs_wa //spi'd grossing factor for working-age adults


keep idhh benunit idperson xhc_hbai idheadbu idspousebu hbai_*  

save "${hbai}/hbai_`year'.dta", replace
}

cap log close

