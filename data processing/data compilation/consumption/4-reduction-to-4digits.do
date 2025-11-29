***************************************************
*** LCF-FRS imputation of consumption data
*** 4. Aggregate 5-digit COICOP categories into 4-digit COICOP categories to Be used By the TCO add-on. 
***************************************************

* Author: 			Daria Popova 
* First version: 	Feb 2025
* This version: 	28/11/2025


clear all
set more off

********************************************
** Load matched UKMOD-LCF Dataset **
********************************************
use "$data\ukmod-lcf-matched-allvbles.dta", clear
drop if idhh==. 
* Identify variables that start with 'C' and end with a "t" 
ds
local clean_names ""

/* 
COICOP Code	Category Description
1	Food and non-alcoholic Beverages
2	Alcoholic Beverages, toBacco, and narcotics
3	Clothing and footwear
4	Housing, water, electricity, gas, and other fuels
5	Furnishings, household equipment, and routine household maintenance
6	Health
7	Transport
8	Communication
9	Recreation and culture
10	Education
11	Restaurants and hotels
12	Miscellaneous goods and services

LCF VariaBle information	
Certain variaBle names are suffixed with a letter and their definition is as follows:	
	
‘c’	child expenditure
‘L’	expenditure in a large supermarket
‘p’ 	anonymised (proxy) variaBles
‘t’ 	total child and adult expenditure
‘u’	unanonymised variaBles
‘w’	internet expenditure
‘x’	clothing/footwear expenditure in a selected clothing chain
‘y’	clothing/footwear expenditure in a large supermarket
‘z’	clothing/footwear expenditure in a charity shop
Please note that adult expenditure has no suffix.	
Therefore we need to keep all C variaBles ending with "t" 
*/
 
* Create lists of consumption variables at 5 digit level from the diary by category 

#delimit ;
local varlist_01 
c11111t
c11121t
c11122t
c11131t
c11141t
c11142t
c11151t
c11211t
c11221t
c11231t
c11241t
c11251t
c11252t
c11253t
c11261t
c11271t
c11311t
c11321t
c11331t
c11341t
c11411t
c11421t
c11431t
c11441t
c11451t
c11461t
c11471t
c11511t
c11521t
c11522t
c11531t
c11541t
c11551t
c11611t
c11621t
c11631t
c11641t
c11651t
c11661t
c11671t
c11681t
c11691t
c11711t
c11721t
c11731t
c11741t
c11751t
c11761t
c11771t
c11781t
c11811t
c11821t
c11831t
c11841t
c11851t
c11861t
c11911t
c11921t
c11931t
c11941t
c12111t
c12121t
c12131t
c12211t
c12221t
c12231t
c12241t
	;
#delimit cr // cr stands for carriage return

#delimit ;
local varlist_02 
c21111t
c21211t
c21212t
c21213t
c21214t
c21221t
c21311t
c22111t
c22121t
c22131t 
	;
#delimit cr // cr stands for carriage return

#delimit ;
local varlist_03 
c31111t
c31211t
c31212t
c31221t
c31222t
c31231t
c31232t
c31233t
c31234t
c31311t
c31312t
c31313t
c31314t
c31315t
c31411t
c31412t
c31413t
c32111t
c32121t
c32131t
c32211t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_04 
c41211t
c43111t
c43112t
c43212c
c44211t
c45112t
c45114t
c45212t
c45214t
c45222t
c45312t
c45411t
c45412t
c45511t
c31111t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_05 
c51111c
c51113t
c51114t
c51211c
c51212t
c51311t
c52111t
c52112t
c53111t
c53121t
c53122t
c53131t
c53132t
c53133t
c53141t
c53151t
c53161t
c53171t
c53211t
c53311t
c53312t
c53313t
c53314t
c54111t
c54121t
c54131t
c54132t
c54141t
c55111t
c55112t
c55211t
c55212t
c55213t
c55214t
c56111t
c56112t
c56121t
c56122t
c56123t
c56124t
c56125t
c56211t
c56221t
c56222t
c56223t 
	;
