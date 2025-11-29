***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         07_Income.do
* DESCRIPTION:          Create income variables 
* INPUT FILE:           individual, benunit, job, pension, renter
* OUTPUT FILE:          income
* NEW VARS:
*                       - ypp             Income - Private pension
*                       - yptmp           Income - Private Transfers - Maintenance payments received
*                       - bch             Child Benefit
*                       - bho             Benefit - Housing
*                       - bhoot           Benefit - Discretionary Housing Payment 
*						- bhoro			  Eligible rooms for social renters
*                       - bsa             Benefit - Income Support (includes income-based JSA)
*                       - bsa01           Employment and Support Allowance (income-based ESA)
*                       - bsauc           Benefit - Universal Credit
*                       - bsadi           Benefit - Housing
*                       - bdioa           Attendance allowance
*                       - bdisc           Disability living allowance (self care)
*                       - bdimb           Disability living allowance (mobility)
*                       - bdiscwa         Personal indipendence payment (daily living allowance)
*                       - bdimbwa         Personal indipendence payment (mobility allowance)
*                       - bdict           Benefit - Incapacity benefit/Employment and Support Allowance (contributory)
*                       - bdict01         Benefit - Incapacity benefit
*                       - bdict02         Benefit - Employment and Support Allowance (contributory/IB)
*                       - bdiwi           Benefit - Industrial injuries benefit
*                       - bcrdi           Benefit - Carer's allowance
*                       - bdisv           Benefit - Severe disablement allowance
*                       - bhlwk           Benefit - Statutory sick pay
*                       - buntr           Benefit - Training allowance
*                       - bunct           Benefit - Unemployment benefit (contributory jobseeker's allowance)
*                       - boawr           Benefit - Armed Forces Compensation Scheme
*                       - bedes           Benefit - Student payments
*                       - bedsl           Benefit - Student loan
*                       - bmana           Benefit - Maternity Benefit
*                       - bmaer           Benefit - Statutory Maternity Pay
*                       - boamt           Benefit - Pension credit
*                       - bfamt           Benefit - Child tax credit
*                       - bot             Benefit - Regular primary income (Other NI or State benefit)
*                       - bwkmt           Benefit - Working tax credit
*                       - bsuwd           Benefit - Widow`s pension
*                       - boaht           Benefit - Winter Fuel Allowance
*                       - bmu             Benefit - Council Tax Reduction
*                       - ypr             Income - Property
*                       - yprtx           Income - Property (taxable)
*                       - yprnt           Income - Property (non-taxable)
*                       - tmu01           Tax - Council tax (based on average amount by region, band and household type)
*                       - tmu02           Tax - Council tax (based on reported CT Amount; for missing values based on average amount by region, band and hh type)
*                       - tmu03           Tax - Council Tax (based on average amount by band at local authoriry level)    
*                       - tmu04           Tax - Council tax (based on reported CT Amount; for missing values based on average amount by band at local authority level)
*                       - yptot           Income - Private transfers
*                       - yds             Original Disposable Income
*                       - yls             Income - Lump-sum income
*                       - lmcee           Flag: whether on CJRS
*                       - bwkmcee         Percentage of earnings received through CJRS 
*                       - lmcse           Flag: Whether on SEISS
*                       - bwkmcse         Total amount of SEISS received - changed to monthly in 17_UKDatabase.do
* LAST UPDATE:          27/11/2025
***************************************************************************************
cap log close 
log using "${log}/07_Income.log", replace

use sernum benunit person sex adult age80 age /*ben3q2 ben3q6*/ wageben5 penben1 sspadj smpadj sppadj sapadj/*
 hbothamt hbothbu // hboth* have been moved from individual and placed into benunit FRS 2009-10
*/ hrpid royyr1 mntamt1 mntamt2 mntus1 mntus2 mntusam1 mntusam2 marital /*
*/ /*adema*/ eduma chema /*ademaamt*/ edumaamt chemaamt grant access accssamt grtdir1 grtdir2 topupl tuborr /*
*/ redany redamt allow1 allow3 allow4 allpay1 allpay3 allpay4 apamt apdamt pareamt /*
*/ nindinc chincdv convbl cvpay rstrct /*injlong incdur*/ injwk injwks injyear /* 
*/ using individual, clear //DP: added COVID-19 variables: chgcovid furlough - removed in Jan 2022//

	gen age2=age80 if adult==1
	replace age2=age if adult==0
	drop age age80
sort sernum benunit person
save temp, replace
* get HB information from benunit file
* HB information from renter file added below at "housing benefit" section
use sernum benunit adultb depchldb hbothamt hbothbu hbothmn hbothwk hbothyr hbotwait /* hboth* have been moved from individual and placed into benunit FRS 2009-10   
  */ using $data/benunit,clear 
	sort sernum benunit
	merge sernum benunit using temp
	assert _merge==3
	drop _merge
	erase temp.dta
sort sernum benunit person
save temp, replace

* get SSP info from job file
use sernum benunit person uincpay1 inclpay1 /*furlo2  furlpay furlpay2 seissgr seissnum seisstot */ using $data/job, clear //DP: COVID-19 variables: furlo2  furlpay furlpay2 seissgr seissnum seisstot - removed in Jan 2022//
	sort sernum benunit person
	by sernum benunit person: ge id=_n
	ta id		// there are more than one obs per person (one obs for each job)
	by sernum benunit person: ge idmax=_N
	foreach var in uincpay1 inclpay1 /*furlo2  furlpay furlpay2 seissgr seissnum seisstot*/ {
		forv i=1/2 {
			by sernum benunit person: replace `var'=`var'[_n+`i'] if id==1 & idmax>`i' & `var'==-1 & `var'[_n+`i']!=-1
		}
	}
	keep if id==1
	sort sernum benunit person	
	merge sernum benunit person using temp
	assert _merge==3 | _merge==2
	drop _merge id idmax
	erase temp.dta
sort sernum person
save income, replace


*** define a program for monthlyfying and including state transfers data in individual level dataset
	program drop _all

	program define minclude
		replace benamt =benamt *(52/12)		// average monthly
		keep sernum person benamt 
		sort sernum person
		merge sernum person using income
		ta _merge
		replace benamt =0 if _merge==2
		drop _merge
	end program
*** 
*******************************
* boaht - Winter Fuel Payment

* benefit = Benefit type (options 1 - 111)
* option 62 = Winter fuel payment 
*******************************
use income, clear
	gen a${SPAw}=age2>=${SPAw}		// adj with rising pension age 
	by sernum, sort: egen na${SPAw}=total(a${SPAw})
	sort sernum person
	save income, replace
use sernum person benefit benamt using $data/benefits,clear

	de benefit benamt
	keep if benefit==62 
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt						/*AMOUNT IS ANNUAL*/
		replace benamt =benamt/12
		keep sernum person benamt 
		sort sernum person
		merge sernum person using income
		ta _merge
		replace benamt =0 if _merge==2
		drop _merge
	by sernum, sort: egen wfa=total(benamt)
	if ${use_assert} assert na${SPAw}==na${SPAw}[_n-1] if sernum==sernum[_n-1]
	if ${use_assert} assert wfa ==wfa[_n-1] if sernum==sernum[_n-1]
	gen boaht= wfa/na${SPAw} /*assign to those aged above SPA in hh, splitting equally*/
 	replace boaht=0 if age2<${SPAw}
	if ${use_assert} assert age2>=${SPAw} if boaht>0
	drop wfa a${SPAw} na${SPAw} benamt
label var boaht "Winter Fuel Allowance - monthly amount"
sort sernum person
save income, replace


***************************
* yds - disposable income

* nindinc - Adult - Net Income
* chincdv - Child - Total income
***************************
use income, clear
	de nindinc chincdv
	su nindinc chincdv
	replace nindinc=0 if (nindinc<0 & nindinc>-10) | nindinc==.
	gen yds=nindinc if adult==1
	replace yds=chincdv if adult==0 & chincdv!=.
	replace yds=yds*52/12
	drop nindinc chincdv
	inspect yds
sort sernum person
save income, replace

*************************************************************
* yptot - private transfers

* benefit=31 Trade Union sick/strike pay
* benefit=32 Friendly Society Benefits
* benefit=33 Private sickness scheme benefits
* benefit=34 Accident insurance scheme benefits
* benefit=35 Hospital savings scheme benefits
* pres - Whether receiving benefit at present
* apamt - Amount received from absent partner
* apdamt - Amount from absent partner paid directly
* pareamt - Parental contribution (students)
* allpay 1 - Amount of allowance: Friend/Relative
* allpay 3 - Amount of allowance:LA/SS (foster child)
* allpay 4 - Amount of allowance:LA/SS (adoption)
*************************************************************
use sernum person benefit benamt pres using $data/benefits,clear
	keep if (benefit==31|benefit==32|benefit==33|benefit==34|benefit==35) & pres==1
	//isid sernum person
	duplicates tag sernum person, generate(dup_tag) //one person getting two types of benefits so need to collapse the data to merge correctly 
    collapse (sum) benamt, by(sernum person)
	isid sernum person

	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	de apamt apdamt pareamt allpay* allow*
	rename benamt yptot
	replace yptot=yptot+apamt*(52/12)  if apamt>0 & apamt!=.
	replace yptot=yptot+apdamt*(52/12)  if apdamt>0 & apdamt!=.
	replace yptot=yptot+pareamt*(52/12)  if pareamt>0 & pareamt!=.
	replace yptot= yptot + allpay3 *(52/12) if allow3==1
	replace yptot= yptot + allpay4 *(52/12) if allow4==1
	replace yptot=yptot+ allpay1*(52/12) if allow1==1
