***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         03_PersonalInformation.do
* DESCRIPTION:          
*						- Create IDs variables; check consistency of these variables
*						- Create personal socio-demographic variables and household weights
* INPUT FILE:           household, individual
* OUTPUT FILE:          pers
* NEW VARS:
*                       - idhh		      Household ID
*                       - idperson		  Person ID 
*                       - idfather        Father ID	
*                       - idmother        Mother ID	
*                       - idfatherbio     Father ID	(only biological parents)
*                       - idmotherbio     Mother ID	(only biological parents)
*                       - idpartner       Partner ID	
*                       - idorighh        Original Household ID
*                       - idorigperson    Original Personal ID
*                       - idorigbenunit   Original Benefit Unit ID
*                       - dag             Age
*                       - dgn             Gender (0. Female 1. Male)	
*                       - dms             Marital status (1. Single 2. Married 3. Separated 4. Divorced 5. Widowed)
*                       - dcz             Citizenship	
*                       - ddi             Disability status
*                       - ddi03           Disability - Equality Act core definition 
*                       - ddt             Date of interview
*						- ddt01 		  Month of interview
*                       - dwt             Household Grossing-up weight
*                       - dct             Country
*                       - dec             Current education	- EUROMOD style 
*                       - dec02           Current education - FRS style 
*                       - deh             Highest education achieved 
*                       - dey             Number of years spent in education 
*                       - dew             Year when highest level of education was attained
*                       - drgn1           Region (NUTS 1 level) 
*                       - dhr             Person responsible for housing
*                       - dpd             Data year 
*                       - dot             Ethnic group
* LAST UPDATE:          19/06/2024
***************************************************************************************
cap log close 
log using "${log}/03_PersonalInformation.log", replace
*** use relevant variables from individual and hh level data
    /*highonow hi3qual hi1qual*/ 
	use sernum benunit person sex adult age80 age r01 r02 r03 r04 r05 r06 r07 r08 r09 r10 r11 r12 r13 r14 /// 
	marital ms empstati chealth1 chcond hrpid /*fted*/ educft  /*typeed*/ educsch typeed2 ///
	/*tea*/ educleft /*tea9697*/ educt97 corign* cameyr cameyr2 contuk /*dvhiqual*/ educqual etngrp* ethgr3 discor* using $data/individual.dta, clear
	sort sernum
	save temp, replace
	use sernum intdate gvtregno gross4 using $data/househol.dta,clear
	sort sernum
	merge sernum using temp
	ta _merge
	drop _merge

************************************************************************
* CHECK AND IMPUTE MISSING VALUES
*
************************************************************************

* check for ID variables *before* the imputations: this is done by calling
* the do file 04_CheckIDs.do from here.

global use_assert1 = 0 // separate switch for the script 04_CheckIDs.do
* INSERT HERE CORRECTIONS OF MISTAKES IN RELATIONSHIP VARIABLES IDENTIFY BY checksIDs.do

*******************************
*  IDHH - household identifier
*******************************
	su sernum
	gen double idhh=sernum
	
*************************************
*  IDORIGHH - household identifier as in source FRS data (same as idhh, NO NEED FOR THIS VARIABLE IN FACT)
*************************************
	gen idorighh=sernum
	
*********************************
*  IDORIGBENUNIT - benefit unit identifier as in source FRS data ('benunit' variable, needed for merge with 'benunit' FRS dataset)
*********************************	
	gen idorigbenunit=benunit
	
********************************
*  IDPERSON - person identifier
********************************
	sort idhh person	
	gen double idperson=(idhh*100+person)
	format idperson %15.0g
	
**********************************************************
*  IDORIGPERSON - person identifier as in source FRS data 
**********************************************************
	gen idorigperson=person
	

	*	CHECKS
	assert idhh==sernum
	assert idorighh==sernum
	assert idorigperson==person
	assert idorigbenunit==benunit
	assert idperson==idhh*100+person
	
