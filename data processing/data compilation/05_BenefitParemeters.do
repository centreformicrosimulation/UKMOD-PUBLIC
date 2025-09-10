******************************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         05_BenefitParameters.do
* DESCRIPTION:          Define benefit parameters as globals
*						Used in do-files 07_Income and 11_Pensions to adjust benefit and pension amounts
* INPUT FILE:           n/a
* OUTPUT FILE:          n/a
* NEW VARs:				n/a
* LAST UPDATE:          09/06/2025
*******************************************************************************************************
*Source: https://www.gov.uk/government/publications/benefit-and-pension-rates-2023-to-2024/benefit-and-pension-rates-2023-to-2024
*!!!!!!!!!!!!!!!!!!! UPDATE FOR THE BENEFIT VALUES IN PERIOD t OF THE BASE DATA !!!!!!!!!!!!!!!!!!!!!!*

* Employment and Support Allowance
global esa 77.00 //74.70 //74.35 // personal allowance for 25+ year olds
global esa_wrag 30.60 //29.70 //29.55 // Work-Related Activity Group
global esa_sg 40.60 //39.40 //39.20 // Support Group

* contributory Jobseeker's Allowance 
global cjsa25 67.20 //61.05 //59.20 //58.90 // under 25 year old
global cjsa 84.80 //77.00 //74.70 //74.35 // aged 25+

* rent a room tax relief
global rent_room 7500 //no change in 2022/23 & 2023/24

* Maternity Allowance 
global ma 	172.48 //156.66 //151.97 //151.20 // standard allowance

* Statutory Sick Pay
global ssp 	109.40 //99.35 //96.35 //95.85

* Severe Disablement Allowance
global sda_basic 92.20 //83.75 // 81.25 //80.85 // basic rate
global sda_addh 13.80 //12.55 //12.15 //12.10 // age-related addition: high rate
global sda_addl 7.65 //6.95 //6.75 //6.70 // age-related addition: middle/low rate
global sda_depad 45.35 //41.20 //39.95 //39.75 // adult dependency increases for spouse or person looking after children
global sda_depch 11.35 //11.35 //11.35 //11.35 // child dependency increases


* Carer's Allowance
global ca 	76.75 //69.70 //67.60 //67.25 // rate
global ca_depad 0 // adult dependency increases for spouse or person looking after children 
/*DP: New claims for the Carer's Allowance Adult Dependency Increase ended on 6 April 2010 but payments continued until 5 April 2020*/
global ca_depech 8.00  //8.00 //8.00 //8 // child dependency increases: eldest child
global ca_depch 11.35 //11.35 //11.35 //11.35 // child dependency increases


* Industrial Injuries Disablement Benefit
global iidb 207.60 //188.60 //182.90 //182.00 // standard rate: 100%


* Incapacity Benefit
global ib_lt 130.20 //	118.25 //114.70 //114.15 // long-term
global ib_stlr_uspa 98.25 //	89.25 //86.55 //86.10 // short-term, low rate, under SPA
global ib_sthr_uspa 116.20 //	105.55 //102.40 //101.90 // short-term, high rate, under SPA
global ib_stlr_ospa 124.90 //113.45 //110.05 //109.50 // short-term, low rate, over SPA
global ib_sthr_ospa 130.20 //118.25 //114.70 //114.15 // short-term, high rate, over SPA
global ib_agehr 13.80 //	12.55 //12.15 //12.10 // increase of long-term IB for age, high rate
global ib_agelr 7.65 //6.95 //6.75 //6.70 // increase of long-term IB for age, low rate

global ib_depadlt 	75.65 //	68.70 //66.65 //66.30 // long-term IB: adult dependency increases for spouse or person looking after children
global ib_depad_ospa 72.80 //	66.10 //64.10 //63.80 // short-term IB over SPA: adult dependency increases
global ib_depad_uspa 58.90 //	53.50 //51.90 //51.65 // short-term IB under SPA: adult dependency increases
global ib_depech 8.00 //8 //8 //8 // child dependency increases: eldest child
global ib_depch 11.35 //11.35 //11.35 //11.35 // child dependency increases


* Personal Independence Payment
global pip_dlc_enh 101.75 //92.40 //89.60 //89.15 // daily living component, enhanced
global pip_dlc_std 68.10 //61.85 //60.00 //59.70 // daily living component, standard
global pip_mc_enh 71.00 //64.50 //62.55 //62.25 // mobility component, enhanced
global pip_mc_enh 26.90 //24.45 //23.70 //23.60 // mobility component, standard


* Disability Living Allowance
global dlac_h 101.75 //92.40 //89.60 //89.15 // care component, highest
global dlac_m 68.10 //61.85 //60.00 //59.70 // care component, middle
global dlac_l 26.90 //24.45 //23.70 //23.60 // care component, lowest
global dlam_h 71.00 // 64.50 //62.55 //62.25 // mobility component, higher
global dlam_l 26.90 //24.45 //23.70 //23.60 // mobility component, lower


* Attendance Allowance
global aa_hr 101.75 //92.40 //89.60 //89.15 // higher rate
global aa_lr 68.10 //85.00 //61.85 //60.00 //59.70 // lower rate


* Old State Pension
global osp_basic 156.20 //	141.85 //137.60 //134.25 // category A or B basic pension
global osp_low 93.60 //85.00 //82.45 //80.45 // category B (lower) - spouse or civil partner/s insurance; category C or D - non-contributory
global osp_depech 8.00 // 8 //8 //8 // child dependency increases: eldest child
global osp_depch  11.35 //11.35 //11.35 //11.35 // child dependency increases

*New State Pension 
global nsp_full 203.85 //185.15 // Full rate
global NSPm = 72 //Men eligible if born on or after 6 April 1951.
global NSPw = 70 //Women eligible if born on or after 6 April 1953.