#delimit cr // cr stands for carriage return

#delimit ;
local varlist_06 
c61111t
c61112t
c61211t
c61311t
c61312t
c61313t
c62111t
c62112t
c62113t
c62114t
c62211t
c62212t
c62311t
c62321t
c62322t
c62331t
c63111t
	;
#delimit cr // cr stands for carriage return

#delimit ;
local varlist_07 
c71111c
c71112t
c71121c
c71122t
c71211c
c71212t
c71311t
c71411t
c72111t
c72112t
c72113t
c72114t
c72115t
c72211t
c72212t
c72213t
c72311c
c72312c
c72313t
c72314t
c72411t
c72412t
c72413t
c72414t
c73112t
c73212t
c73213t
c73214t
c73411t
c73512t
c73513t
c73611t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_08 
c81111t
c82111t
c82112t
c82113t
c83111c
c83112t
c83113c
c83114t
c83115t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_09 
c91111t
c91112t
c91113t
c91121t
c91122t
c91123t
c91124t
c91125t
c91126t
c91127t
c91128t
c91211t
c91221t
c91311t
c91411t
c91412t
c91413t
c91414t
c91511t
c92111t
c92112t
c92117t
c92211t
c92221t
c92311t
c93111t
c93112t
c93113t
c93114t
c93211t
c93212t
c93311t
c93312t
c93313t
c93411t
c93412t
c93511t
c94111t
c94112t
c94113t
c94114c
c94115t
c94211t
c94212t
c94221t
c94231c
c94232t
c94233c
c94235c
c94236t
c94237c
c94238t
c94239t
c94241t
c94242t
c94243t
c94244t
c94245t
c94246t
c94311t
c94312t
c94313t
c94314t
c94315t
c94316t
c94319t
c95111t
c95211t
c95212t
c95311t
c95411t
c96111c
c96112c
c92113c
c92114t
c92115c
c92116t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_10 
ca1111c
ca1112c
ca1113t
ca2111c
ca2112c
ca2113t
ca3111c
ca3112c
ca3113t
ca4111c
ca4112c
ca4113t
ca5111c
ca5112c
ca5113t
	;
#delimit cr // cr stands for carriage return


#delimit ;
local varlist_11 
cb1111t
cb1112t
cb1113t
cb1114t
cb1115t
cb1116t
cb1117c
cb1118c
cb1119c
cb111ac
cb111bc
cb111ct
cb111dt
cb111et
cb111ft
cb111gt
cb111ht
cb111it
cb111jt
cb1121t
cb1122t
cb1123t
cb1124t
cb1125t
cb1126t
cb1127t
cb1128t
cb112bt
cb1213t 
	;
#delimit cr // cr stands for carriage return

#delimit ;
local varlist_12 
cc1111t
cc1211t
cc1311t
cc1312t
cc1313t
cc1314t
cc1315t
cc1316t
cc1317t
cc3111t
cc3112t
cc3211t
cc3221t
cc3222t
cc3223t
cc3224t
cc4111t
cc4112t
cc4121t
cc4122t
cc5213t
cc5411c
cc5412t
cc5413t
cc6211c
cc6212t
cc6214t
cc7111t
cc7112t
cc7113t
cc7114t
cc7115t
cc7116t
cc5311c 
	;
#delimit cr // cr stands for carriage return


* VariaBles to Be transformed
keep idhh `varlist_01' `varlist_02' `varlist_03' `varlist_04' `varlist_05' `varlist_06' `varlist_07' `varlist_08' `varlist_09' `varlist_10' `varlist_11' `varlist_12' 
tempfile transform_data
save `transform_data'


* Remove the last letter 't' or 'c' from all variables ending with 't' or 'c'

* List all variaBles in the dataset
ds

* Loop through all variables to check for variables that end with 't' or 'c'
foreach var of varlist `r(varlist)' {
    * Check if the variaBle name ends with 't' or 'c'
    if substr("`var'", -1, 1) == "t" | substr("`var'", -1, 1) == "c" {
        local newname = substr("`var'", 1, length("`var'") - 1) //Create a new variaBle name By removing the last character
        rename `var' `newname' //Rename the variaBle
    }
}