inspect yptot
	drop apamt apdamt pareamt allpay* allow*
sort sernum person
save income, replace 	


**********************************************************
* ypp - Private pension (non-state, includes occupational)		// The part of occupational pension entering here is employer pensions  

* penpay - Amount of last payment from pension
* penoth - Whether any other deductions from PENPAY
* ptamt - Amount of tax deducted at source
* ptinc - Whether PENPAY before/after tax (1 before, 2 after)
* poamt - Amount of other deduction from PENPAY
* poinc - Whether PENPAY before/after other deduction (1 before, 2 after)
**********************************************************		//               while the part going into boact00 is state earnings related pension. 
                                                                //               **NOTE** that from April 2016 State Pension changes => this variables need revisiting!
use $data/pension, clear
	de penpay ptamt ptinc poinc penoth poamt
	su penpay ptamt ptinc poinc penoth poamt
	gen ypp=0   
	count if !(penpay >0 & penpay!=.) // missing values
	replace ypp=ypp + penpay if penpay>0 & penpay!=. 			// add only positive non-missing
	replace ypp=ypp + ptamt if ptinc==2	& ptamt>0 & ptamt!=. // add tax paid to make up gross pension only for those reporting pension value after tax	
	replace ypp=ypp + poamt if (poinc==2 | penoth==1) & poamt>0 & poamt!=.
	collapse (sum) ypp, by (sernum person) 
	sort sernum person
		merge sernum person using income
	replace ypp=0 if _merge==2
	inspect ypp
	drop _merge
	replace ypp=ypp*(52/12)
sort sernum person
save income, replace 

*******************************
* yls - Lump sum income

* redamt - Amount of redundancy payment
* redany - Whether received any redundancy payments (1 yes, 2 no)
*******************************
	de redamt redany
	if ${use_assert} assert redamt>0 & redamt!=. if redany==1 
	gen yls=0
	replace yls=yls+redamt if redany==1 
	replace yls=yls/12
sort sernum person
save income, replace 

*******************************
*  tmu01 tmu02 tmu03 tmu04 - Council Tax

* ctband - Council Tax band	
*   1	Band A
*	2	Band B
*	3	Band C
*	4	Band D
*	5	Band E
*	6	Band F
*	7	Band G
*	8	Band H
*	9	Band I
*	10	Household not valued separately
* ctannual - Annual CT amount after discounts/reduction
* gvtregn - Region in UK (ONS standard geographies)	
*   112000001	North East
*	112000002	North West
*	112000003	Yorks and the Humber
*	112000004	East Midlands
*	112000005	West Midlands
*	112000006	East of England
*	112000007	London
*	112000008	South East
*	112000009	South West
*	299999999	Scotland
*	399999999	Wales
*	499999999	Northern Ireland
* gvtregno - Region in UK (original FRS codes)	
*   1	North East
*	2	North West
*	4	Yorks and the Humber
*	5	East Midlands
*	6	West Midlands
*	7	East of England
*	8	London
*	9	South East
*	10	South West
*	11	Wales
*	12	Scotland
*	13	Northern Ireland
* ctamtbnd -- Annual council tax payment bands for band D at local authority level   
*       0                                                
*       1  Under 300 a year                            
*       2  300 and less than 600                      
*       3  600 and less than 900                       
*       4  900 and less than 1200                    
*       5  1200 and less than 1500                    
*       6  1500 and less than 1800                    
*       7  1800 and less than 2100                  
*       8  2100 and less than 2400                   
*       9  2400 and less than 2700                   
*       10 2700 and less than 3000                  
*       11 Above 3000                                 
*       12 Household not valued separately or in NI    
                                                 

*******************************
* for NI, set to zero. (ctband==-1)
use sernum gvtregn* /*hhsize*/ adulth depchldh ctband ctannual ctamtbnd using $data/househol,clear 

de adulth depchldh	
su adulth depchldh
ge hhsize = adulth+depchldh
su hhsize
count if hhsize==.
ta ctband, m
replace ctannual=. if ctannual<0
gen band=ctband

gen singlehh=(hhsize==1)

	egen type = group(band gvtregn singlehh) 
	sort type
	replace type=0 if ctband==-1 | ctband ==10 | ctband==. 	/*n.i. or not separately valued*/
	by type, sort: egen av_cta=mean(ctannual)
	list type ctband gvtregn singlehh if type!=0 &  av_cta==.
/*
	type	ctband	gvtregn	singlehh	
					
118	Band F	East Midland	1	==> 117 0 - to add discount 
134	Band G	North East	    1   ==> 133 0 - to add discount
156	Band H	North West	    0   ==> 135 0 
157	Band H	Yorks and th	0	==> 137 0 
158	Band H	Yorks and th	1	==> 138 1 
159	Band H	East Midland	0	==> 139 0 
161	Band H	West Midland	1	==> 160 0 - to add discount 
162	Band H	East of Engl	0	==> 143 0 
166	Band H	South East	    1	==> 165 0 - to add discount 
168	Band H	Scotland	    0	==> 151 0 
169	Band H	Scotland	    1	==> 152 1 
171	Band H	Wales	        1	==> 170 0 - to add discount 
*/				
		
// TO DO: impute missing values of av_cta, using non-missing values of the same region, different household type and possibly different band //

	tab type ctband if av_cta!=.
	tab type ctband if av_cta==. // need to impute missing values of av_cta
		
	tab type ctband if gvtregno==1 // North East 	
	tab type ctband if gvtregno==2 // North West 	
	tab type ctband if gvtregno==4 // Yorks and the Humber  stop 
	tab type ctband if gvtregno==5 // East Midlands  
	tab type ctband if gvtregno==6 // West Midlands	
    tab type ctband if gvtregno==7 // East of England	
	tab type ctband if gvtregno==9 // South East 	
	tab type ctband if gvtregno==10 // South West 
	tab type ctband if gvtregno==12 // Scotland  
	tab type ctband if gvtregno==11 // Wales	
	

	gen type2=type
	replace type2=117 if type==118
	replace type2=133 if type==134
	replace type2=135 if type==156	
	replace type2=137 if type==157	
	replace type2=138 if type==158
	replace type2=139 if type==159
	replace type2=160 if type==161
	replace type2=143 if type==162	
	replace type2=165 if type==166
	replace type2=151 if type==168
	replace type2=152 if type==169
	replace type2=170 if type==171	

	tab type2 ctband if av_cta!=.
	tab type2 ctband if av_cta==.
		
	sort type2
		by type2, sort: egen av2_cta=min(av_cta)
		tab type2 ctband if av2_cta==.
		replace av2_cta=av_cta if type==type2 & av_cta!=av2_cta & av_cta!=.
		
		if ${use_assert} assert av_cta==av2_cta if type==type2 
		if ${use_assert} assert av_cta==av2_cta if type==type2 & av_cta!=.
		if ${use_assert} assert av_cta>av2_cta if type!=type2 
		
		replace av2_cta=av_cta if av_cta>av2_cta & av_cta!=.
		if ${use_assert} assert av_cta>=av2_cta if type!=type2 & av_cta!=.

	/*TO DO: when imputaion for single person hh was based on multiple memebers hh, 
	apply the 25% discount to average, or the other way around*/
	replace av2_cta=av2_cta*0.75 if type==118| type==134 | type==161 | type==166 | type==171 
	
	
	*Tax - Council tax (based on average amount by region, band and household type)
	gen tmu01=.
	replace tmu01=0 if ctband==-1 | ctband==.		/*n.ireland*/
	replace tmu01=0 if ctband==10		/*not separately valued*/
	replace tmu01=av2_cta/12 if tmu01==. 	/*average imputed also to those with non-missing ctannual*/

	*Tax - Council tax (based on reported Council Tax Amount; for missing values based on average amount by region, band and hh type)
	gen tmu02=.
	replace tmu02=0 if ctband==-1 | ctband==.		/*n.ireland*/
	replace tmu02=0 if ctband==10			/*not separately valued*/
	replace tmu02=ctannual/12 if tmu02==. & ctannual>0 & ctannual!=.
	replace tmu02=av2_cta/12 if tmu02==. 	/*average imputed only to those missing ctannual*/

		
