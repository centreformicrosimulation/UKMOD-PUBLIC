***************************************************
*** LCF-FRS imputation of consumption data
*** 10. Data preparation
* LAST UPDATE:          15 June 2026 DP 
***************************************************

***********
*** LCF ***
***********
// 'case' is the identifier of the household
// 'Person' is the identifier of the person

*** A *** Person file
*--------------------
	use ${LCF_ind_dataset}, clear
	//keep case Person a005p a012p A003 A007 A010 A015 A206 B325 B403 B405 B418 P016 P035 P049p 
    keep case person a005p /*a012p*/ a003 a007 a010 a015 a206 b325 b403 b405 b418 p016 p035 /*p049p*/
* Household Reference Person
	gen d_hrp_lcf = (a003 == 1)

* Education
	/*

			   A007: Current full time education |      Freq.     Percent        Cum.
	----------------------------------------+-----------------------------------
	0. 								Not recorded |      9,863       76.80       76.80
	1. 				 Not yet attending education |        290        2.26       79.06
	2. 	 Nursery school/nursery class/playgroup/ |        298        2.32       81.38
	3.   State-run/maintained primary school / m |      1,021        7.95       89.33
	4.                  State run special school |         42        0.33       89.66
	5.   Middle deemed secondary, secondary/gram |        697        5.43       95.09
	6.   Non-advanced further education/sixth fo |        239        1.86       96.95
	7.            Any private/Independent school |         73        0.57       97.52
	8.   University/polytechnic, any other highe |        294        2.29       99.81
	9.                            Home Schooling |         25        0.19      100.00
	*/

	gen education_hrp_lcf = .
	// In education
	replace education_hrp_lcf = 1 if (a007 >= 1 & a007 <= 5) | a007 == 9 
	replace education_hrp_lcf = 1 if a007 >= 6 & a007 <= 7
	replace education_hrp_lcf = 2 if a007 == 8
	// Not in education
	replace education_hrp_lcf = 1 if a010 > 0 & a010 < 18
	replace education_hrp_lcf = 2 if a010 >= 18 & a010 < 21
	replace education_hrp_lcf = 3 if a010 >= 21 & a010 < 90
	replace education_hrp_lcf = 1 if a010 == 97					// None
	// Impute missing values with median for the age group
	recode a005p (15/19 = 15) (20/24 = 20) (25/29 = 25) (30/34 = 30) (35/39 = 35) (40/44 = 40) (45/49 = 45) (50/54 = 50) ///
		(55/59 = 55) (60/64 = 60) (65/69 = 65) (70/74 = 70) (75/79 = 75), gen(age_gr)
	bysort age_gr: egen mdeh = median(education_hrp_lcf)
	replace education_hrp_lcf = mdeh if education_hrp_lcf ==.
	drop age_gr mdeh

	replace education_hrp_lcf =.  if !d_hrp_lcf

	label define lab_education 1 "Low" 2 "Medium" 3 "High"
	label values education_hrp_lcf lab_education

	gen edu_high_hrp_lcf = (education_hrp_lcf == 3)

* Ethnicity
    gen ethnicity_hrp_lcf=0 
	*recode a012p (10 = 5), gen(ethnicity_hrp_lcf)
	/*
					 White |      5,178       91.94       91.94
				Mixed race |         64        1.14       93.08
	Asian or Asian British |        248        4.40       97.48
	Black or Black British |         75        1.33       98.81
		Other ethnic group |         67        1.19      100.00
	*/

