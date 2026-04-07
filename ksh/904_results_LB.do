


global LB_c1_post "i.edu_mother##i.POST i.mother_age##i.POST c.elve1##i.POST"
global LB_c2_post "i.edu_father##i.POST  " 
global LB_c3_post "c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST c.ln_income_2018##i.POST c.U_2018##i.POST c.ln_de01_2018##i.POST"
global LB_c4_post "i.rkod##i.POST"
global LB_c5_post  "i.mkod##i.POST"
global LB_c6_post  "i.jaras##i.POST"



global LB_c1_ty "i.edu_mother##i.ty_baby i.mother_age##i.ty_baby c.elve1##i.ty_baby"
global LB_c2_ty "i.edu_father##i.ty_baby  " 
global LB_c3_ty "c.SH_t_1##i.ty_baby c.SH_t_2##i.ty_baby c.SH_t_3##i.ty_baby c.SH_t_4##i.ty_baby c.ln_income_2018##i.ty_baby c.U_2018##i.ty_baby c.ln_de01_2018##i.ty_baby "
global LB_c4_ty "i.rkod##i.ty_baby"
global LB_c5_ty  "i.mkod##i.ty_baby"
global LB_c6_ty  "i.jaras##i.ty_baby"


/*------------------------------------------------------------------------------
	OLS + reduced form
------------------------------------------------------------------------------*/



foreach BW in "0000"  5000 15000 {
	
	
	use "${temp}/LB_003", clear

	keep if inrange(ty_baby, 2010, .)
	keep if inrange(de01, 0, 20000)
	keep if CSOK_`BW' != .
	
	
	foreach OUTCOME of varlist  bef37w    apgar low_weight    suly /* thet hossz */ {

	
		eststo clear

		eststo q_1 : reghdfe `OUTCOME' CSOK_`BW'_POST  , absorb(ksh4_bpker ty_baby) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			
		eststo q_2 : reghdfe `OUTCOME' CSOK_`BW'_POST  , absorb(ksh4_bpker ty_baby $LB_c1_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			
			
		eststo q_3 : reghdfe `OUTCOME' CSOK_`BW'_POST , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c2_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local father "Yes"
			
			
		eststo q_4 : reghdfe `OUTCOME' CSOK_`BW'_POST  , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			
				
		eststo q_5 : reghdfe `OUTCOME' CSOK_`BW'_POST  , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c4_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local region "Yes"
			
					
		eststo q_6 : reghdfe `OUTCOME' CSOK_`BW'_POST , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c5_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local county "Yes"
			
				
		eststo q_7 : reghdfe `OUTCOME' CSOK_`BW'_POST  , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c6_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local subregion "Yes"
			
		esttab
		
		
		#d ;
		esttab q* 	using "${output}/tab_child_outcome_`OUTCOME'_BW`BW'.rtf",  replace nocons 
		keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		 nomtitles
		scalars("muni_fe  Municipality \& Year FE"
				"mother Mother controls"
				"father Father controls"
				"m_controls Municipality controls"
				"region Region FE"
				"county County FE"
				"subregion Subregion FE"
				) 
		;
		#d cr		
	}
}



/*------------------------------------------------------------------------------
	*** IV regressions
------------------------------------------------------------------------------*/




foreach BW in 5000 15000 {

	use "${temp}/LB_003", clear

	keep if inrange(ty_baby, 2010, .)
	keep if inrange(de01, 0, 20000)
	keep if CSOK_`BW' != .



	foreach OUTCOME of varlist bef37w    apgar low_weight    suly /* thet hossz */ {


		eststo clear

		eststo q_1 : ivreghdfe `OUTCOME' (CSOK_0000_POST = CSOK_`BW'_POST )  , absorb(ksh4_bpker ty_baby) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			
		eststo q_2 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST ) , absorb(ksh4_bpker ty_baby $LB_c1_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			
			
		eststo q_3 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST ) , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c2_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local father "Yes"
			
			
		eststo q_4 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST ) , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			
				
		eststo q_5 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST ) , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c4_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local region "Yes"
			
					
		eststo q_6 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST )  , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c5_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local county "Yes"
			
				
		eststo q_7 : ivreghdfe `OUTCOME'  (CSOK_0000_POST = CSOK_`BW'_POST )   , absorb(ksh4_bpker ty_baby $LB_c1_post $LB_c3_post $LB_c6_post) cluster(ksh4_bpker) 
			estadd local muni_fe "Yes"
			estadd local mother "Yes"
			estadd local m_controls "Yes"
			estadd local subregion "Yes"
			
		esttab
		
		
		#d ;
		esttab q* 	using "${output}/tab_child_outcome_`OUTCOME'_IV_BW`BW'.rtf",  replace nocons 
		keep(CSOK_0000_POST  ) coeflabel( CSOK_0000_POST "Rural CSOK \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		 nomtitles
		scalars("muni_fe  Municipality \& Year FE"
				"mother Mother controls"
				"father Father controls"
				"m_controls Municipality controls"
				"region Region FE"
				"county County FE"
				"subregion Subregion FE"
				) 
		;
		#d cr		
	}
}