* impute band rates using information on local authority rates for band D 
gen ctband_d = 0 if ctamtbnd==0  | ctamtbnd==12 //Household not valued separately or in NI
replace ctband_d = 150 if ctamtbnd==1
replace ctband_d = 450 if ctamtbnd==2
replace ctband_d = 750 if ctamtbnd==3
replace ctband_d = 1050 if ctamtbnd==4
replace ctband_d = 1350 if ctamtbnd==5
replace ctband_d = 1650 if ctamtbnd==6
replace ctband_d = 1950 if ctamtbnd==7
replace ctband_d = 2250 if ctamtbnd==8
replace ctband_d = 2550 if ctamtbnd==9
replace ctband_d = 2850 if ctamtbnd==10
replace ctband_d = 3000 if ctamtbnd==11
tab2 ctband_d gvtregno, m // 1,844 zero values are for NI 

//generate bans rates for other bands using band d
/*The ratios for council tax bands do not change from year to year. 
England: Fixed ratios since the introduction of council tax, ranging from Band A (6/9 of Band D) to Band H (18/9 of Band D).
Scotland: Adjusted ratios since 2017 to charge more on higher-value properties, ranging from Band A (240/360 of Band D) to Band H (882/360 of Band D).
Wales: Ratios similar to England with an additional Band I, ranging from Band A (6/9 of Band D) to Band I (21/9 of Band D).
*/
gen ctband_a = ctband_d * 0.67 if gvtregno<=10 //england 
replace ctband_a = ctband_d * 0.67 if gvtregno==11 //wales  
replace ctband_a = ctband_d * 0.67 if gvtregno==12 //scotland 

gen ctband_b = ctband_d * 0.78 if gvtregno<=10 //england 
replace ctband_b = ctband_d * 0.78 if gvtregno==11 //wales  
replace ctband_b = ctband_d * 0.78 if gvtregno==12 //scotland 

gen ctband_c = ctband_d * 0.89 if gvtregno<=10 //england 
replace ctband_c = ctband_d * 0.89 if gvtregno==11 //wales  
replace ctband_c = ctband_d * 0.89 if gvtregno==12 //scotland 

gen ctband_e = ctband_d * 1.22 if gvtregno<=10 //england 
replace ctband_e = ctband_d * 1.22 if gvtregno==11 //wales  
replace ctband_e = ctband_d * 1.31 if gvtregno==12 //scotland 

gen ctband_f = ctband_d * 1.44 if gvtregno<=10 //england 
replace ctband_f = ctband_d * 1.44 if gvtregno==11 //wales  
replace ctband_f = ctband_d * 1.63 if gvtregno==12 //scotland 

gen ctband_g = ctband_d * 1.67 if gvtregno<=10 //england 
replace ctband_g = ctband_d * 1.67 if gvtregno==11 //wales  
replace ctband_g = ctband_d * 1.96 if gvtregno==12 //scotland 

gen ctband_h = ctband_d * 2 if gvtregno<=10 //england 
replace ctband_h = ctband_d * 2 if gvtregno==11 //wales  
replace ctband_h = ctband_d * 2.45 if gvtregno==12 //scotland 

gen ctband_i = ctband_d * 2.33 if gvtregno==11 //wales  

	*Tax - Council tax (based on average amount by band at local authority level)
	gen tmu03=.
	replace tmu03=0 if ctband_d==0 		/*n.ireland or not separately valued*/
	replace tmu03=ctband_a/12 if tmu03==. & ctband==1
	replace tmu03=ctband_b/12 if tmu03==. & ctband==2 	
    replace tmu03=ctband_c/12 if tmu03==. & ctband==3 	
	replace tmu03=ctband_d/12 if tmu03==. & ctband==4 
	replace tmu03=ctband_e/12 if tmu03==. & ctband==5
	replace tmu03=ctband_f/12 if tmu03==. & ctband==6
	replace tmu03=ctband_g/12 if tmu03==. & ctband==7
	replace tmu03=ctband_h/12 if tmu03==. & ctband==8
	replace tmu03=ctband_i/12 if tmu03==. & ctband==9
	fre tmu03 

	*Tax - Council tax (based on reported Council Tax Amount; for missing values based on average by band at local authority level)
	gen tmu04=.
	replace tmu04=0 if ctband==-1 | ctband==.		/*n.ireland*/
	replace tmu04=0 if ctband==10			/*not separately valued*/
	replace tmu04=ctannual/12 if tmu04==. & ctannual>0 & ctannual!=.
	replace tmu04=tmu03 if tmu04==0 | tmu04==.	/*average by band imputed only to those missing ctannual*/
	replace tmu04=tmu02 if tmu04==0 | tmu04==.	/*average by band*/
	fre tmu04 

	inspect tmu01 tmu02 tmu03 tmu04 
	keep sernum tmu*
	sort sernum
	merge m:m sernum using income
	ta _merge
	drop _merge
	
sort sernum person
save income, replace


*******************************
* bedes - Student payments 

* edumaamt - Amount of Adult EMA earnings
* eduma - Whether Adult EMA earnings (1 yes, 2 no)
* chemaamt - Amount of Child EMA Earnings
* accssamt - Amount : Access Fund
* grtdir1 - Amount of 1st award paid direct
* grtdir2 - Amount of 2nd award paid direct
*******************************
	use income, clear
	count if !(edumaamt>0 & edumaamt!=.) & eduma==1	// missing amount
		su edumaamt if edumaamt>0 & edumaamt!=. & eduma==1
		replace edumaamt=r(mean) if edumaamt==-1 & eduma==1		// impute using average amount
	if ${use_assert} assert chemaamt>0 & chemaamt!=. if chema==1
		gen ema=0		// educational maintenance allowance
	replace ema= ema + edumaamt if eduma==1 & edumaamt>0 & edumaamt!=.
	replace ema= ema + chemaamt if chema==1
		gen accfund=0   // access fund
	replace accfund=accfund+accssamt if accssamt >0 & accssamt !=.
		gen grnt=0
	replace grnt= grnt+ grtdir1 if grtdir1>0 & grtdir1!=.  
	replace grnt= grnt+ grtdir2 if grtdir2>0 & grtdir2!=.
		gen bedes =((ema+accfund)*(52/12)) + grnt/12
	label var bedes "Student payments"
		drop ema accfund grnt eduma chema edumaamt chemaamt grtdir1 grtdir2 accssamt 
sort sernum person
save income, replace 

*******************************
* bedsl - Student loan 

* tuborr - Student loan: amount borrowed
* topupl - Whether eligible for Student loan (1 yes, 2 no)
*******************************
	de tuborr topupl
	count if tuborr<0 & topupl==1			// 1 case
	replace tuborr=0 if tuborr==-1 & topupl==1
	if ${use_assert} assert tuborr > = 0 & tuborr!=. if topupl==1
		gen bedsl = 0
	replace bedsl = bedsl + tuborr if topupl==1
	replace bedsl =bedsl/12
		label var bedsl "Student loan"
	drop tuborr topupl
sort sernum person
save income, replace 

*******************************
*  bdioa - Attendance allowance

* benefit = 12
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==12 					
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt			
minclude
	ta age2 if benamt <.					/* will recode AA<65 years old as DLA cases - see below*/
	rename benamt bdioa
	label var bdioa "Attendance allowance - monthly amount"
	sort sernum person
	save income, replace

**************************************************
*  bdisc - Disability living allowance (self care)

* benefit = 1 
**************************************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==1 | benefit==121 //121=Child Disability Payment (Care) 
	collapse (sum) benamt, by(sernum person)
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
*** [TO DO: imputation!] 
		replace benamt= $dlac_l if benamt==$dlac_l *2 // paid forthnightly but we want the weekly amount
		replace benamt= $dlac_m if benamt==$dlac_m *2		
		replace benamt= $dlac_h if benamt>=$dlac_h *2 // recode unregular values to the most close valid value 
	ta benamt
minclude
	rename benamt bdisc 
	label var bdisc "DLA care - monthly amount"
	sort sernum person
	save income, replace



*******************************
*  bdimb - Disability living allowance (mobility)

* benefit = 2 
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==2 | benefit==122 //122= Child Disability Payment (Mobility) 
	collapse (sum) benamt, by(sernum person)
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt	
		 
*** [to do: imputation!] 	
		replace benamt = $dlam_l if benamt== $dlam_l *2
		replace benamt = $dlam_h if benamt== $dlam_h *2
	ta benamt
