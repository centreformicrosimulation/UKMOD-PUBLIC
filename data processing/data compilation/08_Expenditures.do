***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         08_Expenditures.do
* DESCRIPTION:          Create expenditures variables 
* INPUT FILE:           individual, maint
* OUTPUT FILE:          exp
* NEW VARs:
*                       - xmp             Expenditure - Maintenance Payments
*                       - xhcrt           Expenditure - Housing cost - Rent
*                       - xhcmomi         Expenditure - Housing cost - Mortgage Interest
*						- xhcot			  Expenditure - Housing cost - Water and sewerage charges
*						- xhcsc			  Expenditure - Housing cost - Compulsory service charges
*						- xhc01			  Expenditure - Housing cost - Structural insurance premiums
*                       - xhc             Expenditure - Total housing cost based on the HBAI definition
*						- xhcmomc		  Expenditure - Housing cost - Capital repayment of mortgage
*						- xcc			  Expenditure - Child care costs
*                       - xpp             Expenditure - Private pension contribution
* LAST UPDATE:          26/06/2024
***************************************************************************************
cap log close
log using "${log}\08_Expenditures.log", replace

use sernum person hrpid using individual, clear
sort sernum person
save temp, replace


**************************************
*	xmp - Maintenance payments 

* mramt - Amount of last maintenance payment
* mruamt - Amount of usual maintenance payment
**************************************
use sernum person mruamt mramt mrus using $data/maint.dta, clear
	de
	count if !(mramt>0 & mramt!=.)   // obs with zero value
	qui count if !(mramt>0 & mramt!=.)
	if (r(N) > 0) noi display in r "N OBS WHICH REQUIRE ATTENTION:" r(N) 
	if ${use_assert} assert mruamt>0 if mrus==2
	gen xmp =0
	replace xmp =mramt*(52/12)
	replace xmp =mruamt*(52/12) if mrus==2
	inspect xmp 
	collapse (sum) xmp, by(sernum person) 
	sort sernum person
merge m:m sernum person using temp
	replace xmp=0 if _merge==2
	label var xmp "maintenance paid"
	drop _merge
sort sernum person
save exp, replace

*************************************************************
*	xhcrt - Rent 

* hhrent - Gross Rent for HH
*************************************************************
use sernum hhrent mortint gvtregn* csewamt cwatamtd watsewrt chrgamt* stramt* strcov covoths gbhscost nihscost using $data/househol, clear
	de 
	*if ${use_assert} assert hhrent !=.
	gen xhcrt =0
	replace xhcrt = hhrent*(52/12) if hhrent>0 &  hhrent!=.
	label var xhcrt  "Gross rent"
	sort sernum
merge sernum using exp
	assert _merge==3
	replace xhcrt =0 if hrpid!=1
	label var xhcrt "rent"
	drop _merge hhrent
sort sernum person
save exp, replace

**************************************
*	xhcmomi - Mortgage interest payment 

* mortint - Owner Occupiers only - Mortgage interest
**************************************
	de mortint
	*if ${use_assert} assert mortint!=.
	gen xhcmomi = 0
	replace xhcmomi = mortint*(52/12)  if mortint>0 & mortint!=.
	replace xhcmomi =0 if hrpid!=1
	label var xhcmomi  "mortgage interest payment"
	drop mortint
sort sernum person
save exp, replace

**************************************
*	xhcot - Water and sewerage charges 

* cwatamtd - Deriv Council Tax water charge -Scot
* csewamt - Sew. Charge: Final value after discount
* watsewrt - Total Water and Sewerage
* gvtregno - Region in UK (original FRS codes) 
**************************************
de cwatamtd gvtregno cwatamtd csewamt watsewrt
fre gvtregno
gen xhcot=0
replace xhcot= xhcot + cwatamtd if gvtregno==12 & cwatamtd>=0 & cwatamtd!=. // charges for water and sewage for Scottish hhs    
replace xhcot= xhcot + csewamt if gvtregno==12 & csewamt>=0 & csewamt!=.
replace xhcot= xhcot + watsewrt if gvtregno<12 & watsewrt>=0 & watsewrt!=.	 // charges for water and sewage for non-Scottish hhs (note: no council tax in Northern Ireland)
//replace xhcot = csewamt if sernum==11524 // FRS 2018/19: csewamt included in total housing costs
replace xhcot= xhcot*(52/12) // convert to monthly amount
replace xhcot=0 if hrpid!=1
label var xhcot "water and sewage charges"
drop  csewamt cwatamtd watsewrt
sort sernum person
save exp, replace

