***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         15_LCFconsumption.do
* DESCRIPTION:          Retrieve expenditure from the FRS-LCF database   
* INPUT FILE:           assembled
* OUTPUT FILE:          assembled
* LAST UPDATE:          15 June 2026 DP 
******************************************************************************************
cap log close
log using "${log}\15_LCFconsumption.log", replace

run ${do}\consumption\LCF-FRS-imputation-master.do 

***************************
*add LCF consumption vars *
***************************
cd "$data"
use assembled, clear 
count
merge m:m idhh using ${data}/expend_LCF
drop if _merge !=1 & _merge !=3
count
drop _merge

//ensure consumption is attached to the household reference person only 
fre hrpid
ds x0* x1* xtotal* x_yds  
foreach var in `r(varlist)' {  
replace `var' = 0 if hrpid != 1  
} 
sum xtotal00 xtotal99


**************************************************************************************
* Check the income gradient of consumption in individual UKMOD data & produce graphs *
**************************************************************************************
/////////////////////////////////
//By disposable income deciles //
/////////////////////////////////
	scalar pct = 10	
    local p = pct
	bysort idhh: egen income_net_ukmod = total(yds)
	
preserve 
keep if hrpid==1 

	xtile inc_net_pct_ukmod = income_net_ukmod, n(`p')
	xtile inc_pct_x_yds = x_yds, n(`p')
	
// Define categories and corresponding titles
local cat "01 02 03 04 05 06 07 08 09 10 11 12 00 99"
local titles `" "Food & Beverages" "Alcohol & Tobacco" "Clothing & Footwear" "Housing" "Furniture & Equipment" "Health" "Transport" "Communication" "Recreation & Culture" "Education" "Restaurants & Hotels" "Miscellaneous Goods"  "Total Consumption" "Total Consumption (sum of all 4digit categories)""'

local i = 1
foreach cat in `cat' {
	local title_word : word `i' of `titles'  // Extract corresponding title
	graph bar xtotal`cat', over(inc_net_pct_ukmod, label(labsize(small)) gap(10)) ///
		ytitle("GBP/month") ///
		title("`title_word', UKMOD") ///
		subtitle("Income deciles", size(medium) pos(6)) ///
		name(graph_`cat'_UKMOD, replace)
		
	local ++i  // Increment index
	
}
graph export "$graphs\graph_c_tot_income_UKMOD.png", as(png) name("graph_00_UKMOD") replace

graph combine graph_01_UKMOD graph_02_UKMOD graph_03_UKMOD graph_04_UKMOD graph_05_UKMOD graph_06_UKMOD graph_07_UKMOD ///
	graph_08_UKMOD graph_09_UKMOD graph_10_UKMOD graph_11_UKMOD graph_12_UKMOD graph_00_UKMOD  
graph export "$graphs\graph_c_cat_income_UKMOD.png", as(png) replace


graph bar income_net_ukmod, over(inc_net_pct_ukmod, label(labsize(small)) gap(10)) ///
		ytitle("GBP/month") ///
		title("Disposable household income, UKMOD") ///
		subtitle("Deciles of disposable household income", size(medium) pos(6)) ///
		name(graph_hhincome_UKMOD, replace)
		//graph export "$graphs\graph_hhincome_UKMOD.png", as(png) replace

graph combine graph_hhincome_UKMOD graph_00_UKMOD graph_99_UKMOD , ycommon  
graph export "$graphs\graph_c_cat_income_comp_UKMOD.png", as(png) replace


/////////////////////////////////////////////
//By equivalised disposable income deciles //
/////////////////////////////////////////////
	scalar pct = 10	
    local p = pct
	
	// hh size 
    sort idhh
    cap drop hhsize 
    bysort idhh : egen hhsize = count(idperson) 
    //adult_eq 
    cap gen child_14=(dag<=14)
    bysort idhh : egen n_child_14 = total(child_14) 
    cap gen adult_eq=1+0.5*(hhsize-n_child_14-1)+0.3*n_child_14
    
	cap gen income_eq_ukmod = income_net_ukmod /adult_eq //equivalised income
    xtile inc_eq_pct_ukmod = income_eq_ukmod, n(`p')
		
// Define categories and corresponding titles
local cat "00 01 02 03 04 05 06 07 08 09 10 11 12"
local titles `" "total consumption, UKMOD" "food" "alcohol" "clothing" "housing" "bills" "health" "transport" "comms" "recreation" "education" "resthotels" "miscell" "'

local i = 1
foreach cat in `cat' {
    //replace xtotal`cat'= xtotal`cat'/30.5*7 //move to weekly terms as in LCF

	local title_word : word `i' of `titles'  // Extract corresponding title
	graph bar xtotal`cat', over(inc_eq_pct_ukmod, label(labsize(vsmall)) gap(10)) ///
		ytitle("GBP/month", size(small)) ///
		ylabel(, labsize(vsmall)) ///
		title("`title_word'") ///
		subtitle("income deciles", size(small) pos(6)) ///
		name(graph_`cat'_UKMOD, replace)
		
	local ++i  // Increment index
	
}
graph export "$graphs\graph_c_EQincome_UKMOD.png", as(png) name("graph_00_UKMOD") replace

 		
graph combine graph_01_UKMOD graph_02_UKMOD graph_03_UKMOD graph_04_UKMOD graph_05_UKMOD graph_06_UKMOD graph_07_UKMOD ///
	graph_08_UKMOD graph_09_UKMOD graph_10_UKMOD graph_11_UKMOD graph_12_UKMOD   
graph export "$graphs\graph_c_cat_EQincome_UKMOD.png", as(png) replace


///////////////////////////////////////////////		
//output to Excel file with summary stats   ///
///////////////////////////////////////////////
putexcel set "${summary_table_consumption}", sheet(${frsyr}, replace) modify	

//compare mean income & consumption
putexcel A2=("hh disposable income FRS, GBP per month")
qui mean income_net_ukmod [pw=dwt]
putexcel B2=matrix(e(b)')

putexcel A3=("hh disposable income LCF, GBP per month")
qui mean x_yds [pw=dwt]
putexcel B3=matrix(e(b)')

putexcel A4=("hh consumption expenditure, GBP per month")
qui mean xtotal00 [pw=dwt]
putexcel B4=matrix(e(b)')

putexcel A5=("hh consumption expenditure (sum of 4digit cat), GBP per month")
qui mean xtotal99 [pw=dwt]
putexcel B5=matrix(e(b)')

//ratio of sum of 4 digit consumption categories and reported total consumption 
putexcel A6=("ratio xtotal99/xtotal00")
gen ratio = xtotal99/xtotal00
qui mean ratio [pw=dwt]
putexcel B6=matrix(e(b)')

//correlate FRS & LCF incomes 
putexcel A7=("correlation coefficient for FRS & LCF hh disposable incomes")
corr income_net_ukmod x_yds
local corr_coef = r(rho)
putexcel B7 = "`corr_coef'"


//gen savings rate wrt FRS income  
putexcel A9=("savings rate wrt to FRS income")
putexcel A10=("1st decile") A11=("2") A12=("3") A13=("4") A14=("5") A15=("6") A16=("7") A17=("8") A18=("9") A19=("10th decile")
gen savings_rate_ukmod = ((income_net_ukmod - xtotal00) / income_net_ukmod) 
mean savings_rate_ukmod [fweight = dwt] if income_net_ukmod>0  , over(inc_net_pct_ukmod)
putexcel B10=matrix(e(b)')

putexcel A20=("total") 
mean savings_rate_ukmod [fweight = dwt] if income_net_ukmod>0 
putexcel B20=matrix(e(b)')

//gen savings rate wrt LCF income   
putexcel A21=("savings rate wrt to LCF income")
putexcel A22=("1st decile") A23=("2") A24=("3") A25=("4") A26=("5") A27=("6") A28=("7") A29=("8") A30=("9") A31=("10th decile")
gen savings_rate_lcf = ((x_yds - xtotal00) / x_yds) 
mean savings_rate_lcf [fweight = dwt] if x_yds>0 , over(inc_pct_x_yds)
putexcel B22=matrix(e(b)')

putexcel A32=("total") 
mean savings_rate_lcf [fweight = dwt] if x_yds>0
putexcel B32=matrix(e(b)')
 
//output consumption exp by component 
putexcel A34=("Reported expenditure totals by component") 
putexcel A35=("1 - Food & Beverages") A36=("2 - Alcohol & Tobacco") A37=("3 - Clothing & Footwear") A38=("4 - Housing") A39=("5 - Furniture & Equipment") A40=("6 - Health") ///
A41=("7 - Transport") A42=("8 - Communication") A43=("9 - Recreation & Culture") A44=("10 - Education") A45=("11 - Restaurants & Hotels") A46=("12 - Miscellaneous Goods") A47=("Total consumption expenditure") 

qui mean xtotal01 [pw=dwt]
putexcel B35=matrix(e(b)')

qui mean xtotal02 [pw=dwt]
putexcel B36=matrix(e(b)')

qui mean xtotal03 [pw=dwt]
putexcel B37=matrix(e(b)')

qui mean xtotal04 [pw=dwt]
putexcel B38=matrix(e(b)')

qui mean xtotal05 [pw=dwt]
putexcel B39=matrix(e(b)')

qui mean xtotal06 [pw=dwt]
putexcel B40=matrix(e(b)')

qui mean xtotal07 [pw=dwt]
putexcel B41=matrix(e(b)')

qui mean xtotal08 [pw=dwt]
putexcel B42=matrix(e(b)')

qui mean xtotal09 [pw=dwt]
putexcel B43=matrix(e(b)')

qui mean xtotal10 [pw=dwt]
putexcel B44=matrix(e(b)')

qui mean xtotal11 [pw=dwt]
putexcel B45=matrix(e(b)')

qui mean xtotal12 [pw=dwt]
putexcel B46=matrix(e(b)')

qui mean xtotal00 [pw=dwt]
putexcel B47=matrix(e(b)')
 
/*output 4 digit consumption exp by component 
local cat "01 02 03 04 05 06 07 08 09 10 11 12"
foreach cat in `cat' {
de x`cat'*
egen xtotal99_`cat' =  rowtotal(x`cat'*)
} 
sum xtotal99_*
*/

putexcel A49=("4digit expenditure totals by component") 
putexcel A50=("1 - Food & Beverages") A51=("2 - Alcohol & Tobacco") A52=("3 - Clothing & Footwear") A53=("4 - Housing") A54=("5 - Furniture & Equipment") A55=("6 - Health") ///
A56=("7 - Transport") A57=("8 - Communication") A58=("9 - Recreation & Culture") A59=("10 - Education") A60=("11 - Restaurants & Hotels") A61=("12 - Miscellaneous Goods") A62=("Total 4 digit consumption expenditure") 

qui mean xtotal99_01 [pw=dwt]
putexcel B50=matrix(e(b)')

qui mean xtotal99_02 [pw=dwt]
putexcel B51=matrix(e(b)')

qui mean xtotal99_03 [pw=dwt]
putexcel B52=matrix(e(b)')

qui mean xtotal99_04 [pw=dwt]
putexcel B53=matrix(e(b)')

qui mean xtotal99_05 [pw=dwt]
putexcel B54=matrix(e(b)')

qui mean xtotal99_06 [pw=dwt]
putexcel B55=matrix(e(b)')

qui mean xtotal99_07 [pw=dwt]
putexcel B56=matrix(e(b)')

qui mean xtotal99_08 [pw=dwt]
putexcel B57=matrix(e(b)')

qui mean xtotal99_09 [pw=dwt]
putexcel B58=matrix(e(b)')

qui mean xtotal99_10 [pw=dwt]
putexcel B59=matrix(e(b)')

qui mean xtotal99_11 [pw=dwt]
putexcel B60=matrix(e(b)')

qui mean xtotal99_12 [pw=dwt]
putexcel B61=matrix(e(b)')
 
qui mean xtotal99 [pw=dwt]
putexcel B62=matrix(e(b)')
 
restore 

drop income_net_ukmod 
order x_* xtotal0* xtotal1* xtotal99 x0* x1*, last
save assembled, replace
//end of imputation
cap log close