//recode those ending in capital letters 

ds
local vars_to_change ""

foreach var of varlist `r(varlist)' {
    if regexm("`var'", "[A-J]$") {   // Check if the variaBle name ends with A–J
        local vars_to_change "`vars_to_change' `var'"
    }
}

display "`vars_to_change'"  // Print the list of affected variaBles


* Replace variaBles starting with "CA" "CB", "CC" with numeric values 10 11 12, respectively 
foreach var of varlist _all {
    * If the variaBle starts with "CA", replace it with "C10"
    if substr("`var'", 1, 2) == "ca" {
        local newname = "c10" + substr("`var'", 3, .)  // Keep characters after "CA"
        rename `var' `newname'
    }
    * If the variaBle starts with "CB", replace it with "C11"
    if substr("`var'", 1, 2) == "cb" {
        local newname = "c11" + substr("`var'", 3, .)  // Keep characters after "CB"
        rename `var' `newname'
    }
    * If the variaBle starts with "CC", replace it with "C12"
    else if substr("`var'", 1, 2) == "cc" {
        local newname = "c12" + substr("`var'", 3, .)  // Keep characters after "CC"
        rename `var' `newname'
    }
}

//estimate and remember the total 
//douBle check the sum of x vars 
de c*
egen temp_xtotal99 = rowtotal(c*)
sum temp_xtotal99
local temp_xtotal99_check = r(sum)
di "`temp_xtotal99_check'"
sum idhh 


* Reshape the dataset with variaBles to Be transformed from wide to long 
reshape long c, i(idhh) j(variable) string
rename c value
		
duplicates report idhh variable
//check N of categories 
quietly distinct variable
local unique_count = r(ndistinct)
display "`unique_count'" 

* Keep four first digits only = remove the last character from all the values
gen new_variable = substr(variable, 1, length(variable) - 1) 
destring new_variable, replace
//check N of categories 
quietly distinct new_variable
local unique_count = r(ndistinct)
display "`unique_count'" 
//check the total 
sum value, meanonly  
local value_total_check = r(sum)
di "`value_total_check'"  
assert abs(`temp_xtotal99_check' - `value_total_check') < 0.1
 
drop if idhh==. 
drop variable 
rename new_variable variable 


* Aggregate values at 4 digit COICOP level  
collapse (sum) value, by(idhh variable)
rename value c 
//check N of categories 
quietly distinct variable  
local unique_count_collapsed = r(ndistinct)
display "`unique_count_collapsed'" 
assert abs(`unique_count' - `unique_count_collapsed') < 0.1


* Reshape aggregated variaBles Back to wide format 
reshape wide c, i(idhh) j(variable) 

ds c*
foreach var in `r(varlist)' {
    local length = strlen("`var'")
    
    if `length' == 5 {  // c + 4 digits
        local newname = "x0" + substr("`var'", 2, .)
        display "Renaming `var' → `newname'"
        rename `var' `newname'
    }
    else if `length' == 6 {  // c + 5 digits
        local newname = "x" + substr("`var'", 2, .)
        display "Renaming `var' → `newname'"
        rename `var' `newname'
    }
}

save "$data\expend_LCF", replace 