minclude
	*** RECODE to correct DLAm or DLAc amounts	
		replace bdisc = $dlac_h *52/12 if benamt == $dlac_h *52/12 & bdisc==0
		replace benamt = 0 if benamt == $dlac_h *52/12 & bdisc== $dlac_h *52/12
		ta benamt
	list benamt bdisc bdioa if benamt == $dlac_m * (52/12)	
		su bdisc benamt if bdioa == $dlac_l * 52/12
		replace bdisc = $dlac_l *52/12 if bdioa==$dlac_l *52/12 & bdisc==0
		replace bdioa = 0 if bdioa==$dlac_l *52/12 & bdisc==$dlac_l *52/12
		replace bdisc = $dlac_m *(52/12) if bdisc==0 & benamt == $dlac_m *(52/12)		/*HAS REPORTED MOB WHEN IT'S CARE*/
		replace benamt = 0 if benamt == $dlac_m *(52/12) & bdisc == $dlac_m*(52/12) 
		replace benamt= $dlam_h *(52/12) if benamt>( $dlam_h *(52/12)) 
	ta benamt
	rename benamt bdimb 
	label var bdimb "DLA mob - monthly amount"

	
**********************		AA-DLA_CARE-DLA_MOB consistency checks 

*** RECODE AA as DLAselfcare if received by those aged below 65
 		if ${use_assert} assert bdisc==0 if age2<${SPAm} & bdioa >0
		replace bdisc=bdioa  if age2<${SPAm} & bdioa >0
		replace bdioa=0  if age2<${SPAm} & bdioa >0
*** RECODE to correct DLAm or DLAc amounts	
	list bdimb bdisc bdioa if bdimb == $dlam_h *(52/12)	
		replace bdisc = $dlac_m *(52/12) if bdisc==0 & bdimb == $dlac_m *(52/12) /*HAS REPORTED MOB WHEN IT'S CARE*/
		replace bdimb = 0 if bdimb == $dlac_m *(52/12) & bdisc == $dlac_m *(52/12) 
		replace bdimb = $dlam_h *(52/12) if bdimb == 0 & bdisc== $dlam_h *(52/12)				/*CORRECT MOB RATE*/
		replace bdisc = 0 if bdimb ==  $dlam_h *(52/12) & bdisc== $dlam_h *(52/12)
	list bdimb bdisc bdioa if bdimb > $dlam_h *(52/12)  
		replace bdisc= $dlac_h *(52/12) if bdisc==0 & bdimb== $dlac_h *(52/12)  			/*HAS REPORTED MOB WHEN IT'S CARE*/
		replace bdimb=0 if bdimb==$dlac_h *(52/12) &  bdisc==$dlac_h *(52/12) 

*		replace bdisc=$dlac_h *(52/12) if bdimb==$dlam_h *(52/12) & bdisc==$dlac_l *(52/12) 	/*INVERT MOB AND CARE RATES*/
*		replace bdimb=$dlam_l *(52/12) if bdimb==$dlam_h *(52/12) & bdisc==$dlac_h *(52/12) 

***************************	
	sort sernum person
	save income, replace

**************************************************
*  bdiscwa - Personal independence payment (daily living allowance)	

* new from 2014/15
* benefit = 96					
**************************************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==96 |  benefit==117 //117= ADP (Daily Living)
	collapse (sum) benamt, by(sernum person)
	isid sernum person  
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bdiscwa 
	label var bdiscwa "PIP living - monthly amount"
	sort sernum person
	save income, replace

**************************************************
*  bdimbwa - Personal independence payment (mobility allowance)  

* new from 2014/15
* benefit = 97	                         
**************************************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==97 | benefit==118 //118 = ADP (Mobility) 
	collapse (sum) benamt, by(sernum person)
	isid sernum person 
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bdimbwa 
	label var bdimbwa "PIP mob - monthly amount"
	sort sernum person
	save income, replace		

/*Note: in the original FRS all disablity benefits are assimged to individuals aged 16+ only, meaning all child disability benefits are assigned to parent 	
tab2 age2 bdisc
tab2 age2 bdimb
tab2 age2 bdiscwa	
tab2 age2 bdimbwa
*/  


*********************************************************
*  bsa - Income Support (includes income-based JSA)

* benefit = 19 - Income Support
* benefit = 14 - Jobseeker's Allowance
* 	var2 = 2 - income-based
* 	var2 = 4 - income-based (imputed)
*********************************************************
use sernum person benefit benamt var2 using $data/benefits,clear
keep if benefit==19 | (benefit==14 & ( var2==2| var2==4))  // IS and I-JSA
ta benefit
	isid sernum person			/* checked same person receives one or the other */
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bsa 
	label var bsa "Income Support and ibJSA - monthly amount"
	gen IStoPC=(bsa>0 & age>=${SPAm}) /* if cases exist, later recoding from IS to PC*/
	tab IStoPC
	sort sernum person
	save income, replace
	
*******************************
*  bsa01 - Employment and Support Allowance (income-based ESA)	

* benefit = 16
* 	var2 = 2 - income-based
* 	var2 = 4 - income-based (imputed)
*******************************
use sernum person benefit benamt var2 using $data/benefits,clear

keep if (benefit==16 & ( var2==2| var2==4))  // I-ESA
ta benefit
	isid sernum person			/* checked same person receives one or the other */
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bsa01 
	label var bsa01 "Employment and  Support Allowance ibESA - monthly amount"
	gen ESAtoPC=(bsa01>0 & age>=${SPAm}) /* if cases exist, later recoding from ESA to PC*/
	tab ESAtoPC
	sort sernum person
	save income, replace	
	
*******************************
*  bsauc - Universal Credit		

* benefit = 95
*******************************
use sernum person benefit benamt using $data/benefits,clear
keep if benefit==95
ta benefit
	isid sernum person			/* checked same person receives one or the other */
	if ${use_assert} assert benamt>=0 & benamt!=.
	ta benamt
minclude
	rename benamt bsauc 
	label var bsauc "Universal Credit - monthly amount"
	gen UCtoPC=(bsauc>0 & age>=${SPAm}) /* if cases exist, later recoding from UC to PC*/
	tab UCtoPC
	sort sernum person
	save income, replace	

*******************************
*  boamt - Pension credit

* benefit = 4
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==4
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt boamt 
	label var boamt "Pension Credit - monthly amount"
	count if age<${SPAw} & boamt>0		// people report PC but are under pension age -> recode to IS
	gen PCtoIS=(boamt>0 & age<${SPAw})  /*although this may be possible, below recoded to IS */
* Consistency recoding:
	replace boamt=bsa if IStoPC==1	/*recode as PC cases of IS above SPA*/
	replace bsa=0 if IStoPC==1
	replace boamt=bsa01 if ESAtoPC==1	/*recode as PC cases of ESA above SPA*/  
	replace bsa01=0 if ESAtoPC==1			
	replace boamt=bsauc if UCtoPC==1	
	replace bsauc=0 if UCtoPC==1
	drop IStoPC ESAtoPC UCtoPC
	replace bsa=boamt if PCtoIS==1  /*recode as IS cases of PC below SPA*/
	replace boamt=0 if PCtoIS==1
	drop PCtoIS

	replace bsa=0 if bsa01>0
	if ${use_assert} assert bsa==0 if bsa01>0				// nobody claiming both IS-IbJSA and IrESA
	count if bsauc!=0 & (bsa>0 | bsa01>0)		// receiving both UC and IS/JSA; it could be that they have been transferred to UC within the fiscal year
	if ${use_assert} assert age>=${SPAw} if boamt>0	
	sort sernum person
	save income, replace
	sort sernum benunit person  
	save temp_income, replace   

****************************************************************************
*  bdict - Incapacity benefit/Employment and Support Allowance (contributory)

* benefit = 17 - IB
* benefit = 16 - contributory ESA
* 	var2 = 1 - contributory
*	var2 = 3 - contributed (imputedanswer)
* benefit = 5 - Retirement Pension
****************************************************************************
	use sernum benunit person benefit benamt numweeks  var2 using $data/benefits, clear //numyears dropped in 2021/22
	sort sernum benunit person
	merge m:1 sernum benunit person using temp_income
	assert _merge!=1
	keep sernum benunit person benefit benamt numweeks var2 marital sex age2 injwks injyear rstrct

	fre var2 if benefit==16 
	/*includes the new employment & support allowance; cases of RP to non wid. below pension age */	
	keep if benefit==17 | ///  IB - no cases 
		(benefit==16 & (var2==1 | var2==3)) /* C-ESA (contributory part) */
		/*| 	(benefit==5 & marital!=4 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw})))	// RP: sex=2 was sex=1!*/
	drop if benamt==0	
	isid sernum benunit person benefit	
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
	ta benamt if benefit==17	
	ta benamt if benefit==16	
	ta benamt if benefit==5		
* check multiple obs (ppl receiving more than one benefit)
	sort sernum benunit person
	egen mobs=count(benamt), by (sernum benunit person)
	ta mobs		// receiving more two benefit (ESA and IB)
	list if mobs>1
	egen IBplusESA=sum(benamt), by(sernum benunit person)
	replace benamt=IBplusESA if mobs>1
	by sernum benunit: drop if _n==2 & mobs>1		// drop second obs
	isid sernum person				
	sort sernum person
minclude
	rename benamt bdict
	label var bdict "Incapacity Benefit and Employment and Support Allowance (contributory) - monthly amount"