**************************************
*	xhcsc - Compulsory service charges 

* chrgamt1 - Amount paid for Ground Rent
* chrgamt3 - Amount paid for chief rent
* chrgamt4 - Amount paid for service charge
* chrgamt5 - Amount paid for regular maintenance
* chrgamt6 - Amount paid for site rent
* chrgamt7 - Amount paid for factoring
* chrgamt8 - Amount paid for other regular charges
* chrgamt9 - Amount paid for combined services
**************************************
de chrgamt*
replace chrgamt4=0 if sernum==1710 //chrgamt4 must be included in chrgamt5 for this hh

gen xhcsc =0
replace xhcsc = xhcsc + chrgamt1 if chrgamt1>0 & chrgamt1!=.  & chrgamt1!=-1 // ground rent
replace xhcsc = xhcsc + chrgamt3 if chrgamt3>0 & chrgamt3!=.  & chrgamt3!=-1 // chief rent
replace xhcsc = xhcsc + chrgamt4 if chrgamt4>0 & chrgamt4!=.  & chrgamt4!=-1 // service charge
replace xhcsc = xhcsc + chrgamt5 if chrgamt5>0 & chrgamt5!=.  & chrgamt5!=-1 // regular maintenance charge
replace xhcsc = xhcsc + chrgamt6 if chrgamt6>0 & chrgamt6!=.  & chrgamt6!=-1 // site rent
replace xhcsc = xhcsc + chrgamt7 if chrgamt7>0 & chrgamt7!=.  & chrgamt7!=-1 // factoring
replace xhcsc = xhcsc + chrgamt8 if chrgamt8>0 & chrgamt8!=.  & chrgamt8!=-1 // other regular charges
replace xhcsc = xhcsc + chrgamt9 if chrgamt9>0 & chrgamt9!=.  & chrgamt9!=-1 // combined services
//replace xhcsc = chrgamt1 if sernum==5619 // FRS 2018/19: chrgamt9 not included in total housing costs
replace xhcsc = xhcsc * (52/12) // convert to monthly amount
replace xhcsc = 0 if hrpid!=1
label var xhcsc "compulsory service charges"
drop chrgamt*
sort sernum person
save exp, replace

***************************************
*	xhc01 - Structural insurance premiums

* stramt1 - Amount: Insurance part of repayment
* stramt2 - Amount: Insurance premium
* strcov - Items covered by insurance policy	
*	1	Buildings insurance only
*	2	Contents insurance only
*	3	Buildings and contents insurance
* covoths - Insurance premium: what covered	
*	1	Buildings insurance only
*	2	Buildings and contents
***************************************
gen xhc01 = 0 
* add insurance part of repayment if buildings insurance only
replace xhc01 = xhc01 + stramt1 if strcov==1 & stramt1!=-1 & stramt1!=.
* add 2/3 of insurance part of repayment if buildings & contents insurance
replace xhc01 = xhc01 + 2/3*stramt1 if strcov==3 & stramt1!=-1 & stramt1!=.
* add insurance premium if buildings insurance only
replace xhc01 = xhc01 + stramt2 if covoths==1 & stramt2!=-1 & stramt2!=.
* add 2/3 of insurance premium if buildings & contents insurance
replace xhc01 = xhc01 + 2/3*stramt2 if covoths==2 & stramt2!=-1 & stramt2!=.
replace xhc01 = xhc01*(52/12) // convert to monthly amount
replace xhc01=0 if hrpid!=1
label var xhc01 "structural insurance premiums"
sort sernum person
save exp, replace

