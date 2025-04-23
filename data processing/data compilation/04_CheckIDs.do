***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         04_CheckIDs.do
* DESCRIPTION:          
*						- Create IDs variables; check consistency of these variables
*						- Create personal socio-demographic variables and household weights
* INPUT FILE:           pers
* OUTPUT FILE:          n/a
* LAST UPDATE:          20/06/2024
***************************************************************************************
cap log close
log using "${log}/04_CheckIDs.log", replace
 
use pers, clear

*** check no loose children: dependent children always have either a father of a mother 
	*assert (idfather!=0 | idmother!=0) if dag<16	//7 contradictions in 9,835 observations
	noi list idhh idperson idfather idmother dag if (idfather==0 & idmother==0) & dag<16  
	*assert (idfather!=0 | idmother!=0) if adult==0
	noi list idhh idperson idfather idmother dag if (idfather==0 & idmother==0) & adult==0			
	/*
	   +----------------------------------------------+
       |  idhh   idperson   idfather   idmother   dag |
       |----------------------------------------------|
  333. |   154      15402          0          0    15 |grandparent 
  334. |   154      15403          0          0    13 |
 3849. |  1822     182203          0          0    12 |grandparents 
11042. |  5191     519102          0          0    13 |grandparent
11043. |  5191     519103          0          0     9 |
       |----------------------------------------------|
11044. |  5191     519104          0          0     4 |
40006. | 18761    1876103          0          0    12 |grandparents + one older relative? 
       +----------------------------------------------+
*/
	
	
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
	noi list idhh idperson id`parent' dag `parent'_age if age_diff <= 0
	//if ${use_assert1} assert r(N) == 0
/*
	Inconsistency: there are 3 observations where a father is younger or same age with 
> the child!

       +-----------------------------------------------+
       | idhh   idperson   idfather   dag   father_age |
       |-----------------------------------------------|
10029. | 4710     471002     471003    63           14 |
20526. | 9660     966002     966001    53           26 |
20527. | 9660     966003     966001    52           26 |
       +-----------------------------------------------+

       +---------------------------------------------+
       | idhh   idperson   idfather   dag   father~e |
       |---------------------------------------------|
10029. | 4710     471002     471003    63         14 |
20526. | 9660     966002     966001    53         26 |
20527. | 9660     966003     966001    52         26 |
       +---------------------------------------------+

	Inconsistency: there are 3 observations where a mother is younger or same age with 
> the child!

       +------------------------------------------------+
       |  idhh   idperson   idmother   dag   mother_age |
       |------------------------------------------------|
 5707. |  2688     268802     268804    44           14 |
19004. |  8941     894102     894103    34           16 |
31429. | 14799    1479901    1479902    80           80 |
       +------------------------------------------------+

       +----------------------------------------------+
       |  idhh   idperson   idmother   dag   mother~e |
       |----------------------------------------------|
 5707. |  2688     268802     268804    44         14 |
19004. |  8941     894102     894103    34         16 |
31429. | 14799    1479901    1479902    80         80 | OK, age is truncated at 80, mother must be older than that 
       +----------------------------------------------+
*/

	count if `parent'_age < 15
	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where a `parent' is less than 15 years old."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' dag `parent'_age age_diff if `parent'_age < 15
	if ${use_assert1} assert r(N) == 0

/*	Warning: there are 1 observations where a mother is less than 15 years old.

       +--------------------------------------------------------+
       | idhh   idperson   idmother   dag   mother~e   age_diff |
       |--------------------------------------------------------|
18431. | 8669     866903     866902     5          6          1 |
       +--------------------------------------------------------+
*/
		
	count if age_diff < 15
	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where the `parent' is less than 15 years older than the child."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' dag `parent'_age age_diff if age_diff < 15
	noi tab age_diff if age_diff < 15, m
	
/*	Warning: there	are 28 observations where the	father is	less than	15	years	older	than the child.

Warning: there	are 28 observations where the	father is	less than	15	years	older	tha
> n the child.

				
        idhh	idperson   idfather   dag	father~e	age_diff	
				
2867.   1341	134102     134103    24	33	9	
3715.   1763	176302     176301    41	51	10	
6525.   3072	307203     307202    68	80	12	
8764.   4124	412403     412402    17	26	9	
8765.   4124	412404     412402    16	26	10	
				
8994.   4231	423103     423102    22	34	12	
9488.   4466	446603     446601    14	27	13	
14489.   6820	682003     682001    24	38	14	
19005.   8941	894103     894101    16	30	14	
20878.   9829	982903     982901    18	30	12	
				
20879.   9829	982904     982901    17	30	13	
23123.  10881	1088103    1088102    29	40	11	
23504.  11057	1105703    1105701    13	27	14	
23505.  11057	1105704    1105701    15	27	12	
23506.  11057	1105705    1105701    17	27	10	
				
23507.  11057	1105706    1105701    21	27	6	
23515.  11062	1106201    1106203    69	80	11	
28608.  13448	1344803    1344802    15	27	12	
28609.  13448	1344804    1344802    13	27	14	
31315.  14742	1474201    1474203    18	19	1	//to fix 
				
31316.  14742	1474202    1474203    17	19	2	//to fix
31819.  14981	1498101    1498103    71	80	9	
32120.  15123	1512301    1512303    66	80	14	
35164.  16538	1653803    1653801    33	47	14	
41802.  19607	1960701    1960704    66	80	14	
				
43962.  20625	2062503    2062501    19	33	14	
46744.  21920	2192003    2192002    12	24	12	
48429.  22703	2270303    2270302    20	34	14	
				

*/	
/*
Inconsistency: there are 1 observations where a mother is younger or same age with 
> the child!

       +------------------------------------------------+
       |  idhh   idperson   idmother   dag   mother_age |
       |------------------------------------------------|
31429. | 14799    1479901    1479902    80           80 | OK, truncated age 
       +------------------------------------------------+

       +----------------------------------------------+
       |  idhh   idperson   idmother   dag   mother~e |
       |----------------------------------------------|
31429. | 14799    1479901    1479902    80         80 |
       +----------------------------------------------+
*/

	count if `parent'_gender == 0 + 1 * ("`parent'" == "mother")

	if (r(N) > 0) noi di in y "Warning: there are " r(N) " observations where `parent' ID refers to wrong sex."
	if (r(N) > 0 & r(N) <= ${maxN_obs_listed}) noi list idhh idperson id`parent' `parent'_gender if `parent'_gender == 0, ab(15)
	if ${use_assert1} assert r(N) == 0
}


* CHECK FOR INCONSISTENCIES BETWEEN PARTNER AND MARITAL STATUS

count if dms == 2 & idpartner == 0
if (r(N) > 0) noi di in y "Warning: there are " r(N) " married persons with no partner in the household."
tab dms if idpartner > 0
*Warning: there are 375 married persons with no partner in the household.
restore

cap log close