*** relationship variables
	gen age2=age80 if adult==1
	replace age2=age if adult==0
	drop age age80
	ta age2, m
	order idhh idperson age2 
	sort idperson 
	by idhh, sort: gen maxp=_N
	foreach n in 1 2 3 4 5 6 7 8 9 {
		rename r0`n' r`n'
	}
	sort idperson 
	
*****************************************
*  IDPARTNER

* r01-r14 - Relationship to person 1-14	
*	1	Spouse
*	2	Cohabitee
*	3	Son/daughter (incl. adopted)
*	4	Step-son/daughter
*	5	Foster child
*	6	Son-in-law/daughter-in-law
*	7	Parent
*	8	Step-parent
*	9	Foster parent
*	10	Parent-in-law
*	11	Brother/sister (incl. adopted)
*	12	Step-brother/sister
*	13	Foster brother/sister
*	14	Brother/sister-in-law
*	15	Grand-child
*	16	Grand-parent
*	17	Other relative
*	18	Other non-relative
*	20	Civil Partner
**********************************************
	tempfile all spouseID
	gen spousenr = 0
*	for num 1/14: replace spousenr = X if rX == 1 | rX == 2	
	forv x = 1/14 {
		replace spousenr = `x' if r`x' == 1 | r`x' == 2 
		}
	save `all'
	keep idhh idperson person
	rename person spousenr
	rename idperson idpartner
	sort idhh spousenr
	save `spouseID'
	use `all'
	sort idhh spousenr
	merge idhh spousenr using `spouseID', uniqusing
	tab _merge
	drop if _merge == 2 // do not have spouses
	drop _merge spousenr
	order idhh idperson idpartner sex age2 r*
	replace idpartner=0 if idpartner==.
	format idpartner %15.0g


*** type of parent: father or mother; type of child (of mum or of dad)
*DP: note that this inlcudes all parents/children , biological and non-biological 
	sort idhh person
	cap label define parco 1 "father" 2 "mother" 
	cap label define chico 1 "chi-dad" 2 "chi-mum"
	foreach n of num 1/14 {
		gen sex`n'=0
		replace sex`n'=sex if person==`n'
		by idhh, sort: egen s`n'=max(sex`n')
		gen p`n'=0
		replace p`n'=1 if (r`n'==7|r`n'==8|r`n'==9) & sex==1
		replace p`n'=2 if (r`n'==7|r`n'==8|r`n'==9) & sex==2
		gen c`n'=0
		replace c`n'=1 if (r`n'==3|r`n'==4|r`n'==5) & s`n'==1
		replace c`n'=2 if (r`n'==3|r`n'==4|r`n'==5) & s`n'==2
		label values p`n' parco
		label values c`n' chico 
	}
	order idhh person sex age r1 s1 p1 c1 r2 s2 p2 c2 r3 p3 c3 s3 r4 p4 c4 r5 p5 c5
	
		
************
*  IDFATHER
************
	tempfile all fatherID
	gen fathernr = 0
	for num 1/14: replace fathernr = X if cX == 1 
	save `all'
	keep idhh person idperson
	rename person fathernr
	rename idperson idfather 
	sort idhh fathernr
	save `fatherID'
	use `all'
	sort idhh fathernr
	merge idhh fathernr using `fatherID', uniqusing
	tab _merge
	drop if _merge == 2 // do not have father
	drop _merge fathernr
	replace idfather=0 if idfather==.
	format idfather %15.0g

	
	
************
*  IDMOTHER
************
	tempfile all motherID
	gen mothernr = 0
	for num 1/14: replace mothernr = X if cX == 2 
	save `all'
	keep idhh person idperson
	rename person mothernr
	rename idperson idmother 
	sort idhh mothernr
	save `motherID'
	use `all'
	sort idhh mothernr
	merge idhh mothernr using `motherID', uniqusing
	tab _merge
	drop if _merge == 2 // do not have mother
	drop _merge mothernr
	replace idmother=0 if idmother==.
	format idmother %15.0g
	sort idperson

	inspect idpartner idfather idmother 
	

