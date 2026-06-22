***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         09_Assets.do
* DESCRIPTION:          Create asset variables 
* INPUT FILE:           househol, renter
* OUTPUT FILE:          assets
* NEW VARs:
*                       - amrrm 		Assets - Number of rooms/bedrooms in house 
*                       - amriv00 		Assets - Council Tax Band
*						- amrtn 		Assets - Housing tenure
*                       - afc 			Assets - Value of Financial capital
* LAST UPDATE:           11/06/2026
***************************************************************************************
cap log close 
log using "${log}/09_Assets.log", replace
use sernum rooms rooms10 bedroom bedroom6 tenure ptentyp2 tentyp2 ctband using $data/househol, clear
	sort sernum 
	save temp, replace
use sernum landlord accjob using $data/renter,clear
	sort sernum
	merge sernum using temp
	ta _merge
	gen renter=(_merge==3)
	drop _merge
	de
	su
	
	
*******************************************************************
* amrrm - Number of rooms/bedrooms in house 

* rooms10 - Total number of rooms - max of 10
* bedroom6 - Number of bedrooms - max of 6
*******************************************************************
	if ${use_assert} assert rooms10!=. & bedroom6!=.
	gen amrrm = bedroom6 // we need bedrooms not rooms! otherwise use rooms10
	label var amrrm "Number of bedrooms (max of 6)"

*******************************
*  amriv00 - Council Tax Band

* ctband - Council Tax band	
*	1	Band A
*	2	Band B
*	3	Band C
*	4	Band D
*	5	Band E
*	6	Band F
*	7	Band G
*	8	Band H
*	9	Band I
*	10	Household not valued separately
*******************************
	ta ctband
	gen amriv00=ctband
	replace amriv00 = -1 if ctband==.
	label var amriv00 "Council Tax Band"

************************************************************************************
* amrtn - Housing tenure
* 1 Owned on mortgage
* 2 Owned outright
* 3 Rented
* 4 Reduced Rented
* 5 Social Rented
* 6 Free
* 7 Other

* ptentyp2 - Tenure type - PUB	
*	1	Rented from Council
*	2	Rented from Housing Association
*	3	Rented privately unfurnished
*	4	Rented privately furnished
*	5	Owned outright
*	6	Owned with mortgage
* tentyp2 - Tenure type (housing analysts full breakdown - see also PTENTYP)	
*	1	LA / New Town / NIHE / Council rented
*	2	Housing Association / Co-Op / Trust rented
*	3	Other private rented unfurnished
*	4	Other private rented furnished
*	5	Owned with a mortgage (includes part rent / part own)
*	6	Owned outright
*	7	Rent-free
*	8	Squats
* tenure - Tenure	
*	1	Owns it outright
*	2	Buying with the help of a mortgage
*	3	Part own, part rent
*	4	Rents
*	5	Rent-free
*	6	Squatting
* landlord - Landlord	
*	1	LA/Council/New Town/Scottish Homes/NIHE
*	2	Housing Association/Trust
*	3	Employer (organisation) of a hh member
*	4	Another organisation
*	5	Relative/friend of a household member
*	6	Employer (individual) of a hh member
*	7	Another indiv/private landlord/letting agency
* accjob - Whether accommodation goes with job (1 yes, 2 no)
************************************************************************************
	ta ptentyp2
	ta tentyp2
	ta tenure
	*la list PTENTYP2 TENTYP2 TENURE */ ptentyp2 tentyp2 tenure
	gen amrtn=0
	replace amrtn=1 if ptentyp2==6                		/*owned with mortgage*/
	replace amrtn=2 if ptentyp2==5						/*own outright*/
	replace amrtn=5 if ptentyp2==1|ptentyp2==2      	/*social rented*/
	ta tenure
	la list TENURE
	replace amrtn=6 if tenure==5							/*rent free*/
	replace amrtn=7 if tenure==6							/*other: squatting*/
	ta landlord
	la list LANDLORD ACCJOB
	replace amrtn=4 if ((landlord>2 & landlord<7)|(accjob==1)) & amrtn==0		/*reduced rent assumed if landlord is employer, other org., relative, friend*/
	replace amrtn=3 if amrtn==0							/*residual: rented (non social; non reduced)*/
	label var amrtn "Housing tenure"
	keep sernum amrrm amrtn amriv00
	sort sernum
	save temp, replace
		use sernum person using individual
		sort sernum person
		merge sernum using temp
		assert _merge==3
		drop _merge
		sort sernum person 
		save assets, replace			


