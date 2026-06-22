***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         04_CheckIDs.do
* DESCRIPTION:          
*						- Create IDs variables; check consistency of these variables
*						- Create personal socio-demographic variables and household weights
* INPUT FILE:           pers
* OUTPUT FILE:          n/a
* LAST UPDATE:          11/06/2026
***************************************************************************************
cap log close
log using "${log}/04_CheckIDs.log", replace
 
use pers, clear

*** check no loose children: dependent children always have either a father of a mother 
	assert (idfather!=0 | idmother!=0) if dag<16	//1 contradiction in 6,392 observations
	noi list idhh idperson idfather idmother dag if (idfather==0 & idmother==0) & dag<16  
	assert (idfather!=0 | idmother!=0) if adult==0
	noi list idhh idperson idfather idmother dag if (idfather==0 & idmother==0) & adult==0	
	
	
**************
*CHECK IDs.DO 
**************

preserve
set more off
tempfile main partners father mother

global use_assert1 = 1 // specify 

***********************************************************************

* create age/gender/marital status variable if not existing yet
foreach var in dag dgn dms {
	cap confirm var `var'
	if (_rc) gen `var' = . 
}

save `main'

noi sum dag dgn dms

* CHECK IF IDPERSON IS A UNIQUE IDENTIFIER

if ${use_assert1} isid idperson

* CHECK WHETHER IDPERSON == IDHH * 100

gen long temp_idhh = floor(idperson / 100)
if ${use_assert1} assert idhh == temp_idhh

* CHECK FOR REPEATED PERSON ID OR PARTNER ID

sort idperson
count if idperson == idperson[_n-1]
if (r(N) > 0) noi di in r "Inconsistency: person ID has " r(N) " duplicate values!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson if idperson == idperson[_n-1]
if ${use_assert1} assert r(N) == 0

sort idpartner
count if idpartner == idpartner[_n-1] & idpartner != 0
if (r(N) > 0) noi di in r "Inconsistency: partner ID has " r(N) " duplicate values!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner if idpartner == idpartner[_n-1] & idpartner != 0
if ${use_assert1} assert r(N) == 0

* CHECK FOR EQUAL PERSON/FATHER/MOTHER/PARTNER ID-S

count if idperson == idpartner
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where person ID and partner ID are the same!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner if idperson == idpartner
if ${use_assert1} assert r(N) == 0

count if idperson == idfather
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where person ID and father ID are the same!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idfather if idperson == idfather
if ${use_assert1} assert r(N) == 0

count if idperson == idmother
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where person ID and mother ID are the same!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idmother if idperson == idmother
if ${use_assert1} assert r(N) == 0

count if idfather == idpartner & idfather != 0
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where father and partner ID are the same!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner idfather if idfather == idpartner & idfather != 0
if ${use_assert1} assert r(N) == 0

count if idmother == idpartner & idmother != 0
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where mother and partner ID are the same!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner idmother if idmother == idpartner & idmother != 0
if ${use_assert1} assert r(N) == 0

* CHECK IF PARTNER ID IS VALID AND PARTNERS REFER TO EACH OTHER

keep idhh idperson idpartner
rename idpartner spouse_idpartner
rename idperson idpartner
sort idhh idpartner
save `partners'
use `main'
sort idhh idpartner
merge idhh idpartner using `partners', uniqusing
*noi tab _merge
drop if _merge == 2 // people not referred as partners (without partners or with invalid partner ID)
sort idhh idperson

count if idpartner != 0 & _merge == 1 // people with invalid partner ID
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where partner ID refers to a non-existing person!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner if idpartner != 0 & _merge == 1
if ${use_assert1} assert r(N) == 0

count if _merge == 3 & idperson != spouse_idpartner // people not referred back by spouses
if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where a person (with a valid idpartner) is not referred back by his/her partner!"
if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson idpartner if _merge == 3 & idperson != spouse_idpartner
drop _merge
if ${use_assert1} assert r(N) == 0


* CHECK IF FATHER/MOTHER ID IS VALID, THE GENDER AND THE AGE OF FATHER/MOTHER

foreach parent in father mother {
	use `main', clear

	keep idperson idpartner dag dgn
	rename idperson id`parent'
	rename dag `parent'_age
	rename dgn `parent'_gender
	sort id`parent'
	save ``parent'', replace
	use `main'
	sort id`parent'
	merge id`parent' using ``parent'', uniqusing
	*noi tab _merge
	drop if _merge == 2 // people without children
	sort idhh idperson

	count if _merge == 1 & id`parent' != 0
	if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where `parent' ID refers to a non-existing person!"
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' if _merge == 1 & id`parent' != 0
	if ${use_assert1} assert r(N) == 0

		
	gen age_diff = `parent'_age - dag
	count if age_diff <= 0
	if (r(N) > 0) noi di in r "Inconsistency: there are " r(N) " observations where a `parent' is younger or same age with the child!"
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' dag `parent'_age if age_diff <= 0, ab(15)
	noi list idhh idperson id`parent' id`parent'bio dag `parent'_age if age_diff <= 0
	//if ${use_assert1} assert r(N) == 0

	
    count if `parent'_age < 15
	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where a `parent' is less than 15 years old."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' id`parent'bio dag `parent'_age age_diff if `parent'_age < 15
	if ${use_assert1} assert r(N) == 0

	count if age_diff < 15
	replace id`parent'bio = 0 if age_diff < 14 & id`parent'bio != 0
	
	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where the `parent' is less than 15 years older than the child."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' id`parent'bio dag `parent'_age age_diff if age_diff < 15
	noi tab age_diff if age_diff < 15, m
	
	count if `parent'_gender == 0 + 1 * ("`parent'" == "mother")

	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where `parent' ID refers to wrong sex."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' id`parent'bio `parent'_gender if `parent'_gender == 0, ab(15)
	if ${use_assert1} assert r(N) == 0
}


* CHECK FOR INCONSISTENCIES BETWEEN PARTNER AND MARITAL STATUS

count if dms == 2 & idpartner == 0
if (r(N) > 0) noi di in y "Warning: there are " r(N) " married persons with no partner in the household."
tab dms if idpartner > 0
*Warning: there are 375 married persons with no partner in the household.
restore

cap log close

