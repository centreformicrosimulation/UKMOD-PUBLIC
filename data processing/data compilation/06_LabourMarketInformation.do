***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         06_LabourMarketInformation.do
* DESCRIPTION:          Create labour market variables 
* INPUT FILE:           individual, job
* OUTPUT FILE:          lab
* NEW VARS:
*                       - les             Economic status
*                       - lcs             Civil servant
*                       - lfs             Firm size	
*                       - lindi           Industry			
*                       - liwwh           Work history (Length of time in months)
*                       - lcwnm           Tenure at current job (lengh of time in months)   
*                       - loc             Occupation
*                       - loc01           Standard Occupational Classification
*                       - loc02           Detailed Social-Economic Classifications
*                       - lowas           Out of work - Actively seeking
*						- lcr01			  Caring for dependent person (for Income Support purposes): 1 yes, 0 no
*						- lcr02	  		  Caring for dependent person (for Income Support purposes): 1 child, 2 adult, 3 elderly 
*						- lle			  On leave (under unpaid Maternity, Paternity or Parental leave: for IS eligibility conditions)
* LAST UPDATE:          09/06/2025
***************************************************************************************
cap log close 
log using "${log}/06_LabourMarketInformation.log", replace
	use sernum benunit person sex adult age80 age empstatb /*fted*/ educft  sic /*
*/	ptwk ftwk soc2020 memschm emppen lktrain lkwork abswk abswhy abspay hourtot currjobm /*
*/	careot carefr /*ben1q3*/ wageben8 nssec sic using individual, clear


****************************
*  les - Economic Status
*  0: children in pre-school or younger
*  1: farmer 
*  2: employer or self-employed
*  3: employee
*  4: pensioner
*  5: unemployed
*  6: student
*  7: inactive 
*  8: sick or disabled
*  9: other

* educft - Whether presently in full time education (1 yes, 2 no)
* emstatb - Adult - Employment Status	
*	1	Self-Employed
*	2	Full Time Employee
*	3	Part Time Employee
*	4	FT Employee temporarily Sick
*	5	PT Employee temporarily Sick
*	6	Industrial Action
*	7	Unemployed
*	8	Work related Govt training
*	9	Retired
*	10	Unoccupied under retirement age
*	11	temporarily sick
*	12	Long term sick
*	13	Students in non advanced FE
*	14	Unpaid Family Workers
****************************
	gen les=6 if adult==0 					/*student: any child aged 5 or above (those 15+ must be in education if "child")*/
	replace les=0 if (educft==2|educft==-1) & age<5	/*pre-school*/
	replace les=2 if empstatb==1 /*Employer or self-employed*/
	replace les=3 if empstatb==2|empstatb==3|empstatb==4|empstatb==5|empstatb==6|empstatb==8	/*Employee*/
	replace les=4 if empstatb==9				/*Pensioner*/
	replace les=5 if empstatb==7				/*Unemployed*/
	replace les=6 if empstatb==13				/*Student*/
	replace les=7 if empstatb==10				/*Inactive*/
	replace les=8 if empstatb==11|empstatb==12	/*Sick or Disabled*/
	replace les=9 if empstatb==14			/*Family worker*/
*** children not in education but aged 5 to 15, coded as students; government training 
*** and industral action as employees; there are no other or farmers as in previous releases

	sum age80 if age80<${SPAm} & les==4 // no cases 

**************************
*  lcs - LM Civil Servant 

* sic - Standard Industrial Classification 2007
**************************
	gen lcs=sic==84	      // 84 "Public admin, defence, social security"
	replace lcs=0 if les!=3
	tab2 les lcs if adult==1
	
*** NOTE: if Standard Industrial Classification=Public admin, defence, social security
**********************
*  lfs - LM Firm Size (for first job only - and anyway FRS records it only for first job)

