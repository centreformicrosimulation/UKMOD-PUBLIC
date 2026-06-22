***************************************************
*** LCF-FRS imputation of consumption data
*** 30. Compute Mahalanobis distance between obs. in LCF and FRS
* LAST UPDATE:          15 June 2026 DP 
***************************************************

* Install the ultimatch package (if not already installed)
//ssc install ultimatch, replace

*-----------------------
*** Prepare datasets ***
*-----------------------

* List of all variables used for matching
	global match_vars "inc_net_pct d_male_hrp education_hrp tenure region hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive ageclass_hrp age_hrp income_net" //ethnicity_hrp 
/*Note : ethninity currently excluded as missing in the provided data */
 
* Prepare FRS data
	use "$data\ukmod.dta", clear
	

	// rename variables
		foreach v of global match_vars {
			rename `v'_ukmod `v'
		}
	
	// create dummies
		//tabulate ethnicity_hrp, gen(d_ethnicity_hrp_)
		tabulate tenure, gen(d_tenure_)
		tabulate region, gen (d_region_)
	
	// generate treatment and count variable
	generate t = 1
	generate id_ukmod = _n
	
	// trim and save
	keep id_ukmod idhh t $match_vars d_*
	save "$data\ukmod-tmp.dta", replace

* Prepare LCF data
	use "$data\lcf.dta", clear
	
	// rename variables	
		foreach v of global match_vars {
			rename `v'_lcf `v'
		}
	
	// create dummies
		//tabulate ethnicity_hrp, gen(d_ethnicity_hrp_)
		tabulate tenure, gen(d_tenure_)
		tabulate region, gen (d_region_)
		
	// generate treatment and count variable
	gen t = 0
	generate id_lcf = _n
	
	// trim and save
	keep id_lcf case t $match_vars d_*
	save "$data\lcf-tmp.dta", replace

	append using "$data\ukmod-tmp.dta"
	
* Create high education dummy
	gen edu_high_hrp = (education_hrp == 3)	

* Save dataset
	save "$data\ukmod-lcf.dta", replace

*-----------------------
*** Matching routine ***
*-----------------------

// Strategy: 
// Round    1: Start with highest number of exact matching variables, using nearest neighbour only for income
// Rounds 2-4: Then, move integer variables from exact matching to minimum distance matching.
// Rounds 5-9: Further remove variables from exact matching

	use "$data\ukmod-lcf.dta", clear
		