use "$data\expend_LCF", clear  
* Merge other variables from matched LCF-UKMOD, including expenditures from the HH questionnaire 
//Note: Expenditure on retrospective recall is converted to a weekly equivalent value. That is, if the recall period is one year, then the weekly equivalent value is calculated by dividing by 52.
merge 1:1 idhh using "$data\ukmod-lcf-matched-allvbles.dta", ///
keepusing (id_lcf eqincdop income_net_lcf c_food c_alcohol c_clothing c_housing c_bills c_health c_transport c_comms c_recreation c_education c_resthotels c_miscell c_noncons c_totorig ///
b010 ///
b020 ///
b050 ///
b060 ///
b102 ///
b104 ///
b107 ///
b108 ///
b159 ///
b175 ///
b178 ///
b170 ///
b173 ///
b018 ///
b017 ///
b270 ///
b271 ///
b244 ///
b245 ///
b247 ///
b249 ///
b250 ///
b252 ///
b248 ///
b218 ///
b217 ///
b219 ///
b216 ///
b487 ///
b488 ///
b1661 ///
b195 ///
b162 ///
b181 ///
b191 ///
b192 ///
b193 ///
b480 ///
b481 ///
b2441 ///
b2451 /// 
b160 ///
b164 ///
b1601 ///                       	
b1602 ///                                       	
b1603 ///                   	
b1604 ///                                      	
b1605 ///                                               	
b1641 ///       	
b1642 ///                     	
b1643 /// 	
b1644 ///                   	
b1645 ///	
b260 ///
b482 ///
b483 ///
b484 ///
b485 ///
b110 ///
b168 ///
b188 ///
b229 ///
b1802 ///
b238 ///
b273 ///
b280 ///
b281 ///
b282 ///
b283 )

drop _merge
//rename vars that will be kept in the input data 
rename id_lcf x_idhh //EXPENDITURE : LCF Household ID
rename eqincdop x_ydses	//EXPENDITURE : LCF Equivalised income (OECD Scale) - top-coded 
rename income_net_lcf x_yds //EXPENDITURE : Normal disposable household income - anonymised (GBP)
rename c_food xtotal01	//EXPENDITURE :COICOP: total food and non-alcohlic Beverages
rename c_alcohol xtotal02	//EXPENDITURE :COICOP: alcohlic Beverages, toBacco, and narcotics
rename c_clothing xtotal03	//EXPENDITURE :COICOP: clothing and footwear
rename c_housing xtotal04	//EXPENDITURE :COICOP: housing, water, electricity, gas and other fuels
rename c_bills xtotal05	//EXPENDITURE :COICOP: furninshing, HH equipment and routine maintanance of the house
rename c_health xtotal06	//EXPENDITURE :COICOP: health
rename c_transport xtotal07	//EXPENDITURE :COICOP: transport
rename c_comms xtotal08	//EXPENDITURE :COICOP: communication
rename c_recreation xtotal09	//EXPENDITURE :COICOP: recreation and culture
rename c_education xtotal10	//EXPENDITURE :COICOP: education
rename c_resthotels xtotal11	//EXPENDITURE :COICOP: resturant and hotels
rename c_miscell xtotal12	//EXPENDITURE :COICOP: miscelaneous goods and sevices
rename c_noncons xtotal20	//EXPENDITURE :COICOP: non-consumption expenditure
rename c_totorig xtotal00	//EXPENDITURE :COICOP: Total consumption expenditure - children and adults



****************************************************************************************
* Mapping expenditure variables from HH questionnaire into 4 digit COICOP categories
****************************************************************************************
/*Note: this is only needed for 2022/23 because it is not properly cleaned - might not be needed with the new release
ds b*
foreach var in `r(varlist)' {
    local first = substr("`var'", 1, 1)
    local rest = substr("`var'", 2, .)
    local newname = upper("`first'") + "`rest'"
    rename `var' `newname'
}
*/
/*P604t	COICOP: Total Housing, Water, Electricity
egen P604t_sum =  rowtotal(B010   B020   B050   /*B053u   B056u*/   B060   B102   B104   B107  B108   B159  B175 -B178  /*B222*/  B170 -B173  /*B221*/   B018   B017  ///
C41211t   C43111t   C43112t   C43212c   /*C44112u*/   C44211t   C45112t   C45114t   C45212t   C45214t   C45222t   C45312t   C45411t   C45412t   C45511t )
*/
egen x04111 = rowtotal(b010 b020 b159) //b010 Rent/rates - last net payment + b020 Net rent - service charge deducted + b159 Service charge included in rent - amount