*** gen max possible amount, assuming long term IB for those below pension age
*** for those over pension age, long term ib not available, so assume higher short term rate
*** for long term age addition purposes, allow for higher age, so assume first day of incapacity was before 35
	gen single=(adultb==1)
	replace single=0 if marital==1 | depchldb>0	/* for calc. maximum, will allow 1 dep adult if married or have children*/
									/*(since an adult addition is given also for children`s carer). */
	gen extraadult=(single==0)
	gen haschi=(depchldb>0)
	gen maxib=0
	replace maxib= $ib_sthr_uspa + $ib_agehr + $ib_depad_uspa *extraadult + ///
	$ib_depech *haschi + $ib_depch *(max(0,depchldb-1))  if ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))       // under SPA    
	
	replace maxib= $ib_sthr_ospa + $ib_depad_ospa *extraadult + ///
	$ib_depech *haschi + $ib_depch *(max(0,depchldb-1)) if ((sex==1 & age2>=${SPAm})|(sex==2 & age2>=${SPAw}))       // over SPA                                               
	replace maxib=maxib*52/12
	ta maxib,m 
	capture drop single extraadult haschi
	compare bdict maxib		
	
	// DP: 59 cases report more that they should get
	gen excess_ib=max(0, bdict- maxib)
	replace bdict=maxib if excess_ib>0 & bsa==0		// DP 59 obs /*recode bdict to max possible amount if not on income support*/
	ge bsa_ib=excess_ib if excess_ib>0 & bsa==0		// overreported IB is IS
	su bsa_ib
	replace bsa_ib=0 if bsa_ib==.
	drop excess_ib

sort sernum person
save income, replace

****************************************************************************
* bdict01 - Incapacity Benefit		// distinguish IB-Ir-JSA from Ir-ESA

* injyear - Unable to work for more than a year due to injury/illness/di (1 yes, 2 no)
* injweeks - How many weeks unable to work due to injury/illness/disabili
****************************************************************************
	use sernum person benefit benamt numweeks  using $data/benefits, clear //numyears dropped in 2021/22
	sort sernum person
	merge m:1 sernum person using income
	assert _merge!=1
	
	keep sernum person benefit benamt marital sex age2 rstrct /*injlong incdur*/ injwk injwks injyear
	keep if benefit==17 /*| (benefit==5 & marital!=4 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))) */ // IB or Retirement Pension
	drop if benamt==0
	
	isid sernum person benefit		
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bdict01	
	label var bdict01 "Incapacity Benefit - monthly amount"
	
	*Note: No obs reporting IB so the following imputation is unnecessary and coded out 
 /*	
	ge ib=bdict01
	
** Using the information in:
** rstrct - restricted ability to work because of illness/injury/disability
** injlong - lenght of time unable to work 	                                     05/09/2019: not available from 2017/18
** incdur - year stopped working if more than 1 year-> use injwks or injyear	 05/09/2019: not available from 2017/18
** injwk - how many hrs per week could/are able to work		
** injwks - how many weeks uneable to work due to injury/illness/disability
** injyear - unable to work for more than a year due to injury/illness/disability
** uincpay1 - usual pay includes Statutory Sick Pay
** inclpay1 - last pay includes Statutory Sick Pay 
*** gen max possible amount, assuming long term IB for those below pension age
*** for those over pension age, long tem ib not available, so assume higher short term rate
*** for long term age addition purposes, allow for higher age, so assume first day of incapacity was before 35
	gen single=(adultb==1)
	replace single=0 if marital==1 | depchldb>0	/* for calc. maximum, will allow 1 dep adult if married or have children*/
												/*(since an adult addition is given also for children`s carer). */
	gen extraadult=(single==0)		
	gen haschi=(depchldb>0) 
		ta rstrct if bdict01>0

			** building injlong from current available information
			ge injlong=. // period unable to work due to injury/illness/disability
			replace injlong = 3 if injyear==1 
			replace injlong = 1 if injlong==. & injyear==2 & injwks>0 & injwks<=28 
			replace injlong = 2 if injlong==. & injyear==2 & injwks>28 & injwks<=52 
			la def injlong 1 "28 weeks or less" 2 "More than 28 weeks, up to a year" 3 "More than 1 year"
			la val injlong injlong
		ta injlong if bdict01>0		// all those with positive IB should have been injured for more than 1 year - no obs in 2021/22
		
* IB amount:	
	gen maxib01=0
* long-term	- (under 35 or under 45) when they applied 
	// NOTE: restriction of ability to work does not identify all ppl receiving IB
	// NOTE: from FRS 2017/18 can't identify age when they started receiving the benefits => assume the most generous option (under 35) for all
	replace maxib01= $ib_lt + $ib_agehr + $ib_depadlt *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1))  if injlong==3 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))
	replace maxib01= $ib_lt + $ib_agehr + $ib_depadlt *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1))  if injlong==3 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))
* short-term high rate - under pension age
	replace maxib01= $ib_sthr_uspa + $ib_depad_uspa *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1))  if injlong==2 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))                                                            
* short-term low rate - under pension age
	replace maxib01= $ib_stlr_uspa + $ib_depad_uspa *extraadult if /*rstrct!=3 &*/ injlong==1 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))                                                             	
* long-term incapacitated pensioners don't get IB	
* short-term high rate pensioners (need to be within 5 years of SPA)
	replace maxib01= $ib_sthr_ospa + $ib_depad_ospa *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1)) if injlong>=2 & ((sex==1 & age2>=${SPAm} & age2<=${SPAm}+5)|(sex==2 & age2>=${SPAw} & age2<=${SPAw}+5))                                                             
* short-term low rate pensioners
	replace maxib01= $ib_stlr_ospa + $ib_depad_ospa *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1)) if injlong==1 & ((sex==1 & age2>=${SPAm} & age2<=${SPAm}+5)|(sex==2 & age2>=${SPAw} & age2<=${SPAw})) 
* all the remaining ppl declaring to get IB but not classifying based on the above selection are given the possible max amount
	replace maxib01= $ib_lt + $ib_agehr + $ib_depadlt *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1))  if maxib01==0 & ((sex==1 & age2<${SPAm})|(sex==2 & age2<${SPAw}))       // under SPA                                                      
	replace maxib01= $ib_lt + $ib_depadlt *extraadult + $ib_depech *haschi + $ib_depch *(max(0,depchldb-1)) if maxib01==0 & ((sex==1 & age2>=${SPAm})|(sex==2 & age2>=${SPAw}))              // over SPA                                               
	replace maxib01=maxib01*52/12		// average monthly amt
	ta maxib01,m 
	capture drop single extraadult haschi
	compare bdict01 maxib01	
	count if bdict01>maxib01 & bdict==0
	count if bdict01>maxib01 & bsa==0
	
	gen excess_ib01=max(0, bdict01 - maxib01)
	replace bdict01=maxib01 if maxib01>0 & excess_ib01>0 & bsa==0		// pda: for those who report less than they are entitled to and do not report SA
	
* NOTE: there are some ppl reporting that they get IB when they wouldn't be entitled to it (i.e. maxib01=0)
* in order not to loose this part of their income (which might not be reported anywhere else) we count them as IB receiver	
	drop excess_ib01
*/
	count if bdict01>0		

sort sernum person
save income, replace


******************************************************************
*  bdict02 - Employment and Support Allowance (contributory/IB)

* rstrct - Restricted in amount/type of work done	
*	1	Unable to work at the moment
*	2	Restricted in the amount or type of work
*	3	Not restricted in amount or type of work			
******************************************************************
	use sernum person benefit benamt numweeks var2 using $data/benefits, clear //numyears dropped in 2021/22
	keep if benefit==16	& (var2==1 | var2==3)	// ct-ESA
	count	
	
	drop if benamt==0
	isid sernum person 	
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bdict02
	label var bdict02 "Employment and Support Allowance (contributory) - monthly amount"
	ge c_esa=bdict02
	count if bdict02>0	
	
	
	* checks
	count if bdict01>0 & bdict02>0		// reporting both IB and c-ESA - no obs 
	/*
	su rstrct /*injlong*/ injwk injwks age2 /*maxib01 ib */ bdict01 if bdict01>0 & bdict02>0  // this person has probably IB not c-ESA
	replace bdict01=bdict02+bdict01 if bdict01>0 & bdict02>0			  // recode to IB
	replace bdict01=maxib01 if bdict01>maxib01 & bsa==0	& bdict01>0 & bdict02>0	// check against his maxib01 and recode to max amount possible if reported too much
	replace bdict02=0 if bdict01>0 & bdict02>0
	*/
	if ${use_assert} assert age>=16 & ((sex==1 & age<=${SPAm}) | (sex==2 & age<=${SPAw})) if bdict02>0 // age 16-SPA
	count if !((rstrct==1 | rstrct==2) /*& injlong>=1*/ ) & bdict02>0	// restricted capabilities of work because of illness
	ta rstrct /*injlong*/ if bdict02>0							
	ta age if rstrct>1 /*& injlong==-1*/ & bdict02>0			// could be confusing it with some other benefit?

	
