***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         17_UKDatabase.do
* INPUT FILE:           UK_${frsyr}_${data_source}${data_ver}_16b
* OUTPUT FILE:          UKMOD input database (UK_${frsyr}_${data_source}${data_ver})
* DESCRIPTION:          Create final UKMOD database (drop variables that are not needed, rename variables) 
* LAST UPDATE:          28/06/2024
***************************************************************************************
capture log close
log using "${log}/17_UKDatabase.log", replace     

*use "${data}/UK_${frsyr}_${data_source}${data_ver}_16b", clear	
*de, short 
/*DP: Future reforms are not used therefore output file needs to be updated*/

use "${data}/UK_${frsyr}_${data_source}${data_ver}_15", clear	
de, short



******************************
* IB/c-ESA in base data (period t)
******************************
*globals t and t1 defined in do-file IBESA
/*
global t 21
global t1 22
*/
********************************************************
* IB/ESA entitlement as observed in the data in period t
********************************************************
de bdict* bsa* bdisv bcrdi
su bdict* bsa* bdisv bcrdi

count if bdict>0	
count if bdict01>0	
count if bdict02>0	
count if bdict01>0 & bdict02>0	


/*
ge bdict01${t}=bdict01
cap drop bdict02${t}
ge bdict02${t}=bdict02
la var bdict01${t} "IB observed in 20${t}"
la var bdict02${t} "c-ESA observed in 20${t}"

su bdict01${t} bdict02${t}
su bdict01${t} if bdict01${t}>0	
su bdict02${t} if bdict02${t}>0	
*/
*rename ddictnw ddipd
/*
******************************
* IB/c-ESA in t+1
******************************
ge bdict01${t1}=0 // nobody receives IB in t+1

ta ddict02${t1}		
su bdict02${t1}
su bdict02${t1} if bdict02${t1}>0	
*/

***********************************************************************
* 2014/20 - pensioners in t moved into work in t+x due to rise in SPA
*********************************************************************** 
/*
ge lemiw=. 
lab var lemiw "moved from retirement to work in relevant year"
//replace lemiw = 19 if lemiw==. & pen==1 & emp19==1 & dag==64 & dgn==0 // 65 is SPA in 2019 for women
//replace lemiw = 20 if lemiw==. & pen==1 & emp20==1 & dag==64 & dgn==0 // 65 is SPA in 2020 for women (some get retired aged 66)
replace lemiw = 21 if lemiw==. & pen==1 & emp20==1 & dag==65 & dgn==0 // 66 is SPA from 2021 onwards for women
replace lemiw = 21 if lemiw==. & pen==1 & emp20==1 & dag==65 & dgn==1 // 66 is SPA from 2021 onwards for men
replace lemiw=999 if lemiw==.									
ta lemiw

br idhh idperson dgn dag pen yem yse lhw00 lhw01 boa* lemiw yem_* yse_* lhw00_hat lhw01_hat /// 
if pen==1 & dag==${SPAw}-1 & dgn==0

br idhh idperson dgn dag pen yem yse lhw00 lhw01 boa* lemiw yem_* yse_* lhw00_hat lhw01_hat /// 
if pen==1 & dag==${SPAw} & dgn==0


foreach var in yem_hat yse_hat lhw00_hat lhw01_hat tpceepx_hat liwwh_hat {
	replace `var'=0 if `var'==.	// this information is available only for pensioners who are moved back to work due to rise in SPA
}
	
rename yem_hat yemiv
rename yse_hat yseiv
rename lhw00_hat lhwiv00
rename lhw01_hat lhwiv01
rename tpceepx_hat tpceeivpx
rename liwwh_hat liwivwh
la var yemiv "imputed yem for previously pensioners"
la var yseiv "imputed yse for previously pensioners"
la var lhwiv00 "imputed lhw00 for previously pensioners"
la var lhwiv01 "imputed lhw01 for previously pensioners"
la var tpceeivpx "imputed rate of private pension contribution"
la var liwivwh "imputed work history"
*/
* drop unneccessary variables
drop ddicthw ddictrd bsa_ib /*  *_hat out* rnd_* person sernum lareg pwork_prtn  lareg1  emp pen ibesa*  pwork lessspa   dla  emp*  plusspa   ddict01* ddict02*  ddicten* adult cdaprog1 cdatre1 cdatrep1 dda */
//drop bdict bdict01 bdict02 // otherwise EM does not use the default

/*
* new variables added
su ddi* bdict* *iv tpceeivpx l*iv*
*/
drop adult bdict

*********************************************************************************************
/*Check COVID related variables and drop the unnecessary ones
fre lmcee bwkmcee lmcse bwkmcse 

*replace the total ampount of SEISS by monthly amount 
*DP: We don’t know how many months people actually applied for. A conservative assumption is that each respondent reporting receipt of SEISS in FRS 2020/21 
*applied for all the time that they could up to the survey date. So we assume anyone responding prior to August received SEISS covering 3 months, prior to Nov received 6 months, and 9 months otherwise.
/*
replace bwkmcse = bwkmcse/5 if ddt< 20200815
replace bwkmcse = bwkmcse/6 if ddt< 20201115
replace bwkmcse = bwkmcse/9 if ddt>=20201115
fre bwkmcse
*/

