***************************************************************************************
* PROJECT:              EUROMODupdate/UKMOD: construct a EUROMOD-UK/UKMOD database from FRS database
* DO-FILE NAME:         12_InvestmentIncome.do
* DESCRIPTION:          Create expenditures variables 
* INPUT FILE:           individual, maint
* OUTPUT FILE:          invinc
* NEW VARs:
*                       - yiy             Income - investment
*                       - yiytx	          Income - taxable investment income
*                       - yiynt	          Income - non-taxable investment income
*                       - yittx           Income - taxable interest income 
*                       - ydvtx           Income - taxable dividend income 
* LAST UPDATE:          09/06/2025
***************************************************************************************
cap log close 
log using "${log}/12_InvestmentIncome.log", replace
use sernum person using individual, clear
save invinc, replace
* Normally, 20% tax is deducted from interest payments
/* account - Account Type	
	    1  Current account  
        2  NS&I Direct Saver  
        3  NS&I Investment account 
        5  Savings, investments etc  
        6  Government Gilt Edged Stock
        7  Unit/Investment Trusts
        8  Stocks,Shares, Bonds etc 
        11 Index Linked National Savings Certificates
        12 Fixed Interest National Savings Certificates 
        14 SAYE                                            
        15 Premium bonds                                  
        16 National Savings income bonds                  
        21 ISA                                            
        22 Profit sharing                                
        23 Company Share Option Plans                   
        24 Member of Share Club                         
        25 Fixed Rate Savings/Guaranteed Income/Guaranteed Growth Bonds                                                                             
        26 GEB                                             
        27 Basic Account                                   
        28 Credit Unions                                   
        29 Endowment Policy Not Linked                     
        30 Post Office Card Account                       
        31 Friendly Society Investment  //assumed to be tax free //                   
        32 Informal Assets                                 
    	*/
*****************************************
*	yiynt - exempt investment income

* account
* acctax - Whether sav interest before or after tax	
*1 After tax		
*2 Before tax - but tax payable					          
*3 Before tax - no tax payable on interest					          

* accint - Interest received
****************************************

 
use $data/accounts, clear

fre account
fre acctax

de
keep if account==9|account==21|account==24	//PEP, ISA, Member of Share Club //Note: PEP no longer exists as a category
mvdecode _all, mv(-1)
if ${use_assert} assert acctax==. if account !=2
ta acctax if account==2, m
gen yiynt =0
replace yiynt =accint 
collapse (sum) yiynt , by  (sernum person)				
sort sernum person
merge sernum person using invinc
ta _merge
drop _merge
replace yiynt =0 if yiynt ==.								
replace yiynt =yiynt *(52/12)
sort sernum person
save invinc, replace

*****************************************************
*	yiytx - taxable investment income

* invtax - Whether inv interest before or after tax	
*	1	After tax
*	2	Before tax
*****************************************************
use $data/accounts, clear
keep if account!=9 & account!=21 & account!=24 
mvdecode _all, mv(-1)
ta account if accint>0 & accint!=., nol
by account, sort: ta acctax if accint!=. & accint!=0,m
gen yiytx =0
	replace yiytx =accint if acctax!=1 & (account==1|account==3|account==5 |account==27|account==28) //1-Current account, 3-NS&I Investment account, 5-Savings, investments etc, 27-Basic Account, 28-Credit Unions
	replace yiytx =accint*1.25 if (acctax==1) & (account==1|account==3|account==5 |account==27|account==28)		// HS: 1.25 is grossing up factor! 20% deducted at source
	replace yiytx =max(0,accint-(70/52)) if account==2	/*assumed always gross, see below */ //2-NS&I Direct Saver

by account, sort: ta invtax if accint!=. & accint!=0,m
	replace yiytx =accint*1.25 if account==6 & invtax==1 // HS: 1.25 is grossing up factor! 20% deducted at source //6-Government Gilt Edged Stock
	replace yiytx =accint if account==7|account==8 //7-Unit/Investment Trusts, 8-Stocks,Shares, Bonds etc

collapse (sum) yiy account, by  (sernum person)				
sort sernum person
merge sernum person using invinc
ta _merge
drop _merge
replace yiytx =0 if yiytx ==.	
replace yiytx =yiytx*(52/12)

*************************************
*	yittx - taxable interest income 
*************************************
//DP: dissagregation of yiytx into interest and dividend income. Interest income if account ==1, 2, 3, 5, 6, 27, 28
gen yittx =0
replace yittx = yiytx if (account!=7 & account!=8) 
	
	
*************************************
*	ydvtx - taxable dividend income  
*************************************
//DP: dissagregation of yiytx into interest and dividend income. Dividend income if account ==7, 8
gen ydvtx =0
replace ydvtx =yiytx if account==7|account==8 

if ${use_assert} assert yiytx == (yittx  + ydvtx) 
drop account 

sort sernum person
save invinc, replace


*****************************************************************************
*	yiy - taxable and non-gross investment income (excluding property income) 
*****************************************************************************
gen yiy= yiytx + yiynt 

order sernum person yiy yiynt yiytx yittx ydvtx

sort sernum person
save invinc, replace
des
cap log close