* Activity status (18+)
	gen d_employed_lcf = (a206 >=1 & a206 <= 3)
	gen d_retired_lcf = (p035 == 1 /*| P049p > 0*/) & d_employed_lcf == 0
	gen d_unemployed_lcf = (a206 == 4) & d_retired_lcf == 0
	gen d_student_lcf = (a015 == 3) & d_employed_lcf == 0 & d_retired_lcf == 0

	gen n = d_employed_lcf + d_unemployed_lcf + d_retired_lcf + d_student_lcf
	assert n <= 1 
	drop n

	gen d_inactive_lcf = (!d_employed_lcf & !d_retired_lcf & !d_unemployed_lcf & !d_student_lcf)
	assert d_employed_lcf + d_retired_lcf + d_unemployed_lcf + d_student_lcf + d_inactive_lcf == 1

	gen activity_hrp_lcf = .
	replace activity_hrp_lcf = 3 if d_employed_lcf 
	replace activity_hrp_lcf = 4 if d_retired_lcf
	replace activity_hrp_lcf = 5 if d_unemployed_lcf
	replace activity_hrp_lcf = 6 if d_student_lcf
	replace activity_hrp_lcf = 7 if d_inactive_lcf

	replace activity_hrp_lcf = . if d_hrp_lcf == 0	// keep info for HRP only
	replace activity_hrp_lcf = . if a005p < 18

* Disability
	// Disability living allowance (self care) | Disability living allowance (mobility) | Severe disablement 
	gen d_disability_lcf = (b403 > 0 | b405 > 0 | b418 > 0)	

	collapse (sum) ethnicity_hrp_lcf activity_hrp_lcf ///
		n_employed_lcf = d_employed_lcf n_unemployed_lcf = d_unemployed_lcf n_retired_lcf = d_retired_lcf n_students_lcf = d_student_lcf n_inactive_lcf = d_inactive_lcf ///
		(max) education_hrp_lcf edu_high_hrp_lcf d_disability_lcf, by(case) 

	label define lab_ethnicity 1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other"
	label values ethnicity_hrp_lcf lab_ethnicity

	label define lab_activity 3 "Employed" 4 "Retired" 5 "Unemployed" 6 "Student" 7 "Inactive"
	label values activity_hrp_lcf lab_activity

save "$data\lcf_pers_collapsed.dta", replace


*** B *** Household file
*-----------------------

	use ${LCF_hh_dataset}, clear
	merge 1:1 case using "$data\lcf_pers_collapsed.dta"
	assert _merge == 3
	drop _merge
	duplicates report case

* Gender of hh reference person (HRP)
	gen d_male_hrp_lcf = (sexhrp == 1)

* Age of HRP
	rename p396p age_hrp_lcf
	recode age_hrp_lcf (15/19 = 15) (20/24 = 20) (25/29 = 25) (30/34 = 30) (35/39 = 35) (40/44 = 40) (45/49 = 45) (50/54 = 50) ///
		(55/59 = 55) (60/64 = 60) (65/69 = 65) (70/74 = 70) (75/79 = 75), gen(ageclass_hrp_lcf) 

* Household composition
	rename a049 hh_size_lcf
	rename a040 n_ch_01_lcf 	// Number of children age under 2 
	rename a041 n_ch_24_lcf 	// Number of children age 2 and under 5
	rename a042 n_ch_517_lcf	// Number of children age 5 and under 18
	gen n_children_lcf = n_ch_01_lcf + n_ch_24_lcf + n_ch_517_lcf