*The fourth SEISS covered the period 1 February 2021 to 30 April 2021 = up to 7500 for 3 months
*The fifth SEISS grant covered the period between 1 May 2021 and 30 September 2021 = up to 7500 for 5 months
bysort ddt: sum bwkmcse if bwkmcse>0 //similar mean amount is reported throughout the year 
*assume that all those who reported SEISS in 2021/22 received the fifth grant for the max amount of time (5 months)  
replace bwkmcse = bwkmcse/6


drop  chgcovid furlough furlo2  furlpay furlpay2 seissgr seissnum seisstot 
*/
********************************************************************************************
format afc %12.0g


/**************************************************************************************
*
*	PROGRAM TO REPLACE tmu04 IMPUTED COUNCIL TAX LEVELS 
*	
*	NOTE: program adapted for data reported from 2018/19 to 2021/22,and no longer needed due to DWP providing missing data for Scotland
*   
*	Preliminary analysis of data indicates that other than 2018/19, tmu03 not reported when needed
*	only for Scotland.  
*	Strategy here consequently fills in missing values for tmu (council tax level) via following process:
*		1) tmu = tmu02 by default
*		2) tmu = tmu03 if tmu02>0 and tmu02==tmu01 and tmu03>0
*		3) tmu = imputed rate for band in Scotland if tmu02>0 and tmu02==tmu01 and tmu03==0 and drgn1==12
*	
*************************************************************************************
/**************************************************************************************
*	start analysis
**************************************************************************************/

* source: https://www.gov.scot/publications/council-tax-datasets/
* average each band over all regions, columns:  2018	2019	2020	2021	2022	2023
matrix ctlOfficial = (797.8186583	,	828.9520563	,	866.3402914	,	866.3404104	,	891.170125	,	939.12375	 \ ///
930.7884347	,	967.1107323	,	1010.73034	,	1010.730479	,	1039.698479	,	1095.644375	 \ ///
1063.758211	,	1105.269408	,	1155.120389	,	1155.120547	,	1188.226833	,	1252.165	 \ ///
1196.727988	,	1243.428084	,	1299.510437	,	1299.510616	,	1336.755188	,	1408.685625	 \ ///
1572.367606	,	1633.726344	,	1707.412324	,	1707.412559	,	1756.347788	,	1850.856391	 \ ///
1944.68298	,	2020.570637	,	2111.70446	,	2111.70475	,	2172.22718	,	2289.114141	 \ ///
2343.592309	,	2435.046665	,	2544.874606	,	2544.874956	,	2617.812242	,	2758.676016	 \ ///
2931.983569	,	3046.398807	,	3183.800571	,	3183.801008	,	3275.050209	,	3451.279781	)


	disp "processing file `file'"
	qui{
		local col = 4 /*TO CHANGE */
		
		* initialise imputed value for tmu
		sum tmu04 
		drop tmu04
		gen tmu04 = tmu02
		replace tmu04 = tmu03 if (tmu02>0 & tmu02==tmu01 & tmu03>0)

		* updated tmu for values using council tax levels reported by official statistics where necessary
		gen tmuReq = (tmu02>0)
		gen tmuObs = (tmu02>0)*(tmu02!=tmu01)
		gen tmuMis = (tmu02>0)*(tmu02==tmu01)
		gen tmuVal = tmu02 + bmu
		forval row = 1/8 {
		* loop over each ct band

			* calculate imputed council tax level for respective band
			sum tmuObs if (drgn1==12 & amriv00==`row' & tmuReq==1) [fweight=dwt]
			local obs = r(mean)
			sum tmuVal if (drgn1==12 & amriv00==`row' & tmuObs==1) [fweight=dwt]
			local val = r(mean)
			local ctl = ctlOfficial[`row',`col'] / 12.0
			if ( `obs' > 0 ) {
				local imputedVal = (`ctl' - `obs' * `val')/(1 - `obs')
			}
			else {
				local imputedVal = `ctl'
			}
			noisily disp "imputed council tax level of band `row' is `imputedVal'"
			
			* updated tmu04 for scotland
			replace tmu04 = `imputedVal' - bmu if (tmu02>0 & tmu02==tmu01 & tmu03==0 & amriv00==`row' & drgn1==12)
		}
		drop tmuReq tmuObs tmuMis tmuVal
	} //end of qui loop 

	sum tmu04
	replace tmu04 = 0 if tmu04<0
	sum tmu04
*/	
**********************************************************************************************************************

sort idhh idperson
compress
save "${data}/UK_${frsyr}_${data_source}${data_ver}", replace	// final Input data file  DP: no reforms on SPA (no cases) and IB-ESA (no cases)
de, short
 

outsheet using "${data}/UK_${frsyr}_${data_source}${data_ver}.txt", replace nol
capture log close