**************************************************************************
*	xhc - Total housing costs based on the HBAI definition
* should equal the (rounded) sum of xhcrt, xhcot, xhcmomi, xhcsc and xhc01 
**************************************************************************
gen xhc = 0
replace xhc = gbhscost if gbhscost !=-1 & gbhscost !=-2 & gvtregno!=13 // total housing costs in Great Britain
replace xhc = nihscost if nihscost !=-1 & nihscost !=-2 & gvtregno==13 // total housing costs in Northern Ireland
replace xhc = xhc*(52/12) // convert to monthly amount
replace xhc=0 if hrpid!=1
label var xhc "total housing costs"
 gen tot_hous = xhcrt + xhcot + xhcmomi + xhcsc + xhc01 
compare xhc tot_hous
*if ${use_assert} assert abs(xhc - tot_hous) < 10 // allow for small rounding difference //FRS2021/22 and 2022/23- difference was higher for 2 hhs 
replace xhc = tot_hous if tot_hous>0 & (xhc==0 | (abs(xhc - tot_hous) >10)) //imputed missing or low xhc 
sort sernum person
save exp, replace


******************************************
* xhcmomc - Capital repayment of mortgage

* borramt - Amount of the original mortgage or loan
* rmamt - Total amount of the re-mortgage
* mortend- Term of mortgage
*******************************************
* amount initially borrowed/ monthlyfied term of mortgage 

use sernum borramt rmamt rmort mortend using $data/mortgage, clear
	de
	gen amount=borramt if rmort!=1
	replace amount=rmamt if rmort==1
	inspect amount mortend
		gen xhcmomc = (amount/(mortend*12)) if amount>=0 & mortend>0
	replace xhcmomc =0 if xhcmomc ==.
	keep sernum xhcmomc 
	collapse (sum) xhcmomc , by(sernum)	
sort sernum
merge sernum using exp
	replace xhcmomc=0 if _merge==2
	replace xhcmomc=0 if hrpid!=1
	drop _merge hrpid
	label var xhcmomc "monthly capital repayment"
sort sernum person
save exp, replace

*************************************************************
*	xcc - Child care costs 

* cost - Whether childcare costs anything (1 yes, 2 no)
* registrd - Whether registered	(1 yes, 2 no)
* chamt - Costs of childcare
*************************************************************
*** (registered paid for self childcare only) 
use $data/chldcare, clear
	de
	keep if cost==1 & registrd==1
	gen xcc =0
	replace xcc = chamt*(52/12)
	keep sernum person xcc			
	collapse (sum) xcc, by(sernum person)	
	sort sernum person
merge 1:1 sernum person using exp	
	drop if _merge==1			
	replace xcc=0 if _merge==2
	drop _merge
	inspect xcc
	label var xcc "registr. childcare cost"
sort sernum person
save exp, replace

*************************************************************************
*	xpp - Private pension contribution 

* stemppen - Pension Type	
*	1	Employer: Group Personal Pension
*	2	Employer: Company or Occupational Pension
*	3	Employer: Group Stakeholder Pension
*	4	Employer: Pension - Other / Not Known
*	5	Self: Personal Pension
*	6	Self: Stakeholder Pension
* penamt - Amount of last payment to Pension
*************************************************************************
use $data/penprov, clear
	de
	keep if stemppen==5|stemppen==6 	/*personal or personal/stakeholder pension*/
	replace penamt=0 if penamt==-1
	gen xpp=0
	replace xpp=penamt*52/12
	inspect xpp
	collapse (sum) xpp,  by(sernum person)
 	inspect xpp
	isid sernum person
	sort sernum person
merge sernum person using exp
	replace xpp=0 if _merge==2
	drop _merge
	inspect xpp
	label var xpp "private pension contribution"
	
	su xpp if xpp>0, d
	replace xpp = r(p95) if xpp > r(p95)
	su xpp if xpp> 0, d
	
keep sernum person xmp xhcrt xhcmomi xhcot xhcsc xhc01 xhc xhcmomc xcc xpp 
sort sernum person
save exp, replace
des
cap log close