* jobtype - Job Type	
*	1	First job
*	2	Second job
*	3	Third job
* emplany - How many people do you employ at the place where you work?
* numep - How many people work for your employer
**********************
	sort sernum person
	save temp_lab, replace 
	use sernum person jobtype numemp emplany etype using "$data/job.dta",clear
	de jobtype numemp emplany etype
	la list JOBTYPE NUMEMP EMPLANY ETYPE 
	recode emplany 1/4=1 5/8=2 9=3, ge(empany)	
	ta empany emplany
	recode numemp 1/4=1 5/8=2 9=3, ge(numempl) 
	keep if jobtype==1		// first job
		inspect empany numemp
		count if empany==-1 & numemp==-1
	gen lfs=0
	replace lfs=empany  if emplany>0 & emplany!=.
	replace lfs=numempl  if numempl>0 & numempl!=. & lfs==0
	replace lfs=12 if  lfs==1			/* 1 to 24 */
	replace lfs=262 if lfs==2			/* 25 to 499 */
	replace lfs=500 if lfs==3			/* 500 or more */
	keep sernum person lfs
	sort sernum person
	merge m:m sernum person using temp_lab
	if ${use_assert} assert _merge!=1
	replace lfs=0 if (_merge==2|(les!=2 & les!=3))
	drop _merge
	ta lfs, m 

********************************************************
*  lindi - Standard Industrial Classification 2007
* 1 Agriculture, Forestry and Fishing 
* 2 Mining and Quarrying 
* 3 Manufacturing 
* 4 Electricity, Gas, Steam and Air Conditioning Supply 
* 5 Water Supply 
* 6 Construction 
* 7 Wholesale and Retail Trade 
* 8 Transportation and Storage 
* 9 Accommodation and Food Service Activities 
* 10 Information and Communication 
* 11 Financial and Insurance Activities 
* 12 Real Estate Activities 
* 13 Professional, Scientific and Technical Activities 
* 14 Administrative and Support Service Activities 
* 15 Public Administration and Defence 
* 16 Education 
* 17 Human Health and Social Work Activities 
* 18 Arts, Entertainment and Recreation 
* 19 Other Service Activities 
* 20 Activities of Households 
* 21 Activities of Extraterritorial Organisations and Bodies 
********************************************************
gen lindi = -1
replace lindi = 1 if sic>=1 & sic<=3
replace lindi = 2 if sic>=5 & sic<=9
replace lindi = 3 if sic>=10 & sic<=33
replace lindi = 4 if sic==35
replace lindi = 5 if sic>=36 & sic<=39
replace lindi = 6 if sic>=41 & sic<=43
replace lindi = 7 if sic>=45 & sic<=47
replace lindi = 8 if sic>=49 & sic<=53
replace lindi = 9 if sic>=55 & sic<=56
replace lindi = 10 if sic>=58 & sic<=63
replace lindi = 11 if sic>=64 & sic<=66
replace lindi = 12 if sic==68
replace lindi = 13 if sic>=69 & sic<=75
replace lindi = 14 if sic>=77 & sic<=82
replace lindi = 15 if sic==84
replace lindi = 16 if sic==85
replace lindi = 17 if sic>=86 & sic<=88
replace lindi = 18 if sic>=90 & sic<=93
replace lindi = 19 if sic>=94 & sic<=96
replace lindi = 20 if sic>=97 & sic<=98
replace lindi = 21 if sic>=99 & sic!=.

***************************************************************
*  liwwh - In work : Work history (length of time in months) 

* ptwk - Years in part-time work
* ftwk - Years in full-time work
***************************************************************
	inspect ptwk ftwk if adult==1
	replace ptwk=0 if ptwk<0 | ptwk==.		
	replace ftwk=0 if ftwk<0 | ftwk==.		
	gen liwwh=ptwk+ftwk
	replace liwwh=0 if adult==0
	replace liwwh=liwwh*12 /*number of months*/

	
****************************************************************
*  lcwnm - Tenure at current job (length of time in months)  

*  les - Economic Status
*  0: children in pre-school or younger
*  1: farmer 
*  2: employer or self-employed
*  3: employee
*  4: pensioner
*  5: unemployed
*  6: student
*  7: inactive 
*  8: sick or disabled
*  9: other

* currjobm -- Months since started current job                         
****************************************************************
gen lcwnm = -1 if (les==0 | les> 3) | currjobm==.     /*not applicable or missing*/
replace lcwnm = currjobm  if (les==2|les==3) & currjobm>=0 & currjobm<. 

*************************************
*  loc - Occupation (ISCO 1-Digit)
*  1: Managers, Directors and Senior Officials
*  2: Professional Occupations
*  3: Associate Prof. and Technical Occupations
*  4: Admin and Secretarial Occupations
*  5: Skilled Trades Occupations
*  6: Caring, Leisure and Other Service Occupations
*  7: Sales and Customer Service
*  8: Process, Plant and Machine Operatives
*  9: Elementary Occupations
* -1: not applicable / missing

