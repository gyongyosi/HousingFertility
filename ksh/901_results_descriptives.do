





/*------------------------------------------------------------------------------
	BALANCE -- individual
------------------------------------------------------------------------------*/

cap log close OC_balance_individual_1
log using "${output}/OC_balance_individual_1", text replace name(OC_balance_individual_1) 

foreach BW in "0000"  5000 15000  {

	use "${temp}/census_002_trim_updated", clear
	keep if ty == 2018
	keep if inrange(de01, 0, 20000)
	keep if CSOK_`BW' != .
	
	lab var hungarian "Hungarian"
	lab var roma "Roma"
	lab var ty_mother_birth "Year of birth"
	lab var marriedBy2019 "Married"
	lab var C_childrenNEW "Number of children"


	local VARS_TO_COMPARE ty_mother_birth edu_1 edu_2 edu_3 edu_4 C_childrenNEW marriedBy2019 hungarian roma 

	eststo clear
	eststo TREATED : estpost summarize `VARS_TO_COMPARE' if CSOK_`BW' == 1 
	eststo CONTROL : estpost summarize `VARS_TO_COMPARE' if CSOK_`BW' == 0 
	eststo diff : estpost ttest `VARS_TO_COMPARE' , by(CSOK_`BW') unequal

	#d ;
		esttab TREATED CONTROL diff using "${output}/tab_balance_individual_`BW'.rtf", 
			cells("
				mean(pattern(1 1 0) fmt(2)) 
				b(pattern(0 0 1) fmt(2)) 
				sd(pattern(1 1 0) fmt(2)) 
				t(pattern(0 0 1) fmt(2)) 
			") 
			 wide replace
			 label
			;
	#d cr



	foreach X in `VARS_TO_COMPARE' {
		egen mean_`X' = mean(`X'), by(CSOK_`BW')
		egen std_`X' = sd(`X'), by(CSOK_`BW')
		egen N_`X' = count(`X'), by(CSOK_`BW')

	}

	collapse (mean) N_* mean_* std_*, by(CSOK_`BW')
	reshape long N_ mean_ std_, i(CSOK_`BW') j(var) string
	reshape wide N_ mean_ std_, i(var) j(CSOK_`BW')

	gen N = N_1 + N_0
	gen beta = mean_1 - mean_0
	gen var_0 = (std_0)^2 
	gen var_1 = (std_1)^2 

	gen tStan = beta / sqrt((var_1 / N_1) + (var_0 / N_0))
	gen tNorm = beta / sqrt(var_1 + var_0)


	export delimited using "${output}/tab_balance_individual_`BW'_ndiff", replace delim(";")

}


cap log close OC_balance_individual_1






cap log close OC_balance_individual_2
log using "${output}/OC_balance_individual_2", text replace name(OC_balance_individual_2) 


foreach BW in "0000"  5000 15000  {

	use "${temp}/census_002_trim_updated", clear
	keep if ty == 2018
	keep if inrange(de01, 0, 20000)
	keep if CSOK_`BW' != .

	#d ;
		twoway 
			(histogram ty_mother_birth if CSOK_`BW'==1, start(1969) disc color("$color1")) 
			(histogram ty_mother_birth if CSOK_`BW'==0, start(1969) disc fcolor(none) lcolor(black) ), 
			xtitle("Women's year of birth")
			legend(order(1 "Treated" 2 "Control"))
			;


	#d cr
	graph export "${output}/hist_ty_mother_birth_BW`BW'.pdf", as(pdf) replace



	#d ;
		twoway 
			(histogram C_childrenNEW if CSOK_`BW'==1, start(0) disc color("$color1") ) 
			(histogram C_childrenNEW if CSOK_`BW'==0, start(0) disc fcolor(none) lcolor(black) ),
			xtitle("Number of kids")
			legend(order(1 "Treated" 2 "Control"))
			;
			
	#d cr
	graph export "${output}/hist_kids_by_2018_BW`BW'.pdf", as(pdf) replace




	#d ;
		twoway 
			(histogram eduCatg if CSOK_`BW'==1, disc color("$color1") ) 
			(histogram eduCatg if CSOK_`BW'==0, disc fcolor(none) lcolor(black) ),
			xtitle("Education")
			legend(order(1 "Treated" 2 "Control"))
			xlabel(1 "Primary" 2 "Vocational" 3 "High school" 4 "College")
			;
	#d cr
	graph export "${output}/hist_eduCatg_BW`BW'.pdf", as(pdf) replace

	/*
	#d ;
		twoway 
			(histogram relC if CSOK_`BW'==1, disc color("$color1") ) 
			(histogram relC if CSOK_`BW'==0, disc fcolor(none) lcolor(black) ) ,
			xtitle("Religion")
			legend(order(1 "Treated" 2 "Control"))
			;

	#d cr
	graph export "${output}/hist_relC_BW`BW'.pdf", as(pdf) replace
	*/

	/*
	#d ;
		twoway 
			(histogram lcstip if CSOK_`BW'==1, disc color("$color1") ) 
			(histogram lcstip if CSOK_`BW'==0, disc  fcolor(none) lcolor(black) ),
			xtitle("Family type")
			legend(order(1 "Treated" 2 "Control"))
			;

	#d cr
	graph export "${output}/hist_lcstip_BW`BW'.pdf", as(pdf) replace
	*/
}


cap log close OC_balance_individual_2













/*------------------------------------------------------------------------------
	BALANCE -- settlement
------------------------------------------------------------------------------*/


cap log close OC_balance_municipality_1
log using "${output}/OC_balance_municipality_1", text replace name(OC_balance_municipality_1) 


use "${temp}/tstar_important", clear
keep if ty == 2018

#d ;
	binscatter CSOK_0000 de01 if inrange(de01, 0, 20000), nq(100) rd(5000) 
		line(none)
		mcolor("$color1")
		xtitle("Population, 2018")
		ytitle("Share of Rural CSOK eligible municipalities")
		;
#d cr
graph export "${output}/binscatter_CSOK_0000_de01.pdf", as(pdf) replace


use "${temp}/tstar_important", clear
keep if ty == 2018


#d ;
	hist  de01 if inrange(de01, 0, 20000), 
			start(0) width(200)
			xline(5000)
			color("$color1")

		;
#d cr
graph export "${output}/hist_de01.pdf", as(pdf) replace



cap log close OC_balance_municipality_1









cap log close OC_balance_municipality_2
log using "${output}/OC_balance_municipality_2", text replace name(OC_balance_municipality_2) 


use "${temp}/tstar_important", clear
keep if ty == 2018
forval i = 1(1)4 {
	gen s_CSOK_`i' = subsidy_`i' / women_15_49_TSTAR
}
gen s_CSOK_12 = s_CSOK_1 + s_CSOK_2

lab var s_CSOK_1 "CSOK contract (new house) per women 15-49"
lab var s_CSOK_2 "CSOK contract (old house) per women 15-49"
lab var s_CSOK_3 "Rural CSOK contract per women 15-49"
lab var s_CSOK_4 "Subsidized loans per women 15-49"
lab var s_CSOK_12 "CSOK contract (new + old house) per women 15-49"


foreach X in 1 2 3 4 12 {

	local lab : variable label  s_CSOK_`X'

	#d ;
		binscatter s_CSOK_`X' de01 if inrange(de01, 0, 20000), nq(100) rd(5000) 
			line(none)
			mcolor("$color1")
			xtitle("Population, 2018")
			ytitle("`lab'")
			;
	#d cr
	graph export "${output}/binscatter_s_CSOK_`X'_de01.pdf" , as(pdf) replace
	

	
	#d ;
		binscatter s_CSOK_`X' de01 if inrange(de01, 0, 20000) [aw = women_15_49_TSTAR], nq(100) rd(5000) 
			line(none)
			mcolor("$color1")
			xtitle("Population, 2018")
			ytitle("`lab'")
			;
	#d cr
	graph export "${output}/binscatter_s_CSOK_`X'_de01_weighted.pdf" , as(pdf) replace
	
	
	
}

cap log close OC_balance_municipality_2







cap log close OC_balance_municipality_3
log using "${output}/OC_balance_municipality_3", text replace name(OC_balance_municipality_3) 


use "${temp}/tstar_important", clear
keep if ty == 2018

gen sh_planned = planned_kids_2016_2023 / number_of_contracts_2016_2023
gen sh_exist = existing_kids_2016_2023 / number_of_contracts_2016_2023

gen SH_planned = planned_kids_2016_2023 / women_15_49
gen SH_exist = existing_kids_2016_2023 / women_15_49
gen SH_contract = number_of_contracts_2016_2023 / women_15_49

#d ;
	binscatter sh_planned de01 if inrange(de01, 0, 20000), nq(100) rd(5000)
		xtitle("Population, 2018")
		ytitle("Number of planned children" "as a share of the number of contracts")
		line(none)
		;
#d cr
graph export "${output}/binscatter_sh_planned_de01.pdf", as(pdf) replace




#d ;
	binscatter sh_exist de01 if inrange(de01, 0, 20000), nq(100) rd(5000)
		xtitle("Population, 2018")
		ytitle("Number of existing children" "as a share of the number of contracts")
		line(none)
		;
#d cr
graph export "${output}/binscatter_sh_existing_de01.pdf", as(pdf) replace




#d ;
	binscatter SH_exist de01 if inrange(de01, 0, 20000), nq(100) rd(5000)
		xtitle("Population, 2018")
		ytitle("Number of existing children" "as a share of women (15-49)")
		line(none)
		;
#d cr
graph export "${output}/binscatter_sh_existing_perW_de01.pdf", as(pdf) replace



#d ;
	binscatter SH_planned de01 if inrange(de01, 0, 20000), nq(100) rd(5000)
		xtitle("Population, 2018")
		ytitle("Number of planned children" "as a share of women (15-49)")
		line(none)
		;
#d cr
graph export "${output}/binscatter_sh_planned_perW_de01.pdf", as(pdf) replace



#d ;
	binscatter SH_contract de01 if inrange(de01, 0, 20000), nq(100) rd(5000)
		xtitle("Population, 2018")
		ytitle("Number of contracts" "as a share of the number of women (15-49)")
		line(none)
		;
#d cr
graph export "${output}/binscatter_sh_contract_perW_de01.pdf", as(pdf) replace


cap log close OC_balance_municipality_3







cap log close OC_balance_municipality_4
log using "${output}/OC_balance_municipality_4", text replace name(OC_balance_municipality_4) 


foreach BW in "0000" 5000 15000 {

	use "${temp}/tstar_important", clear
	keep if ty == 2018
	keep if inrange(de01_2018, 0, 20000)
	keep if CSOK_`BW' != .


	local VARS_TO_COMPARE U_2018 ln_income_2018 SH_t_1 SH_t_2 SH_t_3 SH_t_4 

	eststo clear
	eststo TREATED : estpost summarize `VARS_TO_COMPARE' if CSOK_`BW' == 1 
	eststo CONTROL : estpost summarize `VARS_TO_COMPARE' if CSOK_`BW' == 0 
	eststo diff : estpost ttest `VARS_TO_COMPARE' , by(CSOK_`BW') unequal

	#d ;
		esttab TREATED CONTROL diff using "${output}/tab_balance_muni_`BW'.rtf", 
			cells("
				mean(pattern(1 1 0) fmt(2)) 
				b(pattern(0 0 1) fmt(2)) 
				sd(pattern(1 1 0) fmt(2)) 
				t(pattern(0 0 1) fmt(2)) 
			") 
			 wide replace
			;
	#d cr



	foreach X in `VARS_TO_COMPARE' {
		egen mean_`X' = mean(`X'), by(CSOK_`BW')
		egen std_`X' = sd(`X'), by(CSOK_`BW')
		egen N_`X' = count(`X'), by(CSOK_`BW')

	}

	collapse (mean) N_* mean_* std_*, by(CSOK_`BW')
	reshape long N_ mean_ std_, i(CSOK_`BW') j(var) string
	reshape wide N_ mean_ std_, i(var) j(CSOK_`BW')

	gen N = N_1 + N_0
	gen beta = mean_1 - mean_0
	gen var_0 = (std_0)^2 
	gen var_1 = (std_1)^2 

	gen tStan = beta / sqrt((var_1 / N_1) + (var_0 / N_0))
	gen tNorm = beta / sqrt(var_1 + var_0)


	export delimited using "${output}/tab_balance_muni_`BW'_ndiff", replace delim(";")

}


cap log close OC_balance_municipality_4




cap log close OC_balance_municipality_5
log using "${output}/OC_balance_municipality_5", text replace name(OC_balance_municipality_5) 


foreach BW in  5000 15000  "0000"  {
	
	use "${temp}/tstar_important", clear
	keep if ty == 2018
	keep if inrange(de01_2018, 0, 20000)
	keep if CSOK_`BW' != .
	
	#d ;
		twoway 
			(histogram U_2018 if CSOK_`BW'==1, start(0) width(0.01)  color("$color1") ) 
			(histogram U_2018 if CSOK_`BW'==0, start(0) width(0.01)  fcolor(none) lcolor(black) ) ,
			xtitle("Unemployment rate")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr
	graph export "${output}/hist_U_BW`BW'.pdf", as(pdf) replace
	
	
	#d ;
		twoway 
			(histogram ln_income_2018 if CSOK_`BW'==1,  start(4) width(0.1) color("$color1") ) 
			(histogram ln_income_2018 if CSOK_`BW'==0,  start(4) width(0.1)  fcolor(none) lcolor(black) ) ,
			xtitle("Income")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr	
	graph export "${output}/hist_ln_income_BW`BW'.pdf", as(pdf) replace
	
	#d ;
		twoway 
			(histogram SH_t_1 if CSOK_`BW'==1,  start(0) width(0.025) color("$color1") ) 
			(histogram SH_t_1 if CSOK_`BW'==0,  start(0) width(0.025)  fcolor(none) lcolor(black) ) ,
			xtitle("Share of primary education")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr	
	graph export "${output}/hist_SH_t_1_BW`BW'.pdf", as(pdf) replace
	
	#d ;
		twoway 
			(histogram SH_t_2 if CSOK_`BW'==1,  start(0) width(0.0125) color("$color1") ) 
			(histogram SH_t_2 if CSOK_`BW'==0,  start(0) width(0.0125)  fcolor(none) lcolor(black) ) ,
			xtitle("Share of vocational education")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr	
	graph export "${output}/hist_SH_t_2_BW`BW'.pdf", as(pdf) replace
	
	#d ;
		twoway 
			(histogram SH_t_3 if CSOK_`BW'==1,  start(0) width(0.0125) color("$color1") ) 
			(histogram SH_t_3 if CSOK_`BW'==0,  start(0) width(0.0125)  fcolor(none) lcolor(black) ) ,
			xtitle("Share of high school education")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr	
	graph export "${output}/hist_SH_t_3_BW`BW'.pdf", as(pdf) replace
	
	#d ;
		twoway 
			(histogram SH_t_4 if CSOK_`BW'==1,  start(0) width(0.0125) color("$color1") ) 
			(histogram SH_t_4 if CSOK_`BW'==0,  start(0) width(0.0125)  fcolor(none) lcolor(black) ) ,
			xtitle("Share of college education")
			legend(order(1 "Treated" 2 "Control"))
			;
	#d cr	
	graph export "${output}/hist_SH_t_4_BW`BW'.pdf", as(pdf) replace
	
	
}



cap log close OC_balance_municipality_5






