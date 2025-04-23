******************************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         11_Pensions.do
* DESCRIPTION:          Create pension variables 
*						- assume individuals still only receive the basic state pension and second state pension (i.e. noone receives the new state pension)
*						- split the total pension amount into the basic state and second pensions
*						- the split is important as pension amounts are indexed/uprated differently 
* INPUT FILE:           individual, benunit, pensions
* OUTPUT FILE:          pensions
* NEW VARs:
*                       - boact00             Pension - first pension
*                       - boactcm	          Pension - second pension
* LAST UPDATE:          26/06/2024
*******************************************************************************************************
cap log close 
log using "${log}/11_Pensions.log", replace
use sernum benunit person age80 age adult sex marital empstatb disben5 using individual, clear
	de
	keep if adult==1	
	gen age2=age80 
	drop age age80
	sort sernum benunit
	save pensions, replace

use sernum benunit depchldb using $data/benunit, clear
	de
	sort sernum benunit
	merge sernum benunit using pensions
	assert _merge==3
	drop _merge
	sort sernum person
	save pensions, replace 

***************************************************************************
*** TOTAL STATE PENSION

* benefit = 5 - Retirement Pension
* benefit = 6 - Bereavement Support Payment / Widowed Parent's Allowance
***************************************************************************
	use sernum person benefit benamt using $data/benefits, clear
	sort sernum person
	merge sernum person using pensions
	ta _merge
	drop if _merge==1
	keep sernum person benefit benamt sex age2
		/*includes cases of Widow's Pension/Bereavement Allowance received by those above pension age*/	
	keep if benefit==5|(benefit==6 & ((sex==1 & age2>=${SPAm})|(sex==1 & age2>=${SPAw})))
	isid sernum person
	drop benefit
	rename benamt retpen
	sort sernum person
		merge sernum person using pensions
		ta _merge
		drop _merge
	replace retpen=0 if retpen==.
	inspect retpen
	sort sernum person
	save pensions, replace

* previous do-file versions made use of FRS data file penamt to disaggregate pension types, but that file is no longer available
	use pensions, clear
	ge retpen2=.
	ge basic=.
	ge serps=.
	
	//people below state pension age receiving pension???
	if ${use_assert} assert retpen==0 if sex==1 & age<${SPAm} 
	if ${use_assert} assert retpen==0 if sex==2 & age<${SPAw} 
		
	//eligible for old state pension 
	count if sex==1 & age2>=${NSPm} & retpen>0 
	count if sex==2 & age2>=${NSPw} & retpen>0  
	
	//eligible for new state pension 
	count if sex==1 & age2>=${SPAm} & age2<${NSPm} & retpen>0 
	count if sex==2 & age2>=${SPAw} & age2<${NSPw} & retpen>0  
	

* pension can be reported in penamt or in benefit. Compare the two values and impute where missing/possible
***cases to be imputed: 
	gen impute=((basic==.|serps==.) & retpen>0) | (basic==0 & retpen>0)|(serps==0 & basic>0 & retpen-basic>0 & basic!=.)
	ta impute	
	if ${use_assert} assert impute==1  if retpen2==0 & retpen>0
	
	sort sernum person
	save pensions, replace
	des,s 

**************************************************************************************
*** split basic and second state pension (or SERPS as it was called before 2002)
*   where not separately reported or inconsistent
**************************************************************************************
	use pensions, clear
	de
*** gen partnership variable to distinguish: single or cohabiting; married; and living together and married but spouse away 
	by sernum benunit,sort: egen nads=total(adult)	/*if de facto alone, 2 if partner living in bu*/
	by sernum benunit,sort: egen sumsex=total(sex)	
	ta sumsex if nads==2
	gen samesex_couple=(nads==2 & sumsex==2|sumsex==4)
	drop sumsex

	gen couple=1 if marital==2 & nads==2		/*married and both partners present*/
	replace couple=2 if nads==2 & marital!=2 /*couples living together but not  married*/
	replace couple=0 if couple==. /*all the others: will be treated as singles, as even if an absent partner existed we would not have info*/