gen x04411 = b050 //b050 Water charges - last net payment

egen x04321_ = rowtotal(x04321 b102 b104 b107 b108) //b102 Central heating repairs - second dwelling + b104 Central heating repairs - main dwelling + b107 House maintenance etc - main dwelling + b108 House maintenance etc - second dwelling
drop x04321
rename x04321_ x04321

egen x04511_ = rowtotal(x04511 b175 -b178) //b175	Electricity - amount paid in last account - b178 Rebate for separate Electricity amount
drop x04511
rename x04511_ x04511

egen x04521_ = rowtotal(x04521 b170 -b173) //b170	Gas - amount paid in last account - b173 Rebate for separate Gas amount
drop x04521
rename x04521_ x04521

egen x04522_ = rowtotal(x04522 b018) //b018 bottled gas for central heating
drop x04522
rename x04522_ x04522

egen x04531_ = rowtotal(x04531 b017) //b017 Oil for central heating - last quarter
drop x04531
rename x04531_ x04531

gen x04441 = b060 //b060 Other regular housing payments


/*P605t	COICOP: Total Furnishings, HH Equipment, Carpets
egen P605t_sum =  rowtotal(B270   B271   ///
C51111c   /*C51112t*/   C51113t   C51114t   C51211c   C51212t   C51311t   C52111t   C52112t   C53111t   C53121t   C53122t   ///
C53131t   C53132t   C53133t   C53141t   C53151t   C53161t   C53171t   C53211t   C53311t   C53312t   C53313t   C53314t   C54111t   ///
C54121t   C54131t   C54132t   C54141t   C55111t   C55112t   C55211t   C55212t   C55213t   C55214t   C56111t   C56112t   C56121t ///
C56122t   C56123t   C56124t   C56125t   C56211t   C56221t   C56222t   C56223t) 
*/
egen x05111_ = rowtotal(x05111  b270) //b270 Furniture 
drop x05111
rename x05111_ x05111

egen x05121_ = rowtotal(x05121 b271) //b271	Soft floor covering 
drop x05121
rename x05121_ x05121

/*P607	COICOP: Total Transport Costs
egen P607t_sum =  rowtotal(B244   B245   B247   B249   B250   B252   B248   B218   B217  B219   B216   B487   B488  ///
 C71111c   C71112t   C71121c   C71122t   C71211c   C71212t  C71311t   C71411t   C72111t   C72112t   C72113t   C72114t   C72115t  C72211t   C72212t ///
 C72213t   C72311c   C72312c   C72313t   C72314t   C72411t   C72412t   C72413t   C72414t   C73112t   C73212t   C73213t   C73214t   C73411t ///
 C73512t   C73513t   C73611t ) 
 */
egen x07111_ = rowtotal(x07111 b244) //Vehicle - cost of new car | van outright 
drop x07111
rename x07111_ x07111 
 
egen x07112_ = rowtotal(x07112 b245) //Vehicle - cost of 2nd hand car | van outright 
drop x07112
rename x07112_ x07112

egen x07121_ = rowtotal(x07121 b247) //Vehicle - cost of motorcycles outright 
drop x07121
rename x07121_ x07121
 
egen x07231_ = rowtotal(x07231 b249 b250 b252) //b249	Car or van - servicing: amount paid + b250	Car or van - other works, repairs: amount paid + b252 Motorcycle - services, repairs: amount paid
drop x07231
rename x07231_ x07231
 
egen x07241_ = rowtotal(x07241 b248)  //b248	Car leasing - expenditure on
drop x07241
rename x07241_ x07241

egen x07311_ = rowtotal(x07311  b218)  //b218	Season ticket - rail / tube - total net amount
drop x07311
rename x07311_ x07311

