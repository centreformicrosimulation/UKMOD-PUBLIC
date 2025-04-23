***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         10_Earnings_Hours.do
* DESCRIPTION:          Create employment-related variables 
* INPUT FILE:           individual, househol, job
* OUTPUT FILE:          earn_hours
* NEW VARs:
*                       - yem           Income - Employment
*                       - yse           Income - Self-Employment
*						- yseny			How long in self-employment (years)
*                       - lhw00         Hours in work in employment
*                       - lhw01         Hours in work in self-employment
*                       - lhw         	Total hours in work
*						- yot01			Income - other taxable income
*						- tpcpe			National Inusrance Contributions - Pensions
*						- tpceepx		National Inusrance Contributions - private pension contribution rate
* LAST UPDATE:          26/06/2024
***************************************************************************************
cap log close 
log using "${log}/10_Earnings_Hours.log", replace
use sernum person seincam2 chamtern allow2 allpay2 royal* royyr* chamttst inearns age80 using individual, clear
save earn_hours, replace
de

use sernum intdate using $data/househol, clear	/*add interview date info from hh dataset*/
	sort sernum
	save temp, replace
use sernum person working jobaway empstati inearns using individual, clear
	sort sernum
	merge sernum using temp
	assert _merge==3
	drop _merge
	sort sernum person
	save temp, replace
use $data/job, clear
	sort sernum person
	merge sernum person using temp
	keep if _merge==3
	drop _merge
	erase temp.dta
	
***************************************************************
*** keep sample of employees
* etype - Describe your employment situation	
*	1	Employee
*	2	Running a business/prof. practice
*	3	Partner in a business/practice
*	4	Working for myself
*	5	A Sub-Contractor (includes CIS5/6)
*	6	Doing freelance work
*	7	Self employed in some other way
* working - Whether did any paid work in last week (1 yes, 2 no)
* jobaway - Whether away from work in last 7 days (1 yes, 2 no)
****************************************************************
	keep if etype==1		
	
*****************************************************************
* 	lhw00 - number of working hours in employment

* totus1 - Usual Hrs Wrkd Week - no wrk overtime
* usuhr - Usual Hours Worked a Week Excluding O/T
* pothr - hours of paid overtime worked per week
* inearns - Adult - Gross Income from Employment
* everot - Whether any Paid or Unpaid Overtime (1 yes, 2 no)
*****************************************************************
	de totus1 usuhr pothr everot deduc1	
	gen lhw00=totus1 if everot==2 & inearns>0		
		replace lhw00= usuhr + pothr if everot==1 & inearns>0

************************************************
* 	yem - employee earnings

* inearns - Adult - Gross Income from Employment
************************************************		
	gen yem = 0
	replace	yem = inearns*(52/12) // gross income from employment from all job records; used in HBAI
	bys sernum person: replace yem = 0 if _n>1 // replace by 0 for second and any other job

************************************************
* 	tpcpe - pension contribution

* deduc1 - Amount deducted:pensions/superannuation
************************************************	
	gen tpcpe=0									/*pension contribution*/
		replace tpcpe=deduc1*(52/12) if deduc1>0

	inspect lhw00 yem tpcpe 
	
* sum up earnings, pension contributions and hours by person
	collapse (sum) lhw00 yem tpcpe, by(sernum person) 
	sort sernum person
	merge sernum person using earn_hours				/*back to individual level data*/
	assert _merge!=1
	drop _merge
	tab lhw00
	replace lhw00=int(lhw00) 
	tab lhw00
	foreach var in lhw00 yem tpcpe {
	replace `var'=0 if `var'==.
	}

***check/adjust/impute hours of work and employment income, for currently employed 
	count if yem==0 & lhw00>0
	replace lhw00=0 if yem==0 & lhw00>0	/*replace hours=0 if no employment income*/
	count if (yem>0) & lhw00==0	/*need to impute hours of empl. work if employment income*/
	gen int temp=(yem)/lhw00 if (yem>0) & lhw00>0	
	su temp
	replace lhw00 =(yem)/r(mean) if (yem>0) & lhw00==0
	count if lhw00>0 & lhw00<1
	replace lhw00=1 if lhw00>0 & lhw00<1
	replace lhw00=int(lhw00)
	if ${use_assert} assert yem==0 if lhw00==0	
	if ${use_assert} assert yem>0 if lhw00>0	
	drop temp

	sort sernum person
	save earn_hours, replace

*********************************************************
*** keep sample of self-employed
* 	lhw01 - number of working hours in self-employment
*********************************************************

	use $data/job, clear
	drop if etype==1
	gen lhw01=totus1 if everot==2
	replace lhw01= usuhr + pothr if everot==1
		
	collapse (sum) lhw01, by(sernum person) 
		sort sernum person
		merge sernum person using earn_hours
		assert _merge!=1
		drop _merge
		replace lhw01=int(lhw01)
		tab lhw01
		replace lhw01=0 if lhw01==.
	sort sernum person
	save earn_hours, replace

*******************************************************************************************
*	yseny: number of years running business/in self-employment

