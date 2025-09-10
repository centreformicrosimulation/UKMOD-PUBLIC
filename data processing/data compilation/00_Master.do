***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         00_Master.do
* DESCRIPTION:          Main do-file to set the main parameters (country, paths) and
*                       call sub-scripts
************************************************************************
* COUNTRY:              UK
* FRS VERSION:         	Family Resources Survey 2023-2024
* NATIONAL MODELLERS:   Justin Van de Ven, Daria Popova 
* AUTHORS: 				Francesca Zantomio, Francesco Figari, Paola De Agostini, Iva Tasseva, Daria Popova  
* LAST UPDATE:          09/06/2025
***********************************************************************************************************

************************************************************************
* General comments:
*
* - A user should revise the information in the header as far as what 
*   concerns the list of new variables created and the date when the 
*   script was last updated. The only exception is the current file 
*   which requires information on the country, and the names of national
*   modellers who completed the scripts.
*
* - Any temporary variable should be named as temp_* (e.g. temp_poptot) in
*   order to avoid mixing with the final variables in the EUROMOD input
*   database. If the same temporary variable is used in more than one script
*   and is for that purpose stored in an intermediate output file, it should be
*   named as int_* (e.g. int_house).
*
* - Note that in the following scripts some standard commands may be 
*   abbreviated: (gen)erate, (tab)ulate, (sum)marize, (di)splay, 
*   (cap)ture, (qui)etly, (noi)sily
************************************************************************

clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

************************************************************************
* Define the FRS year, i.e. when was collected
* (will be used in the name of output files)
************************************************************************
local FRSv "_1st"
global frsyr "2023"

************************************************************************
* Define UKMOD database source and database version, i.e. x in CC_year_x# (eg. uk_2006_a1)
* (will be used in the name of the final output file)	
************************************************************************
global data_source_a = 1	//a=FRS   
global data_source_d = 0	//d=FRS +LCFvars  

************************************************************************
* Define folder paths for the analysis:	
* - where original FRS and HBAI data are stored and output files *will be* stored
* - where do-files are stored
* - where log-files *will be* stored
************************************************************************
sysdir set PLUS "C:\ado\plus\" // where ado files are stored

global path_proj "D:\Dasha\ESSEX\UKMOD\input-dataset"

* folder where original FRS data are stored 
global origydata "D:\Dasha\UK-original-data\FRS\UKDA-9367-stata-2023-24\stata\stata13"	

global data "${path_proj}\Data\FRS-2023-24\" // store FRS and UKMOD input micro-data

* folder where do-files are stored
global do "${path_proj}\Do\FRS-2023-24"  
   
* folder where log-files *will be* stored  
global log "${path_proj}\Log\FRS-2023-24"

* folder where graphs *will be* stored 
global graphs "${data}\graphs"	

*** set globals for HBAI 
global orig_hbai "D:\Dasha\UK-original-data\HBAI\UKDA-5828-stata\main" 

global hbai "${path_proj}\Data\HBAI\" // store HBAI data on housing costs

*** Set globals for consumption data 
/*global orig_lcf "D:\Dasha\UK-original-data\LCF\UKDA-9335-stata_2022_23\stata\stata13_se"

global dir_do_consumption "${do}\consumption"

global UKMOD_a_dataset "$data\UK_2022_a1.txt"

global LCF_hh_dataset "$orig_lcf\dvhh_ukanon_2022.dta"

global LCF_ind_dataset "$orig_lcf\dvper_ukanon_2022-23.dta"

global summary_table_consumption "${path_proj}\data\summary_table_consumption" //Excel file to store consumption data stats 
*/

***************************************************************************************************