egen x07321_ = rowtotal(x07321  b217)  // b217	Season ticket - bus / coach - total net amount
drop x07321
rename x07321_ x07321

egen x07341_ = rowtotal(x07341  b219)  // b219	Water travel season ticket
drop x07341
rename x07341_ x07341

egen x07351_ = rowtotal(x07351  b216)  // b216	Bus   tube and/or rail season
drop x07351
rename x07351_ x07351

egen x07331 = rowtotal(b487 b488)  // b487	Domestic flight expenditure + b488	International flight expenditure

 
/*P608t	COICOP: Total Communication
egen P608t_sum =  rowtotal(/*B166*/   B1661   B195   C81111t   C82111t   C82112t   C82113t   C83111c   C83112t   C83113c   C83114t   C83115t )
*/

egen x08311_ = rowtotal(x08311 b1661)  //b1661	Mobile telephone account (contract), hhold
drop x08311
rename x08311_ x08311 

gen x08330 = b195 //b195	Internet - weekly amount

/*P609t 	COICOP: Total Recreation
egen P609t_sum =  rowtotal(B162   B181   B191   B192   B193   B480   B481   B2441  B2451  ///
 C91111t   C91112t   C91113t   C91121t   C91122t   C91123t   C91124t   C91125t   C91126t   C91127t   C91128t   C91211t   C91221t   C91311t   C91411t  ///
 C91412t   C91413t   C91414t   C91511t   C92111t   C92112t   C92117t   C92211t   C92221t   C92311t   C93111t   C93112t   C93113t   C93114t   C93211t  ///
 C93212t   C93311t   C93312t   C93313t   C93411t   C93412t   C93511t   C94111t   C94112t   C94113t   C94114c   C94115t   C94211t   C94212t   C94221t  ///
 C94231c   C94232t   C94233c   /*C94234c*/   C94235c   C94236t   C94237c   C94238t   C94239t   C94241t   C94242t   C94243t   C94244t   C94245t   C94246t ///
 C94311t   C94312t   C94313t   C94314t   C94315t   C94316t   C94319t   C95111t   C95211t   C95212t   C95311t   C95411t   C96111c   C96112c   C92113c ///
 C92114t   C92115c   C92116t ) 
 */
egen x09411_ = rowtotal(x09411 b162) //b162	Leisure class fees paid - amount
drop x09411
rename x09411_ x09411

egen x09423_ = rowtotal(x09423 b181 b191 b192 b193)  //b181	TV licence - amount paid last year + b191	Rent for TV\Satellite\VCR weekly amount + b192	Satellite subscription - weekly amount + b193	Cable subscription - weekly amount
drop x09423
rename x09423_ x09423

egen x09611_ = rowtotal(x09611 b480 b481) //b480	Holiday package within United Kingdom + b481	Holiday package outside United Kingdom
drop x09611
rename x09611_ x09611

egen x09211_ = rowtotal(x09211 b2441 b2451) //b2441	Vehicle - cost of new motor caravan outright + b2451	Vehicle cost of 2nd hand motor caravan outright
drop x09211
rename x09211_ x09211


/*P610t	COICOP: Total Education
//egen P610t_sum =  rowtotal(B160   B164  //CA1111c   CA1112c   CA1113t   CA2111c  CA2112c   CA2113t   CA3111c   CA3112c   CA3113t   CA4111c   CA4112c   CA4113t   CA5111c   CA5112c   CA5113t) 
*/
/* Note these can be dissaggregated by level: 
b160	Education – total amount paid last quarter
b164	Members outside household – total educ fees for last quarter

b1601	Amount paid for nursery and primary education last quarter                       	
b1602	Amount paid for secondary education last quarter                                       	
b1603	Amount paid for sixth form/college education last quarter                   	
b1604	Amount paid for uni education last quarter                                      	
b1605	Amount paid for other education last quarter                                               	

b1641	Members outside hhold – educ fees on nursery & primary last quarter       	
b1642	Members outside hhold – educ fees on secondary last quarter                     	
b1643	Members outside hhold – educ fees on 6th form college/college last quarter	
b1644	Members outside hhold – educ fees on university last quarter                   	
b1645	Members outside hhold – educ fees on other education last quarter	
*/
egen x10111_ = rowtotal(x10111 b1601 b1641) //b1601	Amount paid for nursery and primary education last quarter + b1641	Members outside hhold – educ fees on nursery & primary last quarter          
drop x10111
rename x10111_ x10111