* same sex couples treated as if they were singles for this purpose 
	replace couple=0 if couple==1 & samesex_couple==1

	tab couple impute
	replace couple=. if impute==0
	ta couple
	
	gen newclaim =((sex==1 & age2<${SPAm}+5)|(sex==2 & age2<${SPAw}+5)) /*newclaim==1: cannot get dependent children additions anymore, after 2003*/

**************************************
*** SINGLES (including same sex allthough legally partnered) or living with no partner (irrespective of marital status)
**************************************
ta depchldb if couple==0 & newclaim!=1
replace basic=retpen if impute==1 & couple==0 & retpen <= $osp_basic & (depchldb==0|newclaim==1) 
replace basic=$osp_basic if impute==1 & couple==0 & retpen > $osp_basic & (depchldb==0|newclaim==1) 
replace basic=retpen if impute==1 & couple==0 & retpen <= ($osp_basic + $osp_depech + $osp_depch *(depchldb-1)) & depchldb>0 & newclaim!=1
replace basic=$osp_basic + $osp_depech + $osp_depch *(depchldb-1) if impute==1 & couple==0 & retpen > ($osp_basic + $osp_depech + $osp_depch *(depchldb-1)) & depchldb>0 & newclaim!=1

replace serps = retpen- basic if couple==0 
if ${use_assert} assert basic!=. & serps!=. if couple==0


****************************************************************************
*** COHABITING not married: attribute children additions to the male partner
****************************************************************************
ta depchldb if couple==2 & newclaim!=1
replace basic=retpen if impute==1 & couple==2 & retpen <= $osp_basic & (depchldb==0|newclaim==1|sex==2)  
replace basic=$osp_basic if impute==1 & couple==2 & retpen > $osp_basic & (depchldb==0|newclaim==1|sex==2)  
replace basic=retpen if impute==1 & couple==2 & retpen <= $osp_basic + $osp_depech + $osp_depch *(depchldb-1) & depchldb>0 & newclaim!=1 & sex==1 
replace basic=$osp_basic + $osp_depech + $osp_depch *(depchldb-1) if impute==1 & couple==2 & retpen > $osp_basic + $osp_depech + $osp_depch *(depchldb-1) & depchldb>0 & newclaim!=1 & sex==1 
		
replace serps = retpen- basic if couple==2 
if ${use_assert} assert basic!=. & serps!=. if couple==2

sort sernum benunit sex
save pensions, replace	
des,s

****************************************************************************
*** MARRIED and LIVING TOGETHER: impute according to pair amounts & char.
****************************************************************************
*	work only with these couples, rather then entire dataset
		use pensions, clear
		sort sernum benunit sex
		gen couple_partn=couple[_n-1] if sex==2 & sernum==sernum[_n-1] & benunit==benunit[_n-1]
		replace couple_partn=couple[_n+1] if sex==1 & sernum==sernum[_n+1] & benunit==benunit[_n+1]
		keep if couple==1 | couple_partn==1
		sort sernum person
		save temp, replace 

*	merge in info on whether in receipt of contributory JSA
			use sernum person benefit var2 using $data/benefits, clear
			keep if benefit==14			// JSA
			isid sernum person
			keep if var2==1|var2==3 // contributory JSA only
			keep sernum person
			sort sernum person
			merge sernum person using temp
			ta _merge