// Transition IB->ESA finished in 2014 (hence no obs in the data). No need of reimputing ESA to IB anymore!
/*
	if ${use_assert} assert uincpay1!=1 & inclpay1!=1 if bdict02>0   // no entitled/receiving SSP
	ta incdur if (uincpay1==1 | inclpay1==1) & bdict02>0		
	ta injlong if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==-1	// -1 ==> ok, this could be SSP
	ta age if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==-1	  // 1
	ta bdict01 if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==1
	ta bdict02 if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==1
	replace bdict01=bdict01+bdict02 if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==1		// ESA is IB for ppl started years ago
	replace bdict02=0 if (uincpay1==1 | inclpay1==1) & bdict02>0 & incdur==1	
*/
	if ${use_assert} assert bsa==0 if bdict02>0		
		su bsa if bsa>0 & bdict02>0		// claiming both BSA and C-ESA: this is possible if claiming IS-JSA for reasons not related to disability
		su bsa01 if bsa>0 & bdict02>0	// claiming both C-ESA and I-ESA
	
	if ${use_assert} assert bdict01==0 if bdict02>0			// by 2014 c-ESA replaced IB, nobody can't get both
		
* create new variables that could be use in the simulation by Euromod
	//rename injlong ddipd // period unable to work due to injury/illness/disability //not available since 2018/19 
	rename injwk ddicthw // n of weeks unable to work
	rename rstrct ddictrd // Restricted in amount/type of work done	

	foreach var in /*ddipd*/ ddicthw ddictrd {
		replace `var'=0 if `var'==. 
		}

    count if bdict01>0	
	count if bdict02>0	
	count if bdict>0	
		
sort sernum person
save income, replace


*************************************
*  bdiwi- Industrial injuries benefit 

* benefit = 15
*************************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==15 	
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
	count if benamt>$iidb		
minclude
	replace benamt=$iidb*(52/12) if benamt>$iidb*(52/12) 	/*recode to maximum amount */
	rename benamt bdiwi
	label var bdiwi "Industrial injuries - monthly amount"
	sort sernum person
	save income, replace

*******************************
*  bcrdi- Carer's allowance

* benefit = 13
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==13 	
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	ta adultb , m
	ta   depchldb ,m
	gen max_ica = $ca if adultb==1 
	replace max_ica = $ca + $ca_depad if adultb==2 
	replace max_ica = max_ica + $ca_depech if depchldb==1
	replace max_ica = max_ica + $ca_depch * (depchldb-1) if depchldb>1
	ta max_ica, m
	replace max_ica=max_ica*(52/12)
	count if benamt>max_ica			
	replace benamt=max_ica if benamt>max_ica	/*amount replaced with max possible*/
	drop max_ica
rename benamt bcrdi
	label var bcrdi "ICA- monthly amount"
	sort sernum person
	save income, replace

****************************************
*  bdisv - Severe disablement allowance

* benefit = 10
****************************************
* SDA was aboilshed on 6 April 2001, but certain people entitled before that date can continue to receive it.

use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==10
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	gen max_sda= $sda_basic + $sda_addh  if adultb==1 
	replace max_sda = $sda_basic + $sda_addh + $sda_depad if adultb==2 
	replace max_sda = max_sda + $sda_addl if depchldb==1
	replace max_sda = max_sda + $sda_addh *(depchldb-1) if depchldb>1
	ta max_sda if benamt>0, m
	ge sda=benamt*12/52		
	replace max_sda =max_sda *(52/12)
	count if benamt>max_sda 					
	replace benamt=max_sda if benamt>max_sda 		/*amount replaced with max possible*/
	drop max_sda 
rename benamt bdisv 
	label var bdisv "SDA- monthly amount"
	sort sernum person
	save income, replace
	
	
*******************************
*  bhlwk - Statutory sick pay

* sspadj - SSP amount
*******************************
use income, clear
	inspect sspadj 
	su sspadj if sspadj>0	
	ta sspadj if sspadj>0
	replace sspadj=$ssp if sspadj!=. & sspadj>$ssp			
	gen bhlwk = 0
	replace bhlwk = sspadj if sspadj !=. & sspadj>0
	replace bhlwk = bhlwk * (52/12)
	label var bhlwk "Statutory sick pay - monthly amount"
* checks
	count if bhlwk>0 & bdict02>0	
*   cannot get both SSP and IB/c-ESA, however we do not correct the reported amount
*   because it maybe somebody getting SSP for the first 13 weeks and then passing to c-ESA
*   BUT if we decide to correct it, uncomment the two following commands
*	replace bdict=0 if bhlwk>0 & bdict02>0	// probably this person got SSP for the first 13 weeks and then c-ESA
*	replace bdict02=0 if bhlwk>0 & bdict02>0	
	count if bhlwk>0 & bdict01>0
	drop sspadj
	sort sernum person
	save income, replace

*******************************
*  buntr - Training allowance

* benefit = 36
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==36
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
rename benamt buntr 
label var buntr "Training allowance - monthly amount"

	sort sernum person
	save income, replace