egen x10211_ = rowtotal(x10211 b1602 b1642) //b1602	Amount paid for secondary education last quarter + b1642 Members outside hhold – educ fees on secondary last quarter                                       	
drop x10211
rename x10211_ x10211

egen x10311_ = rowtotal(x10311 b1603 b1643) //b1603	Amount paid for sixth form/college education last quarter +  b1643	Members outside hhold – educ fees on 6th form college/college last quarter                                      	
drop x10311
rename x10311_ x10311

egen x10411_ = rowtotal(x10411 b1604 b1644) //b1604	Amount paid for uni education last quarter  +  b1644	Members outside hhold – educ fees on university last quarter                                	
drop x10411
rename x10411_ x10411
  
egen x10511_ = rowtotal(x10511 b1605 b1645) //b1605	Amount paid for other education last quarter  +   b1645	Members outside hhold – educ fees on other education last quarter	                     	
drop x10511
rename x10511_ x10511

/*P611t	COICOP: Total Restaurants and Hotels
egen P611t_sum =  rowtotal(B260   B482   B483   B484   B485 ///
  CB1111t   CB1112t   CB1113t   CB1114t   CB1115t   CB1116t   CB1117c   CB1118c   CB1119c   CB111Ac   CB111Bc   CB111Ct   CB111Dt   CB111Et ///
  CB111Ft   CB111Gt   CB111Ht   CB111It   CB111Jt   CB1121t  CB1122t   CB1123t   CB1124t   CB1125t   CB1126t   CB1127t   CB1128t   CB112Bt   CB1213t) 
*/
egen x11121_ = rowtotal(x11121 b260) //B260 School meals - total amount paid last week	                     	
drop x11121
rename x11121_ x11121

egen x11211 = rowtotal(b482 b483 b484 b485) //b482	Holiday hotel within United Kingdom + b483 Holiday hotel outside United Kingdom	+ b484	Holiday self-cathering within United Kingdom + b485	Holiday self-cathering outside United Kingdom                     	


/*P612t COICOP: Total Miscellaneous Goods and Services
egen P612t_sum = rowtotal(B110   B168   B188   B229   B1802   B238   B273   B280  B281   B282   B283  ///
 CC1111t   CC1211t   CC1311t   CC1312t   CC1313t  CC1314t   CC1315t   CC1316t   CC1317t   /*CC2111t*/   CC3111t   CC3112t  CC3211t   CC3221t   CC3222t ///
 CC3223t   CC3224t   CC4111t   CC4112t  CC4121t   CC4122t   CC5213t   CC5411c   CC5412t   CC5413t  CC6211c   CC6212t   CC6214t   CC7111t   CC7112t  ///
 CC7113t   CC7114t  CC7115t   CC7116t    CC5311c ) 
*/
egen x12521_ = rowtotal(x12521 b110  b168) //b110	Insurance connected with the dwelling + b168 Contents insurance - amount of last premium		                     	
drop x12521
rename x12521_ x12521

egen x12541_ = rowtotal(x12541 b188) //b188 Vehicle insurance - amount paid last year		                     	
drop x12541
rename x12541_ x12541

egen x12531_ = rowtotal(x12531 b229) //b229	Medical insurance - total amount premium			                     	
drop x12531
rename x12531_ x12531

