***************************************************
*** LCF-UKMOD imputation of consumption data
*** 20. Data descriptive. This file compares statistics from UKMOD and LCF data.
* LAST UPDATE:          15 June 2026 DP 
***************************************************

version 14

* Append datasets
	use "$data\ukmod.dta", clear
	append using "$data\lcf.dta"
	save "$data\ukmod-lcf-compare.dta", replace

	//pause on

* Age oh HRP
	twoway (histogram age_hrp_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram age_hrp_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Age of HRP") ytitle("Frequency")
	   
	  // pause Press 'q+ENTER' to continue
	   
   
* Education of HRP
	twoway (histogram education_hrp_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram education_hrp_lcf, xlabel(1 "Low" 2 "Medium" 3 "High") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Education of HRP") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
* Gender of HRP    
	twoway (histogram d_male_hrp_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram d_male_hrp_lcf, xlabel(0 "Female" 1 "Male") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Gender of HRP") ytitle("Frequency")	  
	   
	  // pause Press 'q+ENTER' to continue

* Ethnicity of HRP
	twoway (histogram ethnicity_hrp_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram ethnicity_hrp_lcf, xlabel(1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Ethnicity of HRP") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	 
* Household size
	twoway (histogram hh_size_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram hh_size_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("HH size") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
* Number of children 
	twoway (histogram n_ch_01_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_ch_01_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of children 0-1 (inclusive)") ytitle("Frequency")
	   
	 //pause Press 'q+ENTER' to continue
	   
	twoway (histogram n_ch_24_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_ch_24_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of children 2-4 (inclusive)") ytitle("Frequency")
	   
	// pause Press 'q+ENTER' to continue
	   
	twoway (histogram n_ch_517_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_ch_517_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of children 5-17 (inclusive)") ytitle("Frequency")	
	   
	 // pause Press 'q+ENTER' to continue
	   
* Disability
	twoway (histogram d_disability_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram d_disability_lcf,  xlabel(0 "None" 1 "At least one") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
	   title("Presence of disabled persons in the HH") ytitle("Frequency")	
	   
	 // pause Press 'q+ENTER' to continue
	   
* Activity status
	twoway (histogram activity_hrp_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram activity_hrp_lcf, xlabel(3 "Employed" 4 "Retired" 5 "Unemployed" 6 "Student" 7 "Inactive") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Activity status of HRP") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue

	twoway (histogram n_employed_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_employed_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of employed persons") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
	twoway (histogram n_unemployed_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_unemployed_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of unemployed persons") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
	twoway (histogram n_retired_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_retired_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of retired persons") ytitle("Frequency")
	   
	  //pause Press 'q+ENTER' to continue
	   
	twoway (histogram n_students_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram n_students_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("No. of students") ytitle("Frequency")	   
	   
	 // pause Press 'q+ENTER' to continue
	   

* Gross income, raw
sum income_gross_ukmod income_gross_lcf, det

	twoway (histogram income_gross_ukmod if income_gross_ukmod > -5000 & income_gross_ukmod < 20000, lcolor(gs12) fcolor(gs12)) ///
       (histogram income_gross_lcf if income_gross_lcf > -5000 & income_gross_lcf < 20000, fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Gross income, raw") xtitle("GBP/month") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue

* Gross income, censored
	sum income_gross_lcf, det
	scalar income_gross_min_lcf = r(min)
	scalar income_gross_max_lcf = r(max)

	gen income_gross_ukmod2 = income_gross_ukmod
	replace income_gross_ukmod2 = income_gross_min_lcf if income_gross_ukmod2 < income_gross_min_lcf
	replace income_gross_ukmod2 = income_gross_max_lcf if income_gross_ukmod2 > income_gross_max_lcf
	sum income_gross_ukmod2, det

	twoway (histogram income_gross_ukmod2, lcolor(gs12) fcolor(gs12)) ///
       (histogram income_gross_lcf, fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Gross income, censored") xtitle("GBP/month") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
* Net income, raw
	sum income_net_ukmod income_net_lcf, det

	twoway (histogram income_net_ukmod if income_net_ukmod > -5000 & income_net_ukmod < 20000, lcolor(gs12) fcolor(gs12)) ///
       (histogram income_net_lcf if income_net_lcf > -5000 & income_net_lcf < 20000, fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Net  income, raw") xtitle("GBP/month") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue

* Net income, censored
	sum income_net_lcf, det
	scalar income_net_min_lcf = r(min)
	scalar income_net_max_lcf = r(max)

	gen income_net_ukmod2 = income_net_ukmod
	replace income_net_ukmod2 = income_net_min_lcf if income_net_ukmod2 < income_net_min_lcf
	replace income_net_ukmod2 = income_net_max_lcf if income_net_ukmod2 > income_net_max_lcf
	sum income_net_ukmod2, det

	twoway (histogram income_net_ukmod2, lcolor(gs12) fcolor(gs12))  ///
       (histogram income_net_lcf, fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Net income, censored") xtitle("GBP/month") ytitle("Frequency")	
	   
	 // pause Press 'q+ENTER' to continue
     
* Region
	twoway (histogram region_ukmod, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram region_lcf, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Region") xtitle("GOR-12") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
   
* Tenure
	twoway (histogram tenure_ukmod, xlabel(1 "Free" 2 "Rent" 3 "Mortgage" 4 "Owned outright") fraction lcolor(gs12) fcolor(gs12))  ///
       (histogram tenure_lcf, xlabel(1 "Free" 2 "Rent" 3 "Mortgage" 4 "Owned outright") fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "UKMOD") label(2 "LCF")) ///
       title("Housing tenure") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue
	   
* Consumption - levels
	twoway (histogram c_totorig, fraction lcolor(gs12) fcolor(gs12)) ///
       (histogram c_tot, fraction fcolor(none) lcolor(red)), ///
       legend(label(1 "total (P600t)") label(2 "total (sum)")) ///
       title("Consumption") xtitle("GBP/week") ytitle("Frequency")
	   
	 // pause Press 'q+ENTER' to continue

/* Consumption - shares of gross income
sum w_gross*

	preserve
	local cat "food alcohol clothing housing maintenance health transport comms recreation education resthotels miscell noncons" 
	foreach c of local cat {
		replace w_gross_`c' = 0 if w_gross_`c' < 0
		replace w_gross_`c' = 1 if w_gross_`c' > 1
		twoway (histogram w_gross_`c'), title("`c'") name(graph_w_gross_`c', replace)
	}

	graph combine graph_w_gross_food graph_w_gross_alcohol graph_w_gross_clothing graph_w_gross_housing graph_w_gross_maintenance graph_w_gross_health ///
	graph_w_gross_transport graph_w_gross_comms graph_w_gross_recreation graph_w_gross_education graph_w_gross_resthotels graph_w_gross_miscell ///
	graph_w_gross_noncons

	pause Press 'q+ENTER' to continue

	graph export "$graphs\consumption_shares_gross.png", as(png) replace
	restore
*/
	
* Consumption - shares of net income
	sum w_net*

	preserve
	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell noncons" 
	foreach c of local cat {
		replace w_net_`c' = 0 if w_net_`c' < 0
		replace w_net_`c' = 1 if w_net_`c' > 1
		twoway (histogram w_net_`c'), title("`c'") name(graph_w_net_`c', replace)
	}

	graph combine graph_w_net_food graph_w_net_alcohol graph_w_net_clothing graph_w_net_housing graph_w_net_bills graph_w_net_health ///
	graph_w_net_transport graph_w_net_comms graph_w_net_recreation graph_w_net_education graph_w_net_resthotels graph_w_net_miscell ///
	graph_w_net_noncons
	graph export "$graphs\consumption_shares_net.png", as(png) replace

	//pause Press 'q+ENTER' to continue
	
* Income gradient in original LCF data

	graph bar c_tot, over(inc_net_pct_lcf, label(labsize(vsmall)) gap(10)) ///
		ytitle("GBP/week", size(small)) ///
		ylabel(, labsize(vsmall)) ///
		title("total consumption") ///
		subtitle("income deciles", size(small) pos(6)) ///
		name(graph_c_tot, replace)
		
	graph export "$graphs\graph_c_tot_income_lcf.png", as(png) name("graph_c_tot") replace

	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell" 
	foreach c of local cat {
		graph bar c_`c', over(inc_net_pct_lcf, label(labsize(vsmall)) gap(10)) ///
			ytitle("GBP/week", size(small)) ///
			ylabel(, labsize(vsmall)) ///
			title("`c'") ///
			subtitle("income deciles", size(small) pos(6)) ///
			name(graph_`c', replace)
	}

	graph combine graph_c_tot graph_food graph_alcohol graph_clothing graph_housing graph_bills graph_health ///
		graph_transport graph_comms graph_recreation graph_education graph_resthotels graph_miscell /*graph_noncons*/
		
	graph export "$graphs\graph_c_cat_income_lcf.png", as(png) replace


//using equivalised income 	
	graph bar c_tot, over(income_eq_pct_lcf, label(labsize(vsmall)) gap(10)) ///
    ytitle("GBP/week", size(small)) ///
    yscale(range(0 1200)) ///
    ylabel(0(200)1200, labsize(vsmall)) ///
    title("total consumption, LCF") ///
    subtitle("income deciles", size(small) pos(6)) ///
    name(graph_c_tot2, replace)

	graph export "$graphs\graph_c_EQincome_lcf.png", as(png) name("graph_c_tot2") replace

	
	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell" 
	foreach c of local cat {
		graph bar c_`c', over(income_eq_pct_lcf, label(labsize(vsmall)) gap(10)) ///
			ytitle("GBP/week", size(small)) ///
			ylabel(, labsize(vsmall)) ///
			title("`c'") ///
			subtitle("income deciles", size(small) pos(6)) ///
			name(graph_`c', replace)
	}

	graph combine graph_food graph_alcohol graph_clothing graph_housing graph_bills graph_health ///
		graph_transport graph_comms graph_recreation graph_education graph_resthotels graph_miscell /*graph_noncons*/
		
	graph export "$graphs\graph_c_cat_EQincome_lcf.png", as(png) replace

* Determinants of consumption
	gen logc_tot = log(c_tot)
	gen age2_hrp_lcf = age_hrp_lcf^2
	gen income2_net_lcf = income_net_lcf^2

	xi: reg c_tot age_hrp_lcf age2_hrp_lcf d_male_hrp_lcf i.education_hrp_lcf ethnicity_hrp_lcf ///
		hh_size_lcf n_children_lcf n_ch_01_lcf n_ch_24_lcf n_ch_517_lcf d_disability_lcf	///
		i.activity_hrp_lcf n_employed_lcf n_unemployed_lcf n_retired_lcf n_students_lcf ///
		i.tenure_lcf income_net_lcf income2_net_lcf ///
		i.region_lcf 