*************************************************************************
*  bunct - Unemployment benefit (contributory jobseeker's allowance)

* benefit = 14
*	var2 = 1 - contributory
*	var2 = 3 - contributory (imputed answer)
* wageben5 - In receipt: Income Support
*************************************************************************
use sernum person benefit benamt var2 using $data/benefits,clear
	keep if benefit==14 & (var2==1|var2==3)
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	if ${use_assert} assert wageben5==2 if benamt>0 & benamt<=$cjsa25*(52/12)
	count if age2<25 & benamt>$cjsa25 *(52/12)		// age condition is not respected
	replace benamt=$cjsa25 *(52/12) if benamt>0 & benamt<$cjsa25*(52/12)
	if ${use_assert} assert wageben5==2 if benamt>$cjsa25 *(52/12) & benamt<=$cjsa*(52/12)
	*if ${use_assert} assert age2<25 if benamt>$cjsa25 *(52/12) & benamt<=$cjsa*(52/12)		// age condition is not respected
	replace benamt=$cjsa25 *(52/12) if benamt>$cjsa25 *(52/12) & benamt<=($cjsa25+$cjsa) /2*(52/12)
	replace benamt=$cjsa *(52/12) if benamt>($cjsa25+$cjsa) /2*(52/12) & benamt<=$cjsa *(52/12)
	if ${use_assert} assert wageben5==2 if benamt>$cjsa *(52/12)
	*if ${use_assert} assert age2>=25 if benamt>=$cjsa *(52/12)							// age condition is not respected
	replace benamt=$cjsa*(52/12) if benamt>$cjsa *(52/12)	/*recoded to max. possible amt.*/

* recode benamt as from c-UB rules on age   // PDA-FF: EM checks only if one receives bunct
		replace benamt=$cjsa25 *(52/12) if benamt>0 & age2<25
		replace benamt=$cjsa *(52/12) if benamt>0 & age2>=25
rename benamt bunct 
label var bunct "Contributory JSA - monthly amount"
	sort sernum person
	save income, replace

**********************************************************************
*  boawr - War pension - now Armed Forces Compensation Scheme (AFCS)

* benefit = 8
**********************************************************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==8
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
rename benamt boawr 
label var boawr "War pension - monthly amount"

	sort sernum person
	save income, replace

*******************************
*  bsuwd - Widow`s pension

* benefit = 5 - State Pension
* benefit = 6 - Bereavement Support Payment / Widowed Parent's Allowance
* benefit = 9 - War Widow's/Widower's Pension
*******************************
use sernum person benefit benamt using $data/benefits,clear
	sort sernum person
	merge sernum person using income
	assert _merge!=1
	keep sernum person benefit benamt marital sex age2
		/*includes cases of RP received by widow(er)s below pension age */	
	keep if benefit==6| benefit==9 | (benefit==5 & marital==4 & ((sex==1 & age2<${SPAm})|(sex==1 & age2<${SPAw})))
	ta benefit
		* Widow's Pension/Bereavement Allowance(benefit==6) counts as RP if above pension age, so recode to zero here 
	replace benamt=0 if (benefit==6 & sex==1 & age2>=${SPAm})|(benefit==6 & sex==2 & age2>=${SPAm}) 
	if ${use_assert} assert benamt!=.
collapse (sum) benamt , by (sernum person)
	isid sernum person
	if ${use_assert} assert benamt!=.
minclude
rename benamt bsuwd 
	label var bsuwd "Widow`s pension - monthly amount"
	sort sernum person
	save income, replace

*******************************
*  bfamt - Child tax credit

* benefit = 91 - Child Tax Credit
* benefit = 93 - Child Tax Credit Lump Sum
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==91|benefit==93
	ta benefit
		* exclude cases of lump sum payments
		drop if benefit==93
	isid sernum person
	ta benamt
minclude
	rename benamt bfamt
	label var bfamt "Child Tax Credit - monthly amount"

	sort sernum person
	save income, replace

*******************************
*  bwkmt - Working tax credit

* benefit = 90 - Working Tax Credit
* benefit = 92 - Working Tax Credit Lump Sum
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==90|benefit==92
	ta benefit
		* exclude cases of lump sum payments
		drop if benefit==92
	isid sernum person
	if ${use_assert} assert benamt>=0 & benamt!=.
	ta benamt
minclude
	rename benamt bwkmt 
	label var bwkmt "Working Tax Credit - monthly amount"

	sort sernum person
	save income, replace

*******************************
*  bch - Child benefit

* benefit = 3
*******************************
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==3
ta benefit
	isid sernum person
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bch
label var bch "Child Benefit - monthly amount"
 ta bch,m
tab2 depchldb bch
	sort sernum person
	save income, replace

/*there are apparent inconsistentcies in amounts
(also some amounts do not correposnd with possible CB rates)
but because benefit is simulated, amounts are left as such*/

**********************************************************************************
*  bho - Housing benefit

* hbothbu - Whether qualifies for HB (2nd+ BU) (1 yes, 0 no)
* hbothamt - Amount of HB received, rent paid or rent/rates rebate for 2n
* hbuc - Whether receives Housing Benefit or UC to support with rent (1 HB, 2 UC, 3 None)
* hbenamt - Housing Benefit amount
* hbweeks - Number of weeks on HB (Banded over 2 years)                     //DP: hbweeks dropped in 2021/22 dataset 
**********************************************************************************
use income, clear
	replace hbothbu =0 if hbothbu ==0 | hbothbu ==.	|hbothbu ==-1 /*not receiving and missing recoded as 0*/
	replace hbothamt=0 if hbothamt==.|hbothamt==-1 
	if ${use_assert} assert hbothamt>0 & hbothamt!=. if hbothbu==1
	preserve
		keep if hbothamt>0
		sort sernum benunit person
		list sernum benunit person age2 hrpid hbothamt if sernum==sernum[_n-1] & benunit==benunit[_n-1]	
		*if ${use_assert} assert benunit!=benunit[_n-1] if sernum==sernum[_n-1] 
		restore
	* only one person per household receives HB
	replace hbothamt=0 if hbothamt>0 & hbothamt!=. & sernum==sernum[_n-1] & benunit==benunit[_n-1] & hrpid!=1
	by sernum, sort: egen hbothamt_hh= total(hbothamt)	/*hh amount to everybody*/
		drop hbothamt
	rename hbothamt_hh hbothamt
	sort sernum person
	save income, replace 	

use sernum hbenamt hbuc /*hbenefit hbweeks*/ using $data/renter.dta, clear 

if ${use_assert} assert hbenamt!=. & hbenamt>0 if hbuc==1 /*those receiving have amount known and not zero*/
	count if hbenamt==. & hbuc==1
	count if hbenamt<=0 & hbuc==1

	list sernum if hbenamt<=0 & hbuc==1
	replace hbuc=-1 if hbenamt==0 & hbuc==1	
	replace hbenamt=0 if hbuc==2 | hbuc==3	| hbuc==-1	| missing(hbuc) 	/*replace to zero if receive UC or don`t receive anything*/
	sort sernum 
	merge 1:m sernum using income
		
	replace hbenamt=0 if _merge==2	/*missing for those not in renter dataset*/
		
	inspect hbenamt
    drop _merge

	if ${use_assert} assert hbenamt!=. & hbothamt!=. 
	

/*although hbenamt should include the hbothamt  amount,
as the first is asked with reference to the whole household, there are cases where 
amounts seems recorded seprately, so sum the two if hbothamt > hbenamt*/

	gen bho=hbenamt
	replace bho=bho + hbothamt if hbothamt>hbenamt
	replace bho=0 if bho==-1 | bho==.
	if ${use_assert} assert bho>=0 & bho!=.
	drop hbenamt hbuc hbothamt hbothbu 
		replace bho=bho*(52/12)
	sort sernum

	if ${use_assert} assert bho==bho[_n-1] if sernum==sernum[_n-1]
	ta hrpid
		count if bho>0 & hrpid==1
		count if bho>0 & hrpid!=1
	replace bho=0 if hrpid!=1 /*household level- assigned to pers. resp. for hh costs*/
	label var bho "Housing Benefit - monthly amount"
	sort sernum person
	save income, replace

/* time since LHA claim/receipt HB */	
	use sernum intdate using $data/househol.dta, clear
	sort sernum
	merge sernum using income
	ta _merge
	drop _merge
	sort sernum person
	merge sernum person using pers.dta, keep(ddt)
	ta _merge
	drop _merge
	
	ge bhomy=0
	/*
	ge bhomy = hbweeks/52*12 if bho>0 // number of months claimed HB
	replace bhomy = 1 if bhomy<0			
	la var bhomy "number of months claimed HB"
	su bhomy if bho>0
	if ${use_assert} assert bhomy>0 if hrpid==1		
	replace bhomy=0 if bhomy==.		
	drop hbweeks 
	*/
	sort sernum person
	save income, replace
	
	
**********************************************************************************
* bhoot - Discretionary Housing Payment

* dhp -- Whether Discretionary Housing Payment received  (1  Yes 2  No 3  Don't Know)
* dhpoamt -- Amount: one-off Discretionary Housing Pa
* dhpramt -- Amount: regular Discretionary Housing Pa
* dhprpd -- Pcode: Discretionary Housing Payment (1) 1 week (2) 2 weeks (4) 4 weeks (5) Calendar month (7)  Two Calendar months (13)  Three months (13 weeks)
* dhptype -- Type of Discretionary Housing Payment  (1  One-off payment; 2  Regular payment; 3  Both one-off and regular payments). 

**********************************************************************************	TO DO! Check whether the above categories changed 
use sernum dhp dhpoamt dhpramt dhprpd dhptype using $data/renter.dta, clear 

	fre dhprpd dhptype if dhpoamt>0 & dhpoamt<. 
	fre dhprpd dhptype if dhpramt>0 & dhpramt<. 
	count if dhpoamt<=0 & dhpramt <=0 & dhp==1
	
	gen bhoot1 = 0
	replace bhoot1 = dhpoamt/12 if dhpoamt>0 & dhpoamt<. //lumpsum amount is divided by 12
	//
	gen bhoot2 = 0
	replace bhoot2 = dhpramt/7*30.5 if dhprpd==1 & dhpramt>0 //regular amount for 1 week 
	replace bhoot2 = dhpramt/14*30.5 if dhprpd==2 & dhpramt>0 //regular amount for 2 weeks
	replace bhoot2 = dhpramt/21*30.5 if dhprpd==3 & dhpramt>0 //regular amount for 3 weeks
	replace bhoot2 = dhpramt/28*30.5 if dhprpd==4 & dhpramt>0 //regular amount for 4 weeks
	replace bhoot2 = dhpramt if dhprpd==5 & dhpramt>0 //regular amount for calendar month 
	replace bhoot2 = dhpramt/2 if dhprpd==7 & dhpramt>0 //regular amount for 2 calendar months
	replace bhoot2 = dhpramt/3 if dhprpd==13 & dhpramt>0 //regular amount for 3 calendar months
	
	gen bhoot = bhoot1 + bhoot2 
		
	drop dhp dhpoamt dhpramt dhprpd dhptype bhoot1 bhoot2 
	
	sort sernum 
	merge sernum using income
	replace bhoot=0 if _merge==2	/*missing for those not in renter dataset*/
	inspect bhoot 
	drop _merge
	
	sort sernum

	if ${use_assert} assert bhoot==bhoot[_n-1] if sernum==sernum[_n-1]
	ta hrpid
		count if bhoot>0 & hrpid==1
		count if bhoot>0 & hrpid!=1
	replace bhoot=0 if hrpid!=1 /*household level- assigned to pers. resp. for hh costs*/
	label var bhoot "Discretionary Housing Payment - monthly amount"
	sort sernum person
	save income, replace

	
*******************************************
* bhoro - Number of eligible rooms for renters when calculating Housing Benefit and Universal Credit
*******************************************	
use $data/pers.dta, clear
* calculate eligible number of bedrooms per household
* number of children by age groups and (for adolescents only) gender
ge child=adult==0
egen ch09=sum(child) if dag>=0 & dag<=9, by(idhh)
egen nch09=max(ch09), by(idhh)
replace nch09=0 if nch09==.
egen ch1015f=sum(child) if dag>=10 & dag<=15 & dgn==0, by(idhh)
egen nch1015f=max(ch1015f), by(idhh)
replace nch1015f=0 if nch1015f==.
egen ch1015m=sum(child) if dag>=10 & dag<=15 & dgn==1, by(idhh)
egen nch1015m=max(ch1015m), by(idhh)
replace nch1015m=0 if nch1015m==.
egen ch16plus=sum(child) if dag>=16, by(idhh)
egen nch16plus=max(ch16plus), by(idhh)
replace nch16plus=0 if nch16plus==.
egen adlt=sum(adult), by(idhh)
egen nadlt=max(adlt), by(idhh)
replace nadlt=0 if nadlt==.

* number of rooms for children depending on age and gender
ge nrch09=round(nch09/2)
replace nrch09=nrch09+1 if nrch09<(nch09/2)
ge nrch1015f=round(nch1015f/2)
replace nrch1015f=nrch1015f+1 if nrch1015f<(nch1015f/2)
ge nrch1015m=round(nch1015m/2)
replace nrch1015m=nrch1015m+1 if nrch1015m<(nch1015m/2)

* number of rooms for adult-couple
ge cpl=idpartner!=0
egen couple=sum(cpl/2), by(idhh)
egen nrcouple=max(couple), by(idhh)		// one room per couple

ge bhoro=(nadlt-nrcouple)+nch16plus+nrch1015f+nrch1015m+nrch09
foreach var in bhoro {
	replace `var'=0 if `var'==.
	}

la var bhoro "Eligible rooms for social renters"
keep idhh bhoro
rename idhh sernum
save temp_bhoro.dta, replace 

use income, clear
	merge m:m sernum using temp_bhoro	
	drop _merge

save income, replace


****************************************************************
*  bmu - Council Tax Reduction

* ctreb - Whether received any CT reduction/rebate (1 yes, 2 no)
* ctrebamt - Amount of CT Benefit/rebate
****************************************************************
use sernum ctreb ctrebamt using $data/househol, clear
	inspect ctrebamt if ctreb==1
		gen bmu=0
		replace bmu=ctrebamt*52/12 if ctreb==1 & ctrebamt!=.
	sort sernum
	merge m:m sernum using income
	drop _merge
	if ${use_assert} assert bmu==bmu[_n-1] if sernum==sernum[_n-1]
	ta hrpid
	replace bmu=0 if hrpid!=1					/*household level- assigned to pers. resp. for hh costs*/
	label var bmu "Council Tax Benefit - monthly amount"
sort sernum person
save income, replace



***************************************************************
* bot - Regular primary income (Other NI or State benefit)

* benefit = 30 
***************************************************************
*DP: 3 obs in 2018/19; no cases since then, but category has not been dropped 
use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==30
	isid sernum person			
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	rename benamt bot 
	label var bot "Regular primary income (any other benefit)"
sort sernum person
save income, replace

***************************************************************************************
* ypr, yprtx and yprnt- Taxable and non taxable ("rent a room" scheme) income from rent

* royyr1 - Rent before tax from other property
* subrent - Amount of rent from subletting
* tentyp2 - Tenure type (housing analysts full breakdown - see also PTENTYP)	
*	1	LA / New Town / NIHE / Council rented
*	2	Housing Association / Co-Op / Trust rented
*	3	Other private rented unfurnished
*	4	Other private rented furnished
*	5	Owned with a mortgage (includes part rent / part own)
*	6	Owned outright
*	7	Rent-free
*	8	Squats
* cvpay - Amount of rent after state benefits (boarders/lodgers)

***************************************************************************************
use sernum hhstat tentyp2 subrent using $data/househol, clear
sort sernum
merge sernum using income
drop _merge
	gen ypr_out=0
	replace ypr_out=royyr1 if royyr1>0 & royyr1!=.
	replace ypr_out=ypr_out*52/12			/*monthly rent from properties other than main residence*/
											/*attributed to person receiving the income*/
		
		gen ypr_in=0						/*initially attribute to each hh member*/
		replace ypr_in= subrent*52/12 if (tentyp2==5|tentyp2==6) & subrent>0 & subrent!=.		/*rent of owners letting room*/
		replace cvpay=0 if cvpay<0 | cvpay==.
		by sernum, sort: egen cvpayhh=max(cvpay)
		replace ypr_in = ypr_in + cvpayhh*52/12  	/*from boarders/lodgers (it is net of HB)*/
		if ${use_assert} assert ypr_in==ypr_in[_n-1] if sernum==sernum[_n-1]
		ta hrpid
		replace ypr_in =0 if hrpid!=1		/*household level- assigned to pers. resp. for hh costs*/
	gen yprnt=ypr_in if ypr_in*12<=$rent_room		
											/*assigned to responsible for hh costs*/
	replace yprnt=0 if yprnt==.

	gen yprtx=0	/*the part coming from rent of main residence, assigned to responsible for hh costs*/
	replace yprtx=yprtx+ypr_out
	replace yprtx=yprtx+ypr_in if ypr_in*12>$rent_room
	ge ypr = yprtx + yprnt
	inspect yprtx yprnt
label var yprtx "Taxable income from rent"
label var yprnt "Non-taxable income from rent"
label var ypr "Property income"
sort sernum person
save income, replace

***************************************************************************
* yptmp - maintenance payments received

* mntamt1 - Amount received: maintenance paid to self
* mntamt2 - Amount received: maintenance paid via DWP
* mntus1 - Maintenance to self - whether usual amount (1 yes, 2 no)
* mntus2 - Maintenance via DWP - whether usual amount (1 yes, 2 no)
* mntusam1 - Maintenance to self - usual amount
* mntusam2 - Maintenance via DWP - usual amount 
***************************************************************************
use income, clear
	inspect mntamt1 mntamt2 mntus1 mntus2 mntusam1 mntusam2 
	replace mntamt1 = mntusam1 if mntus1==2 &  mntusam1>0 & mntusam1!=.
	replace mntamt1 = 0 if mntamt1 <0  | mntamt1 ==.
	replace mntamt2 = mntusam2 if mntus2==2 &  mntusam2>0 & mntusam1!=.
	replace mntamt2 = 0 if mntamt2 <0  | mntamt2 ==.
	gen yptmp=(mntamt1 + mntamt2)* (52/12)
	label var yptmp "maintenance payments received - monthly amount" 
sort sernum person
save income, replace

****************************************
* bmana - Maternity Allowance

* benefit = 21
****************************************
 use sernum person benefit benamt using $data/benefits,clear
	keep if benefit==21
	isid sernum person			
	if ${use_assert} assert benamt>0 & benamt!=.
	ta benamt
minclude
	gen bmana=benamt 
	replace bmana = $ma *(52/12) if  benamt > $ma*(52/12) 	
	gen MAtoSMP= benamt-bmana if benamt>$ma*(52/12) 
	replace MAtoSMP=0 if MAtoSMP==.
	drop benamt
	label var bmana "Maternity Allowance"
sort sernum person
save income, replace

****************************************
* bmaer - Statutory Maternity Pay

* smpadj - SMP amount
****************************************
* statutory paternity and adoption pay are so rare that does not pay to have a var for those
use income, clear
	inspect smpadj
	gen bmaer = 0
	replace bmaer = smpadj if smpadj!=. & smpadj>0
	replace bmaer = bmaer * (52/12)
	replace bmaer = bmaer + MAtoSMP if MAtoSMP >0			/* add excess maternity allowance*/ 
	drop MAtoSMP
	label var bmaer "Statutory maternity pay - monthly amount"
	drop smpadj
sort sernum person
save income, replace

keep sernum person ypp yptmp bch bsa* bho bhoro bhoot /*bhomy*/ yls bdioa bdisc bdimb bdiscwa bdimbwa bdict* bdiwi bcrdi bdisv /*
*/ bhlwk buntr bunct boawr bedes bedsl bmana bmaer boamt bfamt bot bwkmt tmu01 tmu02 tmu03 tmu04 yptot /*
*/ bsuwd yds boaht bmu ypr yprtx yprnt /*ddipd*/ ddict* 


/*chgcovid furlough furlo2  furlpay furlpay2 seissgr seissnum seisstot
*DP: recode missing values in COVID vars to -1 
foreach var in chgcovid furlough furlo2  furlpay furlpay2 seissgr seissnum seisstot {
replace `var'=-1 if `var'==. | `var'<=-1
}
**********************************************
*COVID related variables used in simulations *
**********************************************
/* furlpay -- Furlough Pay - added May 2020, removed Jan 2022
1  ...Full pay
2  ... more than 80%, but less than	full pay
3  ... 80% of normal pay
4  ...less than 80% normal 

seisstot -- Total amount of SEISS received - added J
*/      
***************************************
tab2 furlough furlpay
tab2 furlo2  furlpay2 //4 cases only can be ignored
*Flag: whether on CJRS 
gen lmcee = 0 
replace lmcee = 1 if furlpay>0
*Percentage of earnings received through CJRS 
gen bwkmcee = furlpay

bysort seissgr: fre seisstot
*Flag: Whether on SEISS
gen lmcse = 0
replace lmcse = 1 if seisstot>0
*Total amount of SEISS received 
gen bwkmcse = seisstot
recode bwkmcse (-1=0)

fre lmcee bwkmcee lmcse bwkmcse 
***************************************************************
*/ 

sort sernum person
save income, replace
des

cap log close
erase temp_bhoro.dta
