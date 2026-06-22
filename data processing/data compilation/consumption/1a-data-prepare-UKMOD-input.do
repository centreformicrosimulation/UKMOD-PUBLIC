***************************************************
*** LCF-FRS imputation of consumption data
*** 10. Data preparation - FRS
* LAST UPDATE:          15 June 2026 DP 
***************************************************


************************
*** UKMOD input data ***
************************

import delimited ${UKMOD_a_dataset}, clear 


* Household Reference Person (HRP)
	gen d_hrp_ukmod = (dhr == 1)

* Education of HRP
	recode deh (0 1 2 = 1) (3 4 = 2) (5 = 3), gen(education_hrp_ukmod)
	replace education_hrp_ukmod = . if !d_hrp_ukmod
	replace education_hrp_ukmod = . if !d_hrp_ukmod

	label define lab_education 1 "Low" 2 "Medium" 3 "High"
	label values education_hrp_ukmod lab_education

* Ethnicity of HRP
	recode dot (-1 = .) (1/4 = 1) (5/8 = 2) (9/13 = 3) (14/16 = 4) (17/18 = 5), gen(ethnicity_hrp_ukmod) 
	replace ethnicity_hrp_ukmod = . if !d_hrp_ukmod

* Activity status (18+) of HRP
	recode les (1 2 3 = 3)(7 8 = 7), gen(activity_ukmod)
	gen d_employed_ukmod = (activity_ukmod == 3)
	gen d_retired_ukmod = (activity_ukmod == 4)
	gen d_unemployed_ukmod = (activity_ukmod == 5)
	gen d_student_ukmod = (activity_ukmod == 6)
	gen d_inactive_ukmod = (activity_ukmod == 7)

	bysort idhh: egen n_employed_ukmod = total(d_employed_ukmod)
	bysort idhh: egen n_retired_ukmod = total(d_retired_ukmod)
	bysort idhh: egen n_unemployed_ukmod = total(d_unemployed_ukmod)
	bysort idhh: egen n_students_ukmod = total(d_student_ukmod)
	bysort idhh: egen n_inactive_ukmod = total(d_inactive_ukmod)

	rename activity_ukmod activity_hrp_ukmod
	replace activity_hrp_ukmod = . if !d_hrp_ukmod
	replace activity_hrp_ukmod = . if dag < 18

	label define lab_activity 3 "Employed" 4 "Retired" 5 "Unemployed" 6 "Student" 7 "Inactive"
	label values activity_hrp_ukmod lab_activity

* Disability
	gen d = (bdisc > 0 | bdimb > 0 | bdisv > 0)		// Self-care, Mobility, and Severe disability allowance
	bysort idhh: egen d_disability_ukmod = max(d)
	drop d

* Gender of HRP
	gen d_male_hrp_ukmod = (dgn == 1 & d_hrp_ukmod)

* Age of HRP
	gen age_hrp_ukmod = dag if d_hrp_ukmod
	recode age_hrp_ukmod (15/19 = 15) (20/24 = 20) (25/29 = 25) (30/34 = 30) (35/39 = 35) (40/44 = 40) (45/49 = 45) ///
		(50/54 = 50) (55/59 = 55) (60/64 = 60) (65/69 = 65) (70/74 = 70) (75/79 = 75), gen(ageclass_hrp_ukmod)

* Household composition
	bysort idhh: gen hh_size_ukmod = _N
	gen d_ch_01 = (dag < 2)
	gen d_ch_24 = (dag >= 2 & dag < 5)
	gen d_ch_517 = (dag >= 5 & dag < 18)
	bysort idhh: egen n_ch_01_ukmod = total(d_ch_01) 	// Number of children age under 2 
	bysort idhh: egen n_ch_24_ukmod = total(d_ch_24)		// Number of children age 2 and under 5
	bysort idhh: egen n_ch_517_ukmod = total(d_ch_517)	// Number of children age 5 and under 18
	bysort idhh: gen n_children_ukmod = n_ch_01_ukmod + n_ch_24_ukmod + n_ch_517_ukmod
	drop d_ch*

* Gross (market) income  
	local p = pct
	gen income_gross_pers = yem + yiytx + yiynt + yptmp + yot01 + yprtx + yprnt + ypp + yptot + yse 
	bysort idhh: egen income_gross_ukmod = total(income_gross_pers)
	xtile inc_gross_pct_ukmod = income_gross_ukmod, n(`p')

* Disposable income 
	local p = pct
	bysort idhh: egen income_net_ukmod = total(yds)
	xtile inc_net_pct_ukmod = income_net_ukmod, n(`p')

* Region
	gen region_ukmod = drgn
	replace region_ukmod = region_ukmod - 1 if region_ukmod >= 4

* Tenure
	recode amrtn(1 = 3) (2 = 4) (3 4 = 2) (5 6 = 1), gen(tenure_ukmod)

	label define lab_tenure 1 "Social" 2 "Rent" 3 "Mortgage" 4 "Owned outright"
	label values tenure_ukmod lab_tenure

* Save final dataset
	keep if d_hrp_ukmod
	save "$data\ukmod.dta", replace