if r(mean)>1 {
			drop if _merge==1			
		gen on_contr_jsa=(_merge==3)
		drop _merge
		
*	gen adult dependant variable
		gen dependant=0 if (sex==1 & age<${SPAm}) |(sex==2 & age<${SPAw})
		replace dependant=1 if dependant==0 & (empstatb>6 & empstatb!=8) & on_contr_jsa!=1 

* 	set data in wide shape (one suffix for the male, 2 suffix for female)
		keep  sernum benunit person couple basic serps retpen depchldb sex dependant age2 impute newclaim
		duplicates report sernum benunit
		sort sernum benunit sex 
		reshape wide person basic serps couple retpen depchldb age2 impute newclaim dependant, i(sernum benunit) j(sex)
		gen sex1=1
		gen sex2=2
		order sernum benunit couple* age* retpen* basic* serps* 
		des

*	cases where man below pension age and woman above=> confirm woman receivs NO addition for him
		count if age21<${SPAm} & retpen2>0
		count if age21<${SPAm} & retpen2> ($osp_basic + $osp_low ) 	/*1 obs*/
				
*	cases where woman below pension age and man above 
		count if age22<${SPAw} & retpen1>0
		count if age22<${SPAw} & retpen1> ($osp_basic +$osp_low ) 	/*5 obs*/

*    define matrix of cases according to partners ages, amounts, etc.
        gen male_basic1=$osp_basic  	
		replace male_basic1=$osp_basic + $osp_depech + $osp_depch *(depchldb1-1) if depchldb1>0 & newclaim1!=1 
		gen male_basic2=male_basic1+ $osp_low  	
  			
*	reset to zero cases receiving retpen but below pension age 
		replace retpen1=0 if retpen1>0 & age21<${SPAm}
		replace retpen2=0 if retpen2>0 & age22<${SPAw}
		if ${use_assert} assert retpen1==0 if age21<${SPAm}
		if ${use_assert} assert retpen2==0 if age22<${SPAw}

*	gen matrix of pairs types for imputation
		gen married_type=0
		replace married_type=1 if retpen1<male_basic1 & age22<${SPAw}  & dependant2==1
		replace married_type=2 if retpen1<male_basic1 & age22<${SPAw} & dependant2==0
		replace married_type=3 if retpen1<male_basic1 & age22>=${SPAw} & retpen2==0
		replace married_type=4 if retpen1<male_basic1 & age22>=${SPAw} & retpen2>0 & retpen2 <= $osp_low 	
		replace married_type=5 if retpen1<male_basic1 & age22>=${SPAw} & retpen2 > $osp_low & retpen2<$osp_low 	
		replace married_type=6 if retpen1<male_basic1 & age22>=${SPAw} & retpen2 >= $osp_low & retpen2< $osp_basic
		replace married_type=7 if retpen1<male_basic1 & age22>=${SPAw} & retpen2 >= $osp_basic	

			replace married_type=8 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22<${SPAw}  & dependant2==1
			replace married_type=9 if retpen1>=male_basic1 & retpen1<=male_basic2  & age22<${SPAw} & dependant2==0
			replace married_type=10 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22>=${SPAw} & retpen2==0
			replace married_type=11 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22>=${SPAw} & retpen2>0 & retpen2 <= $osp_low 	
			replace married_type=12 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22>=${SPAw} & retpen2 > $osp_low & retpen2<$osp_low 	
			replace married_type=13 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22>=${SPAw} & retpen2 >= $osp_low & retpen2<$osp_basic	
			replace married_type=14 if retpen1>=male_basic1 & retpen1<=male_basic2 & age22>=${SPAw} & retpen2 >= $osp_basic	
			
				replace married_type=15 if retpen1>male_basic2 & age22<${SPAw}  & dependant2==1
				replace married_type=16 if retpen1>male_basic2 & age22<${SPAw} & dependant2==0
				replace married_type=17 if retpen1>male_basic2 & age22>=${SPAw} & retpen2==0
				replace married_type=18 if retpen1>male_basic2 & age22>=${SPAw} & retpen2>0 & retpen2 <= $osp_low 	
				replace married_type=19 if retpen1>male_basic2 & age22>=${SPAw} & retpen2 > $osp_low & retpen2<$osp_low 	
				replace married_type=20 if retpen1>male_basic2 & age22>=${SPAw} & retpen2 >= $osp_low & retpen2<$osp_basic	
				replace married_type=21 if retpen1>male_basic2 & age22>=${SPAw} & retpen2 >= $osp_basic

		ta married_type, m
		if ${use_assert} assert married_type!=.
		
		replace basic1=. if basic1>0		/*were positive but inconsisten amount, to be re imputed*/
		replace basic2=. if basic2>0
		replace serps1=. if serps1>0		/*were positive but inconsisten amount, to be re imputed*/
		replace serps2=. if serps2>0


* finally impute

		scalar qm=$osp_basic /($osp_basic +$osp_low )
		scalar qf=$osp_low /($osp_basic +$osp_low )

		replace basic1=retpen1 if married_type==1 |married_type==2 |married_type==8
		replace serps1=0 if married_type==1|married_type==2 |married_type==8
		replace basic2=0 if married_type==1|married_type==2 |married_type==8
		replace serps2=0 if married_type==1|married_type==2 |married_type==8

		replace basic1=retpen1*qm if married_type==3 |married_type==10
		replace serps1=0 if married_type==3 |married_type==10
		replace basic2=retpen1*qf if married_type==3 |married_type==10
		replace serps2=0 if married_type==3 |married_type==10

		replace basic1=retpen1 if married_type==4
		replace serps1=0 if married_type==4
		replace basic2=retpen2 if married_type==4
		replace serps2=0 if married_type==4

/*		replace basic1=retpen1 if married_type==5
		replace serps1=0 if married_type==5
		replace basic2=$osp_low if married_type==5										// State Pension Category B, C or D			
		replace serps2=retpen2-basic2 if married_type==5
*/
		replace basic1=retpen1 if married_type==6
		replace serps1=0 if married_type==6
		replace basic2=retpen2 if married_type==6
		replace serps2=0 if married_type==6

		replace basic1=retpen1 if married_type==7
		replace serps1=0 if married_type==7
		replace basic2=$osp_basic if married_type==7
		replace serps2=retpen2-basic2 if married_type==7

			replace basic1=male_basic1 if married_type==9| married_type==16
			replace serps1=retpen1- basic1 if married_type==9|married_type==16
			replace basic2=0 if married_type==9|married_type==16
			replace serps2=0 if married_type==9|married_type==16

			replace basic1=male_basic1 if married_type==11|married_type==13|married_type==18|married_type==20
			replace serps1=retpen1- basic1  if married_type==11|married_type==13 |married_type==18|married_type==20
			replace basic2=retpen2  if married_type==11|married_type==13 |married_type==18|married_type==20
			replace serps2=0 if married_type==11|married_type==13 |married_type==18|married_type==20
/*
			replace basic1=male_basic1 if married_type==12
			replace serps1=retpen1- basic1 if married_type==12
			replace basic2=$osp_low if married_type==12
			replace serps2=retpen2-basic2 if married_type==12
*/
			replace basic1=male_basic1 if married_type==14
			replace serps1=retpen1- basic1 if married_type==14
			replace basic2=$osp_basic if married_type==14
			replace serps2=retpen2-basic2 if married_type==14

				replace basic1=male_basic2 if married_type==15
				replace serps1=retpen1- basic1 if married_type==15
				replace basic2=0 if married_type==15
				replace serps2=0 if married_type==15
        
   				replace basic1=male_basic1 if married_type==17
				replace serps1=retpen1- basic1 if married_type==17
				replace basic2=$osp_low if married_type==17
				replace serps2=0 if married_type==17
/*        
   				replace basic1=male_basic1 if married_type==19
				replace serps1=retpen1- basic1 if married_type==19
				replace basic2=$osp_low if married_type==19
				replace serps2=retpen2-basic2 if married_type==19
*/
				replace basic1=male_basic1 if married_type==21
				replace serps1=retpen1- basic1 if married_type==21
				replace basic2=$osp_basic if married_type==21
				replace serps2=retpen2-basic2 if married_type==21


		if ${use_assert} assert basic1!=. & basic2!=. & serps1!=. & serps2!=.

*	back to long shape
		keep sernum benunit basic1 basic2 serps1 serps2
		sort sernum benunit 
		reshape long basic serps, i(sernum benunit) j(sex)
		if ${use_assert} assert basic!=. & serps!=.
		rename basic imp1_basic
		rename serps imp1_serps
		sort sernum benunit sex
		merge sernum benunit sex using pensions
		ta _merge
		replace basic=imp1_basic if _merge==3
		replace serps=imp1_serps if _merge==3
		drop _merge
		

	sum basic serps 
/*Account for the new state pension 
 
The new state pension is calculated based solely on the individual's National Insurance contributions,
and any additional amounts for dependents are no longer applicable.
This change was part of the move to simplify the state pension system and make it more straightforward 
and based on individual contributions. Therefore being in couple or not does not matter anymore*/
replace basic=retpen if impute==1 & retpen <= $nsp_full ///
& ((sex==1 & age2>=${SPAm} & age2<${NSPm}) | (sex==2 & age2>=${SPAw} & age2<${NSPw})) 
replace basic=$nsp_full if impute==1 & retpen > $nsp_full ///
& ((sex==1 & age2>=${SPAm} & age2<${NSPm}) | (sex==2 & age2>=${SPAw} & age2<${NSPw})) 
fre basic if impute ==1 & ((sex==1 & age2>=${SPAm} & age2<${NSPm}) | (sex==2 & age2>=${SPAw} & age2<${NSPw})) 

replace serps = retpen- basic if ((sex==1 & age2>=${SPAm} & age2<${NSPm}) | (sex==2 & age2>=${SPAw} & age2<${NSPw})) 
if ${use_assert} assert basic!=. & serps!=. if impute==1 & ((sex==1 & age2>=${SPAm} & age2<${NSPm}) | (sex==2 & age2>=${SPAw} & age2<${NSPw})) 

	sum basic serps 
/*end*/ 

	if ${use_assert} assert basic!=. & serps!=. if retpen>0
	if ${use_assert} assert (age<${SPAm} & sex==1) |(age<${SPAw} & sex==2) if retpen>0 & basic==0 
	if ${use_assert} assert basic>0 if serps>0 & serps!=.
	
*** end: check how many male pensioners after 5 years deferral have no basic (trivial number of cases)
	count if sex==1 & age2>${SPAm}+5 & basic==0	/*1 obs*/
save temp_pens, replace
}

