********************************************************************************
* DESCRIPTION:		Evaluation of incidence of pension credit (variable boamt_s)
* INPUT FILE(S):	UKMOD output files for standard parameter specifications
* AUTHOR(S):		Justin van de Ven (JV)
* LAST UPDATE:		30/01/2025 (JV)
********************************************************************************

clear all
cap log close
set more off


***********************************************************************
* define parameters
***********************************************************************
local dir "C:\MyFiles\99 DEV ENV\UKMOD\MODELS\PRIVATE\Output"
global start_year = 2005
global end_year = 2015


***********************************************************************
* run analysis
***********************************************************************
cd "`dir'"


***********************************************************************
* check data
***********************************************************************
matrix store = J($end_year - $start_year+1, 6, .)
foreach year of numlist $start_year / $end_year {
* loop over each simulated year

	qui {
		
		noi disp "evaluating statistics for year " `year'
		insheet using "UK_`year'_std.txt", clear
		local jj = 0
		foreach vv of var boamt_s boamtmm_s boamtxp_s {
			
			gen chk = (`vv'>0)
			sum chk [fweight=dwt]
			mat store[`year'-$start_year+1,`jj'+1] = r(mean)
			mat store[`year'-$start_year+1,`jj'+2] = r(mean) * r(N)
			drop chk
			local jj = `jj' + 2
		}
	}
}
matlist store

qui {
	
	matrix store2 = J(1, 6, .)
	insheet using "uk_2014temp_std.txt", clear
	local jj = 0
	foreach vv of var boamt_s boamtmm_s boamtxp_s {
		
		gen chk = (`vv'>0)
		sum chk [fweight=dwt]
		mat store2[1,`jj'+1] = r(mean)
		mat store2[1,`jj'+2] = r(mean) * r(N)
		drop chk
		local jj = `jj' + 2
	}
}
matlist store2