*****************************************
*Create ids for biological parents only *
*****************************************
*** type of parent: father or mother; type of child (of mum or of dad)

	sort idhh person
	cap label define parco 1 "father" 2 "mother" 
	cap label define chico 1 "chi-dad" 2 "chi-mum"
	
	foreach n of num 1/14 {
	    cap drop sex`n'
		gen sex`n'=0
		replace sex`n'=sex if person==`n'
		
		cap drop s`n'
		by idhh, sort: egen s`n'=max(sex`n')
		
		cap drop p`n' 
		gen p`n'=0
		replace p`n'=1 if (r`n'==7 /*|r`n'==8|r`n'==9*/) & sex==1 /*exclude step- and foster parents*/
		replace p`n'=2 if (r`n'==7 /*|r`n'==8|r`n'==9*/) & sex==2
		
		cap drop c`n'
		gen c`n'=0
		replace c`n'=1 if (r`n'==3 /*|r`n'==4|r`n'==5*/) & s`n'==1 /*exclude step- and foster children*/
		replace c`n'=2 if (r`n'==3 /*|r`n'==4|r`n'==5*/) & s`n'==2
		
		label values p`n' parco
		label values c`n' chico 
	}
	order idhh person sex age r1 s1 p1 c1 r2 s2 p2 c2 r3 p3 c3 s3 r4 p4 c4 r5 p5 c5
	
		
********************************************
*  IDFATHERBIO - incl only biological parents 
********************************************
	tempfile all fatherIDbio
	cap drop fathernr
	gen fathernr = 0
	for num 1/14: replace fathernr = X if cX == 1 
	save `all'
	keep idhh person idperson
	rename person fathernr
	rename idperson idfatherbio 
	sort idhh fathernr
	save `fatherIDbio'
	use `all'
	sort idhh fathernr
	merge idhh fathernr using `fatherIDbio', uniqusing
	tab _merge
	drop if _merge == 2 // do not have biological father
	drop _merge fathernr
	replace idfatherbio=0 if idfatherbio==.
	format idfatherbio %15.0g

	
********************************************
*  IDMOTHERBIO - incl only biological parents 
********************************************
	tempfile all motherIDbio
	cap drop mothernr
	gen mothernr = 0
	for num 1/14: replace mothernr = X if cX == 2 
	save `all'
	keep idhh person idperson
	rename person mothernr
	rename idperson idmotherbio 
	sort idhh mothernr
	save `motherIDbio'
	use `all'
	sort idhh mothernr
	merge idhh mothernr using `motherIDbio', uniqusing
	tab _merge
	drop if _merge == 2 // do not have mother
	drop _merge mothernr
	replace idmotherbio=0 if idmotherbio==.
	format idmotherbio %15.0g
	sort idperson
	
	inspect idfather idfatherbio 
	inspect idmother idmotherbio 
	
	
/*Fixes to hh ids based on 04_CheckIds*/
replace idpartner=2296101 if idperson==2296102 	

replace idfather =0 if idperson==471002
replace idfather =471002 if idperson==471003

replace idfather=0 if idperson==966002 
replace idfather=0 if idperson==966003
replace idfather=966002 if idperson==966001
replace idmother=966003 if idperson==966001
	
replace idmother =0 if idperson==268802
replace idmother =268802 if idperson==268803 
replace idmother =268802 if idperson==268804
replace idmotherbio =268802 if idperson==268803 
replace idmotherbio=268802 if idperson==268804

replace idmother=0 if idperson==894102 
replace idmother=894102 if idperson==894103
replace idmotherbio=894102 if idperson==894103

replace idmother=866901 if idperson==866903     
replace idmotherbio=866901 if idperson==866903 