* sejblong - How many years running business/in self emp job 
* sejbmths -How many months running business/in self employed job
*	- recorded if running current business for less than 2 years 
*******************************************************************************************
use $data/job, clear
sort sernum person sejblong sejbmths
* if someone has more than one self-employment job, keep the observation with the longest work history
by sernum person: keep if _n==_N 
gen yseny = sejblong 
replace yseny = 1 + sejbmths/12 if sejblong==1 & sejbmths>0 & sejbmths!=.
replace yseny = sejbmths/12 if sejblong==0 & sejbmths>0 & sejbmths!=.
replace yseny = 0 if sejblong<0 & sejbmths<0 // if n/a or missing, set to 0

merge m:m sernum person using earn_hours
assert _merge!=1
drop _merge
recode yseny (.=0)
sort sernum person
save earn_hours, replace	

count if yseny>age80 
if (r(N) > 0) noi display in y "No of observations with person's age smaller than number of years since current business is running: " r(N)
if (r(N) > 0) noi display in r "MUST BE IMPUTED!" 

replace yseny = age80 if yseny>age80 // top code with person's age
count if yseny> (age80-15) & yseny!=0 
if (r(N) > 0) noi display in y "No of observations where current business has been running before person turned 15: " r(N)
* Unclear what to do with these cases. 
* It may be misreporting (e.g. people reporting number of weeks/months instead of years). 
* Or may be this is a family business and people are reporting for how many years in total it has been running.


************************************************************
*	yse - self-employment earnings (leave negative as such)

* seincam2 - Adult - Gross Earn from Self-Emp Opt 2
************************************************************
	de seincam*
	gen yse=seincam2*(52/12)
	replace yse=0 if seincam2==.	
	//replace yse = seincamt*(52/12) if sernum==8069 & person==1 // FRS 2018/19: FRS team confirmed earnings recorded in seincam2 of this individual are incorrect and should be revised using value of seincamt instead.
* adjustment/imputation for coherence hours/income
	count if yse==0 & lhw01>0			/*FRS 2022/23: 183 cases: accept zero profit with positive hours self employment*/
	count if yse>0 & lhw01==0			/*0 cases: need to impute hours of s.e. work if self empl. income*/
		
	gen int temp=yse/lhw01 if yse!=0 & lhw01>0	
	su temp
	replace lhw01 =yse/r(mean) if yse!=0 & lhw01==0	
	*replace lhw01=round(lhw01)
	replace lhw01=ceil(lhw01) //DP: use instead of round because lhw01 for 1 case was <1
	replace yse=0 if lhw01==0 & yse<0 /*DP: 2022/23: one obs with negative self-employment income and zero hours*/
	if ${use_assert} assert lhw01!=0 if yse!=0  
		drop temp	
	
***************************************************
*	lhw - total hours of work: in employment + self-employment
****************************************************	
	de lhw*
	gen int lhw=lhw00 + lhw01
	if ${use_assert} assert lhw01>0 if (yem==0 & yse==0 & lhw>0)	
	sort sernum person
	save earn_hours, replace

***************************************************
*	yot01 - other taxable income

* ojnow - Whether currently doing odd job (1 yes, 2 no)
* ojamt - Amount received from odd job
* chamtern - Earnings received from spare time job
* allpay2 - Amount of allowance: organisation
* allow2 - Regular allowance: organisation (1 yes, 2 no)
* royal2 - Royalties -land/books/performances 12mth (1 yes, 2 no)
* royal3 - Income as sleeping partner in last 12mth (1 yes, 2 no)
* royal4 - Overseas pension in last 12 months (1 yes, 2 no)
* royyr2 - Amount of royalties
* royyr3 - Amount of income as sleeping partner
* royyr4 - Amount of overseas pension
* chamttst - Income received from a Trust
***************************************************
	use sernum person ojamt ojnow using $data/oddjob, clear
	de
	inspect ojamt if ojnow==1
	gen yodd=0
	replace yodd=ojamt*(52/12) if ojnow ==1
	collapse (sum) yodd, by(sernum person)
	sort sernum person
	merge sernum person using earn_hours
	ta _merge
	drop _merge
	de yodd chamtern allow* roy*
	replace yodd=0 if yodd==.
	inspect yodd
gen yot01=0
replace yot01=yot01+yodd
	inspect chamtern
replace yot01 = yot01 + (chamtern*(52/12)) if chamtern>0 & chamtern!=.
	inspect allpay2 if allow2==1
replace yot01=yot01+ allpay2*(52/12) if allow2==1
	inspect royyr2 if royal2==1
	inspect royyr3 if royal3==1
	inspect royyr4 if royal4==1
replace yot01=yot01+ (royyr2*(52/12)) if royal2==1
replace yot01=yot01+ (royyr3*(52/12)) if royal3==1
replace yot01=yot01+ (royyr4*(52/12)) if royal4==1
replace yot01=yot01+ (chamttst*(52/12)) if chamttst>0 & chamttst!=.
	inspect yot01

************************************************
* tpceepx * private pension contribution rate
************************************************
	de tpcpe
	gen tpceepx = tpcpe / yem
	replace tpceepx = 0 if tpceepx == .
	sum tpceepx if tpceepx > 0, d
	replace tpceepx = r(p99) if tpceepx > r(p99)
sum tpceepx if tpceepx > 0, d

keep sernum person yem* lhw lhw00 lhw01 yse* yot01 tpcpe tpceepx 
sort sernum person
save earn_hours, replace
des

cap log close
