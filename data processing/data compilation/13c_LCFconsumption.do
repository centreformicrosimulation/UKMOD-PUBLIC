***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         13c_LCFconsumption.do
* DESCRIPTION:          Retrieve expenditure on commodities at COICOP 4 level from the FRS-LCF database 
* LAST UPDATE:          05/10/2023
******************************************************************************************


******************************************************************************************
/* Run R script to obtain consumption data 
shell "$RshellPath" --vanilla <"$rScript1"
shell "$RshellPath" --vanilla <"$rScript2"
********************************************************************************************
*/

cap log close
log using "${log}\13c_LCFconsumption.log", replace
use "${LCF}", clear 
keep sernum C*
save temp_LCF, replace

clear all

use temp_LCF
foreach var of varlist _all {
  if `"`var'"' != "sernum" {
    if regexm("`var'", "^C[0-9]|CB|CC") {
      continue
    }
    else {
      drop `var'
    }
  }
}
save temp_LCF, replace


use temp_LCF

foreach var of varlist C* {
 if regexm("`var'", "CB|CC") {
      continue
    }
    else {
  local newvarname = "xx0" + substr("`var'", 2, .)
  rename `var' `newvarname'
}
}
save temp_LCF, replace

use temp_LCF 

foreach var of varlist C* {
  if regexm("`var'", "CC") {
    local newvarname = "xx12" + substr("`var'", 3, .)
    rename `var' `newvarname'
  }
}

save temp_LCF, replace
use temp_LCF 

foreach var of varlist C* {
 if regexm("`var'", "CB") {
    local newvarname = "xx11" + substr("`var'", 3, .)
    rename `var' `newvarname'
  }
}

save expend_LCF, replace


use expend_LCF

foreach var of varlist xx* {
replace `var' = `var' * (365/52)
} 

save ${data}\expend_LCF, replace 