replace idfather=0 if idperson==1474201
replace idfather=0 if idperson==1474202
replace idfatherbio=0 if idperson==1474201
replace idfatherbio=0 if idperson==1474202



	keep idhh idperson sex age2 marital ms idpartner idfather idmother idfatherbio idmotherbio sernum benunit person /*
*/	empstati chealth1 chcond adult idorighh idorigbenunit idorigperson hrpid educft typeed typeed2 educleft educt97 intdate gvtregno gross4 /*
*/	corign etngrp ethgr3 educqual discor* 


**************************************
*  dgn - gender
* 1 - male
* 0 - female

* sex - Sex (1 male, 2 female)
**************************************
	gen dgn=(sex==1)
	
**************************************
*  dag - age (truncated at 80)
**************************************
	gen dag=age2
************************************************************************
* dms		Marital status 
*
* 1: Single (Never Married)
* 2: Married
* 3: Separated
* 4: Divorced
* 5: Widowed	

* marital - Adult - Marital Status	
*	1	Married / Civil Partnership
*	2	Cohabiting
*	3	Single
*	4	Widowed
*	5	Separated
*	6	Divorced / Civil Partnership dissolved
* note FRS 2018/19: in previous do-file versions, variable ms also used but variable has only missing values
************************************************************************
gen dms=0
replace dms=1 if (marital==3|marital==2)	/*single*/
replace dms=2 if marital==1					/*married*/
replace dms=3 if marital==5					/*separated*/
replace dms=4 if marital==6				/*divorced*/
replace dms=5 if marital==4				/*widowed*/

**********************************************
*  dct - Country

* country values are based on EU-SILC data
* relevant when data used with the EU-wide model EUROMOD                                    
* AT: 1     BE: 2     DK: 3    
* FI: 4     FR: 5     DE: 6    
* EL: 7     IE: 8     IT: 9   
* LU: 10    NL: 11    PT: 12 
* ES: 13    SE: 14    UK: 15  
* EE: 16    HU: 17    PL: 18     
* SI: 19    BG: 20    CZ: 21
* CY: 22    LV: 23    LT: 24
* MT: 25    RO: 26    SK: 27
* HR: 28
***********************************************
	gen dct=15
	
*********************
*  dcz - Citizenship 
*
* 1: Same country as country of residence
* 2: Any European country except country of residence
* 3: Any other country

* corign - Country of origin	MISSING FOR ALL CASES
*	1	England
*	2	Wales
*	3	Scotland
*	4	Northern Ireland
*	5	UK, Britain
*	6	Republic of Ireland
*	7	India
*	8	Pakistan
*	9	Poland
*	10	Other
*********************
gen dcz=1 // corign is missing for all cases, so we assume a value of 1 for all
replace dcz=2 if corign == 6 | corign == 9
replace dcz=3 if corign == 7 | corign == 8 | corign == 10 

***************************
*  ddi - disability status
*
*  1: yes
*  0: no

* empstati -Adult - Employment Status - ILO definition	
*	9	Permanently sick/disabled
* chealth1 - Any long standing illness/disability (1 yes, 2 no)
* chcond - Whether condition limits day to day activities
*	1	Yes, activities reduced a lot
*	2	Yes, activities reduced a little
*	3	Not at all
***************************
	gen ddi=0
	replace ddi=1 if  empstati==9 & adult==1
	replace ddi=1 if adult==0 & (chealth1==1 & chcond==1)
	
**********************************
*  ddi03 - disability status - Equality Act core definition
*discora1 -- Whether has a disability (the Equality Act 2010-core def)
*1 YES
*2 NO
*discorc1 -- Whether has a disability (the Equality Act 2010 - core def)
*1 YES
*2 NO
**********************************
	gen ddi03=0
	replace ddi03=1 if discora1==1 | discorc1==1 
    //tab2 ddi03 adult

**********************************
*  dhr - responsible for hh costs