*soc2020	-- Standard Occupational Classification
*   0    Undefined
*	1000 Managers Directors & Senior Officials	
*	2000 Professional Occupations	
*	3000 Associate Prof. & Technical Occupations	
*	4000 Admin & Secretarial Occupations
*	5000 Skilled Trades Occupations	
*	6000 Caring leisure and other service occupations
*	7000 Sales & Customer Service
*	8000 Process, Plant & Machine Operatives	
*	9000 Elementary Occupations	
*************************************
gen loc = -1 // n/a
replace loc = soc2020/1000 if soc2020!=. & soc2020!=-1
replace loc = -1 if loc==0
tab loc

***************************************************
*  lowas - Whether actively looking for job

* lktrain- Whether looking for gov training scheme in those four weeks (1 yes, 2 no)
* lkwork - Whether looking for work in those four weeks (1 yes, 2 no)
***************************************************
	gen lowas=(empstatb==7 & (lktrain==1 | lkwork==1))

***************************************************************************
*  lcr01, lcr02 - Caring for dependent person (for Income Support purposes)

* hourtot - Total hours providing informal care	
*	0	0 hours per week
*	1	0-4 hours per week
*	2	5-9 hours per week
*	3	10-19 hours per week
*	4	20-34 hours per week
*	5	35-49 hours per week
*	6	50-99 hours per week
*	7	100 or more hours per week
*	8	Varies - under 20 hours per week
*	9	Varies - 20-34 hours per week
*	10	Varies - 35 hours a week or more
* carefr - Whether Friends looked after outside the HH (1 yes, 2 no)
* careot - Whether Others outside HH looked after (1 yes, 2 no)
* wholoo01 - wholoo14 - Whether care given by person 1 - 14 (1 yes, 2 no) 
* wageben8 - In receipt: Carer's Allowance (1 yes, 2 no)
***************************************************************************
*** CARER FOR Income Support PURPOSES: 
/*	The rule says: whether (you receive ICA and provide care for more than 35 hours per week) OR
	(whether you provide care to somebody receiving AA or DLA). 
	However, for those providing care to people outside household, we do not observe whether care 
	recipient receives AA or DLA. So create the variable lcr=1 if
receives ICA (in this case should be providing more than 35 hours per week) OR 
provides care to somebody inside hh receiving AA/DLAcare middle or above OR
provides care to somebody outside hh for more than 35 hours per week
*/

	de hourtot carefr careot
    tab hourtot 
	tab carefr 
	tab careot
	replace hourtot=0 if adult==0| hourtot<0		/*missing imputed as zero hours of care provided*/
	gen carer= hourtot>0 					/*for now carer if any positive amount of hours provided*/
	ta carer
	label var carer "informally cares for somebody in or out hh"

	gen carer_out=((carefr==1|careot==1) & carer==1)
	label var carer_out "informally cares for somebody in or out hh"
	drop careot carefr
	sort sernum person
	save temp, replace					

	*** merge info on the cared ones, to identify those in receipt of AA/DLA by the cared one.
	*** this can be done only for cared ones in the hh, not outside  

		use $data/care, clear				/* records of those receiving care, in or out the hh*/
		rename needper person
		ta person, nol
		keep if person < 9
		sort sernum person
		save temp2, replace				/*dataset of individuals in hh receiving care*/
		des,s
			use sernum person adult age80 age sex using individual, clear
			sort sernum person
			merge m:m sernum person using temp2
			ta _merge
			keep if _merge==3
			drop _merge
			gen type1=(adult==0) /*care recipient: child*/
			gen type2=(adult==1 & ((age80<$SPAw & sex==2)|(age80<$SPAm & sex==1))) /*care recipient: adult*/
			gen type3= (adult==1 & ((age80>=$SPAw & sex==2)|(age80>=$SPAm & sex==1))) /*care recipient: elderly*/
			sort sernum person
		save temp2, replace				/*dataset of individuals in hh receiving care, age added*/

		use sernum person benefit benamt using $data/benefits, clear
		de benefit benamt
		keep if benefit==1|benefit==12  //1=dla (self-care) 12=attendance allowance 
		sort sernum person				/*mantain benefit level records as need to use amount below*/
		merge m:m sernum person using temp2
		ta _merge
		keep if _merge==3 /*receiving care and either AA or DLA (Even claim only)*/
		drop _merge
		ta person
		ta benefit

		gen makeselig =(benefit==12 |(benefit==1 & benamt>=$dlac_m))
		drop benefit benamt
		duplicates drop 					/*now back to individual level for receipeints of care*/		
		label var makeselig "whether person-receiving care by hh member- is in receipt of AA or DLAC at least middle has claimed"

		***whether the cared one makes person n eligible for carer premium	
		de wholoo*
		forval num = 1/9	{
			gen eligcarer`num'=(wholoo0`num'==1)	
			replace eligcarer`num'=0 if makeselig==0
				gen type1_`num'=(wholoo0`num'==1) // care recipient: child
					replace type1_`num'=0 if type1==0
				gen type2_`num'=(wholoo0`num'==1) // care recipient: adult
					replace type2_`num'=0 if type2==0
				gen type3_`num'=(wholoo0`num'==1) // care recipient: elderly
					replace type3_`num'=0 if type3==0
			}
		forval num = 10/14	{
			gen eligcarer`num'=(wholoo`num'==1)
			replace eligcarer`num'=0 if makeselig==0
				gen type1_`num'=(wholoo`num'==1)
					replace type1_`num'=0 if type1==0
				gen type2_`num'=(wholoo`num'==1)
					replace type2_`num'=0 if type2==0
				gen type3_`num'=(wholoo`num'==1)
					replace type3_`num'=0 if type3==0
		}
		keep sernum person eligcarer* type1_* type2_* type3_*
		sort sernum person
		collapse (max) eligcarer* type1_* type2_* type3_*, by(sernum)	/*individual info is in wide format, 1 record per hh*/
		sort sernum
		save temp3, replace
		erase temp2.dta

*** merge info in lab dataset being created		
	use temp, clear
	sort sernum 
	merge m:m sernum using temp3
	ta _merge
	drop _merge
	forval num = 1/14	{
		recode eligcarer`num' type1_`num' type2_`num' type3_`num' (.=0)
	}
	erase temp3.dta 

