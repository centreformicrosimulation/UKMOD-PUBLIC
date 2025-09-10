
////////////////////////////////////////////////////////////////////////////////
clear all
pause on

* Set wd
cd "C:\Users\Matt\Documents\ukmod-benref-analysis"

global VERSION "permitNegatives"


* 0. Preprocessing for creating a), binary flag for treated PIP recipient 
*    households and b), catgeorical indicator for treated LCWRA recipient households
*===============================================================================

* Load reform data, keep identifiers and add suffix to PIP/LCWRA vars, saving as tempfile
import delimited "raw data\Data-uk_2029_reform_std-UCchange.txt", clear
keep idhh idperson idorigperson dpd bdiscwa i_bsauc_amtdisadult
rename (bdiscwa i_bsauc_amtdisadult) (bdiscwa_reform i_bsauc_amtdisadult_reform)
tempfile reform
save `reform'
* Load baseline data, keep identifiers and add suffix to PIP/LCWRA vars
import delimited "raw data\Data-uk_2029_baseline_std-UCchange.txt", clear
keep idhh idperson idorigperson dpd bdiscwa i_bsauc_amtdisadult
rename (bdiscwa i_bsauc_amtdisadult) (bdiscwa_base i_bsauc_amtdisadult_base)
* Merge with reform
merge 1:1 idhh idperson dpd  using  `reform', nogen
preserve
* Store ID's of PIP recipient households in local
qui gen pip_receive_flag = cond(bdiscwa_base>0,1,0)
keep if pip_receive_flag==1
levelsof idhh, local(pip_receive_idhh) 
* Calculate PIP differential and store HH ids of treated PIP recipients in local
restore
preserve
gen bdiscwa_dif = bdiscwa_reform - bdiscwa_base
qui gen pip_treated_flag = cond(bdiscwa_dif<0, 1, 0)
keep if pip_treated_flag==1
qui levelsof idhh, local(pip_treated_idhh) 
* Calculate LCWRA differential 
restore
gen i_bsauc_amtdisadult_dif = i_bsauc_amtdisadult_reform - i_bsauc_amtdisadult_base
* Store values of LCWRA in locals
qui levelsof i_bsauc_amtdisadult_dif, local(lcwra_dif_levs)
local nontreated 0
local lcwra_dif_levs: list lcwra_dif_levs- nontreated 
local countr = 1
foreach i of local lcwra_dif_levs {
	local lcwra_dif_`countr' = `i'
	di `lcwra_dif_`countr''
	local ++countr
}
* Drop bugged treatment cases
gen bugged = cond(i_bsauc_amtdisadult_dif==float(`lcwra_dif_1')|i_bsauc_amtdisadult_dif==float(`lcwra_dif_4'),1,0)
bysort idhh dpd: egen max = max(bugged)
replace bugged = max
drop max
count if bugged == 1
local n_bugged1 = `r(N)'
drop if bugged == 1
* Generate indicator (at person level)
gen lcwra_treat_type = 0
replace lcwra_treat_type = 1 if i_bsauc_amtdisadult_dif==float(`lcwra_dif_3')
replace lcwra_treat_type = 2 if i_bsauc_amtdisadult_dif==float(`lcwra_dif_2')
* Recode indicator to household level (and add third category where household is subject to both freeze and rate)
* Note that recoding to household level (as opposed to merging) is necessary in order to identify those household subjec to both freeze and rate
forval i = 1/2 {
	bysort idhh dpd: egen n_treat`i'=total(lcwra_treat_type==`i') if lcwra_treat_type !=0
	replace n_treat`i' = 0 if n_treat`i'== .
}
bysort idhh dpd: gen lcwra_treat_type_hh = cond(n_treat1 > 0 & n_treat2>0, 3,   ///
                                           cond(n_treat1 == 0 & n_treat2>0, 2,  ///
										   cond(n_treat1 > 0 & n_treat2==0, 1, 0)))
bysort idhh dpd: egen max = max(lcwra_treat_type_hh)
bysort idhh dpd: replace lcwra_treat_type_hh = max                                                         
label define lcwra_treat_type_hh_L 0 "Not LCWRA HH" 1 "Frozen LCWRA" 2 "Reduced LCWRA" 3 "Frozen and reduced LCWRA"
label values lcwra_treat_type_hh lcwra_treat_type_hh_L
* Reduce dataframe to identifier-indicator merge key  and save as tempfile
duplicates drop idhh dpd, force
keep idhh dpd lcwra_treat_type_hh
tempfile lcwra_treat_key
save `lcwra_treat_key'




* 1. Loop through scenarios (baseline and reform)
*===============================================================================
local scenarios baseline reform
foreach s of local scenarios {
	di "Generating statistics for `s' scenario "
	* Load data 
	import delimited "raw data\Data-uk_2029_`s'_std-UCchange.txt", clear
    * Genrate flag exising PIP recipient households
	gen pip_receive_flag = 0
	foreach i of local pip_receive_idhh {
		qui replace pip_receive_flag = 1 if idhh==`i' // Loop application = long as hell, should use merge key instead (but this work at least)
	}
	tab pip_receive_flag
	* Generate flag for treated PIP recipient households (those who lose PIP in the reform)
	gen pip_treated_flag = 0
	foreach i of local pip_treated_idhh {
		qui replace pip_treated_flag = 1 if idhh==`i'
	}
	tab pip_treated_flag
	* Generate flag for treated LCWRA recipient households (those who are subject to rate freeze or rate reduction)
	merge m:1 idhh dpd using `lcwra_treat_key'
	count if _m==1
	local n_bugged2 = `r(N)'
	assert `n_bugged1' == `n_bugged2 '
	* Drop non-merged cases (the bugged LCWRA treatment cases)
	drop if _m == 1
	drop _m
	pause
	* Generate flag for workless households
	gen workless = cond(inlist(les, 5, 7), 1, 0)
	bysort idhh dpd: egen workless_hh = min(workless==1)
	* Generate flag for workless households (adjusted definition to include disabled/sick)
	gen workless_adj = cond(inlist(les, 5, 7, 8), 1, 0)
	bysort idhh dpd: egen workless_adj_hh = min(workless_adj==1)
	pause
	* Generate equivalisation factors
	gen age14over = cond(dag >= 14, 1, 0)
	gen age13under = cond(dag < 14, 1, 0)
	bysort idhh dpd: egen age14over_hhnum = sum(age14over)
	bysort idhh dpd: egen age13under_hhnum = sum(age13under)
	bysort idhh dpd: gen equiv_bhc = 0.67 + 0.33 * (age14over_hhnum -1) + 0.2 * age13under_hhnum
	bysort idhh dpd: gen equiv_ahc = 0.58 + 0.42 * (age14over_hhnum -1) + 0.2 * age13under_hhnum
	* Create equivalised weekly households disposable income
	gen il_dispy_bhc = (ils_origy + ils_ben) - (ils_tax + ils_sicdy)
	drop il_dispy_ahc
	gen il_dispy_ahc = il_dispy_bhc - xhc_hbai
	bysort dpd idhh: egen hh_dispy_bhc = sum(il_dispy_bhc)
	bysort dpd idhh: egen hh_dispy_ahc = sum(il_dispy_ahc)
	replace hh_dispy_bhc = hh_dispy_bhc /4.34524
	replace hh_dispy_ahc = hh_dispy_ahc /4.34524
	gen hh_dispy_bhc_eq = hh_dispy_bhc/equiv_bhc
	gen hh_dispy_ahc_eq = hh_dispy_ahc/equiv_ahc
	foreach v of varlist hh_dispy_bhc_eq hh_dispy_ahc_eq {
		replace `v' = 0 if `v' <0
	}
	
	
	* 2. Loop over geographies (UK and London)
	*===========================================================================
	local geos uk london
	foreach geo of local geos {
		preserve
		* Comment out for UK-based poverty rate for London
		if "`geo'"== "london" {
			keep if drgn1 == 8
		}
		* Median
		tabstat hh_dispy_bhc_eq hh_dispy_ahc_eq [aw=dwt] , stats(median) save
		qui mat med =  r(StatTotal) 
		local BHCmed=med[1,1]
		local AHCmed=med[1,2]
		di "BHC median = `BHCmed'"
		di "AHC median = `AHCmed'"
		* Poverty line BHC and AHC 
		local BHCline = `BHCmed'*.6
		local AHCline = `AHCmed'*.6
		di "BHC poverty line = `BHCline'"
		di "AHC poverty = `AHCline'"
		* Poverty indicator
		qui gen inpov_bhc = cond(hh_dispy_bhc_eq < `BHCline',1,0)
		qui gen inpov_ahc = cond(hh_dispy_ahc_eq < `AHCline',1,0)
		
		// Comment out for London-based poverty rate
		//if "`geo'"== "london" {
		//	keep if drgn1 == 8
		//}
		* Matrix to store results
		mat `s'_`geo' = J(12,5,.)
        mat colnames `s'_`geo' = "N-unweighted" "BHC poverty" "AHC poverty" "BHC mean income" "AHC mean income"
        mat rownames `s'_`geo' = "Population" "Disabled" "Receiving PIP" "Lose eligibility to PIP"  ///
                                 "Receiving LCWRA" "LCWRA freeze" "LCWRA reduction" "LCWRA freeze and reduction" "Receiving PIP or LCWRA" ///
								 "Workless" "Workless adjusted" "Children"
		
		* 3. Generate estimates
		*===========================================================================
			
		* Population
		*------------------------------------------------------------------------
		* Sample
		qui su dwt 
		di as text "Population: N= = " as result `r(N)'
		mat `s'_`geo'[1,1] = `r(N)'
		* Poverty
		qui su inpov_bhc [aw=dwt] 
		di as text "BHC `geo' poverty rate for population = " as result `r(mean)'
		mat `s'_`geo'[1,2] = `r(mean)'
		qui su inpov_ahc [aw=dwt]
		di as text "AHC `geo' poverty rate for population = " as result `r(mean)'
		mat `s'_`geo'[1,3] = `r(mean)'
		* Mean HH income
	    qui su hh_dispy_bhc_eq [aw=dwt]
		di as text "BHC `geo' mean HH income for population = " as result `r(mean)'
		mat `s'_`geo'[1,4] = `r(mean)'
		qui su hh_dispy_ahc_eq [aw=dwt]
		di as text "AHC `geo' mean HH income for population = " as result `r(mean)'
		mat `s'_`geo'[1,5] = `r(mean)'
		
		
		* Individuals in households that include a disabled person
		*-------------------------------------------------------------------------------
	    * Indicator
		bysort dpd idhh: egen disab_count = sum(ddi03)
		bysort dpd idhh: gen disab_hh = cond(ddi03>0, 1,0)
		* Sample
		qui su dwt if disab_hh==1 
		di as text "Individuals in households that include a disabled person: N = " as result `r(N)'
		mat `s'_`geo'[2,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if disab_hh==1 [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person = " as result `r(mean)'
		mat `s'_`geo'[2,2] = `r(mean)'
		qui su inpov_ahc if disab_hh==1 [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person = " as result `r(mean)'
		mat `s'_`geo'[2,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if disab_hh==1 [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person = " as result `r(mean)'
		mat `s'_`geo'[2,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if disab_hh==1 [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person = " as result `r(mean)'
		mat `s'_`geo'[2,5] = `r(mean)'

		* Individuals in households that include a disabled person receiving PIP currently (below is wrong rn bc it looks at different sample, not cpaturing those who lose PIP)
		*-------------------------------------------------------------------------------
		* Indicator (bdiscwa=living, bdimbwa=mobility)
		//bysort dpd idhh: egen pip_living = sum(bdiscwa)
		//bysort dpd idhh: egen pip_mobility = sum(bdimbwa)
		//bysort dpd idhh: gen pip_combined = pip_living + pip_mobility
		//bysort dpd idhh: gen disab_hh_pip = cond(pip_combined >0,1,0)
		* Sample
		qui su dwt if pip_receive_flag==1 
		di as text " Individuals in households that include a disabled person receiving PIP currently: N = " as result `r(N)'
		mat `s'_`geo'[3,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if pip_receive_flag==1 [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person receiving PIP = " as result `r(mean)'
		mat `s'_`geo'[3,2] = `r(mean)'
		qui su inpov_ahc if pip_receive_flag==1 [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person receiving PIP = " as result `r(mean)'
		mat `s'_`geo'[3,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if pip_receive_flag==1  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person receiving PIP = " as result `r(mean)'
		mat `s'_`geo'[3,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if pip_receive_flag==1 [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person receiving PIP = " as result `r(mean)'
		mat `s'_`geo'[3,5] = `r(mean)'
		
	    * Individuals in households that include a disabled person who will lose eligibility to PIP
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if pip_treated_flag==1 
		di as text "Individuals in households that include a disabled person who will lose eligibility to PIP: N = " as result `r(N)'
		mat `s'_`geo'[4,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if pip_treated_flag==1  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person who will lose eligibility to PIP = " as result `r(mean)'
		mat `s'_`geo'[4,2] = `r(mean)'
		qui su inpov_ahc if pip_treated_flag==1 [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person who will lose eligibility to PIP = " as result `r(mean)'
		mat `s'_`geo'[4,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if pip_treated_flag==1  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person who will lose eligibility to PIP = " as result `r(mean)'
		mat `s'_`geo'[4,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if pip_treated_flag==1 [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person who will lose eligibility to PIP = " as result `r(mean)'
		mat `s'_`geo'[4,5] = `r(mean)'
		
		* Individuals in households that include a disabled person receiving LCWRA
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if lcwra_treat_type_hh!=0 
		di as text "Individuals in households that include a disabled person receiving LCWRA: N = " as result `r(N)'
		mat `s'_`geo'[5,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if lcwra_treat_type_hh!=0  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person receiving LCWRA = " as result `r(mean)'
		mat `s'_`geo'[5,2] = `r(mean)'
		qui su inpov_ahc if lcwra_treat_type_hh!=0 [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person receiving LCWRA = " as result `r(mean)'
		mat `s'_`geo'[5,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if lcwra_treat_type_hh!=0  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person receiving LCWRA = " as result `r(mean)'
		mat `s'_`geo'[5,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if lcwra_treat_type_hh!=0 [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person receiving LCWRA = " as result `r(mean)'
		mat `s'_`geo'[5,5] = `r(mean)'
		
	   * Individuals in households that include a disabled person subject to rate freeze
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if lcwra_treat_type_hh==1 | lcwra_treat_type_hh==3  
		di as text " Individuals in households that include a disabled person subject to rate freeze: N = " as result `r(N)'
		mat `s'_`geo'[6,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if lcwra_treat_type_hh==1 | lcwra_treat_type_hh==3  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person subject to rate freeze = " as result `r(mean)'
		mat `s'_`geo'[6,2] = `r(mean)'
		qui su inpov_ahc if lcwra_treat_type_hh==1 | lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person subject to rate freeze = " as result `r(mean)'
		mat `s'_`geo'[6,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if lcwra_treat_type_hh==1 | lcwra_treat_type_hh==3   [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person subject to rate freeze = " as result `r(mean)'
		mat `s'_`geo'[6,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if lcwra_treat_type_hh==1 | lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person subject to rate freeze = " as result `r(mean)'
		mat `s'_`geo'[6,5] = `r(mean)'
		
		* Individuals in households that include a disabled person subject to rate reduction
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if lcwra_treat_type_hh==2 | lcwra_treat_type_hh==3 
		di as text "Individuals in households that include a disabled person subject to rate reduction: N = " as result `r(N)'
		mat `s'_`geo'[7,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if lcwra_treat_type_hh==2 | lcwra_treat_type_hh==3  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include a disabled person subject to rate reduction = " as result `r(mean)'
		mat `s'_`geo'[7,2] = `r(mean)'
		qui su inpov_ahc if lcwra_treat_type_hh==2 | lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include a disabled person subject to rate reduction = " as result `r(mean)'
		mat `s'_`geo'[7,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if lcwra_treat_type_hh==2 | lcwra_treat_type_hh==3   [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include a disabled person subject to rate reduction = " as result `r(mean)'
		mat `s'_`geo'[7,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if lcwra_treat_type_hh==2 | lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include a disabled person subject to rate reduction = " as result `r(mean)'
		mat `s'_`geo'[7,5] = `r(mean)'
		
		* Individuals in households that include disabled persons subject to rate freeze and reduction
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if lcwra_treat_type_hh==3 
		di as text "Individuals in households that include disabled persons subject to rate freeze and reduction: N = " as result `r(N)'
		mat `s'_`geo'[8,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if lcwra_treat_type_hh==3  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include disabled persons subject to rate freeze and reduction = " as result `r(mean)'
		mat `s'_`geo'[8,2] = `r(mean)'
		qui su inpov_ahc if lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include disabled person subject to rate freeze and reduction = " as result `r(mean)'
		mat `s'_`geo'[8,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if lcwra_treat_type_hh==3   [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include disabled persons subject to rate freeze and reduction = " as result `r(mean)'
		mat `s'_`geo'[8,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if lcwra_treat_type_hh==3  [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include disabled persons subject to rate freeze and reduction = " as result `r(mean)'
		mat `s'_`geo'[8,5] = `r(mean)'
		
		
		* Individuals in households that include a disabled person receiving PIP or LCWRA
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if lcwra_treat_type_hh!=0 | pip_receive_flag==1 
		di as text "Individuals in households that include disabled receiving PIP or LCWRA: N = " as result `r(N)'
		mat `s'_`geo'[9,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if lcwra_treat_type_hh!=0 | pip_receive_flag==1  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[9,2] = `r(mean)'
		qui su inpov_ahc if lcwra_treat_type_hh!=0 | pip_receive_flag==1 [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[9,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if lcwra_treat_type_hh!=0 | pip_receive_flag==1  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[9,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if lcwra_treat_type_hh!=0 | pip_receive_flag==1 [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[9,5] = `r(mean)'
		
		* Individuals in workless households that include a disabled person receiving PIP or LCWRA
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if workless_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) 
		di as text "Individuals in workless households that include disabled receiving PIP or LCWRA: N = " as result `r(N)'
		mat `s'_`geo'[10,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if workless_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in workless households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[10,2] = `r(mean)'
		qui su inpov_ahc if workless_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in workless households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[10,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if workless_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in workless households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[10,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if workless_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in workless households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[10,5] = `r(mean)'
		
		* Individuals in workless (where workless includes disabled/sick) households that include a disabled person receiving PIP or LCWRA
		*--------------------------------------------------------------------------------------------------------
		* Sample
		qui su dwt if workless_adj_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)
		di as text "Individuals in workless households (where workless includes disabled/sick) households that include disabled receiving PIP or LCWRA: N = " as result `r(N)'
		mat `s'_`geo'[11,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if workless_adj_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt] 
		di as text "BHC `geo' poverty rate for individuals in workless households (where workless includes disabled/sick) households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[11,2] = `r(mean)'
		qui su inpov_ahc if workless_adj_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) [aw=dwt]
		di as text "AHC `geo' poverty rate for individuals in workless households (where workless includes disabled/sick) households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[11,3] = `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if workless_adj_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt]
		di as text "BHC `geo' mean HH income for individuals in workless households (where workless includes disabled/sick) households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[11,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if workless_adj_hh==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) [aw=dwt]
		di as text "AHC `geo' mean HH income for individuals in workless households (where workless includes disabled/sick) households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[11,5] = `r(mean)'
		
		* Children in households that include a disabled person receiving PIP or LCWRA
		*-------------------------------------------------------------------------------
		* Sample
		qui su dwt if dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1) 
		di as text "Individuals in children that include disabled receiving PIP or LCWRA: N = " as result `r(N)'
		mat `s'_`geo'[12,1] = `r(N)'
		* Poverty
		qui su inpov_bhc if dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt] 
		di as text "BHC `geo' poverty rate for children in households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[12,2] = `r(mean)'
		qui su inpov_ahc if dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt]
		di as text "AHC `geo' poverty rate for children in households that include disabled person receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[12,3] = `r(mean)'
		* number in poverty
		qui egen denom = sum(dwt) if dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)
		qui su denom
		di as text "Number of children in households that include a disabled person receiving PIP or LCWRA = " as result `r(mean)'
		qui egen nom = sum(dwt) if dag <16 & inpov_ahc==1 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)
		qui su nom
		di as text "Number of children living in poverty in households that include a disabled person receiving PIP or LCWRA = " as result `r(mean)'
		* Mean HH income
		qui su hh_dispy_bhc_eq if  dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)   [aw=dwt]
		di as text "BHC `geo' mean HH income for children in households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[12,4] = `r(mean)'
		qui su hh_dispy_ahc_eq if  dag <16 & (lcwra_treat_type_hh!=0 | pip_receive_flag==1)  [aw=dwt]
		di as text "AHC `geo' mean HH income for children in households that include disabled persons receiving PIP or LCWRA = " as result `r(mean)'
		mat `s'_`geo'[12,5] = `r(mean)'

	restore	
	}
	
}

* 3. Export matrix differential to Excel
*===========================================================================
local geos uk london
foreach geo of local geos {
	mat `geo'_dif = reform_`geo' - baseline_`geo'
	//pause to check for same samples on reform
	local rows=rowsof(`geo'_dif)
	forvalues i=1(1)`rows'{
		mat `geo'_dif[`i',1]=reform_`geo'[`i',1]
	}
	
	putexcel set ukmod-benref-detailed-analysis_$VERSION , sheet("`geo' Results", replace) modify
	putexcel A1=matrix(`geo'_dif), names
}
putexcel save

