* Gross normal weekly household income - anonymised (GBP)
	local p = pct
	gen income_gross_lcf = p344p * 52/12 * $CPI
	xtile inc_gross_pct_lcf = income_gross_lcf, n(`p')

* Normal weekly disposable household income - anonymised (GBP)
	local p = pct
	gen income_net_lcf = p389p  * 52/12 * $CPI
	xtile inc_net_pct_lcf = income_net_lcf, n(`p')
	
* Equivalised disposable income (GBP)
	local p = pct
	gen income_eq_lcf = eqincdop  * 52/12
	xtile income_eq_pct_lcf = income_eq_lcf, n(`p')	
		
* Region
	rename gorx region_lcf 

* Tenure
	recode a122 (1 2 8 = 1) (3 4 = 2) (5 6 = 3) (7 = 4), gen(tenure_lcf)
	label define lab_tenure 1 "Social" 2 "Rent" 3 "Mortgage" 4 "Owned outright"
	label values tenure_lcf lab_tenure

	/*
	1 -    LA (furnished unfurnished) |        358        6.36        6.36
	2 -Hsng Assn (furnished unfrnish) |        323        5.74       12.09
	3 -         Priv. rented (unfurn) |        675       11.99       24.08
	4 -      Priv. rented (furnished) |        109        1.94       26.01
	5 -           Owned with mortgage |      1,797       31.91       57.92
	6 -      Owned by rental purchase |         33        0.59       58.50
	7 -                Owned outright |      2,295       40.75       99.25
	8 -                     Rent free |         42        0.75      100.00
	*/


* COICOP expenditures (weekly, GBP)
	rename p601t c_food			// total food and non-alcoholic beverages
	rename p602t c_alcohol 		// alcoholic beverages, tobacco, and narcotics
	rename p603t c_clothing		// clothing and footwear
	rename p604t c_housing 		// housing, water, electricity, gas and other fuels
	rename p605t c_bills  // furnishing, HH equipment and routine maintanance of the house
	rename p606t c_health 		// health
	rename p607t c_transport	// transport
	rename p608t c_comms		// communication
	rename p609t c_recreation	// recreation and culture
	rename p610t c_education	// education
	rename p611t c_resthotels 	// resturants and hotels
	rename p612t c_miscell		// riscelaneous goods and sevices
	rename p620tp c_noncons 	// non-consumption expenditure
	rename p600t c_totorig		// COICOP: Total consumption expenditure
	
	foreach var in eqincdop c_food c_alcohol c_clothing c_housing c_bills c_health c_transport c_comms c_recreation c_education c_resthotels c_miscell c_noncons c_totorig {
	replace `var' = `var' * $CPI
	} 
	
	gen c_tot = c_food + c_alcohol + c_clothing + c_housing + c_bills + c_health + c_transport + c_comms + c_recreation ///
		+ c_education + c_resthotels + c_miscell + c_noncons
	
	sum income_net_lcf inc_gross_pct_lcf c_*
	
	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell noncons totorig tot" 
	foreach c of local cat {
		replace c_`c' = 0 if c_`c' < 0		// replace negative values with 0
		gen tag_`c' = (c_`c' > income_gross_lcf)	// tag cases when consumption > income
		quietly sum tag_`c'					// sum over all observations
		scalar tag = tag + r(sum)			// add the total count to scalar
	}
    sum tag*

* Expenditure shares of net income  
	gen w_net_food  		= c_food / income_net_lcf
	gen w_net_alcohol 		= c_alcohol / income_net_lcf
	gen w_net_clothing 		= c_clothing / income_net_lcf
	gen w_net_housing 		= c_housing / income_net_lcf
	gen w_net_bills			= c_bills / income_net_lcf
	gen w_net_health 		= c_health / income_net_lcf
	gen w_net_transport 	= c_transport / income_net_lcf
	gen w_net_comms			= c_comms / income_net_lcf
	gen w_net_recreation 	= c_recreation / income_net_lcf
	gen w_net_education		= c_education / income_net_lcf
	gen w_net_resthotels	= c_resthotels / income_net_lcf
	gen w_net_miscell 		= c_miscell / income_net_lcf
	gen w_net_noncons 		= c_noncons / income_net_lcf

	gen w_net_tot = w_net_food + w_net_alcohol + w_net_clothing + w_net_housing + w_net_bills + w_net_health + w_net_transport ///
		+ w_net_comms + w_net_recreation + w_net_education + w_net_resthotels + w_net_miscell + w_net_noncons

	mean w_*
	
	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell noncons" 
	foreach c of local cat {
		display "`c':"
		sum income_net_lcf if w_net_`c' < 0
	}
	foreach c of local cat {
		display "`c':"
		sum income_net_lcf if w_net_`c' > 1
	}

	sum income_net_lcf if w_net_tot < 0
	sum income_net_lcf if w_net_tot > 1


* Save final dataset
	save "$data\lcf.dta", replace