************************************
* afc - Value of Financial capital

* totcapb3 - BU - Total capital - v3
************************************
	use sernum benunit totcapb3 totcapb4 using $data/benunit, clear // totcapb2 replaced by totcapb3 in second version of FRS 2009/10
	
	sum totcapb3 totcapb4
	sum totcapb4 if totcapb4>0
		sort sernum benunit
		save temp, replace
		de
	use sernum benunit person adult using individual
		sort sernum benunit
		merge m:m sernum benunit using temp
		assert _merge==3
		drop _merge
		de
		gsort sernum benunit -adult person
		by sernum benunit, sort: gen pers_bu=_n 
	gen afc=totcapb3
	if ${use_assert} assert adult==1 if pers_bu==1 
		replace afc=0 if pers_bu!=1	/*assigned to 1 adult in benefit unit*/
	label var afc "Financial capital"
	keep sernum person afc 
	sort sernum person
	merge sernum person using assets
	assert _merge==3
	drop _merge
	sort sernum person 
	save assets, replace

************************************
* aca - Cars																		
************************************
* information not available before FRS 2014/15 and from FRS 2017/18
/*	use sernum benunit eucar using $data/benunit, clear 
		sort sernum benunit
		save temp, replace
		de
	use sernum benunit person adult using individual
		sort sernum benunit
		merge sernum benunit using temp
		assert _merge==3
		drop _merge
		de
		gsort sernum benunit -adult person
		by sernum benunit, sort: gen pers_bu=_n 
	ta eucar, m
	gen aca_bu=eucar						// FRS value 1=yes, 2=no
		replace aca_bu=2 if aca_bu<0			// assume not applicable is like "no"
	bys sernum: egen aca=min(aca_bu)	// assume that if at least one benefit unit within the hh reports to have a car, then everyone else in the hh has access to it too
	if ${use_assert} assert adult==1 if pers_bu==1 
	label var aca "Household owns or has continuous access to a car or van"
	keep sernum person aca 
	sort sernum person
	merge sernum person using assets
	assert _merge==3
	drop _merge
	sort sernum person 
	save assets, replace
*/
************************************
* aco * Computers
************************************
* information not available before FRS 2014/15 and from FRS 2017/18
/*	use sernum benunit computer using $data/benunit, clear 
		sort sernum benunit
		save temp, replace
		de
	use sernum benunit person adult using individual
		sort sernum benunit
		merge sernum benunit using temp
		assert _merge==3
		drop _merge
		de
		gsort sernum benunit -adult person
		by sernum benunit, sort: gen pers_bu=_n 
	ta computer, m
	gen aco_bu=computer						// FRS value 1=yes, 2=no
		replace aco_bu=2 if aco_bu<0			// assume not applicable is like "no"
	bys sernum: egen aco=min(aco_bu)	// assume that if at least one benefit unit within the hh reports to have a computer, then everyone else in the hh has access to it too
	if ${use_assert} assert adult==1 if pers_bu==1 
	label var aco "Household has a home computer"
	keep sernum person aco 
	sort sernum person
	merge sernum person using assets
	assert _merge==3
	drop _merge
	sort sernum person 
	save assets, replace
*/

keep sernum person amrrm amrtn afc amriv00 // aca aco
sort sernum person
save assets, replace
des
	
	
