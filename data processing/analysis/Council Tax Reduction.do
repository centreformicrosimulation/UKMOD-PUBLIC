********************************************************************************
* DESCRIPTION:		Evaluation of incidence of council tax reduction (variable bmu_s)
* INPUT FILE(S):	UKMOD output files for standard parameter specifications
* AUTHOR(S):		Justin van de Ven (JV)
* LAST UPDATE:		15/04/2025 (JV)
********************************************************************************

clear all
cap log close
set more off


***********************************************************************
* define parameters
***********************************************************************
local dir "C:\MyFiles\99 DEV ENV\UKMOD\MODELS\PRIVATE\Output"

global start_year = 2016
global end_year = 2022

global ext = "BTOoff"
global ext = "HBAIon"
global ext = "BTOoff_HBAIon"
global ext = "std1"


***********************************************************************
* run analysis
***********************************************************************
cd "`dir'"


***********************************************************************
* check data
***********************************************************************
matrix store = J($end_year - $start_year+1, 9, .)
foreach year of numlist $start_year / $end_year {
* loop over each simulated year

	qui {
		
		noi disp "evaluating statistics for year " `year'
		insheet using "UK_`year'_${ext}.txt", clear
		gen dwt1 = round(dwt)
			
		sum bmu_s if (drgn1==11 & bmu_s>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,1] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,2] = r(N)
		sum bmu_s if (drgn1==11 & bmu_s>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,3] = r(N)

		sum bmu_s if (drgn1==12 & bmu_s>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,4] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,5] = r(N)
		sum bmu_s if (drgn1==12 & bmu_s>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,6] = r(N)

		sum bmu_s if (drgn1<10.5 & bmu_s>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,7] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,8] = r(N)
		sum bmu_s if (drgn1<10.5 & bmu_s>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,9] = r(N)
	}
}
matlist store, format(%10.0g)

matrix store = J($end_year - $start_year+1, 9, .)
foreach year of numlist $start_year / $end_year {
* loop over each simulated year

	qui {
		
		noi disp "evaluating statistics for year " `year'
		insheet using "UK_`year'_${ext}.txt", clear
		gen dwt1 = round(dwt)
			
		sum tmu if (drgn1==11 & tmu>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,1] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,2] = r(N)
		sum tmu if (drgn1==11 & tmu>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,3] = r(N)

		sum tmu if (drgn1==12 & tmu>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,4] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,5] = r(N)
		sum tmu if (drgn1==12 & tmu>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,6] = r(N)

		sum tmu if (drgn1<10.5 & tmu>0) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,7] = r(N) * r(mean) * 12 / 10^6
		mat store[${end_year}-`year'+1,8] = r(N)
		sum tmu if (drgn1<10.5 & tmu>0 & dag>=65) [fweight=dwt1], mean
		mat store[${end_year}-`year'+1,9] = r(N)
	}
}
matlist store, format(%10.0g)