else {
use pensions, clear

	if ${use_assert} assert basic!=. & serps!=. if retpen>0
	if ${use_assert} assert (age<${SPAm} & sex==1) |(age<${SPAw} & sex==2) if retpen>0 & basic==0 
	if ${use_assert} assert basic>0 if serps>0 & serps!=.
	
*** end: check how many male pensioners after 5 years deferral have no basic (trivial number of cases)
	count if sex==1 & age2>${SPAm}+5 & basic==0	/*1 obs*/
	
save temp_pens, replace
}

***************************
*** BASIC/NEW STATE PENSION 
***************************
use temp_pens, clear
	gen boact00=0
	replace boact00=basic*52/12 if basic>0 & basic!=.
	replace boact00=0 if sex==1 & age<${SPAm}
	replace boact00=0 if sex==2 & age<${SPAw}

************************
*** SECOND STATE PENSION
************************
	gen boactcm=0
	replace boactcm=serps*52/12 if serps>0 & serps!=.
	replace boactcm=0 if sex==1 & age<${SPAm}
	replace boactcm=0 if sex==2 & age<${SPAw}

keep sernum person boact00 boactcm 
sort sernum person
save pensions, replace 					/*adults records only*/
des

* http://www.scottishlife.co.uk/scotlife/web/site/BeeHive/BeeLines/BHBLOct07Page14_c.asp