* hrpid - Household Reference Person Identifier (1 hrp, 2 not hrp)
**********************************
gen dhr=hrpid==1
* (NOTE: if more than one person in hh is responsible for housing costs, they idenfity among those
* the person with highest personal income, and, among those with same income, the eldest)

***********************************
*  dwt - HH cross-sectional weight
***********************************
	rename gross4 dwt
	
*********************************
*  drgn1 - Region at NUTS1 level

* gvtregno - Region in UK (original FRS codes)	
*	1	North East
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
*********************************
	rename gvtregno drgn1
	ta drgn1,m
	
***************************
*  ddt - Date of interview

* intdate - Date on which interview started
***************************
	local yr1 "2022" // TO DO!
	local yr2 "2023" // TO DO!
	gen double ddt=`yr1'0315
	replace ddt=`yr1'0415 if intdate>date("31-3-`yr1'", "DMY") 
	replace ddt=`yr1'0515 if intdate>date("30-4-`yr1'", "DMY") 
	replace ddt=`yr1'0615 if intdate>date("31-5-`yr1'", "DMY") 
	replace ddt=`yr1'0715 if intdate>date("30-6-`yr1'", "DMY")
	replace ddt=`yr1'0815 if intdate>date("31-7-`yr1'", "DMY")	
	replace ddt=`yr1'0915 if intdate>date("31-8-`yr1'", "DMY")
	replace ddt=`yr1'1015 if intdate>date("30-9-`yr1'", "DMY")
	replace ddt=`yr1'1115 if intdate>date("31-10-`yr1'", "DMY")
	replace ddt=`yr1'1215 if intdate>date("30-11-`yr1'", "DMY")
	replace ddt=`yr2'0115 if intdate>date("31-12-`yr1'", "DMY")
	replace ddt=`yr2'0215 if intdate>date("31-1-`yr2'", "DMY")
	replace ddt=`yr2'0315 if intdate>date("28-2-`yr2'", "DMY")
	replace ddt=`yr2'0415 if intdate>date("31-3-`yr2'", "DMY")
	replace ddt=`yr2'0515 if intdate>date("30-4-`yr2'", "DMY")
	format ddt %15.0g

*****************************
*  ddt01 - Month of interview
*****************************
tostring ddt, generate(str_ddt)
gen month = substr(str_ddt,-4,2) // 5th and 6th characters 
destring month, gen(ddt01) // month of interview
drop str_ddt month	

************************************************************************
* dec			Current education - EUROMOD style 	
*
* 0: Not in education
* 1: Pre-school 
* 2: Primary 
* 3: Lower Secondary
* 4: Upper Secondary
* 5: Post Secondary
* 6: Tertiary

* educft - Whether presently in full time education (1 yes, 2 no)
* typeed2 - Type of school or college attended - Anon	
*	1	Nursery/Playgroup/Pre-school (state Run)
*	2	Primary (including reception class)
*	3	Special school (state run or assisted)
*	4	Middle-deemed primary (state run or assisted)
*	5	Middle-deemed secondary(state run or assisted)
*	6	Secondary/Grammer school (state run/assisted)
*	7	Non-advanced further education
*	8	Any PRIVATE school (prep or secondary)
*	9	University/polytechnic/higher education

************************************************************************
	assert dag<=3 | dag>=75 if educft==-1 | educft==.	
	gen dec=0 if educft==2 | educft==-1 | educft==.	/*not in edu*/
	replace dec=1 if typeed2==1	/*pre-primary*/
	replace dec=2 if ((typeed2==2|typeed2==4)|((typeed2==3|typeed2==8) & dag<11) | (typeed2==. & educft==1 & dag>5 & dag<11))	/*primary*/
	replace dec=3 if ((typeed2==5|typeed2==6) | ((typeed2==3|typeed2==8) & dag>=11 & dag <=16) ///
	| (typeed2==. & educft==1 & dag >=11 & dag <=16))	/*lower secondary*/
	replace dec=4 if (typeed2==7 | ((typeed2==3|typeed2==8) & dag >16) | (typeed2==. & educft==1 & dag>16)) /*upper secondary*/
	replace dec=5 if ((typeed2==7|typeed2==8) & dag>=19)	/*post secondary*/
	replace dec=6 if typeed2==9 | (typeed2==. & educft==1 & dag>=19)  /*tertiary*/