/*------------------------------------------------------------------------------
	PRETREND
------------------------------------------------------------------------------*/


cap log close OC_pretrend_LB_child_outcomes
log using "${output}/OC_pretrend_LB_child_outcomes", text replace name(OC_pretrend_LB_child_outcomes)


use "${temp}/LB_003", clear

keep if inrange(ty_baby, 2010, .)
keep if inrange(de01, 0, 20000)



foreach BW in "0000"  5000 15000 {

	foreach OUTCOME of varlist suly apgar low_weight bef37w /* apgar suly low_weight hossz thet bef37w */  {
		
		reghdfe `OUTCOME' i.CSOK_`BW'##ib2018.ty_baby if inrange(ty_baby, 2010, .) , absorb(ksh4_bpker ty_baby $LB_c1_ty   $LB_c3_ty  ) cluster(ksh4_bpker)
		
		gen TIME = _n if inrange(_n, 2010, 2024)
		gen b = .
		gen se = .
		
		forval i = 2010(1)2024 {
			cap replace b = _b[1.CSOK_`BW'#`i'.ty_baby] if TIME == `i'
			cap replace se = _se[1.CSOK_`BW'#`i'.ty_baby] if TIME == `i'
		}
		
		gen hi = b + 1.96 * se
		gen lo = b - 1.96 * se
		
		#d ;
			twoway 
				(connected b TIME, lcolor("$color1") mcolor("$color1"))
				(rcap hi lo TIME, color("$color1")), 
					graphregion(color(white))
					xtitle("Year")
					ytitle("Estimated coefficient")
					legend(off)
					xline(2018.5)	
				;
		#d cr
		graph export "${output}/pretrend_`OUTCOME'_BW`BW'.pdf", as(pdf) replace
		drop TIME b se hi lo
	}

}

cap log close OC_pretrend_LB_child_outcomes


/*------------------------------------------------------------------------------
	mother characteristics as outcome -- suggestive of selection
------------------------------------------------------------------------------*/
/*

cap log close OC_pretrend_LB_mother_characteristics
log using "${output}/OC_pretrend_LB_mother_characteristics", text replace name(OC_pretrend_LB_mother_characteristics)


use "${temp}/LB_003", clear

keep if inrange(ty_baby, 2010, .)
keep if inrange(de01, 0, 20000)


tab edu_mother, gen(edu_)
		

		
		

foreach OUTCOME of varlist parents_married  elve1  mother_age edu_4 edu_3 edu_2 edu_1  {
	
	foreach BW in 15000  "0000" 5000  {
	
		 reghdfe `OUTCOME' i.CSOK_`BW'##ib2018.ty_baby  , absorb(ksh4_bpker ty_baby) cluster(ksh4_bpker) 

		 gen TIME = _n if inrange(_n, 2010, 2024)
		 gen b = .
		 gen se = .
		 
		forval i = 2010(1)2024 {
			replace b = _b[1.CSOK_`BW'#`i'.ty_baby] if TIME == `i'
			replace se = _se[1.CSOK_`BW'#`i'.ty_baby] if TIME == `i'
			
		}
		
		gen hi = b + 1.96 * se
		gen lo = b - 1.96 * se

		#d ;
			twoway 
				(connected b TIME, lcolor("$color1") mcolor("$color1"))
				(rcap hi lo TIME, color("$color1")), 
					graphregion(color(white))
					xtitle("Year")
					ytitle("Estimated coefficient")
					legend(off)
					xline(2018.5)	
				;
		#d cr			
		graph export "${output}/pretrend_mother_char_`OUTCOME'_BW`BW'.pdf", as(pdf) replace
		
		drop TIME b se hi lo
			
	}			
}
			
			
cap log close OC_pretrend_LB_mother_characteristics
*/