set type double
************************************************************************
* Define retirement age for both sexes	
************************************************************************
global SPAw = 66 // Women's pension age: 60 up to 2011, 61 in 2012 and 2013, 62 in 2014 and 2015, 63 in 2016, 64 in 2017, 64/65 in 2018, 65 in 2019, 65/66 in 2020, 66 from 2021/22 until 2026/28 when another increase is planned 
global SPAm = 66 // Men's pension age: 65 in 2019, 65/66 in 2020, 66 fromm 2021/22 till 2026/28  (see https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/310231/spa-timetable.pdf)
global SPArise = 66 // SPA set to rise to 66 from Oct 2020

************************************************************************
* Specify whether assert commands in the script files will be used: 
* yes -> 1, no -> 0 
************************************************************************
global use_assert   = 1 					// [TO DO]!
global use_checkIDs = 0						// [TO DO]!

************************************************************************
* Specify the max number of problematic observations identified below 
* which these observations will be listed in detail. Set to zero if no 
* such observations need to be shown. (Used in script 04_CheckIDs.do)
************************************************************************
global maxN_obs_listed = 50 

************************************************************************
* Run sub-scripts
************************************************************************
cd $data

* UNCOMMENT THE FOLLOWING LINES ONLY AFTER THESE SCRIPTS HAVE BEEN WORKED THROUGH! // [TO DO]!

//////////////////////////////////
//programs to run for a-version //
//////////////////////////////////
if ${data_source_a}==1 {   
global data_source "a" // [TO DO]!
global data_ver "1"	// [TO DO]!

do ${do}/01_AdjustFRS.do // previously adj_FRS.do			
do ${do}/02_GetIndividualData.do 
do ${do}/03_PersonalInformation.do 		
if ${use_checkIDs} == 1 {
	do ${do}/04_CheckIDs.do   // checks on id variables
	do ${do}/03_PersonalInformation.do     // re-run 03_PersonalInformation.do 
}
do ${do}/05_BenefitParemeters.do // TO DO! update benefit amounts
do ${do}/06_LabourMarketInformation.do			
do ${do}/07_Income.do					
do ${do}/08_Expenditures.do			
do ${do}/09_Assets.do		// note: aca and aco not available anymore from uk_2017_*
do ${do}/10_Earnings_Hours.do	
do ${do}/11_Pensions.do					
do ${do}/12_InvestmentIncome.do	

do ${do}/13a_GetHBAIData.do //keep this commented out after the dataset is produced because they refer to a specific release of HBAI as the uprating reference year changes from year to year  	
do ${do}/13b_HBAIVars.do 

do ${do}/14_Assemble.do	

*do ${do}/15_LCFconsumption.do 

do ${do}/16_CheckDraftData.do	

/* reforms to be taken into account from 2008 onwards */
*do ${do}/future_reforms/16a_RiseSPA.do	/*no cases of women or men aged <66 receiving pension. No need for this do-file*/
*do ${do}/future_reforms/16b_IBESA.do /*no obs still receiving IB in 2023/24 data (bdict01=0)*/
	
do ${do}/17_UKDatabase.do
do ${do}/18_DRD.do
/**/
} //end 


//////////////////////////////////
//programs to run for d-version //
//////////////////////////////////

if ${data_source_d}==1 {   
global data_source "d" // [TO DO]!
global data_ver "1"	// [TO DO]!

do ${do}/01_AdjustFRS.do // previously adj_FRS.do			
do ${do}/02_GetIndividualData.do 
do ${do}/03_PersonalInformation.do 		
if ${use_checkIDs} == 1 {
	do ${do}/04_CheckIDs.do   // checks on id variables
	do ${do}/03_PersonalInformation.do     // re-run 03_PersonalInformation.do 
}

do ${do}/05_BenefitParemeters.do // TO DO! update benefit amounts
do ${do}/06_LabourMarketInformation.do			
do ${do}/07_Income.do					
do ${do}/08_Expenditures.do			
do ${do}/09_Assets.do		// note: aca and aco not available anymore from uk_2017_*
do ${do}/10_Earnings_Hours.do	
do ${do}/11_Pensions.do					
do ${do}/12_InvestmentIncome.do	

//do ${do}/13a_GetHBAIData.do //keep this commented out after the dataset is produced because they refer to specific release of HBAI as the uprating reference year changes from year to year  	
//do ${do}/13b_HBAIVars.do 
do ${do}/14_Assemble.do	

do ${do}/15_LCFconsumption.do 

do ${do}/16_CheckDraftData.do	

/* reforms to be taken into account from 2008 onwards */
*do ${do}/future_reforms/16a_RiseSPA.do	/*DP: there are no cases of women or men aged <66 receiving pension. No need for this do-file*/
*do ${do}/future_reforms/16b_IBESA.do /*DP: no obs still receiving IB in 2021/22 data (bdict01=0)*/
	
do ${do}/17_UKDatabase.do
do ${do}/18_DRD.do

} //end 


