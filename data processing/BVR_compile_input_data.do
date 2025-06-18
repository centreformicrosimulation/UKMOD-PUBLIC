***************************************************************************************
* DESCRIPTION:		Compile input data for analysing behavioural responses using the BVR add-on
* AUTHOR(S):		Justin van de Ven
* LAST UPDATE:		03/11/2024 (JV)
*
* DIRECTIONS:		1. Run the BVR add-on for the baseline policy system, enabling the BV0 extension
*					2. Amend the "model_dir" below to indicate the directory where UKMOD is saved
*					3. Amend the "input_file" below to match the input file for the baseline simulation
* 					4. Run this program, which will append output data from (1) to the model input data
*					5. Run the BVR add-on for the counterfactual system, disabling the BV0 extension
***************************************************************************************
clear all
set more off


***********************************************************************
* define parameters
***********************************************************************
global input_file "UK_2022_a1.txt"
global model_dir "C:\MyFiles\99 DEV ENV\UKMOD\MODELS\PRIVATE"


***********************************************************************
* run analysis
***********************************************************************
cd "$model_dir\Input"
import delimited "$model_dir\Output\additional_inputs.txt", asdouble
save temp, replace
import delimited "$model_dir\Input\\$input_file", asdouble clear
capture confirm variable ntax
if !_rc {
	drop ntax* mntr_*
}
merge 1:1 idperson using temp
count if (_merge!=3)
if (r(N)>0) {
	display "Output from BV0 extension not compatible with input data"
}
else {
	drop _merge
	format * %15.0g
	outsheet using "$model_dir\Input\\$input_file", replace nol
}
erase temp.dta


***********************************************************************
* finished
***********************************************************************