egen x12621_ = rowtotal(x12621 b1802 b238) //b1802	Bank & Building societies charges - net amount last 3 months + b238	Annual standing charge for credit cards - weekly amount	B229) //b229	Medical insurance - total amount premium			                     	
drop x12621
rename x12621_ x12621

egen x12711_ = rowtotal(x12711 b273 b280 b281 b282 b283)  //b273 Furniture removal and/or storage + b280	Property transaction - purchase and sale + b281	Property transaction - sale only + b282	Property transaction - purchase only + b283	Property transaction - other payments				                     	
drop x12711
rename x12711_ x12711

/*
P620tp	COICOP: Total Non Consumption Expenditure (anonymised)
egen P620t_sum = rowtotal(B130   B150  B208   /*B213*/  B2081   B038p   B030  B187 -B179  B334h   B265   B237     B228   B196  B197   B198   ///
  B199   B1961   B1981   B2011   B201  B202   B205   B206   CK1315t   CK1316t   CK1412t   CK2111t   CK3111t   CK3112t   CK4111t   CK4112t   CK5221t   CK5222t ///
  CK5223t   CK5224c   CK5212t   CK5213t   CK5214t   CK5215t   CK5216t   CK5315c   CK5111t   CK5113t   CK1313t   CK1314t   CC5111c   CC5312c   CC5511c) 
*/

// Convert weekly LCF variables to monthly, excluding x_yds, x_idhh
foreach var of varlist x* {
    if !inlist("`var'", "x_yds", "x_idhh") {
        replace `var' = `var' * 4.36  
    }
}
// Adjust for inflation all x* vars , excluding x_yds, x_idhh, and any variable starting with xtotal because these were already adjusted 
foreach var of varlist x* {
    if !inlist("`var'", "x_yds", "x_idhh") & !regexm("`var'", "^xtotal") {
        replace `var' = `var' * $CPI 
    }
}


//check sums within each category 
local cat "01 02 03 04 05 06 07 08 09 10 11 12" 
foreach cat in `cat' {  
egen xtotal99_`cat' = rowtotal(x`cat'*)
sum xtotal99_`cat' xtotal`cat'
} 
cap drop xtotal99
egen xtotal99 = rowtotal(xtotal99_01 xtotal99_02 xtotal99_03  xtotal99_04  xtotal99_05   xtotal99_06  xtotal99_07  xtotal99_08 xtotal99_09 xtotal99_10  xtotal99_11  xtotal99_12)
sum xtotal99 xtotal00
/*Note: there are 5 hholds with negative values in xtotal00 which is due to having negative value on B010 (b010 Rent/rates - last net payment) and unrealistically small values on other consumption categories*/

//check for missing values 
foreach var of varlist x* {
qui count if `var' == .
if (r(N) > 0) noi di in r "variable `var' has " r(N) " missing values!"
qui count if `var' == 0
if (r(N) > 0) noi di in r "variable `var' has " r(N) " zero values!"
sum `var' if `var'>0 & `var'<. 
} 

count 

sum xt* x_y* 

* remove missing & negative values 
foreach var of varlist x* {
replace `var' = 0 if `var'==. | `var'<0
 
} 
*******************************
** Save final processed data **
*******************************
drop b* //B*
sum 

save "$data\expend_LCF", replace 


*********************
** Clean up folder **
*********************
*fs *.dta

#delimit ;
local files_to_drop 
LCF_FRS_C_variables_keep.dta     
ukmod-lcf-compare.dta
ukmod-lcf-matched-allvbles.dta
ukmod-lcf-matched-long.dta
ukmod-lcf-matched.dta
ukmod-lcf.dta
ukmod-matched.dta
ukmod-tmp.dta
lcf-matched.dta
ukmod.dta
lcf-tmp.dta
lcf.dta
lcf_frs_c_variables_keep.dta  
lcf_pers_collapsed.dta  
	;
#delimit cr // cr stands for carriage return

foreach file in `files_to_drop' {
    capture erase "$data/`file'"
}