* [END OF 00_Master.do FILE]

/* Notes: names of previous do-file versions
adj_FRS.do 					= 01_AdjustFRS.do		
an_intro.do 				= 02_GetIndividualData.do 		
cr_pers.do 					= 03_PersonalInformation.do 		
check_IDs.do 				= 04_CheckIDs.do  
cr_lab.do					= 06_LabourMarketInformation.do			
cr_income.do 				= 07_Income.do					
cr_exp.do 					= 08_Expenditures.do			
cr_assets.do 				= 09_Assets.do
cr_earn_hours.do 			= 10_Earnings_Hours.do	
cr_pensions.do 				= 11_Pensions.do	
cr_invinc.do 				= 12_InvestmentIncome.do		
hbai_housing_exp.do 		= 13b_HBAIHousingCosts.do
assemble.do					= 14_Assemble.do	
adjust_check.do				= 15_CheckDraftData.do
riseSPA.do 					= 16a_RiseSPA.do
IBESA.do					= 16b_IBESA.do	
cleanup.do 					= 17_UKDatabase.do
drd.do / drd_final.do 		= 18_DRD.do

Do-files that are no longer needed and have been therefore removed from the code:
cr_nic_regime.do 			Notes: The do-file identifies who has contracted out of the State Pension. 
							But on 6 April 2016 the contracting out rules changed. If contracted out, the person will:
							- no longer be contracted out
							- pay more National Insurance (the standard amount of National Insurance)
							Thus, we no longer need to/can identify who has contracted out in the FRS data.

LHA.do						Notes: The do-file does two things:
							1) defines as variables the Local Reference Rents which were then used for calculating HB and UC.
							2) calculates the number of eligible rooms for social renters (bhoro).
							On 1), it is actually the Local Housing Allowance rates which are used in benefit calculations (and since 2011 these are different from the LRR).
							The LHA rates for all policy years are now defined as constants in the model, so the code on 1) is no longer needed.
							On 2), this bit is still needed and has been now moved to "07_Income".

newclaim_cESA.do			Notes: The do-file models the time limit of 1 year for those in the Work-Related Activity Group for the contributory ESA. 
							The time limit was applied in 2012 to both all existing and new claims. 
							We no longer need to model this as the FRS 2018/19 already captures all individuals affected by the reform.
							(Most likely, this do-file should have been commented out also in some of the previous do-file versions.)
							
16a_RiseSPA.do	            Notes: This do-file was used to model the increase to the SPA which has implications on 
                            (1) receipt of incapacity benefit and Employment and suport Allowance (IB/ESA) and 
                            (2) labour supply of people who are at pension age in the data but will not be eligible to pension in the modelled future policy years
                            In 2020/21 data there are only 10 women and 4 men aged 65 (below state pension age of 66). No need to modify their data given that they are so few.
							
16b_IBESA.do	  			Notes: This do-file was used to move people who still report the receipt of IB to ISA and predict ISA for 'new' claimants modelled in 16a_RiseSPA.do	. 
                            There were no obs still receiving IB in 2020/21 data (bdict01=0).
										
							
*/