************************************************************************
* dec02			Current education - same as in the FRS 		

* educft - Whether presently in full time education (1 yes, 2 no)
* typeed2 - Type of school or college attended - Anon	
*	1	Nursery/Playgroup/Pre-school (state Run)
*	2	Primary (including reception class)
*	3	Special school (state run or assisted)
*	4	Middle-deemed primary (state run or assisted)
*	5	Middle-deemed secondary(state run or assisted)
*	6	Secondary/Grammer school (state run/assisted)
*	7	Non-advanced further education
*	8	Any PRIVATE school (prep or secondary)
*	9	University/polytechnic/higher education
    assert dag<=3 | dag>=75 if educft==-1 | educft==.	
	gen dec02=0 if educft==2 | educft==-1 | educft==.	/*not in edu*/
	replace dec02=1 if typeed2==1	/*Nursery/Playgroup/Pre-school (state Run)*/
	replace dec02=2 if typeed2==2	/*Primary (including reception class) */
	replace dec02=3 if typeed2==3	/*Special school (state run or assisted) */
	replace dec02=4 if typeed2==4	/*Middle-deemed primary (state run or assisted) */
	replace dec02=5 if typeed2==5	/*Middle-deemed secondary(state run or assisted) */
	replace dec02=6 if typeed2==6	/*Secondary/Grammer school (state run/assisted) */
	replace dec02=7 if typeed2==7	/*Non-advanced further education */
	replace dec02=8 if typeed2==8	/*Any PRIVATE school (prep or secondary) */
	replace dec02=9 if typeed2==9 /*University/polytechnic/higher education */
	
	
************************************************************************
* deh			Highest Education achieved
*	
* 0: Not completed primary education
* 1: Primary 
* 2: Lower Secondary
* 3: Upper Secondary
* 4: Post Secondary
* 5: Tertiary

* educleft - Age completed full-time education
* educt97 - Full-time education status	
*	96	Still in full time education
*	97	Never been in full time education
* educqual - Highest level of qualification (derived in questionnaire) (categories 1-86)
************************************************************************
gen deh=.
* children 
	replace deh=dec-2 if dec>1 & adult==0
	replace deh=0 if (dec<2 | dec==.) & adult==0
	
* adults in education (dec>0)
	assert adult==0 if dec==1
		
	replace deh=dec-2 if dec>1 & adult==1
	replace deh=3 if dec==6 & adult==1				/*post-secondary considered alternative route to tertiary*/

* adults not in education (use age completed full time education or, if missing, highest qualification achieved)
	replace deh=0 if deh==. & educleft==-1 & educt97==97		/*were never in education*/
	replace deh=0 if deh==. & (educleft <11)
	replace deh=1 if deh==. & (educleft>=11 & educleft <16)
	replace deh=2 if deh==. & (educleft>=16 & educleft <18) | (educleft==. & educqual>=29 & educqual!=.)
	replace deh=3 if deh==. & (educleft>=18 & educleft <20) | (educleft==. & educqual>=18 & educqual<=28)
	replace deh=4 if deh==. & (educleft==20) | (educleft==. & educqual>=8 & educqual<=17)
	replace deh=5 if deh==. & (educleft>=21 & educleft <=64) | (educleft==. & educqual>=1 & educqual<=7)  

count if deh==.	// impute missing values
gen age_gr=1 if dag<20
replace age_gr=2 if dag>=20 & dag<29
replace age_gr=3 if dag>=30 & dag<39
replace age_gr=4 if dag>=40 & dag<49
replace age_gr=5 if dag>=50 & dag<59
replace age_gr=6 if dag>=60
bys age_gr: egen mdeh = median(deh)
replace deh = mdeh if deh==. // impute missing values with median for the age group
drop mdeh age_gr