*** finally generate the variable - as a dummy (lcr01) 
	de wageben8			// in receipt: invalid care allowance
	la list WAGEBEN8
	gen lcr01=0
	replace lcr01=1 if carer==1 & wageben8==1
	forval num = 1/14	{
		replace lcr01=1 if carer==1 & person==`num' & eligcarer`num'==1
	}
	ta hourtot
	replace lcr01=1 if carer_out==1 & (hourtot==5|hourtot==6|hourtot==7|hourtot==10)
	ta carer 
	ta carer_out
	ta lcr01		

*** finally generate the variable - as a categorical var reflecting care recipient's age (lcr02) 
	gen lcr02=0
	replace lcr02=3 if carer==1 & wageben8==1 
	forval num = 1/14	{
		replace lcr02=3 if carer==1 & person==`num' & eligcarer`num'==1
	}
	replace lcr02=3 if carer_out==1 & (hourtot==5|hourtot==6|hourtot==7|hourtot==10)
	tab2 lcr01 lcr02

	forval num = 1/14	{
		replace lcr02=1 if lcr02==3 & person==`num' & type1_`num'==1
		replace lcr02=2 if lcr02==3 & person==`num' & type2_`num'==1
	}
	drop elig* wageben8 hourtot carer carer_out type*
	tab2 lcr01 lcr02, m

*********************
*  lle - On leave (under UNPAID Maternity, Paternity or Parental leave: for IS eligibility conditions)

* abswk - Away from work for more than last 3 days (1 yes, 2 no)
* abswhy - Reason for your absence	
*	1	Pattern of shifts
*	2	Illness/accident
*	3	Holiday
*	4	Strike
*	5	Laid off
*	6	Maternity Leave
*	7	Paternity leave
*	8	Compassionate Leave
*	9	Parental Leave
*	10	Other
* abspay - Whether in receipt of full/part pay	
*	1	Full pay from employer
*	2	Part pay or made-up pay (more than or equal to 50% of normal
*	3	Part pay or made-up pay (less than 50% of normal pay)
*	4	No pay
*********************
	de abswk abswhy abspay
	tab abswk 
	tab abswhy 
	tab abspay
	gen lle=(abswk==1 & (abswhy==6|abswhy==7|abswhy==9) & abspay==4)

keep sernum person les lcs lfs lindi liwwh lcwnm loc* lowas lcr* lle 
sort sernum person
save lab, replace
des
cap log close