* Initialise variables and files
	gen id_match =.		// match id
	gen w_match =.		// math weight
	gen d_match =.		// match distance
	
	copy "$data\Matching_stats_template.xlsx" "$data\Matching_stats.xlsx", replace
	putexcel set "$data\Matching_stats.xlsx", modify
	count if id_ukmod !=.					// Observations to be matched
	putexcel D1 = (`r(N)') //, nformat(number)	
	
* Programs
	capture program drop update_match
	program define update_match

		args round
		display "Round: `round'"
		
		// Max distance allowed when matching (can be overwritten at the different matching rounds)
		scalar trim = 5

		* Matching	
		if(`round' == 1) {
			ultimatch $dist_vars, exact($exact_vars) treated(t) rank copy
		} 
		else {
			ultimatch $dist_vars if id_match ==., exact($exact_vars) treated(t) rank mahalanobis copy
		}
		
		* Check matching results
		tab _copy
		tab _weight

		* Summary stats
		
		local row = `round'+2

		// Store percentiles as scalars
		sum _distance, det
		scalar p5 = r(p5)
		scalar p10 = r(p10)
		scalar p25 = r(p25)
		scalar p50 = r(p50)
		scalar p75 = r(p75)
		scalar p90 = r(p90)
		scalar p95 = r(p95)
		scalar max = r(max)

		// Write summary stats on xls file (shame to Stata that does not allow to do this in one step only)
		putexcel F`row' = (p5) //, nformat(number_d2)
		putexcel G`row' = (p10) //, nformat(number_d2)
		putexcel H`row' = (p25) //, nformat(number_d2)
		putexcel I`row' = (p50) //, nformat(number_d2)
		putexcel J`row' = (p75) //, nformat(number_d2)
		putexcel K`row' = (p90) //, nformat(number_d2)
		putexcel L`row' = (p95) //, nformat(number_d2)
		putexcel M`row' = (max) //, nformat(number_d2)

		count if id_lcf !=.							// Total LCF matchable observations				
		
		count if _match ==. & id_lcf !=.			// Unmatched LCF observations		
		
		count if id_match ==. & id_ukmod !=.		// Total matchable UKMOD observations	
		putexcel D`row' = (`r(N)') //, nformat(number)
		
		count if _match !=. & id_ukmod !=.			// Matched UKMOD observations
		putexcel B`row' = (`r(N)') //, nformat(number)
	
		* Trim match results 
		local trim = trim 							// F**K STATA!
		putexcel N`row' = (`trim') //, nformat(number_d2)
		
		twoway (histogram _distance if _distance < r(p95)), xline(`trim') title("Round `round'")		// Plot distance (0-95 percentiles only)
		replace _match =. if _distance > `trim'		// RETAIN ONLY SUBSET OF MATCHES WITH LOWER DISTANCE VALUES	
		
		* Update match id, weights and distance
		assert id_match ==. if _match !=.
		replace id_match = id_match + id_shifter
		replace id_match = _match if _match !=. & id_match ==.
		
		assert w_match ==. if _match !=.
		replace w_match = _weight if _match !=.
		
		assert d_match ==. if _match !=.
		replace d_match = _distance if _match !=.		

		* Update summary stats
		count if _match !=. & id_ukmod !=.			// Retained matched UKMOD observations
		putexcel C`row' = (`r(N)') //, nformat(number)		
		
		* Drop ultimatch variables 
		drop _*

	end
	

* Match ID shifter (to avoid over-writing)
	scalar id_shifter = 1
	count if id_ukmod !=.	
	while (id_shifter < r(N)) {
		scalar id_shifter = id_shifter * 10
		}
	display "id_shifter: ", _continue
	display id_shifter


/*
*** Round 0: Alternative approach: Exact matching only on income deciles, dummy for categorical vbles included in Mahalanobis distance (very similar results)***
*---------------------------------------------------------------------------------------------------------------------------------------------------------------
	local round = 0

* List of discrete variables (exact matching)
	global exact_vars ///
	"inc_net_pct"

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp d_male_hrp ethnicity_hrp edu_high_hrp tenure region hh_size n_children n_ch_517 d_ethnicity_hrp_1 d_ethnicity_hrp_2 d_ethnicity_hrp_3 d_ethnicity_hrp_4 d_ethnicity_hrp_5 d_tenure_1 d_tenure_2 d_tenure_3 d_tenure_4 d_region_1 d_region_2 d_region_3 d_region_4 d_region_5 d_region_6 d_region_7 d_region_8 d_region_9 d_region_10 d_region_11 d_region_12"
	
* Update stats and match_id
	update_match `round'	
*/


*** Round 1: Highest number of exact matching variables, using nearest neighbour only for income ***
*---------------------------------------------------------------------------------------------------
	local round = 1
	scalar trim = 1000		// accept all matches

* List of discrete variables (exact matching)
	global exact_vars ///
	"inc_net_pct d_male_hrp edu_high_hrp tenure region hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive ageclass_hrp" //ethnicity_hrp

* List of continuous variables (minimum distance)
	global dist_vars "income_net"
	
* Update stats and match_id
	update_match `round'

	

*** Round 2: Age moved to minimum distance matching, Mahalanobis distance used ***
*---------------------------------------------------------------------------------
	local round = 2

* List of discrete variables (exact matching)
	global exact_vars ///
	"inc_net_pct d_male_hrp  edu_high_hrp tenure region hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive" //ethnicity_hrp
    
	* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp"

* Update stats and match_id
	update_match `round'

	

*** Round 3: HH demographics moved to minimum distance matching, Mahalanobis distance used ***
*---------------------------------------------------------------------------------------------
	local round = 3

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct d_male_hrp  edu_high_hrp tenure region n_employed n_unemployed n_retired n_students n_inactive" //ethnicity_hrp

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517"

* Update stats and match_id
	update_match `round'
	

	
*** Round 4: HH activity composition moved to minimum distance matching, Mahalanobis distance used ***
*-----------------------------------------------------------------------------------------------------
	local round = 4

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct d_male_hrp edu_high_hrp tenure region" //ethnicity_hrp 

	* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive" 

* Update stats and match_id
	update_match `round'

	
	
*** Round 5: Region removed from matching ***
*--------------------------------------------
	local round = 5

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct d_male_hrp  edu_high_hrp tenure" //ethnicity_hrp

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive"

* Update stats and match_id
	update_match `round'



*** Round 6: Education removed from matching ***
*--------------------------------------------
local round = 6

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct d_male_hrp  tenure" //ethnicity_hrp

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive"

* Update stats and match_id
	update_match `round'

	

*** Round 7: Ethnicity removed from matching ***
*--------------------------------------------
	local round = 7

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct d_male_hrp tenure"

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive"

* Update stats and match_id
	update_match `round'

	

*** Round 8: Gender removed from matching ***
*--------------------------------------------
	local round = 8

* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct tenure"

* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive"

* Update stats and match_id
	update_match `round'

	

*** Round 9: Tenure removed from matching ***
*--------------------------------------------
	local round = 9
* List of discrete variables (exact matching)
	global exact_vars "inc_net_pct"
* List of continuous variables (minimum distance)
	global dist_vars "income_net age_hrp hh_size n_children n_ch_01 n_ch_24 n_ch_517 n_employed n_unemployed n_retired n_students n_inactive"

* Update stats and match_id
	update_match `round'



*** Final steps ***
*------------------
	
* Count unmatched UKMOD observations
	duplicates tag id_match if id_ukmod !=., gen(tag)
	assert id_match ==. if tag > 0 & tag !=.
	count if tag > 0 & tag !=.		// unmatched UKMOD observations: 77 obs 

* Save number of unmatched observations	on xls file
	local row = `round' + 3
	putexcel D`row' = (`r(N)') //, nformat(number)
	
* Keep only matching and id variables
	sort id_match id_ukmod
	keep idhh case id_ukmod id_lcf id_match w_match d_match

* Keep only UKMOD observations and matched-LCF observations	
	duplicates tag id_match, gen (tag)
	drop if id_match ==. & id_ukmod ==.
	drop tag
	
* Save dataset
	save "$data\ukmod-lcf-matched-long.dta", replace
	
	// br id_match id_ukmod inc_net_pct d_male_hrp age_hrp income_net
	
	
*---------------------
*** Final dataset ***
*---------------------

* Save UKMOD-only data
	use "$data\ukmod-lcf-matched-long.dta", clear
	keep if id_ukmod !=.
	drop id_lcf case	// to prevent clashes when merging
	
	save "$data\ukmod-matched.dta", replace
	
* Save LCF-only data
	use "$data\ukmod-lcf-matched-long.dta", clear
	keep if id_lcf !=.
	drop id_ukmod idhh	// to prevent clashes when merging
	
	save "$data\lcf-matched.dta", replace
	
* Merge and save
	use "$data\ukmod-matched.dta", clear
	merge m:m id_match using "$data\lcf-matched.dta"
	drop _merge
	
	duplicates drop
	duplicates tag id_match, gen(n_matches)
	sort id_ukmod id_lcf id_match w_match d_match
	order id_ukmod id_lcf id_match w_match d_match
	save "$data\ukmod-lcf-matched.dta", replace
	
* Merge back UKMOD info
	merge m:1 idhh using "$data\ukmod.dta"
	assert _merge == 3
	drop _merge

* Merge back LCF info
	merge m:1 case using "$data\lcf.dta"
	drop _merge
	
* Collapse observations matched multiple times and save final dataset	
	ds idhh, not
	local num_vars `r(varlist)'  // Stores all variables except idhh
	ds `num_vars', not(type string)
	collapse (mean) `r(varlist)', by(idhh)
	save "$data\ukmod-lcf-matched-allvbles.dta", replace
	
* Display graphs
	use "$data\ukmod-lcf-matched-allvbles.dta", clear
	
	graph bar c_tot, over(inc_net_pct_ukmod, label(labsize(small)) gap(10)) ///
		ytitle("GBP/week") ///
		title("Total consumption, UKMOD") ///
		subtitle("Deciles of disposable household income", size(medium) pos(6)) ///
		name(graph_tot, replace) 
			
	graph export "$graphs\graph_c_tot_income.png", as(png) name("graph_tot") replace

	local cat "food alcohol clothing housing bills health transport comms recreation education resthotels miscell noncons" 
	foreach c of local cat {
		graph bar c_`c', over(inc_net_pct_ukmod, label(labsize(small)) gap(10)) ///
			ytitle("GBP/week") ///
			title(`"Expenditure on `c', UKMOD"') ///
			subtitle("Deciles of disposable household income", size(medium) pos(6)) ///
			name(graph_`c', replace)
	}

	graph combine graph_tot graph_food graph_alcohol graph_clothing graph_housing graph_bills graph_health ///
		graph_transport graph_comms graph_recreation graph_education graph_resthotels graph_miscell ///
		graph_noncons
		
	graph export "$graphs\graph_c_cat_income.png", as(png) replace
	
	
	