assert dec!=. & deh!=.
count if deh!=(dec-2) & dec>0 & deh>0


***********************************************
*  dew - When achieved Highest education level 
***********************************************
* never obtained a qualification
	gen dew=-1 if deh==0
* those not currently in education: use terminal education age
	gen educleft2=. 				/*educleft2: age when completed highest ed. level*/
	replace educleft2=educleft if dec==0 & deh!=0
* those with missing educleft: impute based on highest qualification received
	replace educleft2=min(dag,10) if deh==1
	replace educleft2=min(dag,16) if deh==2
	replace educleft2=min(dag,19) if deh==3
	replace educleft2=min(dag,20) if deh==4
	replace educleft2=min(dag,22) if deh==5
	*assert educleft2>0 & educleft2!=. if dew!=-1
	gen yearnow=2022 // TO DO!
	replace yearnow=2023 if intdate>date("31-12-2022", "DMY") // TO DO!	
	gen cohort=(yearnow-dag) 
    replace dew = cohort + educleft2 if dew!=-1
	
********************************************
*  dey - Number of years spent in education 
********************************************
gen dey =((dew - cohort)- 5) if dec==0 & deh!=0
replace dey = max(0,(dag-5)) if dec>0
replace dey=0 if dag<5 | deh==0
inspect dey

***********************************************************************
*  dpd - Variable indicating income reference period of the micro-data
***********************************************************************
* Note: FRS period of collection runs from Apr t to Mar t+1 but the variable refers to t only.
gen dpd = ${frsyr}		

**********************************************************
* dot - ethnic group
* 1	White - English/Welsh/Scottish/Northern Irish/British
* 2	White - Irish
* 3	White - Gypsy or Irish Traveller
* 4	Any other white background
* 5	Mixed - White and Black Caribbean
* 6	Mixed - White and Black African
* 7	Mixed - White and Asian
* 8	Any other mixed multiple ethnic background
* 9	Asian or Asian British - Indian
* 10	Asian or Asian British - Pakistani
* 11	Asian or Asian British - Bangladeshi
* 12	Chinese
* 13	Any other Asian/Asian British background
* 14	Black or Black British - African
* 15	Black or black British Caribbean
* 16	Any other black/African/Caribbean background
* 17	Arab
* 18	Any other

* etngrp - Ethnic group (categories 1-18)
* ethgr3 - Ethnicity of Adult (harmonised version)	
*	1	White
*	2	Mixed/ Multiple ethnic groups
*	3	Asian/ Asian British
*	4	Black/ African/ Caribbean/ Black British
*	5	Other ethnic group
**********************************************************
gen dot = -1 // n/a
replace dot = etngrp if etngrp !=.
tab dot
replace dot = 1 if ethgr3==1 & etngrp<=-1
replace dot = 8 if ethgr3==2 & etngrp<=-1
replace dot = 13 if ethgr3==3 & etngrp<=-1
replace dot = 16 if ethgr3==4 & etngrp<=-1
replace dot = 18 if ethgr3==5 & etngrp<=-1
replace dot = -1 if etngrp <=-1 & ethgr3==. | ethgr3==6

tab dot
inspect dot
fre dot etngrp ethgr3 
fre dot etngrp ethgr3 if dag>16
/*
tab2  dot ethgr3 if dag>16, m
tab2  dot ethgr3 , m
*/

keep sernum person  idhh idorigperson idorighh idpartner idperson idfather idmother idfatherbio idmotherbio ///
 idorigbenunit dag dct dcz ddi ddi03 ddt* dec dec02 deh dew dey dgn dms drgn1 dwt dhr ///
 adult dpd dot

sort sernum person
save pers, replace
des

cap log close 
erase temp.dta
